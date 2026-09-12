extends Area2D

const CUTSCENE_SCENE = preload("res://scenes/cutscenes/archivist/archivist_cutscene.tscn")

@export var impairment: ImpairmentData   
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func action() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	
	if DiscoveryManager.discovered_impairments.has(impairment):
		if player: player.is_talking = true
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "already_helped")
		await DialogueManager.dialogue_ended
		if player: player.is_talking = false
		return

	if CUTSCENE_SCENE == null:
		push_error("Errore: Scena cutscene non trovata")
		return
	
	var cutscene = CUTSCENE_SCENE.instantiate()
	get_tree().current_scene.add_child(cutscene)
	
	cutscene.start_cutscene(
		dialogue_resource, 
		impairment, 
		dialogue_start, 
		"res://scenes/cutscenes/images/archivist.png"
	)
