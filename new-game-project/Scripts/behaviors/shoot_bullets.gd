class_name ShootBullets

extends Behavior

var shoot_timer = 0.0

func _process(delta):
	if not active: return

	shoot_timer += delta
	if shoot_timer >= 2.0:
		shoot_timer = 0.0
		shoot()
		
func shoot():
	print("Pew! (shooting bullet)")  # replace this with real bullet code later
