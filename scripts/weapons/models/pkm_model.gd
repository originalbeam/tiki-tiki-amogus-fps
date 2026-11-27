class_name PKMModel
extends RefCounted

# Museum-Grade Russian PKM / PKP General-Purpose Machine Gun (7.62x54mm R)
# Forward along -Z:
# - Procedural laminated Russian birch wood shader on skeletonized cutout stock & carry handle
# - Stamped riveted receiver with side stiffening flutes, dovetail rail, internal feed tray & dust flap
# - Hinged TopCover (opens 74 deg on reload) with ribbed stampings & precision rear tangent sight (y = +0.072)
# - Heavy fluted barrel with gas tube, multi-position regulator, birdcage flash hider & folded ski-foot bipod
# - Right-side hooked ChargingHandle + under-mounted 100rd olive steel AmmoBox & linked 7.62x54R brass belt!

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

static func _create_birch_wood_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

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
	// Soviet laminated amber birch ply grain
	float ply = sin(v_local.x * 230.0 + v_local.y * 36.0 + sin(v_local.z * 16.0) * 1.4);
	float seam = smoothstep(0.84, 0.99, abs(ply));
	float grain = hash31(floor(vec3(v_local.x * 110.0, v_local.y * 110.0, v_local.z * 26.0)));
	vec3 light_w = vec3(0.54, 0.27, 0.10);
	vec3 mid_w = vec3(0.39, 0.18, 0.065);
	vec3 dark_w = vec3(0.20, 0.085, 0.03);
	vec3 col = mix(mid_w, light_w, 0.45 + grain * 0.55);
	col = mix(col, dark_w, seam * 0.65);
	ALBEDO = col;
	ROUGHNESS = clamp(0.42 + seam * 0.14, 0.34, 0.62);
	METALLIC = 0.03;
	SPECULAR = 0.52;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	return sm

