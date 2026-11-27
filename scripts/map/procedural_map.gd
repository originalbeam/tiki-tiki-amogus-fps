class_name ProceduralMap
extends Node3D

# Procedurally Generated 165m x 165m Multi-Biome Battlefield Arena
# Supports 5 distinct playable biomes + live mid-match paid map transfer ([M] at Minivan Shop):
# - "forest"  : Лесной полигон (classic conifer woods, wrecked vehicles & containers)
# - "factory" : Заброшенный Промзавод (concrete yard, pass-through hangars, cisterns, extra barrels)
# - "arctic"  : Зимний Арктический Полигон (snowfield, frosted pines, Quonset shelters, ice blocks)
# - "city"    : Разрушенный Городской Квартал (asphalt roads, 2-story ruins with sightlines, wrecked buses)
# - "desert"  : Пустынная Военная База (sand, HESCO walls, mesas, watchtowers, sandbag bunkers)

const EnvironmentControllerScript = preload("res://scripts/map/environment_controller.gd")
const ArenaInteractablesScript = preload("res://scripts/map/arena_interactables.gd")

const MAP_SIZE: float = 165.0
const HALF_SIZE: float = 82.5
const BERM_HEIGHT: float = 6.5
const BERM_THICKNESS: float = 5.0
const CLEAR_RADIUS: float = 17.5 # Central clear radius around player start, MinivanShop & Workbench

var current_map_id: String = "forest"
var geometry_root: Node3D = null
var ground_body: StaticBody3D = null
var berms_root: Node3D = null
var obstacles_root: Node3D = null
var backdrop_root: Node3D = null
var spawn_markers: Array[Marker3D] = []

var env_controller: Node3D = null
var interactables_mgr: Node3D = null

func _ready() -> void:
	add_to_group("procedural_map")
	if GlobalSettings:
		current_map_id = GlobalSettings.selected_map_id

	env_controller = EnvironmentControllerScript.new()
	env_controller.name = "EnvironmentController"
	add_child(env_controller)

	interactables_mgr = ArenaInteractablesScript.new()
	interactables_mgr.name = "ArenaInteractablesManager"
	add_child(interactables_mgr)

	generate_map(current_map_id)

func get_spawn_points() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for m in spawn_markers:
		if is_instance_valid(m):
			result.append(m)
	return result

func switch_map(new_map_id: String) -> void:
	if not GlobalSettings or not GlobalSettings.MAPS.has(new_map_id):
		return
	GlobalSettings.set_selected_map(new_map_id)
	current_map_id = new_map_id

	# Dismount player if currently sitting on a DShK before rebuilding arena!
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.has_method("dismount_turret"):
			p.dismount_turret()

	# Clear permanent boss wrecks from previous biome when traveling to a new map
	for grp in ["tiger_wreck", "mi24_wreck"]:
		for wr in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(wr):
				wr.queue_free()

	generate_map(current_map_id)

	# Sync EnvironmentController biome palette & weather particles
	if env_controller and env_controller.has_method("set_biome"):
		env_controller.set_biome(current_map_id, true)

	# Rebuild AStar3D navigation grid for the new obstacle layout
	for nav in get_tree().get_nodes_in_group("nav_manager"):
		if is_instance_valid(nav) and nav.has_method("build_navigation_grid"):
			nav.build_navigation_grid()

	# Refresh EnemySpawner spawn points & warmup beacons cleanly
	var spawner = get_parent().get_node_or_null("EnemySpawner") if get_parent() else null
	if spawner:
		spawner.spawn_points = get_spawn_points()
		if spawner.has_method("on_map_switched"):
			spawner.on_map_switched()

