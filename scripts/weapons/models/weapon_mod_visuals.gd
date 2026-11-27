class_name WeaponModVisuals
extends RefCounted

const RPGModelScript = preload("res://scripts/weapons/models/rpg_model.gd")

# Universal Museum-Grade 3D Attachment & Modification Builder for ALL 10 Weapons
# Handles:
# 1) Live attachment mounting & vanilla part replacement on both Viewmodels & Workbench 3D previews
# 2) Real PiP optical lenses: Red Dot, EOTech Holo, ACOG 4x, LPVO, ZF39, Nightforce 6-12x,
#    1PN93 Green Phosphor NVG Shader & FLIR RS-32 Thermal Heat-Signature Shader!
# 3) Exact optical centerline ADS computation for every weapon + optic combination
# 4) Exact 3D Workbench EFT slot anchors & 3D square-slot miniatures for all 12 mod categories

static func _box(parent: Node3D, nm: String, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, nm: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 14, rot_deg: Vector3 = Vector3(-90.0, 0.0, 0.0)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
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

static func _mat(col: Color, met: float = 0.0, rough: float = 0.5, emit: Color = Color.BLACK, emit_e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = met
	m.roughness = rough
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	return m

# Shared mount geometry table per weapon (model-local coordinates, -Z forward)
static func _get_mounts(weapon_id: String) -> Dictionary:
	match weapon_id:
		"ak47":
			return {
				"model_off": Vector3.ZERO,
				"optic_base": Vector3(0.0, 0.0585, 0.008),
				"rail": Vector3(0.0, 0.054, 0.015),
				"side_rail": Vector3(-0.025, 0.018, 0.005),
				"muzzle": Vector3(0.0, 0.004, -0.575),
				"handguard": Vector3(0.0, 0.004, -0.232),
				"underbarrel": Vector3(0.0, -0.028, -0.255),
				"tactical_laser": Vector3(0.032, 0.008, -0.255),
				"flashlight": Vector3(-0.032, 0.006, -0.265),
				"magazine": Vector3(0.0, -0.042, -0.055),
				"pistol_grip": Vector3(0.0, -0.080, 0.082),
				"stock_adapter": Vector3(0.0, -0.008, 0.145),
				"buttstock": Vector3(0.0, -0.008, 0.305),
				"internal": Vector3(0.0, -0.041, 0.022),
				"ammo_type": Vector3(0.0, -0.115, -0.068)
			}
		"shotgun":
			return {
				"model_off": Vector3.ZERO,
				"optic_base": Vector3(0.0, 0.050, 0.005),
				"rail": Vector3(0.0, 0.046, 0.005),
				"muzzle": Vector3(0.0, 0.026, -0.655),
				"handguard": Vector3(0.0, -0.012, -0.320),
				"underbarrel": Vector3(0.0, -0.040, -0.325),
				"tactical_laser": Vector3(0.032, -0.008, -0.345),
				"flashlight": Vector3(-0.032, -0.008, -0.345),
				"magazine": Vector3(0.0, -0.012, -0.600),
				"stock_adapter": Vector3(0.0, -0.006, 0.132),
				"buttstock": Vector3(0.0, -0.014, 0.290),
				"internal": Vector3(0.0, -0.054, 0.070),
				"ammo_type": Vector3(-0.042, 0.004, -0.015)
			}
		"pistol":
			return {
				"model_off": Vector3(-0.02, 0.01, 0.04),
				"optic_base": Vector3(0.0, 0.0445, 0.012),
				"rail": Vector3(0.0, 0.041, 0.012),
				"muzzle": Vector3(0.0, 0.028, -0.106),
				"tactical_laser": Vector3(0.0, -0.004, -0.068),
				"flashlight": Vector3(0.0, -0.005, -0.074),
				"magazine": Vector3(0.0, -0.068, 0.053),
				"pistol_grip": Vector3(0.0, -0.062, 0.050),
				"internal": Vector3(0.0, -0.016, 0.008),
				"ammo_type": Vector3(0.0, -0.110, 0.060)
			}
		"rpg":
			return {
				"model_off": Vector3(0.05, 0.03, 0.14),
				"optic_base": Vector3(-0.062, 0.050, -0.155),
				"rail": Vector3(0.032, 0.004, -0.160),
				"tactical_laser": Vector3(0.042, 0.006, -0.165),
				"flashlight": Vector3(0.042, -0.012, -0.165),
				"ammo_type": Vector3(0.0, 0.0, -0.450)
			}
		"kar98k":
			return {
				"model_off": Vector3.ZERO,
				"optic_base": Vector3(0.0, 0.044, -0.285),
				"rail": Vector3(0.0, 0.040, -0.285),
				"muzzle": Vector3(0.0, 0.016, -0.675),
				"handguard": Vector3(0.0, -0.004, -0.320),
				"underbarrel": Vector3(0.0, -0.032, -0.350),
				"tactical_laser": Vector3(0.030, 0.002, -0.350),
				"flashlight": Vector3(-0.030, 0.002, -0.350),
				"magazine": Vector3(0.0, -0.036, -0.036),
				"stock_adapter": Vector3(0.0, -0.018, 0.105),
				"buttstock": Vector3(0.0, -0.022, 0.265),
				"internal": Vector3(0.0, -0.042, 0.045),
				"ammo_type": Vector3(0.0, -0.065, -0.036)
			}
		"pkm":
			return {
				"model_off": Vector3(0.02, -0.02, 0.04),
				"optic_base": Vector3(0.0, 0.058, -0.065),
				"rail": Vector3(0.0, 0.054, -0.065),
				"muzzle": Vector3(0.0, 0.024, -0.880),
				"handguard": Vector3(0.0, 0.004, -0.365),
				"underbarrel": Vector3(0.0, -0.030, -0.375),
				"tactical_laser": Vector3(0.034, 0.008, -0.385),
				"flashlight": Vector3(-0.034, 0.008, -0.385),
				"magazine": Vector3(0.012, -0.106, -0.115),
				"pistol_grip": Vector3(0.0, -0.088, 0.072),
				"stock_adapter": Vector3(0.0, -0.008, 0.118),
				"buttstock": Vector3(0.0, -0.012, 0.280),
				"internal": Vector3(0.0, -0.052, 0.020),
				"ammo_type": Vector3(0.045, -0.055, -0.115)
			}
		"l96a1":
			return {
				"model_off": Vector3.ZERO,
				"optic_base": Vector3(0.0, 0.048, -0.055),
				"muzzle": Vector3(0.0, 0.022, -0.840),
				"handguard": Vector3(0.0, -0.014, -0.300),
				"underbarrel": Vector3(0.0, -0.042, -0.310),
				"tactical_laser": Vector3(0.032, -0.010, -0.320),
				"flashlight": Vector3(-0.032, -0.010, -0.320),
				"magazine": Vector3(0.0, -0.068, -0.088),
				"stock_adapter": Vector3(0.0, -0.008, 0.095),
				"buttstock": Vector3(0.0, -0.010, 0.255),
				"internal": Vector3(0.0, -0.050, 0.024),
				"ammo_type": Vector3(0.0, -0.115, -0.088)
			}
		"deagle":
			return {
				"model_off": Vector3(-0.018, 0.008, 0.04),
				"optic_base": Vector3(0.0, 0.059, -0.088),
				"rail": Vector3(0.0, 0.011, -0.105),
				"muzzle": Vector3(0.0, 0.038, -0.184),
				"tactical_laser": Vector3(0.0, -0.003, -0.105),
				"flashlight": Vector3(0.0, -0.004, -0.112),
				"magazine": Vector3(0.0, -0.068, 0.058),
				"pistol_grip": Vector3(0.0, -0.058, 0.056),
				"internal": Vector3(0.0, -0.020, 0.014),
				"ammo_type": Vector3(0.0, -0.118, 0.062)
			}
		"aa12":
			return {
				"model_off": Vector3(0.01, -0.01, 0.02),
				"optic_base": Vector3(0.0, 0.058, -0.025),
				"rail": Vector3(0.0, 0.054, -0.025),
				"muzzle": Vector3(0.0, 0.018, -0.648),
				"handguard": Vector3(0.0, 0.004, -0.325),
				"underbarrel": Vector3(0.0, -0.030, -0.330),
				"tactical_laser": Vector3(0.034, 0.006, -0.335),
				"flashlight": Vector3(-0.034, 0.006, -0.335),
				"magazine": Vector3(0.0, -0.132, -0.100),
				"internal": Vector3(0.0, -0.062, 0.042),
				"ammo_type": Vector3(0.055, -0.120, -0.100)
			}
		"mg42":
			return {
				"model_off": Vector3(0.02, -0.02, 0.04),
				"optic_base": Vector3(0.0, 0.053, -0.065),
				"rail": Vector3(0.0, 0.049, -0.065),
				"muzzle": Vector3(0.0, 0.008, -0.885),
				"handguard": Vector3(0.0, 0.008, -0.420),
				"underbarrel": Vector3(0.0, -0.026, -0.400),
				"tactical_laser": Vector3(0.034, 0.008, -0.430),
				"flashlight": Vector3(-0.034, 0.008, -0.430),
				"magazine": Vector3(-0.094, -0.028, -0.125),
				"stock_adapter": Vector3(0.0, -0.004, 0.165),
				"buttstock": Vector3(0.0, -0.006, 0.315),
				"internal": Vector3(0.0, -0.054, 0.012),
				"ammo_type": Vector3(-0.094, 0.042, -0.125)
			}
	return {"model_off": Vector3.ZERO, "optic_base": Vector3(0, 0.065, 0)}

static func get_slot_anchor_local(weapon_id: String, slot_type: String) -> Vector3:
	var m := _get_mounts(weapon_id)
	if slot_type == "optic":
		return m.get("optic_base", Vector3(0, 0.08, 0)) + Vector3(0, 0.042, 0)
	if slot_type == "dust_cover":
		return m.get("rail", Vector3(0, 0.056, 0.02))
	if m.has(slot_type):
		return m[slot_type]
	return Vector3.ZERO

# Exact optical centerline (lens_y_offset above optic_base, lens_z_offset from optic_base) for EVERY optic!
static func _get_optic_lens_offset(optic_id: String) -> Vector3:
	match optic_id:
		"optic_rmr", "optic_pk06":
			return Vector3(0.0, 0.021, 0.010)
		"optic_red_dot":
			return Vector3(0.0, 0.032, 0.018)
		"optic_acog":
			return Vector3(0.0, 0.032, 0.081)
		"optic_zf39":
			return Vector3(0.0, 0.032, 0.120)
		"optic_lpvo":
			return Vector3(0.0, 0.033, 0.121)
		"optic_sniper_12x":
			return Vector3(0.0, 0.036, 0.159)
		"optic_nvg":
			return Vector3(0.0, 0.038, 0.122)
		"optic_thermal":
			return Vector3(0.0, 0.038, 0.116)
	return Vector3.ZERO

# Computes mathematically dead-center WeaponHolder ADS position for ANY weapon + ANY installed optic!
static func get_ads_pos_for_mods(weapon_id: String, installed_mods: Dictionary, fallback_pos: Vector3) -> Vector3:
	var opt := str(installed_mods.get("optic", ""))
	if opt == "" or opt == "optic_tritium_iron" or opt == "l96_opt_pm2" or opt == "rpg_opt_pgo7":
		return fallback_pos
	var m := _get_mounts(weapon_id)
	var model_off: Vector3 = m.get("model_off", Vector3.ZERO)
	var base: Vector3 = m.get("optic_base", Vector3(0, 0.0585, 0))
	var lens_off: Vector3 = _get_optic_lens_offset(opt)
	if lens_off == Vector3.ZERO:
		return fallback_pos
	# Camera eye is at (0,0,0), lens center in WeaponHolder space = model_off + base + lens_off
	var lens_in_holder: Vector3 = model_off + base + lens_off
	# Keep eye_dist strictly > camera.near (0.05) with generous margin so recoil/sway NEVER clips the ocular lens!
	var is_1x: bool = (opt in ["optic_rmr", "optic_pk06", "optic_red_dot"])
	var eye_dist: float = 0.165 if is_1x else 0.098
	if weapon_id == "pistol" or weapon_id == "deagle":
		eye_dist = 0.220 if is_1x else 0.112
	elif weapon_id == "kar98k":
		eye_dist = 0.195 if is_1x else 0.112
	var target_z: float = -eye_dist - lens_in_holder.z
	return Vector3(-lens_in_holder.x, -lens_in_holder.y, target_z)

# =========================================================================
# REAL PiP OPTICAL SHADERS: HOLO, ACOG/LPVO/SNIPER, 1PN93 NVG & FLIR THERMAL!
# =========================================================================
static func _create_red_dot_shader(is_eotech: bool) -> ShaderMaterial:
	var sh := Shader.new()
	var ring_code: String = "float ring = (1.0 - smoothstep(0.005, 0.011, abs(r - 0.135)));" if is_eotech else "float ring = 0.0;"
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;
uniform vec4 ret_col : source_color = vec4(1.0, 0.12, 0.08, 1.0);
void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float dot_m = 1.0 - smoothstep(0.014, 0.026, r);
	%s
	float ret = clamp(dot_m + ring * 0.85, 0.0, 1.0);
	ALBEDO = mix(vec3(0.08, 0.22, 0.26), ret_col.rgb * 2.2, ret);
	ALPHA = clamp(0.10 + ret * 0.90, 0.0, 1.0);
}
""" % ring_code
	var sm := ShaderMaterial.new()
	sm.shader = sh
	return sm

static func _create_pip_scope_shader(style: String) -> ShaderMaterial:
	var sh := Shader.new()
	if style == "nvg":
		# 1PN93 Authentic Green Phosphor Night Vision PiP Shader!
		sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.496) { discard; }
	if (r > 0.450) { ALBEDO = vec3(0.025, 0.03, 0.028); ALPHA = 1.0; }
	else {
		vec3 raw = use_pip ? texture(pip_tex, clamp(UV, vec2(0.005), vec2(0.995))).rgb : vec3(0.04, 0.16, 0.08);
		float lum = dot(raw, vec3(0.299, 0.587, 0.114));
		// P43 Phosphor amplification + fine CRT scanlines + film scintillation
		float amp = clamp(pow(max(lum, 0.01), 0.56) * 2.15 + 0.08, 0.0, 1.5);
		float scan = 0.92 + 0.08 * sin(UV.y * 280.0);
		float grain = fract(sin(dot(floor(UV * 240.0) + vec2(TIME * 7.0), vec2(12.9898, 78.233))) * 43758.5453);
		vec3 nvg = vec3(0.14, 1.0, 0.34) * amp * scan * (0.94 + grain * 0.12);
		// Illuminated amber-red Russian chevron ballistic reticle
		float chev_l = step(abs(p.y - abs(p.x) * 1.15 - 0.004), 0.0045) * step(abs(p.x), 0.036);
		float fine_h = step(abs(p.y), 0.0018) * step(0.055, abs(p.x)) * step(abs(p.x), 0.43);
		float fine_v = step(abs(p.x), 0.0018) * step(0.055, p.y) * step(p.y, 0.43);
		float tick_v = step(abs(p.x), 0.014) * step(0.06, p.y) * step(p.y, 0.28) * step(abs(fract(p.y * 16.0) - 0.5), 0.08);
		float ret = clamp(chev_l + fine_h + fine_v + tick_v, 0.0, 1.0);
		float vig = smoothstep(0.450, 0.355, r);
		vec3 col = nvg * mix(0.22, 1.0, vig);
		col = mix(col, vec3(1.0, 0.22, 0.08) * 1.5, ret * 0.95);
		ALBEDO = col;
		ALPHA = 1.0;
	}
}
"""
	elif style == "thermal":
		# FLIR RS-32 True 3D Silhouette Thermal Vision PiP Shader (Layer-3 heat-emitting geometry + Z-buffer occlusion!)
		sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;

vec3 flir_palette(float t) {
	t = clamp(t, 0.0, 1.0);
	vec3 c0 = vec3(0.03, 0.04, 0.14); // Cold night slate-indigo
	vec3 c1 = vec3(0.12, 0.10, 0.30); // Cool purple-blue
	vec3 c2 = vec3(0.68, 0.14, 0.24); // Warm crimson
	vec3 c3 = vec3(0.98, 0.56, 0.08); // Hot orange
	vec3 c4 = vec3(1.00, 0.98, 0.90); // White-hot core
	if (t < 0.28) return mix(c0, c1, t / 0.28);
	if (t < 0.55) return mix(c1, c2, (t - 0.28) / 0.27);
	if (t < 0.80) return mix(c2, c3, (t - 0.55) / 0.25);
	return mix(c3, c4, (t - 0.80) / 0.20);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.496) { discard; }
	if (r > 0.452) { ALBEDO = vec3(0.022, 0.025, 0.03); ALPHA = 1.0; }
	else {
		vec3 raw = use_pip ? texture(pip_tex, clamp(UV, vec2(0.005), vec2(0.995))).rgb : vec3(0.06, 0.05, 0.14);
		float lum = dot(raw, vec3(0.30, 0.59, 0.11));
		// Base cold environment & cold metal/armor (0.04 .. 0.30)
		float terrain_heat = clamp(lum * 0.28, 0.03, 0.30);
		// Natural bright orange/yellow flames, muzzle flashes & explosions also emit heat!
		float fire_sig = smoothstep(0.35, 0.85, raw.r - raw.b) * smoothstep(0.28, 0.78, raw.r + raw.g * 0.45);
		terrain_heat = max(terrain_heat, fire_sig * 0.92);
		// Decode Layer-3 3D Thermal Heat Proxy meshes (unshaded chroma key: R = heat, G = 0, B = 1)
		// Gives pixel-accurate 3D silhouettes of living enemies & vehicle heat zones with true wall occlusion!
		float key_sig = min(raw.b, raw.r) - raw.g * 1.85;
		float proxy_mask = smoothstep(0.06, 0.18, key_sig);
		float decoded_h = pow(clamp(raw.r / max(raw.b, 0.001), 0.0, 1.0), 0.45);
		float heat = mix(terrain_heat, clamp(decoded_h, 0.52, 1.0), proxy_mask);

		float scan = 0.94 + 0.06 * sin(UV.y * 220.0);
		vec3 thermal_col = flir_palette(heat) * scan;
		// Crisp digital FLIR crosshair + corner frame brackets
		float cross_h = step(abs(p.y), 0.0022) * step(0.022, abs(p.x)) * step(abs(p.x), 0.16);
		float cross_v = step(abs(p.x), 0.0022) * step(0.022, abs(p.y)) * step(abs(p.y), 0.16);
		float center_d = step(r, 0.0065);
		float br_x = step(0.26, abs(p.x)) * step(abs(p.x), 0.32) * step(abs(abs(p.y) - 0.24), 0.003);
		float br_y = step(0.18, abs(p.y)) * step(abs(p.y), 0.24) * step(abs(abs(p.x) - 0.32), 0.003);
		float hud_m = clamp(cross_h + cross_v + br_x + br_y, 0.0, 1.0);
		float vig = smoothstep(0.452, 0.38, r);
		vec3 col = thermal_col * mix(0.35, 1.0, vig);
		col = mix(col, vec3(0.02, 0.03, 0.05), hud_m * 0.85);
		col = mix(col, vec3(0.15, 0.95, 1.0), center_d);
		ALBEDO = col;
		ALPHA = 1.0;
	}
}
"""
	elif style == "zf39":
		# Classic WWII German 3-Post Sniper Reticle (ZF39)
		sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.496) { discard; }
	if (r > 0.448) { ALBEDO = vec3(0.025, 0.028, 0.03); ALPHA = 1.0; }
	else {
		float post_h = step(abs(p.y), 0.008) * step(0.055, abs(p.x)) * step(abs(p.x), 0.44);
		float post_v = step(abs(p.x), 0.009) * step(0.0, p.y) * step(p.y, 0.44);
		float tip = step(abs(p.x), max(0.001, (p.y + 0.012) * 0.7)) * step(-0.012, p.y) * step(p.y, 0.004);
		float mask = clamp(post_h + post_v + tip, 0.0, 1.0);
		vec3 bg = use_pip ? texture(pip_tex, clamp(UV, vec2(0.005), vec2(0.995))).rgb : vec3(0.05, 0.14, 0.14);
		bg *= mix(0.40, 1.0, smoothstep(0.448, 0.36, r));
		ALBEDO = mix(bg, vec3(0.015, 0.015, 0.018), mask);
		ALPHA = 1.0;
	}
}
"""
	else:
		# Crisp ACOG / LPVO / Nightforce Mil-Dot Tactical Reticle
		sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D pip_tex : source_color, filter_linear;
