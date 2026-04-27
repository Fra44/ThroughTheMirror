extends CharacterBody2D

# Velocità regolabile dall'Inspector (utile per testare il Reflow dell'Araldo!)
@export var speed: float = 150.0 

func _physics_process(_delta: float) -> void:
	# 1. Ottieni la direzione dai tasti (WASD o Frecce)
	# Input.get_vector gestisce anche il movimento diagonale bilanciato
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Applica la velocità
	velocity = direction * speed
	
	# 3. Muovi il corpo e gestisci le collisioni
	# move_and_slide() usa automaticamente la proprietà 'velocity'
	move_and_slide()