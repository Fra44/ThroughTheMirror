extends CanvasLayer

signal verification_requested(is_successful: bool)
signal shader_activation_requested
signal dialogue_step_requested(title: String)
signal dialogue_step_finished
signal debug_window_requested

@onready var width_option: OptionButton = %WidthOption
@onready var space_option: OptionButton = %SpaceOption
@onready var preview_label: RichTextLabel = %PreviewLabel
@onready var run_button: Button = %RunCodeButton
@onready var parchment: NinePatchRect = %Parchment
@onready var background_image: TextureRect = %BackgroundImage

@onready var code_editor: CanvasLayer = %CodeEditor
@onready var code_editor_panel: Control = $CodeEditor/MarginContainer/MainPanel

const CLOSED_SCROLL_WIDTH: float = 170.0
const NORMAL_SCROLL_WIDTH: float = 680.0
const BROKEN_SCROLL_WIDTH: float = 3200.0
const FIXED_SCROLL_WIDTH: float = 560.0
const WIDTH_800: float = 1600.0
const INVALID_WIDTH: float = 2000.0

const MIN_SCROLL_HEIGHT: float = 260.0

const TEXT_MARGIN_LEFT: float = 165.0
const TEXT_MARGIN_RIGHT: float = 135.0
const TEXT_MARGIN_TOP: float = 68.0
const TEXT_MARGIN_BOTTOM: float = 62.0

const TINY_FONT_SIZE: int = 18
const ZOOMED_FONT_SIZE: int = 96

const EDITOR_SLIDE_DISTANCE: float = 520.0
const WALK_DEMO_DISTANCE: float = 900.0
const BACKGROUND_WALK_DISTANCE: float = 260.0

const SUCCESS_VERTICAL_SCROLL_DISTANCE: float = 820.0
const SUCCESS_VERTICAL_SCROLL_DURATION: float = 2
const SUCCESS_RETURN_DURATION: float = 0.45


var editor_start_offset: Vector2
var parchment_start_position: Vector2
var background_start_position: Vector2

var is_running_code: bool = false
var intro_finished: bool = false
var intro_started: bool = false
var waiting_for_dialogue_step: bool = false

var placeholder_text: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Scrollum magicum testandum est. Hear ye, hear ye, placeholder words of the royal decree flow across the parchment until the proper layout spell is restored. Integer luctus, sapien non facilisis tincidunt, nunc erat cursus libero, vitae luctus ipsum neque at lorem. Donec nuntius regni nondum scriptus est, sed pergamena iam probanda est. The Royal Herald cannot use this magical scroll while the text refuses to wrap and stretches endlessly across the castle hallway."

var announcement_text: String = "Hear ye, hear ye! A great dragon named Kalipso approaches our lands. Be brave, be ready, and may the light protect the kingdom."

var decree_text: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	editor_start_offset = code_editor.offset
	parchment_start_position = parchment.position
	background_start_position = background_image.position
	
	_setup_options()
	
	width_option.item_selected.connect(_on_option_changed)
	space_option.item_selected.connect(_on_option_changed)
	run_button.pressed.connect(_on_run_pressed)
	
	preview_label.scroll_active = false
	preview_label.fit_content = false
	
	decree_text = placeholder_text
	preview_label.text = decree_text
	
	code_editor.visible = false
	code_editor_panel.modulate.a = 0.0
	run_button.disabled = true
	
	visible = false


func show_ui() -> void:
	if intro_started:
		return
	
	intro_started = true
	visible = true
	call_deferred("play_intro_sequence")


func _setup_options() -> void:
	width_option.clear()
	width_option.add_item("1920px")
	width_option.add_item("100%")
	width_option.add_item("fixed")
	width_option.add_item("800px")
	width_option.select(0)

	space_option.clear()
	space_option.add_item("nowrap")
	space_option.add_item("normal")
	space_option.add_item("pre")
	space_option.add_item("pre-wrap")
	space_option.select(0)


