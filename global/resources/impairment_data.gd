extends Resource
class_name ImpairmentData

@export var name: String # Es: "Cataratta"
@export var icon: Texture2D # Icona per il manuale
@export_multiline var short_info: String # Per la debug window
@export_multiline var manual_text: String # Per il manuale
@export var related_wcag: WCAGData # Collega l'impairment alla sua regola WCAG
