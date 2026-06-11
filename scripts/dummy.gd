extends CharacterBody3D

signal health_changed(current: float, maximum: float)

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Physics")
@export var gravity: float = 20.0

var _current_health: float

func _ready() -> void:
	_current_health = max_health

func take_damage(amount: float) -> void:
	_current_health = max(0.0, _current_health - amount)
	health_changed.emit(_current_health, max_health)
	print("Dummy took %.1f damage, health now %.1f" % [amount, _current_health])

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
