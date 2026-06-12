extends CharacterBody3D

signal health_changed(current: float, maximum: float)

const FLOATING_DMG := preload("res://scenes/floating_damage_number.tscn")

enum State { IDLE, CHASE, ATTACK, STAGGER, DEAD }
enum AttackPhase { WINDUP, ACTIVE, RECOVERY }

@export_group("Archetype")
@export var archetype: EnemyArchetype = null

@export_group("Detection")
# Runaway guard only -- fires if the player is moved outside the arena by
# something pathological. NOT a gameplay disengage distance.
@export var leash_backstop: float = 30.0

@export_group("Attack Phases")
@export var windup_time: float = 0.3
@export var active_time: float = 0.2
@export var recovery_time: float = 0.5

@export_group("Hitbox Debug")
@export var debug_draw_hitboxes: bool = true

var _current_state: State = State.IDLE
var _current_health: float
var _max_health: float = 100.0
var _stagger_timer: float = 0.0
var _stagger_duration: float = 1.2
var _stagger_damage_mult: float = 2.0
var _move_speed: float = 3.5
var _attack_damage: float = 12.0
var _attack_interval: float = 2.0
var _attack_cooldown: float = 0.0
var _attack_phase: AttackPhase = AttackPhase.WINDUP
var _attack_phase_timer: float = 0.0
var _repath_interval: float = 0.3
var _repath_timer: float = 0.0
var _rotation_speed: float = 10.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _nav_agent: NavigationAgent3D
var _hit_area: Area3D
var _hit_debug: MeshInstance3D
# Lazy player reference -- NOT cached at _ready(). Captured only when the
# player body enters DetectionArea. Caching at _ready() bites multi-enemy
# spawn order: the player node may not yet be ready when a spawned enemy runs.
var _player_ref: Node3D = null

func _ready() -> void:
	if archetype == null:
		push_warning("Enemy: no archetype assigned; using defaults.")
	else:
		_max_health = archetype.max_health
		_stagger_duration = archetype.stagger_duration
		_stagger_damage_mult = archetype.stagger_damage_mult
		_move_speed = archetype.move_speed
		_attack_damage = archetype.attack_damage
		_attack_interval = archetype.attack_interval
	_current_health = _max_health
	_nav_agent = $NavigationAgent3D
	_repath_timer = _repath_interval
	# Set DetectionArea collision config from code -- authoritative over .tscn.
	# collision_layer = 0: deliberate detector-only pattern; the area's layer
	# is irrelevant to what IT detects; leaving it empty prevents anything
	# from accidentally detecting the DetectionArea itself.
	# collision_mask = 2: player CharacterBody3D is on collision_layer 2.
	$DetectionArea.collision_layer = 0
	$DetectionArea.collision_mask = 2
	# Create a fresh SphereShape3D per instance (avoids shared sub_resource
	# mutation when multiple enemies are in the scene).
	var detection_col: CollisionShape3D = $DetectionArea/CollisionShape3D
	var sphere := SphereShape3D.new()
	sphere.radius = _get_aggro_range()
	detection_col.shape = sphere
	$DetectionArea.body_entered.connect(_on_detection_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_body_exited)
	_hit_area = $HitArea3D
	_hit_debug = $HitArea3D/DebugMesh
	_hit_area.monitoring = false
	_hit_area.area_entered.connect(_on_hit_area_entered)
	# TODO (weapon reach): HitArea3D offset (0,1,0.6) and BoxShape3D size
	# (0.8,0.8,1.2) are fixed in enemy.tscn. Once enemies carry WeaponResources,
	# read reach from archetype.equipped_weapon and apply to BoxShape extents +
	# CollisionShape3D z-offset here in _ready().
	# DEBUG -- remove after detection is confirmed working
	print("DetectionArea radius=", sphere.radius, "  mask=", $DetectionArea.collision_mask, "  layer=", $DetectionArea.collision_layer)

