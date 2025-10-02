extends CharacterBody2D

const SPEED = 200
const GRAVITY = 980

@onready var hand = $hand
var can_attack = true

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

func _on_hand_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var behaviors = body.get_children().filter(func(n): return n is Node and not n is ColorRect and not n is CollisionShape2D)
		if behaviors.size() > 0:
			var picked = behaviors[randi() % behaviors.size()]
			body.remove_child(picked)
			add_child(picked)
			print("Player grabbed:", picked.name)
