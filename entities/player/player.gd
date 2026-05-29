extends CharacterBody2D

@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Velocità regolabile dall'Inspector
@export var speed: float = 100.0
@export var run_speed: float = 200.0

var is_talking: bool = false
var last_direction: String = "down"


func _ready() -> void:
	add_to_group("Player")
	animated_sprite.play("idle_down")


func _physics_process(_delta: float) -> void:
	# 1. Blocco movimento durante i dialoghi
	if is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
		play_idle_animation()
		return
	
	# 2. Ottieni la direzione dai tasti
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 3. Controlla se il player sta correndo
	var is_running := Input.is_action_pressed("run")
	var current_speed := run_speed if is_running else speed
	
	# 4. Applica la velocità
	velocity = direction * current_speed
	
	# 5. Muovi il corpo
	move_and_slide()
	
	# 6. Aggiorna animazione
	update_animation(direction, is_running)
	
	# 7. Aggiorna direzione dell'ActionableFinder
	update_actionable_direction(direction)


func update_animation(direction: Vector2, is_running: bool) -> void:
	if direction == Vector2.ZERO:
		play_idle_animation()
		return
	
	last_direction = get_direction_name(direction)
	
	if is_running:
		animated_sprite.play("run_" + last_direction)
	else:
		animated_sprite.play("walk_" + last_direction)


func play_idle_animation() -> void:
	animated_sprite.play("idle_" + last_direction)


func get_direction_name(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "right"
		else:
			return "left"
	else:
		if direction.y > 0:
			return "down"
		else:
			return "up"


func update_actionable_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			$Direction.rotation_degrees = 90
		else:
			$Direction.rotation_degrees = -90
	else:
		if direction.y > 0:
			$Direction.rotation_degrees = 180
		else:
			$Direction.rotation_degrees = 0


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if is_talking:
			return
		
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()
			return
