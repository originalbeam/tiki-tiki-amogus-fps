class_name AK47Model
extends RefCounted

# High-Fidelity Procedural AKM / AK-47 Assault Rifle Model
# Shared across First-Person Viewmodel, Workbench 3D Modding, Handbook Inspector, Shop & Enemies.
# Features:
# - Stamped steel receiver with magwell dimples, rivets, fire selector lever & trigger assembly
# - Removable ribbed steel dust cover (strippable to reveal bolt channel & coiled recoil spring!)
# - Reciprocating polished steel bolt carrier & hooked charging handle ("ChargingHandle")
# - Two-piece Soviet laminated birch handguards with louvers, steel ferrules & cleaning rod
# - 45-degree gas block, hooded front sight ears/post & AKM slant muzzle brake with dark bore
# - Contoured hardwood buttstock with steel buttplate & checkered bakelite pistol grip
# - Ribbed curved 30-round magazine ("Magazine") pivoted at magwell for rock-and-lock reload
# - Modular attachment system: Picatinny dust cover, EOTech 1x holographic sight & LPVO 1.5-4x PiP scope
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

static func create(mat_metal_override: Material = null, mat_wood_override: Material = null, mat_mag_override: Material = null) -> Node3D:
	var root := Node3D.new()
	root.name = "AK47Model"
	
	# Rich PBR Material Palette (RPG-7+ craft standard)
	var mat_steel: Material = mat_metal_override
	if not mat_steel:
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.14, 0.15, 0.17) # Blued/parkerized Soviet stamped steel
		ms.metallic = 0.88
		ms.roughness = 0.34
		mat_steel = ms
		
	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.08, 0.09, 0.10)
	mat_steel_dark.metallic = 0.80
	mat_steel_dark.roughness = 0.44
	
	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.76, 0.78, 0.82) # Machined stainless bolt carrier
	mat_bolt.metallic = 0.96
	mat_bolt.roughness = 0.18
	
	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.02, 0.02, 0.025)
	mat_bore.roughness = 0.95
	
	var mat_wood: Material = mat_wood_override
	if not mat_wood:
		var mw := StandardMaterial3D.new()
		mw.albedo_color = Color(0.50, 0.23, 0.09) # Rich Soviet laminated amber birch
		mw.roughness = 0.48
		mw.metallic = 0.04
		mat_wood = mw
		
	var mat_wood_dark := StandardMaterial3D.new()
	mat_wood_dark.albedo_color = Color(0.36, 0.16, 0.06)
	mat_wood_dark.roughness = 0.56
	
	var mat_bakelite := StandardMaterial3D.new()
	mat_bakelite.albedo_color = Color(0.34, 0.13, 0.06) # Checkered bakelite grip
	mat_bakelite.roughness = 0.44
	mat_bakelite.metallic = 0.05
	
	var mat_mag: Material = mat_mag_override
	if not mat_mag:
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.16, 0.17, 0.19) # Ribbed stamped steel magazine
		mm.metallic = 0.84
		mm.roughness = 0.36
		mat_mag = mm

	# ==========================================
	# 1. STAMPED RECEIVER, RIVETS & FIRE SELECTOR
	# ==========================================
	_add_box(root, "ReceiverBody", Vector3(0.046, 0.060, 0.255), Vector3(0, 0.002, 0.012), mat_steel)
	# Front & rear trunnion reinforcements
	_add_box(root, "FrontTrunnion", Vector3(0.049, 0.058, 0.042), Vector3(0, 0.006, -0.105), mat_steel_dark)
	_add_box(root, "RearTrunnion", Vector3(0.048, 0.054, 0.028), Vector3(0, 0.002, 0.132), mat_steel_dark)
	# Magwell receiver dimples on left & right sides
	for sx in [-0.0235, 0.0235]:
		_add_box(root, "MagwellDimple", Vector3(0.003, 0.018, 0.046), Vector3(sx, -0.012, -0.055), mat_steel_dark)
		# Stamped receiver rivets
		for rz in [-0.112, -0.095, 0.018, 0.045, 0.126]:
			_add_cyl(root, "Rivet", 0.0032, 0.0032, 0.004, Vector3(sx, -0.006 if rz > 0.0 else 0.012, rz), mat_steel_dark, 6, Vector3(0, 0, 90))
	
	# Recessed ejection port channel (right side)
	_add_box(root, "EjectRecess", Vector3(0.010, 0.022, 0.105), Vector3(0.022, 0.020, -0.032), mat_bore)
	
	# Iconic AK right-side stamped steel fire selector lever & pivot
	var selector := _add_box(root, "FireSelector", Vector3(0.004, 0.014, 0.115), Vector3(0.026, 0.005, 0.020), mat_steel_dark, Vector3(4.0, 0.0, 0.0))
	_add_box(selector, "SelectorTab", Vector3(0.010, 0.008, 0.016), Vector3(0.004, -0.002, -0.052), mat_steel_dark)
	_add_cyl(root, "SelectorPivot", 0.007, 0.007, 0.008, Vector3(0.025, 0.004, 0.074), mat_steel_dark, 8, Vector3(0, 0, 90))
	
	# Trigger guard loop, magazine catch paddle & curved trigger
	_add_box(root, "TriggerGuardBottom", Vector3(0.014, 0.005, 0.068), Vector3(0, -0.056, 0.018), mat_steel)
	_add_box(root, "TriggerGuardFront", Vector3(0.014, 0.030, 0.006), Vector3(0, -0.042, -0.015), mat_steel)
	_add_box(root, "MagReleasePaddle", Vector3(0.012, 0.024, 0.007), Vector3(0, -0.042, -0.024), mat_steel_dark, Vector3(-16.0, 0, 0))
	_add_box(root, "Trigger", Vector3(0.006, 0.024, 0.009), Vector3(0, -0.041, 0.022), mat_steel_dark, Vector3(-22.0, 0, 0))

	# ==========================================
	# 2. REMOVABLE RIBBED DUST COVER (Moddable!)
	# ==========================================
	var dust_cover := _add_box(root, "ReceiverTop", Vector3(0.042, 0.024, 0.242), Vector3(0, 0.040, 0.018), mat_steel)
	# Chamfered top crown ridge
	_add_box(dust_cover, "CoverCrown", Vector3(0.030, 0.008, 0.236), Vector3(0, 0.013, 0.0), mat_steel)
	# Rear recoil spring lock button protruding out back of dust cover
	_add_box(dust_cover, "RecoilButton", Vector3(0.012, 0.011, 0.012), Vector3(0, 0.001, 0.124), mat_steel_dark)
	# Ribbed reinforcement ribs (hidden when stripped or Picatinny installed)
	_add_box(root, "TopCoverRib1", Vector3(0.0445, 0.005, 0.014), Vector3(0, 0.045, -0.02), mat_steel_dark)
	_add_box(root, "TopCoverRib2", Vector3(0.0445, 0.005, 0.014), Vector3(0, 0.045, 0.055), mat_steel_dark)

	# ==========================================
	# 3. RECIPROCATING BOLT CARRIER & CHARGING HANDLE
	# ==========================================
	var bolt_group := MeshInstance3D.new()
	bolt_group.name = "ChargingHandle"
	var bolt_bm := BoxMesh.new()
	bolt_bm.size = Vector3(0.016, 0.018, 0.095)
	bolt_group.mesh = bolt_bm
	bolt_group.material_override = mat_bolt
	bolt_group.position = Vector3(0.020, 0.020, -0.040)
	root.add_child(bolt_group)
	# Hooked cylindrical charging handle knob extending to right
	_add_cyl(bolt_group, "HandleStem", 0.005, 0.0055, 0.026, Vector3(0.016, 0.001, -0.020), mat_bolt, 8, Vector3(0, 0, 90))
	_add_cyl(bolt_group, "HandleKnob", 0.0065, 0.005, 0.010, Vector3(0.030, 0.003, -0.020), mat_bolt, 8, Vector3(0, 0, 75))

	# ==========================================
	# 4. REAR SIGHT BLOCK, HANDGUARDS, GAS TUBE & BARREL
	# ==========================================
	# Rear tangent sight block & stepped slider leaf
	_add_box(root, "RearSightBase", Vector3(0.034, 0.028, 0.068), Vector3(0, 0.041, -0.140), mat_steel_dark)
	_add_box(root, "RearSightLeaf", Vector3(0.018, 0.007, 0.052), Vector3(0, 0.057, -0.142), mat_steel, Vector3(-4.0, 0, 0))
	_add_box(root, "RearSightSlider", Vector3(0.024, 0.009, 0.012), Vector3(0, 0.058, -0.130), mat_bolt)
	
	# Lower & Upper laminated wooden handguards with ventilation louvers
	_add_box(root, "WoodHandguardLow", Vector3(0.052, 0.044, 0.162), Vector3(0, -0.006, -0.232), mat_wood)
	_add_box(root, "WoodHandguardSwellL", Vector3(0.006, 0.020, 0.132), Vector3(-0.027, -0.004, -0.232), mat_wood_dark)
	_add_box(root, "WoodHandguardSwellR", Vector3(0.006, 0.020, 0.132), Vector3(0.027, -0.004, -0.232), mat_wood_dark)
	_add_cyl(root, "WoodHandguardUp", 0.021, 0.021, 0.145, Vector3(0, 0.031, -0.232), mat_wood, 12)
	# Cooling vent slits between upper & lower handguard
	for vz in [-0.270, -0.232, -0.194]:
		_add_box(root, "HandguardVent", Vector3(0.054, 0.007, 0.022), Vector3(0, 0.016, vz), mat_bore)
	# Steel handguard retainer collars & sling loop
	_add_box(root, "RetainerRear", Vector3(0.055, 0.058, 0.012), Vector3(0, 0.014, -0.150), mat_steel_dark)
	_add_box(root, "RetainerFront", Vector3(0.055, 0.058, 0.014), Vector3(0, 0.014, -0.315), mat_steel_dark)
	_add_cyl(root, "FrontSlingLoop", 0.008, 0.008, 0.005, Vector3(-0.031, 0.004, -0.315), mat_steel_dark, 8, Vector3(0, 90, 0))
	
	# Gas tube (exposed forward of handguard) & iconic 45-degree gas block
	_add_cyl(root, "GasTube", 0.0105, 0.0105, 0.215, Vector3(0, 0.033, -0.268), mat_steel, 12)
	_add_box(root, "GasBlockCollar", Vector3(0.024, 0.048, 0.034), Vector3(0, 0.018, -0.376), mat_steel_dark)
	_add_box(root, "GasBlockAngled", Vector3(0.020, 0.034, 0.026), Vector3(0, 0.022, -0.362), mat_steel_dark, Vector3(36.0, 0, 0))
	
	# Heavy chrome-lined steel barrel
	_add_cyl(root, "Barrel", 0.0095, 0.0105, 0.425, Vector3(0, 0.004, -0.335), mat_steel, 14)
	# Underbarrel steel cleaning rod + bayonet lug
	_add_cyl(root, "CleaningRod", 0.0028, 0.0028, 0.345, Vector3(0, -0.016, -0.355), mat_steel_dark, 8)
	_add_box(root, "BayonetLug", Vector3(0.012, 0.014, 0.026), Vector3(0, -0.012, -0.440), mat_steel_dark)
	
	# Hooded Front Sight Base with protective ears & adjustable front post
	_add_box(root, "FrontSightBase", Vector3(0.022, 0.044, 0.030), Vector3(0, 0.022, -0.500), mat_steel_dark)
	_add_box(root, "FrontSightTower", Vector3(0.014, 0.022, 0.018), Vector3(0, 0.046, -0.502), mat_steel_dark)
	_add_box(root, "FrontSightEarL", Vector3(0.0035, 0.024, 0.014), Vector3(-0.009, 0.058, -0.502), mat_steel)
	_add_box(root, "FrontSightEarR", Vector3(0.0035, 0.024, 0.014), Vector3(0.009, 0.058, -0.502), mat_steel)
	_add_cyl(root, "FrontSightPost", 0.0018, 0.0018, 0.020, Vector3(0, 0.056, -0.502), mat_steel_dark, 6, Vector3.ZERO)
	
	# Iconic AKM Slant Muzzle Compensator + dark bore recess
	_add_cyl(root, "MuzzleCollar", 0.0125, 0.0125, 0.018, Vector3(0, 0.004, -0.532), mat_steel_dark, 12)
	var brake := _add_cyl(root, "SlantBrake", 0.012, 0.012, 0.032, Vector3(0, 0.004, -0.554), mat_steel_dark, 12)
	brake.rotation_degrees = Vector3(-90.0, 0.0, 12.0)
	_add_cyl(root, "MuzzleBore", 0.0075, 0.0075, 0.010, Vector3(0, 0.004, -0.568), mat_bore, 10)

	# ==========================================
	# 5. HARDWOOD BUTTSTOCK & BAKELITE PISTOL GRIP
	# ==========================================
	var stock_root := Node3D.new()
	stock_root.name = "Stock"
	stock_root.position = Vector3(0, -0.008, 0.142)
	root.add_child(stock_root)
	# Neck & tapered buttstock body
	_add_box(stock_root, "StockNeck", Vector3(0.040, 0.052, 0.065), Vector3(0, -0.008, 0.030), mat_wood, Vector3(12.0, 0, 0))
	_add_box(stock_root, "StockMain", Vector3(0.042, 0.098, 0.205), Vector3(0, -0.036, 0.145), mat_wood, Vector3(9.0, 0, 0))
	_add_box(stock_root, "StockComb", Vector3(0.036, 0.022, 0.185), Vector3(0, 0.014, 0.145), mat_wood_dark, Vector3(9.0, 0, 0))
	# Ribbed steel buttplate + rear sling swivel
	_add_box(stock_root, "ButtPlate", Vector3(0.044, 0.106, 0.014), Vector3(0, -0.052, 0.250), mat_steel_dark, Vector3(9.0, 0, 0))
	_add_cyl(stock_root, "RearSlingSwivel", 0.008, 0.008, 0.005, Vector3(0, -0.092, 0.195), mat_steel_dark, 8, Vector3(0, 90, 0))
	
	# Contoured Checkered Bakelite Pistol Grip + steel ferrule
	_add_box(root, "GripFerrule", Vector3(0.034, 0.010, 0.048), Vector3(0, -0.030, 0.064), mat_steel_dark)
	var grip := _add_box(root, "PistolGrip", Vector3(0.031, 0.108, 0.045), Vector3(0, -0.080, 0.082), mat_bakelite, Vector3(-21.0, 0, 0))
	for gy in [-0.028, -0.008, 0.012, 0.030]:
		_add_box(grip, "GripRib", Vector3(0.033, 0.004, 0.034), Vector3(0, gy, 0.0), mat_wood_dark)
	_add_box(grip, "GripButtCap", Vector3(0.032, 0.010, 0.048), Vector3(0, -0.056, 0.002), mat_steel_dark)

	# ==========================================
	# 6. CURVED 30-ROUND RIBBED MAGAZINE (Pivoted at magwell!)
	# ==========================================
	var mag_node := MeshInstance3D.new()
	mag_node.name = "Magazine"
	# Pivot sits right under the magwell so rock-and-lock rotation looks authentic!
	mag_node.position = Vector3(0, -0.042, -0.055)
	root.add_child(mag_node)
	
	# Upper straight section entering magwell
	_add_box(mag_node, "MagUpper", Vector3(0.028, 0.082, 0.064), Vector3(0, -0.034, -0.002), mat_mag, Vector3(8.0, 0, 0))
	# Middle curved section
	_add_box(mag_node, "MagMid", Vector3(0.028, 0.082, 0.064), Vector3(0, -0.104, -0.018), mat_mag, Vector3(20.0, 0, 0))
	# Lower curved section + steel reinforcement floorplate
	_add_box(mag_node, "MagLow", Vector3(0.028, 0.074, 0.064), Vector3(0, -0.168, -0.048), mat_mag, Vector3(31.0, 0, 0))
	_add_box(mag_node, "MagFloorplate", Vector3(0.032, 0.010, 0.070), Vector3(0, -0.204, -0.066), mat_steel_dark, Vector3(31.0, 0, 0))
	# Vertical stamped ribs along sides of magazine
	for rx in [-0.0145, 0.0145]:
		_add_box(mag_node, "MagRibMid", Vector3(0.003, 0.072, 0.008), Vector3(rx, -0.104, -0.018), mat_steel_dark, Vector3(20.0, 0, 0))
		_add_box(mag_node, "MagRibLow", Vector3(0.003, 0.064, 0.008), Vector3(rx, -0.166, -0.048), mat_steel_dark, Vector3(31.0, 0, 0))
	# Front spine reinforcement ridge
	_add_box(mag_node, "MagSpine", Vector3(0.014, 0.076, 0.008), Vector3(0, -0.106, -0.050), mat_steel_dark, Vector3(20.0, 0, 0))

	# ==========================================
	# 7. MARKERS (MUZZLE & EJECTION PORT)
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.004, -0.585)
	root.add_child(muzzle)
	
	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.038, 0.026, -0.025)
	root.add_child(eject)

	return root