uniform bool use_pip = false;
void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	if (r > 0.496) { discard; }
	if (r > 0.450) { ALBEDO = vec3(0.028, 0.032, 0.036); ALPHA = 1.0; }
	else {
		float fine_h = step(abs(p.y), 0.0016) * step(0.014, abs(p.x)) * step(abs(p.x), 0.44);
		float fine_v = step(abs(p.x), 0.0016) * step(0.014, abs(p.y)) * step(abs(p.y), 0.44);
		float thick_h = step(abs(p.y), 0.0058) * step(0.24, abs(p.x)) * step(abs(p.x), 0.44);
		float thick_v = step(abs(p.x), 0.0058) * step(0.24, abs(p.y)) * step(abs(p.y), 0.44);
		float mil_h = step(abs(p.y), 0.008) * step(0.045, abs(p.x)) * step(abs(p.x), 0.23) * step(abs(fract(abs(p.x) * 18.0 + 0.5) - 0.5), 0.08);
		float mil_v = step(abs(p.x), 0.008) * step(0.045, abs(p.y)) * step(abs(p.y), 0.23) * step(abs(fract(abs(p.y) * 18.0 + 0.5) - 0.5), 0.08);
		float mask = clamp(fine_h + fine_v + thick_h + thick_v + mil_h + mil_v, 0.0, 1.0);
		float cdot = 1.0 - smoothstep(0.004, 0.008, r);
		vec3 bg = use_pip ? texture(pip_tex, clamp(UV, vec2(0.005), vec2(0.995))).rgb : vec3(0.05, 0.16, 0.18);
		bg *= mix(0.36, 1.0, smoothstep(0.450, 0.37, r));
		vec3 col = mix(bg, vec3(0.02, 0.02, 0.024), mask * 0.94);
		col = mix(col, vec3(1.0, 0.15, 0.10) * 1.45, cdot);
		ALBEDO = col;
		ALPHA = 1.0;
	}
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	return sm

