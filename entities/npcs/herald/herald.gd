extends CharacterBody2D # Cambialo se il tuo nodo radice dell'Araldo è un Node2D o altro

# Qui trascineremo la risorsa dell'Archivista (es. blindness.tres)
@export var archivist_impairment: ImpairmentData 

# Sostituisci "Actionable" con il nome esatto del tuo nodo Area2D che fa partire il dialogo!
@onready var actionable_area = $Actionable 

func _ready() -> void:
	# All'avvio della scena, nascondiamo l'Araldo e spegniamo la sua area di interazione
	visible = false
	if actionable_area:
		actionable_area.process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta: float) -> void:
	# Controlliamo costantemente: se l'Araldo è invisibile MA l'impairment dell'Archivista è stato risolto...
	if not visible and DiscoveryManager.discovered_impairments.has(archivist_impairment):
		_make_herald_appear()

func _make_herald_appear() -> void:
	# ...allora palesiamo l'Araldo!
	visible = true
	if actionable_area:
		actionable_area.process_mode = Node.PROCESS_MODE_INHERIT
		
	# OPZIONALE: Se vuoi fare lo sborone, qui puoi far partire un suono 
	# o un'animazione di fumo magico per giustificare come sia "spuntata" all'improvviso!