func play_intro_sequence() -> void:
	intro_finished = false
	
	code_editor.visible = false
	code_editor_panel.modulate.a = 0.0
	run_button.disabled = true
	
	decree_text = placeholder_text
	preview_label.text = decree_text
	
	parchment.position = parchment_start_position
	
	# 1. Scroll chiuso.
	preview_label.visible = false
	_set_preview_font_size(TINY_FONT_SIZE)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_rect(1.0, 1.0)
	_resize_parchment_instant(Vector2(CLOSED_SCROLL_WIDTH, MIN_SCROLL_HEIGHT))
	
	await _request_dialogue_step("scroll_closed")
	
	# 2. Lo scroll si apre normalmente.
	await _resize_parchment(Vector2(NORMAL_SCROLL_WIDTH, MIN_SCROLL_HEIGHT))
	
	preview_label.visible = true
	_set_preview_font_size(TINY_FONT_SIZE)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_rect(NORMAL_SCROLL_WIDTH - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT, MIN_SCROLL_HEIGHT - TEXT_MARGIN_TOP - TEXT_MARGIN_BOTTOM)
	
	await _request_dialogue_step("scroll_small_text")
	
	# 3. Herald non riesce a leggere.
	await _request_dialogue_step("scroll_cannot_read")
	
	# 4. Attivazione Mirror / shader.
	await _request_dialogue_step("scroll_activate_mirror")
	shader_activation_requested.emit()
	
	await _wait(0.6)
	
	await _request_dialogue_step("scroll_low_vision")
	
	# 5. Zoom magico.
	await _request_dialogue_step("scroll_zoom")

	decree_text = placeholder_text
	preview_label.text = decree_text

	await _animate_preview_font_size(TINY_FONT_SIZE, ZOOMED_FONT_SIZE, 1.1)

	await _wait(0.35)
	
	# 6. Bug: espansione orizzontale.
	await _request_dialogue_step("scroll_sideways_bug")
	await _animate_scroll_state("1920px", "nowrap")
	
	await _wait(0.3)
	
	# 7. Camminata nel corridoio.
	await _request_dialogue_step("scroll_walk_corridor")
	await _play_horizontal_reading_demo()
	
	await _request_dialogue_step("scroll_corridor_explanation")
	
	# 8. Ritorno al centro.
	await _return_parchment_to_center()
	
	await _request_dialogue_step("scroll_fix_prompt")
	
	# 9. Ora mostriamo Debug Window + CodeEditor insieme.
	debug_window_requested.emit()
	await _wait(0.15)
	await _show_code_editor()

	intro_finished = true
	
	# [TELEMETRIA] L'introduzione è finita e l'utente ha il controllo dell'interfaccia:
	# facciamo partire il timer per il Livello 4 qui per calcolare il vero Time on Task.
	if has_node("/root/TelemetryManager"):
		TelemetryManager.start_level("L4")


func _request_dialogue_step(title: String) -> void:
	waiting_for_dialogue_step = true
	dialogue_step_requested.emit(title)
	
	while waiting_for_dialogue_step:
		await get_tree().process_frame


func notify_dialogue_step_finished() -> void:
	waiting_for_dialogue_step = false


func is_waiting_for_dialogue_step() -> bool:
	return waiting_for_dialogue_step


func _on_option_changed(_index: int) -> void:
	pass


func _on_run_pressed() -> void:
	if is_running_code:
		return
	
	is_running_code = true
	run_button.disabled = true
	
	var final_width: String = width_option.get_item_text(width_option.selected)
	var final_space: String = space_option.get_item_text(space_option.selected)
	
	var is_successful: bool = final_width == "100%" and (final_space == "normal" or final_space == "pre-wrap")
	
	await _hide_code_editor()
	await _wait(0.15)
	
	parchment.position = parchment_start_position
	background_image.position = background_start_position
	
	await _animate_scroll_state(final_width, final_space)
	
	if is_successful:
		# [TELEMETRIA] Vittoria vera!
		if has_node("/root/TelemetryManager"):
			TelemetryManager.end_level("L4")
			
			# ---> QUESTE SONO LE DUE RIGHE CHE MANCAVANO <---
			var stats = TelemetryManager.stats["L4"]
			print("[TELEMETRIA L4] Completato. Tempo totale: ", snapped(stats["total_time"], 0.1), "s | Tentativi falliti: ", stats["fails"])
			
		await _play_success_vertical_scroll_demo()
		_start_success_return_to_initial_position()
		
		# Emettiamo la VITTORIA alla cutscene
		verification_requested.emit(true)
		
	else:
		# [TELEMETRIA] Fallimento vero!
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_fail("L4")
			print("[TELEMETRIA L4] Fallimento registrato. Totale attuale: ", TelemetryManager.stats["L4"]["fails"])
			
		await _wait(0.45)
		
		# Emettiamo il FALLIMENTO alla cutscene
		verification_requested.emit(false)
	
	is_running_code = false


func prepare_retry() -> void:
	if is_running_code:
		return
	
	parchment.position = parchment_start_position
	await _show_code_editor()


func reset_minigame() -> void:
	width_option.select(0)
	space_option.select(0)
	intro_started = false
	await play_intro_sequence()


func show_final_announcement() -> void:
	decree_text = announcement_text
	preview_label.text = decree_text
	_set_preview_font_size(ZOOMED_FONT_SIZE)
	parchment.position = parchment_start_position
	await _animate_scroll_state("100%", "normal")


func _animate_scroll_state(width_value: String, space_value: String) -> void:
	var target_width: float = _get_target_width(width_value)
	
	match space_value:
		"normal":
			await _show_wrapped_scroll(target_width)
		"pre-wrap":
			await _show_pre_wrap_scroll(target_width)
		"nowrap":
			await _show_horizontal_scroll(target_width)
		"pre":
			await _show_pre_scroll(target_width)
		_:
			await _show_horizontal_scroll(target_width)


