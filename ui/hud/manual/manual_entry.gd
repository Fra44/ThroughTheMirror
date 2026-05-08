extends TextureButton

# Questo script gestisce la singola riga nella lista a sinistra
var associated_data: Resource

func setup(data: Resource):
	associated_data = data
	$Label.text = data.name
	
	# FORZA la Label a ignorare completamente il mouse. 
	# Questo garantisce che il click "trapassi" il testo e colpisca il bottone sotto.
	$Label.mouse_filter = Control.MOUSE_FILTER_IGNORE