static func _build_762x54r_round(mat_brass: Material, mat_copper: Material, mat_link: Material) -> Node3D:
	var r := Node3D.new()
	_add_cyl(r, "Rim", 0.0056, 0.0056, 0.0018, Vector3(0, 0, 0.029), mat_brass, 10)
	_add_cyl(r, "Case", 0.0046, 0.0053, 0.036, Vector3(0, 0, 0.010), mat_brass, 10)
	_add_cyl(r, "Neck", 0.0038, 0.0046, 0.008, Vector3(0, 0, -0.012), mat_brass, 10)
	_add_cyl(r, "Bullet", 0.0008, 0.0038, 0.020, Vector3(0, 0, -0.026), mat_copper, 10)
	_add_box(r, "Link", Vector3(0.011, 0.011, 0.016), Vector3(0, 0, 0.012), mat_link)
	return r

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "PKMModel"

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.115, 0.125, 0.14) # Deep Soviet blued/lacquered stamped steel
	mat_steel.metallic = 0.88
	mat_steel.roughness = 0.30

	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.07, 0.075, 0.085) # Matte parkerized hardware & belt links
	mat_steel_dark.metallic = 0.82
	mat_steel_dark.roughness = 0.42

	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.72, 0.74, 0.78) # Machined feed tray & bolt rails
	mat_bolt.metallic = 0.94
	mat_bolt.roughness = 0.20

	var mat_box_green := StandardMaterial3D.new()
	mat_box_green.albedo_color = Color(0.19, 0.27, 0.16) # Soviet olive-drab 100rd belt box
	mat_box_green.metallic = 0.52
	mat_box_green.roughness = 0.48

	var mat_box_dark := StandardMaterial3D.new()
	mat_box_dark.albedo_color = Color(0.13, 0.19, 0.11)
	mat_box_dark.metallic = 0.48
	mat_box_dark.roughness = 0.56

	var mat_wood := _create_birch_wood_material()

	var mat_bakelite := StandardMaterial3D.new()
	mat_bakelite.albedo_color = Color(0.42, 0.17, 0.07) # Ribbed Soviet orange-brown bakelite grip
	mat_bakelite.roughness = 0.42
	mat_bakelite.metallic = 0.05

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.26)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.84, 0.44, 0.19)
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.018, 0.018, 0.022)
	mat_bore.roughness = 0.95

	# ==========================================
	# 1. RIVETED STAMPED RECEIVER, FEED TRAY & SKELETONIZED WOOD STOCK
	# ==========================================
	_add_box(root, "ReceiverMain", Vector3(0.064, 0.074, 0.325), Vector3(0, 0.0, -0.062), mat_steel)
	# Internal machined steel belt feed tray (visible when TopCover flips open!)
	_add_box(root, "InternalFeedTray", Vector3(0.054, 0.010, 0.165), Vector3(0, 0.034, -0.095), mat_bolt)
	_add_box(root, "FeedChannelDark", Vector3(0.036, 0.012, 0.140), Vector3(0, 0.032, -0.095), mat_bore)

	# Side receiver stiffening ribs, rivets, left dovetail rail & hinged ejection dust flap
	for sx in [-0.033, 0.033]:
		_add_box(root, "RecSideRib", Vector3(0.004, 0.014, 0.235), Vector3(sx, -0.016, -0.065), mat_steel_dark)
		for rz in [-0.195, -0.145, -0.045, 0.035, 0.088]:
			_add_cyl(root, "RecRivet", 0.0036, 0.0036, 0.005, Vector3(sx, 0.014 if rz < 0.0 else -0.006, rz), mat_steel_dark, 6, Vector3(0, 0, 90))
	_add_box(root, "LeftDovetailRail", Vector3(0.008, 0.018, 0.115), Vector3(-0.036, 0.012, 0.012), mat_steel_dark)
	_add_box(root, "EjectDustFlap", Vector3(0.005, 0.024, 0.078), Vector3(-0.034, 0.002, -0.105), mat_steel_dark)
	_add_box(root, "FeedPortChuteR", Vector3(0.012, 0.026, 0.086), Vector3(0.035, 0.010, -0.115), mat_steel_dark)

	# Iconic PKM Skeletonized Cutout Laminated Birch Buttstock + Hinged Steel Shoulder Rest!
	_add_box(root, "StockTrunnion", Vector3(0.052, 0.056, 0.036), Vector3(0, -0.006, 0.112), mat_steel_dark)
	_add_box(root, "StockTopBeam", Vector3(0.042, 0.028, 0.235), Vector3(0, -0.008, 0.230), mat_wood, Vector3(4.0, 0, 0))
	_add_box(root, "StockBotBeam", Vector3(0.038, 0.026, 0.235), Vector3(0, -0.068, 0.228), mat_wood, Vector3(11.0, 0, 0))
	_add_box(root, "StockFrontBridge", Vector3(0.040, 0.058, 0.046), Vector3(0, -0.028, 0.138), mat_wood)
	_add_box(root, "StockRearBridge", Vector3(0.042, 0.098, 0.042), Vector3(0, -0.044, 0.335), mat_wood)
	_add_box(root, "ButtPlateSteel", Vector3(0.044, 0.104, 0.014), Vector3(0, -0.046, 0.360), mat_steel_dark)
	_add_box(root, "ShoulderRestFlap", Vector3(0.044, 0.008, 0.068), Vector3(0, 0.008, 0.326), mat_steel_dark)

	# Contoured Ribbed Bakelite Pistol Grip & Sculpted Trigger Guard
	_add_box(root, "GripFerrule", Vector3(0.038, 0.010, 0.052), Vector3(0, -0.038, 0.058), mat_steel_dark)
	var grip := _add_box(root, "PistolGrip", Vector3(0.034, 0.108, 0.046), Vector3(0, -0.088, 0.072), mat_bakelite, Vector3(-18.0, 0, 0))
	for gy in [-0.030, -0.010, 0.010, 0.030]:
		_add_box(grip, "GripRib", Vector3(0.036, 0.004, 0.038), Vector3(0, gy, 0), mat_steel_dark)
	_add_box(root, "TriggerGuardFront", Vector3(0.020, 0.034, 0.006), Vector3(0, -0.054, -0.018), mat_steel_dark)
	_add_box(root, "TriggerGuardBow", Vector3(0.020, 0.006, 0.064), Vector3(0, -0.070, 0.014), mat_steel_dark)
	_add_box(root, "Trigger", Vector3(0.007, 0.024, 0.009), Vector3(0, -0.052, 0.020), mat_bolt, Vector3(-18.0, 0, 0))

	# ==========================================
	# 2. HINGED TOP FEED COVER ("TopCover") + WINDAGE TANGENT REAR SIGHT (y = +0.072)
	# ==========================================
	var top_cover := Node3D.new()
	top_cover.name = "TopCover"
	top_cover.position = Vector3(0, 0.037, -0.215) # Hinged cleanly at front trunnion!
	root.add_child(top_cover)
	_add_box(top_cover, "CoverPlateMain", Vector3(0.062, 0.018, 0.295), Vector3(0, 0.009, 0.148), mat_steel)
	_add_box(top_cover, "CoverCrown", Vector3(0.044, 0.008, 0.275), Vector3(0, 0.021, 0.148), mat_steel)
	# Stamped reinforcement ribs on top cover
	for crz in [0.055, 0.115, 0.175]:
		_add_box(top_cover, "CoverRib", Vector3(0.064, 0.005, 0.014), Vector3(0, 0.016, crz), mat_steel_dark)
	# Cover rear latch button
	_add_box(top_cover, "CoverLatch", Vector3(0.022, 0.014, 0.016), Vector3(0, 0.006, 0.302), mat_steel_dark)
	# Precision PKM windage rear tangent sight (notch aligned at model-local y = +0.072 -> cover-local y = +0.035!)
	_add_box(top_cover, "RearSightBase", Vector3(0.030, 0.012, 0.048), Vector3(0, 0.026, 0.242), mat_steel_dark)
	_add_box(top_cover, "RearSightNotchBase", Vector3(0.022, 0.005, 0.008), Vector3(0, 0.033, 0.262), mat_bore)
	_add_box(top_cover, "RearSightL", Vector3(0.0075, 0.009, 0.008), Vector3(-0.0075, 0.038, 0.262), mat_bore)
	_add_box(top_cover, "RearSightR", Vector3(0.0075, 0.009, 0.008), Vector3(0.0075, 0.038, 0.262), mat_bore)
	_add_cyl(top_cover, "WindageKnob", 0.0055, 0.0055, 0.010, Vector3(0.018, 0.033, 0.262), mat_bolt, 10, Vector3(0, 0, 90))

	# ==========================================
	# 3. HEAVY FLUTED BARREL, GAS REGULATOR, CARRY HANDLE, BIPOD & FLASH HIDER
	# ==========================================
	_add_cyl(root, "BarrelChamber", 0.0185, 0.020, 0.095, Vector3(0, 0.024, -0.265), mat_steel, 16)
	_add_cyl(root, "HeavyBarrel", 0.0132, 0.0175, 0.495, Vector3(0, 0.024, -0.550), mat_steel, 18)
	# 6 longitudinal PKM barrel cooling flutes!
	for f_idx in range(6):
		var fa: float = float(f_idx) * (TAU / 6.0)
		_add_cyl(root, "BarrelFlute_%d" % f_idx, 0.0022, 0.0022, 0.360, Vector3(cos(fa) * 0.0155, 0.024 + sin(fa) * 0.0155, -0.495), mat_steel_dark, 6)

	# Underbarrel Gas Cylinder, Multi-Position Regulator & Cleaning Rod
	_add_cyl(root, "GasTube", 0.0128, 0.0128, 0.355, Vector3(0, -0.012, -0.400), mat_steel_dark, 14)
	_add_box(root, "GasBlockCollar", Vector3(0.028, 0.062, 0.044), Vector3(0, 0.006, -0.562), mat_steel)
	_add_cyl(root, "GasRegulator", 0.010, 0.010, 0.024, Vector3(0, -0.012, -0.592), mat_bolt, 10)

	# Classic PKM Slotted Flash Hider + Dark Rifled Bore!
	_add_cyl(root, "FlashHiderBase", 0.015, 0.014, 0.024, Vector3(0, 0.024, -0.805), mat_steel_dark, 14)
	_add_cyl(root, "FlashHiderBody", 0.018, 0.0155, 0.064, Vector3(0, 0.024, -0.848), mat_steel_dark, 14)
	for sl_ang in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var sr: float = deg_to_rad(sl_ang)
		_add_box(root, "FlashSlot", Vector3(0.005, 0.005, 0.040), Vector3(cos(sr) * 0.0165, 0.024 + sin(sr) * 0.0165, -0.850), mat_bore)
	_add_cyl(root, "MuzzleBore", 0.011, 0.011, 0.016, Vector3(0, 0.024, -0.878), mat_bore, 12)

	# Front Sight Tower with Protective Ears & Crisp Front Post (tip aligned at y = +0.072!)
	_add_box(root, "FrontSightBase", Vector3(0.022, 0.036, 0.032), Vector3(0, 0.042, -0.765), mat_steel)
	_add_box(root, "FrontSightEarL", Vector3(0.004, 0.028, 0.014), Vector3(-0.010, 0.068, -0.765), mat_steel_dark)
	_add_box(root, "FrontSightEarR", Vector3(0.004, 0.028, 0.014), Vector3(0.010, 0.068, -0.765), mat_steel_dark)
	_add_box(root, "FrontSightPost", Vector3(0.003, 0.018, 0.006), Vector3(0, 0.063, -0.765), mat_bore)

	# Iconic Angled Wooden Carry Handle (canting left so iron sight picture stays 100% unobstructed!)
	_add_box(root, "CarryCollar", Vector3(0.032, 0.032, 0.018), Vector3(0, 0.024, -0.255), mat_steel_dark)
	_add_box(root, "CarryWireRear", Vector3(0.008, 0.056, 0.009), Vector3(-0.024, 0.044, -0.258), mat_steel, Vector3(0, 0, 34.0))
	_add_box(root, "CarryWireFront", Vector3(0.008, 0.056, 0.009), Vector3(-0.024, 0.044, -0.365), mat_steel, Vector3(0, 0, 34.0))
	_add_cyl(root, "CarryGripWood", 0.0125, 0.0125, 0.106, Vector3(-0.042, 0.068, -0.312), mat_wood, 12)
	for fz in [-0.262, -0.362]:
		_add_cyl(root, "CarryFerrule", 0.0135, 0.0135, 0.010, Vector3(-0.042, 0.068, fz), mat_steel_dark, 12)

	# Folded Stamped-Steel PKM Bipod with Ribbed Ski Feet!
	_add_box(root, "BipodSwivelCollar", Vector3(0.034, 0.022, 0.026), Vector3(0, -0.024, -0.555), mat_steel_dark)
	for sx in [-1.0, 1.0]:
		_add_cyl(root, "BipodLeg", 0.0062, 0.0062, 0.295, Vector3(0.026 * sx, -0.034, -0.415), mat_steel, 10)
		_add_box(root, "BipodSkiFoot", Vector3(0.018, 0.012, 0.044), Vector3(0.028 * sx, -0.036, -0.268), mat_steel_dark)

	# ==========================================
	# 4. ANIMATED RIGHT-SIDE HOOKED CHARGING HANDLE ("ChargingHandle")
	# ==========================================
	var ch := Node3D.new()
	ch.name = "ChargingHandle"
	ch.position = Vector3(0.038, 0.006, -0.055)
	root.add_child(ch)
	_add_box(ch, "HandleSlide", Vector3(0.014, 0.014, 0.034), Vector3(0.0, 0, 0), mat_steel_dark)
	_add_cyl(ch, "HandleStem", 0.005, 0.005, 0.026, Vector3(0.014, 0.004, 0.0), mat_steel, 8, Vector3(0, 0, 90))
	_add_cyl(ch, "HandleKnob", 0.0075, 0.0065, 0.022, Vector3(0.026, 0.012, 0.0), mat_bolt, 10, Vector3.ZERO)

	# ==========================================
	# 5. UNDER-MOUNTED 100RD OLIVE STEEL AMMO BOX ("AmmoBox") + LINKED 7.62x54R BELT!
	# ==========================================
	var ammo_box := Node3D.new()
	ammo_box.name = "AmmoBox"
	ammo_box.position = Vector3(0.012, -0.106, -0.115)
	root.add_child(ammo_box)
	_add_box(ammo_box, "BoxMain", Vector3(0.092, 0.136, 0.148), Vector3.ZERO, mat_box_green)
	_add_box(ammo_box, "BoxTopLid", Vector3(0.098, 0.016, 0.154), Vector3(0, 0.068, 0), mat_box_dark)
	# Horizontal stamped stiffening ribs + latch clasp
	for ry in [-0.042, 0.0, 0.036]:
		_add_box(ammo_box, "BoxRib", Vector3(0.098, 0.010, 0.132), Vector3(0, ry, 0), mat_box_dark)
	_add_box(ammo_box, "BoxLatchFront", Vector3(0.024, 0.032, 0.010), Vector3(0, 0.048, -0.076), mat_steel_dark)
	_add_box(ammo_box, "BoxLatchRear", Vector3(0.024, 0.032, 0.010), Vector3(0, 0.048, 0.076), mat_steel_dark)

	# 8 gleaming brass/copper 7.62x54R cartridges in steel links curving smoothly up into right feedway!
	for i in range(8):
		var frac: float = float(i) / 7.0
		var bx: float = lerpf(0.038, 0.022, frac) + sin(frac * PI) * 0.016
		var by: float = lerpf(0.072, 0.128, frac)
		var rnd := _build_762x54r_round(mat_brass, mat_copper, mat_steel_dark)
		rnd.name = "BeltRound_%d" % i
		rnd.position = Vector3(bx, by, 0.0)
		rnd.rotation_degrees = Vector3(0, 0, lerpf(16.0, -32.0, frac))
		ammo_box.add_child(rnd)

	# ==========================================
	# 6. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.024, -0.895)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(-0.044, 0.008, -0.105)
	root.add_child(eject)

	return root
