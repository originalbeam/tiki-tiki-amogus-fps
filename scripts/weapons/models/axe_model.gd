class_name AxeModel
extends RefCounted

# High-Fidelity Procedural Pickhead Tactical Fire / Breaching Axe
# Shared across Yellow Heavy Enemy & Handbook 3D Inspector.
# Features:
# - Contoured fiberglass shaft with black diamond-ribbed rubber grip, fawn-foot pommel & lanyard ring
# - Machined steel overstrike collar guard with rivets
# - Sculpted forged crimson-lacquered axe head with chamfered cheeks & top wedge pin
# - Convex mirror-honed curved steel cutting blade (+Z) & tapered armor-piercing rear pick (-Z)

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

static func create(mat_shaft_override: Material = null, mat_head_override: Material = null, mat_steel_override: Material = null) -> Node3D:
	var root := Node3D.new()
	root.name = "AxeModel"
	
	var mat_yellow: Material = mat_shaft_override
	if not mat_yellow:
		var my := StandardMaterial3D.new()
		my.albedo_color = Color(0.92, 0.72, 0.08) # High-vis fiberglass rescue yellow
		my.roughness = 0.30
		my.metallic = 0.08
		mat_yellow = my
		
	var mat_grip := StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.08, 0.09, 0.10) # Textured non-slip rubber grip
	mat_grip.roughness = 0.90
	
	var mat_red: Material = mat_head_override
	if not mat_red:
		var mr := StandardMaterial3D.new()
		mr.albedo_color = Color(0.78, 0.09, 0.09) # Forged fire-rescue crimson lacquer
		mr.metallic = 0.42
		mr.roughness = 0.32
		mat_red = mr
		
	var mat_steel: Material = mat_steel_override
	if not mat_steel:
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.90, 0.93, 0.96) # Mirror-honed high-carbon steel edge
		ms.metallic = 0.98
		ms.roughness = 0.11
		mat_steel = ms
		
	var mat_dark_steel := StandardMaterial3D.new()
	mat_dark_steel.albedo_color = Color(0.18, 0.20, 0.22)
	mat_dark_steel.metallic = 0.88
	mat_dark_steel.roughness = 0.36

	# ==========================================
	# 1. ERGONOMIC SHAFT, RUBBER GRIP & OVERSTRIKE COLLAR
	# ==========================================
	var grip := _add_cyl(root, "RubberGrip", 0.022, 0.019, 0.46, Vector3(0, -0.17, 0), mat_grip, 14)
	grip.scale = Vector3(0.82, 1.0, 1.24)
	# Ribbed non-slip grip rings
	for i in range(6):
		var gr := _add_cyl(root, "GripRing_%d" % i, 0.024, 0.024, 0.014, Vector3(0, -0.34 + float(i) * 0.062, 0), mat_dark_steel, 14)
		gr.scale = Vector3(0.84, 1.0, 1.26)
	# Fawn-foot pommel flare + steel lanyard eyelet
	_add_box(root, "PommelFoot", Vector3(0.036, 0.072, 0.068), Vector3(0, -0.42, 0.015), mat_grip, Vector3(16.0, 0, 0))
	_add_box(root, "PommelPlate", Vector3(0.038, 0.012, 0.070), Vector3(0, -0.456, 0.024), mat_dark_steel, Vector3(16.0, 0, 0))
	_add_cyl(root, "LanyardHole", 0.008, 0.008, 0.044, Vector3(0, -0.42, 0.018), mat_steel, 10, Vector3(0, 0, 90))
	
	# Steel ferrule ring + upper yellow fiberglass oval shaft
	var ferrule := _add_cyl(root, "Ferrule", 0.025, 0.024, 0.024, Vector3(0, 0.072, 0), mat_steel, 14)
	ferrule.scale = Vector3(0.84, 1.0, 1.25)
	var shaft := _add_cyl(root, "UpperShaft", 0.025, 0.023, 0.28, Vector3(0, 0.22, 0), mat_yellow, 14)
	shaft.scale = Vector3(0.84, 1.0, 1.28)
	# Machined steel overstrike guard sleeve beneath axe head with twin bolts
	var guard := _add_cyl(root, "OverstrikeGuard", 0.028, 0.026, 0.078, Vector3(0, 0.345, 0.004), mat_dark_steel, 14)
	guard.scale = Vector3(0.85, 1.0, 1.32)
	for by in [0.325, 0.362]:
		_add_cyl(root, "GuardBolt", 0.005, 0.005, 0.052, Vector3(0, by, 0.004), mat_steel, 6, Vector3(0, 0, 90))

	# ==========================================
	# 2. FORGED AXE HEAD, CONVEX STEEL BLADE & REAR PICK
	# ==========================================
	# Heavy forged eye housing & top wedged tang cap
	_add_box(root, "HeadEye", Vector3(0.052, 0.105, 0.094), Vector3(0, 0.415, 0), mat_red)
	_add_box(root, "TopWedge", Vector3(0.036, 0.014, 0.068), Vector3(0, 0.470, 0), mat_steel)
	
	# Sculpted cheek taper & flared crimson bit (+Z)
	_add_box(root, "BladeCheek", Vector3(0.036, 0.132, 0.105), Vector3(0, 0.410, 0.088), mat_red)
	_add_box(root, "BladeFlare", Vector3(0.024, 0.166, 0.058), Vector3(0, 0.405, 0.150), mat_red)
	# Multi-segment convex mirror-honed razor steel edge (+Z)
	_add_box(root, "BevelMid", Vector3(0.015, 0.184, 0.034), Vector3(0, 0.402, 0.188), mat_steel)
	_add_box(root, "BevelTop", Vector3(0.011, 0.064, 0.026), Vector3(0, 0.464, 0.194), mat_steel, Vector3(-18.0, 0, 0))
	_add_box(root, "BevelBot", Vector3(0.011, 0.064, 0.026), Vector3(0, 0.340, 0.194), mat_steel, Vector3(18.0, 0, 0))
	var razor := MeshInstance3D.new()
	razor.name = "RazorEdge"
	var rm := PrismMesh.new()
	rm.size = Vector3(0.010, 0.026, 0.188)
	razor.mesh = rm
	razor.material_override = mat_steel
	razor.position = Vector3(0, 0.402, 0.214)
	razor.rotation_degrees = Vector3(90.0, 0, 0)
	root.add_child(razor)
	
	# Curved Armor-Piercing Rear Pick Spike (-Z)
	_add_box(root, "PickBase", Vector3(0.038, 0.062, 0.085), Vector3(0, 0.422, -0.078), mat_red)
	_add_box(root, "PickMid", Vector3(0.026, 0.044, 0.088), Vector3(0, 0.406, -0.152), mat_red, Vector3(16.0, 0, 0))
	var pick_tip := MeshInstance3D.new()
	pick_tip.name = "PickTip"
	var ptm := PrismMesh.new()
	ptm.size = Vector3(0.018, 0.072, 0.032)
	pick_tip.mesh = ptm
	pick_tip.material_override = mat_steel
	pick_tip.position = Vector3(0, 0.380, -0.214)
	pick_tip.rotation_degrees = Vector3(-104.0, 0, 0)
	root.add_child(pick_tip)

	return root