func generate_map(map_id: String = "") -> void:
	if map_id != "":
		current_map_id = map_id
	if geometry_root and is_instance_valid(geometry_root):
		remove_child(geometry_root)
		geometry_root.queue_free()
	spawn_markers.clear()

	geometry_root = Node3D.new()
	geometry_root.name = "MapGeometry_" + current_map_id
	add_child(geometry_root)

	build_ground()
	build_perimeter_berms()
	build_procedural_obstacles()
	build_biome_backdrop()
	build_perimeter_spawn_points()

	if interactables_mgr and interactables_mgr.has_method("populate_for_biome"):
		interactables_mgr.populate_for_biome(current_map_id)

func build_ground() -> void:
	ground_body = StaticBody3D.new()
	ground_body.name = "Floor"
	ground_body.collision_layer = 1
	ground_body.collision_mask = 7
	ground_body.position = Vector3(0.0, -0.5, 0.0)
	geometry_root.add_child(ground_body)

	var floor_col := Color(0.24, 0.32, 0.18)
	var rough := 0.95
	match current_map_id:
		"factory":
			floor_col = Color(0.32, 0.33, 0.35)
			rough = 0.88
		"arctic":
			floor_col = Color(0.84, 0.88, 0.94)
			rough = 0.78
		"city":
			floor_col = Color(0.21, 0.22, 0.24)
			rough = 0.90
		"desert":
			floor_col = Color(0.76, 0.64, 0.42)
			rough = 0.96

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	var mat_ground := StandardMaterial3D.new()
	mat_ground.albedo_color = floor_col
	mat_ground.roughness = rough
	mat_ground.metallic_specular = 0.08 if current_map_id == "arctic" else 0.05
	floor_mesh.material = mat_ground

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = floor_mesh
	ground_body.add_child(mesh_inst)

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	col_shape.shape = box_shape
	ground_body.add_child(col_shape)

	# Biome-specific ground markings (city crossroads / factory yellow hazard lanes)
	if current_map_id == "city" or current_map_id == "factory":
		var m_stripe := StandardMaterial3D.new()
		m_stripe.albedo_color = Color(0.86, 0.74, 0.22) if current_map_id == "factory" else Color(0.78, 0.78, 0.76)
		m_stripe.roughness = 0.85
		for lane_i in range(-6, 7):
			var off: float = float(lane_i) * 11.0
			_add_decor_box(geometry_root, Vector3(0.45, 0.03, 4.5), Vector3(0.0, 0.015, off), m_stripe)
			_add_decor_box(geometry_root, Vector3(4.5, 0.03, 0.45), Vector3(off, 0.015, 0.0), m_stripe)

