class_name EnvironmentController
extends Node3D

# Smooth Day/Night Cycle & Dynamic Weather Controller
# Rules:
# - Smooth continuous transitions of sun, sky, ambient, fog & arena floodlights.
# - Night waves are rare: exactly 2 night waves out of every 5 ordinary waves, NEVER on boss waves!
# - Weather: Waves 1..4 are ALWAYS clear; Waves 5+ roll random weather (Clear / Fog / Precip / Storm),
#   adapted to the active biome (Rain in Forest/Factory/City, Blizzard in Arctic, Sandstorm in Desert).

var world_env: WorldEnvironment = null
var sun_light: DirectionalLight3D = null
var sky_mat: ProceduralSkyMaterial = null

var active_map_id: String = "forest"
var current_wave_num: int = 1
var is_night_wave: bool = false
var current_weather: String = "clear" # "clear", "fog", "precip", "storm"
var night_blend: float = 0.0 # 0.0 = day, 1.0 = night
var fog_blend: float = 0.0

# Target environment visual parameters
var target_sun_energy: float = 1.05
var target_sun_color: Color = Color(0.96, 0.94, 0.88)
var target_sun_pitch_deg: float = -45.0
var target_sun_yaw_deg: float = -30.0
var target_ambient_energy: float = 0.85
var target_ambient_color: Color = Color(0.32, 0.36, 0.44)
var target_sky_top: Color = Color(0.14, 0.30, 0.58)
var target_sky_horizon: Color = Color(0.55, 0.68, 0.82)
var target_ground_bottom: Color = Color(0.08, 0.10, 0.08)
var target_fog_density: float = 0.0025
var target_fog_color: Color = Color(0.52, 0.62, 0.72)

# Weather VFX (follows player overhead) & Lightning Storm timer
var precip_particles: CPUParticles3D = null
var precip_mat: StandardMaterial3D = null
var lightning_timer: float = 6.0
var lightning_flash: float = 0.0

# Track wave -> (is_night, weather) deterministically per wave so retries keep consistency
var _wave_schedule_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("environment_controller")
	if GlobalSettings:
		active_map_id = GlobalSettings.selected_map_id
	_bind_scene_nodes()
	_setup_precip_particles()
	apply_wave_environment(1, false, true)

func _bind_scene_nodes() -> void:
	var parent: Node = get_parent()
	if not parent:
		parent = get_tree().current_scene
	if parent:
		world_env = parent.get_node_or_null("WorldEnvironment") as WorldEnvironment
		sun_light = parent.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if not world_env:
		var envs := get_tree().root.find_children("*", "WorldEnvironment", true, false)
		if envs.size() > 0:
			world_env = envs[0] as WorldEnvironment
	if not sun_light:
		var suns := get_tree().root.find_children("*", "DirectionalLight3D", true, false)
		if suns.size() > 0:
			sun_light = suns[0] as DirectionalLight3D
	if world_env and world_env.environment:
		# Duplicate so runtime mutations never dirty scene resource
		world_env.environment = world_env.environment.duplicate()
		var env: Environment = world_env.environment
		env.fog_enabled = true
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			env.sky = env.sky.duplicate()
			sky_mat = (env.sky.sky_material as ProceduralSkyMaterial).duplicate()
			env.sky.sky_material = sky_mat

func _setup_precip_particles() -> void:
	precip_particles = CPUParticles3D.new()
	precip_particles.name = "WeatherPrecipitation"
	precip_particles.emitting = false
	precip_particles.amount = 260
	precip_particles.lifetime = 1.6
	precip_particles.preprocess = 0.5
	precip_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	precip_particles.emission_box_extents = Vector3(26.0, 4.0, 26.0)
	precip_particles.direction = Vector3(0.18, -1.0, 0.12)
	precip_particles.spread = 8.0
	precip_particles.gravity = Vector3(0.0, -2.5, 0.0)
	precip_particles.initial_velocity_min = 14.0
	precip_particles.initial_velocity_max = 20.0

	var bm := BoxMesh.new()
	bm.size = Vector3(0.025, 0.45, 0.025)
	precip_mat = StandardMaterial3D.new()
	precip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	precip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	precip_mat.albedo_color = Color(0.75, 0.85, 0.96, 0.42)
	bm.material = precip_mat
	precip_particles.mesh = bm
	add_child(precip_particles)

func set_biome(map_id: String, instant: bool = false) -> void:
	active_map_id = map_id
	_recompute_targets()
	_configure_precip_for_biome()
	if instant:
		_snap_to_targets()

