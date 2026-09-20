extends SceneTree
# Очередь захвата: capture -> untuned -> tuned -> remove.
func _init() -> void:
	SignalManager.captured.clear()
	var s: Resource = SignalManager.capture_new(55.5, 90.0, -1)
	assert(s != null, "capture_new вернул null")
	assert(str(s.get("id")) == "cap_1", "первый id cap_1")
	assert(SignalManager.first_untuned() != null, "есть ненастроенный")
	assert(SignalManager.mark_tuned("cap_1") == true, "mark_tuned")
	assert(SignalManager.tuned_for_sale().size() == 1, "один на продажу")
	assert(SignalManager.remove_captured("cap_1") == true, "remove")
	assert(SignalManager.captured.is_empty(), "очередь пуста")
	print("signal_manager OK")
	quit()
