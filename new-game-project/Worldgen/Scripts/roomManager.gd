# RoomManager.gd (Godot 4.x / 2D)
extends Node

@export_group("Scenes & Parents")
@export var room_scene: PackedScene                         
@export_node_path("Node") var rooms_parent_path: NodePath  
@export var first_room: Room

@export_group("Layout")
@export var next_offset: Vector2 = Vector2(640, 0)          

var rooms: Array[Node2D] = []       
var latest_room: Room = null     

func _ready() -> void:
	latest_room = first_room

	if latest_room.has_signal("player_entered"):
		latest_room.player_entered.connect(_on_room_player_entered)
	#_spawn_initial_rooms()

func _spawn_initial_rooms() -> void:
	
	var parent := get_node_or_null(rooms_parent_path) as Node
	if parent == null:
		parent = self

	
	var r0 : Room = _spawn_room(parent, Vector2.ZERO)
	latest_room = r0
	#_spawn_next_room()

func _spawn_room(parent: Node, at_pos: Vector2) -> Room:
	if room_scene == null:
		push_error("RoomManager: room_scene not set")
		return null
	
	var inst : Room = room_scene.instantiate()
	if latest_room:
		inst.diagonal_tl_br = !latest_room.diagonal_tl_br
	parent.add_child(inst)
	inst.global_position = at_pos
	rooms.append(inst)
	
	
	if inst.has_signal("player_entered"):
		inst.player_entered.connect(_on_room_player_entered)
	else:
		if inst.has_method("player_entered"):
			
			pass

	return inst

func _on_room_player_entered(room: Node2D) -> void:
	
	if room == latest_room:
		_spawn_next_room()

func _spawn_next_room() -> void:
	var parent := get_node_or_null(rooms_parent_path) as Node
	if parent == null:
		parent = self
	if latest_room == null:
		return

	var next_pos :Vector2= latest_room.global_position + next_offset
	var next_room := _spawn_room(parent, next_pos)
	if next_room:
		latest_room = next_room
