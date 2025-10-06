extends Node2D

var open: bool = false

func _on_player_detector_body_entered(_body: Node2D) -> void:
	if not open:
		open = true
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
		$Ladder.frame = 1
		if _body.global_position > global_position:
			$Ladder.flip_h = true
