extends Node2D # (O il tipo di nodo che fa da radice al tuo overworld)

func _ready() -> void:
	# Questa funzione scatta in automatico appena il main.gd carica questo livello!
	print("Overworld caricato! Controllo lo stato del mondo...")
	
	# CONTROLLA SE IL MENU ERA STATO RISOLTO
	if DiscoveryManager and DiscoveryManager.level_states.get("menu_solved", false) == true:
		
		print("Qui va aggiunta condizione per passare da primo a secondo livello!")
	
	
	# CONTROLLA SE IL CANCELLO ERA STATO RISOLTO
	if DiscoveryManager and DiscoveryManager.level_states.get("gate_solved", false) == true:
		
		# 1. Apri fisicamente il cancello
		var gate = get_tree().get_first_node_in_group("gate_door")
		if gate and gate.has_method("open_door"):
			gate.open_door()
			
		# 2. Recupera e applica i simboli giusti (se sono stati salvati)
		var red_sym = DiscoveryManager.level_states.get("gate_symbol_red", "")
		if red_sym != "":
			_restore_ray_symbol("red", red_sym)
			
		var green_sym = DiscoveryManager.level_states.get("gate_symbol_green", "")
		if green_sym != "":
			_restore_ray_symbol("green", green_sym)

# Funzione d'appoggio per ripristinare le texture all'avvio
func _restore_ray_symbol(color: String, symbol_name: String) -> void:
	var texture_path = "res://assets/diamond_rays/" + symbol_name + "_" + color + ".png"
	if ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		var targets = get_tree().get_nodes_in_group("ray_symbol_preview_" + color)
		for t in targets:
			if t is Sprite2D:
				t.texture = tex
				t.visible = true
