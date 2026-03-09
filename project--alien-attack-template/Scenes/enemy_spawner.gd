extends Node2D

@export var enemy_sprite: PackedScene
@export var enemy_sprite2: PackedScene


func _on_timer_timeout() -> void:
	var spawn_position_array = $SpawnPoint.get_children()
	var random_spawn_point = spawn_position_array.pick_random()
	
	var enemies = [enemy_sprite, enemy_sprite2]
	var random_enemy = enemies.pick_random()
	var new_enemy = enemy_sprite.instantiate()
	new_enemy.global_position = random_spawn_point.global_position
	get_tree().root.add_child(new_enemy, true)
