extends CanvasLayer

signal verification_requested(is_successful: bool)

@onready var width_option: OptionButton = %WidthOption
@onready var space_option: OptionButton = %SpaceOption
@onready var preview_label: RichTextLabel = %PreviewLabel
@onready var run_button: Button = %RunCodeButton
@onready var parchment: NinePatchRect = %Parchment

# CodeEditor è un CanvasLayer, non un Control.
@onready var code_editor: CanvasLayer = %CodeEditor

# Questo invece è il pannello interno che possiamo sfumare con modulate.
# Controlla che il path sia corretto nella tua scena.
@onready var code_editor_panel: Control = $CodeEditor/MarginContainer/MainPanel

const BROKEN_SCROLL_WIDTH: float = 1300.0
const FIXED_SCROLL_WIDTH: float = 520.0
const WIDTH_800: float = 800.0
const INVALID_WIDTH: float = 1000.0

const MIN_SCROLL_HEIGHT: float = 180.0

const TEXT_MARGIN_LEFT: float = 110.0
const TEXT_MARGIN_RIGHT: float = 110.0
const TEXT_MARGIN_TOP: float = 55.0
const TEXT_MARGIN_BOTTOM: float = 55.0

const TINY_FONT_SIZE: int = 18
const ZOOMED_FONT_SIZE: int = 72

const EDITOR_SLIDE_DISTANCE: float = 520.0

var editor_start_offset: Vector2
var is_running_code: bool = false
var intro_finished: bool = false

var decree_text: String = "Hear ye, hear ye! A great dragon named Kalipso approaches our lands. Be brave, be ready, and may the light protect the kingdom."


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	editor_start_offset = code_editor.offset
	
	_setup_options()
	
	width_option.item_selected.connect(_on_option_changed)
	space_option.item_selected.connect(_on_option_changed)
	run_button.pressed.connect(_on_run_pressed)
	
	preview_label.scroll_active = false
	preview_label.fit_content = false
	preview_label.text = decree_text
	
	code_editor.visible = false
	code_editor_panel.modulate.a = 0.0
	run_button.disabled = true
	
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
	
	# 1. Stato iniziale: testo piccolo.
	preview_label.text = decree_text
	preview_label.add_theme_font_size_override("normal_font_size", TINY_FONT_SIZE)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	_set_label_rect(FIXED_SCROLL_WIDTH - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT, 400.0)
	_resize_parchment_instant(Vector2(FIXED_SCROLL_WIDTH, MIN_SCROLL_HEIGHT))
	
	await _wait(0.8)
	
	# 2. Zoom magico: il testo diventa grande.
	preview_label.add_theme_font_size_override("normal_font_size", ZOOMED_FONT_SIZE)
	await get_tree().process_frame
	
	await _wait(0.35)
	
	# 3. Comportamento rotto: testo grande + nowrap + pergamena orizzontale.
	await _animate_scroll_state("1920px", "nowrap")
	
	await _wait(0.4)
	
	# 4. Compare l'editor.
	await _show_code_editor()
	
	intro_finished = true


func _on_option_changed(_index: int) -> void:
	# Non aggiorniamo la pergamena mentre il player cambia opzioni.
	# Il risultato visivo deve apparire solo dopo Run Code.
	pass


func _on_run_pressed() -> void:
	if is_running_code:
		return
	
	is_running_code = true
	run_button.disabled = true
	
	var final_width: String = width_option.get_item_text(width_option.selected)
	var final_space: String = space_option.get_item_text(space_option.selected)
	var is_successful: bool = final_width == "100%" and final_space == "normal"
	
	await _hide_code_editor()
	await _wait(0.15)
	
	await _animate_scroll_state(final_width, final_space)
	
	await _wait(0.45)
	
	verification_requested.emit(is_successful)
	
	is_running_code = false


func prepare_retry() -> void:
	if is_running_code:
		return
	
	await _show_code_editor()


func reset_minigame() -> void:
	width_option.select(0)
	space_option.select(0)
	await play_intro_sequence()


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
	# white-space: nowrap;
	# Il testo non va a capo e la pergamena cresce in orizzontale.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 400.0)
	
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
	# white-space: normal;
	# Il testo va a capo e la pergamena cresce verso il basso.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2000.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(target_width, needed_height))


func _show_pre_scroll(target_width: float) -> void:
	# white-space: pre;
	# Lo trattiamo come comportamento rigido: non risolve davvero il problema.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 400.0)
	
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
	# white-space: pre-wrap;
	# Wrappa, ma non è la soluzione ufficiale del puzzle.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2000.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	await _resize_parchment(Vector2(target_width, needed_height))


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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func update_image(tex: Texture2D) -> void:
	pass
