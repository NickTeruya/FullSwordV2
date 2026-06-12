extends Node3D

@export var enemy_scene: PackedScene
@export var archetype: EnemyArchetype
## Marker3D children of this node mark spawn positions.

func _ready() -> void:
	call_deferred("_spawn_all")

func _spawn_all() -> void:
	var spawn_count: int = 0
	for child in get_children():
		if child is Marker3D:
			_spawn_one(child.global_position)
			spawn_count += 1
	print("Spawner: spawned ", spawn_count, " enemies. Live count: ",
		get_tree().get_nodes_in_group("enemies").size())

func _spawn_one(spawn_pos: Vector3) -> void:
	var enemy := enemy_scene.instantiate()
	enemy.archetype = archetype          # BEFORE add_child — _ready reads it
	# global_position requires the node to be in the tree (needs a parent frame
	# to resolve against). Add first, then place. archetype must precede add_child.
	get_parent().add_child(enemy)
	enemy.add_to_group("enemies")
	enemy.global_position = spawn_pos
