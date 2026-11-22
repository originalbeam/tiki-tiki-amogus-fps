class_name ShotgunModel
extends RefCounted

# High-Fidelity Procedural Remington 870 / Mossberg 590 Tactical Pump Shotgun
# Shared across First-Person Viewmodel, Handbook Inspector & Shop Preview.
# Features:
# - Sculpted parkerized steel receiver with chamfered top & recessed right ejection port
# - Reciprocating chrome bolt ("Bolt") & hinged bottom loading elevator ("Elevator")
# - Heavy 12-gauge barrel with dark bore, ventilated sight rib with support posts & glowing brass bead
# - Full-length tubular magazine with knurled steel end cap & barrel clamp with sling stud
# - Corncob-ribbed walnut pump forend ("Pump") with twin steel action bars
# - Left-side tactical shell saddle holding 4 red/brass 12-gauge shells
# - Contoured walnut buttstock with wrist swell, white spacer & thick ribbed rubber recoil pad
# - Detachable animated 12G shell ("LoadingShell") for shell-by-shell reload
# - Forward direction strictly along -Z

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

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3(-90.0, 0.0, 0.0)) -> MeshInstance3D:
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

static func create(mat_metal_override: Material = null, mat_wood_override: Material = null) -> Node3D:
	var root := Node3D.new()
	root.name = "ShotgunModel"
	
	var mat_steel: Material = mat_metal_override
	if not mat_steel:
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.14, 0.15, 0.17) # Matte parkerized shotgun steel
		ms.metallic = 0.86
		ms.roughness = 0.34
		mat_steel = ms
		
	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.08, 0.09, 0.10)
	mat_steel_dark.metallic = 0.80
	mat_steel_dark.roughness = 0.44
	
	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.80, 0.82, 0.86) # Mirror-machined steel bolt
	mat_bolt.metallic = 0.96
	mat_bolt.roughness = 0.16
	
	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.02, 0.02, 0.025)
	mat_bore.roughness = 0.95
	
	var mat_wood: Material = mat_wood_override
	if not mat_wood:
		var mw := StandardMaterial3D.new()
		mw.albedo_color = Color(0.40, 0.19, 0.08) # Rich American walnut
		mw.roughness = 0.50
		mw.metallic = 0.04
		mat_wood = mw
		
	var mat_wood_dark := StandardMaterial3D.new()
	mat_wood_dark.albedo_color = Color(0.28, 0.13, 0.05)
	mat_wood_dark.roughness = 0.62
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.07, 0.07, 0.08)
	mat_rubber.roughness = 0.88
	
	var mat_shell_red := StandardMaterial3D.new()
	mat_shell_red.albedo_color = Color(0.84, 0.11, 0.10)
	mat_shell_red.roughness = 0.36
	
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.24)
	mat_brass.metallic = 0.92
	mat_brass.roughness = 0.20
	
	var mat_bead := StandardMaterial3D.new()
	mat_bead.albedo_color = Color(1.0, 0.80, 0.22)
	mat_bead.emission_enabled = true
	mat_bead.emission = Color(1.0, 0.68, 0.12)
	mat_bead.emission_energy_multiplier = 0.8
	mat_bead.metallic = 0.85
	mat_bead.roughness = 0.18

	# ==========================================
	# 1. RECEIVER, EJECTION PORT, BOLT & LOADING GATE
	# ==========================================
	_add_box(root, "ReceiverMain", Vector3(0.054, 0.078, 0.265), Vector3(0, 0.002, 0.0), mat_steel)
	# Chamfered top crown of receiver
	_add_box(root, "ReceiverTop", Vector3(0.042, 0.012, 0.258), Vector3(0, 0.044, 0.0), mat_steel)
	# Receiver pins
	for pz in [-0.04, 0.045]:
		_add_cyl(root, "Pin", 0.004, 0.004, 0.057, Vector3(0, -0.018, pz), mat_steel_dark, 8, Vector3(0, 0, 90))
	
	# Deep recessed ejection port on right side
	_add_box(root, "EjectRecess", Vector3(0.012, 0.032, 0.105), Vector3(0.025, 0.018, -0.032), mat_bore)
	
	# Animated Chrome Steel Bolt ("Bolt")
	var bolt := _add_box(root, "Bolt", Vector3(0.014, 0.028, 0.092), Vector3(0.024, 0.018, -0.035), mat_bolt)
	_add_box(bolt, "ExtractorGroove", Vector3(0.004, 0.006, 0.045), Vector3(0.006, 0.004, -0.015), mat_steel_dark)
	
	# Bottom loading port recess & hinged steel carrier ("Elevator")
	_add_box(root, "LoadingPortRecess", Vector3(0.034, 0.010, 0.115), Vector3(0, -0.038, -0.030), mat_bore)
	_add_box(root, "Elevator", Vector3(0.030, 0.007, 0.102), Vector3(0, -0.035, -0.030), mat_bolt)
	
	# Trigger guard housing, loop, curved trigger & cross-bolt safety
	_add_box(root, "TriggerBase", Vector3(0.032, 0.014, 0.088), Vector3(0, -0.042, 0.068), mat_steel_dark)
	_add_box(root, "TriggerGuardLow", Vector3(0.016, 0.006, 0.062), Vector3(0, -0.072, 0.066), mat_steel_dark)
	_add_box(root, "TriggerGuardFront", Vector3(0.016, 0.032, 0.006), Vector3(0, -0.056, 0.036), mat_steel_dark)
	_add_box(root, "Trigger", Vector3(0.007, 0.024, 0.010), Vector3(0, -0.054, 0.070), mat_bolt, Vector3(-20.0, 0, 0))
	_add_cyl(root, "SafetyBtn", 0.005, 0.005, 0.038, Vector3(0, -0.044, 0.095), mat_shell_red, 8, Vector3(0, 0, 90))
	
	# Left-side tactical 4-shell side saddle carrier!
	_add_box(root, "SideSaddlePlate", Vector3(0.007, 0.052, 0.140), Vector3(-0.030, 0.004, -0.015), mat_steel_dark)
	for i in range(4):
		var sz: float = -0.064 + float(i) * 0.032
		var s_holder := Node3D.new()
		s_holder.position = Vector3(-0.042, 0.004, sz)
		root.add_child(s_holder)
		_add_cyl(s_holder, "SaddleHull", 0.0105, 0.0105, 0.044, Vector3(0, -0.004, 0), mat_shell_red, 10, Vector3.ZERO)
		_add_cyl(s_holder, "SaddleBrass", 0.0110, 0.0110, 0.014, Vector3(0, 0.022, 0), mat_brass, 10, Vector3.ZERO)
		_add_box(s_holder, "SaddleClip", Vector3(0.024, 0.018, 0.022), Vector3(0.004, 0.0, 0), mat_rubber)

	# ==========================================
	# 2. HEAVY 12G BARREL, VENTILATED RIB, BEAD & MAG TUBE
	# ==========================================
	_add_cyl(root, "Barrel", 0.0155, 0.0165, 0.52, Vector3(0, 0.026, -0.39), mat_steel, 16)
	_add_cyl(root, "BarrelBore", 0.012, 0.012, 0.012, Vector3(0, 0.026, -0.648), mat_bore, 12)
	# Ventilated sighting rib with individual vertical support posts
	_add_box(root, "VentRibTop", Vector3(0.012, 0.005, 0.49), Vector3(0, 0.049, -0.39), mat_steel_dark)
	for i in range(9):
		var rz: float = -0.17 - float(i) * 0.056
		_add_box(root, "RibPost_%d" % i, Vector3(0.008, 0.010, 0.014), Vector3(0, 0.043, rz), mat_steel_dark)
	# Glowing brass / tritium front bead sight
	var bead := MeshInstance3D.new()
	bead.name = "FrontBead"
	var bm_s := SphereMesh.new()
	bm_s.radius = 0.0042
	bm_s.height = 0.0084
	bead.mesh = bm_s
	bead.material_override = mat_bead
	bead.position = Vector3(0, 0.055, -0.625)
	root.add_child(bead)
	
	# Underbarrel tubular magazine + knurled steel end cap + barrel clamp
	_add_cyl(root, "MagTube", 0.0135, 0.0135, 0.46, Vector3(0, -0.012, -0.36), mat_steel_dark, 14)
	_add_cyl(root, "MagCap", 0.016, 0.016, 0.032, Vector3(0, -0.012, -0.595), mat_steel, 12)
	_add_box(root, "BarrelClamp", Vector3(0.034, 0.058, 0.022), Vector3(0, 0.007, -0.545), mat_steel_dark)
	_add_cyl(root, "FrontSlingStud", 0.006, 0.006, 0.010, Vector3(0, -0.030, -0.595), mat_steel_dark, 8, Vector3.ZERO)

	# ==========================================
	# 3. CORNCOB-RIBBED WALNUT PUMP FOREND ("Pump") + ACTION BARS
	# ==========================================
	var pump := MeshInstance3D.new()
	pump.name = "Pump"
	var pm := CylinderMesh.new()
	pm.top_radius = 0.027
	pm.bottom_radius = 0.028
	pm.height = 0.175
	pm.radial_segments = 14
	pump.mesh = pm
	pump.material_override = mat_wood
	pump.position = Vector3(0, -0.012, -0.32)
	pump.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(pump)
	
	# Corncob grip grooves along forend (in pump's local Y axis since rotated -90 deg X!)
	for gy in [-0.062, -0.038, -0.014, 0.010, 0.034, 0.058]:
		_add_cyl(pump, "CorncobGroove", 0.0292, 0.0292, 0.009, Vector3(0, gy, 0), mat_wood_dark, 14, Vector3.ZERO)
	# Twin steel action slide bars connecting pump back into receiver
	for ax in [-0.021, 0.021]:
		_add_box(pump, "ActionBar", Vector3(0.004, 0.185, 0.009), Vector3(ax, -0.145, 0.008), mat_bolt)

	# ==========================================
	# 4. CONTOURED WALNUT STOCK & RIBBED RUBBER BUTTPAD
	# ==========================================
	var stock_root := Node3D.new()
	stock_root.name = "Stock"
	stock_root.position = Vector3(0, -0.006, 0.132)
	root.add_child(stock_root)
	# Curved pistol-grip stock wrist
	_add_box(stock_root, "StockWrist", Vector3(0.044, 0.060, 0.088), Vector3(0, -0.022, 0.036), mat_wood, Vector3(24.0, 0, 0))
	# Main walnut buttstock body
	_add_box(stock_root, "StockBody", Vector3(0.048, 0.114, 0.225), Vector3(0, -0.056, 0.175), mat_wood, Vector3(9.0, 0, 0))
	_add_box(stock_root, "StockComb", Vector3(0.040, 0.024, 0.205), Vector3(0, 0.002, 0.175), mat_wood_dark, Vector3(9.0, 0, 0))
	# White spacer line + thick ventilated rubber recoil buttpad
	_add_box(stock_root, "ButtSpacer", Vector3(0.049, 0.118, 0.006), Vector3(0, -0.072, 0.289), mat_bolt, Vector3(9.0, 0, 0))
	_add_box(stock_root, "RecoilPad", Vector3(0.051, 0.122, 0.032), Vector3(0, -0.075, 0.308), mat_rubber, Vector3(9.0, 0, 0))

	# ==========================================
	# 5. ANIMATED 12G LOADING SHELL ("LoadingShell")
	# ==========================================
	var loading_shell := Node3D.new()
	loading_shell.name = "LoadingShell"
	loading_shell.position = Vector3(0, -0.14, -0.08)
	loading_shell.visible = false
	root.add_child(loading_shell)
	_add_cyl(loading_shell, "ShellHull", 0.011, 0.011, 0.048, Vector3(0, 0, -0.008), mat_shell_red, 10)
	_add_cyl(loading_shell, "ShellBrass", 0.0115, 0.0115, 0.016, Vector3(0, 0, 0.022), mat_brass, 10)

	# ==========================================
	# 6. MARKERS (MUZZLE & EJECTION PORT)
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.026, -0.665)
	root.add_child(muzzle)
	
	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.042, 0.022, -0.030)
	root.add_child(eject)

	return root
