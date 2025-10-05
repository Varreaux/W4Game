extends Entity

const GRAVITY = 980.0

const BEHAVIORS = [
	preload("res://Objects/Behaviors/JumpOnGround.tscn"),
	preload("res://Objects/Behaviors/explode_on_wall.tscn"),
	preload("res://Objects/Behaviors/shoot_bullets.tscn")
]

func _ready():
	randomize()
	
	for behavior_scene in BEHAVIORS:
		var behavior_instance = behavior_scene.instantiate() as Behavior
		behavior_instance.set_entity(self)
		behavior_instance.set_active(true)
		$Behaviors.add_child(behavior_instance)
	#var behavior_scene = BEHAVIORS[randi() % BEHAVIORS.size()]
	#var behavior_instance = behavior_scene.instantiate()
	#add_child(behavior_instance)


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	velocity.x = 0  # move right
	move_and_slide()
