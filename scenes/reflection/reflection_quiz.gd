extends Control

# --- RIFERIMENTI AI NODI ---
@onready var question_label: Label = $PanelContainer/MarginContainer/VBoxContainer/QuestionLabel
@onready var answers_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/AnswersContainer
@onready var fact_panel: Control = %FactPanel
@onready var fact_label: Label = %FactPanel/MarginContainer/Label
@onready var next_button: Button = %NextButton


# --- DATI DEL QUIZ ---
var questions = [
	{
		"q": "Why is the Alt Text attribute important for images?",
		"options": [
			"To improve colors",
			"For users relying on Screen Readers",
			"To load the image faster"
		],
		"correct": 1,
		"fact": "Correct! Alt Text helps screen reader users understand the meaning of images. Without it, an image can become invisible to blind users."
	},
	{
		"q": "What is the 'Reflow' (WCAG 1.4.10) that you applied to the scroll?",
		"options": [
			"A way to change fonts",
			"The adaptation of text when zooming",
			"A transparency effect"
		],
		"correct": 1,
		"fact": "Correct! Reflow allows content to adapt when users zoom in, reducing the need for horizontal scrolling."
	}
	# Aggiungi qui le altre domande.
]

var current_q: int = 0
var quiz_finished: bool = false
var final_data: String = ""

# INSERISCI QUI IL VERO LINK DEL TUO FORM NETTSKJEMA.
var form_url: String = "https://nettskjema.no/a/629384"


func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)

	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is Button:
			buttons[i].pressed.connect(_on_answer_pressed.bind(i))

	_show_question()
	_play_fade_in()


func _play_fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)


func _show_question() -> void:
	fact_panel.hide()
	next_button.hide()
	answers_container.show()

	var q_data = questions[current_q]
	question_label.text = q_data["q"]

	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]

		if btn is Button:
			btn.remove_theme_color_override("font_disabled_color")
			btn.remove_theme_color_override("font_color")

			if i < q_data["options"].size():
				btn.text = q_data["options"][i]
				btn.show()
				btn.disabled = false
			else:
				btn.hide()


func _on_answer_pressed(index: int) -> void:
	var correct_index: int = questions[current_q]["correct"]
	var correct: bool = index == correct_index

	_update_answer_buttons(index, correct_index)
	_save_quiz_result(correct)
	_show_feedback(correct)

	next_button.text = "Next Question"
	next_button.show()


func _update_answer_buttons(selected_index: int, correct_index: int) -> void:
	var buttons = answers_container.get_children()

	for i in range(buttons.size()):
		var btn = buttons[i]

		if btn is Button:
			btn.disabled = true

			if i < questions[current_q]["options"].size():
				if i == correct_index:
					btn.add_theme_color_override("font_disabled_color", Color("4ade80"))
				elif i == selected_index:
					btn.add_theme_color_override("font_disabled_color", Color("f87171"))
				else:
					btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 0.5))


func _save_quiz_result(correct: bool) -> void:
	if has_node("/root/TelemetryManager"):
		TelemetryManager.quiz_results.append(1 if correct else 0)


func _show_feedback(correct: bool) -> void:
	var fact_text: String = questions[current_q]["fact"]

	if correct:
		fact_label.text = fact_text
	else:
		var cleaned_fact := fact_text.replace("Correct! ", "").replace("Correct!", "")
		fact_label.text = "Wrong, but don't worry!\n" + cleaned_fact

	fact_panel.show()


func _on_next_pressed() -> void:
	if quiz_finished:
		_open_results_popup()
		return

	current_q += 1

	if current_q < questions.size():
		_show_question()
	else:
		_show_final_screen()


func _show_final_screen() -> void:
	quiz_finished = true
	final_data = _get_telemetry_data()

	question_label.text = "Congratulations, you have completed your training as an Accessibility Architect!"

	answers_container.hide()
	fact_panel.show()

	fact_label.text = (
		"Your gameplay summary is ready.\n\n"
		+ "Click the button below to copy your results and open the final questionnaire."
	)

	next_button.text = "Copy Data and Go to Questionnaire"
	next_button.show()


func _get_telemetry_data() -> String:
	if has_node("/root/TelemetryManager"):
		return TelemetryManager.get_summary_string()

	return "[Test Telemetry Data]"


