extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null 
var spawned_minigame: Node = null
var wait_for_debug: bool = false
var pending_retry_minigame: bool = false
var trigger_quiz_at_end: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)


func start_cutscene(
	dialogue_res: Resource,
	impairment: ImpairmentData,
	title: String = "start",
	initial_portrait_path: String = ""
) -> void:
	if dialogue_res == null:
		return
	
	current_resource = dialogue_res
	current_impairment = impairment 
	visible = true
	
	if initial_portrait_path != "" and ResourceLoader.exists(initial_portrait_path):
		portrait.texture = load(initial_portrait_path)
	
	get_tree().paused = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		balloon.start(dialogue_res, title)


func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		
		if tag.begins_with("portrait="):
			var path: String = tag.split("=")[1].strip_edges()
			
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path)
				portrait.texture = tex
				
				if spawned_minigame != null and is_instance_valid(spawned_minigame):
					if spawned_minigame.has_method("update_image"):
						spawned_minigame.update_image(tex)
			else:
				push_warning("Cutscene: Immagine non trovata: " + path)
		
		
		if tag == "show_debug" and current_impairment != null:
			wait_for_debug = true
		
		
		if tag == "activate_shader":
			_activate_low_vision_shader()
		
		
		if tag == "deactivate_shader":
			_deactivate_low_vision_shader()
		
		
		if tag == "close_minigame":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				spawned_minigame.queue_free()
				spawned_minigame = null
			
			portrait.visible = true
			
			if has_node("Dim"):
				$Dim.visible = true
		
		
		if tag == "retry_minigame":
			pending_retry_minigame = true
		
		
		if tag == "minigame_menu":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				return
			
			var menu_scene: PackedScene = preload("res://scenes/cutscenes/herald/ScrollMinigame.tscn")
			var menu_instance: Node = menu_scene.instantiate()
			
			get_tree().root.add_child(menu_instance)
			spawned_minigame = menu_instance
			
			if spawned_minigame.has_method("update_image") and portrait.texture != null:
				spawned_minigame.update_image(portrait.texture)
			
			if spawned_minigame.has_signal("verification_requested"):
				spawned_minigame.verification_requested.connect(_on_minigame_verification)
			
			if spawned_minigame.has_signal("shader_activation_requested"):
				spawned_minigame.shader_activation_requested.connect(_on_minigame_shader_activation_requested)
			
			if spawned_minigame.has_signal("dialogue_step_requested"):
				spawned_minigame.dialogue_step_requested.connect(_on_minigame_dialogue_step_requested)
			
			if spawned_minigame.has_signal("debug_window_requested"):
				spawned_minigame.debug_window_requested.connect(_on_minigame_debug_window_requested)
			
			portrait.visible = false
			
			if has_node("Dim"):
				$Dim.visible = false


func _activate_low_vision_shader() -> void:
	var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
	
	if shaders.size() > 0:
		shaders[0].toggle_effect(true)
	
	if current_impairment and DiscoveryManager:
		DiscoveryManager.discover_impairment(current_impairment)


func _deactivate_low_vision_shader() -> void:
	var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
	
	if shaders.size() > 0:
		shaders[0].toggle_effect(false)


func _on_minigame_shader_activation_requested() -> void:
	_activate_low_vision_shader()


func _on_minigame_dialogue_step_requested(title: String) -> void:
	if is_instance_valid(balloon):
		balloon.start(current_resource, title)


func _on_minigame_verification(is_successful: bool) -> void:
	if is_successful:
		trigger_quiz_at_end = true # <--- NUOVO: Ci ricordiamo che ha vinto!
		if is_instance_valid(balloon):
			balloon.start(current_resource, "win_reaction")
	else:
		if is_instance_valid(balloon):
			balloon.start(current_resource, "fail_reaction")


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		
		if spawned_minigame != null and is_instance_valid(spawned_minigame):
			get_tree().paused = true
			
			if spawned_minigame.has_method("show_ui"):
				spawned_minigame.show_ui()
			
			if pending_retry_minigame:
				pending_retry_minigame = false
				
				if spawned_minigame.has_method("prepare_retry"):
					spawned_minigame.prepare_retry()
			
			if spawned_minigame.has_method("is_waiting_for_dialogue_step"):
				if spawned_minigame.is_waiting_for_dialogue_step():
					if spawned_minigame.has_method("notify_dialogue_step_finished"):
						spawned_minigame.notify_dialogue_step_finished()
			
			return
		
		_end_cutscene()

func _on_minigame_debug_window_requested() -> void:
	if wait_for_debug and DebugManager:
		DebugManager.setup_display(current_impairment)
		wait_for_debug = false

func _end_cutscene() -> void:
	if DebugManager and DebugManager.visible:
		DebugManager.hide_display()
	
	if spawned_minigame == null or not is_instance_valid(spawned_minigame):
		get_tree().paused = false
	
	visible = false # Nasconde l'UI della cutscene (mostrando l'Overworld)
	current_resource = null
	current_impairment = null
	cutscene_finished.emit()
	
	var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
	if shaders.size() > 0:
		shaders[0].toggle_effect(false)
	
	# ---> NUOVO: Decidiamo se distruggere la cutscene o avviare il finale
	if trigger_quiz_at_end:
		_play_ending_transition()
	else:
		queue_free()

func _play_ending_transition() -> void:
	# 1. Creiamo un rettangolo nero che copre tutto lo schermo
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100 # Abbastanza alto da coprire l'overworld
	get_tree().root.add_child(fade_layer)
	
	var black_rect = ColorRect.new()
	black_rect.color = Color(0, 0, 0, 0) # Inizia trasparente
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(black_rect)
	
	# 2. Creiamo l'animazione (Fade Out)
	var tween = create_tween()
	# Impostiamo su PROCESS_ALWAYS così funziona anche se il gioco ha strane pause
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	# Sfuma verso il nero (alpha 1.0) in 2 secondi
	tween.tween_property(black_rect, "color:a", 1.0, 2.0) 
	
	await tween.finished
	
	# 3. Ora che è tutto nero, cambiamo scena!
	get_tree().change_scene_to_file("res://scenes/reflection/ReflectionQuiz.tscn")
	
	# 4. Pulizia finale
	fade_layer.queue_free()
	queue_free()
