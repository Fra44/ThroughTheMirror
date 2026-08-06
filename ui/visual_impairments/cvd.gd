extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_active: bool = false
var tween: Tween

# Valori modificalbili
const TARGET_INTENSITY = 1.0 # 1.0 significa che l'effetto è applicato al 100%
const TRANSITION_TIME = 0.8 
# -----------------------------------------------------

func _ready() -> void:
	# Ignora la pausa del gioco per permettere le animazioni
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Gruppo specifico per i tag della Cutscene (#activate_shader / #deactivate_shader)
	add_to_group("cvd_shader") 
	# Gruppo generico per far capire all'HUD che c'è uno shader attivo (per l'icona ON/OFF)
	add_to_group("visual_shaders")
	
	visible = true 
	_update_shader(0.0) # Resetta l'effetto all'avvio (0.0 = visione normale)

# Funzione richiamabile dall'esterno per forzare l'attivazione/disattivazione
func toggle_effect(activate: bool) -> void:
	if is_active == activate: return # Evita di riprodurre l'animazione se è già nello stato corretto
	is_active = activate
	_animate_vision(is_active)

func _animate_vision(activate: bool) -> void:
	if tween:
		tween.kill() # Ferma le animazioni precedenti
	
	# Creiamo il tween. (Non serve set_parallel(true) perché abbiamo un solo parametro, ma fa lo stesso)
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Calcoliamo il bersaglio: se attiviamo va a TARGET_INTENSITY (1.0), altrimenti torna a 0.0
	var target = TARGET_INTENSITY if activate else 0.0
	
	var mat = color_rect.material
	
	# Animazione fluida del parametro "intensity" del tuo shader
	tween.tween_property(mat, "shader_parameter/intensity", target, TRANSITION_TIME)

func _update_shader(intensity_val: float) -> void:
	var mat = color_rect.material
	mat.set_shader_parameter("intensity", intensity_val)
