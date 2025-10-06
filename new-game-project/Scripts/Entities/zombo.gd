extends Enemy

func _process(_delta: float) -> void:
	$Art.flip_h = get_player_diff().x < 0
	if hp <= 0:
		call_deferred("queue_free")