func is_wave_night_by_rule(wave_num: int, is_boss: bool) -> bool:
	# Boss waves (every 5th wave or forced boss) are NEVER night!
	if is_boss or (wave_num > 0 and wave_num % 5 == 0):
		return false
	# Count how many ordinary (non-boss) waves have occurred up to wave_num (1-based)
	var bosses_before: int = int((wave_num - 1) / 5)
	var ordinary_idx: int = wave_num - bosses_before # 1, 2, 3, 4, 5, 6...
	var pos_in_5: int = (ordinary_idx - 1) % 5 # 0, 1, 2, 3, 4
	# Exactly 2 night waves per every 5 ordinary waves: positions 2 and 3 (e.g. Waves 3 & 4, then 9 & 11...)
	return pos_in_5 == 2 or pos_in_5 == 3

func apply_wave_environment(wave_num: int, is_boss: bool = false, instant: bool = false) -> void:
	current_wave_num = maxi(1, wave_num)
	is_night_wave = is_wave_night_by_rule(current_wave_num, is_boss)

	# Weather rule: Waves 1..4 are ALWAYS clear! Wave 5+ rolls random weather.
	if current_wave_num <= 4:
		current_weather = "clear"
	else:
		var cache_key := "%d_%s" % [current_wave_num, active_map_id]
		if _wave_schedule_cache.has(cache_key):
			current_weather = str(_wave_schedule_cache[cache_key])
		else:
			var roll: float = randf()
			if roll < 0.34:
				current_weather = "clear"
			elif roll < 0.58:
				current_weather = "fog"
			elif roll < 0.82:
				current_weather = "precip"
			else:
				current_weather = "storm"
			_wave_schedule_cache[cache_key] = current_weather

	_recompute_targets()
	_configure_precip_for_biome()
	_sync_arena_floodlights()
	if instant:
		_snap_to_targets()

func set_environment_state(night: bool, weather_id: String, instant: bool = false) -> void:
	is_night_wave = night
	current_weather = weather_id
	_recompute_targets()
	_configure_precip_for_biome()
	_sync_arena_floodlights()
	if instant:
		_snap_to_targets()

func get_weather_display_name() -> String:
	match current_weather:
		"fog": return "Густой туман"
		"precip":
			if active_map_id == "arctic": return "Метель"
			if active_map_id == "desert": return "Песчаная буря"
			return "Дождь"
		"storm": return "Гроза"
		_: return "Ясно"

func get_wave_briefing_tag() -> String:
	var tod_str: String = "🌙 НОЧЬ (берите Фонарь [L] / ПНВ / FLIR!)" if is_night_wave else "☀ ДЕНЬ"
	var w_str: String = "Ясно"
	match current_weather:
		"fog":
			w_str = "🌫 Густой туман (FLIR даёт преимущество!)"
		"precip":
			var p_name: String = "Дождь"
			if active_map_id == "arctic":
				p_name = "❄ Метель"
			elif active_map_id == "desert":
				p_name = "🏜 Песчаная буря"
			else:
				p_name = "🌧 Дождь"
			w_str = p_name
		"storm":
			if active_map_id == "arctic":
				w_str = "⛈ Снежная буря и молнии"
			elif active_map_id == "desert":
				w_str = "🌪 Сильная пылевая буря"
			else:
				w_str = "⛈ Гроза и ливень"
	var map_name: String = str(GlobalSettings.get_map_info(active_map_id).get("name", "Полигон")) if GlobalSettings else "Полигон"
	return "🗺 %s  |  %s  |  %s" % [map_name, tod_str, w_str]

