extends CharacterBody3D

signal stamina_changed(current: float, maximum: float)

enum State { GROUNDED, AIRBORNE, ATTACKING }

@export_group("Movement")
@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var walk_threshold: float = 0.1
@export var rotation_speed: float = 10.0
@export var mouse_sensitivity: float = 0.003

@export_group("Jump & Gravity")
@export var jump_velocity: float = 4.5
@export var fall_gravity_multiplier: float = 2.0
@export var jump_peak_gravity_multiplier: float = 0.6
## Threshold to distinguish "near apex" from "falling"
@export var peak_velocity_threshold: float = 1.0

@export_group("Locomotion Blending")
@export var locomotion_xfade: float = 0.15     # Idle/Walk/Sprint cross-blends
@export var jump_entry_xfade: float = 0.15      # ground state -> Jump_Start
@export var jump_chain_xfade: float = 0.15      # Jump_Start->Jump, Jump->Jump_Land
@export var landing_cancel_xfade: float = 0.15  # Jump_Land -> Walk/Sprint/Jump_Start
@export var landing_settle_xfade: float = 0.15  # Jump_Land -> Idle (AUTO)
@export var landing_protect_window: float = 0.12  # secs Jump_Land plays before move-cancel

@export_group("Combat")
@export var attack_entry_xfade: float = 0.1    # ground state -> Attack_A
@export var attack_chain_xfade: float = 0.1    # Attack_A->Rec->Attack_B->Rec->Attack_C
@export var attack_settle_xfade: float = 0.15  # Rec/Attack_C -> Idle (AUTO)
@export var chain_window_open: float = 0.25    # secs into a _Rec clip before a queued attack chains
@export var root_motion_scale: float = 1.0     # multiplier on extracted attack root motion

