extends CanvasLayer

signal verification_requested(is_successful: bool)

@onready var width_option: OptionButton = %WidthOption
@onready var space_option: OptionButton = %SpaceOption
@onready var preview_label: RichTextLabel = %PreviewLabel
@onready var run_button: Button = %RunCodeButton
@onready var parchment: NinePatchRect = %Parchment



const BROKEN_SCROLL_WIDTH: float = 1300.0
const FIXED_SCROLL_WIDTH: float = 520.0
const WIDTH_800: float = 800.0
const INVALID_WIDTH: float = 1000.0

const MIN_SCROLL_HEIGHT: float = 180.0

const TEXT_MARGIN_LEFT: float = 110.0
const TEXT_MARGIN_RIGHT: float = 110.0
const TEXT_MARGIN_TOP: float = 55.0
const TEXT_MARGIN_BOTTOM: float = 55.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_options()
	
	width_option.item_selected.connect(_on_option_changed)
	space_option.item_selected.connect(_on_option_changed)
	run_button.pressed.connect(_on_run_pressed)
	
	preview_label.scroll_active = false
	preview_label.fit_content = false
	
	_update_preview()


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


func _on_option_changed(_index: int) -> void:
	_update_preview()


func _update_preview() -> void:
	var current_width: String = width_option.get_item_text(width_option.selected)
	var current_space: String = space_option.get_item_text(space_option.selected)
	
	var target_width: float = _get_target_width(current_width)
	
	match current_space:
		"normal":
			_show_wrapped_scroll(target_width)
		"pre-wrap":
			_show_pre_wrap_scroll(target_width)
		"nowrap":
			_show_horizontal_scroll(target_width)
		"pre":
			_show_pre_scroll(target_width)
		_:
			_show_horizontal_scroll(target_width)


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
	# CSS-like:
	# white-space: nowrap;
	#
	# Il testo non va a capo.
	# La pergamena tende ad allargarsi orizzontalmente.
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
	
	_resize_parchment(Vector2(needed_width, needed_height))


func _show_wrapped_scroll(target_width: float) -> void:
	# CSS-like:
	# white-space: normal;
	#
	# Soluzione corretta:
	# il testo va a capo e la pergamena cresce verticalmente.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2000.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	_resize_parchment(Vector2(target_width, needed_height))


func _show_pre_scroll(target_width: float) -> void:
	# CSS-like:
	# white-space: pre;
	#
	# Mantiene spazi e line breaks.
	# In pratica è rigido e può causare overflow orizzontale.
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
	
	_resize_parchment(Vector2(needed_width, needed_height))


func _show_pre_wrap_scroll(target_width: float) -> void:
	# CSS-like:
	# white-space: pre-wrap;
	#
	# Permette il wrap, ma mantiene spazi e line breaks.
	# Non è la risposta che accettiamo come corretta, ma visivamente
	# può sembrare abbastanza buona.
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var content_width: float = target_width - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	
	_set_label_rect(content_width, 2000.0)
	
	await get_tree().process_frame
	
	var needed_height: float = max(
		MIN_SCROLL_HEIGHT,
		preview_label.get_content_height() + TEXT_MARGIN_TOP + TEXT_MARGIN_BOTTOM
	)
	
	_resize_parchment(Vector2(target_width, needed_height))


func _set_label_rect(label_width: float, label_height: float) -> void:
	preview_label.position = Vector2(TEXT_MARGIN_LEFT, TEXT_MARGIN_TOP)
	preview_label.size = Vector2(label_width, label_height)
	preview_label.custom_minimum_size = Vector2.ZERO


func _resize_parchment(target_size: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(parchment, "size", target_size, 0.35)
	
	tween.finished.connect(func() -> void:
		_update_label_after_resize(target_size)
	)


func _update_label_after_resize(parchment_size: Vector2) -> void:
	var label_width: float = parchment_size.x - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT
	var label_height: float = parchment_size.y - TEXT_MARGIN_TOP - TEXT_MARGIN_BOTTOM
	
	preview_label.position = Vector2(TEXT_MARGIN_LEFT, TEXT_MARGIN_TOP)
	preview_label.size = Vector2(label_width, label_height)


func _on_run_pressed() -> void:
	var final_width: String = width_option.get_item_text(width_option.selected)
	var final_space: String = space_option.get_item_text(space_option.selected)
	
	if final_width == "100%" and final_space == "normal":
		verification_requested.emit(true)
	else:
		verification_requested.emit(false)


func update_image(tex: Texture2D) -> void:
	pass
