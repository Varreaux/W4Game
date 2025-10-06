extends Action

@onready var slash = preload("res://Objects/Entities/slash.tscn")
@export_flags_2d_physics var collision_mask_player
@export_flags_2d_physics var collision_mask_enemy

func _ready() -> void:
	cooldown_time = randf_range(0.5, 2)
	
func on_trigger(_bypass_cooldown: bool = false):
	if cooldown_counter > cooldown_time || _bypass_cooldown:
		var _slash = slash.instantiate() as AnimatedHitbox
		_slash.get_node("Art").flip_h = entity.get_node("Art").flip_h
		get_tree().root.get_child(0).call_deferred("add_child",_slash)
		var _y = -8
		var _x = -15 if entity.get_node("Art").flip_h else 15
		_slash.global_position = entity.global_position + Vector2(_x, _y)
		_slash.ignores.append(entity.get_node("Hurtbox"))
		if entity is Enemy:
			_slash.collision_mask &= ~collision_mask_enemy
		cooldown_counter = 0
