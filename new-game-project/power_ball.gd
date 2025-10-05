class_name PowerBall

extends RigidBody2D

var behavior: Behavior
var alive_time: float

func _process(delta: float) -> void:
	alive_time += delta
	
func _on_body_entered(body):
	print("Boop")
	if body is Entity and not (body is Player and alive_time < 0.5):
		body.add_behavior(behavior)
		call_deferred("queue_free")
