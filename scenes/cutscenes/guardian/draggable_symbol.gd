extends TextureRect

@export var symbol_name: String = "circle"

# Questa funzione integrata in Godot scatta in automatico quando clicchi e trascini
func _get_drag_data(at_position: Vector2) -> Variant:
	
	# 1. Creiamo un'anteprima visiva "fantasma" che segue il mouse
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size # Usa la stessa dimensione originale
	preview.modulate.a = 0.6 # Rendiamola un po' trasparente
	
	# Centriamo l'anteprima sul cursore
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2 
	set_drag_preview(control)
	
	# 2. Restituiamo il "pacchetto" di dati nascosto che stiamo trascinando
	return {
		"type": "marker_symbol",
		"symbol": symbol_name
	}
