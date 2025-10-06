extends Enemy

func _process(_delta: float) -> void:
	$Art.flip_h = get_player_diff().x < 0
	if hp <= 0:
		for i in range(randi_range(2, 3)):
			var _exp = exp_item.instantiate()
			get_parent().add_child(_exp)
			_exp.global_position = global_position
		call_deferred("queue_free")
