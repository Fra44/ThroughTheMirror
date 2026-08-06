extends StaticBody2D

@export var required_impairment: ImpairmentData 

func _ready():
	# Quando la mappa viene caricata, controlla se abbiamo già risolto il problema
	if required_impairment and DiscoveryManager.discovered_impairments.has(required_impairment):
		queue_free() # Distrugge la barriera invisibile
