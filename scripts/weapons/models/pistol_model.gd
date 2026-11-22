class_name PistolModel
extends RefCounted

# High-Fidelity Procedural Tactical Glock-17 Gen5 / Combat Sidearm
# Shared across First-Person Viewmodel, Handbook Inspector, Shop & Blue Scout Enemies.
# Features:
# - Two-tone beveled machined steel slide ("Slide") with angled front/rear cocking serrations
# - Deep recessed ejection port exposing brushed stainless barrel hood & crowned steel barrel
# - Glowing tritium 3-dot combat iron sights (green front / crisp white rear)
# - Polymer frame with 3-slot underbarrel Picatinny rail, slide stop lever, takedown tabs & undercut guard
# - Stippled ergonomic grip with backstrap swell, finger contours & flared magwell
# - Removable double-stack steel magazine ("Magazine") with brass top cartridge peek & extended basepad
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

static func create(mat_slide_override: Material = null, mat_frame_override: Material = null) -> Node3D:
	var root := Node3D.new()
	root.name = "PistolModel"
	
	var mat_slide: Material = mat_slide_override
	if not mat_slide:
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.18, 0.19, 0.22) # Satin DLC-coated tactical slide
		ms.metallic = 0.88
		ms.roughness = 0.24
		mat_slide = ms
		
	var mat_frame: Material = mat_frame_override
	if not mat_frame:
		var mf := StandardMaterial3D.new()
		mf.albedo_color = Color(0.10, 0.11, 0.12) # Matte tactical polymer frame
		mf.metallic = 0.12
		mf.roughness = 0.68
		mat_frame = mf
		
	var mat_grip_stipple := StandardMaterial3D.new()
	mat_grip_stipple.albedo_color = Color(0.07, 0.08, 0.09)
	mat_grip_stipple.roughness = 0.90
	
	var mat_barrel := StandardMaterial3D.new()
	mat_barrel.albedo_color = Color(0.76, 0.78, 0.82) # Brushed match stainless barrel
	mat_barrel.metallic = 0.96
	mat_barrel.roughness = 0.18
	
	var mat_dark_steel := StandardMaterial3D.new()
	mat_dark_steel.albedo_color = Color(0.07, 0.075, 0.085)
	mat_dark_steel.metallic = 0.82
	mat_dark_steel.roughness = 0.38
	
	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.02, 0.02, 0.025)
	mat_bore.roughness = 0.95
	
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.90, 0.74, 0.24)
	mat_brass.metallic = 0.92
	mat_brass.roughness = 0.20
	
	var mat_tritium_front := StandardMaterial3D.new()
	mat_tritium_front.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_tritium_front.albedo_color = Color(0.28, 1.0, 0.42) # Bright green night sight front dot
	
	var mat_tritium_rear := StandardMaterial3D.new()
	mat_tritium_rear.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_tritium_rear.albedo_color = Color(0.92, 0.98, 0.95)

	# ==========================================
	# 1. RECIPROCATING BEVELED STEEL SLIDE ("Slide")
	# ==========================================
	var slide := MeshInstance3D.new()
	slide.name = "Slide"
	var sl_m := BoxMesh.new()
	sl_m.size = Vector3(0.033, 0.031, 0.205)
	slide.mesh = sl_m
	slide.material_override = mat_slide
	slide.position = Vector3(0, 0.020, 0.0)
	root.add_child(slide)
	
	# Top chamfered slide crown
	_add_box(slide, "SlideCrown", Vector3(0.025, 0.005, 0.202), Vector3(0, 0.017, 0), mat_slide)
	# Rear & front angled cocking serrations (5 rear, 4 front)
	for i in range(5):
		_add_box(slide, "RearSer_%d" % i, Vector3(0.0345, 0.022, 0.0032), Vector3(0, 0.0, 0.044 + float(i) * 0.009), mat_dark_steel, Vector3(12.0, 0, 0))
	for i in range(4):
		_add_box(slide, "FrontSer_%d" % i, Vector3(0.0345, 0.020, 0.0030), Vector3(0, 0.0, -0.056 - float(i) * 0.0085), mat_dark_steel, Vector3(12.0, 0, 0))
	# Recessed ejection port + extractor claw
	_add_box(slide, "EjectCutout", Vector3(0.012, 0.016, 0.044), Vector3(0.013, 0.009, 0.006), mat_bore)
	_add_box(slide, "Extractor", Vector3(0.004, 0.006, 0.026), Vector3(0.016, 0.006, 0.038), mat_dark_steel)
	# Rear slide cover plate
	_add_box(slide, "BackPlate", Vector3(0.028, 0.026, 0.004), Vector3(0, 0.0, 0.103), mat_dark_steel)
	
	# Rear Dovetail Combat Notch Sight with dual tritium dots
	_add_box(slide, "RearSightL", Vector3(0.009, 0.012, 0.013), Vector3(-0.009, 0.023, 0.088), mat_dark_steel)
	_add_box(slide, "RearSightR", Vector3(0.009, 0.012, 0.013), Vector3(0.009, 0.023, 0.088), mat_dark_steel)
	_add_box(slide, "RearSightBase", Vector3(0.027, 0.005, 0.013), Vector3(0, 0.019, 0.088), mat_dark_steel)
	for dx in [-0.009, 0.009]:
		_add_box(slide, "RearTritium", Vector3(0.0032, 0.0032, 0.002), Vector3(dx, 0.024, 0.095), mat_tritium_rear)
	
	# Front Tritium Night Sight Blade
	_add_box(slide, "FrontSight", Vector3(0.0055, 0.012, 0.014), Vector3(0, 0.023, -0.090), mat_dark_steel)
	_add_box(slide, "FrontTritium", Vector3(0.0034, 0.0034, 0.002), Vector3(0, 0.024, -0.0825), mat_tritium_front)

	# ==========================================
	# 2. MATCH STAINLESS BARREL, CHAMBER HOOD & GUIDE ROD
	# ==========================================
	_add_box(root, "BarrelHood", Vector3(0.023, 0.018, 0.042), Vector3(0.002, 0.025, 0.006), mat_barrel)
	_add_cyl(root, "Barrel", 0.0085, 0.0085, 0.132, Vector3(0, 0.023, -0.048), mat_barrel, 12)
	_add_cyl(root, "MuzzleCrown", 0.0090, 0.0090, 0.010, Vector3(0, 0.023, -0.106), mat_barrel, 12)
	_add_cyl(root, "MuzzleBore", 0.0060, 0.0060, 0.008, Vector3(0, 0.023, -0.111), mat_bore, 10)
	_add_cyl(root, "GuideRod", 0.0045, 0.0045, 0.092, Vector3(0, 0.008, -0.056), mat_dark_steel, 8)

	# ==========================================
	# 3. POLYMER FRAME, UNDERBARREL PICATINNY RAIL & CONTROLS
	# ==========================================
	_add_box(root, "FrameBody", Vector3(0.031, 0.021, 0.184), Vector3(0, -0.005, 0.006), mat_frame)
	# Beavertail rear tang
	_add_box(root, "Beavertail", Vector3(0.028, 0.012, 0.028), Vector3(0, -0.003, 0.098), mat_frame, Vector3(-18.0, 0, 0))
	# Underbarrel 3-slot Picatinny accessory rail
	_add_box(root, "RailSpine", Vector3(0.022, 0.006, 0.058), Vector3(0, -0.017, -0.056), mat_frame)
	for i in range(3):
		_add_box(root, "RailSlot_%d" % i, Vector3(0.024, 0.004, 0.006), Vector3(0, -0.020, -0.038 - float(i) * 0.016), mat_grip_stipple)
	# Slide stop lever, takedown lock & magazine release button
	_add_box(root, "SlideStop", Vector3(0.004, 0.008, 0.030), Vector3(-0.017, 0.002, 0.022), mat_dark_steel)
	_add_box(root, "TakedownTab", Vector3(0.035, 0.007, 0.008), Vector3(0, -0.005, -0.020), mat_dark_steel)
	_add_box(root, "MagReleaseBtn", Vector3(0.005, 0.011, 0.011), Vector3(-0.016, -0.028, 0.026), mat_dark_steel)
	
	# Squared combat trigger guard (hollow loop) & trigger with safety blade
	_add_box(root, "GuardBottom", Vector3(0.014, 0.005, 0.054), Vector3(0, -0.044, -0.008), mat_frame)
	_add_box(root, "GuardFront", Vector3(0.014, 0.030, 0.006), Vector3(0, -0.030, -0.034), mat_frame)
	_add_box(root, "Trigger", Vector3(0.006, 0.022, 0.009), Vector3(0, -0.026, 0.002), mat_dark_steel, Vector3(-22.0, 0, 0))

	# ==========================================
	# 4. STIPPLED ERGONOMIC GRIP & FLARED MAGWELL
	# ==========================================
	var grip := _add_box(root, "Grip", Vector3(0.030, 0.116, 0.052), Vector3(0, -0.064, 0.052), mat_frame, Vector3(-20.0, 0, 0))
	# Textured side stipple grip panels
	for sx in [-0.0155, 0.0155]:
		_add_box(grip, "StipplePanel", Vector3(0.002, 0.088, 0.038), Vector3(sx, -0.004, 0.0), mat_grip_stipple)
	# Finger grooves on front strap
	for gy in [-0.024, 0.0, 0.024]:
		_add_box(grip, "FingerGroove", Vector3(0.028, 0.007, 0.005), Vector3(0, gy, -0.027), mat_grip_stipple)
	# Flared tactical magwell collar at bottom of grip
	_add_box(grip, "FlaredMagwell", Vector3(0.035, 0.012, 0.058), Vector3(0, -0.055, 0.0), mat_dark_steel)

	# ==========================================
	# 5. REMOVABLE DOUBLE-STACK MAGAZINE ("Magazine")
	# ==========================================
	var mag_node := MeshInstance3D.new()
	mag_node.name = "Magazine"
	mag_node.position = Vector3(0, -0.068, 0.053)
	mag_node.rotation_degrees = Vector3(-20.0, 0, 0)
	root.add_child(mag_node)
	
	_add_box(mag_node, "MagTube", Vector3(0.024, 0.112, 0.040), Vector3(0, 0.0, 0.0), mat_dark_steel)
	# Top 9mm brass cartridge peeking out of feed lips!
	_add_cyl(mag_node, "TopCartridge", 0.0045, 0.0045, 0.024, Vector3(0, 0.056, -0.003), mat_brass, 8)
	# Extended ergonomic tactical basepad
	_add_box(mag_node, "Basepad", Vector3(0.033, 0.016, 0.054), Vector3(0, -0.062, 0.002), mat_frame)
	_add_box(mag_node, "BasepadLip", Vector3(0.034, 0.005, 0.056), Vector3(0, -0.068, 0.002), mat_grip_stipple)

	# ==========================================
	# 6. MARKERS (MUZZLE & EJECTION PORT)
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.023, -0.125)
	root.add_child(muzzle)
	
	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.026, 0.030, 0.006)
	root.add_child(eject)

	return root
