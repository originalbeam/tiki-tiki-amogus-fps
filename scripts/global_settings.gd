extends Node

const DIFF_EASY: int = 0
const DIFF_NORMAL: int = 1
const DIFF_HARD: int = 2

var current_difficulty: int = DIFF_NORMAL
var last_wave: int = 1
var current_score: int = 0
var mouse_sensitivity: float = 0.0025

# Arena Map / Biome Selection & Paid Minivan Transfer
const MAP_TRAVEL_COST: int = 250
const MAP_ORDER: Array[String] = ["forest", "factory", "arctic", "city", "desert"]
const MAPS: Dictionary = {
	"forest": {
		"id": "forest",
		"name": "Лесной полигон",
		"short": "ЛЕС",
		"tag": "КЛАССИКА",
		"desc": "Зелёный полигон среди густого хвойного леса: земляные валы, контейнеры, разбитый транспорт и сбалансированные дистанции.",
		"accent": Color(0.42, 0.72, 0.36),
		"weather_precip": "Дождь"
	},
	"factory": {
		"id": "factory",
		"name": "Заброшенный Промзавод",
		"short": "ЗАВОД",
		"tag": "CQB / БОЧКИ",
		"desc": "Бетонный плац, цеха-ангары со сквозными проходами, ржавые цистерны и повышенная плотность топливных бочек и прожекторов.",
		"accent": Color(0.86, 0.56, 0.24),
		"weather_precip": "Ливень"
	},
	"arctic": {
		"id": "arctic",
		"name": "Зимний Арктический Полигон",
		"short": "АРКТИКА",
		"tag": "ХОЛОД / FLIR",
		"desc": "Заснеженный полигон с ледяными укрытиями и полярными ангарами. Идеальный контраст для тепловизора FLIR; вместо дождя — метель.",
		"accent": Color(0.48, 0.78, 0.96),
		"weather_precip": "Метель"
	},
	"city": {
		"id": "city",
		"name": "Разрушенный Городской Квартал",
		"short": "ГОРОД",
		"tag": "СНАЙПЕРЫ",
		"desc": "Асфальт, руины двухэтажных стен с оконными проёмами, разбитые автобусы и длинные прострелы для Kar98k и L96A1.",
		"accent": Color(0.72, 0.74, 0.78),
		"weather_precip": "Дождь"
	},
	"desert": {
		"id": "desert",
		"name": "Пустынная Военная База",
		"short": "ПУСТЫНЯ",
		"tag": "БУРИ / БЛОКПОСТЫ",
		"desc": "Раскалённый песок, бастионы из мешков, дозорные вышки и солнечная дымка. Вместо дождя налетают песчаные бури.",
		"accent": Color(0.92, 0.74, 0.38),
		"weather_precip": "Песчаная буря"
	}
}
var selected_map_id: String = "forest"

func get_map_info(map_id: String = "") -> Dictionary:
	var mid: String = map_id if map_id != "" else selected_map_id
	if MAPS.has(mid):
		return MAPS[mid]
	return MAPS["forest"]

func set_selected_map(map_id: String) -> void:
	if MAPS.has(map_id):
		selected_map_id = map_id

# Graphics Settings
var is_fullscreen: bool = false
var is_vsync: bool = true
var msaa_level: int = 1 # 0: Off, 1: 2x, 2: 4x, 3: 8x
var glow_enabled: bool = true
var shadows_enabled: bool = true

# Audio Settings (0.0 .. 1.0)
var master_volume: float = 0.5
var weapons_volume: float = 0.5
var sfx_volume: float = 0.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Check if window is currently fullscreen
	is_fullscreen = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	setup_audio_buses()
	apply_audio_settings()

func setup_audio_buses() -> void:
	for bus_name in ["Weapons", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func _apply_bus_volume(bus_name: String, linear_val: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped: float = clampf(linear_val, 0.0, 1.0)
	if clamped <= 0.001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))

func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)

func set_weapons_volume(val: float) -> void:
	weapons_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("Weapons", weapons_volume)

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)

func apply_audio_settings() -> void:
	set_master_volume(master_volume)
	set_weapons_volume(weapons_volume)
	set_sfx_volume(sfx_volume)

func _unhandled_input(event: InputEvent) -> void:
	# F11 or Alt+Enter for instant fullscreen toggle
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()

func set_difficulty(diff: int) -> void:
	current_difficulty = diff

func get_enemy_speed_multiplier() -> float:
	match current_difficulty:
		DIFF_EASY:
			return 0.75
		DIFF_HARD:
			return 1.25
		_:
			return 1.0

func get_enemy_damage_multiplier() -> float:
	match current_difficulty:
		DIFF_EASY:
			return 0.65
		DIFF_HARD:
			return 1.35
		_:
			return 1.0

func get_enemy_health_multiplier() -> float:
	match current_difficulty:
		DIFF_EASY:
			return 0.8
		DIFF_HARD:
			return 1.25
		_:
			return 1.0

func get_enemy_shoot_rate_multiplier() -> float:
	match current_difficulty:
		DIFF_EASY:
			return 1.35 # longer delay between shots
		DIFF_HARD:
			return 0.75 # shoots faster
		_:
			return 1.0

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen)

func set_fullscreen(enable: bool) -> void:
	is_fullscreen = enable
	if enable:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_vsync(enable: bool) -> void:
	is_vsync = enable
	if enable:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func set_msaa(level: int) -> void:
	msaa_level = level
	var msaa_val: RenderingServer.ViewportMSAA = RenderingServer.VIEWPORT_MSAA_DISABLED
	match level:
		1:
			msaa_val = RenderingServer.VIEWPORT_MSAA_2X
		2:
			msaa_val = RenderingServer.VIEWPORT_MSAA_4X
		3:
			msaa_val = RenderingServer.VIEWPORT_MSAA_8X
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), msaa_val)

func set_glow(enable: bool) -> void:
	glow_enabled = enable
	var env: Environment = get_current_environment()
	if env:
		env.glow_enabled = enable

func set_shadows(enable: bool) -> void:
	shadows_enabled = enable
	RenderingServer.directional_shadow_atlas_set_size(2048 if enable else 0, true)

func apply_graphics_settings() -> void:
	set_fullscreen(is_fullscreen)
	set_vsync(is_vsync)
	set_msaa(msaa_level)
	set_shadows(shadows_enabled)

func get_current_environment() -> Environment:
	var world_env: Node = get_tree().root.find_child("WorldEnvironment", true, false)
	if world_env and "environment" in world_env and world_env.environment:
		return world_env.environment
	return null
