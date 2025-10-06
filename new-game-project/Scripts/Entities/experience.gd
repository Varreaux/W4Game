extends RigidBody2D

var lifetime = 0

func _ready() -> void:
	var _dir := randf_range(0, PI)
	var _speed := randf_range(100, 150)
	var _vec = Vector2.from_angle(_dir)
	linear_velocity = _vec * _speed
	body_entered.connect(player_entered)

func player_entered(body: Node) -> void:
	if body is Player:
		Player.instance.gain_exp()
		call_deferred("queue_free")

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime > 8:
		modulate = Color(1, 1, 1, 0.5)
	if lifetime > 10: call_deferred("queue_free")