func build_perimeter_berms() -> void:
	berms_root = Node3D.new()
	berms_root.name = "PerimeterBerms"
	geometry_root.add_child(berms_root)

	var berm_col := Color(0.18, 0.22, 0.14)
	match current_map_id:
		"factory": berm_col = Color(0.28, 0.29, 0.31)
		"arctic":  berm_col = Color(0.74, 0.80, 0.88)
		"city":    berm_col = Color(0.32, 0.33, 0.35)
		"desert":  berm_col = Color(0.64, 0.52, 0.34)

	var mat_berm := StandardMaterial3D.new()
	mat_berm.albedo_color = berm_col
	mat_berm.roughness = 0.94

	var berm_configs := [
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
	geometry_root.add_child(obstacles_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261111 ^ current_map_id.hash()

	var mat_rust := _mk_mat(Color(0.35, 0.22, 0.15), 0.70, 0.82)
	var mat_concrete := _mk_mat(Color(0.42, 0.44, 0.46), 0.05, 0.90)
	var mat_crate := _mk_mat(Color(0.48, 0.34, 0.18), 0.05, 0.85)
	var mat_cont := _mk_mat(Color(0.18, 0.32, 0.45), 0.72, 0.42)
	var mat_steel := _mk_mat(Color(0.28, 0.30, 0.33), 0.78, 0.45)
	var mat_snow := _mk_mat(Color(0.82, 0.89, 0.96), 0.10, 0.45)
	var mat_ice := _mk_mat(Color(0.56, 0.80, 0.94), 0.20, 0.18)
	var mat_sandbag := _mk_mat(Color(0.68, 0.58, 0.38), 0.04, 0.94)
	var mat_brick := _mk_mat(Color(0.44, 0.34, 0.30), 0.05, 0.92)
	var mat_bus := _mk_mat(Color(0.62, 0.50, 0.16), 0.55, 0.48)

	MapObstacles.obstacle_aabbs.clear()

	var cluster_grid_coords: Array[Vector2] = []
	for gx in range(-3, 4):
		for gz in range(-3, 4):
			if gx == 0 and gz == 0:
				continue
			var cx: float = float(gx) * 19.5 + rng.randf_range(-3.2, 3.2)
			var cz: float = float(gz) * 19.5 + rng.randf_range(-3.2, 3.2)
			if Vector2(cx, cz).length() < CLEAR_RADIUS:
				continue
			# Also keep MinivanShop parking area (-14, 4) unobstructed!
			if Vector2(cx + 14.0, cz - 4.0).length() < 9.5:
				continue
			cluster_grid_coords.append(Vector2(cx, cz))

	for coord in cluster_grid_coords:
		var pos := Vector3(coord.x, 0.0, coord.y)
		var rot_y: float = rng.randf_range(0.0, 360.0)
		var roll: int = rng.randi() % 6

		match current_map_id:
			"factory":
				match roll:
					0: _build_factory_hangar(pos, rot_y, mat_steel, mat_concrete)
					1: _build_industrial_cistern(pos, rot_y, mat_rust, mat_steel)
					2: MapObstacles._build_shipping_container(obstacles_root, pos, rot_y, mat_cont)
					3: MapObstacles._build_jersey_barrier_line(obstacles_root, pos, rot_y, 3, mat_concrete, mat_concrete)
					4: MapObstacles._build_crate_stack(obstacles_root, pos, rot_y, mat_crate, mat_steel)
					5: MapObstacles._build_barrel_cluster(obstacles_root, pos, mat_rust)
			"arctic":
				match roll:
					0: _build_arctic_shelter(pos, rot_y, mat_snow, mat_steel)
					1: _build_ice_formation(pos, rot_y, mat_ice, mat_snow)
					2: MapObstacles._build_shipping_container(obstacles_root, pos, rot_y, mat_cont)
					3: MapObstacles._build_jersey_barrier_line(obstacles_root, pos, rot_y, 3, mat_snow, mat_concrete)
					4: MapObstacles._build_crate_stack(obstacles_root, pos, rot_y, mat_snow, mat_crate)
					5: MapObstacles._build_wrecked_van(obstacles_root, pos, rot_y, mat_snow, mat_steel, mat_snow, mat_steel)
			"city":
				match roll:
					0, 1: _build_city_ruin_corner(pos, rot_y, mat_concrete, mat_brick)
					2: _build_wrecked_city_bus(pos, rot_y, mat_bus, mat_steel)
					3: MapObstacles._build_jersey_barrier_line(obstacles_root, pos, rot_y, 4, mat_concrete, mat_concrete)
					4: MapObstacles._build_wrecked_sedan(obstacles_root, pos, rot_y, mat_rust, mat_steel, mat_rust, mat_steel)
					5: _build_sandbag_bunker(pos, rot_y, mat_sandbag, mat_concrete)
			"desert":
				match roll:
					0, 1: _build_sandbag_bunker(pos, rot_y, mat_sandbag, mat_crate)
					2: _build_desert_canopy_post(pos, rot_y, mat_sandbag, mat_rust)
					3: MapObstacles._build_shipping_container(obstacles_root, pos, rot_y, mat_sandbag)
					4: MapObstacles._build_crate_stack(obstacles_root, pos, rot_y, mat_crate, mat_sandbag)
					5: MapObstacles._build_wrecked_van(obstacles_root, pos, rot_y, mat_sandbag, mat_rust, mat_sandbag, mat_rust)
			_: # "forest"
				match roll:
					0: MapObstacles._build_wrecked_sedan(obstacles_root, pos, rot_y, mat_rust, mat_rust, mat_rust, mat_rust)
					1: MapObstacles._build_shipping_container(obstacles_root, pos, rot_y, mat_cont)
					2: MapObstacles._build_crate_stack(obstacles_root, pos, rot_y, mat_crate, mat_crate)
					3: MapObstacles._build_jersey_barrier_line(obstacles_root, pos, rot_y, 3, mat_concrete, mat_concrete)
					4: MapObstacles._build_wrecked_van(obstacles_root, pos, rot_y, mat_rust, mat_rust, mat_rust, mat_rust)
					5: MapObstacles._build_barrel_cluster(obstacles_root, pos, mat_rust)

# --- BIOME-SPECIFIC ARCHITECTURAL OBSTACLES (WITH COLLIDERS & NAV AABBs) ---
func _add_static_box_part(parent: Node3D, sz: Vector3, local_pos: Vector3, mat: Material, register_aabb_world: bool = false, world_origin: Vector3 = Vector3.ZERO) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 7
	b.position = local_pos
	parent.add_child(b)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.material_override = mat
	b.add_child(mi)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new(); cs.size = sz
	col.shape = cs
	b.add_child(col)
	if register_aabb_world:
		var wp: Vector3 = world_origin + local_pos
		MapObstacles.obstacle_aabbs.append(AABB(wp - sz * 0.5, sz))

func _build_factory_hangar(pos: Vector3, rot_y: float, m_steel: Material, m_conc: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	# Open-through industrial bay with two heavy side walls and high steel roof!
	_add_static_box_part(n, Vector3(0.55, 4.4, 8.2), Vector3(-3.2, 2.2, 0.0), m_conc)
	_add_static_box_part(n, Vector3(0.55, 4.4, 8.2), Vector3(3.2, 2.2, 0.0), m_conc)
	_add_static_box_part(n, Vector3(7.2, 0.45, 8.6), Vector3(0.0, 4.6, 0.0), m_steel)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(4.2, 0.0, 4.2), Vector3(8.4, 4.8, 8.4)))

func _build_industrial_cistern(pos: Vector3, rot_y: float, m_rust: Material, m_steel: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	var sb := StaticBody3D.new(); sb.collision_layer = 1; sb.collision_mask = 7; n.add_child(sb)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 1.65; cm.bottom_radius = 1.65; cm.height = 6.2; cm.radial_segments = 16
	mi.mesh = cm; mi.material_override = m_rust; mi.position = Vector3(0, 1.9, 0); mi.rotation_degrees = Vector3(0, 0, 90)
	sb.add_child(mi)
	var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(6.2, 3.4, 3.3)
	col.shape = bs; col.position = Vector3(0, 1.7, 0); sb.add_child(col)
	_add_static_box_part(n, Vector3(0.5, 1.4, 2.6), Vector3(-2.1, 0.7, 0), m_steel)
	_add_static_box_part(n, Vector3(0.5, 1.4, 2.6), Vector3(2.1, 0.7, 0), m_steel)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(3.3, 0.0, 3.3), Vector3(6.6, 3.6, 6.6)))

