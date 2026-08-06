extends Node

# Dati di sessione
var session_id: String = ""
var manual_opens: int = 0
var total_manual_time: float = 0.0
var _current_manual_start: float = 0.0

# Statistiche per ogni livello
var stats = {
	"L1": {"fails": 0, "start_time": 0.0, "total_time": 0.0},
	"L2": {"fails": 0, "start_time": 0.0, "total_time": 0.0},
	"L3": {"fails": 0, "start_time": 0.0, "total_time": 0.0},
	"L4": {"fails": 0, "start_time": 0.0, "total_time": 0.0}
}

# Risposte al Quiz Finale (conterrà 1 per corretto, 0 per sbagliato)
var quiz_results = []

func _ready():
	# Generiamo un ID anonimo univoco all'avvio (es. id_4821)
	randomize()
	session_id = "p_" + str(randi() % 9000 + 1000)

func track_manual_open():
	manual_opens += 1
	_current_manual_start = Time.get_unix_time_from_system()

func track_manual_close():
	if _current_manual_start > 0.0:
		var time_spent = Time.get_unix_time_from_system() - _current_manual_start
		total_manual_time += time_spent
		_current_manual_start = 0.0 # Resettiamo per la prossima volta
		print("number of codex opening:" + str(manual_opens))
		print("total time of codex opened:" + str(total_manual_time))

func start_level(id: String):
	if stats.has(id):
		stats[id]["start_time"] = Time.get_unix_time_from_system()
	else:
		push_error("Telemetria: ID Livello non trovato -> " + id)

func end_level(id: String):
	if stats.has(id) and stats[id]["start_time"] > 0.0:
		var end_t = Time.get_unix_time_from_system()
		# Sommiamo il tempo (utile se il giocatore esce e rientra dal minigioco)
		stats[id]["total_time"] += (end_t - stats[id]["start_time"])
		# Resettiamo lo start_time per evitare doppi conteggi se la funzione viene chiamata due volte
		stats[id]["start_time"] = 0.0 

func track_fail(id: String):
	if stats.has(id):
		stats[id]["fails"] += 1

# Genera la stringa finale compatta per il copia-incolla
func get_summary_string() -> String:
	# Chiudiamo il cronometro del manuale prima di generare la stringa
	if _current_manual_start > 0.0:
		var time_spent = Time.get_unix_time_from_system() - _current_manual_start
		total_manual_time += time_spent
		_current_manual_start = 0.0
		
	var s = "[ID: %s] | " % session_id
	
	# 1. Stampiamo le statistiche per OGNI livello (L1, L2, L3, L4)
	for id in stats:
		s += "[%s -> T:%.0fs, F:%d] " % [id, stats[id]["total_time"], stats[id]["fails"]]
	
	# 2. Creiamo la stringa pulita del quiz PRIMA di usarla
	var quiz_str = ""
	for i in range(quiz_results.size()):
		quiz_str += str(quiz_results[i])
		if i < quiz_results.size() - 1:
			quiz_str += ","
			
	# 3. Infine, aggiungiamo i dati del manuale (aperture e tempo) e i risultati del quiz
	s += "| [Codex: %d (%.0fs)] | [Quiz: %s]" % [manual_opens, total_manual_time, quiz_str]
	
	return s