# ==========================================
# DYNAMIC WEAPON MODIFICATION VISUALS
# ==========================================

static func create_with_mods(installed_mods: Dictionary) -> Node3D:
	var root := create()
	apply_mods_to_node(root, installed_mods)
	return root

static func apply_mods_to_node(ak_node: Node3D, installed_mods: Dictionary) -> void:
	if not ak_node:
		return
		
	var old_mods := ak_node.get_node_or_null("DynamicMods")
	if old_mods:
		ak_node.remove_child(old_mods)
		old_mods.queue_free()
		
	var mods_root := Node3D.new()
	mods_root.name = "DynamicMods"
	ak_node.add_child(mods_root)
	
	var dust_cover_id: String = str(installed_mods.get("dust_cover", "ak_cover_std"))
	var optic_id: String = str(installed_mods.get("optic", ""))
	
	var has_cover: bool = (dust_cover_id != "")
	for cname in ["ReceiverTop", "TopCoverRib1", "TopCoverRib2"]:
		var n := ak_node.get_node_or_null(cname)
		if n and n is Node3D:
			(n as Node3D).visible = has_cover
			
	var mat_rail := StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.10, 0.11, 0.13)
	mat_rail.metallic = 0.86
	mat_rail.roughness = 0.28
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.68, 0.70, 0.74)
	mat_steel.metallic = 0.94
	mat_steel.roughness = 0.20
	
	var mat_recess := StandardMaterial3D.new()
	mat_recess.albedo_color = Color(0.04, 0.04, 0.05)
	mat_recess.roughness = 0.80
	
	# Stripped dust cover: detailed exposed internal bolt channel, guide rod & coiled recoil spring!
	if not has_cover:
		_add_box(mods_root, "InternalChannel", Vector3(0.036, 0.014, 0.215), Vector3(0, 0.025, 0.018), mat_recess)
		_add_cyl(mods_root, "RecoilGuideRod", 0.0045, 0.0045, 0.210, Vector3(0, 0.035, 0.024), mat_steel, 10)
		for i in range(12):
			_add_cyl(mods_root, "SpringCoil_%d" % i, 0.0072, 0.0072, 0.004, Vector3(0, 0.035, -0.055 + float(i) * 0.015), mat_steel, 10)
		_add_box(mods_root, "ExposedBoltCarrier", Vector3(0.024, 0.018, 0.088), Vector3(0, 0.035, -0.040), mat_steel)
		
	# Picatinny Dust Cover Rail (B-33 / TWS Dog Leg style)
	if dust_cover_id == "ak_cover_picatinny":
		for cname in ["TopCoverRib1", "TopCoverRib2"]:
			var n := ak_node.get_node_or_null(cname)
			if n and n is Node3D:
				(n as Node3D).visible = false
		_add_box(mods_root, "PicatinnyBase", Vector3(0.022, 0.007, 0.208), Vector3(0, 0.058, 0.014), mat_rail)
		_add_box(mods_root, "PicatinnyClampF", Vector3(0.032, 0.012, 0.016), Vector3(0, 0.052, -0.088), mat_rail)
		for i in range(12):
			_add_box(mods_root, "PicLug_%d" % i, Vector3(0.024, 0.0045, 0.009), Vector3(0, 0.063, -0.078 + float(i) * 0.0165), mat_rail)
			
	if optic_id == "optic_red_dot":
		_build_red_dot_optic(mods_root, mat_rail)
	elif optic_id == "optic_lpvo":
		_build_lpvo_optic(mods_root, mat_rail)

