extends Node
class_name JumpOnGround 

func _process(_delta):
	var entity = get_parent()
	if entity.is_on_floor():
		var jump_force = randf_range(200, 300)
		entity.velocity.y = -jump_force
