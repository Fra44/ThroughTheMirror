extends CanvasLayer

const ENTRY_SCENE = preload("res://ui/hud/manual/ManualEntry.tscn")

# Stato di apertura del manuale
var is_open: bool = false

@onready var impairment_list = $MainContainer/BookBackground/LeftPage/MarginContainer/VBoxContainer/ScrollContainer/ImpairmentList
@onready var title_label = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame/Title
@onready var description = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/ScrollContainer/Description

# --- AGGIUNTE PER LE WCAG CORRELATE ---
@onready var related_wcag_container = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer
@onready var wcag_value_label = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer/WcagLabel
@onready var jump_button = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/RelatedWcagContainer/LinkButton
@onready var icon_frame = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame
@onready var icon = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/IconFrame/Icon
@onready var page_title = $MainContainer/BookBackground/LeftPage/MarginContainer/VBoxContainer/PageTitle

var current_related_wcag: Resource = null
# ---------------------------------------

# Funzione per chiudere forzatamente il manuale
func close_manual():
	is_open = false
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Funzione per aprire forzatamente il manuale
func open_manual():
	is_open = true
	visible = true
	update_impairment_list()
	_clear_details()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready():
	hide() # Il libro parte chiuso
	is_open = false
	# Fondamentale: permette al manuale di funzionare anche quando il gioco è in pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	# Colleghiamo i segnalibri (Tabs) via codice
	$MainContainer/BookBackground/TabsContainer/TabImpairments.pressed.connect(update_impairment_list)
	$MainContainer/BookBackground/TabsContainer/TabWCAG.pressed.connect(update_wcag_list)
	# --- AGGIUNTA: Colleghiamo il tasto freccia e nascondiamo il contenitore ---
	jump_button.pressed.connect(_on_jump_button_pressed)
	related_wcag_container.modulate.a = 0
	# ---------------------------------------------------------------------------
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(node: Control):
	print("Il focus ora è su: ", node.name)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Click registrato dal Manuale a coordinate: ", event.position)
		


func toggle_manual():
	is_open = !is_open
	visible = is_open
	if is_open:
		update_impairment_list() # Di default mostra gli impairment
		_clear_details()
		# --- LOGICA PAUSA E MOUSE ---
		get_tree().paused = true # Ferma il mondo di gioco
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Mostra il mouse per interagire
	else:
		# --- RIPRISTINO GIOCO ---
		get_tree().paused = false # Riattiva il tempo di gioco
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_impairment_list():
	_clear_list()
	_clear_details()
	page_title.text = "Discovered Impairments"
	for impairment in DiscoveryManager.discovered_impairments:
		_add_entry(impairment)

func update_wcag_list():
	_clear_list()
	_clear_details()
	page_title.text = "Discovered WCAGs"
	for wcag in DiscoveryManager.discovered_wcag:
		_add_entry(wcag)

func _clear_list():
	for child in impairment_list.get_children():
		child.queue_free()

func _add_entry(data):
	var new_entry = ENTRY_SCENE.instantiate()
	impairment_list.add_child(new_entry)
	new_entry.setup(data)
	new_entry.pressed.connect(_on_entry_selected.bind(data))

func _on_entry_selected(data):
	if icon_frame:
			icon_frame.modulate.a = 1
	
	# Gestione dinamica del nome (Impairment usa .name, WCAG usa .id)
	var display_name = ""
	if data is ImpairmentData:
		display_name = data.name
	elif data is WCAGData:
		display_name = data.id
	
	print("Hai cliccato su: ", display_name)
	title_label.text = display_name
	
	if data is ImpairmentData:
		description.text = data.manual_text
		# --- AGGIUNTA: Mostra la WCAG correlata se esiste ---
		if data.related_wcag:
			related_wcag_container.modulate.a = 1
			# Usiamo .id perché WCAGData non ha la proprietà .name
			wcag_value_label.text = data.related_wcag.id
			current_related_wcag = data.related_wcag
		else:
			related_wcag_container.modulate.a = 0
			current_related_wcag = null
		# ----------------------------------------------------
	elif data is WCAGData:
		description.text = data.long_description
		# --- AGGIUNTA: Nascondi se siamo già in una WCAG ---
		related_wcag_container.modulate.a = 0
		current_related_wcag = null
		# ----------------------------------------------------
	else:
		description.text = "No data available."

# --- AGGIUNTA: Funzione per saltare alla WCAG ---
func _on_jump_button_pressed():
	if current_related_wcag:
		update_wcag_list()
		_on_entry_selected(current_related_wcag)
# ------------------------------------------------
func _clear_details():
	title_label.text = ""
	description.text = ""
	related_wcag_container.modulate.a = 0
	
	# Se hai un riferimento all'icona (quella dentro IconFrame), 
	# nascondila o togli la texture:
	
	if icon:
		icon.texture = null
	
	if icon_frame:
			icon_frame.modulate.a = 0
		
	
