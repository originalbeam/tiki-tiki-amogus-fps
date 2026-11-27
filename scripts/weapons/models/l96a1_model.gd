class_name L96A1Model
extends RefCounted

# Museum-Grade Accuracy International L96A1 / AWM Sniper Rifle (.338 Lapua Magnum)
# Forward along -Z:
# - Procedural micro-stippled British Olive-Drab AI thumbhole polymer chassis with recessed hex bolts,
#   side vent slots showing aluminum core rail, adjustable cheek rest on steel posts, stacked buttpad spacers
# - Heavy free-floating fluted match barrel, hollow dual-baffle AI muzzle brake & folded spigot bipod
# - Flat-bottomed AI receiver with machined 20-MOA Picatinny rail, scalloped ejection port & fluted bolt
# - Detachable steel .338 Lapua box magazine ("Magazine") with visible top cartridge
# - Schmidt & Bender PM II style 3x-8x PiP tactical scope ("SniperScope/OpticLens") centered cleanly
#   at weapon-local (0.0, +0.082, +0.112) for 100% dead-center ADS alignment!

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

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 16, rot_deg: Vector3 = Vector3(-90.0, 0.0, 0.0)) -> MeshInstance3D:
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

static func _add_sphere(parent: Node3D, node_name: String, r: float, pos: Vector3, mat: Material, scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)
	return mi

