extends Sprite2D

# Seleziona "red" o "green" dall'Inspector per ogni cristallo!
@export var ray_color: String = "green" 

func _ready() -> void:
	# Si aggiunge al gruppo da solo in base al colore scelto
	add_to_group("ray_symbol_preview_" + ray_color)
	
	# Controlla la memoria del gioco
	var saved_symbol = ""
	if DiscoveryManager:
		saved_symbol = DiscoveryManager.level_states.get("gate_symbol_" + ray_color, "")
		
	# Se trova un simbolo salvato per il suo colore, lo carica!
	if saved_symbol != "":
		var texture_path = "res://assets/diamond_rays/" + saved_symbol + "_" + ray_color + ".png"
		if ResourceLoader.exists(texture_path):
			texture = load(texture_path)
			visible = true
		else:
			visible = false
	else:
		# Se non c'è niente di salvato, resta invisibile
		visible = false
