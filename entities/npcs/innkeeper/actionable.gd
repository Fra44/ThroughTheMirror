extends Area2D

# Precarichiamo la scena della cutscene
const CUTSCENE_SCENE = preload("res://scenes/ui/cutscenes/innkeeper/innkeeper_cutscene.tscn")

@export var impairment: ImpairmentData   # Trascina qui il file cataratta.tres nell'Inspector
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func action() -> void:
	# 1. CONTROLLO STATO: Abbiamo già aiutato l'oste?
	if DiscoveryManager.discovered_impairments.has(impairment):
		# Se lo abbiamo già aiutato, mostriamo solo il dialogo breve
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "already_helped")
		return

	# 2. PRIMA VOLTA: Creiamo la cutscene completa
	if CUTSCENE_SCENE == null:
		push_error("Errore: Scena cutscene non trovata")
		return
	
	var cutscene = CUTSCENE_SCENE.instantiate()
	get_tree().current_scene.add_child(cutscene)
	
	# Passiamo l'impairment alla cutscene per la Debug Window
	cutscene.start_cutscene(
		dialogue_resource, 
		impairment, 
		"start", 
		"res://scenes/ui/cutscenes/images/conversation_innkeeper_happy.png"
	)