static func _create_od_polymer_material(dark_shift: float = 0.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 od_base : source_color = vec3(0.22, 0.285, 0.175);
uniform vec3 od_dark : source_color = vec3(0.145, 0.19, 0.115);
uniform float darken : hint_range(0.0, 0.4) = 0.0;

varying vec3 v_local;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	// Micro-stippled glass-filled British Olive-Drab tactical polymer texture
	float stipple = hash31(floor(v_local * 360.0));
	float macro_var = hash31(floor(v_local * 45.0));
	vec3 col = mix(od_dark, od_base, 0.55 + stipple * 0.30 + macro_var * 0.15);
	col *= (1.0 - darken);
	ALBEDO = col;
	ROUGHNESS = clamp(0.56 + (1.0 - stipple) * 0.14, 0.48, 0.76);
	METALLIC = 0.04;
	SPECULAR = 0.42;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("darken", dark_shift)
	return sm

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "L96A1Model"

	# ==========================================
	# PBR & PROCEDURAL SHADER PALETTE
	# ==========================================
	var mat_od := _create_od_polymer_material(0.0)
	var mat_od_dark := _create_od_polymer_material(0.18)

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.105, 0.115, 0.125) # Matte parkerized sniper steel
	mat_steel.metallic = 0.88
	mat_steel.roughness = 0.32

	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.065, 0.072, 0.080) # Deep anodized aluminum / rail / flutes
	mat_steel_dark.metallic = 0.84
	mat_steel_dark.roughness = 0.40

	var mat_scope_body := StandardMaterial3D.new()
	mat_scope_body.albedo_color = Color(0.09, 0.095, 0.105) # Schmidt & Bender matte anodized housing
	mat_scope_body.metallic = 0.82
	mat_scope_body.roughness = 0.28

	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.80, 0.82, 0.86) # Precision stainless steel bolt
	mat_bolt.metallic = 0.96
	mat_bolt.roughness = 0.16

	var mat_hardware := StandardMaterial3D.new()
	mat_hardware.albedo_color = Color(0.46, 0.49, 0.52) # Hex screws, cheek posts, markings
	mat_hardware.metallic = 0.90
	mat_hardware.roughness = 0.26

	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.055, 0.06, 0.065) # Cheekpiece, recoil pad, bipod feet, bolt knob
	mat_rubber.roughness = 0.88

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.016, 0.018, 0.022)
	mat_bore.roughness = 0.95

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.26)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.84, 0.44, 0.19)
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var mat_white_tick := StandardMaterial3D.new()
	mat_white_tick.albedo_color = Color(0.90, 0.90, 0.86)
	mat_white_tick.roughness = 0.45

	var mat_obj_lens := StandardMaterial3D.new()
	mat_obj_lens.albedo_color = Color(0.05, 0.28, 0.26) # Multi-coated emerald/cyan objective glass
	mat_obj_lens.metallic = 0.92
	mat_obj_lens.roughness = 0.04

	# ==========================================
	# 1. ICONIC ACCURACY INTERNATIONAL OLIVE-DRAB THUMBHOLE CHASSIS
	# ==========================================
	var chassis := Node3D.new()
	chassis.name = "Chassis"
	root.add_child(chassis)

	# Internal matte-black machined aluminum chassis backbone visible through side vents!
	_add_box(chassis, "AluminumCore", Vector3(0.036, 0.036, 0.43), Vector3(0, -0.012, -0.185), mat_steel_dark)

	# Two-piece bolted OD-green forend & action side skins
	_add_box(chassis, "ForendMain", Vector3(0.046, 0.046, 0.415), Vector3(0, -0.016, -0.195), mat_od)
	_add_box(chassis, "ForendBottomRail", Vector3(0.034, 0.010, 0.385), Vector3(0, -0.042, -0.205), mat_od_dark)
	_add_box(chassis, "ForendNoseCap", Vector3(0.044, 0.044, 0.026), Vector3(0, -0.014, -0.412), mat_steel_dark)
	# Iconic side ventilation / accessory slots along both flanks of the AI forend
	for sx in [-0.0235, 0.0235]:
		for vz in [-0.21, -0.28, -0.35]:
			_add_box(chassis, "ForendVent", Vector3(0.003, 0.012, 0.042), Vector3(sx, -0.012, vz), mat_bore)
		# Recessed stainless hex chassis assembly bolts
		for bz in [-0.145, -0.040, 0.055, 0.245]:
			_add_cyl(chassis, "ChassisBolt", 0.0036, 0.0036, 0.005, Vector3(sx, -0.020 if bz < 0.0 else -0.012, bz), mat_hardware, 6, Vector3(0, 0, 90))

	# Ergonomic contoured AI thumbhole pistol grip & finger swell
	_add_box(chassis, "GripUpper", Vector3(0.038, 0.054, 0.056), Vector3(0, -0.042, 0.078), mat_od, Vector3(-18.0, 0, 0))
	_add_box(chassis, "GripLower", Vector3(0.036, 0.056, 0.048), Vector3(0, -0.076, 0.094), mat_od, Vector3(-24.0, 0, 0))
	_add_box(chassis, "GripFrontPanel", Vector3(0.030, 0.068, 0.010), Vector3(0, -0.062, 0.068), mat_rubber, Vector3(-21.0, 0, 0))

	# Upper buttstock spine, sculpted thumbhole rear strut & rear bag-rider hook
	_add_box(chassis, "StockTopBeam", Vector3(0.042, 0.034, 0.285), Vector3(0, -0.008, 0.200), mat_od)
	_add_box(chassis, "StockLowerStrut", Vector3(0.034, 0.022, 0.165), Vector3(0, -0.092, 0.175), mat_od)
	_add_box(chassis, "StockRearBridge", Vector3(0.042, 0.078, 0.072), Vector3(0, -0.054, 0.295), mat_od)
	# Monopod / rear bag-rider notch cut under buttstock heel
	_add_box(chassis, "BagRiderStep", Vector3(0.036, 0.016, 0.056), Vector3(0, -0.088, 0.305), mat_od_dark)

	# Stacked black length-of-pull butt spacers + thick ventilated rubber recoil pad
	_add_box(chassis, "LOPSpacer1", Vector3(0.043, 0.106, 0.012), Vector3(0, -0.044, 0.338), mat_steel_dark)
	_add_box(chassis, "LOPSpacer2", Vector3(0.043, 0.106, 0.010), Vector3(0, -0.044, 0.351), mat_od_dark)
	_add_box(chassis, "ButtRecoilPad", Vector3(0.045, 0.110, 0.022), Vector3(0, -0.044, 0.369), mat_rubber)

	# Adjustable Elevated Cheekpiece on Twin Stainless Posts + Knurled Thumbwheel!
	for cz in [0.185, 0.255]:
		_add_cyl(chassis, "CheekPost", 0.005, 0.005, 0.028, Vector3(0, 0.014, cz), mat_hardware, 10, Vector3.ZERO)
	_add_box(chassis, "CheekPieceTop", Vector3(0.044, 0.016, 0.128), Vector3(0, 0.027, 0.220), mat_rubber)
	_add_cyl(chassis, "CheekPieceRound", 0.021, 0.021, 0.126, Vector3(0, 0.021, 0.220), mat_rubber, 14)
	_add_cyl(chassis, "CheekThumbwheel", 0.0085, 0.0085, 0.007, Vector3(0.024, -0.004, 0.220), mat_hardware, 12, Vector3(0, 0, 90))

	# Oversized Winter Trigger Guard, Mag Release Paddle & Match Curved Trigger
	_add_box(chassis, "TriggerGuardFront", Vector3(0.018, 0.034, 0.006), Vector3(0, -0.052, -0.014), mat_steel_dark)
	_add_box(chassis, "TriggerGuardBow", Vector3(0.018, 0.006, 0.070), Vector3(0, -0.068, 0.020), mat_steel_dark)
	_add_box(chassis, "TriggerGuardRear", Vector3(0.018, 0.032, 0.006), Vector3(0, -0.052, 0.054), mat_steel_dark, Vector3(14.0, 0, 0))
	_add_box(chassis, "MagReleasePaddle", Vector3(0.014, 0.022, 0.008), Vector3(0, -0.050, -0.026), mat_steel, Vector3(-16.0, 0, 0))
	_add_box(chassis, "MatchTrigger", Vector3(0.006, 0.022, 0.008), Vector3(0, -0.050, 0.024), mat_bolt, Vector3(-16.0, 0, 0))

	# ==========================================
	# 2. FLAT-BOTTOMED AI RECEIVER, PICATINNY RAIL, FLUTED BARREL & MUZZLE BRAKE
	# ==========================================
	# Heavy machined AI action receiver + recessed right-side ejection port!
	_add_box(root, "ReceiverLower", Vector3(0.042, 0.032, 0.225), Vector3(0, 0.015, -0.052), mat_steel)
	_add_box(root, "ReceiverTopFront", Vector3(0.038, 0.016, 0.088), Vector3(0, 0.034, -0.120), mat_steel)
	_add_box(root, "ReceiverTopRear", Vector3(0.038, 0.016, 0.062), Vector3(0, 0.034, 0.030), mat_steel)
	_add_box(root, "ReceiverLeftWall", Vector3(0.010, 0.018, 0.095), Vector3(-0.014, 0.034, -0.042), mat_steel)
	_add_box(root, "EjectionPortRecess", Vector3(0.016, 0.018, 0.084), Vector3(0.012, 0.026, -0.044), mat_bore)

	# Full-length 20-MOA Picatinny scope rail with machined cross-slots!
	_add_box(root, "PicatinnyRailBase", Vector3(0.024, 0.007, 0.215), Vector3(0, 0.045, -0.055), mat_steel_dark)
	for i in range(11):
		_add_box(root, "RailLug_%d" % i, Vector3(0.025, 0.0045, 0.010), Vector3(0, 0.050, -0.150 + float(i) * 0.019), mat_steel_dark)

	# Free-floating heavy match barrel with 6 longitudinal dark machined cooling flutes!
	_add_cyl(root, "BarrelChamber", 0.0165, 0.0175, 0.095, Vector3(0, 0.022, -0.205), mat_steel, 18)
	_add_cyl(root, "HeavyBarrel", 0.0128, 0.0160, 0.525, Vector3(0, 0.022, -0.505), mat_steel, 18)
	for f_idx in range(6):
		var fang: float = float(f_idx) * (TAU / 6.0)
		var fx: float = cos(fang) * 0.0138
		var fy: float = sin(fang) * 0.0138
		_add_cyl(root, "BarrelFlute_%d" % f_idx, 0.0022, 0.0022, 0.420, Vector3(fx, 0.022 + fy, -0.495), mat_steel_dark, 6)

	# Authentic Accuracy International Dual-Chamber Open-Port Muzzle Brake!
	var brake := Node3D.new()
	brake.name = "MuzzleBrake"
	brake.position = Vector3(0, 0.022, -0.800)
	root.add_child(brake)
	_add_cyl(brake, "BrakeCollar", 0.0155, 0.0145, 0.018, Vector3(0, 0, 0.036), mat_steel_dark, 14)
	_add_box(brake, "BrakeTopBridge", Vector3(0.028, 0.006, 0.072), Vector3(0, 0.012, -0.004), mat_steel)
	_add_box(brake, "BrakeBotBridge", Vector3(0.028, 0.006, 0.072), Vector3(0, -0.012, -0.004), mat_steel)
	_add_box(brake, "BrakeBaffleRear", Vector3(0.030, 0.028, 0.010), Vector3(0, 0, 0.024), mat_steel)
	_add_box(brake, "BrakeBaffleMid", Vector3(0.030, 0.028, 0.010), Vector3(0, 0, -0.004), mat_steel)
	_add_box(brake, "BrakeBaffleFront", Vector3(0.030, 0.028, 0.012), Vector3(0, 0, -0.034), mat_steel)
	# Dark hollow blast chambers & muzzle bore
	_add_box(brake, "BlastChamber1", Vector3(0.024, 0.016, 0.018), Vector3(0, 0, 0.010), mat_bore)
	_add_box(brake, "BlastChamber2", Vector3(0.024, 0.016, 0.018), Vector3(0, 0, -0.019), mat_bore)
	_add_cyl(brake, "MuzzleBore", 0.0075, 0.0075, 0.014, Vector3(0, 0, -0.039), mat_bore, 12)

	# Folded Front Spigot Bipod (Parker-Hale / AI style with knurled locks & rubber feet!)
	_add_box(root, "BipodSpigotMount", Vector3(0.028, 0.022, 0.032), Vector3(0, -0.034, -0.408), mat_steel_dark)
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0.024 * sx, -0.036, -0.415)
		leg.rotation_degrees = Vector3(0.0, 3.5 * sx, 0.0)
		root.add_child(leg)
		_add_cyl(leg, "BipodPivot", 0.008, 0.008, 0.016, Vector3(0, 0, 0), mat_steel_dark, 10, Vector3(0, 0, 90))
		_add_cyl(leg, "BipodUpperTube", 0.0068, 0.0068, 0.145, Vector3(0, 0, -0.075), mat_steel, 10)
		_add_cyl(leg, "BipodLockCollar", 0.0092, 0.0092, 0.016, Vector3(0, 0, -0.148), mat_hardware, 10)
		_add_cyl(leg, "BipodInnerLeg", 0.0052, 0.0052, 0.085, Vector3(0, 0, -0.192), mat_bolt, 10)
		_add_cyl(leg, "BipodFoot", 0.0095, 0.0072, 0.024, Vector3(0, 0, -0.242), mat_rubber, 10)

	# ==========================================
	# 3. DETACHABLE STEEL .338 LAPUA MAGNUM BOX MAGAZINE ("Magazine")
	# ==========================================
	var mag := Node3D.new()
	mag.name = "Magazine"
	mag.position = Vector3(0, -0.068, -0.088)
	root.add_child(mag)
	_add_box(mag, "MagBody", Vector3(0.030, 0.096, 0.092), Vector3.ZERO, mat_steel)
	for sx in [-0.0155, 0.0155]:
		_add_box(mag, "MagRib", Vector3(0.003, 0.072, 0.016), Vector3(sx, -0.002, -0.008), mat_steel_dark)
	_add_box(mag, "MagFloorPlate", Vector3(0.035, 0.013, 0.098), Vector3(0, -0.050, 0), mat_rubber)
	# Visible gleaming .338 Lapua Magnum top round seated in feed lips!
	_add_cyl(mag, "TopRoundCase", 0.0062, 0.0068, 0.048, Vector3(0, 0.049, 0.008), mat_brass, 10)
	_add_cyl(mag, "TopRoundTip", 0.0012, 0.0056, 0.026, Vector3(0, 0.049, -0.028), mat_copper, 10)

	# ==========================================
	# 4. ANIMATED AI 60-DEGREE FLUTED BOLT ASSEMBLY ("BoltHandle")
	# ==========================================
	var bolt_pivot := Node3D.new()
	bolt_pivot.name = "BoltHandle"
	bolt_pivot.position = Vector3(0.0, 0.022, 0.020)
	root.add_child(bolt_pivot)
	_add_cyl(bolt_pivot, "BoltBody", 0.0115, 0.0115, 0.145, Vector3(0, 0, -0.036), mat_bolt, 16)
	# Dark bolt flutes
	for b_ang in [0.0, 120.0, 240.0]:
		var br: float = deg_to_rad(b_ang)
		_add_cyl(bolt_pivot, "BoltFlute", 0.0022, 0.0022, 0.095, Vector3(cos(br) * 0.0108, sin(br) * 0.0108, -0.040), mat_steel_dark, 6)
	# Rear anodized AI bolt shroud & 3-position safety switch
	_add_box(bolt_pivot, "BoltShroud", Vector3(0.022, 0.024, 0.030), Vector3(0, 0.001, 0.044), mat_steel_dark)
	_add_box(bolt_pivot, "SafetyLever", Vector3(0.008, 0.012, 0.014), Vector3(0.013, 0.006, 0.044), mat_hardware)
	# Swept-back AI bolt arm + oversized tactical matte-black bolt knob!
	_add_cyl(bolt_pivot, "BoltArmRoot", 0.0055, 0.0062, 0.026, Vector3(0.016, -0.002, 0.014), mat_steel, 10, Vector3(0, -14.0, -78.0))
	_add_cyl(bolt_pivot, "BoltArmDrop", 0.0052, 0.0055, 0.024, Vector3(0.032, -0.012, 0.018), mat_steel, 10, Vector3(8.0, 0, -34.0))
	_add_sphere(bolt_pivot, "TacticalKnob", 0.0125, Vector3(0.041, -0.024, 0.022), mat_rubber, Vector3(1.05, 0.95, 1.15))

	# ==========================================
	# 5. SCHMIDT & BENDER PM II 3x-8x PiP TACTICAL SCOPE
	#    Optical centerline EXACTLY at weapon-local (0.0, +0.082, z)!
	#    Ocular OpticLens EXACTLY at weapon-local (0.0, +0.082, +0.112)!
	# ==========================================
	var scope := Node3D.new()
	scope.name = "SniperScope"
	scope.position = Vector3(0.0, 0.082, -0.060)
	root.add_child(scope)

	# Heavy AI one-piece cantilever scope mount + twin bolted 34mm rings
	_add_box(scope, "MountBaseRail", Vector3(0.032, 0.012, 0.145), Vector3(0, -0.031, -0.005), mat_steel_dark)
	for rz in [-0.056, 0.048]:
		_add_box(scope, "RingPedestal", Vector3(0.032, 0.026, 0.024), Vector3(0, -0.016, rz), mat_steel_dark)
		_add_cyl(scope, "RingClamp", 0.0215, 0.0215, 0.024, Vector3(0, 0.0, rz), mat_steel_dark, 18)
		# Ring top cap hex screws
		for sx in [-0.014, 0.014]:
			_add_cyl(scope, "RingScrew", 0.0028, 0.0028, 0.008, Vector3(sx, 0.021, rz), mat_hardware, 6, Vector3.ZERO)

	# 34mm Main Scope Tube
	_add_cyl(scope, "MainTube", 0.0172, 0.0172, 0.235, Vector3(0, 0, -0.008), mat_scope_body, 20)

	# Flared 50mm Objective Bell + Extended Anti-Glare Sunshade + Emerald Multi-Coated Lens
	_add_cyl(scope, "ObjectiveFlare", 0.0285, 0.0172, 0.072, Vector3(0, 0, -0.155), mat_scope_body, 24)
	_add_cyl(scope, "Sunshade", 0.0292, 0.0288, 0.082, Vector3(0, 0, -0.230), mat_scope_body, 24)
	_add_cyl(scope, "SunshadeRing", 0.0302, 0.0302, 0.008, Vector3(0, 0, -0.270), mat_rubber, 24)
	_add_cyl(scope, "ObjectiveLens", 0.0265, 0.0265, 0.004, Vector3(0, 0, -0.245), mat_obj_lens, 22)

	# Ocular Eyepiece Bell, Knurled Power Ring, Throw Lever & Diopter Rubber Ring
	_add_cyl(scope, "PowerRing", 0.0218, 0.0218, 0.018, Vector3(0, 0, 0.102), mat_rubber, 20)
	_add_box(scope, "ThrowLever", Vector3(0.006, 0.020, 0.007), Vector3(-0.020, 0.018, 0.102), mat_steel_dark, Vector3(0, 0, 42.0))
	_add_cyl(scope, "OcularBell", 0.0172, 0.0252, 0.068, Vector3(0, 0, 0.138), mat_scope_body, 24)
	_add_cyl(scope, "DiopterRing", 0.0260, 0.0260, 0.014, Vector3(0, 0, 0.165), mat_rubber, 24)

	# Tactical Turret Saddle: Tall Elevation Turret (white ticks), Windage Turret & Left Parallax Drum
	_add_box(scope, "TurretSaddle", Vector3(0.038, 0.038, 0.038), Vector3(0, 0, -0.005), mat_scope_body)
	_add_cyl(scope, "ElevTurretBase", 0.0135, 0.0142, 0.022, Vector3(0, 0.027, -0.005), mat_scope_body, 16, Vector3.ZERO)
	_add_cyl(scope, "ElevTurretMark", 0.0144, 0.0144, 0.003, Vector3(0, 0.021, -0.005), mat_white_tick, 16, Vector3.ZERO)
	_add_cyl(scope, "ElevTurretCap", 0.0115, 0.0125, 0.008, Vector3(0, 0.041, -0.005), mat_rubber, 16, Vector3.ZERO)
	_add_cyl(scope, "WindTurret", 0.0125, 0.0132, 0.022, Vector3(0.026, 0, -0.005), mat_scope_body, 16, Vector3(0, 0, 90))
	_add_cyl(scope, "WindTurretMark", 0.0134, 0.0134, 0.003, Vector3(0.020, 0, -0.005), mat_white_tick, 16, Vector3(0, 0, 90))
	_add_cyl(scope, "ParallaxDrum", 0.0135, 0.0135, 0.020, Vector3(-0.026, 0, -0.005), mat_rubber, 16, Vector3(0, 0, 90))
	_add_cyl(scope, "IllumCap", 0.0095, 0.0095, 0.008, Vector3(-0.037, 0, -0.005), mat_steel_dark, 14, Vector3(0, 0, 90))

	# Precision Circular See-Through PiP Ocular Lens facing player (+Z)
	# Local z = +0.172 -> weapon-local = (0.0, +0.082, +0.112)
	var lens := MeshInstance3D.new()
	lens.name = "OpticLens"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.049, 0.049)
	lens.mesh = qm
	lens.material_override = _create_sniper_lens_material()
	lens.position = Vector3(0.0, 0.0, 0.1725)
	scope.add_child(lens)

	# ==========================================
	# 6. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.022, -0.845)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.028, 0.030, -0.044)
	root.add_child(eject)

	return root

