extends CharacterBody3D

@export_group("Physics")
@export var gravity: float = 20.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
