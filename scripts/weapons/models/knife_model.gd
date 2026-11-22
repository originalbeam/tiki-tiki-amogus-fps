class_name KnifeModel
extends RefCounted

# High-Fidelity Procedural 6H5 / Ka-Bar Tactical Combat Bayonet Knife
# Features:
# - Multi-bevel clip-point steel blade with matte TiN dark spine & mirror-honed silver edge
# - Recessed blood fuller, serrated sawback spine teeth & bayonet wire-cutter aperture slot
# - Blackened steel crossguard with authentic bayonet muzzle-ring collar & locking lug
# - Contoured olive-drab rubberized handle with tactical finger grooves, steel rivets & skull-crusher pommel
# - Upgraded shader-driven metallic wind-shear slash trail ("AirSlashEffect")

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

static func build_knife_model(knife_idle_pos: Vector3 = Vector3(0.24, -0.22, -0.32), knife_idle_rot: Vector3 = Vector3(-12.0, 15.0, 8.0)) -> Node3D:
	var root := Node3D.new()
	root.name = "Knife"
	root.position = knife_idle_pos
	root.rotation_degrees = knife_idle_rot
	
	var mat_blade_coat := StandardMaterial3D.new()
	mat_blade_coat.albedo_color = Color(0.22, 0.24, 0.27) # Satin dark titanium-nitride blade flat
	mat_blade_coat.metallic = 0.92
	mat_blade_coat.roughness = 0.26
	
	var mat_edge := StandardMaterial3D.new()
	mat_edge.albedo_color = Color(0.92, 0.95, 0.98) # Mirror-honed razor cutting bevel
	mat_edge.metallic = 0.99
	mat_edge.roughness = 0.10
	
	var mat_dark_steel := StandardMaterial3D.new()
	mat_dark_steel.albedo_color = Color(0.11, 0.12, 0.14)
	mat_dark_steel.metallic = 0.88
	mat_dark_steel.roughness = 0.34
	
	var mat_grip := StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.18, 0.22, 0.16) # Military olive polymer handle
	mat_grip.roughness = 0.72
	mat_grip.metallic = 0.05
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.07, 0.08, 0.08)
	mat_rubber.roughness = 0.90

	# ==========================================
	# 1. MULTI-BEVEL CLIP-POINT BLADE
	# ==========================================
	# Thick central spine & main flat
	_add_box(root, "BladeSpine", Vector3(0.0065, 0.026, 0.215), Vector3(0, 0.008, -0.115), mat_blade_coat)
	# Mirror-polished lower razor bevel edge
	_add_box(root, "BladeEdge", Vector3(0.0028, 0.013, 0.212), Vector3(0, -0.011, -0.114), mat_edge)
	# Ricasso base near guard
	_add_box(root, "Ricasso", Vector3(0.0075, 0.036, 0.028), Vector3(0, 0.002, -0.020), mat_blade_coat)
	# Recessed fuller / blood groove along both faces
	_add_box(root, "Fuller", Vector3(0.0080, 0.007, 0.135), Vector3(0, 0.009, -0.108), mat_dark_steel)
	# Serrated sawback spine teeth
	for i in range(7):
		_add_box(root, "SawTooth_%d" % i, Vector3(0.0055, 0.005, 0.006), Vector3(0, 0.022, -0.055 - float(i) * 0.014), mat_edge, Vector3(32.0, 0, 0))
	# Bayonet wire-cutter slot boss
	_add_box(root, "WireCutterSlot", Vector3(0.0085, 0.006, 0.018), Vector3(0, -0.002, -0.145), mat_dark_steel)
	
	# Razor Clip-Point Tip (beveled upper swedge + mirror edge)
	var tip := MeshInstance3D.new()
	tip.name = "Tip"
	var tip_m := PrismMesh.new()
	tip_m.size = Vector3(0.0055, 0.036, 0.062)
	tip.mesh = tip_m
	tip.material_override = mat_edge
	tip.position = Vector3(0, -0.001, -0.248)
	tip.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(tip)

	# ==========================================
	# 2. BAYONET CROSSGUARD & MUZZLE RING
	# ==========================================
	_add_box(root, "Crossguard", Vector3(0.018, 0.072, 0.013), Vector3(0, 0.002, -0.006), mat_dark_steel)
	_add_box(root, "GuardQuillonLow", Vector3(0.016, 0.014, 0.020), Vector3(0, -0.032, -0.002), mat_dark_steel, Vector3(-25.0, 0, 0))
	var ring := MeshInstance3D.new()
	ring.name = "BarrelRing"
	var rm := TorusMesh.new()
	rm.inner_radius = 0.0095
	rm.outer_radius = 0.0165
	rm.rings = 16
	rm.ring_segments = 10
	ring.mesh = rm
	ring.material_override = mat_dark_steel
	ring.position = Vector3(0, 0.044, -0.006)
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	root.add_child(ring)

	# ==========================================
	# 3. CONTOURED TACTICAL GRIP & SKULL-CRUSHER POMMEL
	# ==========================================
	# Contoured ergonomic oval grip core
	var grip_core := _add_cyl(root, "Grip", 0.0165, 0.0155, 0.132, Vector3(0, 0.0, 0.068), mat_grip, 14)
	grip_core.scale = Vector3(0.84, 1.0, 1.22)
	# Deep rubberized anti-slip grip rings
	for i in range(5):
		var gr := _add_cyl(root, "GripRib_%d" % i, 0.0178, 0.0178, 0.007, Vector3(0, 0.0, 0.024 + float(i) * 0.022), mat_rubber, 14)
		gr.scale = Vector3(0.86, 1.0, 1.24)
	# Heavy steel bayonet locking pommel + release lug + lanyard hole
	_add_box(root, "PommelBase", Vector3(0.026, 0.038, 0.024), Vector3(0, 0.0, 0.142), mat_dark_steel)
	_add_box(root, "PommelLug", Vector3(0.016, 0.010, 0.014), Vector3(0, 0.021, 0.144), mat_edge)
	var striker := MeshInstance3D.new()
	striker.name = "SkullCrusher"
	var sm := PrismMesh.new()
	sm.size = Vector3(0.022, 0.028, 0.016)
	striker.mesh = sm
	striker.material_override = mat_dark_steel
	striker.position = Vector3(0, 0.0, 0.160)
	striker.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	root.add_child(striker)

	return root

