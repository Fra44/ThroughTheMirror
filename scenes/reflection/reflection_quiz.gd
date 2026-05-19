extends Control

# --- RIFERIMENTI AI NODI ---
@onready var question_label: Label = $PanelContainer/MarginContainer/VBoxContainer/QuestionLabel
@onready var answers_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/AnswersContainer
@onready var fact_panel: Control = %FactPanel
@onready var fact_label: Label = %FactPanel/MarginContainer/Label
@onready var next_button: Button = %NextButton


# --- DATI DEL QUIZ ---
var questions = [
	
	# --- LEVEL 1: CATARACT & CONTRAST ---
	{
		"q": "In the cataract level, what accessibility problem did the low-contrast text create?",
		"options": [
			"It made the text harder to perceive against the background",
			"It made the text too large for the screen",
			"It prevented screen readers from reading the page"
		],
		"correct": 0,
		"fact": "Correct! Cataracts can reduce contrast sensitivity and create a foggy or blurred visual effect. Low-contrast text can therefore become very difficult to read."
	},
	{
		"q": "What is the minimum contrast ratio required for normal text under WCAG 1.4.3?",
		"options": [
			"3:1",
			"4.5:1",
			"7:1"
		],
		"correct": 1,
		"fact": "Correct! Normal text requires a 4.5:1 ratio, while large or bold text can use a 3:1 ratio. This ensures text is readable through a cloudy lens."
	},
	
	# --- LEVEL 2: CVD & USE OF COLOR ---
	{
		"q": "How common can Color Vision Deficiency (CVD) be among men?",
		"options": [
			"1 in 50 (2%)",
			"1 in 12 (8%)",
			"1 in 500 (0.2%)"
		],
		"correct": 1,
		"fact": "Correct! CVD affects approximately 1 in 12 men and 1 in 200 women of Northern European ancestry. This makes color-only communication a real accessibility risk."
	},
	{
		"q": "Why is using ONLY a red border to indicate a form error a bad practice?",
		"options": [
			"Red is always forbidden in accessible interfaces",
			"Borders make forms load more slowly",
			"Users with CVD might not distinguish it from a normal border"
		],
		"correct": 2,
		"fact": "Correct! WCAG 1.4.1 states that color alone cannot be used to convey information. You should always provide redundant visual cues, like an icon or text label."
	},
	
	# --- LEVEL 3: BLINDNESS & ALT TEXT ---
	{
		"q": "In the blindness level, what did the alt attribute provide?",
		"options": [
			"A visual filter for the image",
			"A text alternative that assistive technologies can communicate",
			"A faster way to download the image"
		],
		"correct": 1,
		"fact": "Correct! Alt text allows screen readers to communicate the meaning of meaningful images. Without it, important visual content may be inaccessible to blind users."
	},
	{
		"q": "Which WCAG criterion was represented by the blindness level?",
		"options": [
			"WCAG 1.4.3 Contrast (Minimum)",
			"WCAG 1.1.1 Non-text Content",
			"WCAG 1.4.10 Reflow"
		],
		"correct": 1,
		"fact": "Correct! WCAG 1.1.1 requires meaningful non-text content, such as images and icons, to provide equivalent text alternatives."
	},
	
	# --- LEVEL 4: LOW VISION & REFLOW ---
	{
		"q": "In the low vision level, what was wrong with the fixed-width scroll?",
		"options": [
			"It forced users to scroll horizontally when content was enlarged",
			"It made the text invisible to screen readers",
			"It used color as the only cue"
		],
		"correct": 0,
		"fact": "Correct! Fixed-width layouts can break when users zoom or enlarge text. This can force horizontal scrolling, making reading slow and uncomfortable."
	},
	{
		"q": "Which CSS idea best supported reflow in the low vision level?",
		"options": [
			"Use a very large fixed width",
			"Prevent all line breaks with white-space: nowrap",
			"Use a flexible width and allow text wrapping"
		],
		"correct": 2,
		"fact": "Correct! Reflow is supported by flexible layouts and wrapping text. WCAG 1.4.10 aims to keep content readable and usable when zoomed up to 400%."
	}
]


