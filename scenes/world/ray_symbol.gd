extends Sprite2D

# Seleziona "red" o "green" dall'Inspector per ogni cristallo!
@export var ray_color: String = "green" 

func _ready() -> void:
	add_to_group("ray_symbol_preview_" + ray_color)

	var saved_symbol: String = ""

	if ray_color == "red":
		saved_symbol = DiscoveryManager.gate_symbol_red
	elif ray_color == "green":
		saved_symbol = DiscoveryManager.gate_symbol_green

	if saved_symbol != "":
		var texture_path = (
            "res://assets/diamond_rays/"
			+ saved_symbol
			+ "_"
			+ ray_color
			+ ".png"
		)

		if ResourceLoader.exists(texture_path):
			texture = load(texture_path)
			visible = true
		else:
			visible = false
	else:
		visible = false
