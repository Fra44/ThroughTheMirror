extends CanvasLayer

signal intro_finished

@onready var portrait: TextureRect = $Portrait
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var balloon: Node = $Balloon

var dialogue_resource: DialogueResource = preload("res://dialogue/game_intro.dialogue")

const NEXT_SCENE_PATH := "res://scenes/main/main.tscn"

var balloon_fade_target: CanvasItem = null
var balloon_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		balloon.visible = true
		
		balloon_fade_target = _find_canvas_item(balloon)
		
		if is_instance_valid(balloon_fade_target):
			balloon_fade_target.modulate.a = 1.0
		else:
			push_warning("GameIntro: nessun CanvasItem trovato dentro Balloon. Fade balloon non possibile.")
	
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		fade_overlay.color = Color.BLACK
		fade_overlay.modulate.a = 1.0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		if not balloon.line_changed.is_connected(_on_balloon_line_changed):
			balloon.line_changed.connect(_on_balloon_line_changed)
	
	get_tree().paused = true
	
	await get_tree().process_frame
	
	if is_instance_valid(balloon):
		balloon.start(dialogue_resource, "start")


func _find_canvas_item(node: Node) -> CanvasItem:
	if node is CanvasItem:
		return node as CanvasItem
	
	for child in node.get_children():
		var result := _find_canvas_item(child)
		if result != null:
			return result
	
	return null


func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		
		if tag.begins_with("portrait="):
			var path := tag.split("=")[1].strip_edges()
			_change_portrait(path)
		
		elif tag == "fade_in":
			_fade_in()
		
		elif tag.begins_with("fade_in="):
			var seconds := float(tag.split("=")[1].strip_edges())
			_fade_in(seconds)
		
		elif tag == "fade_out":
			_fade_out()

		elif tag.begins_with("fade_out="):
			var seconds := float(tag.split("=")[1].strip_edges())
			_fade_out(seconds)
		
		elif tag == "hide_balloon":
			await _fade_out_balloon()
		
		elif tag == "show_balloon":
			await _fade_in_balloon(0.45)
		
		elif tag.begins_with("cinematic="):
			var seconds := float(tag.split("=")[1].strip_edges())
			await _play_cinematic_pause(seconds)
		
		elif tag == "show_mirror":
			print("Mirror of Resonance introduced")
		
		elif tag == "show_codex":
			print("Resonance Codex introduced")


func _change_portrait(path: String) -> void:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		portrait.texture = tex
	else:
		push_warning("GameIntro: immagine non trovata: " + path)


func _play_cinematic_pause(seconds: float) -> void:
	if not is_instance_valid(balloon):
		return
	
	# Sparisce subito, senza fade out
	balloon.visible = false
	
	await get_tree().create_timer(seconds, true).timeout
	
	# Riappare con fade in
	await _fade_in_balloon(0.45)


func _fade_out_balloon() -> void:
	if not is_instance_valid(balloon):
		return
	
	# Niente fade out: nasconde direttamente il balloon
	balloon.visible = false


func _fade_in_balloon(duration: float = 0.45) -> void:
	if not is_instance_valid(balloon):
		return
	
	if not is_instance_valid(balloon_fade_target):
		balloon.visible = true
		return
	
	if is_instance_valid(balloon_tween):
		balloon_tween.kill()
	
	balloon.visible = true
	balloon_fade_target.visible = true
	balloon_fade_target.modulate.a = 0.0
	
	balloon_tween = create_tween()
	balloon_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	balloon_tween.tween_property(balloon_fade_target, "modulate:a", 1.0, duration)
	
	await balloon_tween.finished
	
	if is_instance_valid(balloon_fade_target):
		balloon_fade_target.modulate.a = 1.0


func _fade_in(duration: float = 0.5) -> void:
	if not is_instance_valid(fade_overlay):
		return
	
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	
	await tween.finished
	
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = false


func _fade_out(duration: float = 0.8) -> void:
	if not is_instance_valid(fade_overlay):
		return
	
	fade_overlay.visible = true
	
	if fade_overlay.modulate.a >= 0.98:
		fade_overlay.modulate.a = 1.0
		return
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	
	await tween.finished
	
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != dialogue_resource:
		return
	
	await _end_intro()


func _end_intro() -> void:
	await _fade_in_balloon(0.2)
	await _fade_out()
	
	get_tree().paused = false
	intro_finished.emit()
	
	if ResourceLoader.exists(NEXT_SCENE_PATH):
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	else:
		push_warning("GameIntro: scena successiva non trovata: " + NEXT_SCENE_PATH)
		queue_free()
