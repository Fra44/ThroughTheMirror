extends CanvasLayer

signal cutscene_finished

@onready var portrait: TextureRect = $Portrait
@onready var balloon: Node = $Balloon

var current_resource: Resource = null
var current_impairment: ImpairmentData = null 
var spawned_minigame: Node = null
var wait_for_debug: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Connessione fine dialogo globale
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Connessione al segnale del Balloon per cambiare portrait o attivare eventi
	if is_instance_valid(balloon) and balloon.has_signal("line_changed"):
		balloon.line_changed.connect(_on_balloon_line_changed)

# Ora accettiamo anche l'oggetto impairment
func start_cutscene(dialogue_res: Resource, impairment: ImpairmentData, title: String = "start", initial_portrait_path: String = "") -> void:
	if dialogue_res == null:
		return
		
	current_resource = dialogue_res
	current_impairment = impairment 
	visible = true
	
	# Caricamento portrait iniziale
	if initial_portrait_path != "" and ResourceLoader.exists(initial_portrait_path):
		portrait.texture = load(initial_portrait_path)
	
	get_tree().paused = true
	
	if is_instance_valid(balloon):
		balloon.process_mode = Node.PROCESS_MODE_ALWAYS
		balloon.start(dialogue_res, title)

func _on_balloon_line_changed(line: DialogueLine) -> void:
	for tag in line.tags:
		# Gestione cambio immagine: # portrait=res://...
		if tag.begins_with("portrait="):
			var path = tag.split("=")[1].strip_edges()
			if ResourceLoader.exists(path):
				portrait.texture = load(path)
			else:
				push_warning("Cutscene: Immagine non trovata: " + path)
		
		# TRIGGER DEBUG WINDOW
		if tag == "show_debug" and current_impairment != null:
			wait_for_debug = true
				
		# --- ACCENSIONE SHADER CVD (Daltonismo) ---
		if tag == "activate_shader":
			var shaders = get_tree().get_nodes_in_group("cvd_shader")
			if shaders.size() > 0:
				shaders[0].toggle_effect(true)
			
			if current_impairment and DiscoveryManager:
				DiscoveryManager.discover_impairment(current_impairment)
				
		# --- SPEGNIMENTO SHADER CVD ---
		if tag == "deactivate_shader":
			var shaders = get_tree().get_nodes_in_group("cvd_shader")
			if shaders.size() > 0:
				shaders[0].toggle_effect(false)
				
		# --- CHIUSURA MINIGIOCO ---
		if tag == "close_minigame":
			if spawned_minigame != null and is_instance_valid(spawned_minigame):
				spawned_minigame.queue_free()
				spawned_minigame = null
			
			portrait.visible = true
			if has_node("Dim"):
				$Dim.visible = true
				
		# --- NUOVO: MOSTRA I SIMBOLI ---
		if tag == "show_symbols":
			var symbols = get_tree().get_nodes_in_group("gate_symbols")
			for s in symbols:
				s.visible = true
				
		# --- NUOVO: APRI IL CANCELLO ---
		if tag == "open_gate":
			var gate = get_tree().get_first_node_in_group("gate_door")
			if gate and gate.has_method("open_door"):
				gate.open_door()
		
		# --- GESTIONE MINIGIOCO RAGGI ---
		if tag == "minigame_menu":
			# Carichiamo la nuova scena vuota del minigioco dei raggi
			var menu_scene = preload("res://scenes/cutscenes/guardian/RaysMinigame.tscn")
			var menu_instance = menu_scene.instantiate()
			get_tree().root.add_child(menu_instance)
			spawned_minigame = menu_instance
			
			# Questo segnale funzionerà non appena aggiungerai "signal verification_requested(is_successful: bool)" al tuo RaysMinigame.gd
			if spawned_minigame.has_signal("verification_requested"):
				spawned_minigame.verification_requested.connect(_on_minigame_verification)

			if spawned_minigame.has_signal("preview_symbol_updated"):
				spawned_minigame.preview_symbol_updated.connect(_on_minigame_preview_symbol_placed)
			
			# ---> NUOVA RIGA: Connettiamo il segnale di reset <---
			if spawned_minigame.has_signal("preview_symbols_cleared"):
				spawned_minigame.preview_symbols_cleared.connect(_on_minigame_preview_symbols_cleared)
			
			portrait.visible = false
			if has_node("Dim"):
				$Dim.visible = false
		
		# --- SPOSTA LA TELECAMERA VERSO UN PUNTO DEL MONDO ---
		if tag == "pan_camera":
			var cam = get_tree().get_first_node_in_group("MainCamera")
			var target = get_tree().get_first_node_in_group("rays_minigame_camera_target")
			
			if cam and target:
				print("Cutscene: Sposto la telecamera verso il target nel mondo...")
				var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(cam, "global_position", target.global_position, 2.5)

		# --- RIPRISTINA LA TELECAMERA ---
		if tag == "reset_camera":
			var cam = get_tree().get_first_node_in_group("MainCamera")
			if cam:
				print("Cutscene: Ripristino la telecamera sul giocatore.")
				var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				# Riportare la 'position' locale a Vector2.ZERO la ricentra perfettamente sul Player!
				tween.tween_property(cam, "position", Vector2.ZERO, 2.5)

