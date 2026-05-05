extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

func _ready() -> void:
	# In Godot 4 si usa process_mode e la costante PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Assicurarsi che il balloon processi durante la pausa
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		
	visible = false
	
func start_cutscene(dialogue_res: Resource, title: String = "start") -> void:
	visible = true
	
	# Caricamento del portrait
	var tex_path := "res://scenes/ui/cutscenes/images/conversation_innkeeper_sad.png"
	if ResourceLoader.exists(tex_path):
		portrait.texture = load(tex_path)
	
	# Metti in pausa il mondo
	get_tree().paused = true
	
	# Avvia il dialogo
	if is_instance_valid(balloon):
		balloon.start(dialogue_res, title)
		
		# Aspetta che il balloon finisca (diventi invisibile)
		while is_instance_valid(balloon) and balloon.visible:
			await get_tree().process_frame
			
	_end_cutscene()

func _end_cutscene() -> void:
	get_tree().paused = false
	visible = false
	cutscene_finished.emit() # Sintassi moderna di Godot 4 per i segnali
	# ATTENZIONE: queue_free() eliminerà questa scena definitivamente.
	# Se vuoi riutilizzarla per altri dialoghi, NON metterlo.
