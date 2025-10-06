class_name AnimatedHitbox

extends Hitbox

@onready var anim = $AnimationPlayer

func _ready() -> void:
	body_entered.connect(on_body_entered)
	area_entered.connect(on_area_entered)
	anim.animation_finished.connect(anim_end)
	
func anim_end(_anim_name: String) -> void:
	call_deferred("queue_free")