func take_damage(amount: float) -> void:
	if _current_state == State.DEAD:
		return
	if _current_state == State.STAGGER:
		amount *= _stagger_damage_mult
	_current_health = max(0.0, _current_health - amount)
	health_changed.emit(_current_health, _max_health)
	var label: FloatingDamageNumber = FLOATING_DMG.instantiate()
	label.position = Vector3(0.0, 2.0, 0.0)
	add_child(label)
	label.show_damage(amount)
	_enter_stagger()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	match _current_state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.STAGGER:
			_process_stagger(delta)
		State.DEAD:
			_process_dead(delta)
	move_and_slide()

func _process_idle(_delta: float) -> void:
	# Level poll: re-acquire player if already overlapping the sphere but
	# _player_ref is null (e.g. stagger recovery while player stood still,
	# or a spawn-order race where body_entered fired before signal connected).
	# body_entered remains the primary edge-transition; this is the safety net.
	if _player_ref == null:
		var bodies: Array = $DetectionArea.get_overlapping_bodies()
		if bodies.size() > 0:
			_player_ref = bodies[0]
	if _player_ref != null:
		_enter_chase()

func _process_chase(delta: float) -> void:
	if _player_ref == null:
		_lose_aggro()
		return

	# Horizontal-only distance -- S6 y-component lesson: player height
	# difference (step, slope) must not cause spurious aggro loss or
	# wrong engage-range math.
	var flat_pos := Vector2(global_position.x, global_position.z)
	var flat_player := Vector2(_player_ref.global_position.x, _player_ref.global_position.z)
	var flat_dist := flat_pos.distance_to(flat_player)

	# Runaway guard: fires only if something pathological displaces the player
	# outside the arena. Not a gameplay disengage mechanic.
	if flat_dist > leash_backstop:
		_lose_aggro()
		return

	if flat_dist > _get_engage_range():
		# -- APPROACH: steer toward player via proven nav agent --
		# Load-order guard: nav map may not be ready on the first physics frame.
		if NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map()) == 0:
			velocity.x = 0.0
			velocity.z = 0.0
			return

		_repath_timer += delta
		if _repath_timer >= _repath_interval:
			_repath_timer = 0.0
			_nav_agent.target_position = _player_ref.global_position

		var next := _nav_agent.get_next_path_position()
		var dir := next - global_position
		# Zero y before normalizing -- do NOT let the nav agent's y offset
		# tilt the velocity or the facing angle (S6 y-component trap).
		dir.y = 0.0
		if dir.length_squared() > 0.0001:
			dir = dir.normalized()
			velocity.x = dir.x * _move_speed
			velocity.z = dir.z * _move_speed
			# Face movement direction while approaching.
			# Mirror player.gd _apply_movement idiom exactly:
			#   atan2(dir.x, dir.z) -> lerp_angle on rotation.y.
			var target_angle := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, _rotation_speed * delta)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		# -- HOLD AT ENGAGE RANGE: stop and face player --
		velocity.x = 0.0
		velocity.z = 0.0
		# Face the PLAYER (not last movement dir) so the enemy is aimed
		# when the swing fires. Horizontal-only: y-offset must not tilt
		# the facing angle (S6 y-trap, range edition).
		var to_player := _player_ref.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.0001:
			var target_angle := atan2(to_player.x, to_player.z)
			rotation.y = lerp_angle(rotation.y, target_angle, _rotation_speed * delta)
		# Attack cadence gate -- accumulates only while holding, not while chasing.
		_attack_cooldown += delta
		if _attack_cooldown >= _attack_interval:
			_enter_attack()

