extends CanvasLayer

@onready var anchor = $Anchor
@onready var title_label = $Anchor/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var status_label = $Anchor/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var error_label = $Anchor/PanelContainer/MarginContainer/VBoxContainer/ErrorLabel
@onready var violation_label = $Anchor/PanelContainer/MarginContainer/VBoxContainer/ViolationLabel

func _ready():
	hide() # Nascondi all'avvio
	anchor.modulate.a = 0 # Assicuriamoci che sia trasparente all'inizio

# Funzione principale per "iniettare" i dati
func setup_display(data: ImpairmentData):
	if not data: return
	
	title_label.text = "MIRROR OF RESONANCE ACTIVATED"
	status_label.text = "STATUS: VISUAL IMPAIRMENT DETECTED - " + data.name.to_upper()
	error_label.text = "ERROR: " + data.short_info
	
	if data.related_wcag:
		violation_label.text = "VIOLATION: WCAG " + data.related_wcag.id + " - " + data.related_wcag.title
	else:
		violation_label.text = "VIOLATION: NO DATA"
		
	show()
	_animate_entrance()

func _animate_entrance():
	var tween = create_tween()
	
	# Reset iniziale per l'animazione
	self.offset.y = 50 
	anchor.modulate.a = 0 
	
	# Animazione parallela: muoviamo il layer e sfumiamo l'anchor
	tween.parallel().tween_property(self, "offset:y", 0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(anchor, "modulate:a", 1.0, 0.3)

# Funzione aggiuntiva per chiudere la finestra in modo fluido
func hide_display():
	var tween = create_tween()
	tween.parallel().tween_property(anchor, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "offset:y", -20, 0.2)
	tween.finished.connect(hide)
