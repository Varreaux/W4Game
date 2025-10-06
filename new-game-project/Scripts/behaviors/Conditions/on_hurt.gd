extends Condition
var signal_attached_to: Entity = null

var actions = [
	"shoot_action",
	"jump_action",
	"slash_action",
	"explode_action"
]

func _enter_tree() -> void:
	if not init:
		condition_name = "OnHurt"
		actions.shuffle()
		var _action_name: String = actions[0]
		var _action_resource = load("res://Objects/Behaviors/Actions/" + _action_name + ".tscn")
		var _action_object = _action_resource.instantiate()
		add_child(_action_object)
		super._enter_tree()

func set_entity(_entity: Entity):
	super.set_entity(_entity)
	if signal_attached_to != null:
		signal_attached_to.was_hurt.disconnect(trigger_no_cooldown)
	signal_attached_to = _entity
	signal_attached_to.was_hurt.connect(trigger_no_cooldown)
	
