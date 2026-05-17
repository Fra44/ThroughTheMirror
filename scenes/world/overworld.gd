extends Node2D

func _ready() -> void:
	pass
	## L'overworld si preoccupa solo dell'NPC
	#if DiscoveryManager and DiscoveryManager.level_states.get("menu_solved", false) == true:
		#var guardian = get_tree().get_first_node_in_group("guardian_npc")
		#if guardian:
			#guardian.visible = true
	#else:
		#var guardian = get_tree().get_first_node_in_group("guardian_npc")
		#if guardian:
			#guardian.visible = false
