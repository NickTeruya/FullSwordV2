extends ProgressBar

func _ready() -> void:
	show_percentage = false

func _on_health_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