# =========================================================================
# MAIN ENTRY: APPLY ALL INSTALLED MODS TO ANY OF THE 10 WEAPON MODELS!
# =========================================================================
static func _set_children_vis_by_names(parent: Node, names: Array[String], vis: bool, prefix_mode: bool = false) -> void:
	if not parent:
		return
	for ch in parent.get_children():
		var cn: String = String(ch.name)
		var matched: bool = false
		if prefix_mode:
			for p in names:
				if cn == p or cn.begins_with(p):
					matched = true
					break
		else:
			matched = (cn in names)
		if matched and ch is Node3D:
			(ch as Node3D).visible = vis

static func apply_mods_to_weapon_node(weapon_id: String, root: Node3D, installed_mods: Dictionary) -> void:
	if not root:
		return
	for old_path in ["DynamicMods", "TopCover/DynamicModsTopCover", "Pump/DynamicModsPump"]:
		var old_n := root.get_node_or_null(old_path)
		if old_n and old_n.get_parent():
			old_n.get_parent().remove_child(old_n)
			old_n.queue_free()

	var dyn := Node3D.new()
	dyn.name = "DynamicMods"
	root.add_child(dyn)

	# Hinged TopCover sub-container for PKM & MG 42 so rail + optics flip open with the feed cover during reload!
	var top_cover_node := root.get_node_or_null("TopCover") as Node3D
	var dyn_top: Node3D = dyn
	var top_off := Vector3.ZERO
	if top_cover_node and weapon_id in ["pkm", "mg42"]:
		dyn_top = Node3D.new()
		dyn_top.name = "DynamicModsTopCover"
		top_cover_node.add_child(dyn_top)
		top_off = -top_cover_node.position

	var m := _get_mounts(weapon_id)
	var m_dark := _mat(Color(0.09, 0.095, 0.108), 0.84, 0.34)
	var m_steel := _mat(Color(0.16, 0.17, 0.19), 0.90, 0.28)
	var m_chrome := _mat(Color(0.76, 0.78, 0.82), 0.95, 0.18)
	var m_poly := _mat(Color(0.11, 0.115, 0.125), 0.08, 0.68)
	var m_tan := _mat(Color(0.46, 0.40, 0.28), 0.10, 0.62)
	var m_od := _mat(Color(0.20, 0.28, 0.16), 0.45, 0.50)
	var m_bakelite := _mat(Color(0.56, 0.22, 0.08), 0.05, 0.42)
	var m_brass := _mat(Color(0.88, 0.72, 0.25), 0.94, 0.18)
	var m_red := _mat(Color(0.86, 0.14, 0.12), 0.10, 0.35)
	var m_green_glow := _mat(Color(0.25, 1.0, 0.40), 0.0, 0.2, Color(0.20, 0.95, 0.35), 2.2)

	# --- A. VANILLA COMPONENT VISIBILITY TOGGLES (ZERO OVERLAPPING & EMPTY "" REALLY STRIPS PART!) ---
	var dc := str(installed_mods.get("dust_cover", ""))
	var opt_id := str(installed_mods.get("optic", ""))
	var hg_id := str(installed_mods.get("handguard", ""))
	var pg_id := str(installed_mods.get("pistol_grip", ""))
	var stock_ad := str(installed_mods.get("stock_adapter", ""))
	var muz := str(installed_mods.get("muzzle", ""))

	# 1) AK-47 vanilla parts
	if weapon_id == "ak47":
		var rec_top := root.get_node_or_null("ReceiverTop")
		var r1 := root.get_node_or_null("TopCoverRib1")
		var r2 := root.get_node_or_null("TopCoverRib2")
		if rec_top: rec_top.visible = (dc != "")
		if r1: r1.visible = (dc == "ak_cover_std")
		if r2: r2.visible = (dc == "ak_cover_std")
		if dc == "":
			_box(dyn, "ExposedAction", Vector3(0.036, 0.010, 0.215), Vector3(0, 0.033, 0.015), _mat(Color(0.03, 0.03, 0.035), 0.2, 0.9))
			_cyl(dyn, "RecoilGuideRod", 0.004, 0.004, 0.16, Vector3(0, 0.040, 0.045), m_chrome, 8)
		elif dc == "ak_cover_picatinny":
			_build_picatinny_rail(dyn, Vector3(0, 0.054, 0.010), 0.205, m_dark)
		_set_children_vis_by_names(root, ["WoodHandguardLow", "WoodHandguardSwellL", "WoodHandguardSwellR", "WoodHandguardUp", "HandguardVent"], hg_id == "ak_hg_wood", true)
		_set_children_vis_by_names(root, ["PistolGrip"], pg_id == "ak_grip_std")
		_set_children_vis_by_names(root, ["Stock"], stock_ad == "ak_stock_wood")
		_set_children_vis_by_names(root, ["SlantBrake"], muz == "ak_muz_slant")

	# 2) L96A1 vanilla parts (scope, stock inside Chassis, forend inside Chassis, muzzle brake!)
	elif weapon_id == "l96a1":
		var builtin_sc := root.get_node_or_null("SniperScope")
		if builtin_sc:
			builtin_sc.visible = (opt_id == "l96_opt_pm2")
		var l96_chassis := root.get_node_or_null("Chassis")
		if l96_chassis:
			var show_l96_stock: bool = (stock_ad == "l96_stock_std")
			_set_children_vis_by_names(l96_chassis, [
				"StockTopBeam", "StockLowerStrut", "StockRearBridge", "BagRiderStep",
				"LOPSpacer1", "LOPSpacer2", "ButtRecoilPad",
				"CheekPost", "CheekPieceTop", "CheekPieceRound", "CheekThumbwheel"
			], show_l96_stock, true)
			# Also hide rear chassis bolts on the buttstock when stock removed/replaced
			for ch in l96_chassis.get_children():
				if String(ch.name).begins_with("ChassisBolt") and ch is Node3D:
					if (ch as Node3D).position.z > 0.15:
						(ch as Node3D).visible = show_l96_stock
			var show_l96_hg: bool = (hg_id == "l96_hg_std")
			_set_children_vis_by_names(l96_chassis, ["ForendMain", "ForendBottomRail", "ForendNoseCap", "ForendVent"], show_l96_hg, true)
		_set_children_vis_by_names(root, ["MuzzleBrake"], muz == "l96_muz_std")

	# 3) RPG-7 vanilla PGO-7 optic & warhead swap
	elif weapon_id == "rpg":
		var pgo := root.get_node_or_null("PGO7_Optic")
		var use_custom_rpg_opt: bool = (opt_id != "" and opt_id != "rpg_opt_pgo7")
		if pgo:
			pgo.visible = (opt_id == "rpg_opt_pgo7")
		if use_custom_rpg_opt:
			_box(dyn, "RPGOptSideClamp", Vector3(0.014, 0.026, 0.086), Vector3(-0.029, 0.004, -0.155), m_dark)
			_box(dyn, "RPGOptArm", Vector3(0.014, 0.058, 0.032), Vector3(-0.046, 0.027, -0.155), m_dark, Vector3(0, 0, 32.0))
			_build_picatinny_rail(dyn, Vector3(-0.062, 0.048, -0.155), 0.135, m_dark)
		var rpg_ammo := str(installed_mods.get("ammo_type", "ammo_rpg_pg7v"))
		var wh_type := "tandem" if rpg_ammo == "ammo_rpg_tandem" else ("thermobaric" if rpg_ammo == "ammo_rpg_thermo" else "standard")
		var old_wh := root.get_node_or_null("Warhead")
		var wh_vis: bool = old_wh.visible if old_wh else true
		var wh_pos: Vector3 = old_wh.position if old_wh else Vector3(0, 0, -0.45)
		if old_wh:
			root.remove_child(old_wh)
			old_wh.queue_free()
		var new_wh: Node3D = RPGModelScript.create_warhead_by_type(wh_type, false)
		new_wh.name = "Warhead"
		new_wh.position = wh_pos
		new_wh.visible = wh_vis
		root.add_child(new_wh)

	# 4) Pump Shotgun vanilla stock & wooden pump forend
	elif weapon_id == "shotgun":
		_set_children_vis_by_names(root, ["Stock"], stock_ad == "sg_stock_wood")
		var pump_mi := root.get_node_or_null("Pump") as MeshInstance3D
		if pump_mi:
			if not pump_mi.has_meta("orig_pump_mesh") and pump_mi.mesh:
				pump_mi.set_meta("orig_pump_mesh", pump_mi.mesh)
			var show_wood_pump: bool = (hg_id == "sg_hg_wood")
			if show_wood_pump:
				if pump_mi.has_meta("orig_pump_mesh"):
					pump_mi.mesh = pump_mi.get_meta("orig_pump_mesh")
			else:
				pump_mi.mesh = null
			_set_children_vis_by_names(pump_mi, ["CorncobGroove"], show_wood_pump, true)

	# 5) Kar98k vanilla wood buttstock & wood forend (inside Stock!)
	elif weapon_id == "kar98k":
		var k_stock := root.get_node_or_null("Stock")
		if k_stock:
			var show_k_butt: bool = (stock_ad == "k98_stock_wood")
			_set_children_vis_by_names(k_stock, [
				"ButtMain", "ButtComb", "ButtToe", "ButtPlateBack", "ButtPlateCupLow", "ButtPlateTangTop",
				"SlingSlotCutout", "SlingSlotPin", "SlingRearLeather", "SlingStrap", "SlingBuckle",
				"TakedownDisk", "TakedownHole", "WristUpper"
			], show_k_butt, true)
			var show_k_forend: bool = (hg_id == "k98_hg_wood")
			_set_children_vis_by_names(k_stock, ["ForendFront", "ForendRear", "ForendRoundBottom", "UpperHandguard", "FingerGroove"], show_k_forend, true)

	# 6) PKM vanilla stock, grip & flash hider
	elif weapon_id == "pkm":
		_set_children_vis_by_names(root, ["StockTopBeam", "StockBotBeam", "StockFrontBridge", "StockRearBridge", "ButtPlateSteel", "ShoulderRestFlap"], stock_ad == "pkm_stock_wood")
		_set_children_vis_by_names(root, ["PistolGrip"], pg_id == "pkm_grip_std")
		_set_children_vis_by_names(root, ["FlashHiderBase", "FlashHiderBody", "FlashSlot"], muz == "pkm_muz_std", true)

	# 7) MG 42 vanilla bakelite stock & muzzle booster
	elif weapon_id == "mg42":
		_set_children_vis_by_names(root, ["StockUpperSpine", "StockLowerGripCut", "StockButtPlate"], stock_ad == "mg_stock_bakelite")
		_set_children_vis_by_names(root, ["BoosterCollar", "BoosterBody", "BoosterTrumpet"], muz == "mg_muz_std")

	# 8) Desert Eagle vanilla rubber grip panels
	elif weapon_id == "deagle":
		var de_grip := root.get_node_or_null("Grip")
		if de_grip:
			_set_children_vis_by_names(de_grip, ["GripRubberWrap", "FingerGroove", "GripMedallion"], pg_id == "de_grip_rubber", true)

	# 9) Pistol vanilla grip panels
	elif weapon_id == "pistol":
		var ps_grip := root.get_node_or_null("Grip")
		if ps_grip:
			_set_children_vis_by_names(ps_grip, ["StipplePanel"], pg_id == "ps_grip_std", true)

	# 10) AA-12 vanilla handguard & muzzle choke collar
	elif weapon_id == "aa12":
		_set_children_vis_by_names(root, ["ForendCore", "ForendGripRib_", "ForendVentSlot_", "UnderRail"], hg_id == "aa_hg_std", true)
		_set_children_vis_by_names(root, ["ChokeCollar"], muz == "aa_muz_std")

	var is_custom_stock := (stock_ad != "" and not stock_ad.ends_with("_wood") and not stock_ad.ends_with("_std") and not stock_ad.ends_with("_bakelite"))
	var is_custom_muz := (muz != "" and not muz.ends_with("_std") and muz != "ak_muz_slant")

	# --- B. RAILS & SIDE MOUNTS (100% MONOLITHIC, ZERO FLOATING!) ---
	var rail_id := str(installed_mods.get("rail", ""))
	var srail_id := str(installed_mods.get("side_rail", ""))
	if srail_id == "ak_rail_b13":
		var b13 := Node3D.new(); b13.name = "B13SideMount"; dyn.add_child(b13)
		_box(b13, "Clamp", Vector3(0.012, 0.032, 0.110), Vector3(-0.026, 0.016, 0.008), m_dark)
		_box(b13, "Arm", Vector3(0.008, 0.046, 0.090), Vector3(-0.027, 0.039, 0.008), m_dark)
		_box(b13, "CrossBridge", Vector3(0.036, 0.008, 0.092), Vector3(-0.013, 0.056, 0.008), m_dark)
		_build_picatinny_rail(b13, Vector3(0, 0.056, 0.008), 0.145, m_dark)
	if rail_id != "":
		var rpos: Vector3 = m.get("rail", Vector3(0, 0.054, 0))
		if rail_id == "rpg_rail_side":
			_cyl(dyn, "RPGRailClamp", 0.031, 0.031, 0.068, Vector3(0, 0, -0.160), m_dark, 16)
			_box(dyn, "RPGRailBridge", Vector3(0.022, 0.018, 0.068), Vector3(0.022, 0.002, -0.160), m_dark)
			_box(dyn, "RPGRailBar", Vector3(0.012, 0.022, 0.095), rpos, m_dark)
		elif rail_id == "de_rail_under":
			_box(dyn, "DeRailClamp", Vector3(0.028, 0.010, 0.088), rpos + Vector3(0, 0.006, 0), m_dark)
			_build_picatinny_rail(dyn, rpos, 0.088, m_dark)
		elif rail_id == "ps_rail_rmr":
			var pbr := Node3D.new(); pbr.name = "PistolOpticBridge"; dyn.add_child(pbr)
			_box(pbr, "UnderClamp", Vector3(0.036, 0.010, 0.058), Vector3(0, -0.004, -0.048), m_dark)
			for sx in [-0.020, 0.020]:
				_box(pbr, "SideStrut", Vector3(0.005, 0.048, 0.046), Vector3(sx, 0.020, -0.032), m_dark)
				_box(pbr, "TopSideRail", Vector3(0.005, 0.007, 0.088), Vector3(sx, 0.041, -0.008), m_dark)
			_box(pbr, "TopDeck", Vector3(0.044, 0.006, 0.082), rpos + Vector3(0, 0.0, -0.010), m_dark)
			_build_picatinny_rail(pbr, rpos + Vector3(0, 0.003, -0.005), 0.072, m_dark)
		elif rail_id == "k98_rail_scout":
			# Authentic forward barrel-mounted Scout Picatinny rail ahead of the Mauser receiver (breech stays 100% open!)
			var sr := Node3D.new(); sr.name = "K98ScoutRail"; dyn.add_child(sr)
			_cyl(sr, "RearBarrelClamp", 0.020, 0.020, 0.022, Vector3(0, 0.019, -0.215), m_dark, 16)
			_cyl(sr, "FrontBarrelClamp", 0.019, 0.019, 0.022, Vector3(0, 0.019, -0.355), m_dark, 16)
			_box(sr, "RearStrut", Vector3(0.022, 0.018, 0.022), Vector3(0, 0.032, -0.215), m_dark)
			_box(sr, "FrontStrut", Vector3(0.022, 0.018, 0.022), Vector3(0, 0.032, -0.355), m_dark)
			_box(sr, "ScoutBridge", Vector3(0.024, 0.008, 0.162), rpos + Vector3(0, -0.003, 0), m_dark)
			_build_picatinny_rail(sr, rpos, 0.158, m_steel)
		else:
			# On PKM & MG 42, rail sits on hinged TopCover so it opens with the feed cover!
			_box(dyn_top, "RailPedestal", Vector3(0.024, 0.010, 0.148), rpos + top_off + Vector3(0, -0.004, 0), m_dark)
			_build_picatinny_rail(dyn_top, rpos + top_off, 0.155, m_dark)

	# --- C. OPTICS & SIGHTS (INCLUDING NVG & THERMAL!) ---
	if opt_id != "" and opt_id != "l96_opt_pm2" and opt_id != "rpg_opt_pgo7":
		var opos: Vector3 = m.get("optic_base", Vector3(0, 0.064, 0))
		_build_optic_mesh(dyn_top, opt_id, opos + top_off, m_dark, m_steel, m_poly, m_green_glow)

	# --- D. HANDGUARDS / FORENDS (ATTACHED TO PUMP ON SHOTGUN SO IT MOVES WITH PUMP!) ---
	var dyn_hg_parent: Node3D = dyn
	var hg_off := Vector3.ZERO
	var pump_holder: Node3D = null
	if weapon_id == "shotgun":
		var pump_n := root.get_node_or_null("Pump") as Node3D
		if pump_n:
			pump_holder = Node3D.new()
			pump_holder.name = "DynamicModsPump"
			pump_holder.rotation_degrees = Vector3(90.0, 0.0, 0.0) # Undo Pump's -90 deg X rotation!
			pump_n.add_child(pump_holder)
			dyn_hg_parent = pump_holder
			hg_off = -pump_n.position
	if hg_id != "" and not hg_id.ends_with("_wood") and not hg_id.ends_with("_std"):
		var hpos: Vector3 = m.get("handguard", Vector3(0, 0, -0.25))
		_build_handguard_mesh(dyn_hg_parent, weapon_id, hg_id, hpos + hg_off, m_dark, m_poly, m_steel)

	# --- E. MUZZLE DEVICES ---
	if is_custom_muz:
		var mpos: Vector3 = m.get("muzzle", Vector3(0, 0, -0.55))
		_build_muzzle_mesh(dyn, weapon_id, muz, mpos, m_dark, m_steel, m_chrome)

	# --- F. MAGAZINES / TUBES / BELT BOXES ---
	var mag_id := str(installed_mods.get("magazine", ""))
	if mag_id != "" and not mag_id in ["ak_mag_30", "sg_tube_5", "ps_mag_17", "k98_mag_5", "pkm_box_100", "l96_mag_5", "de_mag_7", "aa_mag_20", "mg_box_100"]:
		var mag_pos: Vector3 = m.get("magazine", Vector3(0, -0.05, -0.06))
		_build_magazine_mesh(dyn, root, weapon_id, mag_id, mag_pos, m_dark, m_steel, m_bakelite, m_od, m_poly, m_brass, m_red)
	else:
		for mn in ["Magazine", "AmmoBox", "MagTube"]:
			var mg := root.get_node_or_null(mn)
			if mg:
				mg.scale = Vector3.ONE
				mg.visible = true

	# --- G. UNDERBARREL: ГП-25, M203, FOREGRIPS, BIPOD ---
	var ub_id := str(installed_mods.get("underbarrel", ""))
	if ub_id != "":
		var upos: Vector3 = m.get("underbarrel", Vector3(0, -0.035, -0.25))
		_build_underbarrel_mesh(dyn_hg_parent, ub_id, upos + hg_off, m_dark, m_steel, m_poly, m_bakelite, m_brass)

	# --- H. TACTICAL LASERS & FLASHLIGHTS (WITH EMITTER MARKERS!) ---
	var las_id := str(installed_mods.get("tactical_laser", ""))
	if las_id != "":
		var lpos: Vector3 = m.get("tactical_laser", Vector3(0.034, 0.01, -0.25))
		_build_laser_mesh(dyn_hg_parent, las_id, lpos + hg_off, m_dark, m_tan, m_steel)

	var fl_id := str(installed_mods.get("flashlight", ""))
	if fl_id != "":
		var fpos: Vector3 = m.get("flashlight", Vector3(-0.034, 0.01, -0.26))
		_build_flashlight_mesh(dyn_hg_parent, fl_id, fpos + hg_off, m_dark, m_steel, m_chrome)

	# --- I. PISTOL GRIPS ---
	if pg_id != "" and not pg_id.ends_with("_std") and pg_id != "de_grip_rubber":
		var gpos: Vector3 = m.get("pistol_grip", Vector3(0, -0.08, 0.08))
		_build_pistol_grip_mesh(dyn, pg_id, gpos, m_poly, m_steel, m_chrome, m_bakelite)

	# --- J. STOCK ADAPTERS, BUFFER TUBES & TACTICAL BUTTSTOCKS ---
	if is_custom_stock:
		var spos: Vector3 = m.get("stock_adapter", Vector3(0, -0.01, 0.14))
		_build_stock_adapter_mesh(dyn, stock_ad, spos, m_dark, m_steel, m_poly)
	var bstock_id := str(installed_mods.get("buttstock", ""))
	if bstock_id != "":
		var bpos: Vector3 = m.get("buttstock", Vector3(0, -0.01, 0.30))
		_build_buttstock_mesh(dyn, bstock_id, bpos, m_poly, m_dark, m_tan, m_steel)

	# --- K. INTERNAL MECHANISM ACCENT (GOLD/CHROME MATCH TRIGGER) ---
	var int_id := str(installed_mods.get("internal", ""))
	if int_id != "":
		var ipos: Vector3 = m.get("internal", Vector3(0, -0.04, 0.02))
		var trig_mat := m_brass if int_id == "int_match_trigger" else m_chrome
		_box(dyn, "CustomTriggerAccent", Vector3(0.008, 0.022, 0.011), ipos, trig_mat, Vector3(-18, 0, 0))
		if int_id == "int_pistol_autosear":
			_box(dyn, "G18AutoSelector", Vector3(0.006, 0.010, 0.014), Vector3(-0.016, 0.034, 0.056), m_red)

