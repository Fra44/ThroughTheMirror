extends Area2D

# Carichiamo la scena della cutscene (più pulito usare preload qui)
const CUTSCENE_SCENE = preload("res://scenes/ui/cutscenes/innkeeper_cutscene.tscn")

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func action() -> void:
	# Verifichiamo che la risorsa esista (sicurezza extra)
	if CUTSCENE_SCENE == null:
		push_error("Errore: Scena cutscene non trovata in res://scenes/ui/innkeeper_cutscene.tscn")
		return
	
	# Istanziamo la scena della cutscene
	var cutscene = CUTSCENE_SCENE.instantiate()
	
	# La aggiungiamo all'albero della scena corrente
	get_tree().current_scene.add_child(cutscene)
	
	# Avviamo la cutscene passando la risorsa dialogo e il punto di inizio
	# Nota: assicurati che in innkeeper_cutscene.gd la funzione si chiami start_cutscene
	cutscene.start_cutscene(dialogue_resource, dialogue_start)
