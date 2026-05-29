extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_active: bool = false
var tween: Tween

# L'opacità massima: 0.95 lascia intravedere qualcosina (il 5% del mondo di gioco)
const TARGET_ALPHA = 0.95 
const TRANSITION_TIME = 2.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Gruppi fondamentali per la cutscene e l'HUD
	add_to_group("blindness_shader") 
	add_to_group("visual_shaders")
	
	visible = true 
	_update_shader(0.0) # Partiamo con schermo trasparente

func toggle_effect(activate: bool) -> void:
	if is_active == activate: return 
	is_active = activate
	_animate_vision(is_active)

func _animate_vision(activate: bool) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target = TARGET_ALPHA if activate else 0.0
	
	# Animiamo direttamente il canale "a" (alpha) del colore del ColorRect
	tween.tween_property(color_rect, "color:a", target, TRANSITION_TIME)

func _update_shader(alpha_val: float) -> void:
	var c = color_rect.color
	c.a = alpha_val
	color_rect.color = c
