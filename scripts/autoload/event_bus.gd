extends Node
signal phase_changed(phase: String)
signal signal_detected(id: String)
signal signal_processed(id: String, quality: float)
signal signal_sold(id: String, price: int)
signal day_ended(day: int)
signal night_started()
signal anomaly_contact()
