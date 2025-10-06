class_name Entity

extends CharacterBody2D

@export var gravity: float
@export var max_health: int

var hp

@onready var hp_bar = $HPBar

signal was_hurt

func _ready() -> void:
	hp = max_health
	hp_bar.visible = false

func add_behavior(_behavior: Behavior) -> void:
	_behavior.get_parent().remove_child(_behavior)
	get_node("Behaviors").add_child(_behavior)
	_behavior.owner = self
	_behavior.set_entity(self)
	_behavior.set_active(true)

func hurt(_hb: Hitbox):
	hp -= _hb.damage
	hp_bar.visible = true
	hp_bar.value = hp / max_health
	emit_signal("was_hurt")
