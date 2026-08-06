extends RichTextLabel

signal option_dropped(text: String, audio: AudioStream)

# Se il DropZone ha una Label figlia (come sembra dall'immagine), la prendiamo. 
# Se il DropZone è LUI STESSO una Label, usa semplicemente 'text' al posto di 'label.text'
func _ready() -> void:
	pass

# Godot ci chiede: "Posso rilasciare questi dati qui?"
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Diciamo "Sì" solo se i dati sono un Dizionario che contiene la chiave "text"
	return typeof(data) == TYPE_DICTIONARY and data.has("text")

# Godot ci dice: "Dati rilasciati!"
func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Mandiamo un segnale al manager principale con il nuovo testo e audio
	option_dropped.emit(data["text"], data["audio"])
