extends Sprite2D

# Carichiamo le texture (Modifica il percorso dell'apertura se diverso)
var texture_close = preload("res://assets/gate/gate_close.png")
var texture_open = preload("res://assets/gate/gate_open.png")

func _ready() -> void:
	# Aggiungiamo il nodo al gruppo per trovarlo facilmente
	add_to_group("gate_door")
	
	# Di default il cancello dovrebbe essere chiuso all'inizio del livello 2
	# a meno che non sia già stato risolto (gestito dall'overworld)
	close_door()

func open_door() -> void:
	texture = texture_open
	print("Cancello: Aperto!")
	
	# Se il cancello ha un nodo di collisione come figlio, lo disattiviamo
	# Supponendo che tu abbia un StaticBody2D con un CollisionShape2D
	var collision = get_node_or_null("StaticBody2D/CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)

func close_door() -> void:
	texture = texture_close
	print("Cancello: Chiuso!")
	
	# Riattiviamo la collisione se necessario
	var collision = get_node_or_null("StaticBody2D/CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", false)
