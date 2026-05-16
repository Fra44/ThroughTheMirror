extends CanvasLayer

var manual_instance: Node = null

# --- RIFERIMENTI AI NODI MIRROR & MANUALE ---
@onready var mirror_button = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/MirrorButton
@onready var status_label = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/Status
@onready var book_button = $ToolsHUD/MarginContainer/PanelContainer/HBoxContainer/BookButton

# --- RIFERIMENTI AI NODI DELLE IMPOSTAZIONI (Usa gli Unique Names %) ---
@onready var settings_button = %SettingsButton
@onready var settings_overlay = %SettingsOverlay
@onready var volume_slider = %VolumeSlider
@onready var close_button = %CloseMenuButton
@onready var main_menu_button = %MainMenuButton

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
	
	# ASCOLTIAMO IL DISCOVERY MANAGER
	if DiscoveryManager:
		DiscoveryManager.new_discovery.connect(_on_new_discovery)

func _process(_delta):
	# Scorciatoia da tastiera per il manuale (es. tasto M)
	if Input.is_action_just_pressed("ui_book"):
		_on_book_button_pressed()
		
	# Scorciatoia da tastiera per le impostazioni (opzionale, es. tasto ESC o S)
	# if Input.is_action_just_pressed("ui_cancel"):
	# 	if settings_overlay.visible:
	# 		_close_settings()
	# 	else:
	# 		_on_settings_button_pressed()
		
	# Chiamiamo la funzione di aggiornamento UI ad ogni frame
	_update_mirror_hud()

# --- GESTIONE IMPOSTAZIONI ---

func _on_settings_button_pressed() -> void:
	# Mettiamo in pausa il gioco e mostriamo il menu
	get_tree().paused = true
	settings_overlay.visible = true

func _close_settings() -> void:
	# Togliamo la pausa e nascondiamo il menu
	get_tree().paused = false
	settings_overlay.visible = false

func _on_volume_changed(value: float) -> void:
	# Il volume in Godot non è lineare ma logaritmico (Decibel)
	# Convertiamo il valore dello slider (da 0.0 a 1.0) in decibel
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	
	# Se lo slider è a 0, mutiamo completamente il bus per sicurezza
	AudioServer.set_bus_mute(master_bus, value == 0.0)

func _on_main_menu_pressed() -> void:
	# Quando crei il Main Menu, rimuovi il print e scommenta la riga sotto!
	print("Caricamento Main Menu in corso... (Crea la scena prima!)")
	
	get_tree().paused = false # Togliamo la pausa prima di cambiare scena!
	# get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn") 

# --- GESTIONE SCOPERTE ED HUD ---

func _on_new_discovery(_item) -> void:
	# Cambiamo la texture per mostrare la notifica
	book_button.texture_normal = notification_book_texture

func _update_mirror_hud() -> void:
	var is_any_shader_active = false
	
	# Controlliamo tutti gli shader presenti nel gioco
	var shaders = get_tree().get_nodes_in_group("visual_shaders")
	for shader in shaders:
		# Se anche solo UNO è attivo, flagghiamo a true e interrompiamo il ciclo
		if "is_active" in shader and shader.is_active:
			is_any_shader_active = true
			break
			
	# Aggiorniamo la Label
	if is_any_shader_active:
		status_label.text = "ON"
	else:
		status_label.text = "OFF"
		
	# Aggiorniamo il bottone
	mirror_button.disabled = not is_any_shader_active

func _on_book_button_pressed():
	# QUANDO IL MANUALE VIENE APERTO, RIMUOVIAMO LA NOTIFICA
	book_button.texture_normal = normal_book_texture
	
	if manual_instance == null:
		var manual_scene = preload("res://ui/hud/manual/Manual.tscn")
		manual_instance = manual_scene.instantiate()
		get_tree().root.add_child(manual_instance)
		
	if manual_instance.visible:
		manual_instance.close_manual()
	else:
		manual_instance.open_manual()

func _set_pause_mode_recursive(node: Node, mode: int) -> void:
	# Set process_mode for this node and all children so UI works while game paused
	node.process_mode = mode 
	for child in node.get_children():
		if child is Node:
			_set_pause_mode_recursive(child, mode)
