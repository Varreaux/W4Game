# DungeonBSP.gd (Godot 4.x / GDScript)
class_name Room
extends Node

@export_group("Tile & Layer")
@export_node_path("TileMapLayer") var tilemap_path: NodePath               # TileMap layer to draw on
@export var source_id: int = 0                                             # TileSet atlas source ID
@export var wall_atlas: Vector2i = Vector2i(0, 0)                          # Atlas coords of the wall tile

@export_group("Generation Controls")
@export var min_margin: int = 3                                            # Min distance from edges and between cuts
@export var max_splits_per_band: int = 2                                   # Max recursive vertical splits per band
@export var rng_seed: int = -1                                             # RNG seed (-1 = random)
@export var top_wall_tiles: int = 6                                        # Length of inner vertical posts (from top)

@export_group("Corridors (vertical holes across floors)")
@export var corridor_width: int = 2                                        # Width (in tiles) of a vertical corridor
@export var min_dist_from_inner_wall: int = 2                              # Min horizontal distance from any inner post

@export_group("Side Entrances (outer walls)")
@export var entrance_height: int = 2                                       # Door height on outer wall (in tiles)
@export var entrance_vertical_margin: int = 1                              # Keep this many tiles above the door

@export_group("Connection Mode")
# true  => top layer -> RIGHT outer wall, bottom layer -> LEFT outer wall (↘ TL->BR)
# false => top layer -> LEFT outer wall,  bottom layer -> RIGHT outer wall (↗ BL->TR)
@export var diagonal_tl_br: bool = true

@export_group("Debug")
@export var print_detected_layers: bool = true

@export_group("Props Spawning")
@export var ladder_scene: PackedScene                     
@export var door_scene: PackedScene                       
@export_node_path("Node") var props_root_path: NodePath   


const INT_INF: int = 1 << 30

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _props_root: Node = null

# Per-layer dictionary layout:
# {
#   "rect": Rect2i,           # usable rect inside outer walls (excluding top/bottom walls)
#   "y_range": Vector2i,      # [start_y, end_y] inclusive walkable range
#   "top_wall": Vector2i,     # y segment (inclusive) of the top wall thickness
#   "bot_wall": Vector2i,     # y segment (inclusive) of the bottom wall thickness
#   "cuts": Array[int],       # vertical inner posts (x positions)
#   "left_wall_w": int,       # detected left outer-wall thickness (>=1)
#   "right_wall_w": int       # detected right outer-wall thickness (>=1)
# }
var _layers: Array = []                                                     # Array[Dictionary]
var _bbox: Rect2i                                                           # overall bounding box

func _ready() -> void:
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	generate()
	var trigger := get_node_or_null(enter_trigger_path) as Area2D
	if trigger:
		trigger.body_entered.connect(_on_body_entered)

func generate() -> void:
	var tl: TileMapLayer = get_node_or_null(tilemap_path) as TileMapLayer
	if tl == null:
		push_warning("TileMapLayer not set.")
		return
	
		# Prepare props root for instances (ladders/doors)
	_props_root = get_node_or_null(props_root_path)
	if _props_root == null:
		_props_root = tl.get_parent()

	if _props_root:
		for child in _props_root.get_children():
			child.queue_free()


	# 1) Compute used bounding box (outer frame must exist).
	var used: Array  = tl.get_used_cells()
	if used.is_empty():
		push_warning("No tiles found. Please draw the outer frame first.")
		return

	var minx: int = used[0].x
	var miny: int = used[0].y
	var maxx: int = used[0].x
	var maxy: int = used[0].y
	for c in used:
		if c.x < minx: minx = c.x
		if c.y < miny: miny = c.y
		if c.x > maxx: maxx = c.x
		if c.y > maxy: maxy = c.y

	_bbox = Rect2i(Vector2i(minx, miny), Vector2i(maxx - minx + 1, maxy - miny + 1))
	if _bbox.size.x <= 0 or _bbox.size.y <= 0:
		push_warning("Inner area too small.")
		return

	# 2) Detect layers with wall thickness + side wall thickness per layer.
	_layers = _detect_layers_with_walls_and_side_thickness(tl, _bbox)

	if print_detected_layers:
		var msg: String = "Layers (start,end | top_thk,bottom_thk | Lw,Rw): "
		for layer in _layers:
			var yr: Vector2i = layer["y_range"]
			var tw: Vector2i = layer["top_wall"]
			var bw: Vector2i = layer["bot_wall"]
			msg += "(" + str(yr.x) + "," + str(yr.y) + " | "
			msg += str(tw.y - tw.x + 1) + "," + str(bw.y - bw.x + 1) + " | "
			msg += str(layer["left_wall_w"]) + "," + str(layer["right_wall_w"]) + ") "
		print(msg)

	# 3) Build inner vertical posts (collect x-cuts).
	for layer in _layers:
		var rect: Rect2i = layer["rect"]
		var placed_cuts: Array = []   # Array[int]
		layer["cuts"] = placed_cuts
		_split_band_recursive(tl, rect, max_splits_per_band, placed_cuts)

	# 4) Carve vertical corridors between layers (unified erasing; still not piercing top/bottom outer frame).
	_carve_vertical_corridors(tl, _layers)

	# 5) Carve side entrances according to the diagonal mode (doors bottom-anchored to layer ground).
	_carve_side_entrances_by_mode(tl, _bbox, _layers)

	tl.call_deferred("update_internals")

