extends CanvasLayer

signal intro_finished

@onready var portrait: TextureRect = $Portrait
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var balloon: Node = $Balloon

var dialogue_resource: DialogueResource = preload("res://dialogue/game_intro.dialogue")

# Cambia questo path con la scena vera che deve partire dopo l'intro
const NEXT_SCENE_PATH := "res://scenes/main/main.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		fade_overlay.color = Color.BLACK
		fade_overlay.modulate.a = 1.0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)
	
	get_tree().paused = true
	
	await get_tree().process_frame
	
	if is_instance_valid(balloon):
		balloon.start(dialogue_resource, "start")


func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		
		if tag.begins_with("portrait="):
			var path := tag.split("=")[1].strip_edges()
			_change_portrait(path)
		
		elif tag == "fade_in":
			_fade_in()
		
		elif tag == "fade_out":
			_fade_out()
		
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


func _fade_in() -> void:
	if not is_instance_valid(fade_overlay):
		return
	
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 2)
	
	await tween.finished
	fade_overlay.visible = false


func _fade_out() -> void:
	if not is_instance_valid(fade_overlay):
		return
	
	fade_overlay.visible = true
	
	# Se è già quasi nero, non riportarlo trasparente
	if fade_overlay.modulate.a >= 0.98:
		fade_overlay.modulate.a = 1.0
		return
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.8)
	
	await tween.finished
	
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != dialogue_resource:
		return
	
	await _end_intro()


func _end_intro() -> void:
	await _fade_out()
	
	get_tree().paused = false
	intro_finished.emit()
	
	if ResourceLoader.exists(NEXT_SCENE_PATH):
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	else:
		push_warning("GameIntro: scena successiva non trovata: " + NEXT_SCENE_PATH)
		queue_free()
