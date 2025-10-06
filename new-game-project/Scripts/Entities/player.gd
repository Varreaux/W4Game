class_name Player

extends Entity

enum {HAND_INACTIVE, HAND_SHOOTING, HAND_IDLING, HAND_RETURNING, HAND_RETURNING_HOLDING, HAND_HOLDING}

@export_flags_2d_physics var ladder_layer

@export var move_speed: float
@export var jump_power: float
@export var gravity_shorthop: float
@export var ladder_climb_speed: float

@export var hand_shoot_direction: Vector2
@export var hand_shoot_speed: float
@export var hand_shoot_time: float
@export var hand_idle_time: float
@onready var hand = $HandParent/Hand

@export var behaviors_menu_position: Vector2
@onready var behavior_menu = $BehaviorPanel

@export var ball_throw_power: float
@onready var power_ball_object = preload("res://Objects/Entities/power_ball.tscn")

var do_short_hop = false
var player_behaviors = []
var player_behaviors_menu_on = false
var hand_state: int
var hand_state_counter: float = 0
var current_enemy = null
var enemy_behaviors = []
var held_behavior: Behavior
var on_ladder: bool = false
var touching_ladder: bool = false
var ladder: Node2D
var level: int = 1
var experience: int = 0
@onready var xp_bar: ProgressBar = $Camera2D/EXPBar
@onready var lvl_label: Label = $Camera2D/EXPBar/Level
@onready var abilities: Label = $Camera2D/Abilities

static var instance: Player

func _ready():
	hp = max_health
	hp_bar = $Camera2D/HPBar
	hand.monitoring = false
	hand.visible = false
	hand_state = HAND_INACTIVE
	instance = self
	was_hurt.connect(hitstop_on_hurt)
	Engine.time_scale = 1
	
func _physics_process(delta: float) -> void:
	
	if not on_ladder:
		#Handle horizontal movement
		var _hor: float = Input.get_axis("Left", "Right")
		velocity.x = _hor * move_speed
		
		#Sprite flip
		if _hor != 0:
			$Art.flip_h = true if _hor < 0 else false
		
		#Handle falling
		if not is_on_floor():
			velocity.y += gravity * delta
			if do_short_hop and not Input.is_action_pressed("Jump") and velocity.y < 0:
				velocity.y += gravity_shorthop * delta * -up_direction.y
				
		if is_on_floor():
			if velocity.y >= 0:
				do_short_hop = false
				
		if touching_ladder:
			if Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("Down"):
				on_ladder = true
	else:
		global_position.x = ladder.global_position.x + 16
		var _vert: float = Input.get_axis("Up", "Down")
		velocity.y = _vert * ladder_climb_speed
		var _hor: float = Input.get_axis("Left", "Right")
		#Sprite flip
		if _hor != 0:
			$Art.flip_h = true if _hor < 0 else false
		global_position.y = clamp(global_position.y, ladder.global_position.y, ladder.global_position.y + 160)
	#Execute movement
	move_and_slide()
	
func _process(delta: float) -> void:
	if hp <= 0:
		get_tree().reload_current_scene()
	
	#Manage hand movements
	hand_state_counter += delta
	match hand_state:
		HAND_SHOOTING:
			hand.global_position += hand_shoot_direction * hand_shoot_speed * delta
			if hand_state_counter >= hand_shoot_time: 
				hand_state_counter = 0
				hand_state = HAND_IDLING
				
		HAND_IDLING:
			if hand_state_counter >= hand_idle_time: 
				hand_state_counter = 0
				hand_state = HAND_RETURNING
				hand.monitoring = false
		HAND_RETURNING:
			var _diff: Vector2 = (global_position + Vector2.UP * 10) - hand.global_position
			hand.global_position += _diff.normalized() * hand_shoot_speed * delta
			if _diff.length() < 8:
				hand.visible = false  
				hand_state = HAND_INACTIVE
		HAND_RETURNING_HOLDING:
			var _diff: Vector2 = (global_position + Vector2.UP * 10) - hand.global_position
			hand.global_position += _diff.normalized() * hand_shoot_speed * delta
			if _diff.length() < 8:
				hand_state = HAND_HOLDING
				$HandParent/Hand/Art/GrabbedBehavior.position = Vector2(0, -5)
		HAND_HOLDING:
			hand.global_position = global_position + Vector2.UP * 28
			hand.get_node("Art").flip_v = true
			hand.get_node("Art").flip_h = $Art.flip_h

func _input(event):
	if event.is_action_pressed("open_power_menu"):
		stock_or_pull()
		
	if event.is_action_pressed("Jump") and (is_on_floor() or on_ladder):
		velocity.y = jump_power * -up_direction.y
		do_short_hop = true
		on_ladder = false
	if event.is_action_pressed("Attack"):
		attack()

func get_player_behaviors():
	return $Behaviors.get_children()

