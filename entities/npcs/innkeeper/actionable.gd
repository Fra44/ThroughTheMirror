extends Area2D

const CUTSCENE_SCENE = preload("res://scenes/ui/cutscenes/innkeeper/innkeeper_cutscene.tscn")

@export var impairment: ImpairmentData   
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func action() -> void:
	# Cerchiamo il player nel mondo tramite il gruppo
	var player = get_tree().get_first_node_in_group("Player")
	
	# 1. CONTROLLO STATO: Abbiamo già aiutato l'oste?
	if DiscoveryManager.discovered_impairments.has(impairment):
		
		# --- BLOCCHIAMO IL GIOCATORE ---
		if player: 
			player.is_talking = true
		
		# Mostriamo solo il dialogo breve
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "already_helped")
		
		# Rimaniamo in attesa finché il pallone di dialogo non sparisce
		await DialogueManager.dialogue_ended
		
		# --- SBLOCCHIAMO IL GIOCATORE ---
		if player: 
			player.is_talking = false
			
		return

	# 2. PRIMA VOLTA: Creiamo la cutscene completa
	if CUTSCENE_SCENE == null:
		push_error("Errore: Scena cutscene non trovata")
		return
	
	var cutscene = CUTSCENE_SCENE.instantiate()
	get_tree().current_scene.add_child(cutscene)
	
	# Passiamo l'impairment alla cutscene
	cutscene.start_cutscene(
		dialogue_resource, 
		impairment, 
		"start", 
		"res://scenes/ui/cutscenes/images/conversation_innkeeper_happy.png"
	)
