extends Area2D

# Queste variabili appariranno nell'Inspector e ti permetteranno
# di configurare ogni trigger in modo diverso.
@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_id: String = "Default"

var teleport_started: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# Evitiamo che il trigger venga attivato più volte
	if teleport_started:
		return
	
	# Verifichiamo che il corpo che entra sia il Player
	if body.name != "Player":
		return
	
	teleport_started = true
	
	# Blocchiamo subito il movimento del player
	if "is_talking" in body:
		body.is_talking = true
	
	# Azzeriamo anche la velocity, così non continua a scivolare per inerzia
	if "velocity" in body:
		body.velocity = Vector2.ZERO
	
	# Andiamo a cercare il nodo Main che gestisce i livelli
	var main_node = get_tree().root.get_node("Main")
	
	if main_node and main_node.has_method("change_level"):
		main_node.change_level.call_deferred(
			target_scene_path,
			StringName(target_spawn_id)
		)
