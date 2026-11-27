class_name MG42Model
extends RefCounted

# Museum-Grade WWII German Maschinengewehr 42 ("Hitler's Buzzsaw", 7.92x57mm Mauser)
# Forward along -Z:
# - Procedural marbled WWII German Bakelite shader on detachable hollow-toe buttstock & ribbed grip panels
# - Stamped angular steel receiver with circular buffer housing, right-side quick-change barrel latch & T-handle
# - True HOLLOW perforated rectangular barrel shroud (Laufmantel) with visible gleaming inner barrel inside!
# - Signature conical recoil booster (Rückstoßverstärker) + trumpet flash hider + folded pressed-steel bipod
# - Hinged TopCover with feed pawl track & precision flip-up iron sights (aligned cleanly at y = +0.064)
# - Left-side feldgrau Gurttrommel drum AmmoBox with linked brass/copper 7.92x57mm Patronengurt 34 belt!

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

static func _create_bakelite_material() -> ShaderMaterial:
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
	// Authentic WWII German mottled reddish-brown Bakelit phenolic resin
	float swirl = sin(v_local.z * 52.0 + sin(v_local.y * 74.0 + v_local.x * 48.0) * 2.2);
	float fleck = hash31(floor(v_local * 210.0));
	vec3 light_b = vec3(0.41, 0.175, 0.085);
	vec3 dark_b = vec3(0.18, 0.065, 0.032);
	vec3 col = mix(dark_b, light_b, 0.48 + swirl * 0.26 + fleck * 0.24);
	ALBEDO = col;
	ROUGHNESS = clamp(0.36 + fleck * 0.12, 0.28, 0.52);
	METALLIC = 0.04;
	SPECULAR = 0.58;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	return sm

