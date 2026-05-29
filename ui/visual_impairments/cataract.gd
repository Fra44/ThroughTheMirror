extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

# --- DECLARATION THAT MUST BE AT THE TOP ---
var is_active: bool = false
var tween: Tween

# Values to be changed
const TARGET_BLUR = 2.4
const TARGET_DESAT = 0.6
const TARGET_TINT = 0.3
const TARGET_CONTRAST = 0.8
const TRANSITION_TIME = 0.8 
# -----------------------------------------------------

func _ready() -> void:
	# FONDAMENTALE: Ignora la pausa del gioco per permettere le animazioni
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Aggiungiamo questo nodo a un gruppo per trovarlo facilmente dalla cutscene
	add_to_group("cataract_shader") 
	add_to_group("visual_shaders")
	
	visible = true 
	_update_shader(0.0, 0.0, 0.0, 1.0) # Initial reset

# --- _input rimosso! Il tasto M non funziona più. ---

# Nuova funzione richiamabile dall'esterno per forzare l'attivazione/disattivazione
func toggle_effect(activate: bool) -> void:
	if is_active == activate: return # Evita di riprodurre l'animazione se è già nello stato corretto
	is_active = activate
	_animate_vision(is_active)

func _animate_vision(activate: bool) -> void:
	if tween:
		tween.kill() # Stop previous animations
	
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var b = TARGET_BLUR if activate else 0.0
	var d = TARGET_DESAT if activate else 0.0
	var t = TARGET_TINT if activate else 0.0
	var c = TARGET_CONTRAST if activate else 1.0
	
	var mat = color_rect.material
	
	# Fluid animations of the changed parameters
	tween.tween_property(mat, "shader_parameter/blur_lod", b, TRANSITION_TIME)
	tween.tween_property(mat, "shader_parameter/desaturation", d, TRANSITION_TIME)
	tween.tween_property(mat, "shader_parameter/tint_amount", t, TRANSITION_TIME)
	tween.tween_property(mat, "shader_parameter/contrast", c, TRANSITION_TIME)

func _update_shader(b: float, d: float, t: float, c: float) -> void:
	var mat = color_rect.material
	mat.set_shader_parameter("blur_lod", b)
	mat.set_shader_parameter("desaturation", d)
	mat.set_shader_parameter("tint_amount", t)
	mat.set_shader_parameter("contrast", c)