func _build_arctic_shelter(pos: Vector3, rot_y: float, m_snow: Material, m_steel: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	_add_static_box_part(n, Vector3(4.8, 3.0, 6.2), Vector3(0, 1.5, 0), m_steel)
	_add_decor_box(n, Vector3(5.0, 0.45, 6.4), Vector3(0, 3.15, 0), m_snow)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(3.6, 0.0, 3.6), Vector3(7.2, 3.5, 7.2)))

func _build_ice_formation(pos: Vector3, rot_y: float, m_ice: Material, m_snow: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	_add_static_box_part(n, Vector3(3.4, 2.4, 2.2), Vector3(0, 1.2, 0), m_ice)
	_add_static_box_part(n, Vector3(2.1, 1.5, 1.8), Vector3(1.8, 0.75, 0.8), m_snow)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(2.8, 0.0, 2.4), Vector3(5.8, 2.6, 4.8)))

func _build_city_ruin_corner(pos: Vector3, rot_y: float, m_conc: Material, m_brick: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	# L-shaped bombed 2-story building corner with upper window/sniper slit openings!
	_add_static_box_part(n, Vector3(6.8, 1.35, 0.55), Vector3(0.0, 0.675, -2.8), m_brick)
	_add_static_box_part(n, Vector3(1.8, 3.2, 0.55), Vector3(-2.5, 2.95, -2.8), m_conc)
	_add_static_box_part(n, Vector3(1.8, 3.2, 0.55), Vector3(2.5, 2.95, -2.8), m_conc)
	_add_static_box_part(n, Vector3(6.8, 1.1, 0.55), Vector3(0.0, 4.6, -2.8), m_conc)
	_add_static_box_part(n, Vector3(0.55, 4.2, 5.8), Vector3(-3.15, 2.1, 0.0), m_brick)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(3.8, 0.0, 3.6), Vector3(7.6, 5.0, 7.2)))