static func build_air_slash_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "AirSlashEffect"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments := 28
	for i in range(segments):
		var t0: float = float(i) / float(segments)
		var t1: float = float(i + 1) / float(segments)
		
		var x0: float = lerpf(0.28, -0.28, t0)
		var y0: float = -0.02 + sin(t0 * PI) * 0.07 - (t0 * t0) * 0.16
		var z0: float = -0.08 - 0.24 * sin(t0 * PI) + 0.05 * (t0 * t0)
		
		var x1: float = lerpf(0.28, -0.28, t1)
		var y1: float = -0.02 + sin(t1 * PI) * 0.07 - (t1 * t1) * 0.16
		var z1: float = -0.08 - 0.24 * sin(t1 * PI) + 0.05 * (t1 * t1)
		
		var w0: float = 0.042 * sin(t0 * PI)
		var w1: float = 0.042 * sin(t1 * PI)
		
		var p0_in := Vector3(x0, y0 - w0, z0 + w0 * 0.6)
		var p0_out := Vector3(x0, y0 + w0, z0 - w0 * 0.6)
		var p1_in := Vector3(x1, y1 - w1, z1 + w1 * 0.6)
		var p1_out := Vector3(x1, y1 + w1, z1 - w1 * 0.6)
		
		st.set_uv(Vector2(t0, 0.0))
		st.add_vertex(p0_in)
		st.set_uv(Vector2(t0, 1.0))
		st.add_vertex(p0_out)
		st.set_uv(Vector2(t1, 1.0))
		st.add_vertex(p1_out)
		
		st.set_uv(Vector2(t0, 0.0))
		st.add_vertex(p0_in)
		st.set_uv(Vector2(t1, 1.0))
		st.add_vertex(p1_out)
		st.set_uv(Vector2(t1, 0.0))
		st.add_vertex(p1_in)
		
	mi.mesh = st.commit()
	
	# Metallic wind-shear blade arc shader (bright honed steel leading edge + soft vapor wake)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform float slash_alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float along = sin(UV.x * 3.14159265);
	float edge_core = smoothstep(0.55, 0.96, UV.y);
	float wake = smoothstep(0.0, 0.85, UV.y) * 0.45;
	float a = (edge_core + wake) * along * slash_alpha;
	vec3 col = mix(vec3(0.55, 0.78, 1.0), vec3(1.0, 0.98, 0.94), edge_core);
	ALBEDO = col * 1.4;
	ALPHA = clamp(a, 0.0, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mi.material_override = mat
	mi.visible = false
	return mi

static func create_preview() -> Node3D:
	var root := Node3D.new()
	root.name = "KnifePreview"
	var k := build_knife_model(Vector3.ZERO, Vector3.ZERO)
	k.position = Vector3(0, 0, 0.04)
	k.rotation_degrees = Vector3(0, 45, 0)
	root.add_child(k)
	return root
