class_name VFXFactory
extends RefCounted

# AAA-Style Procedural Shader & Particle VFX Library (Rebuilt from Scratch)
# Provides volumetric muzzle flashes, billowing soft billboard smoke, turbulent shader fireballs,
# Mach shockwaves, glowing ember showers, RPG backblast, and enemy gunfire flashes.

static var _cached_smoke_shader: Shader = null
static var _cached_fireball_shader: Shader = null
static var _cached_flash_shader: Shader = null
static var _cached_scorch_shader: Shader = null

static func get_soft_smoke_shader() -> Shader:
	if not _cached_smoke_shader:
		_cached_smoke_shader = Shader.new()
		_cached_smoke_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 smoke_color : source_color = vec4(0.28, 0.27, 0.26, 0.65);

void vertex() {
	mat4 mat_world = mat4(
		normalize(INV_VIEW_MATRIX[0]),
		normalize(INV_VIEW_MATRIX[1]),
		normalize(INV_VIEW_MATRIX[2]),
		MODEL_MATRIX[3]
	);
	float ang = INSTANCE_CUSTOM.x;
	mat_world = mat_world * mat4(
		vec4(cos(ang), -sin(ang), 0.0, 0.0),
		vec4(sin(ang),  cos(ang), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float n = vnoise(UV * 4.5) * 0.6 + vnoise(UV * 9.0) * 0.4;
	float cloud = smoothstep(0.50, 0.14, r + (n - 0.5) * 0.22);
	float shade = mix(0.72, 1.15, 0.5 - p.y + (n - 0.5) * 0.35);
	ALBEDO = smoke_color.rgb * COLOR.rgb * shade;
	ALPHA = cloud * smoke_color.a * COLOR.a;
}
"""
	return _cached_smoke_shader

static func get_fireball_shader() -> Shader:
	if not _cached_fireball_shader:
		_cached_fireball_shader = Shader.new()
		_cached_fireball_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float heat : hint_range(0.0, 2.0) = 1.4;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0,0,0));
	float n100 = hash31(i + vec3(1,0,0));
	float n010 = hash31(i + vec3(0,1,0));
	float n110 = hash31(i + vec3(1,1,0));
	float n001 = hash31(i + vec3(0,0,1));
	float n101 = hash31(i + vec3(1,0,1));
	float n011 = hash31(i + vec3(0,1,1));
	float n111 = hash31(i + vec3(1,1,1));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

varying vec3 v_local_pos;

void vertex() {
	float n = noise3(VERTEX * 2.4 + vec3(0.0, -TIME * 2.6, 0.0));
	VERTEX += NORMAL * (n - 0.35) * 0.36;
	v_local_pos = VERTEX;
}

void fragment() {
	float n = noise3(v_local_pos * 3.0 + vec3(0.0, -TIME * 3.8, 0.0)) * 0.65 + noise3(v_local_pos * 6.5) * 0.35;
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.6);
	float val = n - dissolve * 1.15;
	if (val < 0.02) {
		discard;
	}
	// Blackbody fire palette: soot edge -> deep crimson -> bright orange -> white-yellow core
	vec3 col = mix(vec3(0.14, 0.06, 0.04), vec3(0.95, 0.22, 0.03), smoothstep(0.02, 0.26, val));
	col = mix(col, vec3(1.0, 0.62, 0.10), smoothstep(0.24, 0.50, val));
	col = mix(col, vec3(1.0, 0.96, 0.78), smoothstep(0.48, 0.76, val));
	col *= mix(1.0, 0.55, fres * dissolve);
	ALBEDO = col * heat;
	ALPHA = smoothstep(0.02, 0.14, val) * (1.0 - dissolve * 0.85);
}
"""
	return _cached_fireball_shader

static func get_muzzle_flash_shader() -> Shader:
	if not _cached_flash_shader:
		_cached_flash_shader = Shader.new()
		_cached_flash_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 core_color : source_color = vec4(1.0, 0.94, 0.72, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.45, 0.08, 1.0);
uniform float intensity : hint_range(0.0, 4.0) = 2.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float ang = atan(p.y, p.x);
	// Jagged radial hot-gas flame star
	float star = 0.28 + 0.18 * pow(abs(cos(ang * 3.0)), 1.6) + 0.06 * sin(ang * 9.0);
	float mask = smoothstep(star, 0.04, r);
	float core = smoothstep(0.16, 0.0, r);
	vec3 col = mix(edge_color.rgb, core_color.rgb, core) * intensity;
	ALBEDO = col;
	ALPHA = clamp(mask, 0.0, 1.0);
}
"""
	return _cached_flash_shader

static func get_scorch_shader() -> Shader:
	if not _cached_scorch_shader:
		_cached_scorch_shader = Shader.new()
		_cached_scorch_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float opacity : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float ang = atan(p.y, p.x);
	float edge = 0.42 + 0.07 * sin(ang * 7.0) * cos(ang * 5.0);
	float m = smoothstep(edge, 0.08, r);
	float center_hole = smoothstep(0.18, 0.04, r);
	ALBEDO = mix(vec3(0.08, 0.07, 0.06), vec3(0.015, 0.015, 0.018), center_hole);
	ALPHA = m * opacity;
}
"""
	return _cached_scorch_shader

static func create_soft_smoke_material(tint: Color = Color(0.55, 0.54, 0.52, 0.55)) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = get_soft_smoke_shader()
	mat.set_shader_parameter("smoke_color", tint)
	return mat

# Builds a volumetric multi-plane 3D muzzle flash rig (star core + forward plasma cone + twin side brake jets + dynamic light!)
static func build_muzzle_flash_rig() -> Node3D:
	var root := Node3D.new()
	root.name = "MuzzleFlashRig"
	
	var star_mat := ShaderMaterial.new()
	star_mat.shader = get_muzzle_flash_shader()
	star_mat.set_shader_parameter("intensity", 2.2)
	
	# Front facing volumetric star card
	var front_q := MeshInstance3D.new()
	front_q.name = "StarCard"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.28, 0.28)
	front_q.mesh = qm
	front_q.material_override = star_mat
	front_q.position = Vector3(0, 0, -0.02)
	root.add_child(front_q)
	
	# 3 crossed longitudinal flame petals extending forward along -Z
	var jet_sh := Shader.new()
	jet_sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.76, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.42, 0.06, 1.0);
