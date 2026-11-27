class_name AA12Model
extends RefCounted

# Museum-Grade MPS AA-12 Atchisson Assault Shotgun (12 Gauge Full-Auto)
# Forward along -Z:
# - Procedural matte stippled charcoal glass-filled polymer shell shader
# - Riveted two-piece slab-sided stainless-core receiver & integral comb buttstock
# - Recessed right-side ejection port revealing polished stainless open-bolt carrier
# - Ribbed combat forend, heavy stainless 12-gauge barrel with vented barrel shroud & cavernous bore
# - Tall protective ghost-ring rear sight & hooded front post (aligned cleanly at y = +0.088)
# - Top knurled reciprocating ChargingHandle + massive 20-round ribbed Drum Magazine showing 6 red/brass 12G shells!

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

static func _create_polymer_material(tone: float = 0.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

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
	// Matte stippled glass-filled tactical polymer shell
	float stipple = hash31(floor(v_local * 380.0));
	float patch_v = hash31(floor(v_local * 42.0));
	vec3 base_c = vec3(0.115, 0.122, 0.132) * (1.0 - darken);
	ALBEDO = base_c * (0.86 + stipple * 0.18 + patch_v * 0.08);
	ROUGHNESS = clamp(0.62 + (1.0 - stipple) * 0.16, 0.54, 0.84);
	METALLIC = 0.05;
	SPECULAR = 0.40;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("darken", tone)
	return sm

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "AA12Model"

	var mat_poly := _create_polymer_material(0.0)
	var mat_poly_dark := _create_polymer_material(0.24)

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.74, 0.77, 0.80) # Bead-blasted stainless steel barrel & bolt
	mat_steel.metallic = 0.94
	mat_steel.roughness = 0.22

	var mat_steel_dark := StandardMaterial3D.new()
	mat_steel_dark.albedo_color = Color(0.14, 0.15, 0.17) # Gunmetal shroud, rail & hardware
	mat_steel_dark.metallic = 0.86
	mat_steel_dark.roughness = 0.34

	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.055, 0.06, 0.066)
	mat_rubber.roughness = 0.90

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.016, 0.018, 0.022)
	mat_bore.roughness = 0.95

	var mat_shell_red := StandardMaterial3D.new()
	mat_shell_red.albedo_color = Color(0.84, 0.11, 0.10) # 12-gauge red plastic hulls
	mat_shell_red.roughness = 0.34

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.25)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18

	var mat_dot := StandardMaterial3D.new()
	mat_dot.albedo_color = Color(1.0, 0.42, 0.12)
	mat_dot.emission_enabled = true
	mat_dot.emission = Color(1.0, 0.34, 0.08)
	mat_dot.emission_energy_multiplier = 1.6

	# ==========================================
	# 1. RIVETED TWO-PIECE SLAB-SIDED AA-12 RECEIVER & INTEGRAL BUTTSTOCK
	# ==========================================
	_add_box(root, "ReceiverCore", Vector3(0.056, 0.104, 0.515), Vector3(0, 0.0, 0.048), mat_poly)
	# Molded recessed side grip panels & stainless assembly bolts along both flanks!
	for sx in [-0.0285, 0.0285]:
		_add_box(root, "SidePanelMid", Vector3(0.004, 0.068, 0.340), Vector3(sx, -0.002, 0.085), mat_poly_dark)
		for bz in [-0.175, -0.095, 0.015, 0.125, 0.225, 0.285]:
			_add_cyl(root, "ShellBolt", 0.0038, 0.0038, 0.006, Vector3(sx, 0.032, bz), mat_steel, 6, Vector3(0, 0, 90))
			_add_cyl(root, "ShellBoltLow", 0.0038, 0.0038, 0.006, Vector3(sx, -0.036, bz), mat_steel, 6, Vector3(0, 0, 90))
	# Raised carry-rib top spine + machined top charging-handle track
	_add_box(root, "UpperSpine", Vector3(0.042, 0.026, 0.495), Vector3(0, 0.063, 0.038), mat_poly)
	_add_box(root, "ChargeSlot", Vector3(0.012, 0.008, 0.165), Vector3(0, 0.075, -0.095), mat_bore)
	# Recessed right-side ejection port exposing polished stainless open bolt carrier!
	_add_box(root, "EjectPortRecess", Vector3(0.014, 0.034, 0.098), Vector3(0.025, 0.020, -0.042), mat_bore)
	_add_box(root, "StainlessOpenBolt", Vector3(0.010, 0.026, 0.082), Vector3(0.022, 0.020, -0.046), mat_steel)

	# Integral Buttstock Comb, Thick Ribbed Recoil Pad & Rear Sling Swivel
	_add_box(root, "ButtCheekComb", Vector3(0.046, 0.016, 0.175), Vector3(0, 0.052, 0.215), mat_rubber)
	_add_box(root, "ButtPadPlate", Vector3(0.058, 0.114, 0.024), Vector3(0, -0.002, 0.314), mat_rubber)
	for py in [-0.036, -0.012, 0.012, 0.036]:
		_add_box(root, "PadGroove", Vector3(0.060, 0.005, 0.008), Vector3(0, py, 0.326), mat_bore)
	_add_cyl(root, "RearSlingLoop", 0.008, 0.008, 0.006, Vector3(-0.030, -0.028, 0.275), mat_steel_dark, 10, Vector3(0, 90, 0))

	# Ergonomic Ribbed Pistol Grip, Selector Switch, Oversized Trigger Guard & Magwell Funnel
	var grip := _add_box(root, "PistolGrip", Vector3(0.036, 0.110, 0.050), Vector3(0, -0.090, 0.092), mat_rubber, Vector3(-17.0, 0, 0))
	for gy in [-0.030, -0.010, 0.010, 0.030]:
		_add_box(grip, "GripRib", Vector3(0.038, 0.004, 0.040), Vector3(0, gy, 0), mat_poly_dark)
	_add_box(root, "SelectorSwitch", Vector3(0.006, 0.009, 0.024), Vector3(-0.030, -0.032, 0.072), mat_steel_dark, Vector3(-18.0, 0, 0))
	_add_box(root, "TriggerGuardFront", Vector3(0.022, 0.036, 0.007), Vector3(0, -0.064, -0.002), mat_poly_dark)
	_add_box(root, "TriggerGuardBow", Vector3(0.022, 0.007, 0.074), Vector3(0, -0.080, 0.036), mat_poly_dark)
	_add_box(root, "Trigger", Vector3(0.008, 0.024, 0.010), Vector3(0, -0.062, 0.042), mat_steel, Vector3(-18.0, 0, 0))
	_add_box(root, "MagwellCollar", Vector3(0.064, 0.024, 0.118), Vector3(0, -0.056, -0.100), mat_poly_dark)

	# ==========================================
	# 2. SCULPTED RIBBED FOREND, VENTED SHROUD & HEAVY STAINLESS 12G BARREL
	# ==========================================
	_add_box(root, "ForendCore", Vector3(0.052, 0.072, 0.245), Vector3(0, 0.006, -0.325), mat_poly_dark)
	for ri in range(6):
		var rz: float = -0.225 - float(ri) * 0.038
		_add_box(root, "ForendGripRib_%d" % ri, Vector3(0.056, 0.052, 0.015), Vector3(0, 0.002, rz), mat_poly)
		_add_box(root, "ForendVentSlot_%d" % ri, Vector3(0.058, 0.012, 0.018), Vector3(0, 0.028, rz), mat_bore)
	# Underbarrel tactical rail under forend nose
	_add_box(root, "UnderRail", Vector3(0.024, 0.008, 0.115), Vector3(0, -0.034, -0.365), mat_steel_dark)
	# Heavy stainless steel 12-gauge barrel + threaded choke collar + cavernous dark bore!
	_add_cyl(root, "BarrelShroudCollar", 0.023, 0.024, 0.065, Vector3(0, 0.018, -0.468), mat_steel_dark, 18)
	_add_cyl(root, "HeavyStainlessBarrel", 0.0168, 0.0178, 0.195, Vector3(0, 0.018, -0.545), mat_steel, 20)
	_add_cyl(root, "ChokeCollar", 0.0188, 0.0188, 0.022, Vector3(0, 0.018, -0.630), mat_steel_dark, 18)
	_add_cyl(root, "Bore12G", 0.0132, 0.0132, 0.018, Vector3(0, 0.018, -0.640), mat_bore, 16)

	# ==========================================
	# 3. TALL PROTECTIVE GHOST-RING IRON SIGHTS (aligned cleanly at y = +0.088!)
	# ==========================================
	# Rear twin protective wings + open ghost-ring notch centered at y = +0.088
	_add_box(root, "RearSightBase", Vector3(0.034, 0.010, 0.038), Vector3(0, 0.078, 0.155), mat_steel_dark)
	_add_box(root, "RearSightWingL", Vector3(0.006, 0.028, 0.028), Vector3(-0.014, 0.092, 0.155), mat_poly)
	_add_box(root, "RearSightWingR", Vector3(0.006, 0.028, 0.028), Vector3(0.014, 0.092, 0.155), mat_poly)
	_add_box(root, "RearNotchL", Vector3(0.0055, 0.012, 0.006), Vector3(-0.0075, 0.089, 0.165), mat_steel_dark)
	_add_box(root, "RearNotchR", Vector3(0.0055, 0.012, 0.006), Vector3(0.0075, 0.089, 0.165), mat_steel_dark)

	# Tall front sight tower with protective wings & glowing orange front post tip at y = +0.088!
	_add_box(root, "FrontSightBase", Vector3(0.036, 0.016, 0.032), Vector3(0, 0.062, -0.415), mat_steel_dark)
	_add_box(root, "FrontSightGuardL", Vector3(0.006, 0.034, 0.022), Vector3(-0.015, 0.086, -0.415), mat_poly)
	_add_box(root, "FrontSightGuardR", Vector3(0.006, 0.034, 0.022), Vector3(0.015, 0.086, -0.415), mat_poly)
	_add_box(root, "FrontSightPost", Vector3(0.0036, 0.020, 0.007), Vector3(0, 0.079, -0.415), mat_steel_dark)
	_add_box(root, "FrontSightTip", Vector3(0.0038, 0.004, 0.008), Vector3(0, 0.089, -0.415), mat_dot)

	# ==========================================
	# 4. ANIMATED TOP KNURLED CHARGING HANDLE ("ChargingHandle")
	# ==========================================
	var ch := Node3D.new()
	ch.name = "ChargingHandle"
	ch.position = Vector3(0, 0.084, -0.105)
	root.add_child(ch)
	_add_box(ch, "HandleStem", Vector3(0.010, 0.014, 0.016), Vector3(0, -0.005, 0), mat_steel_dark)
	_add_cyl(ch, "HandleCrossbar", 0.0075, 0.0075, 0.034, Vector3(0, 0.003, 0), mat_steel, 12, Vector3(0, 0, 90))

	# ==========================================
	# 5. MASSIVE 20-ROUND 12-GAUGE RIBBED DRUM MAGAZINE ("Magazine")
	# ==========================================
	var drum := Node3D.new()
	drum.name = "Magazine"
	drum.position = Vector3(0, -0.132, -0.100)
	root.add_child(drum)
	# Tapered polymer feed tower locking cleanly into magwell
	_add_box(drum, "FeedTower", Vector3(0.046, 0.082, 0.092), Vector3(0, 0.074, 0), mat_poly_dark)
	_add_box(drum, "FeedTowerRib", Vector3(0.050, 0.014, 0.096), Vector3(0, 0.056, 0), mat_steel_dark)
	# Massive cylindrical 20-round drum housing with outer rim bevels & 8 radial structural ribs!
	_add_cyl(drum, "DrumBodyMain", 0.098, 0.098, 0.094, Vector3.ZERO, mat_poly_dark, 28)
	_add_cyl(drum, "DrumRimFront", 0.101, 0.101, 0.012, Vector3(0, 0, -0.044), mat_poly, 28)
	_add_cyl(drum, "DrumRimRear", 0.101, 0.101, 0.012, Vector3(0, 0, 0.044), mat_poly, 28)
	for ri in range(8):
		var ra: float = float(ri) * (TAU / 8.0)
		_add_box(drum, "DrumRadialRib_%d" % ri, Vector3(0.008, 0.086, 0.099), Vector3(cos(ra) * 0.052, sin(ra) * 0.052, 0), mat_poly, Vector3(0, 0, rad_to_deg(ra) + 90.0))
	# Brushed stainless center winding hub & rear winding key!
	_add_cyl(drum, "DrumHub", 0.032, 0.032, 0.104, Vector3.ZERO, mat_steel, 18)
	_add_box(drum, "WindingKey", Vector3(0.056, 0.012, 0.010), Vector3(0, 0, 0.055), mat_steel_dark)

	# Curved witness window showing 6 individual gleaming red/brass 12-gauge shells stacked inside the drum!
	for si in range(6):
		var sang: float = deg_to_rad(-55.0 + float(si) * 22.0)
		var sx: float = cos(sang) * 0.068
		var sy: float = sin(sang) * 0.068
		_add_cyl(drum, "DrumShellHull_%d" % si, 0.0098, 0.0098, 0.052, Vector3(sx, sy, -0.012), mat_shell_red, 10)
		_add_cyl(drum, "DrumShellBrass_%d" % si, 0.0104, 0.0104, 0.016, Vector3(sx, sy, 0.042), mat_brass, 10)

	# ==========================================
	# 6. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.018, -0.655)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.038, 0.022, -0.042)
	root.add_child(eject)

	return root
