class_name Entity

extends CharacterBody2D

func add_behavior(_behavior: Behavior) -> void:
	_behavior.get_parent().remove_child(_behavior)
	get_node("Behaviors").add_child(_behavior)
	_behavior.owner = self
	_behavior.entity = self
	_behavior.active = true
