extends CanvasLayer

const ENTRY_SCENE = preload("res://ui/hud/manual/ManualEntry.tscn")

# Stato di apertura del manuale
var is_open: bool = false

# Memorizza se il gioco era già in pausa prima di aprire il manuale
var was_paused_before_manual: bool = false

# --- BOTTONE DI CHIUSURA ---
@onready var close_button = $MainContainer/BookBackground/LeftPage/CloseButton
# ---------------------------------

@onready var impairment_list = $MainContainer/BookBackground/LeftPage/MarginContainer/VBoxContainer/ScrollContainer/ImpairmentList
@onready var title_label = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame/Title
@onready var description = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/ScrollContainer/Description

@onready var list_scroll = $MainContainer/BookBackground/LeftPage/MarginContainer/VBoxContainer/ScrollContainer
@onready var detail_scroll = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/ScrollContainer

# --- WCAG CORRELATE ---
@onready var related_wcag_container = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer
@onready var wcag_value_label = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer/WcagLabel
@onready var jump_button = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer/LinkButton
@onready var icon_frame = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame
@onready var icon = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame/Icon
@onready var page_title = $MainContainer/BookBackground/LeftPage/MarginContainer/VBoxContainer/PageTitle

var current_related_wcag: Resource = null
# ---------------------------------------


func _ready():
	hide()
	is_open = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	$MainContainer/BookBackground/TabsContainer/TabImpairments.pressed.connect(update_impairment_list)
	$MainContainer/BookBackground/TabsContainer/TabWCAG.pressed.connect(update_wcag_list)
	jump_button.pressed.connect(_on_jump_button_pressed)
	related_wcag_container.modulate.a = 0
	
	# --- COLLEGAMENTO DEL NUOVO PULSANTE ---
	if close_button:
		close_button.pressed.connect(close_manual)
	# ---------------------------------------
	
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func open_manual():
	is_open = true
	visible = true
	
	update_impairment_list()
	_clear_details()
	
	# --- LOGICA DI PAUSA ---
	# Salviamo lo stato attuale PRIMA di forzare la pausa
	was_paused_before_manual = get_tree().paused
	get_tree().paused = true
	# -----------------------
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_manual():
	is_open = false
	visible = false
	
	# --- LOGICA DI PAUSA ---
	# Ripristiniamo lo stato esattamente com'era prima
	get_tree().paused = was_paused_before_manual
	# -----------------------
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if has_node("/root/TelemetryManager"):
		TelemetryManager.track_manual_close()


func toggle_manual():
	if is_open:
		close_manual()
	else:
		open_manual()


func _on_focus_changed(node: Control):
	print("Il focus ora è su: ", node.name)


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Click registrato dal Manuale a coordinate: ", event.position)


func update_impairment_list():
	_clear_list()
	_clear_details()
	page_title.text = "Discovered Impairments"
	
	for impairment in DiscoveryManager.discovered_impairments:
		_add_entry(impairment)
	
	_reset_list_scroll()


func update_wcag_list():
	_clear_list()
	_clear_details()
	page_title.text = "Discovered WCAGs"
	
	for wcag in DiscoveryManager.discovered_wcag:
		_add_entry(wcag)
	
	_reset_list_scroll()


func _clear_list():
	for child in impairment_list.get_children():
		child.queue_free()
	
	_reset_list_scroll()


func _add_entry(data):
	var new_entry = ENTRY_SCENE.instantiate()
	impairment_list.add_child(new_entry)
	new_entry.setup(data)
	new_entry.pressed.connect(_on_entry_selected.bind(data))


func _on_entry_selected(data):
	if data == null:
		return
	
	if icon_frame:
		icon_frame.modulate.a = 1
	
	var display_name = ""
	
	if data is ImpairmentData:
		display_name = data.name
	elif data is WCAGData:
		display_name = data.id
	
	print("Hai cliccato su: ", display_name)
	title_label.text = display_name
	
	if data is ImpairmentData:
		description.text = data.manual_text
		
		if data.related_wcag:
			related_wcag_container.modulate.a = 1
			wcag_value_label.text = data.related_wcag.id
			current_related_wcag = data.related_wcag
		else:
			related_wcag_container.modulate.a = 0
			current_related_wcag = null
	
	elif data is WCAGData:
		description.text = data.long_description
		related_wcag_container.modulate.a = 0
		current_related_wcag = null
	
	else:
		description.text = "No data available."
		related_wcag_container.modulate.a = 0
		current_related_wcag = null
	
	_reset_detail_scroll()


func _on_jump_button_pressed():
	if current_related_wcag == null:
		return
	
	# IMPORTANTISSIMO:
	# Salviamo la WCAG prima di cambiare tab/lista.
	# update_wcag_list() chiama _clear_details(), che resetta current_related_wcag.
	var wcag_to_open = current_related_wcag
	
	update_wcag_list()
	
	# Aspettiamo un frame per lasciare a Godot il tempo di ricostruire la lista.
	await get_tree().process_frame
	
	_on_entry_selected(wcag_to_open)


func _clear_details():
	title_label.text = ""
	description.text = ""
	
	_reset_detail_scroll()
	
	related_wcag_container.modulate.a = 0
	current_related_wcag = null
	
	if icon:
		icon.texture = null
	
	if icon_frame:
		icon_frame.modulate.a = 0


func _reset_list_scroll() -> void:
	if not is_instance_valid(list_scroll):
		return
	
	list_scroll.scroll_vertical = 0
	call_deferred("_reset_list_scroll_deferred")


func _reset_list_scroll_deferred() -> void:
	if is_instance_valid(list_scroll):
		list_scroll.scroll_vertical = 0


func _reset_detail_scroll() -> void:
	if not is_instance_valid(detail_scroll):
		return
	
	detail_scroll.scroll_vertical = 0
	call_deferred("_reset_detail_scroll_deferred")


func _reset_detail_scroll_deferred() -> void:
	if is_instance_valid(detail_scroll):
		detail_scroll.scroll_vertical = 0
