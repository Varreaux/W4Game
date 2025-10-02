extends Node
class_name ShootBullets

var shoot_timer = 0.0

func _ready():
	print("ShootBullets is running!")


func _process(delta):
	shoot_timer += delta
	if shoot_timer >= 2.0:
		shoot_timer = 0.0
		shoot()
		
func shoot():
	print("Pew! (shooting bullet)")  # replace this with real bullet code later
