class_name Action

extends Node2D

@export var cooldown_time: float

var cooldown_counter: float = 0
var entity: Entity
var active: bool

func on_trigger(_bypass_cooldown: bool = false):
	pass

func _process(delta: float) -> void:
	cooldown_counter += delta
	
func set_entity(_entity: Entity):
	entity = _entity

func set_active(_active: bool):
	active = _active