func _recompute_targets() -> void:
	# 1) Biome base daytime palette
	var day_sky_top := Color(0.16, 0.34, 0.62)
	var day_sky_hor := Color(0.56, 0.69, 0.82)
	var day_sun_col := Color(0.98, 0.95, 0.88)
	var day_sun_e := 1.05
	var day_amb_col := Color(0.34, 0.39, 0.46)
	var day_amb_e := 0.82
	var day_fog_col := Color(0.54, 0.65, 0.74)
	var day_fog_d := 0.0022
	var ground_col := Color(0.10, 0.14, 0.08)

	match active_map_id:
		"factory":
			day_sky_top = Color(0.24, 0.28, 0.34)
			day_sky_hor = Color(0.54, 0.56, 0.58)
			day_sun_col = Color(0.94, 0.89, 0.82)
			day_sun_e = 0.95
			day_amb_col = Color(0.36, 0.37, 0.40)
			day_fog_col = Color(0.46, 0.48, 0.50)
			day_fog_d = 0.0038
			ground_col = Color(0.14, 0.14, 0.15)
		"arctic":
			day_sky_top = Color(0.20, 0.42, 0.72)
			day_sky_hor = Color(0.76, 0.85, 0.94)
			day_sun_col = Color(0.94, 0.97, 1.0)
			day_sun_e = 1.15
			day_amb_col = Color(0.52, 0.60, 0.72)
			day_amb_e = 0.92
			day_fog_col = Color(0.76, 0.84, 0.92)
			day_fog_d = 0.0030
			ground_col = Color(0.58, 0.64, 0.72)
		"city":
			day_sky_top = Color(0.22, 0.30, 0.42)
			day_sky_hor = Color(0.58, 0.60, 0.64)
			day_sun_col = Color(0.95, 0.92, 0.86)
			day_sun_e = 0.96
			day_amb_col = Color(0.36, 0.38, 0.42)
			day_fog_col = Color(0.50, 0.52, 0.56)
			day_fog_d = 0.0034
			ground_col = Color(0.12, 0.12, 0.13)
		"desert":
			day_sky_top = Color(0.24, 0.46, 0.74)
			day_sky_hor = Color(0.86, 0.76, 0.58)
			day_sun_col = Color(1.0, 0.92, 0.74)
			day_sun_e = 1.28
			day_amb_col = Color(0.56, 0.48, 0.36)
			day_amb_e = 0.88
			day_fog_col = Color(0.78, 0.68, 0.50)
			day_fog_d = 0.0036
			ground_col = Color(0.42, 0.34, 0.20)

	# 2) Night vs Day blend
	if is_night_wave:
		target_sky_top = Color(0.012, 0.018, 0.040)
		target_sky_horizon = Color(0.045, 0.060, 0.110)
		target_sun_color = Color(0.45, 0.58, 0.88) # Cool moonlight
		target_sun_energy = 0.20
		target_sun_pitch_deg = -26.0
		target_sun_yaw_deg = 42.0
		target_ambient_color = Color(0.08, 0.10, 0.16)
		target_ambient_energy = 0.24
		target_fog_color = Color(0.03, 0.04, 0.075)
		target_fog_density = 0.011
		target_ground_bottom = Color(0.015, 0.02, 0.03)
	else:
		target_sky_top = day_sky_top
		target_sky_horizon = day_sky_hor
		target_sun_color = day_sun_col
		target_sun_energy = day_sun_e
		target_sun_pitch_deg = -48.0
		target_sun_yaw_deg = -32.0
		target_ambient_color = day_amb_col
		target_ambient_energy = day_amb_e
		target_fog_color = day_fog_col
		target_fog_density = day_fog_d
		target_ground_bottom = ground_col

	# 3) Weather modifiers
	match current_weather:
		"fog":
			target_fog_density = 0.032 if not is_night_wave else 0.038
			target_sun_energy *= 0.62
			target_sky_top = target_sky_top.lerp(target_fog_color, 0.55)
			target_sky_horizon = target_sky_horizon.lerp(target_fog_color, 0.72)
		"precip":
			target_fog_density = maxf(target_fog_density, 0.016 if active_map_id != "desert" else 0.026)
			target_sun_energy *= 0.72
			if active_map_id == "desert":
				target_fog_color = Color(0.68, 0.54, 0.34) if not is_night_wave else Color(0.14, 0.10, 0.06)
		"storm":
			target_fog_density = 0.028 if active_map_id != "desert" else 0.036
			target_sun_energy *= 0.45
			target_ambient_energy *= 0.65
			target_sky_top = target_sky_top.darkened(0.45)
			target_sky_horizon = target_sky_horizon.darkened(0.38)
			if active_map_id == "desert":
				target_fog_color = Color(0.58, 0.42, 0.24) if not is_night_wave else Color(0.12, 0.08, 0.04)

