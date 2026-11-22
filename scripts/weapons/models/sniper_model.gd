class_name SniperModel
extends RefCounted

# High-Fidelity Procedural AI L96A1 / AWP Precision Sniper Rifle
# Shared across Green Sniper Enemy & Handbook 3D Inspector.
# Features:
# - Sculpted AI Olive Drab polymer thumbhole chassis with ventilated barrel channel
# - Adjustable cheek rest with knurled thumbscrews, rear monopod hook & thick ribbed buttpad
# - Machined match steel receiver, full toothed Picatinny rail & swept bolt handle with tactical knob
# - Detachable 10-round steel box magazine with rubber floorplate
# - Heavy fluted match barrel with dark bore & massive dual-baffle tactical muzzle brake
# - Articulated Harris-style folded tactical bipod with springs & rubber feet
# - Long-range sniper scope with cantilevered rings, knurled turrets, honeycomb sunshade & coated lens
# - Forward direction strictly along +Z (muzzle at +Z ~ 1.14m)

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

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3(90.0, 0.0, 0.0)) -> MeshInstance3D:
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
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func create(mat_metal_override: Material = null, mat_stock_override: Material = null) -> Node3D:
	var root := Node3D.new()
	root.name = "SniperModel"
	
	var mat_steel: Material = mat_metal_override
	if not mat_steel:
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.12, 0.13, 0.15) # Matte parkerized match steel
		ms.metallic = 0.90
		ms.roughness = 0.26
		mat_steel = ms
		
	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.07, 0.08, 0.09)
	mat_steel_dark.metallic = 0.82
	mat_steel_dark.roughness = 0.38
	
	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.76, 0.78, 0.82) # Fluted stainless bolt body
	mat_bolt.metallic = 0.96
	mat_bolt.roughness = 0.16
	
	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.02, 0.02, 0.025)
	mat_bore.roughness = 0.95
	
	var mat_od: Material = mat_stock_override
	if not mat_od:
		var mo := StandardMaterial3D.new()
		mo.albedo_color = Color(0.22, 0.28, 0.19) # Authentic Accuracy International Olive Drab
		mo.roughness = 0.58
		mo.metallic = 0.05
		mat_od = mo
		
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.06, 0.065, 0.075)
	mat_rubber.roughness = 0.90
	
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.10, 0.44, 0.38, 0.92)
	mat_lens.metallic = 0.70
	mat_lens.roughness = 0.05
	mat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# ==========================================
	# 1. ACCURACY INTERNATIONAL POLYMER THUMBHOLE CHASSIS
	# ==========================================
	_add_box(root, "Forend", Vector3(0.062, 0.076, 0.56), Vector3(0, -0.014, 0.31), mat_od)
	# Cooling vent slots along forend sides
	for i in range(4):
		_add_box(root, "ForendSlot_%d" % i, Vector3(0.066, 0.014, 0.055), Vector3(0, 0.002, 0.24 + float(i) * 0.095), mat_steel_dark)
	_add_box(root, "ForendCap", Vector3(0.060, 0.074, 0.022), Vector3(0, -0.014, 0.595), mat_steel_dark)
	_add_box(root, "MidChassis", Vector3(0.064, 0.078, 0.24), Vector3(0, -0.010, -0.04), mat_od)
	# Ergonomic thumbhole pistol grip + base cap
	_add_box(root, "Grip", Vector3(0.050, 0.132, 0.066), Vector3(0, -0.090, -0.140), mat_od, Vector3(17.0, 0, 0))
	_add_box(root, "GripCap", Vector3(0.054, 0.014, 0.070), Vector3(0, -0.155, -0.160), mat_rubber, Vector3(17.0, 0, 0))
	# Upper stock bridge, lower strut & rear buttstock enclosing thumbhole
	_add_box(root, "StockComb", Vector3(0.052, 0.040, 0.25), Vector3(0, 0.005, -0.27), mat_od)
	_add_box(root, "StockLowerStrut", Vector3(0.046, 0.030, 0.22), Vector3(0, -0.150, -0.26), mat_od)
	_add_box(root, "ButtstockMain", Vector3(0.058, 0.145, 0.145), Vector3(0, -0.068, -0.38), mat_od)
	# Adjustable satin rubber cheek riser + twin knurled adjustment knobs
	_add_box(root, "CheekRest", Vector3(0.058, 0.032, 0.16), Vector3(0, 0.036, -0.28), mat_rubber)
	for sx in [-0.032, 0.032]:
		_add_cyl(root, "CheekKnob", 0.008, 0.008, 0.008, Vector3(sx, 0.020, -0.28), mat_steel, 8, Vector3(0, 0, 90))
	# Spacer plates + heavy ribbed recoil buttpad + rear monopod foot
	_add_box(root, "ButtSpacers", Vector3(0.060, 0.148, 0.022), Vector3(0, -0.068, -0.456), mat_steel_dark)
	_add_box(root, "ButtPad", Vector3(0.062, 0.154, 0.032), Vector3(0, -0.068, -0.482), mat_rubber)
	_add_cyl(root, "Monopod", 0.008, 0.010, 0.048, Vector3(0, -0.162, -0.415), mat_steel_dark, 8, Vector3.ZERO)

	# ==========================================
	# 2. MATCH RECEIVER, BOLT ACTION & 10-RD MAGAZINE
	# ==========================================
	_add_box(root, "Receiver", Vector3(0.058, 0.062, 0.34), Vector3(0, 0.042, 0.06), mat_steel)
	# Toothed full-length Picatinny rail
	_add_box(root, "RailBase", Vector3(0.028, 0.012, 0.32), Vector3(0, 0.078, 0.06), mat_steel_dark)
	for i in range(14):
		_add_box(root, "RailLug_%d" % i, Vector3(0.030, 0.005, 0.011), Vector3(0, 0.086, -0.09 + float(i) * 0.023), mat_steel_dark)
	# Ejection port exposing fluted stainless bolt body
	_add_box(root, "EjectRecess", Vector3(0.014, 0.026, 0.096), Vector3(0.024, 0.050, 0.075), mat_bore)
	_add_cyl(root, "BoltBody", 0.013, 0.013, 0.19, Vector3(0, 0.052, -0.01), mat_bolt, 12)
	_add_cyl(root, "BoltShroud", 0.016, 0.015, 0.045, Vector3(0, 0.052, -0.125), mat_steel_dark, 12)
	# Swept bolt handle stem + oversized tactical knurled knob
	_add_cyl(root, "BoltStem", 0.0055, 0.0055, 0.064, Vector3(0.042, 0.042, -0.075), mat_steel, 8, Vector3(0, 0, 52))
	var knob := MeshInstance3D.new()
	knob.name = "BoltKnob"
	var km := SphereMesh.new()
	km.radius = 0.014
	km.height = 0.028
	knob.mesh = km
	knob.material_override = mat_rubber
	knob.position = Vector3(0.074, 0.022, -0.075)
	root.add_child(knob)
	
	# 10-Round Box Magazine & Trigger Assembly
	_add_box(root, "Magazine", Vector3(0.042, 0.088, 0.102), Vector3(0, -0.074, 0.03), mat_steel_dark)
	_add_box(root, "MagBasepad", Vector3(0.048, 0.014, 0.110), Vector3(0, -0.122, 0.03), mat_rubber)
	_add_box(root, "TriggerGuardLow", Vector3(0.018, 0.006, 0.068), Vector3(0, -0.095, -0.082), mat_steel_dark)
	_add_box(root, "TriggerGuardFront", Vector3(0.018, 0.044, 0.006), Vector3(0, -0.073, -0.048), mat_steel_dark)
	_add_box(root, "Trigger", Vector3(0.007, 0.026, 0.010), Vector3(0, -0.070, -0.082), mat_bolt, Vector3(18.0, 0, 0))

	# ==========================================
	# 3. HEAVY FLUTED BARREL, DUAL-BAFFLE MUZZLE BRAKE & BIPOD
	# ==========================================
	_add_cyl(root, "Barrel", 0.0155, 0.020, 0.72, Vector3(0, 0.044, 0.58), mat_steel, 16)
	# Longitudinal barrel cooling flutes
	for ang in [0, 60, 120, 180, 240, 300]:
		var rad := deg_to_rad(float(ang))
		_add_box(root, "Flute_%d" % ang, Vector3(0.004, 0.004, 0.44), Vector3(cos(rad) * 0.0175, 0.044 + sin(rad) * 0.0175, 0.56), mat_steel_dark)
	# Massive dual-chamber rectangular sniper muzzle brake with side ports
	_add_box(root, "BrakeBody", Vector3(0.044, 0.038, 0.115), Vector3(0, 0.044, 1.00), mat_steel_dark)
	for pz in [0.972, 1.022]:
		_add_box(root, "BrakePort", Vector3(0.048, 0.024, 0.024), Vector3(0, 0.044, pz), mat_bore)
	_add_cyl(root, "MuzzleBore", 0.011, 0.011, 0.012, Vector3(0, 0.044, 1.058), mat_bore, 10)
	
	# Folded Harris-Style Tactical Bipod under front chassis
	_add_box(root, "BipodMount", Vector3(0.048, 0.026, 0.056), Vector3(0, -0.062, 0.55), mat_steel_dark)
	for sx in [-1.0, 1.0]:
		_add_cyl(root, "BipodLeg", 0.009, 0.008, 0.25, Vector3(0.036 * sx, -0.072, 0.44), mat_steel, 10, Vector3(90.0, 6.0 * sx, 0))
		_add_cyl(root, "BipodFoot", 0.014, 0.014, 0.022, Vector3(0.052 * sx, -0.072, 0.315), mat_rubber, 10, Vector3(90.0, 6.0 * sx, 0))

	# ==========================================
	# 4. HIGH-POWER SNIPER SCOPE (34MM TUBE, TURRETS & SUNSHADE)
	# ==========================================
	for rz in [-0.02, 0.14]:
		_add_box(root, "RingStem", Vector3(0.028, 0.032, 0.024), Vector3(0, 0.102, rz), mat_steel_dark)
		_add_cyl(root, "ScopeRing", 0.025, 0.025, 0.026, Vector3(0, 0.130, rz), mat_steel_dark, 16)
	_add_cyl(root, "ScopeTube", 0.020, 0.020, 0.28, Vector3(0, 0.130, 0.06), mat_steel, 16)
	# Objective bell + long sunshade + coated emerald glass
	_add_cyl(root, "ObjectiveBell", 0.032, 0.020, 0.075, Vector3(0, 0.130, 0.22), mat_steel, 18)
	_add_cyl(root, "Sunshade", 0.033, 0.033, 0.085, Vector3(0, 0.130, 0.295), mat_steel_dark, 18)
	_add_cyl(root, "FrontLens", 0.029, 0.029, 0.006, Vector3(0, 0.130, 0.330), mat_lens, 16)
	# Ocular bell + zoom ring + rubber eyecup
	_add_cyl(root, "OcularBell", 0.020, 0.026, 0.075, Vector3(0, 0.130, -0.10), mat_steel, 18)
	_add_cyl(root, "ZoomRing", 0.027, 0.027, 0.018, Vector3(0, 0.130, -0.07), mat_rubber, 16)
	_add_cyl(root, "OcularLens", 0.022, 0.022, 0.005, Vector3(0, 0.130, -0.138), mat_lens, 16)
	# Tactical elevation, windage & parallax turrets
	_add_box(root, "TurretSaddle", Vector3(0.044, 0.044, 0.044), Vector3(0, 0.130, 0.06), mat_steel_dark)
	_add_cyl(root, "ElevTurret", 0.014, 0.014, 0.026, Vector3(0, 0.162, 0.06), mat_rubber, 12, Vector3.ZERO)
	_add_cyl(root, "WindTurret", 0.014, 0.014, 0.024, Vector3(0.030, 0.130, 0.06), mat_rubber, 12, Vector3(0, 0, 90))
	_add_cyl(root, "ParallaxTurret", 0.013, 0.013, 0.022, Vector3(-0.029, 0.130, 0.06), mat_rubber, 12, Vector3(0, 0, 90))

	return root
