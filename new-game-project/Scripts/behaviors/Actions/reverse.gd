extends Action

func _ready() -> void:
	cooldown_time = randf_range(4, 6)
	
func on_trigger(_bypass_cooldown: bool = false):
	if cooldown_counter > cooldown_time || _bypass_cooldown:
		entity.up_direction = -entity.up_direction
		entity.gravity = -entity.gravity
		entity.get_node("Art").flip_v = (true if entity.up_direction.y == 1 else false)
		cooldown_counter = 0
