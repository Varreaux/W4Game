class_name Slime
extends Enemy

@onready var slime_object = preload("res://Objects/Entities/slime.tscn")
@export var size: float = 1

func _ready():
	super._ready()
	global_scale = Vector2.ONE * size
	max_health = size
	hp = size
	
func _process(_delta: float) -> void:
	$Art.flip_h = get_player_diff().x < 0
	if hp <= 0:
		if size > 0.26:
			var _slime = self.duplicate()
			if(_slime != null):
				_slime.size = size/2
				_slime.hp = max_health-1
				_slime.load_behaviors = false
				_slime.assign_behaviors_to_self = true
				get_parent().add_child(_slime)
				_slime.global_position = global_position + Vector2.LEFT * size * 20
			
			_slime = self.duplicate()
			if(_slime != null):
				_slime.size = size/2
				_slime.hp = max_health-1
				_slime.load_behaviors = false
				_slime.assign_behaviors_to_self = true
				get_parent().add_child(_slime)
				_slime.global_position = global_position + Vector2.RIGHT * size * 20
		else:
			var _exp = exp_item.instantiate()
			get_parent().add_child(_exp)
			_exp.global_position = global_position
		call_deferred("queue_free")