static func _create_eotech_lens_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 reticle_color : source_color = vec4(1.0, 0.12, 0.08, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	
	// Seamless 1:1 true holographic EOTech 65-MOA ring + 4 cardinal ticks + 1-MOA center dot
	float dot_mask = 1.0 - smoothstep(0.012, 0.020, d);
	float ring_mask = 1.0 - smoothstep(0.006, 0.013, abs(d - 0.135));
	float tick_x = step(abs(p.y), 0.007) * step(0.105, abs(p.x)) * step(abs(p.x), 0.17);
	float tick_y = step(abs(p.x), 0.007) * step(0.105, abs(p.y)) * step(abs(p.y), 0.17);
	float ret = clamp(dot_mask + ring_mask * 0.85 + (tick_x + tick_y) * 0.85, 0.0, 1.0);
	
	vec3 glass_tint = vec3(0.16, 0.34, 0.36);
	ALBEDO = mix(glass_tint, reticle_color.rgb * 1.45, ret);
	ALPHA = mix(0.09, 0.98, ret);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat

static func _create_lpvo_lens_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;
uniform vec4 reticle_color : source_color = vec4(1.0, 0.16, 0.10, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.495) {
		discard;
	}
	if (r > 0.445) {
		ALBEDO = vec3(0.04, 0.045, 0.05);
		ALPHA = 1.0;
	} else {
		float thick_h = step(abs(p.y), 0.0055) * step(0.18, abs(p.x));
		float thick_v = step(abs(p.x), 0.0055) * step(0.18, p.y);
		float fine_h = step(abs(p.y), 0.0022) * step(0.024, abs(p.x)) * step(abs(p.x), 0.44);
		float fine_v = step(abs(p.x), 0.0022) * step(0.024, abs(p.y)) * step(abs(p.y), 0.44);
		float hash_x = step(abs(p.y), 0.011) * step(0.06, abs(p.x)) * step(abs(p.x), 0.34) * step(abs(fract(abs(p.x) * 16.0 + 0.5) - 0.5), 0.06);
		float hash_y = step(abs(p.x), 0.011) * step(0.06, p.y) * step(p.y, 0.34) * step(abs(fract(p.y * 16.0 + 0.5) - 0.5), 0.06);
		float black_ret = clamp(thick_h + thick_v + fine_h + fine_v + hash_x + hash_y, 0.0, 1.0);
		
		float center_dot = 1.0 - smoothstep(0.007, 0.012, r);
		float horseshoe = (1.0 - smoothstep(0.004, 0.009, abs(r - 0.042))) * step(p.y, 0.022);
		float illum_ret = clamp(center_dot + horseshoe * 0.9, 0.0, 1.0);
		float vig = smoothstep(0.37, 0.445, r);
		
		if (use_pip) {
			vec2 pip_uv = clamp(UV, vec2(0.01), vec2(0.99));
			vec3 world_col = texture(pip_tex, pip_uv).rgb;
			vec3 col = mix(world_col, vec3(0.02, 0.02, 0.025), black_ret * 0.92);
			col = mix(col, reticle_color.rgb * 1.45, illum_ret);
			col = mix(col, vec3(0.01, 0.012, 0.015), vig * 0.85);
			ALBEDO = col;
			ALPHA = 1.0;
		} else {
			float sheen = smoothstep(0.45, 0.0, length(p - vec2(-0.14, -0.14))) * 0.32;
			vec3 glass = vec3(0.06, 0.24, 0.22) + vec3(0.18, 0.32, 0.28) * sheen;
			glass = mix(glass, vec3(0.02, 0.02, 0.025), black_ret * 0.55);
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

static func _build_red_dot_optic(parent: Node3D, mat_rail: Material) -> void:
	var optic := Node3D.new()
	optic.name = "OpticRedDot"
	optic.position = Vector3(0, 0.064, 0.015)
	parent.add_child(optic)
	
	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.09, 0.10, 0.11)
	mat_body.metallic = 0.76
	mat_body.roughness = 0.32
	
	var mat_accent := StandardMaterial3D.new()
	mat_accent.albedo_color = Color(0.24, 0.25, 0.27)
	mat_accent.metallic = 0.88
	mat_accent.roughness = 0.28
	
	# Low-profile quick-detach Picatinny base + side clamp lever
	_add_box(optic, "Base", Vector3(0.032, 0.009, 0.074), Vector3(0, 0.0045, 0), mat_rail)
	_add_box(optic, "QDLever", Vector3(0.005, 0.008, 0.026), Vector3(-0.018, 0.005, 0.004), mat_accent)
	# Low cylindrical transverse battery cap (EOTech EXPS3 signature, sits completely below glass!)
	_add_cyl(optic, "BatteryTube", 0.0062, 0.0062, 0.038, Vector3(0, 0.0115, -0.024), mat_body, 10, Vector3(0, 0, 90))
	_add_box(optic, "BatteryHousing", Vector3(0.032, 0.011, 0.024), Vector3(0, 0.011, -0.020), mat_body)
	# Lower window sill bar + brightness buttons on side
	_add_box(optic, "Sill", Vector3(0.038, 0.004, 0.038), Vector3(0, 0.0175, 0.008), mat_body)
	# Knurled windage/elevation screws on right side
	_add_cyl(optic, "WindageScrew", 0.0035, 0.0035, 0.005, Vector3(0.020, 0.014, 0.002), mat_accent, 8, Vector3(0, 0, 90))
	_add_cyl(optic, "ElevScrew", 0.0035, 0.0035, 0.005, Vector3(0.020, 0.014, 0.014), mat_accent, 8, Vector3(0, 0, 90))
	# Protective outer aluminum hood arch
	for sx in [-0.018, 0.018]:
		_add_box(optic, "HoodWall", Vector3(0.0045, 0.034, 0.038), Vector3(sx, 0.035, 0.008), mat_body)
	_add_box(optic, "HoodTop", Vector3(0.0405, 0.0045, 0.038), Vector3(0, 0.052, 0.008), mat_body)
	# Clean unobstructed 1:1 holographic glass window
	var glass := MeshInstance3D.new()
	glass.name = "OpticLens"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.0315, 0.030)
	glass.mesh = qm
	glass.material_override = _create_eotech_lens_material()
	glass.position = Vector3(0, 0.035, 0.016)
	optic.add_child(glass)

static func _build_lpvo_optic(parent: Node3D, mat_rail: Material) -> void:
	var optic := Node3D.new()
	optic.name = "OpticLPVO"
	optic.position = Vector3(0, 0.064, 0.005)
	parent.add_child(optic)
	
	var mat_scope := StandardMaterial3D.new()
	mat_scope.albedo_color = Color(0.11, 0.12, 0.13)
	mat_scope.metallic = 0.84
	mat_scope.roughness = 0.26
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.06, 0.06, 0.07)
	mat_rubber.roughness = 0.90
	
	var mat_front_lens := StandardMaterial3D.new()
	mat_front_lens.albedo_color = Color(0.10, 0.38, 0.34, 0.90)
	mat_front_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_front_lens.metallic = 0.72
	mat_front_lens.roughness = 0.05
	
	# Cantilever one-piece tactical rail mount + dual rings
	_add_box(optic, "MountBase", Vector3(0.026, 0.009, 0.115), Vector3(0, 0.0045, 0.0), mat_rail)
	for rz in [-0.044, 0.044]:
		_add_box(optic, "RingStem", Vector3(0.026, 0.024, 0.018), Vector3(0, 0.017, rz), mat_rail)
		_add_cyl(optic, "RingClamp", 0.0195, 0.0195, 0.018, Vector3(0, 0.033, rz), mat_rail, 14)
		
	# Main 30mm anodized tube
	_add_cyl(optic, "MainTube", 0.0155, 0.0155, 0.175, Vector3(0, 0.033, 0.0), mat_scope, 16)
	# Objective bell (front -Z) & multi-coated green objective lens
	_add_cyl(optic, "ObjectiveBell", 0.0205, 0.0155, 0.042, Vector3(0, 0.033, -0.095), mat_scope, 16)
	_add_cyl(optic, "FrontLens", 0.018, 0.018, 0.003, Vector3(0, 0.033, -0.1155), mat_front_lens, 16)
	# Ocular eyepiece, knurled zoom ring & throw lever (rear +Z)
	_add_cyl(optic, "OcularBell", 0.0155, 0.022, 0.048, Vector3(0, 0.033, 0.092), mat_scope, 20)
	_add_cyl(optic, "ZoomRing", 0.0215, 0.0215, 0.014, Vector3(0, 0.033, 0.072), mat_rubber, 16)
	_add_box(optic, "ThrowLever", Vector3(0.005, 0.018, 0.006), Vector3(-0.020, 0.047, 0.072), mat_rubber, Vector3(0, 0, 35.0))
	
	# Real circular see-through ocular glass lens facing player (+Z) with PiP magnification + illuminated reticle
	var ocular_lens := MeshInstance3D.new()
	ocular_lens.name = "OpticLens"
	var olm := QuadMesh.new()
	olm.size = Vector2(0.043, 0.043)
	ocular_lens.mesh = olm
	ocular_lens.material_override = _create_lpvo_lens_material()
	ocular_lens.position = Vector3(0, 0.033, 0.117)
	optic.add_child(ocular_lens)
	
	# Turret saddle + Elevation, Windage & Illumination caps
	_add_box(optic, "Saddle", Vector3(0.036, 0.034, 0.030), Vector3(0, 0.033, 0.0), mat_scope)
	_add_cyl(optic, "ElevTurret", 0.009, 0.009, 0.015, Vector3(0, 0.054, 0.0), mat_scope, 12, Vector3.ZERO)
	_add_cyl(optic, "WindTurret", 0.009, 0.009, 0.015, Vector3(0.022, 0.033, 0.0), mat_scope, 12, Vector3(0, 0, 90))
	_add_cyl(optic, "IllumDial", 0.0085, 0.0085, 0.012, Vector3(-0.021, 0.033, 0.0), mat_rubber, 12, Vector3(0, 0, 90))

