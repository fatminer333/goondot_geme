extends CharacterBody3D
# Task 5: Аномалия — Observe (силуэт 60-90с) -> Stalk (круги 20-30м) -> Hunt (7 м/с, 15с).
# Дом + дверь = спасён (контакт вне Hunt или днём не похищает, см. HorrorDirector.on_contact).
enum State { OBSERVE, STALK, HUNT }
var state: int = State.OBSERVE
var state_time: float = 0.0
var observe_len: float = 75.0
var hunt_len: float = 15.0
var stalk_radius: float = 25.0
var hunt_speed: float = 7.0
var stalk_speed: float = 2.5
var contact_cooldown: float = 0.0
var angle: float = 0.0

func _ready() -> void:
	observe_len = randf_range(60.0, 90.0)
	stalk_radius = randf_range(20.0, 30.0)
	add_to_group("anomaly")

func _physics_process(delta: float) -> void:
	state_time += delta
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		# Fallback: искать Player по имени сцены.
		player = get_tree().current_scene.get_node_or_null("Player") as Node3D
	match state:
		State.OBSERVE:
			velocity = Vector3.ZERO
			move_and_slide()
			if state_time >= observe_len:
				_set_state(State.STALK)
		State.STALK:
			if player != null:
				angle += delta * 0.35
				var target: Vector3 = player.global_position + Vector3(cos(angle) * stalk_radius, 0.0, sin(angle) * stalk_radius)
				var dir: Vector3 = target - global_position
				dir.y = 0.0
				if dir.length() > 1.0:
					velocity = dir.normalized() * stalk_speed
				else:
					velocity = Vector3.ZERO
				move_and_slide()
				_try_contact(player)
			if state_time >= 30.0:
				_set_state(State.HUNT)
		State.HUNT:
			if player != null:
				var dir: Vector3 = player.global_position - global_position
				dir.y = 0.0
				if dir.length() > 0.1:
					velocity = dir.normalized() * hunt_speed
				else:
					velocity = Vector3.ZERO
				move_and_slide()
				_try_contact(player)
			if state_time >= hunt_len:
				_set_state(State.OBSERVE)

func _set_state(s: int) -> void:
	state = s
	state_time = 0.0
	if s == State.OBSERVE:
		observe_len = randf_range(60.0, 90.0)
	elif s == State.STALK:
		stalk_radius = randf_range(20.0, 30.0)

func _try_contact(player: Node3D) -> void:
	if contact_cooldown > 0.0:
		return
	if global_position.distance_to(player.global_position) < 1.6:
		contact_cooldown = 5.0
		var hd: Node = get_node_or_null("/root/HorrorDirector")
		if hd != null:
			hd.call("on_contact")
