extends Control

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var start_button: TextureButton = $MarginContainer/StartButton


func _ready() -> void:
	print("=== MAIN MENU READY ===")
	
	fade_overlay.visible = true
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	start_button.visible = true
	start_button.modulate = Color(1, 1, 1, 0)
	start_button.disabled = true
	start_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	
	start_button.mouse_entered.connect(func():
		print(">>> HOVER ENTERED | disabled = ", start_button.disabled)
	)
	
	start_button.mouse_exited.connect(func():
		print("<<< HOVER EXITED | disabled = ", start_button.disabled)
	)
	
	await _play_intro_fade()


func _play_intro_fade() -> void:
	print("=== INTRO FADE START ===")
	
	var bg_tween: Tween = create_tween()
	bg_tween.tween_property(fade_overlay, "modulate:a", 0.0, 2.0)
	
	await get_tree().create_timer(1.5).timeout
	
	print("=== BUTTON FADE START ===")
	
	var button_tween: Tween = create_tween()
	button_tween.tween_property(start_button, "modulate:a", 1.0, 0.45)
	
	await bg_tween.finished
	
	print("=== BACKGROUND FADE FINISHED ===")
	
	fade_overlay.visible = false
	
	# Non facciamo await button_tween.finished qui,
	# perché potrebbe essere già finito.
	start_button.modulate.a = 1.0
	start_button.disabled = false
	
	print("=== BUTTON ENABLED ===")
	print("StartButton disabled: ", start_button.disabled)


func _on_start_button_pressed() -> void:
	print("=== START BUTTON PRESSED ===")
	
	start_button.disabled = true
	
	fade_overlay.visible = true
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Fade-out dello schermo verso il nero
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.8)
	
	# Fade-out del bottone insieme allo sfondo
	tween.tween_property(start_button, "modulate:a", 0.0, 0.8)
	
	await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