# =========================================================================
# INDIVIDUAL HIGH-DETAIL 3D COMPONENT BUILDERS
# =========================================================================
static func _build_picatinny_rail(parent: Node3D, pos: Vector3, length: float, mat_rail: Material) -> void:
	var r := Node3D.new(); r.position = pos; parent.add_child(r)
	_box(r, "RailBase", Vector3(0.022, 0.006, length), Vector3.ZERO, mat_rail)
	var steps: int = maxi(4, int(length / 0.017))
	for i in range(steps):
		var lz: float = -length * 0.45 + float(i) * (length * 0.90 / maxf(1.0, float(steps - 1)))
		_box(r, "Lug", Vector3(0.024, 0.004, 0.008), Vector3(0, 0.0045, lz), mat_rail)

static func _build_optic_mesh(parent: Node3D, opt_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_poly: Material, m_glow: Material) -> void:
	var opt := Node3D.new()
	opt.name = "ModOptic_" + opt_id
	opt.position = pos
	parent.add_child(opt)
	var m_obj := _mat(Color(0.06, 0.28, 0.26), 0.90, 0.05)

	match opt_id:
		"optic_tritium_iron":
			_box(opt, "Base", Vector3(0.026, 0.010, 0.032), Vector3(0, 0.004, 0), m_dark)
			_box(opt, "WingL", Vector3(0.005, 0.018, 0.014), Vector3(-0.010, 0.016, 0.008), m_dark)
			_box(opt, "WingR", Vector3(0.005, 0.018, 0.014), Vector3(0.010, 0.016, 0.008), m_dark)
			_box(opt, "DotL", Vector3(0.003, 0.003, 0.003), Vector3(-0.010, 0.018, 0.016), m_glow)
			_box(opt, "DotR", Vector3(0.003, 0.003, 0.003), Vector3(0.010, 0.018, 0.016), m_glow)
		"optic_rmr", "optic_pk06":
			# 100% monolithic reflex sight: base, side frames & top bridge fused cleanly!
			_box(opt, "Base", Vector3(0.028, 0.010, 0.044), Vector3(0, 0.004, 0), m_dark)
			_box(opt, "FrameL", Vector3(0.004, 0.025, 0.014), Vector3(-0.0125, 0.0195, 0.004), m_dark)
			_box(opt, "FrameR", Vector3(0.004, 0.025, 0.014), Vector3(0.0125, 0.0195, 0.004), m_dark)
			_box(opt, "FrameTop", Vector3(0.029, 0.004, 0.014), Vector3(0, 0.032, 0.004), m_dark)
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.022, 0.021)
			g.mesh = q; g.material_override = _create_red_dot_shader(false)
			g.position = Vector3(0, 0.021, 0.010); opt.add_child(g)
		"optic_red_dot":
			# 100% monolithic EOTech EXPS3 Holographic Sight (continuous fused lower deck + full-depth hood!)
			_box(opt, "Base", Vector3(0.034, 0.012, 0.078), Vector3(0, 0.005, 0), m_dark)
			_box(opt, "InnerDeck", Vector3(0.038, 0.008, 0.044), Vector3(0, 0.013, 0.008), m_poly)
			_cyl(opt, "Batt", 0.008, 0.008, 0.038, Vector3(0, 0.013, -0.024), m_poly, 12, Vector3(0, 0, 90))
			for sx in [-0.018, 0.018]:
				_box(opt, "Hood", Vector3(0.005, 0.040, 0.044), Vector3(sx, 0.029, 0.008), m_dark)
			_box(opt, "HoodTop", Vector3(0.041, 0.005, 0.044), Vector3(0, 0.048, 0.008), m_dark)
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.031, 0.030)
			g.mesh = q; g.material_override = _create_red_dot_shader(true)
			g.position = Vector3(0, 0.032, 0.018); opt.add_child(g)
		"optic_acog":
			_box(opt, "Mount", Vector3(0.026, 0.024, 0.088), Vector3(0, 0.011, 0), m_dark)
			_cyl(opt, "Tube", 0.017, 0.016, 0.135, Vector3(0, 0.032, 0.002), m_dark, 18)
			_cyl(opt, "ObjBell", 0.023, 0.017, 0.040, Vector3(0, 0.032, -0.076), m_dark, 18)
			_cyl(opt, "ObjGlass", 0.020, 0.020, 0.003, Vector3(0, 0.032, -0.097), m_obj, 16)
			_cyl(opt, "FiberTube", 0.0035, 0.0035, 0.068, Vector3(0, 0.050, -0.012), _mat(Color(1.0, 0.18, 0.10), 0.0, 0.2, Color(1.0, 0.16, 0.08), 1.8), 8)
			_cyl(opt, "Ocular", 0.017, 0.022, 0.036, Vector3(0, 0.032, 0.060), m_poly, 18)
			# Placed strictly +3mm behind Ocular rear face (0.078) so PiP lens is NEVER occluded!
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.044, 0.044)
			g.mesh = q; g.material_override = _create_pip_scope_shader("tactical")
			g.position = Vector3(0, 0.032, 0.081); opt.add_child(g)
		"optic_zf39":
			_box(opt, "RailClamp", Vector3(0.022, 0.008, 0.108), Vector3(0, 0.003, 0), m_steel)
			for rz in [-0.042, 0.042]:
				_box(opt, "Stem", Vector3(0.018, 0.030, 0.016), Vector3(0, 0.017, rz), m_steel)
				_cyl(opt, "Ring", 0.0155, 0.0155, 0.018, Vector3(0, 0.032, rz), m_steel, 14)
			_cyl(opt, "Tube", 0.013, 0.013, 0.220, Vector3(0, 0.032, 0.0), m_steel, 16)
			_cyl(opt, "Obj", 0.019, 0.013, 0.045, Vector3(0, 0.032, -0.115), m_steel, 16)
			_cyl(opt, "Ocular", 0.013, 0.019, 0.042, Vector3(0, 0.032, 0.096), m_steel, 16)
			_cyl(opt, "Turret", 0.008, 0.008, 0.014, Vector3(0, 0.048, 0.0), m_steel, 10, Vector3.ZERO)
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.039, 0.039)
			g.mesh = q; g.material_override = _create_pip_scope_shader("zf39")
			g.position = Vector3(0, 0.032, 0.120); opt.add_child(g)
		"optic_lpvo":
			_box(opt, "Mount", Vector3(0.026, 0.012, 0.115), Vector3(0, 0.005, 0), m_dark)
			for rz in [-0.044, 0.044]:
				_box(opt, "Stem", Vector3(0.024, 0.028, 0.018), Vector3(0, 0.019, rz), m_dark)
				_cyl(opt, "Ring", 0.0195, 0.0195, 0.018, Vector3(0, 0.033, rz), m_dark, 16)
			_cyl(opt, "Tube", 0.0155, 0.0155, 0.185, Vector3(0, 0.033, 0.0), m_steel, 18)
			_cyl(opt, "ObjBell", 0.021, 0.0155, 0.044, Vector3(0, 0.033, -0.098), m_steel, 18)
			_cyl(opt, "ObjGlass", 0.0185, 0.0185, 0.003, Vector3(0, 0.033, -0.121), m_obj, 16)
			_cyl(opt, "Ocular", 0.0155, 0.0225, 0.048, Vector3(0, 0.033, 0.094), m_steel, 20)
			_cyl(opt, "Elev", 0.009, 0.009, 0.016, Vector3(0, 0.054, 0.0), m_dark, 12, Vector3.ZERO)
			_cyl(opt, "Wind", 0.009, 0.009, 0.016, Vector3(0.022, 0.033, 0.0), m_dark, 12, Vector3(0, 0, 90))
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.046, 0.046)
			g.mesh = q; g.material_override = _create_pip_scope_shader("tactical")
			g.position = Vector3(0, 0.033, 0.121); opt.add_child(g)
		"optic_sniper_12x":
			_box(opt, "Mount", Vector3(0.030, 0.014, 0.145), Vector3(0, 0.006, 0), m_dark)
			for rz in [-0.055, 0.048]:
				_box(opt, "Stem", Vector3(0.028, 0.030, 0.022), Vector3(0, 0.021, rz), m_dark)
				_cyl(opt, "Ring", 0.022, 0.022, 0.022, Vector3(0, 0.036, rz), m_dark, 18)
			_cyl(opt, "Tube", 0.0175, 0.0175, 0.245, Vector3(0, 0.036, 0.0), m_dark, 20)
			_cyl(opt, "ObjBell", 0.031, 0.0175, 0.115, Vector3(0, 0.036, -0.175), m_dark, 22)
			_cyl(opt, "ObjGlass", 0.028, 0.028, 0.004, Vector3(0, 0.036, -0.233), m_obj, 20)
			_cyl(opt, "Ocular", 0.0175, 0.0255, 0.068, Vector3(0, 0.036, 0.122), m_dark, 22)
			_cyl(opt, "Elev", 0.013, 0.013, 0.026, Vector3(0, 0.062, 0.0), m_steel, 14, Vector3.ZERO)
			_cyl(opt, "Wind", 0.012, 0.012, 0.024, Vector3(0.026, 0.036, 0.0), m_steel, 14, Vector3(0, 0, 90))
			_cyl(opt, "Parallax", 0.013, 0.013, 0.022, Vector3(-0.026, 0.036, 0.0), m_poly, 14, Vector3(0, 0, 90))
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.051, 0.051)
			g.mesh = q; g.material_override = _create_pip_scope_shader("tactical")
			g.position = Vector3(0, 0.036, 0.159); opt.add_child(g)
		"optic_nvg":
			# 1PN93 Bulky Cylindrical Night Vision Scope with Battery Pod & Green Phosphor PiP!
			_box(opt, "Mount", Vector3(0.032, 0.024, 0.125), Vector3(0, 0.011, 0), m_dark)
			_cyl(opt, "NVBody", 0.026, 0.024, 0.175, Vector3(0, 0.038, -0.010), _mat(Color(0.14, 0.17, 0.14), 0.72, 0.38), 20)
			_cyl(opt, "NVObj", 0.032, 0.026, 0.055, Vector3(0, 0.038, -0.115), m_dark, 20)
			_cyl(opt, "NVObjLens", 0.028, 0.028, 0.004, Vector3(0, 0.038, -0.144), _mat(Color(0.05, 0.36, 0.16), 0.90, 0.04), 18)
			_cyl(opt, "NVBattPod", 0.011, 0.011, 0.075, Vector3(0.026, 0.028, 0.015), m_poly, 12)
			_cyl(opt, "NVEyecup", 0.022, 0.026, 0.042, Vector3(0, 0.038, 0.098), m_poly, 20)
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.050, 0.050)
			g.mesh = q; g.material_override = _create_pip_scope_shader("nvg")
			g.position = Vector3(0, 0.038, 0.122); opt.add_child(g)
		"optic_thermal":
			# FLIR RS-32 Angular Thermal Scope with Germanium Lens & Live Heat-Signature PiP!
			_box(opt, "Mount", Vector3(0.034, 0.022, 0.125), Vector3(0, 0.010, 0), m_dark)
			_box(opt, "FLIRBody", Vector3(0.054, 0.048, 0.145), Vector3(0, 0.038, -0.005), m_poly)
			_box(opt, "FLIRControlTop", Vector3(0.038, 0.008, 0.055), Vector3(0, 0.065, 0.015), m_dark)
			for bi in range(3):
				_box(opt, "Btn", Vector3(0.008, 0.004, 0.008), Vector3(-0.010 + float(bi) * 0.010, 0.070, 0.015), _mat(Color(0.85, 0.42, 0.12), 0.1, 0.4))
			_cyl(opt, "GermaniumBell", 0.027, 0.025, 0.055, Vector3(0, 0.038, -0.098), m_dark, 20)
			_cyl(opt, "GermaniumLens", 0.023, 0.023, 0.004, Vector3(0, 0.038, -0.127), _mat(Color(0.28, 0.24, 0.34), 0.96, 0.06), 18)
			_cyl(opt, "Eyecup", 0.023, 0.026, 0.046, Vector3(0, 0.038, 0.090), m_poly, 20)
			var g := MeshInstance3D.new(); g.name = "OpticLens"
			var q := QuadMesh.new(); q.size = Vector2(0.050, 0.050)
			g.mesh = q; g.material_override = _create_pip_scope_shader("thermal")
			g.position = Vector3(0, 0.038, 0.116); opt.add_child(g)

