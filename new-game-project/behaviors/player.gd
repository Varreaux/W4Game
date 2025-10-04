extends CharacterBody2D

const SPEED = 200
const GRAVITY = 980

@onready var hand = $hand
var can_attack = true

var player_behaviors = []
var player_behaviors_menu_on = false
func _input(event):
	if event.is_action_pressed("open_power_menu"):
		player_behaviors_menu_on = true
		player_behaviors = get_player_behaviors()
		_show_behavior_menu(player_behaviors)

func get_player_behaviors():
	return get_tree().get_nodes_in_group("player_behaviors")

func _ready():
	hand.monitoring = false
	hand.visible = false
	can_attack = true
	
func _physics_process(delta):
	velocity.y += GRAVITY * delta
	velocity.x = 0

	if Input.is_action_pressed("ui_left"):
		velocity.x -= SPEED
	if Input.is_action_pressed("ui_right"):
		velocity.x += SPEED

	move_and_slide()
	
	if Input.is_action_just_pressed("ui_accept") and can_attack:
		attack()



func attack():
	can_attack = false
	hand.monitoring = true
	hand.visible = true  

	await get_tree().create_timer(0.2).timeout
	hand.monitoring = false
	hand.visible = false
	can_attack = true
	
	

@onready var behavior_menu = $BehaviorPanel
var current_enemy = null
var enemy_behaviors = []

func _on_hand_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		current_enemy = body
		enemy_behaviors = body.get_children().filter(func(n):
			return n is Node and not n is ColorRect and not n is CollisionShape2D)
		
		if enemy_behaviors.size() > 0:
			_show_behavior_menu(enemy_behaviors)
			

func _show_behavior_menu(behaviors):
	behavior_menu.visible = true
	get_tree().paused = true
	
	var container = behavior_menu.get_node("VBoxContainer")
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	for behavior in behaviors:
		var btn = Button.new()
		btn.text = behavior.name
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.set_meta("behavior_node", behavior)
		btn.pressed.connect(_on_behavior_selected.bind(behavior))
		container.add_child(btn)
	
#	This is just formatting the enemy's behavior box once grabbed
	behavior_menu.custom_minimum_size.y = behaviors.size() * 35  
	behavior_menu.custom_minimum_size.x = 135 
	var offset_y = -40-(behaviors.size() * 35)
	behavior_menu.global_position = global_position + Vector2(40, offset_y)

func _on_behavior_selected(behavior):
	print("Button was pressed!")
	if player_behaviors_menu_on:
		var power_ball_scene = preload("res://power_ball.tscn")
		var ball = power_ball_scene.instantiate()
		ball.behavior = behavior.duplicate()  # clone it
		ball.direction = Vector2.RIGHT  # or aim later
		ball.global_position = global_position + Vector2(30, -30)
		remove_child(behavior)
		get_parent().add_child(ball)
		player_behaviors_menu_on = false
	else:
		current_enemy.remove_child(behavior)
		add_child(behavior)
		behavior.add_to_group("player_behaviors")  
	print("Player chose:", behavior.name)
	behavior_menu.visible = false
	get_tree().paused = false