@export_group("Environment")
@export var background_color: Color = Color(0.25, 0.45, 0.9, 1.0)

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 25.0      # stamina per second when regenerating
@export var stamina_regen_delay: float = 0.5      # secs after last drain before regen starts

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _current_state: State = State.GROUNDED
var _landing_started_ms: int = -1    # Time.get_ticks_msec() at landing; -1 = not landing
var _attack_queued: bool = false
var _current_stamina: float = max_stamina
var _last_drain_ms: int = -1    # Time.get_ticks_msec() at last stamina drain; -1 = never drained
var _camera_pivot: Node3D
var _mesh_pivot: Node3D
var _anim: AnimationPlayer
var _anim_tree: AnimationTree
var _state_machine: AnimationNodeStateMachinePlayback

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
	# Build the locomotion state machine in code (libraries must already be
	# added so the clip names resolve). Runtime tree state is set here, never
	# in the .tscn — Godot strips AnimationTree sub-resource state on Ctrl+S.
	_anim_tree = $AnimTree
	_anim_tree.anim_player = _anim_tree.get_path_to(_anim)
	_anim_tree.root_motion_track = NodePath("%GeneralSkeleton:Root")
	var sm := AnimationNodeStateMachine.new()
	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = "ual1/Idle"
	sm.add_node("Idle", idle_node)
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = "ual1/Walk"
	sm.add_node("Walk", walk_node)
	var t_iw := AnimationNodeStateMachineTransition.new()
	t_iw.xfade_time = locomotion_xfade
	t_iw.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Idle", "Walk", t_iw)
	var t_wi := AnimationNodeStateMachineTransition.new()
	t_wi.xfade_time = locomotion_xfade
	t_wi.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Walk", "Idle", t_wi)
	var sprint_node := AnimationNodeAnimation.new()
	sprint_node.animation = "ual1/Sprint"
	sm.add_node("Sprint", sprint_node)
	var jump_start_node := AnimationNodeAnimation.new()
	jump_start_node.animation = "ual1/Jump_Start"
	sm.add_node("Jump_Start", jump_start_node)
	var jump_node := AnimationNodeAnimation.new()
	jump_node.animation = "ual1/Jump"
	sm.add_node("Jump", jump_node)
	var jump_land_node := AnimationNodeAnimation.new()
	jump_land_node.animation = "ual1/Jump_Land"
	sm.add_node("Jump_Land", jump_land_node)
	# Locomotion cross-transitions (code-driven via travel()).
	var t_is := AnimationNodeStateMachineTransition.new()
	t_is.xfade_time = locomotion_xfade
	t_is.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Idle", "Sprint", t_is)
	var t_si := AnimationNodeStateMachineTransition.new()
	t_si.xfade_time = locomotion_xfade
	t_si.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Sprint", "Idle", t_si)
	var t_ws := AnimationNodeStateMachineTransition.new()
	t_ws.xfade_time = locomotion_xfade
	t_ws.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Walk", "Sprint", t_ws)
	var t_sw := AnimationNodeStateMachineTransition.new()
	t_sw.xfade_time = locomotion_xfade
	t_sw.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Sprint", "Walk", t_sw)
	# Jump entry from any ground state (code-driven).
	var t_ijs := AnimationNodeStateMachineTransition.new()
	t_ijs.xfade_time = jump_entry_xfade
	t_ijs.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Idle", "Jump_Start", t_ijs)
	var t_wjs := AnimationNodeStateMachineTransition.new()
	t_wjs.xfade_time = jump_entry_xfade
	t_wjs.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Walk", "Jump_Start", t_wjs)
	var t_sjs := AnimationNodeStateMachineTransition.new()
	t_sjs.xfade_time = jump_entry_xfade
	t_sjs.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Sprint", "Jump_Start", t_sjs)
	# Jump chain (code-driven; Jump_Start is committed through to Jump).
	var t_jsj := AnimationNodeStateMachineTransition.new()
	t_jsj.xfade_time = jump_chain_xfade
	t_jsj.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	sm.add_transition("Jump_Start", "Jump", t_jsj)
	var t_jjl := AnimationNodeStateMachineTransition.new()
	t_jjl.xfade_time = jump_chain_xfade
	t_jjl.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Jump", "Jump_Land", t_jjl)
	# Landing: AUTO-settles to Idle if uninterrupted. The Walk/Sprint/Jump_Start
	# edges are cancel paths reached by code travel() when input is present.
	var t_jli := AnimationNodeStateMachineTransition.new()
	t_jli.xfade_time = landing_settle_xfade
	t_jli.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	sm.add_transition("Jump_Land", "Idle", t_jli)
	var t_jlw := AnimationNodeStateMachineTransition.new()
	t_jlw.xfade_time = landing_cancel_xfade
	t_jlw.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Jump_Land", "Walk", t_jlw)
	var t_jls := AnimationNodeStateMachineTransition.new()
	t_jls.xfade_time = landing_cancel_xfade
	t_jls.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Jump_Land", "Sprint", t_jls)
	var t_jljs := AnimationNodeStateMachineTransition.new()
	t_jljs.xfade_time = landing_cancel_xfade
	t_jljs.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Jump_Land", "Jump_Start", t_jljs)
	# Attack subgraph (UAL2 Regular sword combo, code-driven via travel()).
	var attack_a_node := AnimationNodeAnimation.new()
	attack_a_node.animation = "ual2/Sword_Regular_A"
	sm.add_node("Attack_A", attack_a_node)
	var attack_a_rec_node := AnimationNodeAnimation.new()
	attack_a_rec_node.animation = "ual2/Sword_Regular_A_Rec"
	sm.add_node("Attack_A_Rec", attack_a_rec_node)
	var attack_b_node := AnimationNodeAnimation.new()
	attack_b_node.animation = "ual2/Sword_Regular_B"
	sm.add_node("Attack_B", attack_b_node)
	var attack_b_rec_node := AnimationNodeAnimation.new()
	attack_b_rec_node.animation = "ual2/Sword_Regular_B_Rec"
	sm.add_node("Attack_B_Rec", attack_b_rec_node)
	var attack_c_node := AnimationNodeAnimation.new()
	attack_c_node.animation = "ual2/Sword_Regular_C"
	sm.add_node("Attack_C", attack_c_node)
	# Attack entry from any ground state (code-driven).
	var t_ia := AnimationNodeStateMachineTransition.new()
	t_ia.xfade_time = attack_entry_xfade
	t_ia.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Idle", "Attack_A", t_ia)
	var t_wa := AnimationNodeStateMachineTransition.new()
	t_wa.xfade_time = attack_entry_xfade
	t_wa.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Walk", "Attack_A", t_wa)
	var t_sa := AnimationNodeStateMachineTransition.new()
	t_sa.xfade_time = attack_entry_xfade
	t_sa.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Sprint", "Attack_A", t_sa)
	# Attack chain (code-driven; A/B commit through to their _Rec clips).
	var t_aar := AnimationNodeStateMachineTransition.new()
	t_aar.xfade_time = attack_chain_xfade
	t_aar.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	t_aar.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("Attack_A", "Attack_A_Rec", t_aar)
	var t_bbr := AnimationNodeStateMachineTransition.new()
	t_bbr.xfade_time = attack_chain_xfade
	t_bbr.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	t_bbr.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("Attack_B", "Attack_B_Rec", t_bbr)
	# Recovery -> next hit (code-driven combo continuation, wired for next task).
	var t_arb := AnimationNodeStateMachineTransition.new()
	t_arb.xfade_time = attack_chain_xfade
	t_arb.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Attack_A_Rec", "Attack_B", t_arb)
	var t_brc := AnimationNodeStateMachineTransition.new()
	t_brc.xfade_time = attack_chain_xfade
	t_brc.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Attack_B_Rec", "Attack_C", t_brc)
	# Recovery/finisher settle back to Idle (code-driven via travel() near clip end).
	var t_ari := AnimationNodeStateMachineTransition.new()
	t_ari.xfade_time = attack_settle_xfade
	t_ari.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Attack_A_Rec", "Idle", t_ari)
	var t_bri := AnimationNodeStateMachineTransition.new()
	t_bri.xfade_time = attack_settle_xfade
	t_bri.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Attack_B_Rec", "Idle", t_bri)
	var t_ci := AnimationNodeStateMachineTransition.new()
	t_ci.xfade_time = attack_settle_xfade
	t_ci.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("Attack_C", "Idle", t_ci)
	_anim_tree.tree_root = sm
	_anim_tree.active = true
	_state_machine = _anim_tree.get("parameters/playback")
	_state_machine.start("Idle")
	var env_node := get_tree().current_scene.get_node("WorldEnvironment")
	if env_node and env_node is WorldEnvironment:
		var env: Environment = env_node.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = background_color
	_current_stamina = max_stamina
	var stamina_bar: ProgressBar = get_node_or_null("HUD/StaminaBar")
	if is_instance_valid(stamina_bar):
		stamina_bar.max_value = max_stamina
		stamina_bar.value = _current_stamina
		stamina_changed.connect(stamina_bar._on_stamina_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		$CameraPivot/CameraArm.rotate_x(-event.relative.y * mouse_sensitivity)
		var arm_rotation: Vector3 = $CameraPivot/CameraArm.rotation
		arm_rotation.x = clamp(arm_rotation.x, -PI / 3.0, PI / 3.0)
		$CameraPivot/CameraArm.rotation = arm_rotation
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# TEMPORARY DEBUG: drain stamina to test the pool. Remove when block state drives drain.
	if event is InputEventKey and event.keycode == KEY_P and event.pressed and not event.echo:
		_drain_stamina(30.0)

func _physics_process(delta: float) -> void:
	if _current_state == State.ATTACKING and Input.is_action_just_pressed("attack_light"):
		_attack_queued = true
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
	_update_stamina(delta)
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
	if Input.is_action_just_pressed("attack_light") and _current_state == State.GROUNDED and is_on_floor():
		_enter_attack()

func _process_airborne(delta: float) -> void:
	_apply_movement(delta)
	if is_on_floor():
		_current_state = State.GROUNDED
		_state_machine.travel("Jump_Land")
		_landing_started_ms = Time.get_ticks_msec()

func _process_attacking(delta: float) -> void:
	var rm: Vector3 = _anim_tree.get_root_motion_position()
	var rm_world: Vector3 = _mesh_pivot.global_transform.basis * rm * root_motion_scale
	velocity.x = rm_world.x / delta
	velocity.z = rm_world.z / delta
	var node := _state_machine.get_current_node()
	if node == "Attack_A_Rec" and _attack_queued and _state_machine.get_current_play_position() >= chain_window_open:
		_attack_queued = false
		_state_machine.travel("Attack_B")
	elif node == "Attack_B_Rec" and _attack_queued and _state_machine.get_current_play_position() >= chain_window_open:
		_attack_queued = false
		_state_machine.travel("Attack_C")
	elif (node == "Attack_A_Rec" or node == "Attack_B_Rec" or node == "Attack_C") and \
			_state_machine.get_current_play_position() >= _state_machine.get_current_length() - attack_settle_xfade:
		_attack_queued = false
		_state_machine.travel("Idle")
	elif node == "Idle" or node == "Walk" or node == "Sprint":
		_attack_queued = false
		_current_state = State.GROUNDED

func _enter_attack() -> void:
	_current_state = State.ATTACKING
	velocity.x = 0
	velocity.z = 0
	_attack_queued = false
	_state_machine.travel("Attack_A")

func _update_animation_conditions() -> void:
	match _current_state:
		State.GROUNDED:
			# Animation-only landing protect: for a short window after touchdown,
			# suppress the Walk/Sprint travel so Jump_Land reads before the
			# move-cancel. Movement itself (_apply_movement) is NOT gated — the
			# character keeps full speed; only the anim cancel is delayed.
			var in_landing_protect := _landing_started_ms >= 0 and \
				(Time.get_ticks_msec() - _landing_started_ms) < int(landing_protect_window * 1000.0)
			if _landing_started_ms >= 0 and not in_landing_protect:
				_landing_started_ms = -1  # window expired: one-shot, re-arm on next landing
			var moving := Vector2(velocity.x, velocity.z).length() > walk_threshold
			var sprinting := Input.is_action_pressed("sprint") and moving
			if sprinting:
				if not in_landing_protect and _state_machine.get_current_node() != "Sprint":
					_state_machine.travel("Sprint")
			elif moving:
				if not in_landing_protect and _state_machine.get_current_node() != "Walk":
					_state_machine.travel("Walk")
			else:
				# No movement input. Travel to Idle only from locomotion states;
				# on a landing (Jump/Jump_Land) leave it alone so the AUTO
				# Jump_Land->Idle transition plays the landing through in full.
				var node := _state_machine.get_current_node()
				if node == "Walk" or node == "Sprint":
					_state_machine.travel("Idle")
		State.AIRBORNE:
			# Enter Jump_Start once on the way up; it AUTO-advances to the Jump
			# fall loop on its own. No code travel to "Jump" — that fired at
			# apex and overrode the auto-advance (the old snap). Exclude "Jump"
			# from the guard too: if Jump_Start auto-advances before apex (short
			# clip), we must not yank back to Jump_Start while still rising.
			var node := _state_machine.get_current_node()
			if velocity.y > 0.0 and node != "Jump_Start" and node != "Jump":
				_state_machine.travel("Jump_Start")

func _update_stamina(delta: float) -> void:
	if _current_stamina < max_stamina:
		var regen_ready := _last_drain_ms < 0 or \
			(Time.get_ticks_msec() - _last_drain_ms) >= int(stamina_regen_delay * 1000.0)
		if regen_ready:
			_current_stamina = minf(max_stamina, _current_stamina + stamina_regen_rate * delta)
			stamina_changed.emit(_current_stamina, max_stamina)

func _drain_stamina(amount: float) -> bool:
	if _current_stamina <= 0.0:
		return false
	_current_stamina = maxf(0.0, _current_stamina - amount)
	_last_drain_ms = Time.get_ticks_msec()
	stamina_changed.emit(_current_stamina, max_stamina)
	return true
