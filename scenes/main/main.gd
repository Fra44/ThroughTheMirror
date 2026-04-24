extends Node2D

signal level_changed(level_path: String)

@export_file("*.tscn") var initial_level_path: String = "res://scenes/world/level_0.tscn"

@onready var current_level_container: Node = $CurrentLevel
@onready var player: Node2D = $Actors/Player

var current_level_instance: Node = null


func _ready() -> void:
	if not initial_level_path.is_empty():
		change_level(initial_level_path)


func change_level(path: String, spawn_id: StringName = &"") -> void:
	if path.is_empty():
		push_error("change_level called with an empty path")
		return

	var packed_scene := load(path) as PackedScene
	if packed_scene == null:
		push_error("Failed to load level scene: %s" % path)
		return

	if current_level_instance != null and is_instance_valid(current_level_instance):
		current_level_instance.queue_free()

	var next_level := packed_scene.instantiate()
	current_level_container.add_child(next_level)
	current_level_instance = next_level

	_place_player_at_spawn(spawn_id)
	level_changed.emit(path)


func _place_player_at_spawn(spawn_id: StringName) -> void:
	if spawn_id == StringName():
		return

	var spawn_path := NodePath("SpawnPoints/%s" % String(spawn_id))
	if current_level_instance != null and current_level_instance.has_node(spawn_path):
		var spawn := current_level_instance.get_node(spawn_path) as Node2D
		if spawn != null:
			player.global_position = spawn.global_position
			return

	push_warning("Spawn point not found: %s" % String(spawn_id))
