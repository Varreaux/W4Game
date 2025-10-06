extends Action

@onready var slash = preload("res://Objects/Entities/explosion.tscn")


func _ready() -> void:
	cooldown_time = randf_range(0.5, 2)
	
func on_trigger(_bypass_cooldown: bool = false):
	if cooldown_counter > cooldown_time || _bypass_cooldown:
		var _slash = slash.instantiate() as AnimatedHitbox
		get_tree().root.get_child(0).call_deferred("add_child",_slash)
		var _y = -8
		var _x = 0
		_slash.global_position = entity.global_position + Vector2(_x, _y)
		cooldown_counter = 0
