extends Node2D

signal level_changed(level_path: String)

@export_file("*.tscn") var initial_level_path: String = "res://scenes/world/level_0.tscn"

@onready var current_level_container: Node = $CurrentLevel
@onready var player: Node2D = $Actors/Player

# Riferimento al sipario nero
@onready var transition_rect: ColorRect = $TransitionLayer/ColorRect

var current_level_instance: Node = null
var is_transitioning: bool = false # Sicurezza anti-spam


func _ready() -> void:
	if transition_rect:
		transition_rect.modulate.a = 0.0
	
	if not initial_level_path.is_empty():
		change_level(initial_level_path, &"Default")
		
	var hud_scene = preload("res://ui/hud/hud.tscn")
	var hud_instance = hud_scene.instantiate()
	add_child(hud_instance)


func change_level(path: String, spawn_id: StringName = &"") -> void:
	if path.is_empty():
		push_error("change_level called with an empty path")
		return

	# Se stiamo già cambiando livello, blocchiamo richieste duplicate
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Blocchiamo il player anche da Main, per sicurezza
	_set_player_movement_locked(true)

	var packed_scene := load(path) as PackedScene
	if packed_scene == null:
		push_error("Failed to load level scene: %s" % path)
		is_transitioning = false
		_set_player_movement_locked(false)
		return

	# --- 1. FADE IN: schermo nero ---
	if transition_rect:
		var tween_in = create_tween()
		tween_in.tween_property(transition_rect, "modulate:a", 1.0, 0.25)
		await tween_in.finished
	
	await get_tree().process_frame

	# --- 2. LOGICA DI TELETRASPORTO AL BUIO ---
	var next_level := packed_scene.instantiate()

	if spawn_id != StringName():
		var spawn_points_node = next_level.get_node_or_null("SpawnPoints")
		
		if spawn_points_node != null:
			var spawn = spawn_points_node.get_node_or_null(String(spawn_id))
			
			if spawn != null:
				var destination = spawn.global_position
				player.global_position = destination
				
				var cam = get_tree().get_first_node_in_group("MainCamera")
				
				if cam:
					var was_smoothing = cam.position_smoothing_enabled
					cam.position_smoothing_enabled = false
					cam.global_position = destination
					cam.reset_smoothing()
					cam.force_update_scroll()
					cam.position_smoothing_enabled = was_smoothing

	if current_level_instance != null and is_instance_valid(current_level_instance):
		current_level_container.remove_child(current_level_instance)
		current_level_instance.queue_free()

	current_level_container.add_child(next_level)
	current_level_instance = next_level

	level_changed.emit(path)
	
	# Aspettiamo un attimo per assicurarci che Godot abbia caricato il nuovo livello
	await get_tree().create_timer(0.1).timeout

	# --- 3. FADE OUT: torna la luce ---
	if transition_rect:
		var tween_out = create_tween()
		tween_out.tween_property(transition_rect, "modulate:a", 0.0, 0.25)
		await tween_out.finished

	# Sblocco finale
	_set_player_movement_locked(false)
	is_transitioning = false


func _set_player_movement_locked(locked: bool) -> void:
	if not is_instance_valid(player):
		return
	
	if "is_talking" in player:
		player.is_talking = locked
	
	if "velocity" in player:
		player.velocity = Vector2.ZERO
