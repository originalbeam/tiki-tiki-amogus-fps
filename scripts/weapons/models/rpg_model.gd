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
	# 4. PGO-7 SIDE OPTICAL SIGHT (LEFT SIDE, PiP MAGNIFYING SCOPE)
	# ==========================================
	var optic_node := Node3D.new()
	optic_node.name = "PGO7_Optic"
	root.add_child(optic_node)
	
	# Side dovetail mounting plate & quick-release clamp lever on left of barrel
	_add_box(optic_node, "SideRail", Vector3(0.012, 0.024, 0.082), Vector3(-0.029, 0.004, -0.155), mat_steel_dark)
	_add_box(optic_node, "ClampLever", Vector3(0.008, 0.010, 0.032), Vector3(-0.038, -0.002, -0.140), mat_steel_dark)
	# Angled support arm stepping out and up to left
	var arm := _add_box(optic_node, "OpticArm", Vector3(0.014, 0.066, 0.028), Vector3(-0.045, 0.032, -0.155), mat_optic_body)
	arm.rotation.z = deg_to_rad(28.0)
	# Main PGO-7 optical prism housing
	_add_box(optic_node, "OpticHousing", Vector3(0.036, 0.052, 0.068), Vector3(-0.062, 0.064, -0.155), mat_optic_body)
	# Elevation & windage adjustment turrets + illumination battery cap
	var elev_t := MeshInstance3D.new()
	var elev_cm := CylinderMesh.new()
	elev_cm.top_radius = 0.0085
	elev_cm.bottom_radius = 0.0085
	elev_cm.height = 0.014
	elev_cm.radial_segments = 12
	elev_t.mesh = elev_cm
	elev_t.material_override = mat_steel_dark
	elev_t.position = Vector3(-0.062, 0.095, -0.155)
	optic_node.add_child(elev_t)
	
	var batt := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.009
	bm.bottom_radius = 0.009
	bm.height = 0.018
	bm.radial_segments = 10
	batt.mesh = bm
	batt.material_override = mat_steel_dark
	batt.rotation.z = deg_to_rad(90.0)
	batt.position = Vector3(-0.085, 0.060, -0.155)
	optic_node.add_child(batt)
	
	# Front objective tube, flared bell & emerald-coated objective lens (-Z)
	_add_cyl(optic_node, "OpticFrontTube", 0.016, 0.015, 0.042, Vector3(-0.062, 0.064, -0.205), mat_optic_body, 16)
	_add_cyl(optic_node, "OpticFrontBell", 0.020, 0.016, 0.028, Vector3(-0.062, 0.064, -0.236), mat_optic_body, 16)
	_add_cyl(optic_node, "OpticFrontLens", 0.0175, 0.0175, 0.003, Vector3(-0.062, 0.064, -0.250), mat_lens, 16)
	
	# Rear ocular eyepiece bell & ribbed rubber focus collar (+Z, analogous to AK-47 LPVO)
	_add_cyl(optic_node, "OpticOcularBell", 0.0155, 0.022, 0.046, Vector3(-0.062, 0.064, -0.119), mat_optic_body, 20)
	_add_cyl(optic_node, "OpticFocusRing", 0.0225, 0.0225, 0.012, Vector3(-0.062, 0.064, -0.103), mat_rubber, 18)
	
	# Real circular see-through ocular glass lens facing player (+Z) with PiP magnification + PGO-7 ballistic reticle
	var ocular_lens := MeshInstance3D.new()
	ocular_lens.name = "OpticLens"
	var olm := QuadMesh.new()
	olm.size = Vector2(0.043, 0.043)
	ocular_lens.mesh = olm
	ocular_lens.material_override = _create_pgo7_lens_material()
	ocular_lens.position = Vector3(-0.062, 0.064, -0.095)
	optic_node.add_child(ocular_lens)
	
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

