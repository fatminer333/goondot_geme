extends SceneTree
# Дефолты и клампы CapturedSignal (замена старого радар-теста).
func _init() -> void:
	SignalManager.captured.clear()
	var s: Resource = SignalManager.capture_new(500.0, 999.0, -5)
	assert(float(s.get("freq_mhz")) == 100.0, "частота кламп 100")
	assert(float(s.get("polarity_deg")) == 360.0, "полярность кламп 360")
	assert(int(s.get("polarity_sign")) == -1, "знак -1")
	assert(int(s.get("state")) == 0, "state 0 = захвачен")
	assert(int(s.get("reward")) == 50, "награда 50")
	SignalManager.captured.clear()
	print("capture clamp OK")
	quit()
