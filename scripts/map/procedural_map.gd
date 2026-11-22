class_name ProceduralMap
extends Node3D

# Procedurally Generated 165m x 165m Battlefield Arena
# - 165m x 165m terrain floor with grass/dirt material and static collider
# - 4 perimeter earthen berms and security barriers
# - Procedural obstacle clusters (wrecked vehicles, shipping containers, barricades, crates)
# - Surrounding dense conifer forest backdrop
# - Dynamic perimeter spawn markers for enemy waves

const MAP_SIZE: float = 165.0
const HALF_SIZE: float = 82.5
const BERM_HEIGHT: float = 6.5
const BERM_THICKNESS: float = 5.0
const CLEAR_RADIUS: float = 13.0 # Central clear radius around player start

var ground_body: StaticBody3D = null
var berms_root: Node3D = null
var obstacles_root: Node3D = null
var forest_root: Node3D = null
var spawn_markers: Array[Marker3D] = []

func _ready() -> void:
	add_to_group("procedural_map")
	generate_map()

func get_spawn_points() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for m in spawn_markers:
		if is_instance_valid(m):
			result.append(m)
	return result

func generate_map() -> void:
	# Clear existing children if regenerating
	for c in get_children():
		c.queue_free()
	spawn_markers.clear()

	build_ground()
	build_perimeter_berms()
	build_procedural_obstacles()
	build_forest_backdrop()
	build_perimeter_spawn_points()

func build_ground() -> void:
	ground_body = StaticBody3D.new()
	ground_body.name = "Floor"
	ground_body.collision_layer = 1
	ground_body.collision_mask = 7
	ground_body.position = Vector3(0.0, -0.5, 0.0)
	add_child(ground_body)

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)

	var mat_ground := StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.24, 0.32, 0.18)
	mat_ground.roughness = 0.95
	mat_ground.metallic_specular = 0.05
	mat_ground.uv1_scale = Vector3(41.25, 41.25, 1.0)
	floor_mesh.material = mat_ground

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = floor_mesh
	ground_body.add_child(mesh_inst)

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	col_shape.shape = box_shape
	ground_body.add_child(col_shape)

func build_perimeter_berms() -> void:
	berms_root = Node3D.new()
	berms_root.name = "PerimeterBerms"
	add_child(berms_root)

	var mat_berm := StandardMaterial3D.new()
	mat_berm.albedo_color = Color(0.18, 0.22, 0.14)
	mat_berm.roughness = 0.95

	var mat_wall_top := StandardMaterial3D.new()
	mat_wall_top.albedo_color = Color(0.32, 0.34, 0.36)
	mat_wall_top.roughness = 0.85

	# 4 perimeter walls: North (Z=-HALF), South (Z=+HALF), West (X=-HALF), East (X=+HALF)
	var berm_configs = [
		{"pos": Vector3(0.0, BERM_HEIGHT * 0.5, -HALF_SIZE), "size": Vector3(MAP_SIZE + BERM_THICKNESS * 2, BERM_HEIGHT, BERM_THICKNESS)},
		{"pos": Vector3(0.0, BERM_HEIGHT * 0.5, HALF_SIZE), "size": Vector3(MAP_SIZE + BERM_THICKNESS * 2, BERM_HEIGHT, BERM_THICKNESS)},
		{"pos": Vector3(-HALF_SIZE, BERM_HEIGHT * 0.5, 0.0), "size": Vector3(BERM_THICKNESS, BERM_HEIGHT, MAP_SIZE + BERM_THICKNESS * 2)},
		{"pos": Vector3(HALF_SIZE, BERM_HEIGHT * 0.5, 0.0), "size": Vector3(BERM_THICKNESS, BERM_HEIGHT, MAP_SIZE + BERM_THICKNESS * 2)}
	]

	for cfg in berm_configs:
		var wall_body := StaticBody3D.new()
		wall_body.collision_layer = 1
		wall_body.collision_mask = 7
		wall_body.position = cfg["pos"]
		berms_root.add_child(wall_body)

		var mesh := BoxMesh.new()
		mesh.size = cfg["size"]
		mesh.material = mat_berm

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		wall_body.add_child(mi)

		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = cfg["size"]
		col.shape = cs
		wall_body.add_child(col)

