extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Connessione fine dialogo globale
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Connessione al nuovo segnale del Balloon per cambiare portrait
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)

# Aggiunto parametro opzionale initial_portrait_path
func start_cutscene(dialogue_res: Resource, title: String = "start", initial_portrait_path: String = "") -> void:
	if dialogue_res == null:
		return
		
	current_resource = dialogue_res
	visible = true
	
	# Se passiamo un'immagine iniziale, la carichiamo (es. Happy)
	if initial_portrait_path != "" and ResourceLoader.exists(initial_portrait_path):
		portrait.texture = load(initial_portrait_path)
	
	get_tree().paused = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		balloon.start(dialogue_res, title)

# Funzione che legge i tag della linea (es: # portrait=res://.../innkeeper_sad.png)
func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		if tag.begins_with("portrait="):
			var path = tag.split("=")[1].strip_edges()
			if ResourceLoader.exists(path):
				portrait.texture = load(path)
			else:
				push_warning("Cutscene: Immagine non trovata al percorso: " + path)

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		_end_cutscene()

func _end_cutscene() -> void:
	get_tree().paused = false
	visible = false
	current_resource = null
	cutscene_finished.emit()
	queue_free()
