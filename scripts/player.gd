extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var walk_threshold: float = 0.1

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _src_skeleton: Skeleton3D
var _dst_skeleton: Skeleton3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_src_skeleton = $UAL1/Armature/GeneralSkeleton
	_dst_skeleton = $Superhero_Male_FullBody/Armature/GeneralSkeleton
	$UAL1/AnimationPlayer.play("Idle")

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
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()
	_update_animation_conditions()
	_copy_pose()

func _update_animation_conditions() -> void:
	var moving := velocity.length() > walk_threshold
	var ap := $UAL1/AnimationPlayer
	if moving and ap.current_animation != "Walk":
		ap.play("Walk")
	elif not moving and ap.current_animation != "Idle":
		ap.play("Idle")

func _copy_pose() -> void:
	if not _src_skeleton or not _dst_skeleton:
		return
	var bone_count := _src_skeleton.get_bone_count()
	for i in bone_count:
		_dst_skeleton.set_bone_pose_position(i, _src_skeleton.get_bone_pose_position(i))
		_dst_skeleton.set_bone_pose_rotation(i, _src_skeleton.get_bone_pose_rotation(i))
		_dst_skeleton.set_bone_pose_scale(i, _src_skeleton.get_bone_pose_scale(i))