func _build_wrecked_city_bus(pos: Vector3, rot_y: float, m_bus: Material, m_steel: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	_add_static_box_part(n, Vector3(2.6, 2.55, 8.4), Vector3(0, 1.45, 0), m_bus)
	_add_decor_box(n, Vector3(2.66, 0.85, 7.2), Vector3(0, 1.95, 0), m_steel)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(4.2, 0.0, 4.2), Vector3(8.4, 2.8, 8.4)))

func _build_sandbag_bunker(pos: Vector3, rot_y: float, m_bag: Material, m_crate: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	_add_static_box_part(n, Vector3(5.2, 1.35, 0.9), Vector3(0, 0.675, -1.6), m_bag)
	_add_static_box_part(n, Vector3(0.9, 1.35, 3.2), Vector3(-2.3, 0.675, 0.0), m_bag)
	_add_static_box_part(n, Vector3(0.9, 1.35, 3.2), Vector3(2.3, 0.675, 0.0), m_bag)
	_add_static_box_part(n, Vector3(1.2, 1.0, 1.2), Vector3(0.8, 0.5, 0.2), m_crate)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(3.0, 0.0, 2.6), Vector3(6.0, 1.6, 5.2)))

func _build_desert_canopy_post(pos: Vector3, rot_y: float, m_bag: Material, m_rust: Material) -> void:
	var n := Node3D.new(); n.position = pos; n.rotation_degrees.y = rot_y; obstacles_root.add_child(n)
	for px in [-2.2, 2.2]:
		for pz in [-2.2, 2.2]:
			_add_static_box_part(n, Vector3(0.28, 3.6, 0.28), Vector3(px, 1.8, pz), m_rust)
	_add_decor_box(n, Vector3(5.0, 0.22, 5.0), Vector3(0, 3.65, 0), m_bag)
	_add_static_box_part(n, Vector3(3.6, 1.25, 0.8), Vector3(0, 0.625, -1.8), m_bag)
	MapObstacles.obstacle_aabbs.append(AABB(pos - Vector3(2.8, 0.0, 2.8), Vector3(5.6, 3.8, 5.6)))

# --- BIOME PERIMETER BACKDROPS ---
func build_biome_backdrop() -> void:
	backdrop_root = Node3D.new()
	backdrop_root.name = "BiomeBackdrop"
	geometry_root.add_child(backdrop_root)

	if current_map_id == "forest" or current_map_id == "arctic":
		_build_pine_forest_backdrop(current_map_id == "arctic")
	elif current_map_id == "factory":
		_build_factory_skyline_backdrop()
	elif current_map_id == "city":
		_build_city_skyline_backdrop()
	elif current_map_id == "desert":
		_build_desert_mesa_backdrop()