# Creates the iconic PG-7V / PG-7VR Tandem / TBG-7V Thermobaric rocket warhead (forward along -Z).
# Set include_fins = true for the launched flying rocket projectile!
static func create_warhead(include_fins: bool = false, warhead_type: String = "standard") -> Node3D:
	return create_warhead_by_type(warhead_type, include_fins)

static func create_warhead_by_type(warhead_type: String = "standard", include_fins: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "PG7V_Warhead"
	
	var mat_green := StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.24, 0.31, 0.19) # Soviet military olive drab
	mat_green.metallic = 0.25
	mat_green.roughness = 0.46

	var mat_dark_olive := StandardMaterial3D.new()
	mat_dark_olive.albedo_color = Color(0.14, 0.19, 0.13) # Deep armored tandem olive
	mat_dark_olive.metallic = 0.36
	mat_dark_olive.roughness = 0.40

	var mat_charcoal := StandardMaterial3D.new()
	mat_charcoal.albedo_color = Color(0.16, 0.17, 0.16) # Thermobaric TBG-7V dark canister
	mat_charcoal.metallic = 0.32
	mat_charcoal.roughness = 0.48
	
	var mat_yellow := StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.84, 0.68, 0.18) # High-explosive identification stripe
	mat_yellow.roughness = 0.45

	var mat_crimson := StandardMaterial3D.new()
	mat_crimson.albedo_color = Color(0.84, 0.14, 0.10) # AP Tandem / Thermobaric hazard band
	mat_crimson.roughness = 0.38

	var mat_orange := StandardMaterial3D.new()
	mat_orange.albedo_color = Color(0.96, 0.44, 0.08) # Thermobaric fuel-air flame stripe
	mat_orange.roughness = 0.38
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.16, 0.17, 0.19)
	mat_steel.metallic = 0.85
	mat_steel.roughness = 0.32
	
	var mat_aluminum := StandardMaterial3D.new()
	mat_aluminum.albedo_color = Color(0.74, 0.76, 0.78)
	mat_aluminum.metallic = 0.92
	mat_aluminum.roughness = 0.22
	
	# Extended propellant booster stem / neck seated into launch tube
	_add_cyl(root, "BoosterNeck", 0.019, 0.019, 0.32, Vector3(0, 0, 0.10), mat_steel, 12)
	_add_cyl(root, "PropellantSleeve", 0.0215, 0.0215, 0.20, Vector3(0, 0, 0.21), mat_green, 12)

	if warhead_type == "tandem":
		# PG-7VR "Resume" 105mm/64mm DOUBLE-STAGE TANDEM HEAT WARHEAD!
		_add_cyl(root, "MainRearCone", 0.056, 0.020, 0.082, Vector3(0, 0, -0.098), mat_dark_olive, 16)
		_add_cyl(root, "Main105Body", 0.056, 0.056, 0.095, Vector3(0, 0, -0.186), mat_dark_olive, 16)
		_add_cyl(root, "APBandRed", 0.0568, 0.0568, 0.014, Vector3(0, 0, -0.162), mat_crimson, 16)
		_add_cyl(root, "APBandGold", 0.0568, 0.0568, 0.010, Vector3(0, 0, -0.206), mat_yellow, 16)
		_add_cyl(root, "MainFrontCone", 0.022, 0.056, 0.092, Vector3(0, 0, -0.278), mat_dark_olive, 16)
		# Extended standoff boom connecting main 105mm charge to forward 64mm precursor warhead!
		_add_cyl(root, "StandoffShaft", 0.016, 0.022, 0.095, Vector3(0, 0, -0.365), mat_steel, 14)
		_add_cyl(root, "PrecursorRear", 0.035, 0.016, 0.044, Vector3(0, 0, -0.428), mat_dark_olive, 14)
		_add_cyl(root, "Precursor64Body", 0.035, 0.035, 0.052, Vector3(0, 0, -0.474), mat_dark_olive, 14)
		_add_cyl(root, "PrecursorBand", 0.0358, 0.0358, 0.011, Vector3(0, 0, -0.474), mat_crimson, 14)
		_add_cyl(root, "PrecursorNose", 0.010, 0.035, 0.068, Vector3(0, 0, -0.534), mat_aluminum, 14)
	elif warhead_type == "thermobaric":
		# TBG-7V "Tanin" 105mm BLUNT CYLINDRICAL THERMOBARIC FUEL-AIR CANISTER!
		_add_cyl(root, "ThermoRearTaper", 0.056, 0.020, 0.068, Vector3(0, 0, -0.092), mat_charcoal, 18)
		_add_cyl(root, "ThermoCanister", 0.056, 0.056, 0.255, Vector3(0, 0, -0.252), mat_charcoal, 18)
		# Bold dual bright-orange & crimson fuel-air hazard rings around blunt canister!
		_add_cyl(root, "ThermoBand1", 0.057, 0.057, 0.024, Vector3(0, 0, -0.185), mat_orange, 18)
		_add_cyl(root, "ThermoBand2", 0.057, 0.057, 0.016, Vector3(0, 0, -0.220), mat_crimson, 18)
		_add_cyl(root, "ThermoBand3", 0.057, 0.057, 0.020, Vector3(0, 0, -0.325), mat_orange, 18)
		# Iconic rounded blunt cap & recessed impact nose cap (NO pointy cone!)
		_add_cyl(root, "BluntShoulder", 0.044, 0.056, 0.024, Vector3(0, 0, -0.391), mat_steel, 18)
		_add_cyl(root, "BluntNoseCap", 0.032, 0.044, 0.018, Vector3(0, 0, -0.412), mat_crimson, 16)
		_add_cyl(root, "ImpactButton", 0.016, 0.018, 0.012, Vector3(0, 0, -0.425), mat_aluminum, 12)
	else:
		# Classic PG-7V 85mm HEAT Warhead
		_add_cyl(root, "WarheadRearCone", 0.047, 0.020, 0.088, Vector3(0, 0, -0.102), mat_green, 14)
		_add_cyl(root, "WarheadBody", 0.047, 0.047, 0.048, Vector3(0, 0, -0.168), mat_green, 14)
		_add_cyl(root, "YellowBand", 0.0478, 0.0478, 0.012, Vector3(0, 0, -0.168), mat_yellow, 14)
		_add_cyl(root, "WarheadFrontCone", 0.016, 0.047, 0.116, Vector3(0, 0, -0.248), mat_green, 14)
		_add_cyl(root, "FuzeCollar", 0.015, 0.016, 0.022, Vector3(0, 0, -0.316), mat_steel, 10)
		_add_cyl(root, "FuzeProbe", 0.010, 0.014, 0.050, Vector3(0, 0, -0.350), mat_aluminum, 10)
		_add_cyl(root, "FuzeTip", 0.008, 0.010, 0.012, Vector3(0, 0, -0.380), mat_steel, 10)
	
	if include_fins:
		# Extra-long 2x PG-7V propellant rocket motor shaft, booster charge casing & rear stabilizer boom
		_add_cyl(root, "TailBoom", 0.016, 0.014, 0.88, Vector3(0, 0, 0.46), mat_steel, 12)
		_add_cyl(root, "PropellantCharge", 0.021, 0.021, 0.48, Vector3(0, 0, 0.42), mat_green, 12)
		_add_cyl(root, "BoosterCollar", 0.0225, 0.0225, 0.024, Vector3(0, 0, 0.68), mat_steel, 12)
		_add_cyl(root, "MotorNozzle", 0.015, 0.022, 0.048, Vector3(0, 0, 0.91), mat_steel, 12)
		
		# 4 deployed folding tail stabilizer fins near rear of extended 2x propellant tube
		for i in range(4):
			var angle: float = i * (PI * 0.5) + (PI * 0.25)
			var fin_pivot := Node3D.new()
			fin_pivot.rotation.z = angle
			fin_pivot.position = Vector3(0, 0, 0.85)
			root.add_child(fin_pivot)
			
			var fin := _add_box(fin_pivot, "Fin_%d" % i, Vector3(0.003, 0.072, 0.048), Vector3(0, 0.044, 0), mat_aluminum)
			fin.rotation.x = deg_to_rad(-18.0)
	
	return root

