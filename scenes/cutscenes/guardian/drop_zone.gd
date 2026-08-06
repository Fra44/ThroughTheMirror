extends RichTextLabel

@export var ray_color: String = "green" 

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "marker_symbol"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# 1. Scriviamo il testo nella Label
	text = " " + data["symbol"] + ""
	
	# --- LOGICA DEI COLORI ---
	var ui_color: Color
	if ray_color == "red":
		ui_color = Color("ff4d4d")
	else:
		ui_color = Color("4dff4d")
		
	# Applichiamo il colore scelto al testo
	add_theme_color_override("default_color", ui_color) 
	
	# OUTLINE NERA:
	# 1. Impostiamo il colore del bordo a nero
	add_theme_color_override("font_outline_color", Color.BLACK)
	
	# 2. Impostiamo lo spessore del bordo
	add_theme_constant_override("outline_size", 2)
	# -------------------------------
	
	# 2. Avvisiamo lo script principale (RaysMinigame)
	if owner.has_method("update_symbol_for_ray"):
		owner.update_symbol_for_ray(ray_color, data["symbol"])
		
# Riporta la casella allo stato iniziale
func reset() -> void:
	text = "[i] drag symbol here[/i]"
	remove_theme_color_override("font_outline_color")
	remove_theme_constant_override("outline_size")
	add_theme_color_override("default_color", Color.BLACK)
