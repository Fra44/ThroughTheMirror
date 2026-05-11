extends Marker2D

func _ready() -> void:
	# Aggiunge forzatamente il marker al gruppo non appena il livello viene caricato
	add_to_group("rays_minigame_camera_target")
	
	# Assicuriamoci che non venga bloccato dalla pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
