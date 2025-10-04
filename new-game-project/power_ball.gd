extends Area2D

var behavior
var speed = 300
var direction = Vector2.ZERO

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.name != "Ground" and behavior:
		body.add_child(behavior)
		behavior.owner = body
		queue_free()