static func _build_handguard_mesh(parent: Node3D, weapon_id: String, hg_id: String, pos: Vector3, m_dark: Material, m_poly: Material, m_steel: Material) -> void:
	var hg := Node3D.new(); hg.name = "ModHandguard"; hg.position = pos; parent.add_child(hg)
	var is_quad := ("quad" in hg_id or "tac" in hg_id)
	var body_m := m_dark if is_quad else m_poly
	var len_z: float = 0.215 if weapon_id in ["pkm", "mg42", "l96a1", "kar98k"] else 0.168
	_box(hg, "HGShell", Vector3(0.058, 0.052, len_z), Vector3.ZERO, body_m)
	for i in range(4):
		var vz: float = -len_z * 0.34 + float(i) * (len_z * 0.22)
		_box(hg, "Vent", Vector3(0.061, 0.011, 0.022), Vector3(0, 0.004, vz), _mat(Color(0.02, 0.02, 0.025), 0.1, 0.95))
	if is_quad:
		# 4-sided Picatinny quad-rail strips!
		_build_picatinny_rail(hg, Vector3(0, -0.029, 0), len_z * 0.88, m_steel)
		var r_left := Node3D.new(); r_left.position = Vector3(-0.031, 0, 0); r_left.rotation_degrees = Vector3(0, 0, 90); hg.add_child(r_left)
		_build_picatinny_rail(r_left, Vector3.ZERO, len_z * 0.82, m_steel)
		var r_right := Node3D.new(); r_right.position = Vector3(0.031, 0, 0); r_right.rotation_degrees = Vector3(0, 0, -90); hg.add_child(r_right)
		_build_picatinny_rail(r_right, Vector3.ZERO, len_z * 0.82, m_steel)
		if weapon_id == "kar98k":
			# Integrated top Scout Picatinny rail flush with optic_base (y=0.044, z=-0.285 -> local y=0.044, z=+0.035)
			_box(hg, "ScoutTopRiser", Vector3(0.026, 0.020, 0.178), Vector3(0, 0.033, 0.028), m_dark)
			_build_picatinny_rail(hg, Vector3(0, 0.044, 0.035), 0.172, m_steel)

