extends CharacterBody3D

enum State { GROUNDED, ATTACKING }

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var walk_threshold: float = 0.1
@export var sprint_speed: float = 8.0
@export var rotation_speed: float = 10.0
@export var jump_velocity: float = 4.5

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _src_skeleton: Skeleton3D
var _dst_skeleton: Skeleton3D
var _state: State = State.GROUNDED
var _camera_pivot: Node3D
var _mesh_pivot: Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_src_skeleton = $MeshPivot/UAL1/Armature/GeneralSkeleton
	_dst_skeleton = $MeshPivot/Superhero_Male_FullBody/Armature/GeneralSkeleton
	_camera_pivot = $CameraPivot
	_mesh_pivot = $MeshPivot
	$MeshPivot/UAL1/AnimationPlayer.play("Idle")
	$MeshPivot/UAL1/AnimationPlayer.animation_finished.connect(_on_animation_finished)

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
		velocity.y -= _gravity * delta
	match _state:
		State.GROUNDED:
			_process_grounded(delta)
		State.ATTACKING:
			_process_attacking(delta)
	move_and_slide()
	_copy_pose()

func _process_grounded(delta: float) -> void:
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
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var moving := velocity.length() > walk_threshold
	var ap := $MeshPivot/UAL1/AnimationPlayer
	if sprinting and ap.current_animation != "Sprint":
		ap.play("Sprint")
	elif not sprinting and moving and ap.current_animation != "Walk":
		ap.play("Walk")
	elif not sprinting and not moving and ap.current_animation != "Idle":
		ap.play("Idle")
	if Input.is_action_just_pressed("attack_light"):
		_enter_attack()

func _process_attacking(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

func _enter_attack() -> void:
	_state = State.ATTACKING
	velocity.x = 0
	velocity.z = 0
	$MeshPivot/UAL1/AnimationPlayer.play("Sword_Attack")

func _on_animation_finished(_anim_name: StringName) -> void:
	if _state == State.ATTACKING:
		_state = State.GROUNDED

func _copy_pose() -> void:
	if not _src_skeleton or not _dst_skeleton:
		return
	var bone_count := _src_skeleton.get_bone_count()
	for i in bone_count:
		_dst_skeleton.set_bone_pose_position(i, _src_skeleton.get_bone_pose_position(i))
		_dst_skeleton.set_bone_pose_rotation(i, _src_skeleton.get_bone_pose_rotation(i))
		_dst_skeleton.set_bone_pose_scale(i, _src_skeleton.get_bone_pose_scale(i))
