extends Area2D
class_name Actionable

var dialogue_resource: DialogueResource
var dialogue_start: String = "start"

func action() -> void:
	if dialogue_resource != null:
		# Cerchiamo il player nel mondo tramite il gruppo
		var player = get_tree().get_first_node_in_group("Player")
		
		# --- BLOCCHIAMO IL GIOCATORE ---
		if player: 
			player.is_talking = true
			
		# Avvia il balloon del Dialogue Manager
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
		
		# Rimaniamo in attesa finché il pallone di dialogo non sparisce
		await DialogueManager.dialogue_ended
		
		# --- SBLOCCHIAMO IL GIOCATORE ---
		if player: 
			player.is_talking = false
			
	else:
		print("Attenzione: Nessuna risorsa dialogo assegnata a questo NPC!")
