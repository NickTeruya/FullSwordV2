extends CharacterBody3D

enum State { GROUNDED, AIRBORNE, ATTACKING }

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var walk_threshold: float = 0.1
@export var sprint_speed: float = 8.0
@export var rotation_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var fall_gravity_multiplier: float = 2.0
@export var jump_peak_gravity_multiplier: float = 0.6
## Threshold to distinguish "near apex" from "falling"
@export var peak_velocity_threshold: float = 1.0
@export var background_color: Color = Color(0.25, 0.45, 0.9, 1.0)

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _current_state: State = State.GROUNDED
var _is_landing: bool = false
var _camera_pivot: Node3D
var _mesh_pivot: Node3D
var _anim: AnimationPlayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera_pivot = $CameraPivot
	_mesh_pivot = $MeshPivot
	_anim = $CharacterAnimPlayer
	_anim.root_node = _anim.get_path_to($MeshPivot/Superhero_Male_FullBody)
	var ual1_lib: AnimationLibrary = load("res://assets/animations/UAL1.glb")
	var ual2_lib: AnimationLibrary = load("res://assets/animations/UAL2.glb")
	_anim.add_animation_library("ual1", ual1_lib)
	_anim.add_animation_library("ual2", ual2_lib)
	print(_anim.get_animation_list())
	_anim.play("ual1/Idle", 0.15)
	_anim.animation_finished.connect(_on_animation_finished)
	var env_node := get_tree().current_scene.get_node("WorldEnvironment")
	if env_node and env_node is WorldEnvironment:
		var env: Environment = env_node.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = background_color

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		$CameraPivot/CameraArm.rotate_x(-event.relative.y * mouse_sensitivity)
		var arm_rotation: Vector3 = $CameraPivot/CameraArm.rotation
		arm_rotation.x = clamp(arm_rotation.x, -PI / 3.0, PI / 3.0)
		$CameraPivot/CameraArm.rotation = arm_rotation
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var gravity_mult: float = 1.0
		if velocity.y < -peak_velocity_threshold:
			gravity_mult = fall_gravity_multiplier
		elif absf(velocity.y) <= peak_velocity_threshold:
			gravity_mult = jump_peak_gravity_multiplier
		velocity.y -= _gravity * gravity_mult * delta
	match _current_state:
		State.GROUNDED:
			_process_grounded(delta)
		State.AIRBORNE:
			_process_airborne(delta)
		State.ATTACKING:
			_process_attacking(delta)
	move_and_slide()
	_update_animation_conditions()

func _apply_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (_camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var sprinting := Input.is_action_pressed("sprint") and direction != Vector3.ZERO
	if direction:
		var current_speed := sprint_speed if sprinting else speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		var target_angle := atan2(direction.x, direction.z)
		_mesh_pivot.rotation.y = lerp_angle(_mesh_pivot.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func _process_grounded(delta: float) -> void:
	_apply_movement(delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_current_state = State.AIRBORNE
	if Input.is_action_just_pressed("attack_light") and _current_state == State.GROUNDED:
		_enter_attack()

func _process_airborne(delta: float) -> void:
	_apply_movement(delta)
	if is_on_floor():
		_current_state = State.GROUNDED
		_is_landing = true
		_anim.play("ual1/Jump_Land", 0.1)

func _process_attacking(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

func _enter_attack() -> void:
	_current_state = State.ATTACKING
	velocity.x = 0
	velocity.z = 0
	_anim.play("ual1/Sword_Attack", 0.15)

func _update_animation_conditions() -> void:
	var ap := _anim
	match _current_state:
		State.GROUNDED:
			if _is_landing:
				return
			var moving := velocity.length() > walk_threshold
			var sprinting := Input.is_action_pressed("sprint") and moving
			if sprinting and ap.current_animation != "ual1/Sprint":
				ap.play("ual1/Sprint", 0.15)
			elif not sprinting and moving and ap.current_animation != "ual1/Walk":
				ap.play("ual1/Walk", 0.15)
			elif not sprinting and not moving and ap.current_animation != "ual1/Idle":
				ap.play("ual1/Idle", 0.15)
		State.AIRBORNE:
			if velocity.y > 0.0 and ap.current_animation != "ual1/Jump_Start":
				ap.play("ual1/Jump_Start", 0.15)
			elif velocity.y <= 0.0 and ap.current_animation != "ual1/Jump":
				ap.play("ual1/Jump", 0.15)

func _on_animation_finished(anim_name: StringName) -> void:
	if _current_state == State.ATTACKING:
		_current_state = State.GROUNDED
	elif anim_name == "ual1/Jump_Land":
		_is_landing = false
