extends StaticBody2D

# --- VARIABILI UNICHE PER OGNI ISTANZA ---
@export var npc_sprite: Texture2D
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

# --- LOGICA DI BLOCCO / APPARIZIONE ---
@export var required_impairment: ImpairmentData # Trascina qui cataratta.tres
@export var is_stairs_blocker: bool = false
@export var appears_after_impairment: bool = false # <--- NUOVA OPZIONE!

@onready var sprite_node = $Sprite2D
@onready var actionable_node = $Actionable

func _ready():
	# 1. Imposta la grafica unica
	if npc_sprite:
		sprite_node.texture = npc_sprite
		
	# 2. Passiamo i dati del dialogo al nodo Actionable
	if actionable_node:
		actionable_node.dialogue_resource = dialogue_resource
		actionable_node.dialogue_start = dialogue_start
		
	# 3. Controllo Progressione nel mondo
	if required_impairment:
		var is_solved = DiscoveryManager.discovered_impairments.has(required_impairment)
		
		# A) Se è un blocco per le scale: SPARISCE se il problema è stato risolto
		if is_stairs_blocker and is_solved:
			queue_free()
			
		# B) Se è un cliente della taverna: SPARISCE se il problema NON è ancora stato risolto
		elif appears_after_impairment and not is_solved:
			queue_free()
