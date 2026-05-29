extends CanvasLayer

signal verification_requested(is_successful: bool)

@onready var drop_zone = %DropZone
@onready var run_button = %RunCodeButton
@onready var reset_button = %ResetButton
@onready var audio_player = $AudioStreamPlayer

@onready var crystal_ball_image = %CrystalBallImage

# CodeEditor è un CanvasLayer, quindi va animato con offset, non con position
@onready var code_editor: CanvasLayer = $CrystalBallImage/CodeEditor
@onready var code_editor_panel: Control = $CrystalBallImage/CodeEditor/MarginContainer/MainPanel

const DEFAULT_TEXT = "[i]Visual_prophecy.magic[/i]"
const CORRECT_ANSWER = "A dragon flying over a burning castle"

# Audio di default del segnaposto
var default_audio: AudioStream = preload("res://assets/audio/AltTextMinigame/voice_Visual_prophecy.magic.mp3")

var current_dropped_text: String = DEFAULT_TEXT
var current_dropped_audio: AudioStream = null

# --- ANIMAZIONE INTRO CODE EDITOR ---
const EDITOR_SLIDE_DISTANCE: float = 520.0
const EDITOR_SLIDE_DURATION: float = 0.35
const EDITOR_FADE_DURATION: float = 0.25

var editor_start_offset: Vector2
var editor_intro_played: bool = false
var is_showing_editor_intro: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Salviamo SOLO l'offset iniziale del CodeEditor.
	# Non tocchiamo CrystalBallImage.
	editor_start_offset = code_editor.offset
	
	# All'inizio nascondiamo solo l'editor, non tutta la crystal ball.
	code_editor.visible = false
	code_editor_panel.modulate.a = 0.0
	
	_set_buttons_enabled(false)
	
	# Impostiamo l'audio iniziale al file placeholder
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


# --- FUNZIONE CHIAMATA DALLA CUTSCENE ---
func show_ui() -> void:
	if is_showing_editor_intro:
		return
	
	# Mostriamo il CanvasLayer principale, ma non lo animiamo.
	show()
	
	if not editor_intro_played:
		await _show_code_editor_intro()
		editor_intro_played = true
	else:
		code_editor.offset = editor_start_offset
		code_editor.visible = true
		code_editor_panel.modulate.a = 1.0
		_set_buttons_enabled(true)
	
	# [TELEMETRIA] Inizio misurazione del Time on Task per il Livello 3
	if has_node("/root/TelemetryManager"):
		TelemetryManager.start_level("L3")


func _show_code_editor_intro() -> void:
	is_showing_editor_intro = true
	
	_set_buttons_enabled(false)
	
	code_editor.visible = true
	code_editor_panel.modulate.a = 0.0
	
	# Parte solo il CodeEditor da sinistra.
	code_editor.offset = Vector2(
		editor_start_offset.x - EDITOR_SLIDE_DISTANCE,
		editor_start_offset.y
	)
	
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	# Slide del CodeEditor verso la sua posizione originale.
	tween.tween_property(
		code_editor,
		"offset:x",
		editor_start_offset.x,
		EDITOR_SLIDE_DURATION
	)
	
	# Fade-in solo del pannello dell'editor.
	tween.tween_property(
		code_editor_panel,
		"modulate:a",
		1.0,
		EDITOR_FADE_DURATION
	)
	
	await tween.finished
	
	# Sicurezza: forziamo lo stato finale corretto.
	code_editor.offset = editor_start_offset
	code_editor_panel.modulate.a = 1.0
	
	_set_buttons_enabled(true)
	is_showing_editor_intro = false


func _set_buttons_enabled(enabled: bool) -> void:
	if is_instance_valid(run_button):
		run_button.disabled = not enabled
	
	if is_instance_valid(reset_button):
		reset_button.disabled = not enabled


func _on_option_dropped(text: String, audio: AudioStream) -> void:
	# Rimuoviamo gli "a capo" invisibili dalla stringa
	var cleaned_text = text.replace("\n", "").replace("\r", "")
	
	current_dropped_text = cleaned_text
	current_dropped_audio = audio
	
	_update_drop_zone_ui()


func _update_drop_zone_ui() -> void:
	if drop_zone:
		drop_zone.text = current_dropped_text


func _play_audio(stream: AudioStream) -> void:
	if stream != null:
		audio_player.stream = stream
		audio_player.play()


func _on_reset_pressed() -> void:
	current_dropped_text = DEFAULT_TEXT
	
	# Ripristiniamo l'audio di default quando resettiamo
	current_dropped_audio = default_audio
	
	_update_drop_zone_ui()


func _on_run_pressed() -> void:
	# --- VERIFICA VITTORIA E TELEMETRIA ---
	var is_correct = (current_dropped_text == CORRECT_ANSWER)
	
	if is_correct:
		# [TELEMETRIA] Risoluzione corretta e stop del timer
		if has_node("/root/TelemetryManager"):
			TelemetryManager.end_level("L3")
			var stats = TelemetryManager.stats["L3"]
			print("[TELEMETRIA L3] Completato. Tempo totale: ", snapped(stats["total_time"], 0.1), "s | Tentativi falliti: ", stats["fails"])
	else:
		# [TELEMETRIA] Errore utente registrato
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_fail("L3")
			print("[TELEMETRIA L3] Fallimento registrato. Totale attuale: ", TelemetryManager.stats["L3"]["fails"])

	# Suoniamo l'audio della scelta attuale
	if current_dropped_audio != null:
		_play_audio(current_dropped_audio)
		
		# Aspettiamo che l'audio finisca prima di dire se hai vinto/perso
		await audio_player.finished
	
	# Emettiamo il segnale di vittoria o fallimento alla fine
	verification_requested.emit(is_correct)


# Funzione chiamata dalla Cutscene per cambiare l'immagine al volo
func update_image(new_texture: Texture2D) -> void:
	if crystal_ball_image:
		crystal_ball_image.texture = new_texture