static func get_slot_anchor_local(weapon_id: String, slot_type: String) -> Vector3:
	if weapon_id == "ak47":
		match slot_type:
			"dust_cover":
				return Vector3(0.0, 0.056, 0.025)
			"optic":
				return Vector3(0.0, 0.105, 0.005)
	return Vector3.ZERO

static func create_mod_preview(mod_id: String) -> Node3D:
	var wrap := Node3D.new()
	wrap.name = "ModPreview_" + mod_id
	
	var mat_metal := StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.18, 0.19, 0.21)
	mat_metal.metallic = 0.86
	mat_metal.roughness = 0.34
	
	var mat_rail := StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.11, 0.11, 0.12)
	mat_rail.metallic = 0.80
	mat_rail.roughness = 0.32
	
	match mod_id:
		"ak_cover_std":
			_add_box(wrap, "Cover", Vector3(0.044, 0.024, 0.24), Vector3.ZERO, mat_metal)
			for rz in [-0.04, 0.04]:
				_add_box(wrap, "Rib", Vector3(0.046, 0.005, 0.014), Vector3(0, 0.008, rz), mat_rail)
			wrap.scale = Vector3(3.2, 3.2, 3.2)
		"ak_cover_picatinny":
			_add_box(wrap, "Cover", Vector3(0.044, 0.024, 0.24), Vector3.ZERO, mat_metal)
			_add_box(wrap, "RailBase", Vector3(0.022, 0.007, 0.195), Vector3(0, 0.0155, -0.005), mat_rail)
			for i in range(11):
				_add_box(wrap, "Lug", Vector3(0.024, 0.004, 0.009), Vector3(0, 0.020, -0.09 + float(i) * 0.017), mat_rail)
			wrap.scale = Vector3(3.1, 3.1, 3.1)
		"optic_red_dot":
			var holder := Node3D.new()
			_build_red_dot_optic(holder, mat_rail)
			holder.position = Vector3(0, -0.094, -0.015)
			wrap.add_child(holder)
			wrap.scale = Vector3(6.8, 6.8, 6.8)
		"optic_lpvo":
			var holder := Node3D.new()
			_build_lpvo_optic(holder, mat_rail)
			holder.position = Vector3(0, -0.097, -0.005)
			wrap.add_child(holder)
			wrap.scale = Vector3(3.4, 3.4, 3.4)
			
	wrap.rotation_degrees = Vector3(12.0, -35.0, 0.0)
	return wrap
