extends CharacterBody3D

enum State { GROUNDED, ATTACKING }

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var walk_threshold: float = 0.1

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _src_skeleton: Skeleton3D
var _dst_skeleton: Skeleton3D
var _state: State = State.GROUNDED

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_src_skeleton = $UAL1/Armature/GeneralSkeleton
	_dst_skeleton = $Superhero_Male_FullBody/Armature/GeneralSkeleton
	$UAL1/AnimationPlayer.play("Idle")
	$UAL1/AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$CameraArm.rotate_x(-event.relative.y * mouse_sensitivity)
		var arm_rotation: Vector3 = $CameraArm.rotation
		arm_rotation.x = clamp(arm_rotation.x, -PI / 3.0, PI / 3.0)
		$CameraArm.rotation = arm_rotation
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

func _process_grounded(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	var moving := velocity.length() > walk_threshold
	var ap := $UAL1/AnimationPlayer
	if moving and ap.current_animation != "Walk":
		ap.play("Walk")
	elif not moving and ap.current_animation != "Idle":
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
	$UAL1/AnimationPlayer.play("Sword_Attack")

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
