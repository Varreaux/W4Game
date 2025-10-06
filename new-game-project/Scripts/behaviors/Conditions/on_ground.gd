extends Condition

var actions = [
	"shoot_action",
	"jump_action",
	"slash_action",
	"explode_action",
	"walk_action"
]

func _enter_tree() -> void:
	condition_name = "OnGround"
	if not init and get_child_count() == 0:
		actions.shuffle()
		var _action_name: String = actions[0]
		var _action_resource = load("res://Objects/Behaviors/Actions/" + _action_name + ".tscn")
		var _action_object = _action_resource.instantiate()
		add_child(_action_object)
	super._enter_tree()
	
func _process(_delta):
	if not active: return
	if get_player_range() > ACTIVE_RANGE: return
	if entity.is_on_floor():
		trigger()
