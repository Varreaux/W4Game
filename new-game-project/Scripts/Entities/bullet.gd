class_name Bullet

extends Hitbox

@export var direction: Vector2
@export var speed: float

func _ready() -> void:
	body_entered.connect(on_body_entered)
	area_entered.connect(on_area_entered)
	
func _physics_process(_delta: float) -> void:
	global_position += direction.normalized() * speed * _delta

func on_body_entered(_body: Node):
	super.on_body_entered(_body)
	call_deferred("queue_free")

func on_area_entered(_area: Area2D):
	super.on_area_entered(_area)
	if _area in ignores: return
	call_deferred("queue_free")
