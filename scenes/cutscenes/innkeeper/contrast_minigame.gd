extends CanvasLayer

@onready var text_container = $MarginContainer/TextContainer
@onready var ratio_label = $RatioDisplay/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/RatioValue
@onready var color_picker = $ColorPickerDisplay/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/ColorPickerButton

# --- RIFERIMENTI AI PANNELLI PRINCIPALI ---
@onready var color_picker_display = $ColorPickerDisplay
@onready var ratio_display = $RatioDisplay

# Il bottone per la verifica
@onready var confirm_button = $RatioDisplay/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ValueCheckerButton

const BG_COLOR = Color("eac388") 
const MIN_CONTRAST = 4.5

# SEGNALE: Passa "true" se il contrasto è ok, "false" se non lo è
signal verification_requested(is_successful: bool)

var current_color: Color 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Nascondiamo i pannelli della UI all'avvio
	if color_picker_display: color_picker_display.hide()
	if ratio_display: ratio_display.hide()
	
	current_color = Color("dfb27a")
	color_picker.color = current_color
	update_ui(current_color)
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_button_pressed)

# --- FUNZIONE CHIAMATA DALLA CUTSCENE ---
func show_ui() -> void:
	if color_picker_display: color_picker_display.show()
	if ratio_display: ratio_display.show()
	
	# [TELEMETRIA] Inizio misurazione del Time on Task per il Livello 1
	if has_node("/root/TelemetryManager"):
		TelemetryManager.start_level("L1")

func _on_confirm_button_pressed() -> void:
	var ratio = calculate_contrast(current_color, BG_COLOR)
	print("Minigame: Contrasto calcolato: ", ratio)
	
	# Forziamo la chiusura del popup dei colori se è aperto
	if color_picker.get_popup().visible:
		color_picker.get_popup().hide()
	
	if ratio >= MIN_CONTRAST:
		# [TELEMETRIA] Risoluzione corretta e stop del timer
		if has_node("/root/TelemetryManager"):
			TelemetryManager.end_level("L1")
			
			# Print di debug richiesto per la validazione
			var stats = TelemetryManager.stats["L1"]
			print("[TELEMETRIA L1] Completato. Tempo totale: ", snapped(stats["total_time"], 0.1), "s | Tentativi falliti: ", stats["fails"])
		
		verification_requested.emit(true)

	else:
		# [TELEMETRIA] Errore utente registrato
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_fail("L1")
			print("[TELEMETRIA L1] Fallimento registrato. Totale attuale: ", TelemetryManager.stats["L1"]["fails"])
			
		verification_requested.emit(false)

func _on_color_picker_button_color_changed(color):
	current_color = color 
	update_ui(color)

func update_ui(new_color):
	for label in text_container.get_children():
		if label is Label:
			label.add_theme_color_override("font_color", new_color)
	
	var ratio = calculate_contrast(new_color, BG_COLOR)
	ratio_label.text = "Contrast Ratio: " + str(snapped(ratio, 0.01)) + ":1"

# --- FUNZIONI MATEMATICHE ---
func calculate_contrast(c1: Color, c2: Color) -> float:
	var l1 = get_relative_luminance(c1)
	var l2 = get_relative_luminance(c2)
	return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)

func get_relative_luminance(c: Color) -> float:
	var res = []
	for channel in [c.r, c.g, c.b]:
		if channel <= 0.03928:
			res.append(channel / 12.92)
		else:
			res.append(pow((channel + 0.055) / 1.055, 2.4))
	return 0.2126 * res[0] + 0.7152 * res[1] + 0.0722 * res[2]
