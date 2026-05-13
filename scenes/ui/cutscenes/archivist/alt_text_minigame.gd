extends CanvasLayer

signal verification_requested(is_successful: bool)

@onready var drop_zone = %DropZone
@onready var run_button = %RunCodeButton
@onready var reset_button = %ResetButton
@onready var audio_player = $AudioStreamPlayer

const DEFAULT_TEXT = "[i]Visual_prophecy.magic[/i]"
const CORRECT_ANSWER = "A dragon flying over a burning castle" 

# --- NUOVO: Precarichiamo l'audio di default del segnaposto ---
var default_audio: AudioStream = preload("res://assets/audio/AltTextMinigame/voice_Visual_prophecy.magic.mp3")

var current_dropped_text: String = DEFAULT_TEXT
var current_dropped_audio: AudioStream = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# --- NUOVO: Impostiamo l'audio iniziale al file caricato sopra ---
	current_dropped_audio = default_audio
	
	run_button.pressed.connect(_on_run_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Colleghiamo il segnale del DropZone
	drop_zone.option_dropped.connect(_on_option_dropped)
	
	# Troviamo tutti i pannellini delle opzioni e colleghiamo il loro bottoncino audio
	var options_container = $CrystalBallImage/CodeEditor/MarginContainer/MainPanel/Background/Padding/MainVBox/OptionsPanel/OptionsVBox/CenterContainer/GridContainer
	for option_panel in options_container.get_children():
		if option_panel.has_signal("play_requested"):
			option_panel.play_requested.connect(_play_audio)
			
	_update_drop_zone_ui()

func _on_option_dropped(text: String, audio: AudioStream) -> void:
	# Rimuoviamo gli "a capo" invisibili (\n e \r) dalla stringa
	var cleaned_text = text.replace("\n", "").replace("\r", "")
	
	current_dropped_text = cleaned_text
	current_dropped_audio = audio
	_update_drop_zone_ui()

func _update_drop_zone_ui() -> void:
	if drop_zone:
		# --- NUOVO: Aggiungiamo lo spazio iniziale SOLO per la visualizzazione ---
		# current_dropped_text rimane intatto dietro le quinte, così non rompiamo il controllo vittoria!
		drop_zone.text = current_dropped_text

func _play_audio(stream: AudioStream) -> void:
	if stream != null:
		audio_player.stream = stream
		audio_player.play()

func _on_reset_pressed() -> void:
	current_dropped_text = DEFAULT_TEXT
	# --- NUOVO: Ripristiniamo l'audio di default quando resettiamo ---
	current_dropped_audio = default_audio 
	_update_drop_zone_ui()

func _on_run_pressed() -> void:
	# Suoniamo l'audio della scelta attuale
	if current_dropped_audio != null:
		_play_audio(current_dropped_audio)
		
		# Aspettiamo che l'audio finisca prima di dire se hai vinto/perso
		await audio_player.finished 
	
	# Verifica vittoria
	if current_dropped_text == CORRECT_ANSWER:
		verification_requested.emit(true)
	else:
		verification_requested.emit(false)
# Funzione chiamata dalla Cutscene per cambiare l'immagine al volo!
func update_image(new_texture: Texture2D) -> void:
	if %CrystalBallImage:
		%CrystalBallImage.texture = new_texture
