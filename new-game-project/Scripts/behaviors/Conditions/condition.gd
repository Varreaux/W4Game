class_name Condition

extends Behavior

var action: Action
var init: bool = false

signal triggered(bypass_cooldown: bool)

var condition_name: String

const ACTIVE_RANGE = 300

func _enter_tree() -> void:
	if not init:
		action = get_child(0) as Action
		triggered.connect(action.on_trigger)
		init = true
	
func trigger():
	emit_signal("triggered", false)
	
func trigger_no_cooldown():
	emit_signal("triggered", true)
	
func set_entity(_entity: Entity):
	entity = _entity
	action.set_entity(_entity)

func set_active(_active: bool):
	active = _active
	action.set_active(true)

func get_behavior_name() -> String:
	return get_child(0).name + condition_name

func get_player_range() -> float:
	return (Player.instance.global_position - global_position).length()
