extends CanvasLayer

var manual_instance: Node = null

# Recuperiamo i riferimenti ai nuovi nodi dell'HUD
@onready var mirror_button = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/MirrorButton
@onready var status_label = $MirrorHUD/MarginContainer/PanelContainer2/MarginContainer/HBoxContainer/Status

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var book_button = $ToolsHUD/MarginContainer/PanelContainer/HBoxContainer/BookButton
	book_button.pressed.connect(_on_book_button_pressed)
	# Ensure all HUD children remain interactive while the game is paused

func _process(_delta):
	if Input.is_action_just_pressed("ui_book"):
		_on_book_button_pressed()
		
	# Chiamiamo la funzione di aggiornamento UI ad ogni frame
	_update_mirror_hud()

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
	# Impostando "disabled", Godot userà in automatico la texture associata allo stato Disabled
	# NOTA: se il bottone è disabled, non potrà essere cliccato! 
	# Se in futuro vorrai renderlo cliccabile per accendere/spegnere, dovrai usare un approccio 
	# diverso (es. scambiare manualmente mirror_button.texture_normal = load("..."))
	mirror_button.disabled = not is_any_shader_active


func _on_book_button_pressed():
	if manual_instance == null:
		var manual_scene = preload("res://ui/hud/manual/Manual.tscn")
		manual_instance = manual_scene.instantiate()
		get_tree().root.add_child(manual_instance)
	if manual_instance.visible:
		manual_instance.close_manual()
	else:
		manual_instance.open_manual()

func _set_pause_mode_recursive(node: Node, mode: int) -> void:
	# Set pause_mode for this node and all children so UI works while game paused
	node.process_mode = mode # In Godot 4 pause_mode è stato sostituito da process_mode
	for child in node.get_children():
		if child is Node:
			_set_pause_mode_recursive(child, mode)
