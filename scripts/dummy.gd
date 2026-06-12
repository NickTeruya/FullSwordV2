extends CharacterBody3D

signal health_changed(current: float, maximum: float)

const FLOATING_DMG := preload("res://scenes/floating_damage_number.tscn")

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Physics")
@export var gravity: float = 20.0

@export_group("Attack")
@export var attack_interval: float = 2.0
@export var attack_damage: float = 8.0
@export var attack_active_time: float = 0.15
@export var stagger_damage_mult: float = 2.0
@export var stagger_duration: float = 1.2

@export_group("Hitbox Debug")
@export var debug_draw_hitboxes: bool = true

var _current_health: float
var _attack_hitarea: Area3D
var _attack_hitbox_debug: MeshInstance3D
var _attack_timer: float = 0.0
var _attack_window_elapsed: float = 0.0
var _blade_live: bool = false
var _staggered: bool = false
var _stagger_timer: float = 0.0

func _ready() -> void:
	_current_health = max_health
	_attack_hitarea = $HitArea3D
	_attack_hitbox_debug = $HitArea3D/DebugMesh
	_attack_hitarea.monitoring = false
	_attack_hitarea.area_entered.connect(_on_dummy_hit)

func take_damage(amount: float) -> void:
	if _staggered:
		amount *= stagger_damage_mult
	_current_health = max(0.0, _current_health - amount)
	health_changed.emit(_current_health, max_health)
	var label: FloatingDamageNumber = FLOATING_DMG.instantiate()
	label.position = Vector3(0.0, 2.0, 0.0)
	add_child(label)
	label.show_damage(amount)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _staggered:
		_stagger_timer += delta
		if _stagger_timer >= stagger_duration:
			_staggered = false
			_attack_timer = 0.0
			print("Dummy stagger ended")
	else:
		_attack_timer += delta
		if not _blade_live and _attack_timer >= attack_interval:
			_attack_timer = 0.0
			_blade_live = true
			_attack_window_elapsed = 0.0
			_attack_hitarea.monitoring = true
			_attack_hitbox_debug.visible = debug_draw_hitboxes

		if _blade_live:
			_attack_window_elapsed += delta
			if _attack_window_elapsed >= attack_active_time:
				_blade_live = false
				_attack_hitarea.monitoring = false
				_attack_hitbox_debug.visible = false

	move_and_slide()

func _enter_stagger() -> void:
	_staggered = true
	_stagger_timer = 0.0
	_blade_live = false
	_attack_hitarea.set_deferred("monitoring", false)
	_attack_hitbox_debug.visible = false
	print("Dummy STAGGERED")

func _on_dummy_hit(area: Area3D) -> void:
	if area.get_parent() == self:
		return
	var target := area.get_parent()
	if target.has_method("take_damage"):
		var was_parried: bool = target.take_damage(attack_damage)
		if was_parried:
			_enter_stagger()
