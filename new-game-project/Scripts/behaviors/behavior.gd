class_name Behavior

extends Node2D

var entity: Entity
var active: bool

func set_entity(_entity: Entity):
	entity = _entity

func set_active(_active: bool):
	active = _active
