class_name JumpOnGround 

extends Behavior

func _process(_delta):
	if not active: return
	if entity.is_on_floor():
		var jump_force = randf_range(200, 300)
		entity.velocity.y = -jump_force
