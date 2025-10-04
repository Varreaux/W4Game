extends Node
class_name ExplodeOnWall


func _physics_process(_delta):
	var entity = get_parent()
	if entity.is_on_wall():
		entity.queue_free()
		print("BOOM!")
