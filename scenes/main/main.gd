extends Node2D

signal level_changed(level_path: String)

@export_file("*.tscn") var initial_level_path: String = "res://scenes/world/level_0.tscn"

@onready var current_level_container: Node = $CurrentLevel
@onready var player: Node2D = $Actors/Player

# Riferimento al sipario nero
@onready var transition_rect: ColorRect = $TransitionLayer/ColorRect

var current_level_instance: Node = null
var is_transitioning: bool = false

# Serve solo per distinguere il primissimo caricamento dai cambi livello normali
var is_first_load: bool = true


func _ready() -> void:
	# Fondamentale: la scena main deve partire già completamente nera.
	# Così Godot non mostra HUD/player/livello per un frame prima del caricamento.
	if transition_rect:
		transition_rect.visible = true
		transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_rect.modulate.a = 1.0
	
	# Carichiamo il primo livello mentre lo schermo è già nero.
	if not initial_level_path.is_empty():
		await change_level(initial_level_path, &"Default", true)
	
	# Creiamo l'HUD mentre lo schermo è ancora nero.
	var hud_scene = preload("res://ui/hud/hud.tscn")
	var hud_instance = hud_scene.instantiate()
	add_child(hud_instance)
	
	# Aspettiamo un frame, così HUD, livello, player e camera hanno tempo
	# di stabilizzarsi prima di mostrare qualcosa.
	await get_tree().process_frame
	
	# Fade-in iniziale lento della schermata completa.
	if transition_rect:
		var startup_tween := create_tween()
		startup_tween.tween_property(transition_rect, "modulate:a", 0.0, 5.0)
		await startup_tween.finished
	
	is_first_load = false


func change_level(path: String, spawn_id: StringName = &"", skip_fade_in: bool = false) -> void:
	if path.is_empty():
		push_error("change_level called with an empty path")
		return

	if is_transitioning:
		return
	
	is_transitioning = true
	_set_player_movement_locked(true)

	var packed_scene := load(path) as PackedScene
	if packed_scene == null:
		push_error("Failed to load level scene: %s" % path)
		is_transitioning = false
		_set_player_movement_locked(false)
		return

	# --- 1. FADE IN: schermo nero ---
	# Nel primo caricamento lo schermo è già nero, quindi non serve rifare il fade-in.
	if transition_rect and not skip_fade_in:
		var tween_in := create_tween()
		tween_in.tween_property(transition_rect, "modulate:a", 1.0, 0.25)
		await tween_in.finished
	elif transition_rect:
		transition_rect.modulate.a = 1.0
	
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
	
	await get_tree().create_timer(0.1).timeout

	# --- 3. FADE OUT: torna la luce ---
	# Nel primo caricamento NON lo facciamo qui.
	# Lo gestisce _ready(), dopo aver creato anche l'HUD.
	if transition_rect and not skip_fade_in:
		var tween_out := create_tween()
		tween_out.tween_property(transition_rect, "modulate:a", 0.0, 0.25)
		await tween_out.finished

	_set_player_movement_locked(false)
	is_transitioning = false


func _set_player_movement_locked(locked: bool) -> void:
	if not is_instance_valid(player):
		return
	
	if "is_talking" in player:
		player.is_talking = locked
	
	if "velocity" in player:
		player.velocity = Vector2.ZERO
