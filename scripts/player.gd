extends CharacterBody3D
# Player FPS: walk 4.0, run 6.5. Управление: WASD + мышь, E — взаимодействовать.
const WALK_SPEED: float = 4.0
const RUN_SPEED: float = 6.5
const MOUSE_SENS: float = 0.003
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractionRay
var controls_locked := false
func set_locked(l: bool) -> void:
	controls_locked = l
	velocity.x = 0.0
	velocity.z = 0.0
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		$Head.rotate_x(-event.relative.y * MOUSE_SENS)
		$Head.rotation.x = clampf($Head.rotation.x, -1.2, 1.2)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		var fl: SpotLight3D = $Head/Camera3D/Flashlight as SpotLight3D
		if fl != null:
			fl.visible = not fl.visible
		get_viewport().set_input_as_handled()
func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if not controls_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var speed: float = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	var dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if dir != Vector3.ZERO:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	if not controls_locked and is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = 4.5
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
