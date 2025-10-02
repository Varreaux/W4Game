extends CharacterBody2D


const GRAVITY = 980.0

const BEHAVIORS = [
	preload("res://behaviors/JumpOnGround.tscn"),
	preload("res://behaviors/explode_on_wall.tscn"),
	preload("res://behaviors/shoot_bullets.tscn")
]

func _ready():
	randomize()
	var behavior_scene = BEHAVIORS[randi() % BEHAVIORS.size()]
	var behavior_instance = behavior_scene.instantiate()
	add_child(behavior_instance)


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	velocity.x = 0  # move right

	if is_on_wall():
		print("I'm touching a wall!")
	move_and_slide()
