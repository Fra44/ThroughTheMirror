extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null 
var spawned_minigame: Node = null
var wait_for_debug: bool = false


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
		
		# --- CAMBIO RITRATTO / IMMAGINE ---
		if tag.begins_with("portrait="):
			var path: String = tag.split("=")[1].strip_edges()
			
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path)
				portrait.texture = tex
				
				# Se il minigioco è aperto, mandiamo l'immagine anche a lui.
				if spawned_minigame != null and is_instance_valid(spawned_minigame):
					if spawned_minigame.has_method("update_image"):
						spawned_minigame.update_image(tex)
			else:
				push_warning("Cutscene: Immagine non trovata: " + path)
		
		
		# --- DEBUG WINDOW / MIRROR DIAGNOSIS ---
		if tag == "show_debug" and current_impairment != null:
			wait_for_debug = true
		
		
		# --- ATTIVA SHADER LOW VISION ---
		if tag == "activate_shader":
			var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
			
			if shaders.size() > 0:
				shaders[0].toggle_effect(true)
			
			if current_impairment and DiscoveryManager:
				DiscoveryManager.discover_impairment(current_impairment)
		
		
		# --- DISATTIVA SHADER LOW VISION ---
		if tag == "deactivate_shader":
			var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
			
			if shaders.size() > 0:
				shaders[0].toggle_effect(false)
		
		
		# --- CHIUDI MINIGIOCO ---
		if tag == "close_minigame":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				spawned_minigame.queue_free()
				spawned_minigame = null
			
			portrait.visible = true
			
			if has_node("Dim"):
				$Dim.visible = true
		
		
		# --- RITENTA MINIGIOCO DOPO FAIL ---
		if tag == "retry_minigame":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				if spawned_minigame.has_method("prepare_retry"):
					spawned_minigame.prepare_retry()
				else:
					push_warning("HeraldCutscene: il minigioco non ha prepare_retry().")
		
		
		# --- CARICA IL MINIGIOCO SCROLL ---
		if tag == "minigame_menu":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				return
			
			var menu_scene: PackedScene = preload("res://scenes/cutscenes/herald/ScrollMinigame.tscn")
			var menu_instance: Node = menu_scene.instantiate()
			
			get_tree().root.add_child(menu_instance)
			spawned_minigame = menu_instance
			
			# Passiamo l'immagine attuale immediatamente.
			if spawned_minigame.has_method("update_image") and portrait.texture != null:
				spawned_minigame.update_image(portrait.texture)
			
			if spawned_minigame.has_signal("verification_requested"):
				spawned_minigame.verification_requested.connect(_on_minigame_verification)
			
			portrait.visible = false
			
			if has_node("Dim"):
				$Dim.visible = false


func _on_minigame_verification(is_successful: bool) -> void:
	if is_successful:
		if is_instance_valid(balloon):
			balloon.start(current_resource, "win_reaction")
	else:
		if is_instance_valid(balloon):
			balloon.start(current_resource, "fail_reaction")


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		
		# Se il minigioco è ancora aperto, la cutscene non deve finire.
		if spawned_minigame != null and is_instance_valid(spawned_minigame):
			get_tree().paused = true
			
			# Manteniamo la tua logica originale:
			# dopo show_debug, prepara la finestra debug e poi mostra eventualmente la UI del minigioco.
			if wait_for_debug and DebugManager:
				DebugManager.setup_display(current_impairment)
				wait_for_debug = false 
				
				await get_tree().create_timer(1.0).timeout
				
				if spawned_minigame.has_method("show_ui"):
					spawned_minigame.show_ui()
			
			return
		
		_end_cutscene()


func _end_cutscene() -> void:
	if DebugManager and DebugManager.visible:
		DebugManager.hide_display()
	
	if spawned_minigame == null or not is_instance_valid(spawned_minigame):
		get_tree().paused = false
	
	visible = false
	current_resource = null
	current_impairment = null
	cutscene_finished.emit()
	
	# Spegniamo lo shader low vision alla fine.
	var shaders: Array = get_tree().get_nodes_in_group("low_vision_shader")
	
	if shaders.size() > 0:
		shaders[0].toggle_effect(false)
	
	queue_free()
