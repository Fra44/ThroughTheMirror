extends Area2D

@export var dialogue_resource: DialogueResource # Trascina qui Signs.dialogue
@export var dialogue_start: String = "start"    # Qui scriverai il tag (es: "cartello_lago")

func action() -> void:
	# 1. Sicurezza: se non c'è il file, non fare nulla invece di crashare
	if dialogue_resource == null:
		print("Errore: Manca il file dialogue in questo cartello!")
		return

	var player = get_tree().get_first_node_in_group("Player")
	
	if player: 
		player.is_talking = true
		
		# USIAMO dialogue_start per scegliere QUALE tag leggere nel file
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
		
		await DialogueManager.dialogue_ended
		
		if is_instance_valid(player): 
			player.is_talking = false
