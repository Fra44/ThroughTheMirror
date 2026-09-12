extends Sprite2D

# Carichiamo le texture
var texture_close = preload("res://assets/gate/gate_close.png")
var texture_open = preload("res://assets/gate/gate_open.png")

func _ready() -> void:
	# Aggiungiamo il nodo al gruppo per trovarlo facilmente (serve per la cutscene!)
	add_to_group("gate_door")

	if DiscoveryManager.gate_solved:
		# Se il livello era già stato risolto, si apre da solo all'istante
		open_door()
	else:
		# Altrimenti si chiude
		close_door()

func open_door() -> void:
	texture = texture_open
	print("Cancello: Aperto!")
	
	# Disattiviamo la collisione
	var collision = get_node_or_null("StaticBody2D/CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)

func close_door() -> void:
	texture = texture_close
	
	# Riattiviamo la collisione
	var collision = get_node_or_null("StaticBody2D/CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", false)
