extends Action

@onready var bullet = preload("res://Objects/Entities/bullet.tscn")

var shooting_speed = randf_range(80, 200)

func _ready() -> void:
	cooldown_time = randf_range(0.5, 2)
	
func on_trigger(_bypass_cooldown: bool = false):
	if cooldown_counter > cooldown_time || _bypass_cooldown:
		var _bullet = bullet.instantiate() as Bullet
		_bullet.direction = Vector2.LEFT if entity.get_node("Art").flip_h else Vector2.RIGHT
		_bullet.speed = shooting_speed
		get_tree().root.get_child(0).call_deferred("add_child",_bullet)
		_bullet.global_position = entity.global_position + Vector2.UP * 8
		_bullet.ignores.append(entity.get_node("Hurtbox"))
		cooldown_counter = 0
