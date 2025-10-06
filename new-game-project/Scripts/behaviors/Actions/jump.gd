extends Action

func _ready() -> void:
	cooldown_time = randf_range(1, 3)
	
func on_trigger(_bypass_cooldown: bool = false):
	if cooldown_counter > cooldown_time || _bypass_cooldown:
		var jump_force = randf_range(200, 300)
		entity.velocity.y = -jump_force
		cooldown_counter = 0
