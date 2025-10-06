class_name Enemy

extends Entity

const ACTIVE_RANGE = 300
const BEHAVIORS = [
	preload("res://Objects/Behaviors/Conditions/on_ground_condition.tscn"),
	preload("res://Objects/Behaviors/Conditions/forever_condition.tscn"),
	preload("res://Objects/Behaviors/Conditions/on_hurt_condition.tscn")
]

var load_behaviors: bool = true
var assign_behaviors_to_self: bool = false


func _ready():
	super._ready()
	randomize()
	
	if(load_behaviors):
		for behavior_scene in BEHAVIORS:
			var behavior_instance = behavior_scene.instantiate() as Behavior
			$Behaviors.add_child(behavior_instance)
			behavior_instance.set_entity(self)
			behavior_instance.set_active(true)	
	#var behavior_scene = BEHAVIORS[randi() % BEHAVIORS.size()]
	#var behavior_instance = behavior_scene.instantiate()
	#add_child(behavior_instance)

func _physics_process(delta):
	if assign_behaviors_to_self:
		for _behavior: Behavior in $Behaviors.get_children():
			_behavior.set_entity(self)
			_behavior.set_active(true)
		assign_behaviors_to_self = false
		
	if get_player_range() > ACTIVE_RANGE: return
	
	velocity.y += gravity * delta
	move_and_slide()

func _process(_delta: float) -> void:
	if hp <= 0:
		call_deferred("queue_free")

func get_player_range() -> float:
	return (Player.instance.global_position - global_position).length()

func get_player_diff() -> Vector2:
	return (Player.instance.global_position - global_position)
