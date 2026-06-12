extends Label3D
class_name FloatingDamageNumber

@export var rise_height: float = 1.0
@export var lifetime: float = 0.8

func show_damage(amount: float) -> void:
	text = str(int(round(amount)))

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	# no object pooling -- fine for current low hit density;
	# pool if many-simultaneous-hits density arrives (enemy waves).
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector3(0.0, rise_height, 0.0), lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	await tween.finished
	queue_free()
