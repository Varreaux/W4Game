class_name Rock

extends Entity

const ACTIVE_RANGE = 300


func _ready():
	super._ready()


func _physics_process(delta):
	if get_player_range() > ACTIVE_RANGE: return
	
	velocity.y += gravity * delta
	move_and_slide()

func _process(_delta: float) -> void:
	if hp <= 0:
		call_deferred("queue_free")

func get_player_range() -> float:
	return (Player.instance.global_position - global_position).length()

func get_player_diff() -> Vector2:
	return (Player.instance.global_position - global_position)