# -------------------------------------------------------------------
# Layer detection with wall thickness and side outer-wall thickness
# -------------------------------------------------------------------
func _detect_layers_with_walls_and_side_thickness(tl: TileMapLayer, bbox: Rect2i) -> Array:
	var x0: int = bbox.position.x
	var x1: int = bbox.position.x + bbox.size.x - 1
	var y0: int = bbox.position.y
	var y1: int = bbox.position.y + bbox.size.y - 1

	var wall_rows: Array = []     # Array[bool] where full row is wall
	wall_rows.resize(y1 - y0 + 1)
	for i in range(wall_rows.size()):
		wall_rows[i] = false

	for y in range(y0, y1 + 1):
		var all_wall: bool = true
		for x in range(x0, x1 + 1):
			if tl.get_cell_source_id(Vector2i(x, y)) == -1:
				all_wall = false
				break
		wall_rows[y - y0] = all_wall

	var wall_segments: Array = []  # Array[Vector2i], consecutive wall rows
	var i: int = 0
	while i < wall_rows.size():
		if wall_rows[i]:
			var seg_s: int = i
			var seg_e: int = i
			while seg_e + 1 < wall_rows.size() and wall_rows[seg_e + 1]:
				seg_e += 1
			wall_segments.append(Vector2i(y0 + seg_s, y0 + seg_e))
			i = seg_e + 1
		else:
			i += 1

	var layers: Array = []         # Array[Dictionary]
	for idx in range(wall_segments.size() - 1):
		var top_wall: Vector2i = wall_segments[idx]
		var bot_wall: Vector2i = wall_segments[idx + 1]
		var inner_height: int = bot_wall.x - top_wall.y - 1
		if inner_height <= 0:
			continue

		var y_range: Vector2i = Vector2i(top_wall.y + 1, bot_wall.x - 1)

		var rect: Rect2i = Rect2i(
			Vector2i(x0 + 1, top_wall.y + 1),
			Vector2i((x1 - 1) - (x0 + 1) + 1, inner_height)
		)

		var left_w: int = _measure_outer_wall_width_side(tl, x0, y_range.x, y_range.y, +1)
		var right_w: int = _measure_outer_wall_width_side(tl, x1, y_range.x, y_range.y, -1)
		if left_w <= 0: left_w = 1
		if right_w <= 0: right_w = 1

		var layer: Dictionary = {
			"rect": rect,
			"y_range": y_range,
			"top_wall": top_wall,
			"bot_wall": bot_wall,
			"cuts": [] as Array,          # Array[int]
			"left_wall_w": left_w,
			"right_wall_w": right_w
		}
		layers.append(layer)

	return layers

# Scan outer-wall thickness from the edge inward; dir: +1 left->right, -1 right->left
func _measure_outer_wall_width_side(tl: TileMapLayer, x_edge: int, y_from: int, y_to: int, dir: int) -> int:
	var min_w: int = INT_INF
	for y in range(y_from, y_to + 1):
		var w: int = 0
		var x: int = x_edge
		while true:
			var sid: int = tl.get_cell_source_id(Vector2i(x, y))
			if sid == -1:
				break
			w += 1
			x += dir
			if w > 64:  # hard cap for safety
				break
		if w < min_w:
			min_w = w
	return (0 if min_w == INT_INF else min_w)

# -------------------------------------------------------------------
# Recursive vertical splitting (inner posts)
# -------------------------------------------------------------------
func _split_band_recursive(tl: TileMapLayer, rect: Rect2i, splits_left: int, placed_cuts: Array) -> void:
	if splits_left <= 0:
		return
	if rect.size.x < min_margin * 2 + 3:
		return

	var x: int = _rand_x_avoiding(rect, placed_cuts, min_margin)
	if x == INT_INF:
		return

	_draw_vline(tl, x, rect.position.y, rect.position.y + rect.size.y - 1)
	placed_cuts.append(x)

	var left: Rect2i = Rect2i(rect.position, Vector2i(x - rect.position.x, rect.size.y))
	var right: Rect2i = Rect2i(Vector2i(x + 1, rect.position.y), Vector2i(rect.end.x - (x + 1) + 1, rect.size.y))

	var next_rect: Rect2i = left
	if right.size.x * right.size.y > left.size.x * left.size.y:
		next_rect = right

	_split_band_recursive(tl, next_rect, splits_left - 1, placed_cuts)

