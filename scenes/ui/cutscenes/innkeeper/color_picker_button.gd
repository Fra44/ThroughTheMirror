extends ColorPickerButton

func _ready():
	# Connettiamo il segnale
	pressed.connect(_on_button_pressed)
	
	var picker = get_picker()
	
	# --- VISIBILITÀ E MODI ---
	picker.edit_alpha = false
	picker.color_mode = ColorPicker.MODE_RGB 
	
	picker.sampler_visible = false
	picker.color_modes_visible = false
	picker.sliders_visible = true
	picker.hex_visible = false
	picker.presets_visible = false

	# Filtro del picker (per sicurezza)
	picker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_button_pressed():
	var picker = get_picker()
	
	# Usiamo un timer piccolissimo invece di process_frame per "fregare" il reset di Godot
	await get_tree().create_timer(0.01).timeout
	
	# Il parent di un picker in un ColorPickerButton è solitamente un PopupPanel o una Window
	var popup = picker.get_parent()
	
	if popup is Window:
		# 1. Scaliamo il fattore di contenuto (scala tutto: font, slider, icone)
		popup.content_scale_factor = 0.7
		
		# 2. Forziamo il rimpicciolimento della finestra fisica. 
		# Senza questo, il contenuto è piccolo ma la finestra (e l'ombra) restano enormi.
		var original_size = popup.size
		popup.size = original_size * 0.7
		
		# 3. Applichiamo il filtro Nearest al viewport della finestra per la pixel art
		popup.get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