static func _create_sniper_lens_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.496) {
		discard;
	}
	if (r > 0.452) {
		// Matte anodized ocular bezel ring
		ALBEDO = vec3(0.028, 0.032, 0.036);
		ALPHA = 1.0;
	} else {
		// Schmidt & Bender P4F / Mil-Dot Sniper Reticle with illuminated ruby center dot
		float fine_h = step(abs(p.y), 0.0014) * step(0.012, abs(p.x)) * step(abs(p.x), 0.44);
		float fine_v = step(abs(p.x), 0.0014) * step(0.012, abs(p.y)) * step(abs(p.y), 0.44);
		// Heavy outer duplex stadia posts
		float thick_h = step(abs(p.y), 0.0055) * step(0.25, abs(p.x)) * step(abs(p.x), 0.44);
		float thick_v = step(abs(p.x), 0.0055) * step(0.25, abs(p.y)) * step(abs(p.y), 0.44);
		// Precision Mil-Dot / hash graduations along both axes
		float mil_h = step(abs(p.y), 0.0085) * step(0.045, abs(p.x)) * step(abs(p.x), 0.24) * step(abs(fract(abs(p.x) * 18.0 + 0.5) - 0.5), 0.08);
		float mil_v = step(abs(p.x), 0.0085) * step(0.045, abs(p.y)) * step(abs(p.y), 0.24) * step(abs(fract(abs(p.y) * 18.0 + 0.5) - 0.5), 0.08);
		// Lower windage holdover ticks (subtle Christmas-tree dots below horizontal axis)
		float tree_y = step(0.05, p.y) * step(p.y, 0.23) * step(abs(fract(p.y * 18.0 + 0.5) - 0.5), 0.09);
		float tree_x = step(0.035, abs(p.x)) * step(abs(p.x), p.y * 0.72) * step(abs(fract(abs(p.x) * 18.0 + 0.5) - 0.5), 0.09);
		float mask = clamp(fine_h + fine_v + thick_h + thick_v + mil_h + mil_v + tree_y * tree_x * 0.85, 0.0, 1.0);
		float center_dot = 1.0 - smoothstep(0.0038, 0.0068, r);

		vec3 bg;
		if (use_pip) {
			bg = texture(pip_tex, clamp(UV, vec2(0.005), vec2(0.995))).rgb;
		} else {
			// Subtle emerald multi-coated glass reflection when viewed from hipfire / Handbook
			float sheen = smoothstep(0.45, 0.0, length(p - vec2(-0.14, -0.14))) * 0.34;
			bg = vec3(0.04, 0.14, 0.15) + vec3(0.14, 0.28, 0.26) * sheen;
		}
		float vig = smoothstep(0.452, 0.385, r);
		bg *= mix(0.32, 1.0, vig);
		vec3 col = mix(bg, vec3(0.02, 0.02, 0.024), mask * 0.94);
		col = mix(col, vec3(1.0, 0.14, 0.10) * 1.4, center_dot);
		ALBEDO = col;
		ALPHA = 1.0;
	}
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	return sm
