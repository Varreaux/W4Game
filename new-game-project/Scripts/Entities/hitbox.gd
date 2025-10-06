class_name Hitbox

extends Area2D

@export var damage: float
var ignores: Array[Area2D]

func _ready() -> void:
	body_entered.connect(on_body_entered)
	area_entered.connect(on_area_entered)

func on_body_entered(_body: Node):
	pass

func on_area_entered(_area: Area2D):
	if _area in ignores: return
	_area.get_parent().hurt(self)
