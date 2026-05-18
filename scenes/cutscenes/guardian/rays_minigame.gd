extends CanvasLayer

signal verification_requested(is_successful: bool, winning_symbol: String)
signal preview_symbol_updated(ray_color, symbol_name)
signal preview_symbols_cleared

@onready var main_panel = $MarginContainer/MainPanel
@onready var run_button = $MarginContainer/MainPanel/Background/Padding/MainVBox/ButtonsHBox/RunCodeButton
@onready var reset_button = $MarginContainer/MainPanel/Background/Padding/MainVBox/ButtonsHBox/ResetButton

@onready var drop_zone_red = $MarginContainer/MainPanel/Background/Padding/MainVBox/CodeEditorPanel/CodeGrid/RedDropContainer/DropZoneRed
@onready var drop_zone_green = $MarginContainer/MainPanel/Background/Padding/MainVBox/CodeEditorPanel/CodeGrid/GreenDropContainer/DropZoneGreen

# Queste variabili conterranno l'ID (o il nome) del simbolo attualmente droppato
var current_symbol_red: String = ""
var current_symbol_green: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_panel.hide() # Nascondiamo tutto all'inizio
	
	if run_button:
		run_button.pressed.connect(_on_run_button_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)

# Chiamato dalla cutscene dopo il pan della camera
func show_ui() -> void:
	main_panel.show()
	
	# [TELEMETRIA] Inizio misurazione del Time on Task per il Livello 2
	if has_node("/root/TelemetryManager"):
		TelemetryManager.start_level("L2")

func _on_run_button_pressed() -> void:
	print("Minigame: Avvio validazione codice...")
	
	# --- LOGICA DI VITTORIA ---
	# 1. Il raggio VERDE deve essere "circle" OPPURE "tick"
	var green_is_correct = (current_symbol_green == "circle" or current_symbol_green == "tick")
	
	# 2. Il raggio ROSSO deve essere "cross"
	var red_is_correct = (current_symbol_red == "cross")
	
	# Verifichiamo se entrambe le condizioni sono soddisfatte
	if green_is_correct and red_is_correct:
		print("Risultato: CODICE CORRETTO! Emissione vittoria...")
		
		# [TELEMETRIA] Risoluzione corretta e stop del timer
		if has_node("/root/TelemetryManager"):
			TelemetryManager.end_level("L2")
			var stats = TelemetryManager.stats["L2"]
			print("[TELEMETRIA L2] Completato. Tempo totale: ", snapped(stats["total_time"], 0.1), "s | Tentativi falliti: ", stats["fails"])
		
		# ---> NUOVO: SALVIAMO LO STATO E I SIMBOLI SCELTI <---
		if DiscoveryManager:
			DiscoveryManager.level_states["gate_solved"] = true
			DiscoveryManager.level_states["gate_symbol_red"] = current_symbol_red
			DiscoveryManager.level_states["gate_symbol_green"] = current_symbol_green
		# ----------------------------------------------------
		
		verification_requested.emit(true, current_symbol_green)

	else:
		print("Risultato: CODICE ERRATO. Emissione fallimento...")
		
		# [TELEMETRIA] Errore utente registrato
		if has_node("/root/TelemetryManager"):
			TelemetryManager.track_fail("L2")
			print("[TELEMETRIA L2] Fallimento registrato. Totale attuale: ", TelemetryManager.stats["L2"]["fails"])
			
		# Opzionale: potresti voler resettare la UI o far apparire un messaggio di errore
		verification_requested.emit(false, "")

# ---> NUOVA FUNZIONE: Eseguita quando si preme RESET CODE <---
func _on_reset_button_pressed() -> void:
	# 1. Svuotiamo le variabili
	current_symbol_red = ""
	current_symbol_green = ""
	
	# 2. Ripristiniamo la grafica della UI
	if is_instance_valid(drop_zone_red) and drop_zone_red.has_method("reset"):
		drop_zone_red.reset()
	if is_instance_valid(drop_zone_green) and drop_zone_green.has_method("reset"):
		drop_zone_green.reset()
		
	# 3. Avvisiamo il mondo di nascondere i simboli
	preview_symbols_cleared.emit()
	print("Minigame: Codice resettato!")

# Questa funzione viene chiamata in automatico dalle DropZone!
func update_symbol_for_ray(ray_color: String, symbol_name: String) -> void:
	if ray_color == "red":
		current_symbol_red = symbol_name
		print("Raggio Rosso aggiornato con: ", symbol_name)
	elif ray_color == "green":
		current_symbol_green = symbol_name
		print("Raggio Verde aggiornato con: ", symbol_name)
		
	# ---> QUI INVIAMO IL SEGNALE ALL'ESTERNO <---
	preview_symbol_updated.emit(ray_color, symbol_name)
