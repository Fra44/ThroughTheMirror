extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_active: bool = false
var tween: Tween

const TARGET_BLUR = 2.5 # Quanto forte deve essere la sfocatura
const TRANSITION_TIME = 1.0 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# GRUPPI FONDAMENTALI
	add_to_group("low_vision_shader") 
	add_to_group("visual_shaders")
	
	visible = true 
	_update_shader(0.0)

func toggle_effect(activate: bool) -> void:
	if is_active == activate: return 
	is_active = activate
	_animate_vision(is_active)

func _animate_vision(activate: bool) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target = TARGET_BLUR if activate else 0.0
	var mat = color_rect.material
	
	tween.tween_property(mat, "shader_parameter/blur_amount", target, TRANSITION_TIME)

func _update_shader(blur_val: float) -> void:
	var mat = color_rect.material
	mat.set_shader_parameter("blur_amount", blur_val)
