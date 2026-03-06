extends Node2D

@export var enemy_sprite: PackedScene

func _on_timer_timeout() -> void:
	var spawn_point_array = $Spawnpoint.get_children()
	print(spawn_point_array)
	var random_spawn_location = spawn_point_array.pick_random()
	print(random_spawn_location)
	
	var new_enemy = enemy_sprite.instantiate()
	print(new_enemy)
	new_enemy.global_position = random_spawn_location.global_position
	print(new_enemy.global_position)
	get_tree().root.add_child(new_enemy, true)
