extends TextureButton

var original_position: Vector2
var press_offset := Vector2(0, 8)

func _ready() -> void:
	original_position = position
	
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", original_position + press_offset, 0.06)


func _on_button_up() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", original_position, 0.08)
