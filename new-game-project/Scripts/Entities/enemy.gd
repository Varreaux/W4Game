class_name Enemy

extends Entity

const BEHAVIORS = [
	preload("res://Objects/Behaviors/Conditions/on_ground.tscn"),
	preload("res://Objects/Behaviors/Conditions/forever.tscn"),
	preload("res://Objects/Behaviors/Conditions/on_hurt.tscn")
]

func _ready():
	super._ready()
	randomize()
	
	for behavior_scene in BEHAVIORS:
		var behavior_instance = behavior_scene.instantiate() as Behavior
		$Behaviors.add_child(behavior_instance)
		behavior_instance.set_entity(self)
		behavior_instance.set_active(true)
	#var behavior_scene = BEHAVIORS[randi() % BEHAVIORS.size()]
	#var behavior_instance = behavior_scene.instantiate()
	#add_child(behavior_instance)

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.x = 0  # move right
	move_and_slide()

func _process(_delta: float) -> void:
	if hp <= 0:
		call_deferred("queue_free")
