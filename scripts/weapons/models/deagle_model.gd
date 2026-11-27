class_name DeagleModel
extends RefCounted

# Museum-Grade IMI / Magnum Research Desert Eagle Mark XIX (.50 AE)
# Forward along -Z:
# - Procedural brushed satin stainless steel shader with crisp machining grain
# - Signature triangular fixed barrel with dual-slot Weaver top rib, ported vents & giant .50 cal bore
# - Sculpted beavertail frame, squared combat trigger guard, skeletonized hammer & finger-grooved Hogue rubber grip
# - Reciprocating cutaway rear Slide with 6 angled serrations, ambidextrous safety levers & glowing 3-dot tritium sights (y = +0.066)
# - Detachable steel .50 AE Magazine with witness holes & visible chunky flat-nose .50 AE top cartridge!

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

static func _create_brushed_stainless_material(tint: float = 0.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float darken : hint_range(0.0, 0.35) = 0.0;

varying vec3 v_local;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	// Fine longitudinal brushed satin chrome grain along slide & barrel (-Z)
	float brush = hash21(vec2(floor(v_local.y * 520.0 + v_local.x * 260.0), floor(v_local.z * 38.0)));
	float micro = hash21(floor(v_local.xy * 420.0));
	vec3 base_col = vec3(0.81, 0.84, 0.87) * (1.0 - darken);
	ALBEDO = base_col * (0.93 + brush * 0.09);
	METALLIC = 0.96;
	ROUGHNESS = clamp(0.15 + brush * 0.08 + micro * 0.03, 0.12, 0.28);
	SPECULAR = 0.65;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("darken", tint)
	return sm

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "DeagleModel"

	var mat_chrome := _create_brushed_stainless_material(0.0)
	var mat_frame := _create_brushed_stainless_material(0.11)

	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.065, 0.07, 0.078) # Textured black Hogue rubber grip
	mat_rubber.roughness = 0.88

	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.09, 0.095, 0.108) # Matte blued controls, sights, trigger, mag
	mat_dark.metallic = 0.86
	mat_dark.roughness = 0.30

	var mat_bore := StandardMaterial3D.new()
	mat_bore.albedo_color = Color(0.015, 0.015, 0.02)
	mat_bore.roughness = 0.95

	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.88, 0.12, 0.10)
	mat_red.roughness = 0.35

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.25)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.82, 0.46, 0.20)
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var mat_dot := StandardMaterial3D.new()
	mat_dot.albedo_color = Color(0.35, 1.0, 0.45)
	mat_dot.emission_enabled = true
	mat_dot.emission = Color(0.25, 0.95, 0.38)
	mat_dot.emission_energy_multiplier = 2.4

	# ==========================================
	# 1. HEAVY FRAME, BEAVERTAIL, TRIGGER GUARD & CONTROLS
	# ==========================================
	_add_box(root, "FrameDustCover", Vector3(0.036, 0.026, 0.235), Vector3(0, 0.005, -0.050), mat_frame)
	_add_box(root, "FrameChamferL", Vector3(0.006, 0.012, 0.228), Vector3(-0.016, -0.008, -0.050), mat_frame, Vector3(0, 0, 38.0))
	_add_box(root, "FrameChamferR", Vector3(0.006, 0.012, 0.228), Vector3(0.016, -0.008, -0.050), mat_frame, Vector3(0, 0, -38.0))
	# Extended sculpted beavertail tang protecting hand from massive slide recoil
	_add_box(root, "Beavertail", Vector3(0.028, 0.014, 0.042), Vector3(0, 0.006, 0.082), mat_frame, Vector3(-10.0, 0, 0))
	# Left-side takedown latch, slide stop & magazine release button
	_add_box(root, "TakedownLatch", Vector3(0.005, 0.010, 0.028), Vector3(-0.020, 0.006, -0.058), mat_dark)
	_add_box(root, "SlideStop", Vector3(0.005, 0.008, 0.032), Vector3(-0.020, 0.012, 0.006), mat_dark)
	_add_cyl(root, "MagReleaseBtn", 0.0055, 0.0055, 0.006, Vector3(-0.019, -0.014, 0.038), mat_dark, 10, Vector3(0, 0, 90))

	# Squared combat trigger guard with front finger rest & curved combat trigger
	_add_box(root, "TriggerGuardFront", Vector3(0.018, 0.036, 0.006), Vector3(0, -0.022, -0.026), mat_frame, Vector3(12.0, 0, 0))
	_add_box(root, "TriggerGuardBow", Vector3(0.018, 0.006, 0.068), Vector3(0, -0.039, 0.006), mat_frame)
	_add_box(root, "Trigger", Vector3(0.008, 0.024, 0.010), Vector3(0, -0.020, 0.014), mat_dark, Vector3(-18.0, 0, 0))
	# Exposed skeletonized combat hammer
	_add_box(root, "HammerSpur", Vector3(0.011, 0.024, 0.018), Vector3(0, 0.026, 0.088), mat_dark, Vector3(-28.0, 0, 0))
	_add_cyl(root, "HammerRing", 0.004, 0.004, 0.013, Vector3(0, 0.030, 0.092), mat_bore, 10, Vector3(0, 0, 90))

	# ==========================================
	# 2. ICONIC TRIANGULAR FIXED BARREL, WEAVER RIB & MASSIVE .50 CAL BORE
	# ==========================================
	_add_box(root, "FixedBarrelLower", Vector3(0.032, 0.022, 0.172), Vector3(0, 0.027, -0.098), mat_chrome)
	# Signature angled Desert Eagle triangular barrel chamfers!
	_add_box(root, "BarrelBevelL", Vector3(0.014, 0.028, 0.168), Vector3(-0.011, 0.042, -0.098), mat_chrome, Vector3(0, 0, -28.0))
	_add_box(root, "BarrelBevelR", Vector3(0.014, 0.028, 0.168), Vector3(0.011, 0.042, -0.098), mat_chrome, Vector3(0, 0, 28.0))
	# Integrated Weaver/Picatinny top rail rib + cross-slots
	_add_box(root, "BarrelTopRib", Vector3(0.020, 0.009, 0.168), Vector3(0, 0.056, -0.098), mat_chrome)
	for slz in [-0.045, -0.085, -0.125]:
		_add_box(root, "WeaverSlot", Vector3(0.021, 0.004, 0.009), Vector3(0, 0.0595, slz), mat_dark)
	# Ported muzzle compensator vents on top flanks + gas piston plug + massive .50 cal bore!
	for sx in [-0.007, 0.007]:
		_add_box(root, "CompPort", Vector3(0.004, 0.006, 0.016), Vector3(sx, 0.058, -0.158), mat_bore)
	_add_cyl(root, "GasPistonPlug", 0.0068, 0.0068, 0.014, Vector3(0, 0.014, -0.180), mat_dark, 12)
	_add_cyl(root, "MuzzleCrown", 0.0118, 0.0118, 0.008, Vector3(0, 0.038, -0.184), mat_chrome, 16)
	_add_cyl(root, "Bore50AE", 0.0092, 0.0092, 0.016, Vector3(0, 0.038, -0.186), mat_bore, 16)

	# Fixed Front Combat Blade Sight + Glowing Tritium Dot (aligned at y = +0.066!)
	_add_box(root, "FrontSightBlade", Vector3(0.0055, 0.013, 0.018), Vector3(0, 0.064, -0.168), mat_dark)
	_add_box(root, "FrontDot", Vector3(0.0036, 0.0036, 0.003), Vector3(0, 0.066, -0.1585), mat_dot)

	# ==========================================
	# 3. ERGONOMIC WRAP-AROUND RUBBER GRIP & DETACHABLE .50 AE MAGAZINE
	# ==========================================
	var grip_root := Node3D.new()
	grip_root.name = "Grip"
	grip_root.position = Vector3(0, -0.058, 0.056)
	grip_root.rotation_degrees = Vector3(-18.0, 0, 0)
	root.add_child(grip_root)
	_add_box(grip_root, "GripCoreFrame", Vector3(0.035, 0.118, 0.058), Vector3.ZERO, mat_frame)
	_add_box(grip_root, "GripRubberWrap", Vector3(0.041, 0.106, 0.052), Vector3(0, -0.002, 0.004), mat_rubber)
	# Finger grooves on front strap + stainless side medallion screw
	for fy in [-0.032, -0.008, 0.016]:
		_add_cyl(grip_root, "FingerGroove", 0.016, 0.016, 0.036, Vector3(0, fy, -0.024), mat_rubber, 10, Vector3(0, 0, 90))
	for sx in [-0.021, 0.021]:
		_add_cyl(grip_root, "GripScrew", 0.0042, 0.0042, 0.004, Vector3(sx, 0.014, 0.006), mat_chrome, 10, Vector3(0, 0, 90))
		_add_cyl(grip_root, "GripMedallion", 0.0075, 0.0075, 0.003, Vector3(sx, -0.018, 0.004), mat_dark, 12, Vector3(0, 0, 90))

	var mag := Node3D.new()
	mag.name = "Magazine"
	mag.position = Vector3(0, -0.068, 0.058)
	mag.rotation_degrees = Vector3(-18.0, 0, 0)
	root.add_child(mag)
	_add_box(mag, "MagBody", Vector3(0.027, 0.112, 0.048), Vector3.ZERO, mat_dark)
	for wy in [-0.022, 0.0, 0.022]:
		_add_cyl(mag, "WitnessHole", 0.0028, 0.0028, 0.029, Vector3(0, wy, 0.0), mat_brass, 8, Vector3(0, 0, 90))
	_add_box(mag, "MagBasePad", Vector3(0.037, 0.015, 0.060), Vector3(0, -0.060, -0.002), mat_rubber)
	# Chunky gleaming .50 AE flat-nose hollow-point top round in magazine lips!
	_add_cyl(mag, "Top50Case", 0.0068, 0.0068, 0.032, Vector3(0, 0.056, 0.004), mat_brass, 12)
	_add_cyl(mag, "Top50Bullet", 0.0052, 0.0065, 0.014, Vector3(0, 0.056, -0.018), mat_copper, 12)

	# ==========================================
	# 4. ANIMATED HEAVY BRUSHED-CHROME CUTAWAY SLIDE ("Slide")
	# ==========================================
	var slide := Node3D.new()
	slide.name = "Slide"
	slide.position = Vector3.ZERO
	root.add_child(slide)
	# Heavy rear slide block + signature forward slide side arms straddling the fixed barrel!
	_add_box(slide, "SlideRearBlock", Vector3(0.039, 0.042, 0.098), Vector3(0, 0.037, 0.030), mat_chrome)
	_add_box(slide, "SlideTopCrown", Vector3(0.031, 0.008, 0.094), Vector3(0, 0.059, 0.030), mat_chrome)
	_add_box(slide, "SlideArmL", Vector3(0.0085, 0.032, 0.102), Vector3(-0.0175, 0.032, -0.064), mat_chrome)
	_add_box(slide, "SlideArmR", Vector3(0.0085, 0.032, 0.102), Vector3(0.0175, 0.032, -0.064), mat_chrome)
	# Internal rotating AR-style locking bolt head visible in top cutaway breech!
	_add_cyl(slide, "InternalBoltHead", 0.011, 0.011, 0.038, Vector3(0, 0.038, -0.022), mat_dark, 12)
	# 6 crisp angled rear slide cocking serrations on both sides
	for si in range(6):
		var sz: float = 0.006 + float(si) * 0.0095
		for sx in [-0.020, 0.020]:
			_add_box(slide, "Serration", Vector3(0.0022, 0.026, 0.0038), Vector3(sx, 0.036, sz), mat_dark, Vector3(14.0, 0, 0))
	# Ambidextrous wing safety levers with red fire-ready indicator dots!
	for sx in [-1.0, 1.0]:
		_add_box(slide, "SafetyWing", Vector3(0.007, 0.009, 0.024), Vector3(0.0225 * sx, 0.046, 0.060), mat_dark, Vector3(-12.0, 0, 0))
		_add_cyl(slide, "SafetyFireDot", 0.0024, 0.0024, 0.003, Vector3(0.0202 * sx, 0.048, 0.046), mat_red, 8, Vector3(0, 0, 90))
	# Rear combat iron sights with twin glowing green tritium dots (aligned at y = +0.066!)
	_add_box(slide, "RearSightBase", Vector3(0.028, 0.006, 0.016), Vector3(0, 0.061, 0.068), mat_dark)
	_add_box(slide, "RearSightL", Vector3(0.0085, 0.010, 0.015), Vector3(-0.0095, 0.066, 0.068), mat_dark)
	_add_box(slide, "RearSightR", Vector3(0.0085, 0.010, 0.015), Vector3(0.0095, 0.066, 0.068), mat_dark)
	_add_box(slide, "RearDotL", Vector3(0.0034, 0.0034, 0.003), Vector3(-0.0095, 0.066, 0.0765), mat_dot)
	_add_box(slide, "RearDotR", Vector3(0.0034, 0.0034, 0.003), Vector3(0.0095, 0.066, 0.0765), mat_dot)

	# ==========================================
	# 5. MUZZLE & EJECTION MARKERS
	# ==========================================
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.038, -0.198)
	root.add_child(muzzle)

	var eject := Marker3D.new()
	eject.name = "EjectMarker"
	eject.position = Vector3(0.026, 0.048, -0.020)
	root.add_child(eject)

	return root