func build_procedural_obstacles() -> void:
	obstacles_root = Node3D.new()
	obstacles_root.name = "Obstacles"
	add_child(obstacles_root)

	# Build predefined modular clusters scattered across 4 quadrants
	# keeping center (radius CLEAR_RADIUS) completely unobstructed
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261111 # Consistent deterministic battlefield layout

	# Standard materials
	var mat_rust := StandardMaterial3D.new()
	mat_rust.albedo_color = Color(0.35, 0.22, 0.15)
	mat_rust.metallic = 0.7
	mat_rust.roughness = 0.85

	var mat_concrete := StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.42, 0.44, 0.46)
	mat_concrete.roughness = 0.9

	var mat_crate := StandardMaterial3D.new()
	mat_crate.albedo_color = Color(0.48, 0.34, 0.18)
	mat_crate.roughness = 0.85

	var mat_cont := StandardMaterial3D.new()
	mat_cont.albedo_color = Color(0.18, 0.32, 0.45)
	mat_cont.metallic = 0.75
	mat_cont.roughness = 0.4

	# Delegate to MapObstacles static builders
	MapObstacles.obstacle_aabbs.clear()

	# Grid of obstacle clusters across [-62, 62] x [-62, 62]
	var cluster_grid_coords: Array[Vector2] = []
	for gx in range(-3, 4):
		for gz in range(-3, 4):
			if gx == 0 and gz == 0:
				continue # skip dead center
			var cx := gx * 19.5 + rng.randf_range(-3.5, 3.5)
			var cz := gz * 19.5 + rng.randf_range(-3.5, 3.5)
			if Vector2(cx, cz).length() < CLEAR_RADIUS:
				continue
			cluster_grid_coords.append(Vector2(cx, cz))

	for coord in cluster_grid_coords:
		var pos := Vector3(coord.x, 0.0, coord.y)
		var rot_y := rng.randf_range(0.0, 360.0)
		var cluster_type := rng.randi() % 6

		match cluster_type:
			0:
				MapObstacles._build_wrecked_sedan(obstacles_root, pos, rot_y, mat_rust, mat_rust, mat_rust, mat_rust)
			1:
				MapObstacles._build_shipping_container(obstacles_root, pos, rot_y, mat_cont)
			2:
				MapObstacles._build_crate_stack(obstacles_root, pos, rot_y, mat_crate, mat_crate)
			3:
				MapObstacles._build_jersey_barrier_line(obstacles_root, pos, rot_y, 3, mat_concrete, mat_concrete)
			4:
				MapObstacles._build_wrecked_van(obstacles_root, pos, rot_y, mat_rust, mat_rust, mat_rust, mat_rust)
			5:
				MapObstacles._build_barrel_cluster(obstacles_root, pos, mat_rust)

