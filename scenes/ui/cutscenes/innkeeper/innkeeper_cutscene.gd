extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null # Memorizziamo i dati tecnici del livello

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Connessione fine dialogo globale
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Connessione al segnale del Balloon per cambiare portrait o attivare eventi
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)

# Ora accettiamo anche l'oggetto impairment (es. la risorsa cataratta.tres)
func start_cutscene(dialogue_res: Resource, impairment: ImpairmentData, title: String = "start", initial_portrait_path: String = "") -> void:
	if dialogue_res == null:
		return
		
	current_resource = dialogue_res
	current_impairment = impairment # Salviamo il riferimento per usarlo nei tag
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
		
		# TRIGGER DEBUG WINDOW: Se nel file .dialogue scrivi # show_debug
		if tag == "show_debug" and current_impairment != null:
			if DebugManager: # Verifichiamo che l'Autoload esista
				DebugManager.setup_display(current_impairment)

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		# REGISTRAZIONE SCOPERTA: Prima di chiudere, salviamo il progresso nel manuale
		if current_impairment and DiscoveryManager:
			DiscoveryManager.discover_impairment(current_impairment)
			
		_end_cutscene()

func _end_cutscene() -> void:
	get_tree().paused = false
	visible = false
	current_resource = null
	current_impairment = null
	cutscene_finished.emit()
	queue_free()