func _get_target_width(current_width: String) -> float:
	match current_width:
		"1920px":
			return BROKEN_SCROLL_WIDTH
		"100%":
			return FIXED_SCROLL_WIDTH
		"800px":
			return WIDTH_800
		"fixed":
			return INVALID_WIDTH
		_:
			return INVALID_WIDTH


func _show_horizontal_scroll(target_width: float) -> void:
	preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 500.0)
	
	await get_tree().process_frame
	
	var needed_width: float = max(
		target_width,
		preview_label.get_content_width() + TEXT_MARGIN_LEFT + TEXT_MARGIN_RIGHT
	)
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(needed_width, needed_height))


func _show_wrapped_scroll(target_width: float) -> void:
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2600.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(target_width, needed_height))


func _show_pre_scroll(target_width: float) -> void:
	preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 500.0)
	
	await get_tree().process_frame
	
	var needed_width: float = max(
		target_width,
		preview_label.get_content_width() + TEXT_MARGIN_LEFT + TEXT_MARGIN_RIGHT
	)
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(needed_width, needed_height))


func _show_pre_wrap_scroll(target_width: float) -> void:
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2600.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(target_width, needed_height))


func _play_horizontal_reading_demo() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	tween.tween_property(
		parchment,
		"position:x",
		parchment_start_position.x - WALK_DEMO_DISTANCE,
		2.2
	)
	
	tween.tween_property(
		background_image,
		"position:x",
		background_start_position.x - BACKGROUND_WALK_DISTANCE,
		2.2
	)
	
	await tween.finished

func _play_success_vertical_scroll_demo() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(
		parchment,
		"position:y",
		parchment_start_position.y - SUCCESS_VERTICAL_SCROLL_DISTANCE,
		SUCCESS_VERTICAL_SCROLL_DURATION
	)
	
	await tween.finished

func _start_success_return_to_initial_position() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	tween.tween_property(
		parchment,
		"position:x",
		parchment_start_position.x,
		SUCCESS_RETURN_DURATION
	)
	
	tween.tween_property(
		parchment,
		"position:y",
		parchment_start_position.y,
		SUCCESS_RETURN_DURATION
	)

func _return_parchment_to_center() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	tween.tween_property(
		parchment,
		"position:x",
		parchment_start_position.x,
		0.65
	)
	
	tween.tween_property(
		background_image,
		"position:x",
		background_start_position.x,
		0.65
	)
	
	await tween.finished


func _set_label_rect(label_width: float, label_height: float) -> void:
	preview_label.position = Vector2(TEXT_MARGIN_LEFT, TEXT_MARGIN_TOP)
	preview_label.size = Vector2(label_width, label_height)
	preview_label.custom_minimum_size = Vector2.ZERO


func _resize_parchment(target_size: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(parchment, "size", target_size, 0.45)
	
	tween.finished.connect(func() -> void:
		_update_label_after_resize(target_size)
	)
	
	await tween.finished


func _resize_parchment_instant(target_size: Vector2) -> void:
	parchment.size = target_size
	_update_label_after_resize(target_size)


func _update_label_after_resize(parchment_size: Vector2) -> void:
	var label_width: float = parchment_size.x - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	var label_height: float = parchment_size.y - TEXT_MARGIN_TOP - TEXT_MARGIN_BOTTOM
	
	if label_width < 1.0:
		label_width = 1.0
	
	if label_height < 1.0:
		label_height = 1.0
	
	preview_label.position = Vector2(TEXT_MARGIN_LEFT, TEXT_MARGIN_TOP)
	preview_label.size = Vector2(label_width, label_height)


func _hide_code_editor() -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(code_editor, "offset:x", editor_start_offset.x - EDITOR_SLIDE_DISTANCE, 0.35)
	tween.tween_property(code_editor_panel, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	
	code_editor.visible = false


func _show_code_editor() -> void:
	code_editor.visible = true
	code_editor.offset.x = editor_start_offset.x - EDITOR_SLIDE_DISTANCE
	code_editor_panel.modulate.a = 0.0
	
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(code_editor, "offset:x", editor_start_offset.x, 0.35)
	tween.tween_property(code_editor_panel, "modulate:a", 1.0, 0.25)
	
	await tween.finished
	
	run_button.disabled = false


func _set_preview_font_size(font_size: int) -> void:
	preview_label.remove_theme_font_size_override("normal_font_size")
	preview_label.add_theme_font_size_override("normal_font_size", font_size)
	preview_label.queue_redraw()

func _animate_preview_font_size(from_size: int, to_size: int, duration: float) -> void:
	var steps: int = 18
	var step_time: float = duration / float(steps)
	
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var current_size: int = int(lerp(float(from_size), float(to_size), t))
		
		_set_preview_font_size(current_size)
		await get_tree().process_frame
		await _wait(step_time)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func update_image(tex: Texture2D) -> void:
	pass