static func _build_muzzle_mesh(parent: Node3D, weapon_id: String, muz_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_chrome: Material) -> void:
	var mz := Node3D.new(); mz.name = "ModMuzzle"; mz.position = pos; parent.add_child(mz)
	var m_bore := _mat(Color(0.015, 0.015, 0.02), 0.0, 0.95)
	match muz_id:
		"muz_suppressor":
			var is_pistol := weapon_id in ["pistol", "deagle"]
			var rad: float = 0.0165 if is_pistol else 0.020
			var h: float = 0.145 if is_pistol else 0.195
			_cyl(mz, "CanBody", rad, rad, h, Vector3(0, 0, -h * 0.48), m_dark, 18)
			_cyl(mz, "CanCollar", rad * 1.08, rad * 1.08, 0.022, Vector3(0, 0, -0.010), m_steel, 18)
			_cyl(mz, "CanBore", rad * 0.45, rad * 0.45, 0.012, Vector3(0, 0, -h * 0.96), m_bore, 12)
		"muz_salvo12":
			# Iconic rectangular sectional SilencerCo Salvo 12 shotgun suppressor!
			_box(mz, "SalvoBody", Vector3(0.036, 0.050, 0.220), Vector3(0, -0.008, -0.108), m_dark)
			for rz in [-0.045, -0.105, -0.165]:
				_box(mz, "SalvoRod", Vector3(0.039, 0.008, 0.010), Vector3(0, -0.008, rz), m_steel)
			_cyl(mz, "SalvoBore", 0.012, 0.012, 0.014, Vector3(0, 0.0, -0.218), m_bore, 12)
		"muz_dtk2":
			_box(mz, "DTKBody", Vector3(0.028, 0.026, 0.068), Vector3(0, 0, -0.032), m_steel)
			_box(mz, "DTKPort1", Vector3(0.030, 0.014, 0.014), Vector3(0, 0, -0.020), m_bore)
			_box(mz, "DTKPort2", Vector3(0.030, 0.014, 0.014), Vector3(0, 0, -0.046), m_bore)
		"muz_deagle_10":
			_box(mz, "ExtBarrel", Vector3(0.030, 0.032, 0.115), Vector3(0, 0, -0.056), m_chrome)
			_box(mz, "ExtRib", Vector3(0.018, 0.008, 0.110), Vector3(0, 0.018, -0.056), m_chrome)
			for pz in [-0.075, -0.095]:
				_box(mz, "CompCut", Vector3(0.020, 0.006, 0.010), Vector3(0, 0.021, pz), m_bore)
			_cyl(mz, "ExtBore", 0.009, 0.009, 0.014, Vector3(0, 0, -0.114), m_bore, 14)
		"muz_choke_full":
			_cyl(mz, "Choke", 0.017, 0.019, 0.055, Vector3(0, 0, -0.026), m_steel, 16)
			_cyl(mz, "ChokeRing", 0.0195, 0.0195, 0.010, Vector3(0, 0, -0.015), m_chrome, 16)
		"muz_duckbill":
			_box(mz, "Duckbill", Vector3(0.044, 0.022, 0.056), Vector3(0, 0, -0.026), m_dark)
			_box(mz, "DuckSlot", Vector3(0.036, 0.012, 0.014), Vector3(0, 0, -0.054), m_bore)

static func _build_magazine_mesh(parent: Node3D, weapon_root: Node3D, weapon_id: String, mag_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_bakelite: Material, m_od: Material, m_poly: Material, m_brass: Material, m_red: Material) -> void:
	# Hide vanilla magazine when replacing with a custom-sized magazine or drum!
	var van_mag := weapon_root.get_node_or_null("Magazine")
	var van_box := weapon_root.get_node_or_null("AmmoBox")
	if van_mag and weapon_id in ["ak47", "pistol", "l96a1", "deagle", "aa12"]:
		van_mag.visible = false
	if van_box and weapon_id in ["pkm", "mg42"]:
		van_box.visible = false

	var mg := Node3D.new(); mg.name = "ModMagazine"; mg.position = pos; parent.add_child(mg)
	match mag_id:
		"ak_mag_10":
			_box(mg, "ShortMag", Vector3(0.028, 0.088, 0.062), Vector3(0, -0.042, -0.005), m_poly, Vector3(10, 0, 0))
		"ak_mag_45":
			_box(mg, "RPKUp", Vector3(0.028, 0.115, 0.064), Vector3(0, -0.052, -0.008), m_bakelite, Vector3(12, 0, 0))
			_box(mg, "RPKMid", Vector3(0.028, 0.115, 0.064), Vector3(0, -0.155, -0.038), m_bakelite, Vector3(26, 0, 0))
			_box(mg, "RPKLow", Vector3(0.028, 0.085, 0.064), Vector3(0, -0.238, -0.082), m_bakelite, Vector3(36, 0, 0))
		"ak_mag_75":
			_box(mg, "DrumNeck", Vector3(0.030, 0.075, 0.064), Vector3(0, -0.032, 0), m_dark)
			_cyl(mg, "Drum75", 0.084, 0.084, 0.062, Vector3(0, -0.125, -0.005), m_dark, 24)
			_cyl(mg, "DrumHub", 0.026, 0.026, 0.070, Vector3(0, -0.125, -0.005), m_steel, 14)
		"sg_tube_4":
			var mt := weapon_root.get_node_or_null("MagTube")
			if mt: mt.scale = Vector3(1.0, 0.78, 1.0)
		"sg_tube_8":
			_cyl(mg, "ExtTube", 0.014, 0.014, 0.165, Vector3(0, 0, -0.080), m_dark, 14)
			_cyl(mg, "ExtCap", 0.0165, 0.0165, 0.028, Vector3(0, 0, -0.165), m_steel, 14)
			_box(mg, "ExtClamp", Vector3(0.034, 0.054, 0.018), Vector3(0, 0.018, -0.125), m_dark)
		"ps_mag_12":
			_box(mg, "Mag12", Vector3(0.021, 0.085, 0.030), Vector3(0, 0.005, 0), m_dark, Vector3(-20, 0, 0))
		"ps_mag_33":
			_box(mg, "Mag33", Vector3(0.022, 0.215, 0.032), Vector3(0, -0.055, 0.022), m_dark, Vector3(-20, 0, 0))
			_box(mg, "Mag33Pad", Vector3(0.028, 0.014, 0.038), Vector3(0, -0.158, 0.060), m_poly, Vector3(-20, 0, 0))
		"k98_mag_10":
			_box(mg, "TrenchMag", Vector3(0.028, 0.092, 0.095), Vector3(0, -0.042, 0), m_steel, Vector3(6, 0, 0))
		"pkm_box_50":
			_box(mg, "SoftBox50", Vector3(0.072, 0.098, 0.115), Vector3(0, 0.018, 0), m_od)
		"pkm_box_200":
			_box(mg, "HugeBox200", Vector3(0.128, 0.175, 0.185), Vector3(0, -0.022, 0), m_od)
			_box(mg, "Rib", Vector3(0.134, 0.016, 0.175), Vector3(0, 0.02, 0), m_dark)
		"l96_mag_10":
			_box(mg, "Mag10", Vector3(0.032, 0.155, 0.092), Vector3(0, -0.028, 0), m_steel)
			_box(mg, "Pad10", Vector3(0.036, 0.014, 0.098), Vector3(0, -0.106, 0), m_poly)
		"de_mag_10":
			_box(mg, "DeMag10", Vector3(0.027, 0.155, 0.048), Vector3(0, -0.022, 0.008), m_dark, Vector3(-18, 0, 0))
			_box(mg, "DePad10", Vector3(0.036, 0.016, 0.058), Vector3(0, -0.098, 0.034), m_poly, Vector3(-18, 0, 0))
		"aa_mag_8":
			_box(mg, "Box8", Vector3(0.042, 0.165, 0.090), Vector3(0, 0.018, 0), m_poly)
		"aa_mag_32":
			_box(mg, "Tower32", Vector3(0.048, 0.082, 0.096), Vector3(0, 0.074, 0), m_poly)
			_cyl(mg, "Drum32", 0.122, 0.122, 0.104, Vector3(0, -0.018, 0), m_poly, 28)
			_cyl(mg, "Hub32", 0.038, 0.038, 0.114, Vector3(0, -0.018, 0), m_steel, 18)
			_box(mg, "RedArc", Vector3(0.022, 0.072, 0.110), Vector3(0.075, -0.010, 0), m_red)
		"mg_box_50":
			_cyl(mg, "Drum50", 0.064, 0.064, 0.074, Vector3(0.016, 0.010, 0), m_od, 20)
		"mg_box_250":
			_box(mg, "Box250", Vector3(0.115, 0.165, 0.185), Vector3(-0.012, -0.036, 0), m_od)
			_box(mg, "BeltBridge", Vector3(0.068, 0.024, 0.076), Vector3(0.048, 0.040, 0), m_brass)