func _process_attack(delta: float) -> void:
	_attack_phase_timer += delta
	match _attack_phase:
		AttackPhase.WINDUP:
			# Hitbox is DEAD during windup (telegraph — player can react/parry).
			# Transition only; activation belongs to ACTIVE.
			if _attack_phase_timer >= windup_time:
				_attack_phase = AttackPhase.ACTIVE
				_attack_phase_timer = 0.0
		AttackPhase.ACTIVE:
			# Activate hitbox on entry: first frame of ACTIVE still has monitoring
			# false (killed at _enter_attack). Direct assignment safe here
			# (_physics_process, not a signal callback).
			if not _hit_area.monitoring:
				_hit_area.monitoring = true
				_hit_debug.visible = debug_draw_hitboxes
				print("Enemy SWING")
			if _attack_phase_timer >= active_time:
				# Deactivate -- hitbox DEAD for recovery phase.
				_hit_area.monitoring = false
				_hit_debug.visible = false
				_attack_phase = AttackPhase.RECOVERY
				_attack_phase_timer = 0.0
		AttackPhase.RECOVERY:
			# Hitbox is DEAD (deactivated at end of ACTIVE above).
			if _attack_phase_timer >= recovery_time:
				# Reset cooldown so the next hold period waits the full interval.
				_attack_cooldown = 0.0
				_current_state = State.CHASE
				_repath_timer = _repath_interval

func _process_stagger(delta: float) -> void:
	_stagger_timer += delta
	if _stagger_timer >= _stagger_duration:
		_current_state = State.IDLE
		_repath_timer = _repath_interval
		print("Enemy stagger ended")

func _process_dead(_delta: float) -> void:
	pass  # TODO: death increment

func _enter_chase() -> void:
	_current_state = State.CHASE
	print("Enemy AGGRO")

func _enter_attack() -> void:
	_current_state = State.ATTACK
	_attack_phase = AttackPhase.WINDUP
	_attack_phase_timer = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	# Explicit off -- WINDUP must never carry a stale-live hitbox.
	_hit_area.monitoring = false
	_hit_debug.visible = false

func _enter_stagger() -> void:
	_current_state = State.STAGGER
	_stagger_timer = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	# Kill hitbox immediately if staggered mid-swing. set_deferred is required
	# because take_damage can be called from area_entered (a physics-signal
	# callback); toggling monitoring directly inside a physics callback causes a
	# re-entrancy error (S9 lesson from dummy.gd).
	_hit_area.set_deferred("monitoring", false)
	_hit_debug.visible = false
	# Reset cooldown so the enemy waits a full interval before attacking again
	# after recovering from stagger -- prevents instant re-attack.
	_attack_cooldown = 0.0
	print("Enemy STAGGERED")

# Mechanical core of aggro drop -- seam where future taste-tier behaviors attach.
# Future callers: player stealth/disengage powerup; per-archetype disengage
# (relentless archetypes never call this; skittish ones call it and reposition).
# Those are feel-tier behaviors deferred to a later increment.
# Contract: state -> IDLE only. _player_ref is owned by detection (body_entered/
# exited), not by this function.
func _lose_aggro() -> void:
	_current_state = State.IDLE
	print("Enemy lost aggro")

# Seam for future per-attack / range-band logic.
# Multiple attacks with differing reach will change what this returns;
# callers (chase hold-gate) never change.
func _get_engage_range() -> float:
	if archetype == null:
		return 2.0
	return archetype.attack_range

func _get_aggro_range() -> float:
	if archetype == null:
		return 12.0
	return archetype.aggro_range

func _can_detect_player() -> bool:
	# Proximity check: _player_ref is non-null only while the player body is
	# inside DetectionArea's sphere (maintained via body_entered/exited signals).
	# LoS raycast slots in here as an additional AND condition in a later increment.
	return _player_ref != null

func _on_detection_body_entered(body: Node3D) -> void:
	# DEBUG -- remove after detection is confirmed working
	print("DETECTED: ", body.name)
	_player_ref = body

func _on_detection_body_exited(body: Node3D) -> void:
	if body == _player_ref:
		_player_ref = null

func _on_hit_area_entered(area: Area3D) -> void:
	var target := area.get_parent()
	# Self-hit guard: skip if the area belongs to this enemy node.
	if target == self:
		return
	if target.has_method("take_damage"):
		target.take_damage(_attack_damage)
