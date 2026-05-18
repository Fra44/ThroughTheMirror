extends Control

# --- RIFERIMENTI AI NODI ---
# Uso i percorsi esatti basati sul tuo screenshot
@onready var question_label = $PanelContainer/MarginContainer/VBoxContainer/QuestionLabel
@onready var answers_container = $PanelContainer/MarginContainer/VBoxContainer/AnswersContainer
@onready var fact_panel = %FactPanel
@onready var fact_label = %FactPanel/MarginContainer/Label
@onready var next_button = %NextButton

# --- DATI DEL QUIZ ---
var questions = [
	{
		"q": "Why is the Alt Text attribute important for images?",
		"options": ["To improve colors", "For users relying on Screen Readers", "To load the image faster"],
		"correct": 1,
		"fact": "Correct! In 2024, 54% of websites still have images without Alt Text, making the web 'invisible' to millions of blind people."
	},
	{
		"q": "What is the 'Reflow' (WCAG 1.4.10) that you applied to the scroll?",
		"options": ["A way to change fonts", "The adaptation of text when zooming", "A transparency effect"],
		"correct": 1,
		"fact": "Correct! Reflow allows zooming up to 400% without horizontal scrolling. Without it, reading a page is like looking through a peephole."
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
	
	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		
		# ---> NUOVO: Resettiamo i colori delle risposte precedenti
		btn.remove_theme_color_override("font_disabled_color")
		btn.remove_theme_color_override("font_color")
		
		if i < q_data["options"].size():
			btn.text = q_data["options"][i]
			btn.show()
			btn.disabled = false 
		else:
			btn.hide()

func _on_answer_pressed(index: int):
	var correct_index = questions[current_q]["correct"]
	var correct = (index == correct_index)
	
	# ---> NUOVO: Logica dei colori sui bottoni
	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.disabled = true # Blocchiamo i click
		
		if i < questions[current_q]["options"].size():
			if i == correct_index:
				# La risposta corretta diventa VERDE
				btn.add_theme_color_override("font_disabled_color", Color("4ade80"))
			elif i == index:
				# Se hai cliccato una risposta sbagliata, diventa ROSSA
				btn.add_theme_color_override("font_disabled_color", Color("f87171"))
			else:
				# Le altre risposte non cliccate diventano grigie/mezze trasparenti
				btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 0.5))
	
	# Registriamo il risultato per la telemetria
	if has_node("/root/TelemetryManager"):
		TelemetryManager.quiz_results.append(1 if correct else 0)
	
	# Mostriamo il feedback correggendo il problema del testo "Sbagliato... Esatto!"
	var fact_text = questions[current_q]["fact"]
	if correct:
		fact_label.text = fact_text
	else:
		# Rimuoviamo "Correct! " dalla stringa originale per non creare contraddizioni
		var cleaned_fact = fact_text.replace("Correct! ", "").replace("Correct!", "")
		fact_label.text = "Wrong, but don't worry!\n" + cleaned_fact
		
	fact_panel.show()
	next_button.text = "Next Question"
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
	question_label.text = "Congratulations, you have completed your training as an Accessibility Architect!"
	
	# Nascondiamo le vecchie risposte e il pannello delle info
	answers_container.hide()
	fact_panel.hide()
	
	# Ricicliamo il bottone Next come grande chiamata all'azione finale
	next_button.text = "Copy Data and Go to Questionnaire"
	next_button.show()

func _copy_data_and_exit():
	if has_node("/root/TelemetryManager"):
		var data = TelemetryManager.get_summary_string()
		DisplayServer.clipboard_set(data)
		print("Data copied to clipboard: ", data)
	else:
		DisplayServer.clipboard_set("[Test Telemetry Data]")
		
	# Scommenta la riga sotto e inserisci il vero link quando lo avrai pronto!
	# OS.shell_open("https://il_tuo_link_nettskjema_qui")
