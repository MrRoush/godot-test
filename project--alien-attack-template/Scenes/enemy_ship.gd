extends Area2D

@export var speed: int = 250

func _physics_process(delta: float) -> void:
	global_position.x -= speed * delta

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		$hit.play()
		body.health -= 5
		queue_free()
		


func _on_area_entered(area: Area2D) -> void:
	if area is Rocket: 
		$hit.play()
		await $hit.finished
		get_tree().root.find_child("Player1", true, false).score += 5
	if $hit.finished:
		area.queue_free()
		queue_free()