static func _build_underbarrel_mesh(parent: Node3D, ub_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_poly: Material, m_bakelite: Material, m_brass: Material) -> void:
	var ub := Node3D.new(); ub.name = "ModUnderbarrel"; ub.position = pos; parent.add_child(ub)
	var m_bore := _mat(Color(0.015, 0.015, 0.02), 0.0, 0.95)
	match ub_id:
		"ub_gp25":
			# Authentic Soviet GP-25 Koster 40mm Underbarrel Grenade Launcher!
			_box(ub, "MountBracket", Vector3(0.036, 0.026, 0.088), Vector3(0, 0.008, 0.025), m_dark)
			_cyl(ub, "GP25Barrel", 0.0225, 0.0225, 0.185, Vector3(0, -0.018, -0.038), m_steel, 18)
			_cyl(ub, "GP25Bore", 0.0185, 0.0185, 0.014, Vector3(0, -0.018, -0.130), m_bore, 14)
			_cyl(ub, "VOG25Tip", 0.014, 0.018, 0.028, Vector3(0, -0.018, -0.125), m_brass, 12)
			_box(ub, "GP25Receiver", Vector3(0.036, 0.042, 0.082), Vector3(0, -0.020, 0.072), m_dark)
			_box(ub, "GP25Grip", Vector3(0.028, 0.078, 0.036), Vector3(0, -0.068, 0.095), m_bakelite, Vector3(-16, 0, 0))
			_box(ub, "QuadSight", Vector3(0.006, 0.034, 0.028), Vector3(-0.022, 0.004, 0.055), m_steel)
		"ub_m203":
			# Classic M203 40mm Underbarrel Grenade Launcher!
			_box(ub, "M203Mount", Vector3(0.038, 0.020, 0.115), Vector3(0, 0.008, 0.010), m_dark)
			_cyl(ub, "M203Tube", 0.0235, 0.0235, 0.235, Vector3(0, -0.018, -0.025), m_dark, 18)
			for rz in [-0.09, -0.05, -0.01, 0.03]:
				_cyl(ub, "TubeRib", 0.025, 0.025, 0.012, Vector3(0, -0.018, rz), m_poly, 16)
			_cyl(ub, "M203Bore", 0.019, 0.019, 0.014, Vector3(0, -0.018, -0.142), m_bore, 14)
			_box(ub, "M203TriggerGuard", Vector3(0.018, 0.026, 0.044), Vector3(0, -0.044, 0.082), m_steel)
		"ub_grip_rk1":
			_box(ub, "Clamp", Vector3(0.032, 0.016, 0.042), Vector3(0, 0.004, 0), m_dark)
			_cyl(ub, "GripBody", 0.0155, 0.0145, 0.096, Vector3(0, -0.050, 0.004), m_poly, 14, Vector3(6, 0, 0))
			_cyl(ub, "GripCap", 0.0165, 0.0165, 0.014, Vector3(0, -0.096, 0.008), m_steel, 14, Vector3(6, 0, 0))
		"ub_grip_afg":
			_box(ub, "AFGRail", Vector3(0.030, 0.016, 0.115), Vector3(0, 0.002, 0), m_poly)
			_box(ub, "AFGSlope", Vector3(0.028, 0.028, 0.098), Vector3(0, -0.014, -0.006), m_poly, Vector3(-16, 0, 0))
		"ub_bipod_harris":
			_box(ub, "BipodMount", Vector3(0.036, 0.022, 0.036), Vector3(0, 0, 0), m_dark)
			for sx in [-1.0, 1.0]:
				_cyl(ub, "Leg", 0.007, 0.006, 0.185, Vector3(0.024 * sx, -0.022, -0.088), m_steel, 10, Vector3(-96, 6 * sx, 0))
				_cyl(ub, "Foot", 0.010, 0.010, 0.018, Vector3(0.032 * sx, -0.032, -0.182), m_poly, 10)

static func _build_laser_mesh(parent: Node3D, las_id: String, pos: Vector3, m_dark: Material, m_tan: Material, m_steel: Material) -> void:
	var las := Node3D.new(); las.name = "ModLaser"; las.position = pos; parent.add_child(las)
	var is_green := (las_id == "tac_laser_green")
	var body_m := m_tan if is_green else m_dark
	var emit_col := Color(0.12, 1.0, 0.28) if is_green else Color(1.0, 0.10, 0.08)
	# Monolithic rail clamp collar bridging cleanly into handguard/rail (zero floating!)
	var clamp_off := Vector3(-0.012, 0, 0) if pos.x > 0.01 else Vector3(0, 0.012, 0)
	_box(las, "RailClamp", Vector3(0.018, 0.018, 0.056), clamp_off, m_dark)
	_box(las, "LaserBox", Vector3(0.026, 0.024, 0.072), Vector3.ZERO, body_m)
	_cyl(las, "LaserEmitterLens", 0.0065, 0.0065, 0.010, Vector3(0, 0, -0.038), _mat(emit_col, 0.0, 0.1, emit_col, 2.5), 12)
	_cyl(las, "ModeDial", 0.007, 0.007, 0.008, Vector3(0, 0.015, 0.012), m_steel, 10, Vector3.ZERO)
	var em := Marker3D.new(); em.name = "LaserEmitter"; em.position = Vector3(0, 0, -0.044); las.add_child(em)

static func _build_flashlight_mesh(parent: Node3D, fl_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_chrome: Material) -> void:
	var fl := Node3D.new(); fl.name = "ModFlashlight"; fl.position = pos; parent.add_child(fl)
	var big := (fl_id == "tac_light_surefire")
	var r_head: float = 0.0165 if big else 0.0135
	var clamp_off := Vector3(0.012, 0, 0) if pos.x < -0.01 else (Vector3(-0.012, 0, 0) if pos.x > 0.01 else Vector3(0, 0.012, 0))
	_box(fl, "RailMount", Vector3(0.018, 0.018, 0.052), clamp_off, m_dark)
	_cyl(fl, "Tube", 0.011, 0.011, 0.085, Vector3(0, 0, 0.012), m_dark, 14)
	_cyl(fl, "Bezel", r_head, 0.012, 0.032, Vector3(0, 0, -0.042), m_steel, 16)
	_cyl(fl, "Lens", r_head * 0.82, r_head * 0.82, 0.004, Vector3(0, 0, -0.058), _mat(Color(1.0, 0.96, 0.85), 0.1, 0.1, Color(1.0, 0.94, 0.78), 1.2), 14)
	_cyl(fl, "TailCap", 0.012, 0.012, 0.016, Vector3(0, 0, 0.058), m_chrome, 12)
	var em := Marker3D.new(); em.name = "FlashlightEmitter"; em.position = Vector3(0, 0, -0.062); fl.add_child(em)

static func _build_pistol_grip_mesh(parent: Node3D, pg_id: String, pos: Vector3, m_poly: Material, m_steel: Material, m_chrome: Material, m_bakelite: Material) -> void:
	var pg := Node3D.new(); pg.name = "ModPistolGrip"; pg.position = pos; pg.rotation_degrees = Vector3(-18, 0, 0); parent.add_child(pg)
	match pg_id:
		"grip_rk3":
			_box(pg, "RK3Body", Vector3(0.036, 0.108, 0.048), Vector3.ZERO, m_poly)
			_box(pg, "RK3Back", Vector3(0.038, 0.092, 0.014), Vector3(0, -0.004, 0.022), m_steel)
		"grip_skeleton":
			_box(pg, "SkelFront", Vector3(0.034, 0.106, 0.012), Vector3(0, 0, -0.018), m_chrome)
			_box(pg, "SkelRear", Vector3(0.034, 0.106, 0.012), Vector3(0, 0, 0.018), m_chrome)
			_box(pg, "SkelBase", Vector3(0.036, 0.012, 0.048), Vector3(0, -0.052, 0), m_steel)
		"de_grip_walnut":
			_box(pg, "WalnutWrap", Vector3(0.043, 0.108, 0.054), Vector3(0, -0.002, 0.004), m_bakelite)
		"ps_grip_rubber":
			_box(pg, "HogueSideL", Vector3(0.005, 0.084, 0.044), Vector3(-0.016, 0.0, 0.0), m_poly)
			_box(pg, "HogueSideR", Vector3(0.005, 0.084, 0.044), Vector3(0.016, 0.0, 0.0), m_poly)
			_box(pg, "HogueBack", Vector3(0.032, 0.082, 0.006), Vector3(0, 0.0, 0.022), m_poly)