static func _build_792_linked_round(mat_brass: Material, mat_copper: Material, mat_link: Material) -> Node3D:
	var r := Node3D.new()
	_add_cyl(r, "Case", 0.0048, 0.0054, 0.038, Vector3(0, 0, 0.010), mat_brass, 10)
	_add_cyl(r, "Neck", 0.0038, 0.0048, 0.008, Vector3(0, 0, -0.013), mat_brass, 10)
	_add_cyl(r, "Bullet", 0.0007, 0.0038, 0.022, Vector3(0, 0, -0.028), mat_copper, 10)
	_add_box(r, "Link", Vector3(0.0105, 0.0105, 0.018), Vector3(0, 0, 0.012), mat_link)
	return r

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "MG42Model"

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.125, 0.138, 0.155) # Deep stamped Wehrmacht blued gunmetal
	mat_steel.metallic = 0.90
	mat_steel.roughness = 0.28

	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.075, 0.082, 0.092) # Phosphate bipod, latches & belt links
	mat_steel_dark.metallic = 0.84
	mat_steel_dark.roughness = 0.40

	var mat_inner_barrel := StandardMaterial3D.new()
	mat_inner_barrel.albedo_color = Color(0.32, 0.30, 0.28) # Heat-tempered inner quick-change steel barrel!
	mat_inner_barrel.metallic = 0.92
	mat_inner_barrel.roughness = 0.24

	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.74, 0.77, 0.80) # Machined feed tray & bolt steel
	mat_bolt.metallic = 0.95
	mat_bolt.roughness = 0.18

	var mat_bakelite := _create_bakelite_material()

	var mat_drum := StandardMaterial3D.new()
	mat_drum.albedo_color = Color(0.24, 0.27, 0.23) # Wehrmacht feldgrau Gurttrommel steel drum
	mat_drum.metallic = 0.68
	mat_drum.roughness = 0.42

	var mat_drum_dark := StandardMaterial3D.new()
	mat_drum_dark.albedo_color = Color(0.16, 0.18, 0.15)
	mat_drum_dark.metallic = 0.64
	mat_drum_dark.roughness = 0.48

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.26)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.84, 0.44, 0.19)
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.016, 0.018, 0.022)
	mat_bore.roughness = 0.95

	# ==========================================
	# 1. STAMPED ANGULAR RECEIVER, BUFFER HOUSING & BAKELITE BUTTSTOCK
	# ==========================================
	_add_box(root, "ReceiverMain", Vector3(0.064, 0.068, 0.345), Vector3(0, 0.0, -0.052), mat_steel)
	# Internal machined steel belt feed tray visible when TopCover opens!
	_add_box(root, "InternalFeedTray", Vector3(0.054, 0.010, 0.155), Vector3(0, 0.032, -0.095), mat_bolt)
	_add_box(root, "FeedChannelDark", Vector3(0.036, 0.012, 0.135), Vector3(0, 0.030, -0.095), mat_bore)

	# Right-side quick-change barrel latch door (Laufwechselklappe) & cocking track recess!
	_add_box(root, "BarrelChangeLatch", Vector3(0.008, 0.038, 0.092), Vector3(0.035, 0.004, -0.178), mat_steel_dark)
	_add_box(root, "CockingSlotTrack", Vector3(0.005, 0.012, 0.175), Vector3(0.033, 0.006, -0.030), mat_bore)
	# Left-side stamped stiffening flute & belt feed chute lip
	_add_box(root, "LeftFeedLip", Vector3(0.012, 0.026, 0.092), Vector3(-0.036, 0.010, -0.125), mat_steel_dark)

	# Iconic MG 42 cylindrical buffer collar (Puffergehäuse) + angular marbled Bakelite buttstock!
	_add_cyl(root, "BufferHousing", 0.026, 0.024, 0.088, Vector3(0, -0.004, 0.152), mat_steel_dark, 18)
	_add_box(root, "StockUpperSpine", Vector3(0.044, 0.042, 0.215), Vector3(0, -0.006, 0.275), mat_bakelite, Vector3(4.0, 0, 0))
	_add_box(root, "StockLowerGripCut", Vector3(0.040, 0.046, 0.135), Vector3(0, -0.046, 0.305), mat_bakelite, Vector3(12.0, 0, 0))
	_add_box(root, "StockButtPlate", Vector3(0.046, 0.096, 0.014), Vector3(0, -0.034, 0.388), mat_steel_dark)

	# Classic MG 42 Grip Frame with Ribbed Bakelite Panels & Cross-Bolt Safety
	_add_box(root, "GripHousingFrame", Vector3(0.034, 0.028, 0.125), Vector3(0, -0.044, 0.028), mat_steel_dark)
	var grip := _add_box(root, "PistolGripCore", Vector3(0.034, 0.104, 0.048), Vector3(0, -0.088, 0.064), mat_bakelite, Vector3(-16.0, 0, 0))
	for gy in [-0.030, -0.012, 0.006, 0.024]:
		_add_box(grip, "GripGroove", Vector3(0.036, 0.004, 0.036), Vector3(0, gy, 0), mat_steel_dark)
	_add_cyl(root, "CrossBoltSafety", 0.0055, 0.0055, 0.044, Vector3(0, -0.044, 0.068), mat_bolt, 10, Vector3(0, 0, 90))
	_add_box(root, "TriggerGuardFront", Vector3(0.020, 0.032, 0.006), Vector3(0, -0.056, -0.026), mat_steel_dark)
	_add_box(root, "TriggerGuardBow", Vector3(0.020, 0.006, 0.066), Vector3(0, -0.072, 0.006), mat_steel_dark)
	_add_box(root, "Trigger", Vector3(0.007, 0.024, 0.009), Vector3(0, -0.054, 0.012), mat_bolt, Vector3(-18.0, 0, 0))

	# ==========================================
	# 2. HINGED TOP FEED COVER ("TopCover") + FLIP-UP TANGENT REAR SIGHT (y = +0.064)
	# ==========================================
	var top_cover := Node3D.new()
	top_cover.name = "TopCover"
	top_cover.position = Vector3(0, 0.034, -0.205) # Hinged at front!
	root.add_child(top_cover)
	_add_box(top_cover, "CoverPlateMain", Vector3(0.060, 0.018, 0.275), Vector3(0, 0.009, 0.138), mat_steel)
	_add_box(top_cover, "FeedPawlHousing", Vector3(0.046, 0.009, 0.145), Vector3(0, 0.021, 0.095), mat_steel_dark)
	_add_box(top_cover, "CoverLatchRear", Vector3(0.028, 0.012, 0.018), Vector3(0, 0.012, 0.278), mat_steel_dark)
	# Precision MG 42 rear sight block & V-notch (aligned at model-local y = +0.064 -> cover-local y = +0.030!)
	_add_box(top_cover, "RearSightBase", Vector3(0.028, 0.010, 0.036), Vector3(0, 0.021, 0.215), mat_steel_dark)
	_add_box(top_cover, "RearNotchBase", Vector3(0.020, 0.005, 0.007), Vector3(0, 0.0275, 0.228), mat_bore)
	_add_box(top_cover, "RearSightL", Vector3(0.0068, 0.0085, 0.007), Vector3(-0.0068, 0.032, 0.228), mat_bore)
	_add_box(top_cover, "RearSightR", Vector3(0.0068, 0.0085, 0.007), Vector3(0.0068, 0.032, 0.228), mat_bore)

	# ==========================================
	# 3. TRUE HOLLOW PERFORATED BARREL SHROUD (Laufmantel) + VISIBLE INNER BARREL + CONICAL BOOSTER!
	# ==========================================
	# Visible heat-tempered inner quick-change barrel running full length inside the perforated shroud!
	_add_cyl(root, "InnerQuickChangeBarrel", 0.0135, 0.0165, 0.565, Vector3(0, 0.008, -0.495), mat_inner_barrel, 16)

	# True hollow perforated steel shroud built from longitudinal rails + rhythmic cross-bridges!
	# Top & bottom longitudinal shroud corner rails
	for sx in [-0.025, 0.025]:
		for sy in [-0.019, 0.035]:
			_add_box(root, "ShroudRail", Vector3(0.008, 0.008, 0.545), Vector3(sx, sy, -0.495), mat_steel)
	# Solid front & rear shroud collars
	_add_box(root, "ShroudRearCollar", Vector3(0.058, 0.060, 0.056), Vector3(0, 0.008, -0.250), mat_steel)
	_add_box(root, "ShroudFrontCollar", Vector3(0.056, 0.058, 0.054), Vector3(0, 0.008, -0.742), mat_steel)
	# 8 perforated cross-bridges creating true open cooling slots all along top, sides & bottom!
	for bi in range(8):
		var bz: float = -0.298 - float(bi) * 0.058
		_add_box(root, "ShroudBridgeTop_%d" % bi, Vector3(0.044, 0.006, 0.018), Vector3(0, 0.036, bz), mat_steel)
		_add_box(root, "ShroudBridgeBot_%d" % bi, Vector3(0.044, 0.006, 0.018), Vector3(0, -0.020, bz), mat_steel)
		_add_box(root, "ShroudBridgeL_%d" % bi, Vector3(0.006, 0.048, 0.018), Vector3(-0.026, 0.008, bz), mat_steel)
		_add_box(root, "ShroudBridgeR_%d" % bi, Vector3(0.006, 0.048, 0.018), Vector3(0.026, 0.008, bz), mat_steel)

	# Iconic MG 42 Conical Recoil Booster (Rückstoßverstärker) + Tapered Trumpet Flash Hider!
	_add_cyl(root, "BoosterCollar", 0.022, 0.024, 0.028, Vector3(0, 0.008, -0.782), mat_steel_dark, 16)
	_add_cyl(root, "BoosterBody", 0.018, 0.022, 0.042, Vector3(0, 0.008, -0.816), mat_steel, 16)
	_add_cyl(root, "BoosterTrumpet", 0.027, 0.016, 0.046, Vector3(0, 0.008, -0.858), mat_steel_dark, 18)
	_add_cyl(root, "MuzzleBore", 0.012, 0.012, 0.018, Vector3(0, 0.008, -0.878), mat_bore, 14)

	# Flip-up Hooded Front Sight Post (tip aligned at y = +0.064!)
	_add_box(root, "FrontSightBase", Vector3(0.024, 0.014, 0.028), Vector3(0, 0.044, -0.742), mat_steel_dark)
	_add_box(root, "FrontSightEarL", Vector3(0.0038, 0.022, 0.014), Vector3(-0.0095, 0.060, -0.742), mat_steel)
	_add_box(root, "FrontSightEarR", Vector3(0.0038, 0.022, 0.014), Vector3(0.0095, 0.060, -0.742), mat_steel)
	_add_box(root, "FrontSightPost", Vector3(0.0028, 0.016, 0.006), Vector3(0, 0.056, -0.742), mat_bore)

	# Folded Pressed-Steel WWII Bipod (Zweibein) with Spiked Ski Feet!
	_add_box(root, "BipodMountBlock", Vector3(0.036, 0.018, 0.026), Vector3(0, -0.028, -0.735), mat_steel_dark)
	for sx in [-1.0, 1.0]:
		_add_box(root, "BipodChannelLeg", Vector3(0.012, 0.014, 0.305), Vector3(0.026 * sx, -0.034, -0.575), mat_steel_dark)
		_add_box(root, "BipodSpikedFoot", Vector3(0.022, 0.010, 0.042), Vector3(0.028 * sx, -0.038, -0.418), mat_steel)

	# ==========================================
	# 4. ANIMATED RIGHT-SIDE T-HANDLE COCKING SLIDE ("ChargingHandle")
	# ==========================================
	var ch := Node3D.new()
	ch.name = "ChargingHandle"
	ch.position = Vector3(0.040, 0.006, -0.032)
	root.add_child(ch)
	_add_box(ch, "CockingStem", Vector3(0.018, 0.014, 0.016), Vector3(0, 0, 0), mat_steel_dark)
	_add_cyl(ch, "CockingBarT", 0.0065, 0.0065, 0.036, Vector3(0.014, 0, 0), mat_bolt, 10, Vector3.ZERO)

	# ==========================================
	# 5. LEFT-SIDE FELDGRAU GURTTROMMEL ASSAULT DRUM ("AmmoBox") + LINKED 7.92x57mm BELT!
	# ==========================================
	var ammo_box := Node3D.new()
	ammo_box.name = "AmmoBox"
	ammo_box.position = Vector3(-0.094, -0.028, -0.125)
	root.add_child(ammo_box)
	# Stamped feldgrau Gurttrommel 34 drum body + outer rim flange + 6 radial stamped ribs!
	_add_cyl(ammo_box, "DrumCan", 0.088, 0.088, 0.086, Vector3.ZERO, mat_drum, 24)
	_add_cyl(ammo_box, "DrumRimF", 0.091, 0.091, 0.010, Vector3(0, 0, -0.040), mat_drum_dark, 24)
	_add_cyl(ammo_box, "DrumRimR", 0.091, 0.091, 0.010, Vector3(0, 0, 0.040), mat_drum_dark, 24)
	_add_cyl(ammo_box, "DrumHub", 0.026, 0.026, 0.094, Vector3.ZERO, mat_steel_dark, 16)
	for ri in range(6):
		var ra: float = float(ri) * (TAU / 6.0)
		_add_box(ammo_box, "DrumRib_%d" % ri, Vector3(0.007, 0.072, 0.090), Vector3(cos(ra) * 0.048, sin(ra) * 0.048, 0), mat_drum_dark, Vector3(0, 0, rad_to_deg(ra) + 90.0))
	# Feed mouth collar bridging drum into MG 42 left feed tray + 5 linked brass/copper 7.92x57mm rounds!
	_add_box(ammo_box, "DrumFeedNeck", Vector3(0.044, 0.034, 0.084), Vector3(0.048, 0.036, 0.0), mat_drum_dark, Vector3(0, 0, -18.0))
	for i in range(5):
		var frac: float = float(i) / 4.0
		var rnd := _build_792_linked_round(mat_brass, mat_copper, mat_steel_dark)
		rnd.name = "BeltRound_%d" % i
		rnd.position = Vector3(0.034 + frac * 0.044, 0.044 + sin(frac * PI) * 0.008, 0.0)
		rnd.rotation_degrees = Vector3(0, 0, lerpf(-20.0, 5.0, frac))
		ammo_box.add_child(rnd)

	# ==========================================
	# 6. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.008, -0.895)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.010, -0.044, -0.105) # Authentic downward-right MG 42 ejection chute!
	root.add_child(eject)

	return root
