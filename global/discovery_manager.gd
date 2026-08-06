extends Node

# Liste che salvano gli oggetti unici scoperti
var discovered_impairments: Array[ImpairmentData] = []
var discovered_wcag: Array[WCAGData] = []

var gate_solved: bool = false
var gate_symbol_red: String = ""
var gate_symbol_green: String = ""

# Segnale emesso ogni volta che trovi qualcosa di nuovo
signal new_discovery(item)

func discover_impairment(data: ImpairmentData):
	if data and not discovered_impairments.has(data):
		discovered_impairments.append(data)
		print("New Impairment discovered: ", data.name)
		
		# Se l'impairment ha una WCAG collegata, scopriamo anche quella
		if data.related_wcag:
			discover_wcag(data.related_wcag)
		
		new_discovery.emit(data)

func discover_wcag(data: WCAGData):
	if data and not discovered_wcag.has(data):
		discovered_wcag.append(data)
		print("New WCAG guideline discovered: ", data.id)
		new_discovery.emit(data)
