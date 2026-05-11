extends CharacterBody2D

@onready var actionable_finder: Area2D = $Direction/ActionableFinder

# Velocità regolabile dall'Inspector
@export var speed: float = 600.0 

# --- NUOVA VARIABILE DI STATO ---
var is_talking: bool = false

func _ready() -> void:
	# Aggiungiamo il player a un gruppo per renderlo "trovabile" da qualsiasi script!
	add_to_group("Player")

func _physics_process(_delta: float) -> void:
	# 1. BLOCCO MOVIMENTO DURANTE I DIALOGHI
	if is_talking:
		velocity = Vector2.ZERO
		move_and_slide() # Lo chiamiamo per azzerare l'inerzia all'istante
		return
		
	# 2. Ottieni la direzione dai tasti (WASD o Frecce)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 3. Applica la velocità
	velocity = direction * speed
	
	# 4. Muovi il corpo e gestisci le collisioni
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"): 
		# BLOCCO INTERAZIONE: Se stai già parlando, non puoi far partire altri dialoghi!
		if is_talking:
			return
			
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action() 
			return
