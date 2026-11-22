class_name ForestBackdrop
extends Node3D

# Procedural distant forest encircling the battlefield beyond the earth berms
# Conifer / spruce trees of varying heights, shades and layers

func _ready() -> void:
	build_distant_forest()

func build_distant_forest() -> void:
	# Materials for evergreen spruce & pine
	var mat_bark := StandardMaterial3D.new()
	mat_bark.albedo_color = Color(0.24, 0.16, 0.10)
	mat_bark.roughness = 0.92
	mat_bark.metallic = 0.0
	
	var needle_colors = [
		Color(0.07, 0.17, 0.09), # Deep spruce
		Color(0.10, 0.22, 0.12), # Russian taiga pine
		Color(0.13, 0.26, 0.14), # Fresh needle green
		Color(0.06, 0.14, 0.08)  # Shadow conifer
	]
	
	var needle_materials: Array[StandardMaterial3D] = []
	for col in needle_colors:
		var nm := StandardMaterial3D.new()
		nm.albedo_color = col
		nm.roughness = 0.85
		nm.metallic = 0.0
		needle_materials.append(nm)

	# Shared meshes for efficient memory usage
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

	# 1. Left Flank Forest (outside LeftConeWall and RearLeftWall: strictly beyond earthen walls)
	for z_step in range(-175, 25, 6):
		var zl = float(z_step) + randf_range(-2.5, 2.5)
		var wall_xl: float = -22.0
		if zl < -14.0:
			wall_xl = -22.0 - ((-zl - 14.0) / 146.0) * 26.0
		for layer in range(3):
			var dist_out_l = 7.0 + layer * 8.0 + randf_range(-1.0, 3.0)
			var xl = wall_xl - dist_out_l
			_spawn_pine_tree(Vector3(xl, 0, zl), trunk_mesh, tier_bottom, tier_mid, tier_top, mat_bark, needle_materials.pick_random())

	# 2. Right Flank Forest (outside RightConeWall and RearRightWall: strictly beyond earthen walls)
	for z_step in range(-175, 25, 6):
		var zr = float(z_step) + randf_range(-2.5, 2.5)
		var wall_xr: float = 22.0
		if zr < -14.0:
			wall_xr = 22.0 + ((-zr - 14.0) / 146.0) * 26.0
		for layer in range(3):
			var dist_out_r = 7.0 + layer * 8.0 + randf_range(-1.0, 3.0)
			var xr = wall_xr + dist_out_r
			_spawn_pine_tree(Vector3(xr, 0, zr), trunk_mesh, tier_bottom, tier_mid, tier_top, mat_bark, needle_materials.pick_random())

	# 3. Base / Distant Horizon Forest (Beyond enemy spawn base: Z from -170 to -220, X from -70 to 70)
	for x_step in range(-70, 71, 5):
		var xb = float(x_step) + randf_range(-2.0, 2.0)
		for layer in range(3):
			var zb = -170.0 - layer * 9.5 + randf_range(-2.0, 2.0)
			_spawn_pine_tree(Vector3(xb, 0, zb), trunk_mesh, tier_bottom, tier_mid, tier_top, mat_bark, needle_materials.pick_random())

	# 4. Rear Forest (Strictly behind rear earthen wall Z = 21.0, starting at Z >= 29.5 to prevent branches entering shop)
	for x_step in range(-40, 41, 6):
		var x_rear = float(x_step) + randf_range(-2.0, 2.0)
		for layer in range(4):
			var z_rear = 30.0 + layer * 8.5 + randf_range(-1.5, 2.5)
			_spawn_pine_tree(Vector3(x_rear, 0, z_rear), trunk_mesh, tier_bottom, tier_mid, tier_top, mat_bark, needle_materials.pick_random())

func _spawn_pine_tree(pos: Vector3, t_mesh: Mesh, b_mesh: Mesh, m_mesh: Mesh, top_mesh: Mesh, t_mat: Material, f_mat: Material) -> void:
	# Absolute safety guard: strictly reject any tree inside or near the shop and playable arena
	if pos.z < 28.5 and absf(pos.x) < 27.0:
		return
	if pos.z <= -14.0 and absf(pos.x) < (22.0 + ((-pos.z - 14.0) / 146.0) * 26.0 + 5.0):
		return
	var tree := Node3D.new()
	var s := randf_range(0.85, 1.4)
	tree.scale = Vector3(s, s * randf_range(0.95, 1.3), s)
	tree.position = pos
	tree.rotation_degrees.y = randf_range(0, 360)
	add_child(tree)
	
	# Trunk
	var trunk := MeshInstance3D.new()
	trunk.mesh = t_mesh
	trunk.material_override = t_mat
	trunk.position = Vector3(0, 3.75, 0)
	tree.add_child(trunk)
	
	# Bottom needle tier
	var tier1 := MeshInstance3D.new()
	tier1.mesh = b_mesh
	tier1.material_override = f_mat
	tier1.position = Vector3(0, 5.2, 0)
	tree.add_child(tier1)
	
	# Middle needle tier
	var tier2 := MeshInstance3D.new()
	tier2.mesh = m_mesh
	tier2.material_override = f_mat
	tier2.position = Vector3(0, 7.6, 0)
	tree.add_child(tier2)
	
	# Top needle tier
	var tier3 := MeshInstance3D.new()
	tier3.mesh = top_mesh
	tier3.material_override = f_mat
	tier3.position = Vector3(0, 9.8, 0)
	tree.add_child(tier3)
