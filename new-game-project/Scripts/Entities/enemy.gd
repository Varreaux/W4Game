class_name Enemy

extends Entity

const ACTIVE_RANGE = 300
const BEHAVIORS = [
	preload("res://Objects/Behaviors/Conditions/on_ground_condition.tscn"),
	preload("res://Objects/Behaviors/Conditions/forever_condition.tscn"),
	preload("res://Objects/Behaviors/Conditions/on_hurt_condition.tscn")
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
	if get_player_range() > ACTIVE_RANGE: return
	
	velocity.y += gravity * delta
	move_and_slide()

func _process(_delta: float) -> void:
	if hp <= 0:
		call_deferred("queue_free")

func get_player_range() -> float:
	return (Player.instance.global_position - global_position).length()
