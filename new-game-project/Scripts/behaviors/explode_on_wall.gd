class_name ExplodeOnWall

extends Behavior

func _physics_process(_delta):
	if not active: return

	if entity.is_on_wall():
		entity.queue_free()
		print("BOOM!")
