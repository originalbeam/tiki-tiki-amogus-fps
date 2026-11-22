class_name RPGModel
extends RefCounted

# RPG-7V (РПГ-7В) Rocket-Propelled Grenade Launcher Model
# High-fidelity procedural 3D model matching first-person weapon & Handbook 3D Inspector:
# - Parkerized steel launch tube with muzzle collar & dark bore recess
# - Iconic wooden shoulder heat shield with 3 steel clamping bands
# - Bulging mid-rear expansion chamber & flared Venturi rear exhaust nozzle
# - Front trigger housing, bakelite pistol grip, trigger guard, trigger & hammer spur
# - Rear bakelite support grip
# - Folding front & rear ladder iron sights
# - Side-mounted PGO-7 optical sight with dovetail bracket, coated green lens & rubber eyecup
# - Detachable/animatable PG-7V warhead node ("Warhead") for reload & rocket projectile reuse
# - Forward direction is strictly along -Z (matching AK47Model, ShotgunModel, PistolModel)

static func create(with_warhead: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "RPG7Model"
	
	# Materials
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.15, 0.16, 0.17)
	mat_steel.metallic = 0.86
	mat_steel.roughness = 0.34
	
	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.08, 0.09, 0.10)
	mat_steel_dark.metallic = 0.78
	mat_steel_dark.roughness = 0.45
	
	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.02, 0.02, 0.025)
	mat_bore.roughness = 0.95
	
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.46, 0.22, 0.09)
	mat_wood.roughness = 0.56
	mat_wood.metallic = 0.04
	
	var mat_bakelite := StandardMaterial3D.new()
	mat_bakelite.albedo_color = Color(0.32, 0.14, 0.07)
	mat_bakelite.roughness = 0.42
	mat_bakelite.metallic = 0.05
	
	var mat_optic_body := StandardMaterial3D.new()
	mat_optic_body.albedo_color = Color(0.22, 0.25, 0.23) # Classic Soviet hammer-tone grey-green
	mat_optic_body.metallic = 0.65
	mat_optic_body.roughness = 0.40
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.06, 0.06, 0.07)
	mat_rubber.roughness = 0.90
	
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.12, 0.42, 0.32, 0.9)
	mat_lens.metallic = 0.6
	mat_lens.roughness = 0.08
	mat_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# ==========================================
	# 1. LAUNCH TUBE, WOOD HEAT SHIELD & VENTURI NOZZLE
	# (rotation.x = -90 deg => top_radius = Front -Z, bottom_radius = Rear +Z)
	# ==========================================
	# Front steel barrel tube (-0.45 to -0.11)
	_add_cyl(root, "FrontTube", 0.025, 0.025, 0.34, Vector3(0, 0, -0.28), mat_steel)
	
	# Reinforced muzzle collar ring
	_add_cyl(root, "MuzzleCollar", 0.031, 0.031, 0.026, Vector3(0, 0, -0.445), mat_steel_dark)
	_add_cyl(root, "MuzzleBore", 0.021, 0.021, 0.012, Vector3(0, 0, -0.454), mat_bore)
	
	# Iconic wooden shoulder heat shield (-0.12 to +0.22)
	_add_cyl(root, "WoodHeatShield", 0.034, 0.034, 0.34, Vector3(0, 0, 0.05), mat_wood, 12)
	
	# Three steel clamping bands around wooden heat shield
	for bz in [-0.105, 0.05, 0.205]:
		_add_cyl(root, "HeatShieldBand", 0.0365, 0.0365, 0.016, Vector3(0, 0, bz), mat_steel_dark, 12)
	
	# Swollen mid-rear expansion chamber (+0.22 to +0.37)
	_add_cyl(root, "ChamberFrontTaper", 0.030, 0.039, 0.055, Vector3(0, 0, 0.245), mat_steel, 12)
	_add_cyl(root, "ChamberBody", 0.039, 0.039, 0.050, Vector3(0, 0, 0.295), mat_steel, 12)
	_add_cyl(root, "ChamberRearTaper", 0.039, 0.024, 0.055, Vector3(0, 0, 0.345), mat_steel, 12)
	
	# Flared Venturi exhaust cone (+0.37 to +0.50)
	_add_cyl(root, "ExhaustNozzle", 0.024, 0.046, 0.130, Vector3(0, 0, 0.435), mat_steel, 14)
	_add_cyl(root, "NozzleRim", 0.048, 0.048, 0.014, Vector3(0, 0, 0.498), mat_steel_dark, 14)
	_add_cyl(root, "NozzleBore", 0.040, 0.040, 0.010, Vector3(0, 0, 0.502), mat_bore, 14)
	
	# ==========================================
	# 2. TRIGGER GROUP, FRONT PISTOL GRIP & REAR SUPPORT GRIP
	# ==========================================
	# Trigger mechanism housing block under front barrel
	_add_box(root, "TriggerHousing", Vector3(0.034, 0.042, 0.125), Vector3(0, -0.040, -0.225), mat_steel)
	
	# Front bakelite pistol grip
	var f_grip := _add_box(root, "FrontGrip", Vector3(0.032, 0.115, 0.048), Vector3(0, -0.095, -0.205), mat_bakelite)
	f_grip.rotation.x = deg_to_rad(-18.0)
	var f_grip_cap := _add_box(root, "FrontGripCap", Vector3(0.035, 0.012, 0.052), Vector3(0, -0.150, -0.188), mat_steel_dark)
	f_grip_cap.rotation.x = deg_to_rad(-18.0)
	
	# Trigger guard & trigger
	_add_box(root, "TriggerGuardBottom", Vector3(0.014, 0.008, 0.062), Vector3(0, -0.088, -0.258), mat_steel)
	_add_box(root, "TriggerGuardFront", Vector3(0.014, 0.034, 0.008), Vector3(0, -0.072, -0.286), mat_steel)
	var trig := _add_box(root, "Trigger", Vector3(0.008, 0.026, 0.011), Vector3(0, -0.068, -0.254), mat_steel_dark)
	trig.rotation.x = deg_to_rad(-20.0)
	
	# Cocking hammer spur behind grip
	var hammer := _add_box(root, "HammerSpur", Vector3(0.012, 0.024, 0.022), Vector3(0, -0.052, -0.162), mat_steel_dark)
	hammer.rotation.x = deg_to_rad(25.0)
	
	# Rear support grip under wood heat shield
	_add_box(root, "RearGripMount", Vector3(0.030, 0.026, 0.052), Vector3(0, -0.042, 0.02), mat_steel_dark)
	var r_grip := _add_box(root, "RearGrip", Vector3(0.030, 0.105, 0.042), Vector3(0, -0.095, 0.032), mat_bakelite)
	r_grip.rotation.x = deg_to_rad(-14.0)
	
	# ==========================================
	# 3. IRON SIGHTS (FOLDING FRONT & REAR LADDER)
	# ==========================================
	# Front sight base & protective ears
	_add_box(root, "FrontSightBase", Vector3(0.022, 0.024, 0.032), Vector3(0, 0.034, -0.405), mat_steel)
	_add_box(root, "FrontSightEarL", Vector3(0.005, 0.042, 0.016), Vector3(-0.010, 0.062, -0.405), mat_steel)
	_add_box(root, "FrontSightEarR", Vector3(0.005, 0.042, 0.016), Vector3(0.010, 0.062, -0.405), mat_steel)
	_add_box(root, "FrontSightPost", Vector3(0.004, 0.034, 0.004), Vector3(0, 0.058, -0.405), mat_steel_dark)
	
	# Rear folding ladder sight
	_add_box(root, "RearSightBase", Vector3(0.024, 0.022, 0.034), Vector3(0, 0.034, -0.155), mat_steel)
	_add_box(root, "RearSightFrameL", Vector3(0.005, 0.048, 0.008), Vector3(-0.011, 0.065, -0.155), mat_steel)
	_add_box(root, "RearSightFrameR", Vector3(0.005, 0.048, 0.008), Vector3(0.011, 0.065, -0.155), mat_steel)
	_add_box(root, "RearSightTopBar", Vector3(0.027, 0.006, 0.008), Vector3(0, 0.088, -0.155), mat_steel)
	_add_box(root, "RearSightSlider", Vector3(0.024, 0.007, 0.010), Vector3(0, 0.064, -0.155), mat_steel_dark)
	
	# ==========================================
	# 4. PGO-7 SIDE OPTICAL SIGHT (LEFT SIDE)
	# ==========================================
	var optic_node := Node3D.new()
	optic_node.name = "PGO7_Optic"
	root.add_child(optic_node)
	
	# Side dovetail mounting plate on left of barrel
	_add_box(optic_node, "SideRail", Vector3(0.012, 0.024, 0.075), Vector3(-0.029, 0.004, -0.155), mat_steel_dark)
	# Angled support arm stepping out and up to left
	var arm := _add_box(optic_node, "OpticArm", Vector3(0.014, 0.062, 0.026), Vector3(-0.045, 0.030, -0.155), mat_optic_body)
	arm.rotation.z = deg_to_rad(28.0)
	# Main vertical/angled PGO-7 prism housing
	_add_box(optic_node, "OpticHousing", Vector3(0.034, 0.056, 0.062), Vector3(-0.062, 0.058, -0.155), mat_optic_body)
	# Front objective tube & coated green lens
	_add_cyl(optic_node, "OpticFrontTube", 0.017, 0.015, 0.045, Vector3(-0.062, 0.072, -0.195), mat_optic_body, 10)
	_add_cyl(optic_node, "OpticFrontLens", 0.014, 0.014, 0.004, Vector3(-0.062, 0.072, -0.216), mat_lens, 10)
	# Rear ocular eyepiece & rubber eyecup
	_add_cyl(optic_node, "OpticRearTube", 0.015, 0.017, 0.036, Vector3(-0.062, 0.052, -0.118), mat_optic_body, 10)
	_add_cyl(optic_node, "OpticEyecup", 0.016, 0.021, 0.038, Vector3(-0.062, 0.052, -0.084), mat_rubber, 10)
	# Battery/illumination cap on left side of optic
	var batt := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.009
	bm.bottom_radius = 0.009
	bm.height = 0.018
	bm.radial_segments = 8
	batt.mesh = bm
	batt.material_override = mat_steel_dark
	batt.rotation.z = deg_to_rad(90.0)
	batt.position = Vector3(-0.084, 0.046, -0.155)
	optic_node.add_child(batt)
	
	# ==========================================
	# 5. PG-7V ROCKET WARHEAD (LOADABLE / DETACHABLE)
	# ==========================================
	var warhead := create_warhead(false)
	warhead.name = "Warhead"
	warhead.position = Vector3(0, 0, -0.45)
	warhead.visible = with_warhead
	root.add_child(warhead)
	
	# ==========================================
	# 6. MARKERS (MUZZLE & BACKBLAST)
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0, -0.84)
	root.add_child(muzzle)
	
	var backblast := Marker3D.new()
	backblast.name = "BackblastMarker"
	backblast.position = Vector3(0, 0, 0.54)
	root.add_child(backblast)
	
	return root

