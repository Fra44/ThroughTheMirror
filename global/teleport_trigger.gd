extends Area2D

# Queste variabili appariranno nell'Inspector e ti permetteranno
# di configurare ogni trigger in modo diverso.
@export_file("*.tscn") var target_scene_path: String # La scena di destinazione
@export var target_spawn_id: String = "Default"      # L'ID del Marker2D di arrivo

func _ready():
	# Connettiamo il segnale via codice per comodità
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifichiamo che il corpo che entra sia il Player
	if body.name == "Player":
		# Andiamo a cercare il nodo Main che gestisce i livelli
		var main_node = get_tree().root.get_node("Main")
		
		if main_node and main_node.has_method("change_level"):
			# MODIFICA QUI: Usiamo call_deferred per evitare l'errore "flushing queries"
			# La sintassi moderna di Godot 4 permette di chiamare .call_deferred() direttamente sulla funzione
			main_node.change_level.call_deferred(target_scene_path, StringName(target_spawn_id))
