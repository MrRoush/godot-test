extends Area2D
class_name Rocket 

@export var speed: int = 10

func _physics_process(delta: float) -> void:
	# Delat makes the sprite move at a constant speed no matter the refresh rate.
	global_position.x += speed * delta
	
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()



	