func _build_pine_forest_backdrop(is_snowy: bool) -> void:
	var mat_bark := _mk_mat(Color(0.24, 0.16, 0.10), 0.05, 0.92)
	var needle_colors: Array = [
		Color(0.76, 0.84, 0.90), Color(0.68, 0.78, 0.86), Color(0.26, 0.38, 0.36), Color(0.84, 0.90, 0.95)
	] if is_snowy else [
		Color(0.07, 0.17, 0.09), Color(0.10, 0.22, 0.12), Color(0.13, 0.26, 0.14), Color(0.06, 0.14, 0.08)
	]
	var needle_mats: Array[StandardMaterial3D] = []
	for c in needle_colors:
		needle_mats.append(_mk_mat(c, 0.02, 0.85))

	var trunk_mesh := CylinderMesh.new(); trunk_mesh.top_radius = 0.28; trunk_mesh.bottom_radius = 0.42; trunk_mesh.height = 7.5; trunk_mesh.radial_segments = 6
	var tier_b := CylinderMesh.new(); tier_b.top_radius = 0.4; tier_b.bottom_radius = 3.2; tier_b.height = 4.2; tier_b.radial_segments = 6
	var tier_m := CylinderMesh.new(); tier_m.top_radius = 0.25; tier_m.bottom_radius = 2.4; tier_m.height = 3.6; tier_m.radial_segments = 6
	var tier_t := CylinderMesh.new(); tier_t.top_radius = 0.05; tier_t.bottom_radius = 1.6; tier_t.height = 3.2; tier_t.radial_segments = 6

	var rng := RandomNumberGenerator.new(); rng.seed = 98765
	var sides := [
		{"fixed_z": -HALF_SIZE - 6.0, "dir": -1.0},
		{"fixed_z": HALF_SIZE + 6.0, "dir": 1.0},
		{"fixed_x": -HALF_SIZE - 6.0, "dir": -1.0},
		{"fixed_x": HALF_SIZE + 6.0, "dir": 1.0}
	]
	for side in sides:
		for step in range(int(-HALF_SIZE - 12.0), int(HALF_SIZE + 12.0), 8):
			for depth_layer in range(1, 4):
				var od: float = float(depth_layer) * 6.8 + rng.randf_range(-1.5, 1.5)
				var pos := Vector3.ZERO
				if side.has("fixed_z"):
					pos.x = float(step) + rng.randf_range(-2.0, 2.0)
					pos.z = float(side["fixed_z"]) + float(side["dir"]) * od
				else:
					pos.z = float(step) + rng.randf_range(-2.0, 2.0)
					pos.x = float(side["fixed_x"]) + float(side["dir"]) * od
				var f_mat: Material = needle_mats[rng.randi() % needle_mats.size()]
				var tr := Node3D.new(); tr.position = pos
				var sv: float = rng.randf_range(0.85, 1.25)
				tr.scale = Vector3(sv, sv, sv); tr.rotation.y = rng.randf_range(0.0, TAU)
				backdrop_root.add_child(tr)
				for pair in [[trunk_mesh, mat_bark, 3.75], [tier_b, f_mat, 3.8], [tier_m, f_mat, 6.2], [tier_t, f_mat, 8.4]]:
					var mi := MeshInstance3D.new()
					mi.mesh = pair[0]; mi.material_override = pair[1]; mi.position.y = float(pair[2])
					tr.add_child(mi)

func _build_factory_skyline_backdrop() -> void:
	var m_hall := _mk_mat(Color(0.22, 0.23, 0.25), 0.35, 0.82)
	var m_stack := _mk_mat(Color(0.38, 0.24, 0.20), 0.20, 0.88)
	var rng := RandomNumberGenerator.new(); rng.seed = 4411
	for i in range(28):
		var ang: float = (float(i) / 28.0) * TAU
		var dist: float = HALF_SIZE + rng.randf_range(14.0, 28.0)
		var pos := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		if i % 3 == 0:
			var cyl := MeshInstance3D.new()
			var cm := CylinderMesh.new(); cm.top_radius = 1.6; cm.bottom_radius = 2.6; cm.height = rng.randf_range(26.0, 42.0)
			cyl.mesh = cm; cyl.material_override = m_stack; cyl.position = pos + Vector3(0, cm.height * 0.5, 0)
			backdrop_root.add_child(cyl)
		else:
			var h: float = rng.randf_range(12.0, 22.0)
			_add_decor_box(backdrop_root, Vector3(rng.randf_range(14.0, 26.0), h, rng.randf_range(12.0, 20.0)), pos + Vector3(0, h * 0.5, 0), m_hall)