func stock_or_pull():
	if player_behaviors_menu_on:
		player_behaviors_menu_on = false
		behavior_menu.visible = false
		get_tree().paused = false
	elif hand_state == HAND_INACTIVE:
		if $Behaviors.get_child_count() == 0: return
		player_behaviors_menu_on = true
		player_behaviors = get_player_behaviors()
		_show_behavior_menu(player_behaviors)
	elif hand_state == HAND_HOLDING:
		if $Behaviors.get_child_count() >= 2 + level: return
		held_behavior.get_parent().remove_child(held_behavior)
		get_node("Behaviors").add_child(held_behavior)
		held_behavior.owner = self
		held_behavior.set_entity(self)
		held_behavior.active = true
		hand_state = HAND_INACTIVE
		hand.visible = false
		abilities.text = "Abilities: %d/%d" % [$Behaviors.get_child_count(), 2 + level]
		
func attack():
	if hand_state == HAND_INACTIVE:
		hand_shoot_direction = get_mouse_direction()
		hand.monitoring = true
		hand.visible = true  
		hand.global_position = global_position + Vector2( 8 * (-1 if $Art.flip_h else 1), -10)
		hand.get_node("Art").flip_h = $Art.flip_h
		$HandParent/Hand/Art/GrabbedBehavior.visible = false
		hand_state = HAND_SHOOTING
		hand_state_counter = 0
		$HandParent/Hand/Art.flip_v = false
	if hand_state == HAND_HOLDING:
		var ball = power_ball_object.instantiate() as PowerBall
		get_parent().add_child(ball)
		hand.remove_child(held_behavior)
		hand_state = HAND_INACTIVE
		hand.monitoring = false
		hand.visible = false
		$HandParent/Hand/Art/GrabbedBehavior.visible = false
		ball.behavior = held_behavior
		ball.add_child(held_behavior)
		ball.get_node("Label").text = held_behavior.get_behavior_name()
		ball.global_position = global_position + Vector2(15 * (-1.0 if $Art.flip_h else 1.0), -10)
		ball.linear_velocity = ball_throw_power * get_mouse_direction()
		held_behavior = null
		
func _on_hand_body_entered(body: Node2D) -> void:
	if hand_state != HAND_SHOOTING: return
	if body.is_in_group("enemies"):
		current_enemy = body
		enemy_behaviors = body.get_node("Behaviors").get_children()
		if enemy_behaviors.size() > 0:
			_show_behavior_menu(enemy_behaviors)
		
func _show_behavior_menu(behaviors):
	behavior_menu.visible = true
	get_tree().paused = true
	
	var container = behavior_menu.get_node("VBoxContainer")
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	for behavior: Behavior in behaviors:
		var btn = Button.new()
		btn.text = behavior.get_behavior_name()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.set_meta("behavior_node", behavior)
		btn.pressed.connect(_on_behavior_selected.bind(behavior))
		container.add_child(btn)
	
#	This is just formatting the enemy's behavior box once grabbed
	behavior_menu.custom_minimum_size.y = behaviors.size() * 35  
	behavior_menu.custom_minimum_size.x = 135 
	var offset_y = behaviors_menu_position.y-(behaviors.size() * 35)
	behavior_menu.global_position = global_position + Vector2(behaviors_menu_position.x, offset_y)

func _on_behavior_selected(_behavior: Behavior):
	if player_behaviors_menu_on:
		get_node("Behaviors").remove_child(_behavior)
		_behavior.set_active(false)
		_behavior.set_entity(null)
		abilities.text = "Abilities: %d/%d" % [$Behaviors.get_child_count(), 2 + level]
		held_behavior = _behavior
		hand.add_child(_behavior)
		hand_state = HAND_HOLDING
		hand.visible = true
		hand.get_node("Art/GrabbedBehavior").visible = true
		hand.get_node("Art/GrabbedBehavior/Label").text = _behavior.get_behavior_name()
		$HandParent/Hand/Art/GrabbedBehavior.position = Vector2(0, -5)
		player_behaviors_menu_on = false
	else:
		current_enemy.get_node("Behaviors").remove_child(_behavior)
		_behavior.set_active(false)
		_behavior.set_entity(null)
		held_behavior = _behavior
		hand.add_child(_behavior)
		hand.visible = true
		hand_state = HAND_RETURNING_HOLDING
		hand.get_node("Art/GrabbedBehavior").visible = true
		hand.get_node("Art/GrabbedBehavior/Label").text = _behavior.get_behavior_name()
		$HandParent/Hand/Art/GrabbedBehavior.position = Vector2(0, 5)
	behavior_menu.visible = false
	get_tree().paused = false

func get_mouse_diff() -> Vector2:
	return get_global_mouse_position() - global_position

func get_mouse_direction() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()

func _on_ladder_detector_area_entered(area: Area2D) -> void:
	touching_ladder = true
	ladder = area as Node2D
	print("OnLadder")

func _on_ladder_detector_area_exited(_area: Area2D) -> void:
	touching_ladder = false
	print("OffLadder")

func hitstop_on_hurt():
	hitstop(0.02, 0.5)

func hitstop(time_scale: float, duration: float):
	modulate = Color.RED
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1
	modulate = Color.WHITE

func gain_exp():
	experience += 1
	if(experience >= 5 * level):
		level += 1
		experience = 0
		hp = max_health
		hp_bar.value = hp / max_health
		lvl_label.text = "Lv. %d" % [level]
	xp_bar.value = (float(experience) / (5.0 * float(level)))
	
