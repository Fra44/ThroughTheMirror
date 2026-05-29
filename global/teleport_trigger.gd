@tool
extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_id: String = "Default"

@export var trigger_size: Vector2 = Vector2(24, 8):
	set(value):
		trigger_size = value
		_update_collision_shape()

var teleport_started: bool = false


func _ready() -> void:
	_update_collision_shape()
	
	if Engine.is_editor_hint():
		return
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _update_collision_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	
	if shape_node == null:
		return
	
	if shape_node.shape == null:
		shape_node.shape = RectangleShape2D.new()
	
	if shape_node.shape is RectangleShape2D:
		if not Engine.is_editor_hint():
			shape_node.shape = shape_node.shape.duplicate()
		
		shape_node.shape.size = trigger_size


func _on_body_entered(body: Node) -> void:
	if teleport_started:
		return
	
	if not body.is_in_group("Player") and body.name != "Player":
		return
	
	if target_scene_path.is_empty():
		push_warning("TeleportTrigger: target_scene_path non impostato su " + name)
		return
	
	var main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node == null:
		push_warning("TeleportTrigger: nodo Main non trovato.")
		return
	
	if not main_node.has_method("change_level"):
		push_warning("TeleportTrigger: Main non ha il metodo change_level.")
		return
	
	# Se Main sta ancora facendo una transizione, non blocchiamo il trigger.
	# Il player potrà riattivarlo appena la transizione sarà finita.
	if "is_transitioning" in main_node and main_node.is_transitioning:
		return
	
	teleport_started = true
	
	if "is_talking" in body:
		body.is_talking = true
	
	if "velocity" in body:
		body.velocity = Vector2.ZERO
	
	main_node.change_level.call_deferred(
		target_scene_path,
		StringName(target_spawn_id)
	)
