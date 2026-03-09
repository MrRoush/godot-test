extends CharacterBody2D

class_name player

@export var speed: int = 300
@export var rocket_scene: PackedScene

@export var health: int = 100
var score: int = 0

signal player_died

func _process(_delta: float) -> void:
	get_tree().root.find_child("ProgressBar", true, false).value = health
	get_tree().root.find_child("Label", true, false).text = "score: " + str(score)
	if health <= 0:
		$shoot/explosion.play()
		player_died.emit()
		queue_free()

func _physics_process(_delta: float) -> void:
	velocity = Vector2(0,0)
	if Input.is_action_pressed("move_down"):
		velocity.y = 300
	if Input.is_action_pressed("move_up"):
		velocity.y = -300
	if Input.is_action_pressed("move_left"):
		velocity.x = -300
	if Input.is_action_pressed("move_right"):
		velocity.x = 300
	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	var screen_size = get_viewport_rect().size
	
	if global_position.x < 0:
		global_position.x = 0
	if global_position.x > screen_size.x/2:
		global_position.x = screen_size.x/2
	if global_position.y < 0:
		global_position.y = 0
	if global_position.y > screen_size.y:
		global_position.y = screen_size.y
		
func shoot():
	print("shoot")
	$shoot.play()
	var new_rocket = rocket_scene.instantiate()
	new_rocket.global_position = $launchpoint.global_position
	$RocketContainer.add_child(new_rocket, true)
	
	
