extends PanelContainer

@onready var label = $MarginContainer/HBoxContainer/Label
@onready var play_button = $MarginContainer/HBoxContainer/PlayAudioButton

# Esportiamo l'audio così puoi trascinare un file .wav o .ogg diverso per ogni pannello dall'Inspector
@export var audio_stream: AudioStream 

signal play_requested(stream: AudioStream)

func _ready() -> void:
	# Quando clicchi l'icona dell'audio, diciamo al main script di suonarlo
	play_button.pressed.connect(func(): play_requested.emit(audio_stream))

func _get_drag_data(at_position: Vector2) -> Variant:
	# Questo è il "pacchetto" di dati che ci portiamo dietro col mouse
	var data = {
		"text": label.text,
		"audio": audio_stream
	}
	
	# Creiamo un'anteprima visiva di quello che stiamo trascinando
	var preview_label = Label.new()
	preview_label.text = label.text
	preview_label.add_theme_color_override("font_color", Color("a8a8a8")) # Colore del tuo testo
	
	var preview_panel = PanelContainer.new()
	preview_panel.add_child(preview_label)
	preview_panel.modulate.a = 0.7 # Rendiamolo un po' trasparente mentre lo trascini
	
	# Usiamo un Control fittizio per centrare l'anteprima sotto il mouse
	var control = Control.new()
	control.add_child(preview_panel)
	preview_panel.position = -preview_panel.size / 2
	
	set_drag_preview(control)
	
	return data
