extends Node2D

func _ready() -> void:
	get_tree().paused = false

func _on_player_player_died() -> void:
	$GameOverScreen.show()
	get_tree().paused = true
