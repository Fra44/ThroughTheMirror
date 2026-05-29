extends TextureButton

# Questo script gestisce la singola riga nella lista a sinistra
var associated_data: Resource

func setup(data: Resource):
	associated_data = data
	var icon = $Icon
	
	# Controlliamo il tipo di dato per assegnare il testo corretto alla label
	if data is ImpairmentData:
		$Label.text = data.name
		if data.icon:
			icon.texture = data.icon
			icon.show()
		else:
			icon.hide()
			
	elif data is WCAGData:
		$Label.text = data.id + " - " + data.title 
		icon.hide()
	
	# Forza la label a ignorare il mouse così il click passa al bottone
	$Label.mouse_filter = Control.MOUSE_FILTER_IGNORE
