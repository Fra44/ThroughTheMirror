extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null # Memorizziamo i dati tecnici del livello
var spawned_minigame: Node = null
var wait_for_debug: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Connessione fine dialogo globale
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Connessione al segnale del Balloon per cambiare portrait o attivare eventi
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)

# Ora accettiamo anche l'oggetto impairment
func start_cutscene(dialogue_res: Resource, impairment: ImpairmentData, title: String = "start", initial_portrait_path: String = "") -> void:
	if dialogue_res == null:
		return
		
	current_resource = dialogue_res
	current_impairment = impairment 
	visible = true
	
	# Caricamento portrait iniziale
	if initial_portrait_path != "" and ResourceLoader.exists(initial_portrait_path):
		portrait.texture = load(initial_portrait_path)
	
	get_tree().paused = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		balloon.start(dialogue_res, title)

func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		# Gestione cambio immagine: # portrait=res://...
		if tag.begins_with("portrait="):
			var path = tag.split("=")[1].strip_edges()
			if ResourceLoader.exists(path):
				portrait.texture = load(path)
			else:
				push_warning("Cutscene: Immagine non trovata: " + path)
		
		# TRIGGER DEBUG WINDOW
		if tag == "show_debug" and current_impairment != null:
			wait_for_debug = true
				
		# ACCENSIONE SHADER CATARATTA (o futuri shader)
		if tag == "activate_shader":
			var shaders = get_tree().get_nodes_in_group("cataract_shader")
			if shaders.size() > 0:
				shaders[0].toggle_effect(true)
			
			# NUOVA POSIZIONE: Inseriamo i dati nel manuale ESATTAMENTE ora!
			if current_impairment and DiscoveryManager:
				DiscoveryManager.discover_impairment(current_impairment)
				
		# SPEGNIMENTO SHADER (Nuovo!)
		if tag == "deactivate_shader":
			var shaders = get_tree().get_nodes_in_group("cataract_shader")
			if shaders.size() > 0:
				shaders[0].toggle_effect(false)
				
		# CHIUSURA MINIGIOCO E RITORNO ALLA CUTSCENE (Nuovo!)
		if tag == "close_minigame":
			# Distruggiamo il minigioco
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				spawned_minigame.queue_free()
				spawned_minigame = null
			
			# Ripristiniamo la grafica della cutscene
			portrait.visible = true
			if has_node("Dim"):
				$Dim.visible = true
		
		# GESTIONE MINIGIOCO
		if tag == "minigame_menu":
			var menu_scene = preload("res://scenes/ui/cutscenes/innkeeper/ContrastMinigame.tscn")
			var menu_instance = menu_scene.instantiate()
			get_tree().root.add_child(menu_instance)
			spawned_minigame = menu_instance
			
			# COLLEGA IL NUOVO SEGNALE!
			spawned_minigame.verification_requested.connect(_on_minigame_verification)
			
			portrait.visible = false
			if has_node("Dim"):
				$Dim.visible = false

# FUNZIONE CHIAMATA DAL SEGNALE DI VITTORIA DEL MINIGIOCO
func _on_minigame_verification(is_successful: bool) -> void:
	if is_successful:
		print("Cutscene: Vinto! Avvio dialogo di successo sopra il minigioco...")
		# NON chiudiamo più il minigioco e NON riaccendiamo il portrait qui!
		# Lasciamo che se ne occupino i tag del Dialogue Manager.
		
		if is_instance_valid(balloon):
			balloon.start(current_resource, "win_reaction")
			
	else:
		print("Cutscene: Fallito! Avvio dialogo di errore...")
		if is_instance_valid(balloon):
			balloon.start(current_resource, "fail_reaction")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		# EVITIAMO CHE LA CUTSCENE SI CHIUDA SE IL MINIGIOCO È ATTIVO
		if spawned_minigame != null and is_instance_valid(spawned_minigame):
			get_tree().paused = true
			
			# IL BALLOON SI È APPENA CHIUSO! CONTROLLIAMO SE DOBBIAMO MOSTRARE IL DEBUG
			if wait_for_debug and DebugManager:
				DebugManager.setup_display(current_impairment)
				wait_for_debug = false 
				
				# ---> NUOVA RIGA: MOSTRA I COMANDI DEL MINIGIOCO <---
				if spawned_minigame.has_method("show_ui"):
					spawned_minigame.show_ui()
				
			return
			
		# (Abbiamo rimosso DiscoveryManager da qui!)
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
	
	# SPEGNIAMO LO SHADER DELLA CATARATTA
	var shaders = get_tree().get_nodes_in_group("cataract_shader")
	if shaders.size() > 0:
		shaders[0].toggle_effect(false)
		
	queue_free()