void fragment() {
	float along = UV.x; // 0 = muzzle base, 1 = flame tip
	float width = abs(UV.y - 0.5) * 2.0;
	float envelope = sin(along * 3.14159265) * (1.0 - along * 0.45);
	float mask = smoothstep(max(envelope, 0.01), 0.0, width) * (1.0 - smoothstep(0.75, 1.0, along));
	float hot = smoothstep(0.45, 0.0, along) * smoothstep(0.45, 0.0, width);
	ALBEDO = mix(edge_color.rgb, core_color.rgb, hot) * 2.1;
	ALPHA = clamp(mask, 0.0, 1.0);
}
"""
	var jet_mat := ShaderMaterial.new()
	jet_mat.shader = jet_sh
	
	for i in range(3):
		var petal := MeshInstance3D.new()
		petal.name = "FlamePetal_%d" % i
		var pm := QuadMesh.new()
		pm.size = Vector2(0.32, 0.14)
		petal.mesh = pm
		petal.material_override = jet_mat
		petal.position = Vector3(0, 0, -0.15)
		petal.rotation_degrees = Vector3(0, 90.0, float(i) * 60.0)
		root.add_child(petal)
		
	# Twin angled side compensator jets (for AK slant brake / shotgun blast)
	var side_jets := Node3D.new()
	side_jets.name = "SideJets"
	root.add_child(side_jets)
	for sx in [-1.0, 1.0]:
		var sj := MeshInstance3D.new()
		var sjm := QuadMesh.new()
		sjm.size = Vector2(0.18, 0.075)
		sj.mesh = sjm
		sj.material_override = jet_mat
		sj.position = Vector3(0.08 * sx, 0.02, -0.02)
		sj.rotation_degrees = Vector3(0, 18.0 * sx, 16.0 * sx)
		side_jets.add_child(sj)
		
	var light := OmniLight3D.new()
	light.name = "OmniLight3D"
	light.light_color = Color(1.0, 0.74, 0.34)
	light.light_energy = 3.2
	light.omni_range = 7.5
	light.position = Vector3(0, 0, -0.12)
	root.add_child(light)
	
	return root

# Builds a clean soft billowing gunsmoke particle emitter (replaces solid sphere smoke!)
static func build_muzzle_smoke_emitter() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "MuzzleSmoke"
	p.emitting = false
	p.one_shot = true
	p.local_coords = false
	p.explosiveness = 0.72
	p.amount = 14
	p.lifetime = 0.75
	p.direction = Vector3(0, 0.35, -1.0)
	p.spread = 32.0
	p.gravity = Vector3(0, 1.15, 0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 2.4
	p.damping_min = 2.2
	p.damping_max = 3.6
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -45.0
	p.angular_velocity_max = 45.0
	
	var sc_curve := Curve.new()
	sc_curve.add_point(Vector2(0.0, 0.35))
	sc_curve.add_point(Vector2(0.45, 1.15))
	sc_curve.add_point(Vector2(1.0, 2.05))
	p.scale_amount_curve = sc_curve
	
	var grad := Gradient.new()
	grad.set_color(0, Color(0.92, 0.90, 0.86, 0.52))
	grad.add_point(0.35, Color(0.68, 0.68, 0.70, 0.34))
	grad.set_color(grad.get_point_count() - 1, Color(0.45, 0.45, 0.48, 0.0))
	p.color_ramp = grad
	
	var qm := QuadMesh.new()
	qm.size = Vector2(0.22, 0.22)
	qm.material = create_soft_smoke_material(Color(0.82, 0.80, 0.78, 0.68))
	p.mesh = qm
	return p

# Brief hot spark puff from ejection port / muzzle
static func build_muzzle_sparks_emitter() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "AK_Sparks"
	p.emitting = false
	p.one_shot = true
	p.local_coords = false
	p.explosiveness = 0.96
	p.amount = 10
	p.lifetime = 0.24
	p.direction = Vector3(0.4, 0.2, -1.0)
	p.spread = 42.0
	p.gravity = Vector3(0, -10.0, 0)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 9.5
	var bm := BoxMesh.new()
	bm.size = Vector3(0.008, 0.008, 0.045)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.84, 0.32)
	bm.material = mat
	p.mesh = bm
	return p

# Crisp battlefield muzzle flash for Enemy gunfire (Red AK, Blue Pistol, Green AWP)
static func spawn_enemy_muzzle_flash(parent: Node, pos: Vector3, dir: Vector3, tint: Color = Color(1.0, 0.65, 0.22), scale_mult: float = 1.0) -> void:
	if not parent:
		return
	var vfx := Node3D.new()
	vfx.position = pos
	parent.add_child(vfx)
	vfx.global_position = pos
	if dir.length_squared() > 0.001:
		var n := dir.normalized()
		var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
		vfx.look_at(pos + n, up)
		
	var rig := build_muzzle_flash_rig()
	rig.scale = Vector3.ONE * (1.25 * scale_mult)
	rig.rotation.z = randf_range(0.0, TAU)
	var l: OmniLight3D = rig.get_node_or_null("OmniLight3D")
	if l:
		l.light_color = tint
		l.light_energy = 3.6 * scale_mult
	vfx.add_child(rig)
	
	# Tiny quick gunsmoke puff
	var sm := build_muzzle_smoke_emitter()
	sm.amount = 5
	sm.lifetime = 0.45
	sm.position = Vector3.ZERO
	vfx.add_child(sm)
	sm.emitting = true
	
	var tw := vfx.create_tween()
	tw.tween_property(rig, "scale", Vector3.ONE * (0.2 * scale_mult), 0.055)
	if l:
		tw.parallel().tween_property(l, "light_energy", 0.0, 0.07)
	tw.tween_callback(func():
		if is_instance_valid(rig):
			rig.visible = false
	)
	vfx.get_tree().create_timer(0.55).timeout.connect(vfx.queue_free)

# Dramatic RPG-7 Rear Venturi Backblast cone + billowing blast smoke
static func spawn_rpg_backblast(parent: Node, pos: Vector3, back_dir: Vector3) -> void:
	if not parent:
		return
	var vfx := Node3D.new()
	vfx.position = pos
	parent.add_child(vfx)
	vfx.global_position = pos
	var n := back_dir.normalized()
	if n.length_squared() > 0.001:
		var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
		vfx.look_at(pos + n, up)
		
	var smoke := build_muzzle_smoke_emitter()
	smoke.amount = 24
	smoke.lifetime = 1.15
	smoke.spread = 38.0
	smoke.initial_velocity_min = 3.5
	smoke.initial_velocity_max = 8.5
	vfx.add_child(smoke)
	smoke.emitting = true
	
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.60, 0.18)
	l.light_energy = 5.5
	l.omni_range = 8.0
	vfx.add_child(l)
	var tw := vfx.create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.14)
	vfx.get_tree().create_timer(1.3).timeout.connect(vfx.queue_free)

# Cinematic 4-Stage Volumetric Explosion (RPG-7 Warhead & Shahed-136 Detonation!)
static func spawn_explosion(parent: Node, pos: Vector3, normal: Vector3 = Vector3.UP, scale_mult: float = 1.0) -> void:
	if not parent:
		return
	var vfx := Node3D.new()
	vfx.name = "VolumetricExplosionVFX"
	vfx.position = pos
	parent.add_child(vfx)
	vfx.global_position = pos
	
	# 1. Blinding Dynamic Explosion Light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.64, 0.22)
	light.light_energy = 14.0 * scale_mult
	light.omni_range = 22.0 * scale_mult
	vfx.add_child(light)
	
	# 2. Inner White-Hot Flash Core
	var core := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.72 * scale_mult
	cm.height = 1.44 * scale_mult
	cm.radial_segments = 16
	cm.rings = 10
	core.mesh = cm
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	core_mat.albedo_color = Color(1.0, 0.96, 0.80, 0.95)
	core.material_override = core_mat
	vfx.add_child(core)
	
	# 3. Turbulent Volumetric Shader Fireball Cluster (5 offset churning fire plumes!)
	var fire_mats: Array[ShaderMaterial] = []
	var fire_nodes: Array[MeshInstance3D] = []
	var offsets := [
		Vector3(0.0, 0.25, 0.0),
		Vector3(0.45, 0.55, 0.35),
		Vector3(-0.48, 0.45, -0.32),
		Vector3(0.32, 0.82, -0.44),
		Vector3(-0.36, 0.78, 0.42)
	]
	for i in range(offsets.size()):
		var fb := MeshInstance3D.new()
		var fbm := SphereMesh.new()
		var r: float = (1.10 if i == 0 else randf_range(0.68, 0.92)) * scale_mult
		fbm.radius = r
		fbm.height = r * 2.0
		fbm.radial_segments = 18
		fbm.rings = 12
		fb.mesh = fbm
		var fmat := ShaderMaterial.new()
		fmat.shader = get_fireball_shader()
		fmat.set_shader_parameter("dissolve", 0.0)
		fmat.set_shader_parameter("heat", 1.75 if i == 0 else 1.45)
		fb.material_override = fmat
		fb.position = offsets[i] * scale_mult
		fb.scale = Vector3(0.35, 0.35, 0.35)
		vfx.add_child(fb)
		fire_mats.append(fmat)
		fire_nodes.append(fb)
		
	# 4. Supersonic Expanding Shockwave Ring oriented to impact normal
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.82 * scale_mult
	rm.outer_radius = 1.05 * scale_mult
	rm.rings = 24
	rm.ring_segments = 10
	ring.mesh = rm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.albedo_color = Color(1.0, 0.84, 0.55, 0.72)
	ring.material_override = ring_mat
	vfx.add_child(ring)
	var n := normal.normalized() if normal.length_squared() > 0.01 else Vector3.UP
	if absf(n.dot(Vector3.UP)) < 0.98:
		ring.look_at(pos + n, Vector3.UP)
		ring.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
		
	# 5. Scorched Blast Crater Mark on impact surface (fades out after 10s)
	var scorch := MeshInstance3D.new()
	var sqm := QuadMesh.new()
	sqm.size = Vector2(3.6 * scale_mult, 3.6 * scale_mult)
	scorch.mesh = sqm
	var smat := ShaderMaterial.new()
	smat.shader = get_scorch_shader()
	smat.set_shader_parameter("opacity", 0.82)
	scorch.material_override = smat
	scorch.position = n * 0.03
	vfx.add_child(scorch)
	if absf(n.dot(Vector3.UP)) > 0.98:
		scorch.rotation_degrees = Vector3(-90.0, randf_range(0, 360), 0)
	else:
		scorch.look_at(pos + n * 2.0, Vector3.UP)
		
	# 6. Billowing Dark Rising Mushroom Smoke Cloud (Soft Billboard Shader Cards!)
	var smoke := CPUParticles3D.new()
	smoke.emitting = false
	smoke.local_coords = true
	smoke.one_shot = true
	smoke.explosiveness = 0.88
	smoke.amount = 34
	smoke.lifetime = 2.35
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 115.0
	smoke.gravity = Vector3(0, 2.2, 0)
	smoke.initial_velocity_min = 2.4 * scale_mult
	smoke.initial_velocity_max = 7.2 * scale_mult
	smoke.damping_min = 2.4
	smoke.damping_max = 4.2
	smoke.angle_min = 0.0
	smoke.angle_max = 360.0
	smoke.angular_velocity_min = -40.0
	smoke.angular_velocity_max = 40.0
	var sm_sc := Curve.new()
	sm_sc.add_point(Vector2(0.0, 0.55))
	sm_sc.add_point(Vector2(0.4, 1.55))
	sm_sc.add_point(Vector2(1.0, 2.65))
	smoke.scale_amount_curve = sm_sc
	var sm_grad := Gradient.new()
	sm_grad.set_color(0, Color(0.95, 0.45, 0.14, 0.78))
	sm_grad.add_point(0.18, Color(0.18, 0.16, 0.15, 0.82))
	sm_grad.add_point(0.65, Color(0.14, 0.14, 0.15, 0.55))
	sm_grad.set_color(sm_grad.get_point_count() - 1, Color(0.12, 0.12, 0.13, 0.0))
	smoke.color_ramp = sm_grad
	var sq := QuadMesh.new()
	sq.size = Vector2(1.45 * scale_mult, 1.45 * scale_mult)
	sq.material = create_soft_smoke_material(Color(1.0, 1.0, 1.0, 0.90))
	smoke.mesh = sq
	vfx.add_child(smoke)
	
	# 7. Fiery Shrapnel & Glowing Ember Shower (gravity-arcing velocity-aligned sparks!)
	var embers := CPUParticles3D.new()
	embers.emitting = false
	embers.local_coords = true
	embers.one_shot = true
	embers.explosiveness = 0.96
	embers.amount = 44
	embers.lifetime = 1.15
	embers.direction = n
	embers.spread = 110.0
	embers.gravity = Vector3(0, -16.0, 0)
	embers.initial_velocity_min = 7.0 * scale_mult
	embers.initial_velocity_max = 19.0 * scale_mult
	embers.particle_flag_align_y = true
	var em_grad := Gradient.new()
	em_grad.set_color(0, Color(1.0, 0.96, 0.65, 1.0))
	em_grad.add_point(0.45, Color(1.0, 0.50, 0.10, 0.95))
	em_grad.set_color(em_grad.get_point_count() - 1, Color(0.55, 0.10, 0.02, 0.0))
	embers.color_ramp = em_grad
	var em_m := CylinderMesh.new()
	em_m.top_radius = 0.022
	em_m.bottom_radius = 0.005
	em_m.height = 0.34
	em_m.radial_segments = 5
	var em_mat := StandardMaterial3D.new()
	em_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em_mat.vertex_color_use_as_albedo = true
	em_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	em_m.material = em_mat
	embers.mesh = em_m
	vfx.add_child(embers)
	
	smoke.emitting = true
	embers.emitting = true
	
	# Animate multi-stage expansion, rising fireballs, shockwave & fade
	var tw := vfx.create_tween()
	tw.tween_property(core, "scale", Vector3(3.2, 3.2, 3.2), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(core_mat, "albedo_color:a", 0.0, 0.22)
	tw.parallel().tween_property(ring, "scale", Vector3(6.8, 1.0, 6.8), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring_mat, "albedo_color:a", 0.0, 0.36)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.55)
	for i in range(fire_nodes.size()):
		var fn := fire_nodes[i]
		var fm := fire_mats[i]
		var dur: float = 0.58 + float(i) * 0.06
		tw.parallel().tween_property(fn, "scale", Vector3(2.45, 2.65, 2.45), dur * 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(fn, "position:y", fn.position.y + 1.35 * scale_mult, dur)
		tw.parallel().tween_method(func(v: float):
			if is_instance_valid(fm):
				fm.set_shader_parameter("dissolve", v)
		, 0.0, 1.0, dur).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		for fn in fire_nodes:
			if is_instance_valid(fn):
				fn.visible = false
	)
	
	# Keep crater mark briefly, then fade & clean up
	var scorch_tw := vfx.create_tween()
	scorch_tw.tween_interval(6.0)
	scorch_tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("opacity", v)
	, 0.82, 0.0, 2.0)
	scorch_tw.tween_callback(vfx.queue_free)

# Colossal 2-Stage TBG-7V Thermobaric Fuel-Air Vacuum Detonation!
# Visually unmistakable: giant 3.2x billowing orange-crimson mushroom fireball + DOUBLE supersonic shockwave rings + fiery pillar!
static func spawn_thermobaric_explosion(parent: Node, pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	if not parent:
		return
	# Huge primary fuel-air fireball cluster (nearly 2x larger than standard PG-7V!)
	spawn_explosion(parent, pos, normal, 3.25)

	var vfx := Node3D.new()
	vfx.name = "ThermobaricFuelAirVFX"
	vfx.position = pos
	parent.add_child(vfx)
	vfx.global_position = pos

	# Secondary gigantic crimson-orange fuel-air overpressure dome + rising mushroom stem
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 2.6
	dm.height = 5.2
	dm.radial_segments = 24
	dm.rings = 16
	dome.mesh = dm
	var dmat := ShaderMaterial.new()
	dmat.shader = get_fireball_shader()
	dmat.set_shader_parameter("dissolve", 0.0)
	dmat.set_shader_parameter("heat", 2.35)
	dome.material_override = dmat
	dome.position = Vector3(0, 1.8, 0)
	dome.scale = Vector3(0.4, 0.3, 0.4)
	vfx.add_child(dome)

	var cap := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 3.2
	cm.height = 4.0
	cm.radial_segments = 24
	cm.rings = 14
	cap.mesh = cm
	var cmat := ShaderMaterial.new()
	cmat.shader = get_fireball_shader()
	cmat.set_shader_parameter("dissolve", 0.0)
	cmat.set_shader_parameter("heat", 2.15)
	cap.material_override = cmat
	cap.position = Vector3(0, 3.2, 0)
	cap.scale = Vector3(0.3, 0.25, 0.3)
	vfx.add_child(cap)

	# Massive secondary overpressure vacuum shockwave ring expanding across 25m!
	var wave := MeshInstance3D.new()
	var wm := TorusMesh.new()
	wm.inner_radius = 1.8
	wm.outer_radius = 2.35
	wm.rings = 32
	wm.ring_segments = 12
	wave.mesh = wm
	var wmat := StandardMaterial3D.new()
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wmat.albedo_color = Color(1.0, 0.54, 0.14, 0.85)
	wave.material_override = wmat
	wave.position = Vector3(0, 0.35, 0)
	vfx.add_child(wave)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.42, 0.08)
	light.light_energy = 32.0
	light.omni_range = 52.0
	light.position = Vector3(0, 2.5, 0)
	vfx.add_child(light)

	var tw := vfx.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dome, "scale", Vector3(3.4, 3.8, 3.4), 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dome, "position:y", 5.8, 1.35)
	tw.tween_property(cap, "scale", Vector3(4.2, 2.8, 4.2), 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(cap, "position:y", 11.5, 1.55)
	tw.tween_property(wave, "scale", Vector3(11.5, 1.2, 11.5), 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(wmat, "albedo_color:a", 0.0, 0.62)
	tw.tween_property(light, "light_energy", 0.0, 1.35)
	tw.tween_method(func(v: float):
		if is_instance_valid(dmat): dmat.set_shader_parameter("dissolve", v)
		if is_instance_valid(cmat): cmat.set_shader_parameter("dissolve", v)
	, 0.0, 1.0, 1.50).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(vfx.queue_free)

# Focused PG-7VR Tandem HEAT Armor-Piercing Shaped-Charge Plasma Jet VFX!
static func spawn_tandem_explosion(parent: Node, pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	if not parent:
		return
	# Tighter, sharper shaped-charge blast (1.25x vs 1.75x standard) + intense blue-white copper-jet flash & armor spall!
	spawn_explosion(parent, pos, normal, 1.25)

	var vfx := Node3D.new()
	vfx.name = "TandemHEATJetVFX"
	vfx.position = pos
	parent.add_child(vfx)
	vfx.global_position = pos

	var jet_light := OmniLight3D.new()
	jet_light.light_color = Color(0.82, 0.92, 1.0)
	jet_light.light_energy = 24.0
	jet_light.omni_range = 20.0
	vfx.add_child(jet_light)

	# Molten copper armor-penetration spark shower!
	var spall := CPUParticles3D.new()
	spall.one_shot = true
	spall.explosiveness = 0.98
	spall.amount = 64
	spall.lifetime = 0.85
	spall.direction = normal.normalized() if normal.length_squared() > 0.01 else Vector3.UP
	spall.spread = 52.0
	spall.gravity = Vector3(0, -18.0, 0)
	spall.initial_velocity_min = 12.0
	spall.initial_velocity_max = 28.0
	spall.particle_flag_align_y = true
	var sm := CylinderMesh.new()
	sm.top_radius = 0.025
	sm.bottom_radius = 0.004
	sm.height = 0.55
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(0.85, 0.95, 1.0)
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.material = smat
	spall.mesh = sm
	vfx.add_child(spall)
	spall.emitting = true

	var tw := vfx.create_tween()
	tw.tween_property(jet_light, "light_energy", 0.0, 0.25)
	tw.tween_interval(0.8)
	tw.tween_callback(vfx.queue_free)
