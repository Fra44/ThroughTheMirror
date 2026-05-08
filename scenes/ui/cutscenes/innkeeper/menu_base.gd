extends CanvasLayer

@onready var text_container = $MarginContainer/TextContainer
@onready var ratio_label = $RatioDisplay
@onready var color_picker = $ColorPickerButton

# BACKGROUND COLOR (PAPER)
const BG_COLOR = Color("eac388") 

func _ready():
	# FOREGROUND COLOR (TEXT) [initial value]
	var initial_color = Color("dfb27a")
	color_picker.color = initial_color
	update_ui(initial_color)
	process_mode = Node.PROCESS_MODE_ALWAYS

# ATTTENTION! Must be linked to the signal in ContrastMinigame
func _on_color_picker_button_color_changed(color):
	update_ui(color)

func update_ui(new_color):
	# 1. Changes the colors of ALL the labels in TextContainer
	for label in text_container.get_children():
		if label is Label:
			label.add_theme_color_override("font_color", new_color)
	
	# 2. Compute the contrast ratio
	var ratio = calculate_contrast(new_color, BG_COLOR)
	
	# 3. Update rendered texts
	ratio_label.text = "Contrast Ratio: " + str(snapped(ratio, 0.01)) + ":1"

func calculate_contrast(c1: Color, c2: Color) -> float:
	var l1 = get_relative_luminance(c1)
	var l2 = get_relative_luminance(c2)
	# Num is always bigger than Den
	return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)

func get_relative_luminance(c: Color) -> float:
	var res = []
	for channel in [c.r, c.g, c.b]:
		if channel <= 0.03928:
			res.append(channel / 12.92)
		else:
			res.append(pow((channel + 0.055) / 1.055, 2.4))
	return 0.2126 * res[0] + 0.7152 * res[1] + 0.0722 * res[2]