static func _build_stock_adapter_mesh(parent: Node3D, st_id: String, pos: Vector3, m_dark: Material, m_steel: Material, m_poly: Material) -> void:
	var st := Node3D.new(); st.name = "ModStockAdapter"; st.position = pos; parent.add_child(st)
	if "tube" in st_id:
		# Authentic AR-15 Buffer Tube + Castle Nut + Endplate!
		_box(st, "AdapterBlock", Vector3(0.042, 0.046, 0.034), Vector3(0, 0, 0.015), m_dark)
		_cyl(st, "CastleNut", 0.0195, 0.0195, 0.014, Vector3(0, 0, 0.038), m_steel, 12)
		_cyl(st, "BufferTube", 0.016, 0.016, 0.175, Vector3(0, 0, 0.128), m_dark, 16)
		_box(st, "PosRail", Vector3(0.010, 0.010, 0.145), Vector3(0, -0.016, 0.130), m_steel)
	elif st_id == "ak_stock_fold":
		# Classic AKS-74 Folding Triangle Skeleton Stock!
		_box(st, "TopStrut", Vector3(0.014, 0.014, 0.225), Vector3(0, 0.010, 0.115), m_steel)
		_box(st, "BotStrut", Vector3(0.014, 0.014, 0.232), Vector3(0, -0.044, 0.115), m_steel, Vector3(-16, 0, 0))
		_box(st, "ButtBar", Vector3(0.032, 0.102, 0.014), Vector3(0, -0.034, 0.230), m_dark)
	elif st_id == "sg_stock_pistol":
		_box(st, "SawedGrip", Vector3(0.036, 0.095, 0.046), Vector3(0, -0.048, 0.036), m_poly, Vector3(-24, 0, 0))

static func _build_buttstock_mesh(parent: Node3D, bs_id: String, pos: Vector3, m_poly: Material, m_dark: Material, m_tan: Material, m_steel: Material) -> void:
	var bs := Node3D.new(); bs.name = "ModButtstock"; bs.position = pos; parent.add_child(bs)
	match bs_id:
		"stock_ctr":
			_box(bs, "TopTubeWrap", Vector3(0.042, 0.042, 0.155), Vector3(0, 0.002, 0.0), m_poly)
			_box(bs, "LowerFrame", Vector3(0.032, 0.068, 0.120), Vector3(0, -0.042, 0.022), m_poly, Vector3(12, 0, 0))
			_box(bs, "Pad", Vector3(0.044, 0.112, 0.018), Vector3(0, -0.036, 0.082), m_dark)
		"stock_glshock":
			_box(bs, "GLBody", Vector3(0.046, 0.052, 0.165), Vector3(0, 0.004, 0.0), m_tan)
			_box(bs, "GLCheek", Vector3(0.048, 0.020, 0.115), Vector3(0, 0.028, 0.010), m_dark)
			_box(bs, "GLSpring", Vector3(0.036, 0.065, 0.115), Vector3(0, -0.040, 0.025), m_tan)
			_box(bs, "GLPad", Vector3(0.048, 0.118, 0.024), Vector3(0, -0.034, 0.088), m_dark)
		"stock_prs":
			_box(bs, "PRSMain", Vector3(0.044, 0.098, 0.185), Vector3(0, -0.030, 0.010), m_poly)
			_box(bs, "PRSCheek", Vector3(0.046, 0.024, 0.120), Vector3(0, 0.032, 0.008), m_dark)
			_cyl(bs, "Wheel1", 0.014, 0.014, 0.046, Vector3(0, -0.012, 0.015), m_steel, 12, Vector3(0, 0, 90))
			_cyl(bs, "Wheel2", 0.014, 0.014, 0.046, Vector3(0, -0.048, 0.045), m_steel, 12, Vector3(0, 0, 90))
			_box(bs, "PRSPad", Vector3(0.046, 0.118, 0.022), Vector3(0, -0.032, 0.106), m_dark)

# =========================================================================
# 3D MINIATURE GENERATOR FOR WORKBENCH EFT SQUARE SLOTS (ALL 85+ MODS!)
# =========================================================================
static func create_mod_preview(mod_id: String) -> Node3D:
	var wrap := Node3D.new()
	wrap.name = "ModPreview_" + mod_id
	var m_dark := _mat(Color(0.10, 0.11, 0.12), 0.84, 0.34)
	var m_steel := _mat(Color(0.20, 0.21, 0.23), 0.90, 0.28)
	var m_chrome := _mat(Color(0.76, 0.78, 0.82), 0.95, 0.18)
	var m_poly := _mat(Color(0.13, 0.14, 0.15), 0.10, 0.65)
	var m_tan := _mat(Color(0.48, 0.42, 0.30), 0.10, 0.60)
	var m_od := _mat(Color(0.22, 0.30, 0.17), 0.45, 0.50)
	var m_bakelite := _mat(Color(0.56, 0.22, 0.08), 0.05, 0.42)
	var m_brass := _mat(Color(0.88, 0.72, 0.25), 0.94, 0.18)
	var m_red := _mat(Color(0.86, 0.14, 0.12), 0.10, 0.35)
	var m_glow := _mat(Color(0.25, 1.0, 0.40), 0.0, 0.2, Color(0.20, 0.95, 0.35), 2.2)

	var holder := Node3D.new()
	wrap.add_child(holder)

	if mod_id.begins_with("optic_") or mod_id in ["l96_opt_pm2", "rpg_opt_pgo7"]:
		var oid := "optic_sniper_12x" if mod_id == "l96_opt_pm2" else ("optic_acog" if mod_id == "rpg_opt_pgo7" else mod_id)
		_build_optic_mesh(holder, oid, Vector3(0, -0.032, 0), m_dark, m_steel, m_poly, m_glow)
		wrap.scale = Vector3(3.8, 3.8, 3.8)
	elif mod_id.begins_with("muz_") or mod_id in ["ak_muz_slant", "pkm_muz_std", "l96_muz_std", "mg_muz_std"]:
		_build_muzzle_mesh(holder, "ak47", "muz_dtk2" if not mod_id.begins_with("muz_") else mod_id, Vector3(0, 0, 0.06), m_dark, m_steel, m_chrome)
		wrap.scale = Vector3(4.2, 4.2, 4.2)
	elif mod_id.begins_with("ub_"):
		_build_underbarrel_mesh(holder, mod_id, Vector3(0, 0.03, 0.02), m_dark, m_steel, m_poly, m_bakelite, m_brass)
		wrap.scale = Vector3(3.5, 3.5, 3.5)
	elif mod_id.begins_with("tac_laser"):
		_build_laser_mesh(holder, mod_id, Vector3.ZERO, m_dark, m_tan, m_steel)
		wrap.scale = Vector3(7.0, 7.0, 7.0)
	elif mod_id.begins_with("tac_light"):
		_build_flashlight_mesh(holder, mod_id, Vector3.ZERO, m_dark, m_steel, m_chrome)
		wrap.scale = Vector3(5.8, 5.8, 5.8)
	elif mod_id.begins_with("stock_"):
		_build_buttstock_mesh(holder, mod_id, Vector3.ZERO, m_poly, m_dark, m_tan, m_steel)
		wrap.scale = Vector3(3.4, 3.4, 3.4)
	elif "tube_" in mod_id or "_stock_" in mod_id:
		_build_stock_adapter_mesh(holder, mod_id if ("tube" in mod_id or mod_id in ["ak_stock_fold", "sg_stock_pistol"]) else "ak_stock_fold", Vector3(0, 0, -0.10), m_dark, m_steel, m_poly)
		wrap.scale = Vector3(3.2, 3.2, 3.2)
	elif "_hg_" in mod_id:
		_build_handguard_mesh(holder, "ak47", mod_id, Vector3.ZERO, m_dark, m_poly, m_steel)
		wrap.scale = Vector3(3.4, 3.4, 3.4)
	elif "_rail" in mod_id or "_cover_" in mod_id:
		_build_picatinny_rail(holder, Vector3.ZERO, 0.16, m_dark)
		wrap.scale = Vector3(3.8, 3.8, 3.8)
	elif "_grip" in mod_id or mod_id.begins_with("grip_"):
		_build_pistol_grip_mesh(holder, mod_id if mod_id in ["grip_rk3", "grip_skeleton", "de_grip_walnut"] else "grip_rk3", Vector3.ZERO, m_poly, m_steel, m_chrome, m_bakelite)
		wrap.scale = Vector3(5.2, 5.2, 5.2)
	elif "_mag_" in mod_id or "_box_" in mod_id or "_tube_" in mod_id:
		var dummy := Node3D.new()
		_build_magazine_mesh(holder, dummy, "ak47", mod_id if mod_id in ["ak_mag_10", "ak_mag_45", "ak_mag_75", "ps_mag_33", "pkm_box_200", "aa_mag_32", "mg_box_250"] else "ak_mag_45", Vector3(0, 0.08, 0), m_dark, m_steel, m_bakelite, m_od, m_poly, m_brass, m_red)
		dummy.free()
		wrap.scale = Vector3(2.8, 2.8, 2.8)
	elif mod_id.begins_with("int_"):
		_box(holder, "Trig", Vector3(0.014, 0.048, 0.022), Vector3.ZERO, m_brass if mod_id == "int_match_trigger" else m_chrome, Vector3(-16, 0, 0))
		_cyl(holder, "Spring", 0.012, 0.012, 0.065, Vector3(0, 0.025, -0.02), m_steel, 12)
		wrap.scale = Vector3(6.5, 6.5, 6.5)
	elif mod_id in ["ammo_rpg_pg7v", "ammo_rpg_tandem", "ammo_rpg_thermo"]:
		var wt := "tandem" if mod_id == "ammo_rpg_tandem" else ("thermobaric" if mod_id == "ammo_rpg_thermo" else "standard")
		var wh := RPGModelScript.create_warhead_by_type(wt, false)
		wh.position = Vector3(0, 0, 0.18)
		holder.add_child(wh)
		wrap.scale = Vector3(1.55, 1.55, 1.55)
	elif mod_id.begins_with("ammo_"):
		var tip_m := m_red if ("dragon" in mod_id or "inc" in mod_id or "thermo" in mod_id) else (m_dark if ("ap" in mod_id or "smk" in mod_id or "bs" in mod_id or "tandem" in mod_id) else m_brass)
		for i in range(3):
			_cyl(holder, "C_%d" % i, 0.011, 0.012, 0.055, Vector3(-0.026 + float(i) * 0.026, -0.01, 0), m_brass, 12, Vector3.ZERO)
			_cyl(holder, "T_%d" % i, 0.002, 0.010, 0.028, Vector3(-0.026 + float(i) * 0.026, 0.032, 0), tip_m, 12, Vector3.ZERO)
		wrap.scale = Vector3(6.2, 6.2, 6.2)
	else:
		_box(holder, "Fallback", Vector3(0.08, 0.05, 0.10), Vector3.ZERO, m_steel)
		wrap.scale = Vector3(4.0, 4.0, 4.0)

	wrap.rotation_degrees = Vector3(14.0, -34.0, 0.0)
	return wrap
