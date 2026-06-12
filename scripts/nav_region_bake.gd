extends NavigationRegion3D

func _ready() -> void:
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_collision_mask = 1  # Floor StaticBody3D is on default layer 1
	navigation_mesh.cell_size = 0.25             # matches navigation map default; mismatched values risk edge rasterization errors
	navigation_mesh.agent_radius = 0.4
	bake_navigation_mesh(false)
