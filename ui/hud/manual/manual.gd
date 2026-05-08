extends CanvasLayer

# Percorso dello stampo (assicurati che il file si chiami esattamente così!)
const ENTRY_SCENE = preload("res://ui/hud/manual/ManualEntry.tscn")

@onready var impairment_list = $MainContainer/BookBackground/LeftPage/MarginContainer/ScrollContainer/ImpairmentList
@onready var title_label = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/Title
@onready var description = $MainContainer/BookBackground/RightPage/MarginContainer/DetailView/Description

func _ready():
	hide() # Il libro parte chiuso
	
	# Fondamentale: permette al manuale di funzionare anche quando il gioco è in pausa
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Colleghiamo i segnalibri (Tabs) via codice
	$MainContainer/BookBackground/TabsContainer/TabImpairments.pressed.connect(update_impairment_list)
	$MainContainer/BookBackground/TabsContainer/TabWCAG.pressed.connect(update_wcag_list)
	# Questo serve per il debug estremo
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(node: Control):
	print("Il focus ora è su: ", node.name)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Click registrato dal Manuale a coordinate: ", event.position)
		
func _input(event):
	# Apri/Chiudi il libro con il tasto configurato (es. "B")
	if event.is_action_pressed("ui_book"): 
		toggle_manual()

func toggle_manual():
	visible = !visible
	
	if visible:
		update_impairment_list() # Di default mostra gli impairment
		
		# --- LOGICA PAUSA E MOUSE ---
		get_tree().paused = true # Ferma il mondo di gioco
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Mostra il mouse per interagire
	else:
		# --- RIPRISTINO GIOCO ---
		get_tree().paused = false # Riattiva il tempo di gioco
		# Se il tuo gioco è in prima persona o non usa il mouse normalmente, 
		# potresti voler usare MOUSE_MODE_CAPTURED qui sotto.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func update_impairment_list():
	_clear_list()
	# Cicla attraverso gli impairment scoperti nel DiscoveryManager (Autoload)
	for impairment in DiscoveryManager.discovered_impairments:
		_add_entry(impairment)

func update_wcag_list():
	_clear_list()
	# Cicla attraverso le WCAG scoperte nel DiscoveryManager (Autoload)
	for wcag in DiscoveryManager.discovered_wcag:
		_add_entry(wcag)

func _clear_list():
	# Svuota la lista a sinistra prima di ripopolarla
	for child in impairment_list.get_children():
		child.queue_free()

func _add_entry(data):
	# Istanza un nuovo bottone dallo "stampo" ManualEntry.tscn
	var new_entry = ENTRY_SCENE.instantiate()
	impairment_list.add_child(new_entry)
	
	# Configura il bottone con i dati (nome, ecc.)
	new_entry.setup(data)
	
	# Collega il click del bottone per mostrare i dettagli nella pagina destra
	new_entry.pressed.connect(_on_entry_selected.bind(data))

func _on_entry_selected(data):
	print("Hai cliccato su: ", data.name) # Questo apparirà nella console in basso
	# Mostra il titolo in maiuscolo
	title_label.text = data.name.to_upper()
	
	# Controlla che tipo di dato è per scegliere quale testo mostrare
	if data is ImpairmentData:
		# Se è un Impairment (NPC), mostra il testo medico/sociale
		description.text = data.manual_text
	elif data is WCAGData:
		# Se è una WCAG, mostra la descrizione tecnica
		description.text = data.long_description
	else:
		description.text = "No data available."

#func _process(_delta):
	#if visible: # Solo quando il libro è aperto
		#var hovered_node = get_viewport().gui_get_hovered_control()
		#if hovered_node:
			## Stampa il nome del nodo che sta "mangiando" il mouse in questo istante
			#print("Il mouse è sopra: ", hovered_node.name)