func _rand_x_avoiding(rect: Rect2i, placed_cuts: Array, min_gap: int) -> int:
	var left: int = rect.position.x + min_margin
	var right: int = rect.position.x + rect.size.x - 1 - min_margin
	if right < left:
		return INT_INF

	var candidates: Array = []   # Array[int]
	for x in range(left, right + 1):
		var ok: bool = true
		for c in placed_cuts:
			if abs(x - int(c)) < min_gap:
				ok = false
				break
		if ok:
			candidates.append(x)

	if candidates.is_empty():
		return INT_INF
	return int(candidates[_rng.randi_range(0, candidates.size() - 1)])

# -------------------------------------------------------------------
# Unified erasing for “vertical door-like blocks”
# Bottom-anchored at ground_y, with fixed height.
# -------------------------------------------------------------------
func _erase_vertical_door_block(
	tl: TileMapLayer,
	x_from: int, x_to: int,
	ground_y: int,
	height: int,
	y_min: int, y_max: int
) -> void:
	var h: int = max(1, height)

	# Start position we desire if the bottom must sit on ground_y.
	var desired_start: int = ground_y - (h - 1)

	# Clamp within [y_min, y_max] while keeping as low as possible.
	var start_y: int = max(y_min, min(desired_start, y_max - (h - 1)))
	var end_y: int = start_y + h - 1

	# If there is room, make bottom touch ground_y exactly (unless margins prevent it).
	if end_y < ground_y and (ground_y - start_y + 1) >= h and ground_y <= y_max:
		start_y = ground_y - (h - 1)
		if start_y < y_min:
			start_y = y_min
		end_y = start_y + h - 1

	for x in range(x_from, x_to + 1):
		for y in range(start_y, end_y + 1):
			tl.erase_cell(Vector2i(x, y))

# -------------------------------------------------------------------
# Vertical corridors between layers (now using the unified erasing)
# -------------------------------------------------------------------
func _carve_vertical_corridors(tl: TileMapLayer, layers: Array) -> void:
	if layers.size() <= 1:
		return

	for i in range(layers.size()):
		if i == layers.size() - 1:
			break

		var cur: Dictionary = layers[i]
		var nxt: Dictionary = layers[i + 1]

		var rect: Rect2i = cur["rect"]
		var bot_wall: Vector2i = cur["bot_wall"]   # inclusive [y_from..y_to], this is the floor thickness

		var y_from: int = bot_wall.x
		var y_to: int = bot_wall.y

		# X-range selection (avoid inner cuts by margin)
		var left_x: int = rect.position.x + min_margin
		var right_x: int = rect.position.x + rect.size.x - corridor_width - min_margin
		if right_x < left_x:
			continue

		var avoid_cuts: Array = []
		for v in cur["cuts"]:
			avoid_cuts.append(int(v))
		for v in nxt["cuts"]:
			avoid_cuts.append(int(v))

		var candidates: Array = []  # Array[int]
		for x in range(left_x, right_x + 1):
			var ok: bool = true
			for c in avoid_cuts:
				var cc: int = int(c)
				if abs(x - cc) < min_dist_from_inner_wall or abs((x + corridor_width - 1) - cc) < min_dist_from_inner_wall:
					ok = false
					break
				if cc >= x and cc <= x + corridor_width - 1:
					ok = false
					break
			if ok:
				candidates.append(x)

		if candidates.is_empty():
			continue

		var start_x: int = int(candidates[_rng.randi_range(0, candidates.size() - 1)])
		var end_x: int = start_x + corridor_width - 1

		# Use unified erasing to pierce exactly the floor thickness [y_from..y_to].
		var corridor_height: int = y_to - y_from + 1
		# Anchor the bottom at y_to so the erased block fully matches the slab thickness.
		_erase_vertical_door_block(
			tl,
			start_x, end_x,
			y_to,
			corridor_height,
			y_from, y_to
		)
		
		# ===== Spawn Ladder aligned to the LEFT edge of the hole =====

		if ladder_scene and _props_root:
			var tile_size := _tile_size_px(tl)
			var mid_y: int = int((y_from + y_to) / 2)
			var hole_center_world := _map_cell_center_world(tl, Vector2i(start_x, mid_y))
			hole_center_world.x -= tile_size.x * 0.5
			_spawn_scene_at_world(ladder_scene, hole_center_world)