# Creates the iconic PG-7V rocket warhead (forward along -Z).
# Set include_fins = true for the launched flying rocket projectile!
static func create_warhead(include_fins: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "PG7V_Warhead"
	
	var mat_green := StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.24, 0.31, 0.19) # Soviet military olive drab
	mat_green.metallic = 0.25
	mat_green.roughness = 0.46
	
	var mat_yellow := StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.82, 0.68, 0.18) # High-explosive identification stripe
	mat_yellow.roughness = 0.45
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.16, 0.17, 0.19)
	mat_steel.metallic = 0.85
	mat_steel.roughness = 0.32
	
	var mat_aluminum := StandardMaterial3D.new()
	mat_aluminum.albedo_color = Color(0.74, 0.76, 0.78)
	mat_aluminum.metallic = 0.92
	mat_aluminum.roughness = 0.22
	
	# Booster stem / neck seated into launch tube
	_add_cyl(root, "BoosterNeck", 0.020, 0.020, 0.08, Vector3(0, 0, -0.02), mat_steel, 12)
	
	# Rear expanding cone of PG-7V warhead
	_add_cyl(root, "WarheadRearCone", 0.047, 0.020, 0.088, Vector3(0, 0, -0.102), mat_green, 14)
	
	# Main wide warhead cylinder
	_add_cyl(root, "WarheadBody", 0.047, 0.047, 0.048, Vector3(0, 0, -0.168), mat_green, 14)
	
	# Yellow ordnance stripe around warhead body
	_add_cyl(root, "YellowBand", 0.0478, 0.0478, 0.012, Vector3(0, 0, -0.168), mat_yellow, 14)
	
	# Forward tapered ogive nose cone
	_add_cyl(root, "WarheadFrontCone", 0.016, 0.047, 0.116, Vector3(0, 0, -0.248), mat_green, 14)
	
	# Piezoelectric fuze collar & silver VP-7 nose probe
	_add_cyl(root, "FuzeCollar", 0.015, 0.016, 0.022, Vector3(0, 0, -0.316), mat_steel, 10)
	_add_cyl(root, "FuzeProbe", 0.010, 0.014, 0.050, Vector3(0, 0, -0.350), mat_aluminum, 10)
	_add_cyl(root, "FuzeTip", 0.008, 0.010, 0.012, Vector3(0, 0, -0.380), mat_steel, 10)
	
	if include_fins:
		# Sustainer rocket motor shaft & rear stabilizer boom
		_add_cyl(root, "TailBoom", 0.015, 0.013, 0.24, Vector3(0, 0, 0.13), mat_steel, 10)
		_add_cyl(root, "MotorNozzle", 0.014, 0.019, 0.032, Vector3(0, 0, 0.255), mat_steel, 10)
		
		# 4 deployed folding tail stabilizer fins
		for i in range(4):
			var angle: float = i * (PI * 0.5) + (PI * 0.25)
			var fin_pivot := Node3D.new()
			fin_pivot.rotation.z = angle
			fin_pivot.position = Vector3(0, 0, 0.215)
			root.add_child(fin_pivot)
			
			var fin := _add_box(fin_pivot, "Fin_%d" % i, Vector3(0.003, 0.068, 0.042), Vector3(0, 0.042, 0), mat_aluminum)
			fin.rotation.x = deg_to_rad(-18.0)
	
	return root

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	# Rotate -90 on X so top_radius points along -Z (forward) and bottom_radius along +Z (rear)
	mi.rotation.x = deg_to_rad(-90.0)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_box(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
