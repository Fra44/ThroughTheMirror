extends CanvasLayer

var manual_instance: Node = null

# --- RIFERIMENTI AI NODI MIRROR E MANUALE (Lasciati intatti come i tuoi originali) ---
@onready var mirror_button = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/MirrorButton
@onready var status_label = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/Status
@onready var book_button = $ToolsHUD/MarginContainer/PanelContainer/HBoxContainer/BookButton

# --- RIFERIMENTI AI NODI DELLE IMPOSTAZIONI ---
@onready var settings_button = %SettingsButton
@onready var settings_overlay = %SettingsOverlay
@onready var volume_slider = %VolumeSlider
@onready var close_button = %CloseMenuButton
@onready var main_menu_button = %MainMenuButton

# --- RIFERIMENTO AL TUTORIAL (Assicurati che il nodo si chiami %TutorialPanel nell'editor) ---
@onready var tutorial_panel = get_node_or_null("%TutorialPanel")
var tutorial_fade_started: bool = false # Il lucchetto per il timer

# --- TEXTURE DEL MANUALE ---
var normal_book_texture: Texture2D
var notification_book_texture = preload("res://assets/book/book_notification_icon.png")

# --- AUDIO ---
var master_bus = AudioServer.get_bus_index("Master")

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
	
	# --- SETUP INIZIALE IMPOSTAZIONI ---
	settings_overlay.visible = false
	var current_db = AudioServer.get_bus_volume_db(master_bus)
	volume_slider.value = db_to_linear(current_db)
	
	# --- SETUP INIZIALE TUTORIAL ---
	if tutorial_panel != null:
		tutorial_panel.visible = true
		tutorial_panel.modulate.a = 1.0
	
	# ASCOLTIAMO IL DISCOVERY MANAGER
	if DiscoveryManager:
		DiscoveryManager.new_discovery.connect(_on_new_discovery)

# --- CONTROLLO INPUT PER IL TUTORIAL ---
func _input(event: InputEvent) -> void:
	# Controlliamo il movimento solo se il tutorial c'è e non è già in dissolvenza
	if tutorial_panel != null and not tutorial_fade_started:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or \
		   event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_start_tutorial_sequence()

func _process(_delta):
	# Scorciatoia da tastiera per il manuale (es. tasto M)
	if Input.is_action_just_pressed("ui_book"):
		_on_book_button_pressed()
		
	# Scorciatoia da tastiera per le impostazioni (tasto P)
	if Input.is_action_just_pressed("ui_settings"):
		if settings_overlay.visible:
			_close_settings()
		else:
			_on_settings_button_pressed()
		
	# Chiamiamo la funzione di aggiornamento UI ad ogni frame
	_update_mirror_hud()


# --- LOGICA SCOMPARSA TUTORIAL ---
func _start_tutorial_sequence() -> void:
	tutorial_fade_started = true # Chiudiamo il lucchetto
	
	# 1. Delay di lettura
	await get_tree().create_timer(2.5).timeout
	if tutorial_panel == null: return
	
	# 2. Dissolvenza lunga
	var tween = create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 0.0, 10.0)
	
	await tween.finished
	if tutorial_panel != null:
		tutorial_panel.visible = false


# --- GESTIONE IMPOSTAZIONI ---
func _on_settings_button_pressed() -> void:
	get_tree().paused = true
	settings_overlay.visible = true

func _close_settings() -> void:
	get_tree().paused = false
	settings_overlay.visible = false

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
	else:
		status_label.text = " Status: \nDormant"
		
	mirror_button.disabled = not is_any_shader_active

func _on_book_button_pressed():
	book_button.texture_normal = normal_book_texture
	
	if manual_instance == null:
		var manual_scene = preload("res://ui/hud/manual/Manual.tscn")
		manual_instance = manual_scene.instantiate()
		get_tree().root.add_child(manual_instance)
		
	if manual_instance.visible:
		manual_instance.close_manual()
		# Ho rimosso la telemetria qui, ci pensa close_manual()!
	else:
		manual_instance.open_manual()
		
		# --- TELEMETRIA: Il manuale si sta aprendo ---
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_manual_open()

func _set_pause_mode_recursive(node: Node, mode: int) -> void:
	node.process_mode = mode 
	for child in node.get_children():
		if child is Node:
			_set_pause_mode_recursive(child, mode)
