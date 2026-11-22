class_name PreviewDrone
extends RefCounted

# High-Fidelity Procedural Shahed-136 Kamikaze Delta-Wing UAV + Green Crewmate Pilot
# Shared by BOTH live Battlefield Drones (drone_enemy.gd) AND Handbook 3D Inspector!
# Features:
# - True swept aerodynamic triangular delta-wing mesh built with SurfaceTool (NO blocky rectangles!)
# - Blended cylindrical/tapered fuselage with pointed warhead nose cone, pitot probe & hazard band
# - Swept vertical wingtip winglets with red & green aviation navigation strobe lights
# - Rear boxer engine nacelle, twin chrome exhaust pipes, spinner hub & pitched 2-blade pusher prop ("Propeller")
# - Iconic detailed mini Green Crewmate pilot in dorsal cockpit with curved reflective visor & mini backpack
# Note: forward_plus_z = true for live drone_enemy.gd (+Z nose), false for Handbook preview (-Z nose)

static func _add_box(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _build_swept_delta_wing_mesh(mat: Material) -> MeshInstance3D:
	# Builds a genuine swept aerodynamic Shahed-136 triangular delta wing (+Z is forward nose!)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var y_top: float = 0.026
	var y_bot: float = -0.026
	# Wing planform points (nose apex at Z=+0.75, trailing root at Z=-0.62, wingtips at X=±1.14, Z=-0.58..-0.18)
	var pts_2d: Array[Vector2] = [
		Vector2(0.0, 0.78),    # 0: front center apex
		Vector2(1.14, -0.22),  # 1: right leading tip
		Vector2(1.14, -0.62),  # 2: right trailing tip
		Vector2(0.0, -0.64),   # 3: rear center trailing edge
		Vector2(-1.14, -0.62), # 4: left trailing tip
		Vector2(-1.14, -0.22)  # 5: left leading tip
	]
	var top_pts: Array[Vector3] = []
	var bot_pts: Array[Vector3] = []
	for i in range(pts_2d.size()):
		var p := pts_2d[i]
		var thick: float = 1.0 if (i == 0 or i == 3) else 0.42
		top_pts.append(Vector3(p.x, y_top * thick, p.y))
		bot_pts.append(Vector3(p.x, y_bot * thick, p.y))
		
	var tris := [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
	# Top faces
	for t in tris:
		st.add_vertex(top_pts[t[0]])
		st.add_vertex(top_pts[t[1]])
		st.add_vertex(top_pts[t[2]])
	# Bottom faces (reversed winding)
	for t in tris:
		st.add_vertex(bot_pts[t[0]])
		st.add_vertex(bot_pts[t[2]])
		st.add_vertex(bot_pts[t[1]])
	# Perimeter beveled edge walls
	for i in range(pts_2d.size()):
		var j: int = (i + 1) % pts_2d.size()
		st.add_vertex(top_pts[i])
		st.add_vertex(bot_pts[i])
		st.add_vertex(bot_pts[j])
		st.add_vertex(top_pts[i])
		st.add_vertex(bot_pts[j])
		st.add_vertex(top_pts[j])
		
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "DeltaWing"
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi

static func populate_drone_visuals(parent: Node3D) -> Dictionary:
	# All geometry built with nose pointing strictly along +Z (matching drone_enemy.gd flight axis!)
	var mat_composite := StandardMaterial3D.new()
	mat_composite.albedo_color = Color(0.24, 0.26, 0.28) # Matte radar-absorbing military grey
	mat_composite.roughness = 0.50
	mat_composite.metallic = 0.22
	
	var mat_nose := StandardMaterial3D.new()
	mat_nose.albedo_color = Color(0.14, 0.15, 0.16)
	mat_nose.roughness = 0.36
	mat_nose.metallic = 0.45
	
	var mat_hazard := StandardMaterial3D.new()
	mat_hazard.albedo_color = Color(0.86, 0.18, 0.12) # Warhead warning band
	mat_hazard.roughness = 0.42
	
	var mat_engine := StandardMaterial3D.new()
	mat_engine.albedo_color = Color(0.11, 0.12, 0.14)
	mat_engine.metallic = 0.85
	mat_engine.roughness = 0.30
	
	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.75, 0.77, 0.80)
	mat_chrome.metallic = 0.94
	mat_chrome.roughness = 0.20
	
	var mat_prop := StandardMaterial3D.new()
	mat_prop.albedo_color = Color(0.16, 0.11, 0.08) # Laminated pusher propeller wood/composite
	mat_prop.roughness = 0.34
	mat_prop.metallic = 0.20
	
	var mat_prop_tip := StandardMaterial3D.new()
	mat_prop_tip.albedo_color = Color(0.95, 0.78, 0.12) # Yellow safety prop tips
	mat_prop_tip.roughness = 0.35
	
	var mat_nav_red := StandardMaterial3D.new()
	mat_nav_red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_nav_red.albedo_color = Color(1.0, 0.18, 0.14)
	
	var mat_nav_green := StandardMaterial3D.new()
	mat_nav_green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_nav_green.albedo_color = Color(0.18, 1.0, 0.36)
	
	var flash_meshes: Array[MeshInstance3D] = []

	# 1. Swept Delta Wing
	var wing := _build_swept_delta_wing_mesh(mat_composite)
	parent.add_child(wing)
	flash_meshes.append(wing)
	
	# 2. Blended Aerodynamic Central Fuselage + Pointed Warhead Nose Cone + Pitot Probe
	var fuse := _add_cyl(parent, "Fuselage", 0.125, 0.135, 1.32, Vector3(0, 0.02, 0.04), mat_composite, 14, Vector3(90.0, 0, 0))
	fuse.scale = Vector3(1.15, 1.0, 0.82)
	flash_meshes.append(fuse)
	
	var nose := _add_cyl(parent, "NoseCone", 0.018, 0.124, 0.44, Vector3(0, 0.02, 0.90), mat_nose, 14, Vector3(90.0, 0, 0))
	nose.scale = Vector3(1.15, 1.0, 0.82)
	var band := _add_cyl(parent, "HazardBand", 0.112, 0.122, 0.055, Vector3(0, 0.02, 0.72), mat_hazard, 14, Vector3(90.0, 0, 0))
	band.scale = Vector3(1.16, 1.0, 0.83)
	_add_cyl(parent, "PitotProbe", 0.005, 0.009, 0.18, Vector3(0, 0.02, 1.18), mat_chrome, 8, Vector3(90.0, 0, 0))
	
	# Panel access hatch & trailing control elevons
	_add_box(parent, "ElevonL", Vector3(0.68, 0.018, 0.09), Vector3(-0.56, 0.0, -0.65), mat_nose)
	_add_box(parent, "ElevonR", Vector3(0.68, 0.018, 0.09), Vector3(0.56, 0.0, -0.65), mat_nose)

	# 3. Swept Wingtip Stabilizer Winglets + Aviation Navigation Strobes
	for sx in [-1.0, 1.0]:
		var wl := _add_box(parent, "Winglet", Vector3(0.032, 0.34, 0.44), Vector3(1.14 * sx, 0.06, -0.44), mat_composite, Vector3(-16.0, 0, 0))
		flash_meshes.append(wl)
		_add_box(parent, "WingletTipStripe", Vector3(0.036, 0.05, 0.38), Vector3(1.14 * sx, 0.18, -0.46), mat_hazard, Vector3(-16.0, 0, 0))
		var nav := MeshInstance3D.new()
		var nm := SphereMesh.new()
		nm.radius = 0.028
		nm.height = 0.056
		nav.mesh = nm
		nav.material_override = mat_nav_red if sx < 0.0 else mat_nav_green
		nav.position = Vector3(1.15 * sx, 0.22, -0.34)
		parent.add_child(nav)

	# 4. Rear Pusher Boxer Engine Cowling, Twin Exhausts & Spinning 2-Blade Propeller ("Propeller")
	_add_cyl(parent, "EngineNacelle", 0.11, 0.085, 0.28, Vector3(0, 0.02, -0.72), mat_engine, 12, Vector3(90.0, 0, 0))
	for sx in [-0.095, 0.095]:
		_add_box(parent, "CylinderHead", Vector3(0.08, 0.07, 0.14), Vector3(sx, 0.02, -0.70), mat_engine)
		_add_cyl(parent, "ExhaustPipe", 0.016, 0.016, 0.16, Vector3(sx * 1.1, -0.04, -0.78), mat_chrome, 8, Vector3(105.0, 0, 0))
	
	var prop_hub := Node3D.new()
	prop_hub.name = "Propeller"
	prop_hub.position = Vector3(0, 0.02, -0.89)
	parent.add_child(prop_hub)
	_add_cyl(prop_hub, "SpinnerCone", 0.046, 0.010, 0.09, Vector3(0, 0, -0.02), mat_chrome, 10, Vector3(90.0, 0, 0))
	# Pitched 2-blade composite pusher propeller with yellow safety tips
	for s in [-1.0, 1.0]:
		var b := _add_box(prop_hub, "Blade", Vector3(0.28, 0.048, 0.012), Vector3(0.15 * s, 0, 0), mat_prop, Vector3(14.0 * s, 0, 0))
		_add_box(b, "Tip", Vector3(0.048, 0.044, 0.014), Vector3(0.125 * s, 0, 0), mat_prop_tip)

	# 5. Iconic Detailed Mini Green Crewmate Pilot in Dorsal Cockpit!
	var mat_green := StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.15, 0.85, 0.25)
	mat_green.roughness = 0.35
	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.38, 0.84, 0.98)
	mat_visor.metallic = 0.65
	mat_visor.roughness = 0.08
	
	var cockpit := Node3D.new()
	cockpit.name = "GreenCrewmatePilot"
	cockpit.position = Vector3(0, 0.22, 0.16)
	parent.add_child(cockpit)
	_add_cyl(cockpit, "CockpitRim", 0.19, 0.21, 0.06, Vector3(0, -0.10, 0), mat_engine, 14)
	var dome := MeshInstance3D.new()
	var dm := CapsuleMesh.new()
	dm.radius = 0.145
	dm.height = 0.38
	dm.radial_segments = 16
	dome.mesh = dm
	dome.material_override = mat_green
	cockpit.add_child(dome)
	# Rounded visor frame + glass
	var vf := MeshInstance3D.new()
	var vfm := CapsuleMesh.new()
	vfm.radius = 0.062
	vfm.height = 0.21
	vf.mesh = vfm
	vf.material_override = mat_engine
	vf.rotation_degrees = Vector3(0, 0, 90.0)
	vf.scale = Vector3(1.0, 1.0, 0.65)
	vf.position = Vector3(0, 0.045, 0.115)
	cockpit.add_child(vf)
	var vg := MeshInstance3D.new()
	var vgm := CapsuleMesh.new()
	vgm.radius = 0.048
	vgm.height = 0.18
	vg.mesh = vgm
	vg.material_override = mat_visor
	vg.rotation_degrees = Vector3(0, 0, 90.0)
	vg.scale = Vector3(1.0, 1.0, 0.72)
	vg.position = Vector3(0, 0.045, 0.132)
	cockpit.add_child(vg)
	_add_box(cockpit, "MiniBackpack", Vector3(0.18, 0.22, 0.10), Vector3(0, -0.01, -0.13), mat_green)

	return {
		"propeller": prop_hub,
		"fuselage": fuse,
		"wing": wing,
		"flash_meshes": flash_meshes,
		"base_mat": mat_composite
	}

# Handbook 3D Inspector factory
static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "DronePreview"
	var holder := Node3D.new()
	holder.rotation.y = PI # Point nose toward Handbook camera nicely
	root.add_child(holder)
	populate_drone_visuals(holder)
	return root