# -------------------------------------------------------------------
# Side entrances on outer walls (diagonal mode; doors bottom-anchored to ground)
# -------------------------------------------------------------------
func _carve_side_entrances_by_mode(tl: TileMapLayer, bbox: Rect2i, layers: Array) -> void:
	if layers.is_empty():
		return

	var top_layer: Dictionary = layers[0]
	var bottom_layer: Dictionary = layers[layers.size() - 1]

	var x_left_edge: int = bbox.position.x
	var x_right_edge: int = bbox.position.x + bbox.size.x - 1

	if diagonal_tl_br:
		# top -> RIGHT, bottom -> LEFT
		_carve_wall_door_adjacent_floor(
			tl, x_right_edge, top_layer, false, entrance_height, entrance_vertical_margin
		)
		_carve_wall_door_adjacent_floor(
			tl, x_left_edge, bottom_layer, true, entrance_height, entrance_vertical_margin
		)
	else:
		# top -> LEFT, bottom -> RIGHT
		_carve_wall_door_adjacent_floor(
			tl, x_left_edge, top_layer, true, entrance_height, entrance_vertical_margin
		)
		_carve_wall_door_adjacent_floor(
			tl, x_right_edge, bottom_layer, false, entrance_height, entrance_vertical_margin
		)

# Carve a side door on an outer wall: bottom-anchored to the layer ground and fully piercing wall thickness.
func _carve_wall_door_adjacent_floor(
	tl: TileMapLayer,
	wall_x_edge: int,
	layer: Dictionary,
	is_left: bool,
	door_h: int,
	v_margin: int
) -> void:
	var y_range: Vector2i = layer["y_range"]
	var ground_y: int = y_range.y
	var door_height: int = max(1, door_h)

	# Only keep an upper margin (above the door); allow the bottom to sit on ground.
	var y_min: int = y_range.x + max(0, v_margin)
	var y_max: int = y_range.y   # bottom can reach the ground

	if y_min > y_max:
		return

	var wall_w: int = (layer["left_wall_w"] if is_left else layer["right_wall_w"])
	wall_w = max(1, wall_w)

	var x_start: int = wall_x_edge if is_left else (wall_x_edge - wall_w + 1)
	var x_end: int = x_start + wall_w - 1

	_erase_vertical_door_block(
		tl,
		x_start, x_end,
		ground_y,
		door_height,
		y_min, y_max
	)

# -------------------------------------------------------------------
# Draw a vertical wall (post) from the top side with fixed length.
# -------------------------------------------------------------------
#func _draw_vline(tl: TileMapLayer, x: int, y0: int, y1: int) -> void:
	#var top: int = min(y0, y1)
	#var bottom: int = max(y0, y1)
	#var length: int = max(0, top_wall_tiles)
	#if length <= 0:
		#return
	#var last: int = min(top + length - 1, bottom)
	#for y in range(top, last + 1):
		#tl.set_cell(Vector2i(x, y), source_id, wall_atlas)

func _draw_vline(tl: TileMapLayer, x: int, y0: int, y1: int) -> void:
	var top: int = min(y0, y1)
	var bottom: int = max(y0, y1)
	var length: int = max(0, top_wall_tiles)
	if length <= 0:
		return
	var last: int = min(top + length - 1, bottom)
	for y in range(top, last + 1):
		tl.set_cell(Vector2i(x, y), source_id, wall_atlas)

	# ===== 在立柱的“最低处”生成门（门的中心对准最低处这一格的中心）=====
	if door_scene and _props_root:
		var door_world := _map_cell_center_world(tl, Vector2i(x, last))
		_spawn_scene_at_world(door_scene, door_world + Vector2.DOWN*72)



func _map_cell_center_world(tl: TileMapLayer, cell: Vector2i) -> Vector2:
	var local: Vector2 = tl.map_to_local(cell)               
	return tl.to_global(local)                               

func _tile_size_px(tl: TileMapLayer) -> Vector2:
	if tl.tile_set:
		return Vector2(tl.tile_set.tile_size)
	return Vector2(64, 64)  

func _spawn_scene_at_world(packed: PackedScene, world_pos: Vector2) -> void:
	if packed == null or _props_root == null:
		return
	var inst: Node = packed.instantiate()
	_props_root.add_child(inst)
	
	if inst is Node2D:
		(inst as Node2D).global_position = world_pos
	elif inst.has_method("set_global_position"):
		inst.call("set_global_position", world_pos)
	
	inst.name = "AUTO_" + packed.resource_path.get_file().get_basename()


signal player_entered(room: Node2D)

@export_node_path("Area2D") var enter_trigger_path: NodePath
@export var one_shot_trigger: bool = true   

var _fired := false

func _on_body_entered(body: Node) -> void:
	print("_on_body_entered")
	if _fired and one_shot_trigger:
		return
	if body.is_in_group("player"):
		_fired = true
		player_entered.emit(self)
		print("body.is_in_group(player)")
