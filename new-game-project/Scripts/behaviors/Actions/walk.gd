extends Action

@onready var direction = randi_range(0, 1) *2 -1
@onready var walk_speed = randi_range(20, 50)

func _ready() -> void:
	cooldown_time = randf_range(0.5, 2)
	
func on_trigger(_bypass_cooldown: bool = false):
	entity.velocity.x = walk_speed * direction
	entity.get_node("Art").flip_h = false if direction == 1 else true
	

func _physics_process(_delta: float) -> void:
	if active:
		if entity.is_on_wall():
			direction = -direction
