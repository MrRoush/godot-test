extends Area2D

class_name rocket

@export var speed: int = 30

func _physics_process(delta: float) -> void:
#	global_position.x = global_position + 10
	global_position.x += speed * delta
	


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	queue_free()
