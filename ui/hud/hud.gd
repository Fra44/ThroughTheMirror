extends CanvasLayer

var manual_instance: Node = null

# --- RIFERIMENTI AI NODI MIRROR E MANUALE ---
@onready var mirror_button = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/MirrorButton
@onready var status_label = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/Status
@onready var book_button = $ToolsHUD/MarginContainer/PanelContainer/HBoxContainer/BookButton
@onready var mirror_panel = $MirrorHUD/MarginContainer/PanelContainer2

# --- RIFERIMENTI AI NODI DELLE IMPOSTAZIONI ---
@onready var settings_button = %SettingsButton
@onready var settings_overlay = %SettingsOverlay
@onready var volume_slider = %VolumeSlider
@onready var close_button = %CloseMenuButton
@onready var main_menu_button = %MainMenuButton
@onready var show_control_button = get_node_or_null("%ShowControlsButton")

# --- RIFERIMENTO AL TUTORIAL ---
@onready var tutorial_panel = get_node_or_null("%TutorialPanel")
@onready var tutorial_close_button = get_node_or_null("%CloseButton")

# --- TEXTURE DEL MANUALE ---
var normal_book_texture: Texture2D
var notification_book_texture = preload("res://assets/book/book_notification_icon.png")

# --- AUDIO ---
var master_bus = AudioServer.get_bus_index("Master")

# Colori per il panel del Mirror: originale (#adc5c954) e awakened (#b0cf5954)
var normal_panel_color: Color = Color(173.0/255.0, 197.0/255.0, 201.0/255.0, 84.0/255.0)
var awakened_panel_color: Color = Color(176.0/255.0, 207.0/255.0, 89.0/255.0, 84.0/255.0)


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Salviamo la texture originale impostata nell'editor
	normal_book_texture = book_button.texture_normal
	
	# --- CONNESSIONI SEGNALI MANUALE E SETTINGS ---
	book_button.pressed.connect(_on_book_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_button.pressed.connect(_close_settings)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	if show_control_button != null:
		show_control_button.pressed.connect(_on_show_control_pressed)
	
	# --- SETUP INIZIALE IMPOSTAZIONI ---
	settings_overlay.visible = false
	var current_db = AudioServer.get_bus_volume_db(master_bus)
	volume_slider.value = db_to_linear(current_db)

	# Salviamo il colore originale del panel mirror (prendendo la StyleBox se presente)
	if mirror_panel:
		var sb = mirror_panel.get_theme_stylebox("panel")
		if sb and sb is StyleBoxFlat:
			normal_panel_color = sb.bg_color
	
	# --- SETUP INIZIALE TUTORIAL ---
	if tutorial_panel != null:
		tutorial_panel.visible = true
		tutorial_panel.modulate.a = 1.0

	if tutorial_close_button != null:
		tutorial_close_button.pressed.connect(_on_tutorial_close_pressed)
		
	# ASCOLTIAMO IL DISCOVERY MANAGER
	if DiscoveryManager:
		DiscoveryManager.new_discovery.connect(_on_new_discovery)


func _process(_delta):
	# Scorciatoia da tastiera per il manuale
	if Input.is_action_just_pressed("ui_book"):
		_on_book_button_pressed()
		
	# Scorciatoia da tastiera per le impostazioni
	if Input.is_action_just_pressed("ui_settings"):
		if settings_overlay.visible:
			_close_settings()
		else:
			_on_settings_button_pressed()
		
	# Aggiorna lo stato del Mirror HUD
	_update_mirror_hud()


# --- GESTIONE TUTORIAL ---
func _on_tutorial_close_pressed() -> void:
	if tutorial_panel != null:
		tutorial_panel.visible = false


func show_tutorial_panel() -> void:
	if tutorial_panel == null:
		return
	
	tutorial_panel.visible = true
	tutorial_panel.modulate.a = 1.0


func _set_tutorial_dimmed(dimmed: bool) -> void:
	if tutorial_panel == null:
		return
	
	if dimmed:
		tutorial_panel.modulate.a = 0.65
	else:
		tutorial_panel.modulate.a = 1.0


func _on_show_control_pressed() -> void:
	# Chiudiamo prima le impostazioni, così il tutorial non resta sotto l'overlay.
	_close_settings()
	
	# Poi mostriamo di nuovo il tutorial dei comandi.
	show_tutorial_panel()


# --- GESTIONE IMPOSTAZIONI ---
func _on_settings_button_pressed() -> void:
	get_tree().paused = true
	settings_overlay.visible = true
	_set_tutorial_dimmed(true)


func _close_settings() -> void:
	get_tree().paused = false
	settings_overlay.visible = false
	_set_tutorial_dimmed(false)


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus, value == 0.0)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn") 


# --- GESTIONE SCOPERTE ED HUD ---
func _on_new_discovery(_item) -> void:
	book_button.texture_normal = notification_book_texture


func _update_mirror_hud() -> void:
	var is_any_shader_active = false
	
	var shaders = get_tree().get_nodes_in_group("visual_shaders")
	for shader in shaders:
		if "is_active" in shader and shader.is_active:
			is_any_shader_active = true
			break

	if is_any_shader_active:
		status_label.text = " Status: \nAwakened"
		# Impostiamo il colore del panel quando il mirror è attivo (awakened)
		if mirror_panel:
			var sb_on = mirror_panel.get_theme_stylebox("panel")
			if sb_on and sb_on is StyleBoxFlat:
				sb_on.bg_color = awakened_panel_color
	else:
		status_label.text = " Status: \nDormant"
		# Ripristiniamo il colore originale quando dormiente
		if mirror_panel:
			var sb_off = mirror_panel.get_theme_stylebox("panel")
			if sb_off and sb_off is StyleBoxFlat:
				sb_off.bg_color = normal_panel_color
	
	mirror_button.disabled = not is_any_shader_active


func _on_book_button_pressed():
	book_button.texture_normal = normal_book_texture
	
	if manual_instance == null:
		var manual_scene = preload("res://ui/hud/manual/Manual.tscn")
		manual_instance = manual_scene.instantiate()
		get_tree().root.add_child(manual_instance)
		
	if manual_instance.visible:
		manual_instance.close_manual()
	else:
		manual_instance.open_manual()
		
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_manual_open()


func _set_pause_mode_recursive(node: Node, mode: int) -> void:
	node.process_mode = mode 
	for child in node.get_children():
		if child is Node:
			_set_pause_mode_recursive(child, mode)
