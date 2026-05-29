extends Area2D

const CUTSCENE_SCENE = preload("res://scenes/cutscenes/herald/herald_cutscene.tscn")

@export var impairment: ImpairmentData
@export var archivist_impairment: ImpairmentData

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

const HERALD_INITIAL_PORTRAIT := "res://scenes/cutscenes/images/herald_normal.png"


func action() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	
	# 1. Se il livello dell'Archivist non è ancora stato completato,
	# non parte la cutscene vera: parte solo un dialogo semplice.
	if not _is_archivist_completed():
		if player:
			player.is_talking = true
		
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "not_ready")
		await DialogueManager.dialogue_ended
		
		if player:
			player.is_talking = false
		
		return
	
	# 2. Se l'Herald è già stata aiutata, mostra il dialogo già esistente.
	if DiscoveryManager.discovered_impairments.has(impairment):
		if player:
			player.is_talking = true
		
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "already_helped")
		await DialogueManager.dialogue_ended
		
		if player:
			player.is_talking = false
		
		return
	
	# 3. Se Archivist è completato e Herald non è ancora stata aiutata,
	# parte normalmente la cutscene/minigioco dell'Herald.
	if CUTSCENE_SCENE == null:
		push_error("Errore: Scena cutscene non trovata")
		return
	
	var cutscene = CUTSCENE_SCENE.instantiate()
	get_tree().current_scene.add_child(cutscene)
	
	cutscene.start_cutscene(
		dialogue_resource,
		impairment,
		dialogue_start,
		HERALD_INITIAL_PORTRAIT
	)


func _is_archivist_completed() -> bool:
	if archivist_impairment == null:
		push_warning("HeraldActionable: archivist_impairment non assegnato nell'Inspector.")
		return false
	
	if DiscoveryManager == null:
		push_warning("HeraldActionable: DiscoveryManager non trovato.")
		return false
	
	return DiscoveryManager.discovered_impairments.has(archivist_impairment)
