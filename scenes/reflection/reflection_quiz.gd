extends Control

# --- RIFERIMENTI AI NODI ---
# Uso i percorsi esatti basati sul tuo screenshot
@onready var question_label = $PanelContainer/MarginContainer/VBoxContainer/QuestionLabel
@onready var answers_container = $PanelContainer/MarginContainer/VBoxContainer/AnswersContainer
@onready var fact_panel = %FactPanel
@onready var fact_label = %FactPanel/Label
@onready var next_button = %NextButton

# --- DATI DEL QUIZ ---
var questions = [
	{
		"q": "Perché è importante l'attributo Alt Text nelle immagini?",
		"options": ["Per migliorare i colori", "Per gli utenti che usano Screen Reader", "Per caricare l'immagine prima"],
		"correct": 1,
		"fact": "Esatto! Nel 2024, il 54% dei siti web ha ancora immagini senza Alt Text, rendendo il web 'invisibile' a milioni di persone cieche."
	},
	{
		"q": "Cos'è il 'Reflow' (WCAG 1.4.10) che hai applicato alla pergamena?",
		"options": ["Un modo per cambiare font", "L'adattamento del testo quando si zooma", "Un effetto di trasparenza"],
		"correct": 1,
		"fact": "Esatto! Il Reflow permette di zoomare fino al 400% senza scorrimento orizzontale. Senza di esso, leggere una pagina è come guardare attraverso uno spioncino."
	}
	# Aggiungi le altre 2 qui...
]

var current_q = 0
var quiz_finished = false

func _ready():
	# 1. Colleghiamo il tasto Next
	next_button.pressed.connect(_on_next_pressed)
	
	# 2. Colleghiamo i 4 bottoni delle risposte in modo dinamico
	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is Button:
			# .bind(i) passa l'indice (0, 1, 2 o 3) alla funzione quando viene premuto
			buttons[i].pressed.connect(_on_answer_pressed.bind(i))
			
	_show_question()

func _show_question():
	fact_panel.hide()
	next_button.hide()
	
	var q_data = questions[current_q]
	question_label.text = q_data["q"]
	
	# Gestione intelligente dei bottoni: mostra solo quelli necessari
	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i < q_data["options"].size():
			btn.text = q_data["options"][i]
			btn.show()
			btn.disabled = false # Riabilitiamo il bottone per la nuova domanda
		else:
			btn.hide() # Nascondiamo i bottoni extra

func _on_answer_pressed(index: int):
	# Disabilitiamo tutti i bottoni per evitare che il giocatore ne clicchi due
	for btn in answers_container.get_children():
		btn.disabled = true
		
	var correct = (index == questions[current_q]["correct"])
	
	# Registriamo il risultato per la telemetria (Controllo se hai già creato l'Autoload)
	if has_node("/root/TelemetryManager"):
		TelemetryManager.quiz_results.append(1 if correct else 0)
	
	# Mostriamo il feedback
	if correct:
		fact_label.text = questions[current_q]["fact"]
	else:
		fact_label.text = "Sbagliato, ma non preoccuparti! " + questions[current_q]["fact"]
		
	fact_panel.show()
	next_button.text = "Prossima Domanda"
	next_button.show()

func _on_next_pressed():
	# Se siamo già alla fine, questo bottone fa da "Copia Dati e Vai al form"
	if quiz_finished:
		_copy_data_and_exit()
		return

	# Altrimenti, andiamo alla prossima domanda
	current_q += 1
	if current_q < questions.size():
		_show_question()
	else:
		_show_final_screen()

func _show_final_screen():
	quiz_finished = true
	question_label.text = "Congratulazioni, hai completato la tua formazione da Architetto dell'Accessibilità!"
	
	# Nascondiamo le vecchie risposte e il pannello delle info
	answers_container.hide()
	fact_panel.hide()
	
	# Ricicliamo il bottone Next come grande chiamata all'azione finale
	next_button.text = "Copia Dati e Vai al Questionario"
	next_button.show()

func _copy_data_and_exit():
	if has_node("/root/TelemetryManager"):
		var data = TelemetryManager.get_summary_string()
		DisplayServer.clipboard_set(data)
		print("Dati copiati negli appunti: ", data)
	else:
		DisplayServer.clipboard_set("[Dati Telemetria di Prova]")
		
	# Scommenta la riga sotto e inserisci il vero link quando lo avrai pronto!
	# OS.shell_open("https://il_tuo_link_nettskjema_qui")