# --- NUOVA FUNZIONE HANDLER: Riceve il segnale dal minigioco e aggiorna il mondo ---
func _on_minigame_preview_symbol_placed(ray_color: String, symbol_name: String) -> void:
	# 1. Calcoliamo l'indirizzo dell'asset della texture da caricare
	# ASSUNZIONE: le tue texture visive nel mondo sono salvate in una cartella specifica, 
	# e il loro nome file corrisponde esattamente al "symbol_name" (es. res://assets/world_symbols/circle.png)
	# Modifica questo percorso per puntare alla cartella giusta dei tuoi assets visivi del mondo!
	var texture_path = "res://assets/diamond_rays/" + symbol_name + "_" + ray_color + ".png"
	
	# 2. Proviamo a caricare la texture
	if not ResourceLoader.exists(texture_path):
		push_error("Cutscene Preview: Texture non trovata per il mondo: " + texture_path)
		return
		
	var target_texture = load(texture_path)
	
	# 3. Troviamo il nodo sprite corretto nel mondo e gli applichiamo la texture
	var group_name = "ray_symbol_preview_" + ray_color
	var targets = get_tree().get_nodes_in_group(group_name)
	
	for t in targets:
		if t is Sprite2D:
			# Applichiamo la texture
			t.texture = target_texture
			# Rendiamo lo sprite visibile!
			t.visible = true
			# Facciamo un print di conferma
			print("Preview: Aggiornato sprite ", ray_color, " con ", symbol_name, " nel mondo!")

# --- NUOVA FUNZIONE HANDLER: Nasconde tutti i simboli dal mondo ---
func _on_minigame_preview_symbols_cleared() -> void:
	# Spegniamo i rossi
	var red_targets = get_tree().get_nodes_in_group("ray_symbol_preview_red")
	for t in red_targets:
		if t is Sprite2D:
			t.visible = false
			
	# Spegniamo i verdi
	var green_targets = get_tree().get_nodes_in_group("ray_symbol_preview_green")
	for t in green_targets:
		if t is Sprite2D:
			t.visible = false
			
	print("Preview: Simboli nascosti dal mondo (Reset).")

# FUNZIONE CHIAMATA DAL SEGNALE DI VITTORIA DEL MINIGIOCO
# ---> AGGIORNATA LA FIRMA PER ACCETTARE IL SECONDO PARAMETRO <---
func _on_minigame_verification(is_successful: bool, winning_symbol: String = "") -> void:
	if is_successful:
		if is_instance_valid(balloon):
			# Controlliamo quale simbolo ha usato per vincere
			if winning_symbol == "circle":
				balloon.start(current_resource, "circle")
			elif winning_symbol == "tick":
				balloon.start(current_resource, "tick")
			else:
				# Fallback di sicurezza (che nel tuo dialogo fa => tick)
				balloon.start(current_resource, "win_reaction") 
	else:
		if is_instance_valid(balloon):
			balloon.start(current_resource, "fail_reaction")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == current_resource:
		# EVITIAMO CHE LA CUTSCENE SI CHIUDA SE IL MINIGIOCO È ATTIVO
		if spawned_minigame != null and is_instance_valid(spawned_minigame):
			get_tree().paused = true
			
			# IL BALLOON SI È APPENA CHIUSO! CONTROLLIAMO SE DOBBIAMO MOSTRARE IL DEBUG
			if wait_for_debug and DebugManager:
				DebugManager.setup_display(current_impairment)
				wait_for_debug = false 
				
				# Aspettiamo 1 secondo (il tempo dell'animazione della telecamera)
				await get_tree().create_timer(1.0).timeout
				
				# MOSTRA I COMANDI DEL MINIGIOCO (quando lo avrai implementato)
				if spawned_minigame.has_method("show_ui"):
					spawned_minigame.show_ui()
				
			return
			
		_end_cutscene()

func _end_cutscene() -> void:
	if DebugManager and DebugManager.visible:
		DebugManager.hide_display()
	
	# --- SISTEMA DI SICUREZZA DELLA TELECAMERA ---
	var cam = get_tree().get_first_node_in_group("MainCamera")
	if cam:
		cam.position = Vector2.ZERO # La ricentriamo all'istante sul giocatore
	# ----------------------------------------------------
	
	if spawned_minigame == null or not is_instance_valid(spawned_minigame):
		get_tree().paused = false
	visible = false
	current_resource = null
	current_impairment = null
	cutscene_finished.emit()
	
	# SPEGNIAMO LO SHADER CVD (Sicurezza)
	var shaders = get_tree().get_nodes_in_group("cvd_shader")
	if shaders.size() > 0:
		shaders[0].toggle_effect(false)
		
	queue_free()
