extends Node2D




func _on_player_1_player_died() -> void:
	$gameoverscreen.show()
	get_tree().paused = true 
	
