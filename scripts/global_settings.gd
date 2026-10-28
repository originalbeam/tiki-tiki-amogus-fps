extends Node

const DIFF_EASY: int = 0
const DIFF_NORMAL: int = 1
const DIFF_HARD: int = 2

var current_difficulty: int = DIFF_NORMAL
var last_wave: int = 1
var current_score: int = 0
var mouse_sensitivity: float = 0.0025

# Graphics Settings
var is_fullscreen: bool = false
var is_vsync: bool = true
var msaa_level: int = 1 # 0: Off, 1: 2x, 2: 4x, 3: 8x
var glow_enabled: bool = true
var shadows_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Check if window is currently fullscreen
	is_fullscreen = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

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
