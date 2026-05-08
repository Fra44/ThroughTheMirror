extends CanvasLayer

var manual_instance: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var book_button = $Control/MarginContainer/PanelContainer/HBoxContainer/BookButton
	book_button.pressed.connect(_on_book_button_pressed)
	set_process(true)

func _process(_delta):
	if Input.is_action_just_pressed("ui_book"):
		_on_book_button_pressed()

func _on_book_button_pressed():
	if manual_instance == null:
		var manual_scene = preload("res://ui/hud/manual/Manual.tscn")
		manual_instance = manual_scene.instantiate()
		get_tree().root.add_child(manual_instance)
	if manual_instance.visible:
		manual_instance.close_manual()
	else:
		manual_instance.open_manual()