func _configure_precip_for_biome() -> void:
	if not precip_particles or not precip_mat:
		return
	var active: bool = (current_weather == "precip" or current_weather == "storm")
	precip_particles.emitting = active
	if not active:
		return
	var heavy: bool = (current_weather == "storm")
	precip_particles.amount = 360 if heavy else 220
	var bm := precip_particles.mesh as BoxMesh
	if active_map_id == "arctic":
		if bm: bm.size = Vector3(0.08, 0.08, 0.08)
		precip_mat.albedo_color = Color(0.94, 0.97, 1.0, 0.72)
		precip_particles.direction = Vector3(0.65 if heavy else 0.30, -0.85, 0.25)
		precip_particles.initial_velocity_min = 6.0 if heavy else 3.2
		precip_particles.initial_velocity_max = 10.5 if heavy else 5.5
	elif active_map_id == "desert":
		if bm: bm.size = Vector3(0.32, 0.05, 0.08)
		precip_mat.albedo_color = Color(0.84, 0.68, 0.42, 0.48 if heavy else 0.34)
		precip_particles.direction = Vector3(1.0, -0.18, 0.35)
		precip_particles.initial_velocity_min = 16.0 if heavy else 11.0
		precip_particles.initial_velocity_max = 24.0 if heavy else 16.0
	else:
		if bm: bm.size = Vector3(0.022, 0.55 if heavy else 0.40, 0.022)
		precip_mat.albedo_color = Color(0.72, 0.84, 0.96, 0.45 if heavy else 0.32)
		precip_particles.direction = Vector3(0.22 if heavy else 0.10, -1.0, 0.14)
		precip_particles.initial_velocity_min = 18.0 if heavy else 14.0
		precip_particles.initial_velocity_max = 25.0 if heavy else 19.0

func _sync_arena_floodlights() -> void:
	if not is_inside_tree():
		return
	var want_lights: bool = is_night_wave or current_weather == "storm" or current_weather == "fog"
	for mgr in get_tree().get_nodes_in_group("arena_interactables"):
		if is_instance_valid(mgr) and mgr.has_method("set_all_floodlights_powered"):
			mgr.set_all_floodlights_powered(want_lights)

func _snap_to_targets() -> void:
	if sun_light:
		sun_light.light_energy = target_sun_energy
		sun_light.light_color = target_sun_color
		sun_light.rotation_degrees = Vector3(target_sun_pitch_deg, target_sun_yaw_deg, 0.0)
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.ambient_light_color = target_ambient_color
		env.ambient_light_energy = target_ambient_energy
		env.fog_light_color = target_fog_color
		env.fog_density = target_fog_density
	if sky_mat:
		sky_mat.sky_top_color = target_sky_top
		sky_mat.sky_horizon_color = target_sky_horizon
		sky_mat.ground_bottom_color = target_ground_bottom
		sky_mat.ground_horizon_color = target_sky_horizon
	night_blend = 1.0 if is_night_wave else 0.0

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	var spd: float = dt * 0.85
	night_blend = lerpf(night_blend, 1.0 if is_night_wave else 0.0, spd)

	# Follow player with weather precipitation volume
	if precip_particles and precip_particles.emitting and is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node3D:
			var pp: Vector3 = (players[0] as Node3D).global_position
			precip_particles.global_position = Vector3(pp.x, pp.y + 11.5, pp.z)

	# Storm lightning flashes + procedural thunder rumble
	if current_weather == "storm":
		lightning_timer -= dt
		if lightning_timer <= 0.0:
			lightning_timer = randf_range(5.5, 13.0)
			lightning_flash = 1.0
			_play_thunder_sfx()
	if lightning_flash > 0.0:
		lightning_flash = maxf(0.0, lightning_flash - dt * 3.8)

	var flash_boost: float = lightning_flash * 1.45
	if sun_light:
		sun_light.light_energy = lerpf(sun_light.light_energy, target_sun_energy, spd) + flash_boost * 0.55
		sun_light.light_color = sun_light.light_color.lerp(target_sun_color, spd)
		sun_light.rotation_degrees.x = lerpf(sun_light.rotation_degrees.x, target_sun_pitch_deg, spd)
		sun_light.rotation_degrees.y = lerpf(sun_light.rotation_degrees.y, target_sun_yaw_deg, spd)
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.ambient_light_color = env.ambient_light_color.lerp(target_ambient_color, spd)
		env.ambient_light_energy = lerpf(env.ambient_light_energy, target_ambient_energy, spd) + flash_boost * 0.25
		env.fog_light_color = env.fog_light_color.lerp(target_fog_color, spd)
		env.fog_density = lerpf(env.fog_density, target_fog_density, spd)
	if sky_mat:
		sky_mat.sky_top_color = sky_mat.sky_top_color.lerp(target_sky_top, spd)
		sky_mat.sky_horizon_color = sky_mat.sky_horizon_color.lerp(target_sky_horizon, spd)
		sky_mat.ground_bottom_color = sky_mat.ground_bottom_color.lerp(target_ground_bottom, spd)
		sky_mat.ground_horizon_color = sky_mat.sky_horizon_color.lerp(target_sky_horizon, spd)

func _play_thunder_sfx() -> void:
	if not is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = SoundEffects.create_rpg_explosion_sound()
	p.pitch_scale = randf_range(0.34, 0.48)
	p.volume_db = -9.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