func _open_results_popup() -> void:
	if final_data == "":
		final_data = _get_telemetry_data()

	print("Telemetry data:")
	print(final_data)

	if OS.has_feature("web"):
		_show_web_copy_popup(final_data, form_url)
	else:
		DisplayServer.clipboard_set(final_data)
		OS.shell_open(form_url)

	fact_label.text = (
		"Your results are ready.\n\n"
		+ "Use the copy window to copy them, then paste them into the questionnaire."
	)

	next_button.text = "Open Copy Window Again"


func _show_web_copy_popup(data: String, target_url: String) -> void:
	var safe_data := JSON.stringify(data)
	var safe_url := JSON.stringify(target_url)

	var js_code := """
	(function() {
		const data = %s;
		const formUrl = %s;

		const oldOverlay = document.getElementById("godot-copy-overlay");
		if (oldOverlay) {
			oldOverlay.remove();
		}

		const overlay = document.createElement("div");
		overlay.id = "godot-copy-overlay";
		overlay.style.position = "fixed";
		overlay.style.left = "0";
		overlay.style.top = "0";
		overlay.style.width = "100%%";
		overlay.style.height = "100%%";
		overlay.style.background = "rgba(0, 0, 0, 0.75)";
		overlay.style.zIndex = "999999";
		overlay.style.display = "flex";
		overlay.style.alignItems = "center";
		overlay.style.justifyContent = "center";
		overlay.style.fontFamily = "Arial, sans-serif";

		const box = document.createElement("div");
		box.style.width = "80%%";
		box.style.maxWidth = "760px";
		box.style.background = "#1f2d4a";
		box.style.color = "white";
		box.style.border = "2px solid #8fa7ff";
		box.style.borderRadius = "12px";
		box.style.padding = "24px";
		box.style.boxShadow = "0 8px 30px rgba(0,0,0,0.5)";

		const title = document.createElement("h2");
		title.textContent = "Copy your game results";
		title.style.marginTop = "0";

		const instructions = document.createElement("p");
		instructions.textContent = "Click Copy Results, then open the questionnaire and paste the text into the first question.";

		const textarea = document.createElement("textarea");
		textarea.value = data;
		textarea.readOnly = true;
		textarea.style.width = "100%%";
		textarea.style.height = "160px";
		textarea.style.marginTop = "12px";
		textarea.style.marginBottom = "16px";
		textarea.style.fontSize = "14px";
		textarea.style.padding = "12px";
		textarea.style.boxSizing = "border-box";

		const status = document.createElement("p");
		status.textContent = "";
		status.style.minHeight = "20px";

		const copyButton = document.createElement("button");
		copyButton.textContent = "Copy Results";
		copyButton.style.marginRight = "12px";
		copyButton.style.padding = "10px 16px";
		copyButton.style.cursor = "pointer";

		copyButton.onclick = async function() {
			textarea.focus();
			textarea.select();

			try {
				await navigator.clipboard.writeText(textarea.value);
				status.textContent = "Copied! Now open the questionnaire and paste the results.";
			} catch (err) {
				try {
					const ok = document.execCommand("copy");
					status.textContent = ok
						? "Copied! Now open the questionnaire and paste the results."
						: "Clipboard blocked. Please press CTRL+C manually.";
				} catch (err2) {
					status.textContent = "Clipboard blocked. Please press CTRL+C manually.";
				}
			}
		};

		const openButton = document.createElement("button");
		openButton.textContent = "Open Questionnaire";
		openButton.style.marginRight = "12px";
		openButton.style.padding = "10px 16px";
		openButton.style.cursor = "pointer";

		openButton.onclick = function() {
			window.open(formUrl, "_blank");
		};

		const closeButton = document.createElement("button");
		closeButton.textContent = "Close";
		closeButton.style.padding = "10px 16px";
		closeButton.style.cursor = "pointer";

		closeButton.onclick = function() {
			overlay.remove();
		};

		box.appendChild(title);
		box.appendChild(instructions);
		box.appendChild(textarea);
		box.appendChild(copyButton);
		box.appendChild(openButton);
		box.appendChild(closeButton);
		box.appendChild(status);
		overlay.appendChild(box);
		document.body.appendChild(overlay);

		textarea.focus();
		textarea.select();
	})();
	""" % [safe_data, safe_url]

	JavaScriptBridge.eval(js_code)
