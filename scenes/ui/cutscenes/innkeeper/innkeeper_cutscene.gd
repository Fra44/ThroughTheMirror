extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null # Memorizziamo i dati tecnici del livello
var spawned_minigame: Node = null

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
			if DebugManager:
				DebugManager.setup_display(current_impairment)
				
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
		print("Cutscene: Vinto! Avvio dialogo di successo...")
		# Distruggiamo il minigioco
		spawned_minigame.queue_free()
		spawned_minigame = null 
		
		# Ripristiniamo la UI della cutscene
		portrait.visible = true 
		if has_node("Dim"):
			$Dim.visible = true
		
		# Facciamo partire il dialogo finale
		if is_instance_valid(balloon):
			balloon.start(current_resource, "win_reaction")
			
	else:
		print("Cutscene: Fallito! Avvio dialogo di errore...")
		# Facciamo apparire SOLO il balloon (il minigioco resta aperto dietro)
		if is_instance_valid(balloon):
			balloon.start(current_resource, "fail_reaction")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		# EVITIAMO CHE LA CUTSCENE SI CHIUDA SE IL MINIGIOCO È ATTIVO
		if spawned_minigame != null and is_instance_valid(spawned_minigame):
			print("Cutscene: Dialogo interrotto per minigioco. Forzo la pausa per non far muovere il player.")
			get_tree().paused = true
			return
			
		# REGISTRAZIONE SCOPERTA (Fine VERA della cutscene)
		if current_impairment and DiscoveryManager:
			DiscoveryManager.discover_impairment(current_impairment)
			
		_end_cutscene()

func _end_cutscene() -> void:
	if spawned_minigame == null or not is_instance_valid(spawned_minigame):
		get_tree().paused = false
	visible = false
	current_resource = null
	current_impairment = null
	cutscene_finished.emit()
	queue_free()