func _build_city_skyline_backdrop() -> void:
	var m_bldg := _mk_mat(Color(0.26, 0.27, 0.30), 0.10, 0.90)
	var m_bldg2 := _mk_mat(Color(0.32, 0.30, 0.28), 0.10, 0.92)
	var rng := RandomNumberGenerator.new(); rng.seed = 7722
	for i in range(36):
		var ang: float = (float(i) / 36.0) * TAU
		var dist: float = HALF_SIZE + rng.randf_range(12.0, 32.0)
		var pos := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var h: float = rng.randf_range(14.0, 38.0)
		_add_decor_box(backdrop_root, Vector3(rng.randf_range(10.0, 18.0), h, rng.randf_range(10.0, 18.0)), pos + Vector3(0, h * 0.5, 0), m_bldg if i % 2 == 0 else m_bldg2)

func _build_desert_mesa_backdrop() -> void:
	var m_mesa := _mk_mat(Color(0.60, 0.44, 0.28), 0.05, 0.95)
	var m_wood := _mk_mat(Color(0.42, 0.32, 0.20), 0.05, 0.90)
	var rng := RandomNumberGenerator.new(); rng.seed = 9933
	for i in range(24):
		var ang: float = (float(i) / 24.0) * TAU
		var dist: float = HALF_SIZE + rng.randf_range(16.0, 36.0)
		var pos := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		if i % 4 == 0:
			# Perimeter wooden guard watchtower
			_add_decor_box(backdrop_root, Vector3(3.8, 11.0, 3.8), pos + Vector3(0, 5.5, 0), m_wood)
			_add_decor_box(backdrop_root, Vector3(5.2, 2.4, 5.2), pos + Vector3(0, 12.2, 0), m_mesa)
		else:
			var h: float = rng.randf_range(10.0, 24.0)
			var cyl := MeshInstance3D.new()
			var cm := CylinderMesh.new(); cm.top_radius = rng.randf_range(6.0, 12.0); cm.bottom_radius = rng.randf_range(14.0, 24.0); cm.height = h; cm.radial_segments = 7
			cyl.mesh = cm; cyl.material_override = m_mesa; cyl.position = pos + Vector3(0, h * 0.5, 0)
			backdrop_root.add_child(cyl)

func build_perimeter_spawn_points() -> void:
	var spawns_root := Node3D.new()
	spawns_root.name = "PerimeterSpawnPoints"
	geometry_root.add_child(spawns_root)

	var spawn_dist: float = HALF_SIZE - 9.5
	var count_per_side: int = 5
	for i in range(count_per_side):
		var frac: float = float(i) / float(count_per_side - 1)
		var offset: float = lerpf(-spawn_dist + 12.0, spawn_dist - 12.0, frac)
		create_spawn_marker(spawns_root, Vector3(offset, 0.1, -spawn_dist))
		create_spawn_marker(spawns_root, Vector3(offset, 0.1, spawn_dist))
		create_spawn_marker(spawns_root, Vector3(-spawn_dist, 0.1, offset))
		create_spawn_marker(spawns_root, Vector3(spawn_dist, 0.1, offset))

func create_spawn_marker(parent: Node3D, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = "ProcSpawn_%d" % (spawn_markers.size() + 1)
	marker.position = pos
	parent.add_child(marker)
	spawn_markers.append(marker)

static func _mk_mat(col: Color, met: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col; m.metallic = met; m.roughness = rough
	return m

static func _add_decor_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.material_override = mat; mi.position = pos
	parent.add_child(mi)
