class_name Kar98kModel
extends RefCounted

# Museum-Grade WWII German Mauser Karabiner 98k (7.92x57mm IS)
# Authentic geometry, procedural Schichtholz laminated wood shader, open-top Mauser 98 receiver,
# true hollow sight hood (clear ADS V-notch sight picture), and multi-part mechanical bolt assembly:
# - BoltAssembly (translates +Z on pull/push):
#     - BoltRotator (rotates around Z on lift/lock: BoltBody, LockingLugs, swept Kammerstengel & sphere knob)
#     - Extractor (non-rotating Mauser external claw extractor)
#     - BoltShroud (non-rotating Schlossmutter with gas shield flange)
#     - FlagSafety (3-position Mauser wing safety)
#     - CockingPiece (cams back on bolt lift, snaps forward on firing pin drop!)
#     - ExtractedCase (spent 7.92x57 brass case gripped on bolt face during extraction)
# - ClipStrip (seated in receiver bridge guides):
#     - ClipRail (stamped steel clip, kicked out spinning when bolt slams shut!)
#     - ClipRounds (5 staggered brass/copper 7.92x57 spitzer cartridges pressed down into magwell)
# - SingleRound (individual 7.92x57 cartridge for partial hand-loading & chamber feeding)
# - FollowerRound (top cartridge visible inside open Mauser action when ammo > 0)
# - Trigger (two-stage curved Mauser trigger)

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