static func _create_pgo7_lens_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;
uniform vec4 reticle_color : source_color = vec4(1.0, 0.24, 0.08, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.495) {
		discard;
	}
	if (r > 0.445) {
		// Thick black rubber ocular rim
		ALBEDO = vec3(0.035, 0.038, 0.042);
		ALPHA = 1.0;
	} else {
		// Authentic Soviet PGO-7 ballistic reticle:
		// Main horizontal windage line + vertical centerline
		float h_main = step(abs(p.y), 0.0024) * step(abs(p.x), 0.36);
		float v_main = step(abs(p.x), 0.0024) * step(-0.14, p.y) * step(p.y, 0.34);
		// Windage lead ticks along horizontal line
		float h_ticks = step(abs(p.y), 0.012) * step(0.045, abs(p.x)) * step(abs(p.x), 0.34)
			* step(abs(fract(abs(p.x) * 18.0 + 0.5) - 0.5), 0.065);
		// Ballistic drop stadia bars below center (200m, 300m, 400m, 500m)
		float bar2 = step(abs(p.y - 0.075), 0.0024) * step(abs(p.x), 0.14);
		float bar3 = step(abs(p.y - 0.145), 0.0024) * step(abs(p.x), 0.105);
		float bar4 = step(abs(p.y - 0.215), 0.0024) * step(abs(p.x), 0.075);
		float bar5 = step(abs(p.y - 0.285), 0.0024) * step(abs(p.x), 0.050);
		// Lower-right stadia rangefinder baseline & curve (2.7m tank height scale)
		float rf_base = step(abs(p.y - 0.26), 0.0022) * step(0.11, p.x) * step(p.x, 0.34);
		float curve_y = 0.26 - 0.022 / max(p.x - 0.02, 0.08);
		float rf_curve = step(abs(p.y - curve_y), 0.0025) * step(0.11, p.x) * step(p.x, 0.34);
		float black_ret = clamp(h_main + v_main + h_ticks + bar2 + bar3 + bar4 + bar5 + rf_base + rf_curve, 0.0, 1.0);
		
		// Illuminated central aiming cross & dot
		float center_dot = 1.0 - smoothstep(0.007, 0.012, r);
		float center_cross = (step(abs(p.y), 0.0032) * step(abs(p.x), 0.032) + step(abs(p.x), 0.0032) * step(abs(p.y), 0.032));
		float illum_ret = clamp(center_dot + center_cross * 0.85, 0.0, 1.0);
		float vig = smoothstep(0.365, 0.445, r);
		
		if (use_pip) {
			vec2 pip_uv = clamp(UV, vec2(0.01), vec2(0.99));
			vec3 world_col = texture(pip_tex, pip_uv).rgb;
			vec3 col = mix(world_col, vec3(0.02, 0.022, 0.025), black_ret * 0.90);
			col = mix(col, reticle_color.rgb * 1.45, illum_ret);
			col = mix(col, vec3(0.01, 0.012, 0.015), vig * 0.88);
			ALBEDO = col;
			ALPHA = 1.0;
		} else {
			float sheen = smoothstep(0.45, 0.0, length(p - vec2(-0.14, -0.14))) * 0.34;
			vec3 glass = vec3(0.06, 0.25, 0.20) + vec3(0.18, 0.34, 0.26) * sheen;
			glass = mix(glass, vec3(0.02, 0.022, 0.025), black_ret * 0.55);
			glass = mix(glass, reticle_color.rgb * 0.9, illum_ret * 0.7);
			glass = mix(glass, vec3(0.015, 0.02, 0.025), vig * 0.9);
			ALBEDO = glass;
			ALPHA = 0.92;
		}
	}
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat

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
