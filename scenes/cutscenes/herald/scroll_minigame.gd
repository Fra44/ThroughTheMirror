extends CanvasLayer

signal verification_requested(is_successful: bool)

@onready var width_option = %WidthOption
@onready var space_option = %SpaceOption
@onready var preview_label = %PreviewLabel
@onready var run_button = %RunCodeButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Quando cambiamo una tendina, aggiorniamo la pergamena in tempo reale!
	width_option.item_selected.connect(_on_option_changed)
	space_option.item_selected.connect(_on_option_changed)
	
	run_button.pressed.connect(_on_run_pressed)
	
	# Forziamo l'aggiornamento visivo iniziale allo stato "rotto"
	_update_preview()

func _on_option_changed(_index: int) -> void:
	_update_preview()

func _update_preview() -> void:
	var current_width = width_option.get_item_text(width_option.selected)
	var current_space = space_option.get_item_text(space_option.selected)
	
	# --- SIMULAZIONE DELLA PROPRIETÀ "white-space" ---
	if current_space == "nowrap":
		# ROTTO: Il testo non va a capo
		preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	elif current_space == "normal":
		# CORRETTO: Il testo va a capo seguendo i limiti del contenitore
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	else:
		# Comportamenti ibridi per le opzioni sbagliate
		preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		
	# --- SIMULAZIONE DELLA PROPRIETÀ "width" ---
	if current_width == "1920px":
		# ROTTO: Forziamo la Label a essere larghissima, causando lo scroll orizzontale
		preview_label.custom_minimum_size.x = 1500 
	elif current_width == "100%":
		# CORRETTO: Togliamo il limite forzato, permettendo al testo di rientrare nel MarginContainer
		preview_label.custom_minimum_size.x = 0
	elif current_width == "800px":
		preview_label.custom_minimum_size.x = 800
	else:
		preview_label.custom_minimum_size.x = 1000

func _on_run_pressed() -> void:
	var final_width = width_option.get_item_text(width_option.selected)
	var final_space = space_option.get_item_text(space_option.selected)
	
	# CONTROLLO VITTORIA: Se ha scelto 100% e normal, ha vinto!
	if final_width == "100%" and final_space == "normal":
		verification_requested.emit(true)
	else:
		verification_requested.emit(false)

# Funzione obbligatoria nel caso la cutscene provi a passarti l'immagine (come nell'Archivista)
func update_image(tex: Texture2D) -> void:
	pass