func build_forest_backdrop() -> void:
	forest_root = Node3D.new()
	forest_root.name = "Forest"
	add_child(forest_root)

	var mat_bark := StandardMaterial3D.new()
	mat_bark.albedo_color = Color(0.24, 0.16, 0.10)
	mat_bark.roughness = 0.92

	var needle_colors = [
		Color(0.07, 0.17, 0.09),
		Color(0.10, 0.22, 0.12),
		Color(0.13, 0.26, 0.14),
		Color(0.06, 0.14, 0.08)
	]

	var needle_materials: Array[StandardMaterial3D] = []
	for col in needle_colors:
		var nm := StandardMaterial3D.new()
		nm.albedo_color = col
		nm.roughness = 0.85
		needle_materials.append(nm)

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 7.5
	trunk_mesh.radial_segments = 6

	var tier_bottom := CylinderMesh.new()
	tier_bottom.top_radius = 0.4
	tier_bottom.bottom_radius = 3.2
	tier_bottom.height = 4.2
	tier_bottom.radial_segments = 6

	var tier_mid := CylinderMesh.new()
	tier_mid.top_radius = 0.25
	tier_mid.bottom_radius = 2.4
	tier_mid.height = 3.6
	tier_mid.radial_segments = 6

	var tier_top := CylinderMesh.new()
	tier_top.top_radius = 0.05
	tier_top.bottom_radius = 1.6
	tier_top.height = 3.2
	tier_top.radial_segments = 6

	# Forest trees along 4 outer sides beyond perimeter walls
	var rng := RandomNumberGenerator.new()
	rng.seed = 98765

	var sides = [
		{"axis": "x", "fixed_z": -HALF_SIZE - 6.0, "dir": -1.0},
		{"axis": "x", "fixed_z": HALF_SIZE + 6.0, "dir": 1.0},
		{"axis": "z", "fixed_x": -HALF_SIZE - 6.0, "dir": -1.0},
		{"axis": "z", "fixed_x": HALF_SIZE + 6.0, "dir": 1.0}
	]

	for side in sides:
		for step in range(int(-HALF_SIZE - 12.0), int(HALF_SIZE + 12.0), 7):
			for depth_layer in range(1, 4):
				var offset_depth: float = float(depth_layer) * 6.5 + rng.randf_range(-1.5, 1.5)
				var pos := Vector3.ZERO
				if side.has("fixed_z"):
					pos.x = float(step) + rng.randf_range(-2.0, 2.0)
					pos.z = side["fixed_z"] + side["dir"] * offset_depth
				else:
					pos.z = float(step) + rng.randf_range(-2.0, 2.0)
					pos.x = side["fixed_x"] + side["dir"] * offset_depth

				var f_mat = needle_materials[rng.randi() % needle_materials.size()]
				spawn_pine_tree(pos, trunk_mesh, tier_bottom, tier_mid, tier_top, mat_bark, f_mat)

func spawn_pine_tree(pos: Vector3, t_mesh: Mesh, b_mesh: Mesh, m_mesh: Mesh, top_mesh: Mesh, t_mat: Material, f_mat: Material) -> void:
	var tree_root := Node3D.new()
	tree_root.position = pos
	var scale_var := randf_range(0.85, 1.25)
	tree_root.scale = Vector3(scale_var, scale_var, scale_var)
	tree_root.rotation.y = randf_range(0, TAU)
	forest_root.add_child(tree_root)

	var trunk := MeshInstance3D.new()
	trunk.mesh = t_mesh
	trunk.material_override = t_mat
	trunk.position = Vector3(0.0, 3.75, 0.0)
	tree_root.add_child(trunk)

	var b_tier := MeshInstance3D.new()
	b_tier.mesh = b_mesh
	b_tier.material_override = f_mat
	b_tier.position = Vector3(0.0, 3.8, 0.0)
	tree_root.add_child(b_tier)

	var m_tier := MeshInstance3D.new()
	m_tier.mesh = m_mesh
	m_tier.material_override = f_mat
	m_tier.position = Vector3(0.0, 6.2, 0.0)
	tree_root.add_child(m_tier)

	var t_tier := MeshInstance3D.new()
	t_tier.mesh = top_mesh
	t_tier.material_override = f_mat
	t_tier.position = Vector3(0.0, 8.4, 0.0)
	tree_root.add_child(t_tier)

func build_perimeter_spawn_points() -> void:
	var spawns_root := Node3D.new()
	spawns_root.name = "PerimeterSpawnPoints"
	add_child(spawns_root)

	# 20 spawn points distributed around the inner perimeter (~73m from center)
	var spawn_dist: float = HALF_SIZE - 9.5 # 73.0m
	var count_per_side: int = 5

	for i in range(count_per_side):
		var frac := float(i) / float(count_per_side - 1)
		var offset := lerpf(-spawn_dist + 12.0, spawn_dist - 12.0, frac)

		# North side
		create_spawn_marker(spawns_root, Vector3(offset, 0.1, -spawn_dist))
		# South side
		create_spawn_marker(spawns_root, Vector3(offset, 0.1, spawn_dist))
		# West side
		create_spawn_marker(spawns_root, Vector3(-spawn_dist, 0.1, offset))
		# East side
		create_spawn_marker(spawns_root, Vector3(spawn_dist, 0.1, offset))

func create_spawn_marker(parent: Node3D, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = "ProcSpawn_%d" % (spawn_markers.size() + 1)
	marker.position = pos
	parent.add_child(marker)
	spawn_markers.append(marker)