var current_q: int = 0
var quiz_finished: bool = false
var quiz_started: bool = false
var final_data: String = ""

# INSERISCI QUI IL VERO LINK DEL TUO FORM NETTSKJEMA.
var form_url: String = "https://nettskjema.no/a/629384"

var wcag_url: String = "https://www.w3.org/WAI/standards-guidelines/wcag/"
var who_url: String = "https://www.who.int/news-room/fact-sheets/detail/blindness-and-visual-impairment"


func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)

	var buttons = answers_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is Button:
			buttons[i].pressed.connect(_on_answer_pressed.bind(i))

	_show_intro_screen()
	_play_fade_in()


func _play_fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)


func _show_intro_screen() -> void:
	quiz_started = false
	quiz_finished = false
	current_q = 0

	answers_container.hide()
	fact_panel.show()

	question_label.text = "Reflection Quiz"

	fact_label.text = (
		"You are about to start a short questionnaire about the game and the accessibility concepts you explored.\n\n"
		+ "The questions will ask you to connect situations from the game to real accessibility issues, visual impairments, and WCAG guidelines.\n\n"
		+ "After each answer, you will receive a short explanation."
	)

	next_button.text = "Start Quiz"
	next_button.show()


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
	if not quiz_started:
		quiz_started = true
		current_q = 0
		_show_question()
		return

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

	question_label.text = "Congratulations, you have completed your journey of Resonance!"

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
	var safe_wcag_url := JSON.stringify(wcag_url)
	var safe_who_url := JSON.stringify(who_url)

	var js_code := """
	(function() {
		const data = %s;
		const formUrl = %s;
		const wcagUrl = %s;
		const whoUrl = %s;

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
		textarea.style.height = "150px";
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

		const resourcesBox = document.createElement("div");
		resourcesBox.style.marginTop = "22px";
		resourcesBox.style.paddingTop = "16px";
		resourcesBox.style.borderTop = "1px solid rgba(255,255,255,0.35)";

		const resourcesTitle = document.createElement("h3");
		resourcesTitle.textContent = "Further resources";
		resourcesTitle.style.margin = "0 0 8px 0";

		const resourcesText = document.createElement("p");
		resourcesText.textContent = "You can learn more about accessibility guidelines and visual impairments through these resources.";
		resourcesText.style.margin = "0 0 12px 0";

		const wcagButton = document.createElement("button");
		wcagButton.textContent = "WCAG Guidelines";
		wcagButton.style.marginRight = "12px";
		wcagButton.style.padding = "10px 16px";
		wcagButton.style.cursor = "pointer";

		wcagButton.onclick = function() {
			window.open(wcagUrl, "_blank");
		};

		const whoButton = document.createElement("button");
		whoButton.textContent = "WHO: Visual Impairment";
		whoButton.style.padding = "10px 16px";
		whoButton.style.cursor = "pointer";

		whoButton.onclick = function() {
			window.open(whoUrl, "_blank");
		};

		resourcesBox.appendChild(resourcesTitle);
		resourcesBox.appendChild(resourcesText);
		resourcesBox.appendChild(wcagButton);
		resourcesBox.appendChild(whoButton);

		box.appendChild(title);
		box.appendChild(instructions);
		box.appendChild(textarea);
		box.appendChild(copyButton);
		box.appendChild(openButton);
		box.appendChild(closeButton);
		box.appendChild(status);
		box.appendChild(resourcesBox);

		overlay.appendChild(box);
		document.body.appendChild(overlay);

		textarea.focus();
		textarea.select();
	})();
	""" % [safe_data, safe_url, safe_wcag_url, safe_who_url]

	JavaScriptBridge.eval(js_code)
