extends Area2D

@export var speed: int = 100

func _physics_process(delta: float) -> void:
	global_position.x -= speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is rocket:
		get_tree().root.find_child("Player", true, false).score += 5
		if $Hit.finished:
			queue_free()
			area.queue_free()
	
func _on_body_entered(body: Node2D) -> void:
	if body is player:
		$Hit.play()
		body.health -= 5
		queue_free()
	if body.health <= 0:
		body.queue_free()
