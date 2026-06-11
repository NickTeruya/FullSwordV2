extends CharacterBody3D

signal health_changed(current: float, maximum: float)

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Physics")
@export var gravity: float = 20.0

@export_group("Attack")
@export var attack_interval: float = 2.0
@export var attack_damage: float = 8.0
@export var attack_active_time: float = 0.15

@export_group("Hitbox Debug")
@export var debug_draw_hitboxes: bool = true

var _current_health: float
var _attack_hitarea: Area3D
var _attack_hitbox_debug: MeshInstance3D
var _attack_timer: float = 0.0
var _attack_window_elapsed: float = 0.0
var _blade_live: bool = false

func _ready() -> void:
	_current_health = max_health
	_attack_hitarea = $HitArea3D
	_attack_hitbox_debug = $HitArea3D/DebugMesh
	_attack_hitarea.monitoring = false
	_attack_hitarea.area_entered.connect(_on_dummy_hit)

func take_damage(amount: float) -> void:
	_current_health = max(0.0, _current_health - amount)
	health_changed.emit(_current_health, max_health)
	print("Dummy took %.1f damage, health now %.1f" % [amount, _current_health])

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

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

func _on_dummy_hit(area: Area3D) -> void:
	if area.get_parent() == self:
		return
	var target := area.get_parent()
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