static func _create_laminated_wood_material(dark_tint: float = 0.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 wood_light : source_color = vec3(0.45, 0.21, 0.085);
uniform vec3 wood_mid   : source_color = vec3(0.32, 0.135, 0.052);
uniform vec3 wood_dark  : source_color = vec3(0.16, 0.065, 0.024);
uniform float darken : hint_range(0.0, 0.5) = 0.0;

varying vec3 v_local;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	// WWII German Schichtholz: thin beech/walnut laminate plies glued with phenolic resin
	vec3 p = v_local;
	float warp = noise3(vec3(p.x * 28.0, p.y * 24.0, p.z * 7.5)) * 0.35;
	float ply_coord = (p.x * 260.0 + p.y * 42.0) + warp * 4.5;
	float ply = sin(ply_coord);
	float glue_line = smoothstep(0.86, 0.99, abs(ply));
	float fiber = noise3(vec3(p.x * 95.0, p.y * 95.0, p.z * 18.0));
	float ring = 0.5 + 0.5 * sin((p.y * 85.0 + p.z * 6.5) + fiber * 3.2);

	vec3 col = mix(wood_mid, wood_light, ring * 0.72 + fiber * 0.28);
	col = mix(col, wood_dark, glue_line * 0.62 + (1.0 - ring) * 0.22);
	col *= (1.0 - darken);

	ALBEDO = col;
	ROUGHNESS = clamp(0.43 + glue_line * 0.14 - fiber * 0.06, 0.34, 0.64);
	METALLIC = 0.03;
	SPECULAR = 0.54;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("darken", dark_tint)
	return sm

static func _build_792_cartridge(mat_brass: Material, mat_copper: Material, mat_steel_dark: Material, include_bullet: bool = true) -> Node3D:
	# Authentic 7.92x57mm IS Mauser rimless bottleneck spitzer cartridge (overall length ~80.6mm -> 0.076m in viewmodel)
	# Oriented forward along -Z!
	var c := Node3D.new()
	# Rim & extractor groove at rear (+Z)
	_add_cyl(c, "Rim", 0.0058, 0.0058, 0.0018, Vector3(0, 0, 0.034), mat_brass, 12)
	_add_cyl(c, "Groove", 0.0049, 0.0049, 0.0022, Vector3(0, 0, 0.032), mat_steel_dark, 10)
	# Tapered brass body (57mm case)
	_add_cyl(c, "CaseBody", 0.0054, 0.0059, 0.040, Vector3(0, 0, 0.011), mat_brass, 12)
	# Bottleneck shoulder & neck
	_add_cyl(c, "Shoulder", 0.0043, 0.0054, 0.006, Vector3(0, 0, -0.012), mat_brass, 12)
	_add_cyl(c, "Neck", 0.0042, 0.0043, 0.007, Vector3(0, 0, -0.0185), mat_brass, 12)
	if include_bullet:
		# Pointed copper-nickel / tombak spitzer boat-tail projectile
		_add_cyl(c, "BulletBody", 0.0038, 0.0040, 0.010, Vector3(0, 0, -0.027), mat_copper, 12)
		_add_cyl(c, "BulletOgive", 0.0007, 0.0038, 0.014, Vector3(0, 0, -0.039), mat_copper, 12)
	else:
		# Dark hollow mouth on fired brass case
		_add_cyl(c, "SpentMouth", 0.0037, 0.0037, 0.003, Vector3(0, 0, -0.021), mat_steel_dark, 10)
	return c

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "Kar98kModel"

	# ==========================================
	# PBR & PROCEDURAL SHADER PALETTE
	# ==========================================
	var mat_wood := _create_laminated_wood_material(0.0)
	var mat_wood_dark := _create_laminated_wood_material(0.20)

	var mat_blued := StandardMaterial3D.new()
	mat_blued.albedo_color = Color(0.11, 0.125, 0.15) # Deep German salt-blued forged steel
	mat_blued.metallic = 0.91
	mat_blued.roughness = 0.27

	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.07, 0.075, 0.09) # Matte sight / phosphate steel
	mat_steel_dark.metallic = 0.84
	mat_steel_dark.roughness = 0.42

	var mat_sight_black := StandardMaterial3D.new()
	mat_sight_black.albedo_color = Color(0.035, 0.038, 0.042) # Anti-glare smoked sight post & V-notch
	mat_sight_black.metallic = 0.45
	mat_sight_black.roughness = 0.72

	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.79, 0.81, 0.85) # Bright machined Mauser bolt steel
	mat_bolt.metallic = 0.96
	mat_bolt.roughness = 0.16

	var mat_bolt_worn := StandardMaterial3D.new()
	mat_bolt_worn.albedo_color = Color(0.56, 0.59, 0.63) # Extractor & shroud tempered steel
	mat_bolt_worn.metallic = 0.92
	mat_bolt_worn.roughness = 0.24

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.018, 0.018, 0.022)
	mat_bore.roughness = 0.95

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.71, 0.26)
	mat_brass.metallic = 0.93
	mat_brass.roughness = 0.20

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.83, 0.45, 0.20)
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var mat_leather := StandardMaterial3D.new()
	mat_leather.albedo_color = Color(0.24, 0.12, 0.06) # Pebbled brown Wehrmacht leather sling
	mat_leather.roughness = 0.76
	mat_leather.metallic = 0.04

	var mat_white_mark := StandardMaterial3D.new()
	mat_white_mark.albedo_color = Color(0.88, 0.86, 0.78)
	mat_white_mark.roughness = 0.55

	# ==========================================
	# 1. CONTOURED SCHICHTHOLZ LAMINATED STOCK, SLING & HARDWARE
	# ==========================================
	var stock := Node3D.new()
	stock.name = "Stock"
	root.add_child(stock)

	# Contoured semi-pistol grip wrist (Halbpistolengriff)
	_add_box(stock, "WristUpper", Vector3(0.037, 0.042, 0.115), Vector3(0, -0.018, 0.105), mat_wood, Vector3(13.0, 0, 0))
	_add_box(stock, "PistolGripSwell", Vector3(0.039, 0.048, 0.072), Vector3(0, -0.048, 0.128), mat_wood, Vector3(28.0, 0, 0))
	_add_cyl(stock, "PistolGripCap", 0.019, 0.017, 0.055, Vector3(0, -0.068, 0.145), mat_wood_dark, 12, Vector3(-62.0, 0, 0))

	# Main buttstock body, fluted comb & lower toe taper
	_add_box(stock, "ButtMain", Vector3(0.042, 0.088, 0.225), Vector3(0, -0.042, 0.258), mat_wood, Vector3(7.5, 0, 0))
	_add_cyl(stock, "ButtComb", 0.019, 0.016, 0.215, Vector3(0, 0.002, 0.255), mat_wood, 14, Vector3(-82.5, 0, 0))
	_add_box(stock, "ButtToe", Vector3(0.040, 0.036, 0.185), Vector3(0, -0.084, 0.272), mat_wood, Vector3(13.5, 0, 0))

	# Cupped stamped steel buttplate (Kappenblech) wrapping heel & toe
	_add_box(stock, "ButtPlateBack", Vector3(0.044, 0.118, 0.012), Vector3(0, -0.054, 0.371), mat_steel_dark, Vector3(7.5, 0, 0))
	_add_box(stock, "ButtPlateTangTop", Vector3(0.043, 0.010, 0.038), Vector3(0, 0.006, 0.352), mat_steel_dark, Vector3(7.5, 0, 0))
	_add_box(stock, "ButtPlateCupLow", Vector3(0.044, 0.010, 0.026), Vector3(0, -0.112, 0.364), mat_steel_dark, Vector3(7.5, 0, 0))

	# Iconic through-stock bolt takedown disk (Stempelplatte) + dark central hole
	_add_cyl(stock, "TakedownDisk", 0.0145, 0.0145, 0.045, Vector3(0, -0.048, 0.258), mat_bolt_worn, 16, Vector3(0, 0, 90))
	_add_cyl(stock, "TakedownHole", 0.0048, 0.0048, 0.047, Vector3(0, -0.048, 0.258), mat_bore, 12, Vector3(0, 0, 90))

	# Through-stock rear sling slot (Riemendurchbruch) + steel cross-pin + leather wrap
	_add_box(stock, "SlingSlotCutout", Vector3(0.045, 0.028, 0.012), Vector3(0, -0.058, 0.312), mat_bore, Vector3(7.5, 0, 0))
	_add_cyl(stock, "SlingSlotPin", 0.0028, 0.0028, 0.045, Vector3(0, -0.058, 0.312), mat_bolt_worn, 8, Vector3(0, 0, 90))
	_add_box(stock, "SlingRearLeather", Vector3(0.048, 0.022, 0.016), Vector3(-0.003, -0.058, 0.312), mat_leather, Vector3(7.5, 0, 0))

	# Receiver action bedding & sculpted forend
	_add_box(stock, "ActionStockBed", Vector3(0.045, 0.044, 0.220), Vector3(0, -0.012, -0.038), mat_wood)
	# Turned-down bolt handle recess (Kammerstengel-Aussparung) on right stock flank
	_add_cyl(stock, "BoltHandleRecess", 0.016, 0.016, 0.018, Vector3(0.022, -0.004, 0.028), mat_wood_dark, 12, Vector3(0, 0, 90))
	# Heavy steel cross-bolt recoil lug (Querstollen) under front receiver ring
	_add_cyl(stock, "RecoilCrossBolt", 0.0075, 0.0075, 0.047, Vector3(0, -0.012, -0.095), mat_steel_dark, 12, Vector3(0, 0, 90))

	# Forend body tapering gracefully toward nose cap + side finger grooves (Griffrillen)
	_add_box(stock, "ForendRear", Vector3(0.043, 0.040, 0.205), Vector3(0, -0.008, -0.245), mat_wood)
	_add_cyl(stock, "ForendRoundBottom", 0.0215, 0.0185, 0.390, Vector3(0, -0.012, -0.340), mat_wood, 14)
	_add_box(stock, "ForendFront", Vector3(0.036, 0.034, 0.195), Vector3(0, -0.006, -0.440), mat_wood)
	for sx in [-0.0218, 0.0218]:
		_add_cyl(stock, "FingerGroove", 0.0055, 0.0055, 0.135, Vector3(sx, 0.002, -0.225), mat_wood_dark, 10)

	# Arch-profiled Upper Wooden Handguard (Handschutz) from rear sight to rear barrel band
	_add_cyl(stock, "UpperHandguard", 0.0185, 0.0205, 0.255, Vector3(0, 0.019, -0.322), mat_wood_dark, 14)

	# Rear Barrel Band (Unterring) with left-side sling bar + band retaining spring (Oberringfeder)
	_add_box(stock, "RearBand", Vector3(0.044, 0.048, 0.018), Vector3(0, 0.006, -0.335), mat_steel_dark)
	_add_box(stock, "RearBandSlingLoop", Vector3(0.010, 0.026, 0.006), Vector3(-0.026, 0.002, -0.335), mat_steel_dark)
	_add_box(stock, "BandSpring", Vector3(0.003, 0.006, 0.085), Vector3(0.019, -0.004, -0.470), mat_bolt_worn)

	# Stepped H-Style Front Barrel Band / Nose Cap (Oberring) + Bayonet Lug (Seitengewehrhalter)
	_add_box(stock, "FrontBandRear", Vector3(0.039, 0.044, 0.014), Vector3(0, 0.006, -0.505), mat_steel_dark)
	_add_box(stock, "FrontBandBridge", Vector3(0.037, 0.014, 0.032), Vector3(0, -0.006, -0.520), mat_steel_dark)
	_add_box(stock, "FrontBandNose", Vector3(0.038, 0.044, 0.018), Vector3(0, 0.006, -0.536), mat_steel_dark)
	_add_box(stock, "BayonetLug", Vector3(0.012, 0.010, 0.036), Vector3(0, -0.023, -0.532), mat_blued)

	# Underbarrel Steel Cleaning Rod (Putzstock)
	_add_cyl(stock, "CleaningRod", 0.0026, 0.0026, 0.135, Vector3(0, -0.012, -0.595), mat_bolt_worn, 8)
	_add_cyl(stock, "CleaningRodSlotHead", 0.0034, 0.0028, 0.012, Vector3(0, -0.012, -0.662), mat_bolt, 8)

	# Wehrmacht Leather Combat Sling (Trageriemen) running cleanly along left/bottom!
	_add_box(stock, "SlingFrontWrap", Vector3(0.006, 0.022, 0.024), Vector3(-0.028, 0.002, -0.335), mat_leather)
	_add_box(stock, "SlingBuckle", Vector3(0.008, 0.024, 0.014), Vector3(-0.028, -0.012, -0.295), mat_bolt_worn, Vector3(8.0, 0, 0))
	_add_box(stock, "SlingStrap", Vector3(0.004, 0.019, 0.635), Vector3(-0.025, -0.034, -0.012), mat_leather, Vector3(4.2, -1.8, 0))

	# ==========================================
	# 2. OPEN-TOP MAUSER 98 RECEIVER & INTERNAL MAGAZINE
	# ==========================================
	var rec := Node3D.new()
	rec.name = "Receiver"
	root.add_child(rec)

	# Cylindrical Front Receiver Ring (Hülsenkopf) where barrel threads in
	_add_cyl(rec, "FrontReceiverRing", 0.0185, 0.0185, 0.048, Vector3(0, 0.016, -0.106), mat_blued, 18)
	_add_cyl(rec, "ChamberBore", 0.0095, 0.0095, 0.018, Vector3(0, 0.016, -0.084), mat_bore, 12)

	# Left Receiver Rail + Iconic Mauser Curved Thumb Cutout (Daumenloch)
	_add_box(rec, "LeftWallFront", Vector3(0.0065, 0.026, 0.042), Vector3(-0.015, 0.015, -0.062), mat_blued)
	_add_box(rec, "LeftWallThumbLow", Vector3(0.0065, 0.013, 0.046), Vector3(-0.015, 0.008, -0.018), mat_blued)
	_add_box(rec, "LeftWallRear", Vector3(0.0065, 0.026, 0.028), Vector3(-0.015, 0.015, 0.018), mat_blued)

	# Lowered Right Receiver Rail (wide ejection & loading port!)
	_add_box(rec, "RightWallLow", Vector3(0.0065, 0.012, 0.112), Vector3(0.015, 0.007, -0.026), mat_blued)

	# Split Rear Receiver Bridge (Hülsenbrücke) with Stripper-Clip Guide Slots (Ladestreifenführung)
	_add_box(rec, "RearBridgeL", Vector3(0.008, 0.028, 0.026), Vector3(-0.013, 0.017, 0.038), mat_blued)
	_add_box(rec, "RearBridgeR", Vector3(0.008, 0.028, 0.026), Vector3(0.013, 0.017, 0.038), mat_blued)
	_add_box(rec, "ClipGuideLipL", Vector3(0.005, 0.008, 0.012), Vector3(-0.009, 0.033, 0.033), mat_blued)
	_add_box(rec, "ClipGuideLipR", Vector3(0.005, 0.008, 0.012), Vector3(0.009, 0.033, 0.033), mat_blued)
	_add_box(rec, "ReceiverTang", Vector3(0.018, 0.007, 0.034), Vector3(0, 0.008, 0.064), mat_blued, Vector3(8.0, 0, 0))

	# Left-Side Hinged Bolt Stop / Ejector Box (Schlosshalter)
	_add_box(rec, "BoltStopBox", Vector3(0.007, 0.016, 0.036), Vector3(-0.020, 0.015, 0.022), mat_steel_dark)

	# Dark Open Magazine Well + Polished Steel Follower + Visible Top Cartridge ("FollowerRound")
	_add_box(rec, "MagWellInterior", Vector3(0.022, 0.010, 0.092), Vector3(0, 0.002, -0.032), mat_bore)
	_add_box(rec, "MagFollower", Vector3(0.014, 0.004, 0.072), Vector3(-0.002, 0.006, -0.032), mat_bolt_worn)

	var follower_round := _build_792_cartridge(mat_brass, mat_copper, mat_steel_dark, true)
	follower_round.name = "FollowerRound"
	follower_round.position = Vector3(0.001, 0.010, -0.030)
	root.add_child(follower_round)

	# Bottom Magazine Floorplate (Kastenboden), Locking Screws & Sculpted Trigger Guard
	_add_box(rec, "MagFloorplate", Vector3(0.026, 0.006, 0.115), Vector3(0, -0.035, -0.036), mat_steel_dark)
	_add_box(rec, "TriggerGuardBase", Vector3(0.020, 0.006, 0.065), Vector3(0, -0.035, 0.048), mat_steel_dark)
	_add_box(rec, "TriggerGuardFront", Vector3(0.014, 0.026, 0.005), Vector3(0, -0.048, 0.018), mat_blued, Vector3(-14.0, 0, 0))
	_add_box(rec, "TriggerGuardBow", Vector3(0.014, 0.005, 0.048), Vector3(0, -0.061, 0.042), mat_blued)
	_add_box(rec, "TriggerGuardRear", Vector3(0.014, 0.026, 0.005), Vector3(0, -0.048, 0.066), mat_blued, Vector3(16.0, 0, 0))

	# Animated Two-Stage Mauser Curved Trigger ("Trigger")
	var trig := Node3D.new()
	trig.name = "Trigger"
	trig.position = Vector3(0, -0.036, 0.045)
	root.add_child(trig)
	_add_box(trig, "TriggerBlade", Vector3(0.0055, 0.021, 0.008), Vector3(0, -0.011, 0.0), mat_bolt_worn, Vector3(-20.0, 0, 0))

	# ==========================================
	# 3. STEPPED BARREL, KURVENVISIER & TRUE OPEN SIGHT HOOD
	# ==========================================
	# Authentic Mauser 3-step tapered barrel + dark rifled bore
	_add_cyl(root, "BarrelChamberStep", 0.0145, 0.0155, 0.055, Vector3(0, 0.016, -0.155), mat_blued, 16)
	_add_cyl(root, "BarrelMidStep", 0.0118, 0.0135, 0.160, Vector3(0, 0.016, -0.260), mat_blued, 16)
	_add_cyl(root, "BarrelMain", 0.0092, 0.0115, 0.340, Vector3(0, 0.016, -0.505), mat_blued, 16)
	_add_cyl(root, "MuzzleBore", 0.0062, 0.0062, 0.012, Vector3(0, 0.016, -0.672), mat_bore, 12)

	# Tangent Rear Sight (Kurvenvisier) — crisp V-notch aligned at y = +0.048!
	_add_box(root, "RearSightSleeve", Vector3(0.026, 0.014, 0.074), Vector3(0, 0.030, -0.165), mat_steel_dark)
	_add_box(root, "RearSightRampL", Vector3(0.004, 0.010, 0.064), Vector3(-0.011, 0.039, -0.165), mat_blued)
	_add_box(root, "RearSightRampR", Vector3(0.004, 0.010, 0.064), Vector3(0.011, 0.039, -0.165), mat_blued)
	_add_box(root, "TangentLeafBody", Vector3(0.016, 0.004, 0.058), Vector3(0, 0.041, -0.164), mat_blued)
	_add_box(root, "RangeSlider", Vector3(0.023, 0.007, 0.013), Vector3(0, 0.041, -0.178), mat_bolt_worn)
	_add_box(root, "WhiteGradMark", Vector3(0.012, 0.001, 0.038), Vector3(0, 0.0435, -0.168), mat_white_mark)
	# Precision smoked-black rear sight notch walls (clean V/U gap at x=0, y=0.048!)
	_add_box(root, "RearNotchBase", Vector3(0.018, 0.005, 0.005), Vector3(0, 0.0445, -0.136), mat_sight_black)
	_add_box(root, "RearNotchWallL", Vector3(0.0068, 0.0065, 0.005), Vector3(-0.0056, 0.0495, -0.136), mat_sight_black)
	_add_box(root, "RearNotchWallR", Vector3(0.0068, 0.0065, 0.005), Vector3(0.0056, 0.0495, -0.136), mat_sight_black)

	# Front Sight Ramp, Tapered Barleycorn Post (tip at y = +0.048!) & TRUE HOLLOW SIGHT HOOD (Kornschutz)!
	_add_box(root, "FrontSightBand", Vector3(0.020, 0.022, 0.028), Vector3(0, 0.020, -0.645), mat_blued)
	_add_box(root, "FrontSightRamp", Vector3(0.009, 0.010, 0.032), Vector3(0, 0.034, -0.645), mat_steel_dark, Vector3(8.0, 0, 0))
	# Crisp anti-glare front post whose top edge sits dead-level with rear notch at y = 0.048!
	_add_box(root, "FrontSightPost", Vector3(0.0022, 0.0105, 0.006), Vector3(0, 0.0428, -0.645), mat_sight_black)

	# True open hollow spring-steel sight hood (11 curved segments around (0, 0.047, -0.645) — ZERO solid end-caps!)
	var hood_root := Node3D.new()
	hood_root.name = "FrontSightHood"
	hood_root.position = Vector3(0, 0.0465, -0.645)
	root.add_child(hood_root)
	var hood_r: float = 0.0135
	for i in range(11):
		var ang_deg: float = -135.0 + float(i) * 27.0 # Open arch from -135 deg to +135 deg wrapping around sight ramp!
		var ang_rad: float = deg_to_rad(ang_deg)
		var seg_pos := Vector3(sin(ang_rad) * hood_r, cos(ang_rad) * hood_r, 0.0)
		_add_box(hood_root, "HoodSeg_%d" % i, Vector3(0.0068, 0.0018, 0.022), seg_pos, mat_blued, Vector3(0, 0, -ang_deg))

	# ==========================================
	# 4. MULTI-PART MECHANICAL MAUSER 98 BOLT ASSEMBLY ("BoltHandle")
	# ==========================================
	# Kept named "BoltHandle" at root so external scripts stay compatible, while exposing
	# BoltRotator, BoltShroud, FlagSafety, CockingPiece & ExtractedCase inside!
	var bolt_assy := Node3D.new()
	bolt_assy.name = "BoltHandle"
	bolt_assy.position = Vector3(0.0, 0.016, 0.0)
	root.add_child(bolt_assy)

	# A) Rotating Bolt Body & Turned-Down Handle ("BoltRotator")
	var bolt_rot := Node3D.new()
	bolt_rot.name = "BoltRotator"
	bolt_assy.add_child(bolt_rot)

	_add_cyl(bolt_rot, "BoltCylinder", 0.0092, 0.0092, 0.142, Vector3(0, 0, -0.022), mat_bolt, 16)
	# Twin Mauser front locking lugs
	_add_box(bolt_rot, "LockingLugL", Vector3(0.005, 0.007, 0.014), Vector3(-0.010, 0, -0.084), mat_bolt)
	_add_box(bolt_rot, "LockingLugR", Vector3(0.005, 0.007, 0.014), Vector3(0.010, 0, -0.084), mat_bolt)
	#Bolt handle root collar + graceful swept-back & turned-down Kar98k Kammerstengel + Kammerkugel
	_add_cyl(bolt_rot, "HandleRootCollar", 0.0110, 0.0110, 0.014, Vector3(0, 0, 0.026), mat_bolt, 14)
	_add_cyl(bolt_rot, "HandleUpperSweep", 0.0046, 0.0056, 0.024, Vector3(0.015, -0.003, 0.027), mat_bolt, 10, Vector3(0, -10.0, -74.0))
	_add_cyl(bolt_rot, "HandleDownBend", 0.0044, 0.0046, 0.026, Vector3(0.028, -0.015, 0.030), mat_bolt, 10, Vector3(8.0, 0, -28.0))
	_add_sphere(bolt_rot, "BoltKnobSphere", 0.0108, Vector3(0.035, -0.029, 0.032), mat_bolt, Vector3(1.0, 0.92, 1.0))

	# B) Non-Rotating Mauser External Claw Extractor ("Extractor")
	_add_box(bolt_assy, "ExtractorCollar", Vector3(0.021, 0.021, 0.008), Vector3(0, 0, 0.012), mat_bolt_worn)
	_add_box(bolt_assy, "ExtractorClaw", Vector3(0.0032, 0.0065, 0.098), Vector3(0.0102, 0.001, -0.038), mat_bolt_worn)

	# C) Non-Rotating Rear Bolt Shroud (Schlossmutter) & Gas Shield Flange
	var shroud := Node3D.new()
	shroud.name = "BoltShroud"
	shroud.position = Vector3(0, 0, 0.052)
	bolt_assy.add_child(shroud)
	_add_cyl(shroud, "GasShieldFlange", 0.0132, 0.0125, 0.007, Vector3(0, 0.001, -0.004), mat_bolt_worn, 16)
	_add_box(shroud, "ShroudBody", Vector3(0.017, 0.021, 0.022), Vector3(0, 0.002, 0.008), mat_blued)
	# Iconic 3-Position Mauser Wing/Flag Safety (Sicherungsflügel — set to left = FIRE ready!)
	var safety := Node3D.new()
	safety.name = "FlagSafety"
	safety.position = Vector3(0, 0.012, 0.014)
	shroud.add_child(safety)
	_add_cyl(safety, "SafetyShaft", 0.0038, 0.0038, 0.014, Vector3(0, 0, 0), mat_bolt_worn, 10)
	_add_box(safety, "SafetyWing", Vector3(0.017, 0.0035, 0.013), Vector3(-0.009, 0.002, 0.002), mat_bolt_worn, Vector3(0, 0, 14.0))

	# D) Animated Firing-Pin Cocking Piece (Schlagbolzenmutter — snaps forward on shot, cams back on bolt lift!)
	var cocking := Node3D.new()
	cocking.name = "CockingPiece"
	cocking.position = Vector3(0, 0.001, 0.068) # Cocked resting Z = +0.068 (snaps to +0.060 when fired!)
	bolt_assy.add_child(cocking)
	_add_box(cocking, "CockingSear", Vector3(0.0075, 0.016, 0.015), Vector3(0, -0.002, 0.0), mat_bolt)
	_add_cyl(cocking, "CockingKnurl", 0.0062, 0.0062, 0.006, Vector3(0, 0.003, 0.006), mat_bolt_worn, 12)

	# E) Extracted Spent Brass Case gripped on Bolt Face during Bolt Pull!
	var ext_case := _build_792_cartridge(mat_brass, mat_copper, mat_bore, false)
	ext_case.name = "ExtractedCase"
	ext_case.position = Vector3(0.0, 0.0, -0.106)
	ext_case.visible = false
	bolt_assy.add_child(ext_case)

	# ==========================================
	# 5. AUTHENTIC 5-ROUND STRIPPER CLIP ("ClipStrip") & SINGLE ROUND ("SingleRound")
	# ==========================================
	var clip := Node3D.new()
	clip.name = "ClipStrip"
	clip.position = Vector3(0, 0.056, -0.026)
	clip.visible = false
	root.add_child(clip)

	# Stamped steel stripper clip rail (Ladestreifen) seated vertically at rear receiver bridge!
	var clip_rail := Node3D.new()
	clip_rail.name = "ClipRail"
	clip_rail.position = Vector3(0, 0, 0.058)
	clip.add_child(clip_rail)
	_add_box(clip_rail, "RailSpine", Vector3(0.0135, 0.064, 0.0035), Vector3(0, 0, 0.003), mat_steel_dark)
	_add_box(clip_rail, "RailLipL", Vector3(0.0025, 0.064, 0.0075), Vector3(-0.0065, 0, -0.001), mat_bolt_worn)
	_add_box(clip_rail, "RailLipR", Vector3(0.0025, 0.064, 0.0075), Vector3(0.0065, 0, -0.001), mat_bolt_worn)

	# 5 Staggered 7.92x57mm Mauser Spitzer Cartridges ("ClipRounds" — slides down into internal mag!)
	var clip_rounds := Node3D.new()
	clip_rounds.name = "ClipRounds"
	clip.add_child(clip_rounds)
	for i in range(5):
		var stag_x: float = -0.0022 if (i % 2 == 0) else 0.0022
		var rnd := _build_792_cartridge(mat_brass, mat_copper, mat_steel_dark, true)
		rnd.name = "Round_%d" % i
		rnd.position = Vector3(stag_x, -0.023 + float(i) * 0.0115, 0.022)
		clip_rounds.add_child(rnd)

	# Standalone 7.92x57mm Cartridge for Partial Single-Round Hand Loading & Bolt Feeding!
	var single_rnd := _build_792_cartridge(mat_brass, mat_copper, mat_steel_dark, true)
	single_rnd.name = "SingleRound"
	single_rnd.position = Vector3(0, 0.048, -0.028)
	single_rnd.visible = false
	root.add_child(single_rnd)

	# ==========================================
	# 6. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.016, -0.682)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.028, 0.028, -0.015)
	root.add_child(eject)

	return root
