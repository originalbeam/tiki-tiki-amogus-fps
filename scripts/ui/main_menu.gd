extends Control

@onready var main_buttons: VBoxContainer = $CenterContainer/MainButtons
@onready var difficulty_panel: VBoxContainer = $CenterContainer/DifficultyPanel
@onready var settings_panel: VBoxContainer = $CenterContainer/SettingsPanel

# Settings UI controls
@onready var fullscreen_check: CheckBox = $CenterContainer/SettingsPanel/Grid/FullscreenCheck
@onready var vsync_check: CheckBox = $CenterContainer/SettingsPanel/Grid/VsyncCheck
@onready var msaa_options: OptionButton = $CenterContainer/SettingsPanel/Grid/MsaaOptions
@onready var glow_check: CheckBox = $CenterContainer/SettingsPanel/Grid/GlowCheck
@onready var shadows_check: CheckBox = $CenterContainer/SettingsPanel/Grid/ShadowsCheck

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show_main_menu()
	init_settings_values()

func show_main_menu() -> void:
	if main_buttons:
		main_buttons.visible = true
	if difficulty_panel:
		difficulty_panel.visible = false
	if settings_panel:
		settings_panel.visible = false

func init_settings_values() -> void:
	if not GlobalSettings:
		return
	if fullscreen_check:
		fullscreen_check.button_pressed = GlobalSettings.is_fullscreen
	if vsync_check:
		vsync_check.button_pressed = GlobalSettings.is_vsync
	
	if msaa_options:
		msaa_options.clear()
		msaa_options.add_item("Выкл (Disabled)", 0)
		msaa_options.add_item("MSAA 2x", 1)
		msaa_options.add_item("MSAA 4x", 2)
		msaa_options.add_item("MSAA 8x", 3)
		msaa_options.selected = GlobalSettings.msaa_level
	
	if glow_check:
		glow_check.button_pressed = GlobalSettings.glow_enabled
	if shadows_check:
		shadows_check.button_pressed = GlobalSettings.shadows_enabled

# --- Main Buttons ---
func _on_play_btn_pressed() -> void:
	main_buttons.visible = false
	difficulty_panel.visible = true

func _on_settings_btn_pressed() -> void:
	main_buttons.visible = false
	settings_panel.visible = true
	# Sync fullscreen checkbox with actual window state
	if fullscreen_check and GlobalSettings:
		fullscreen_check.button_pressed = GlobalSettings.is_fullscreen

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

# --- Difficulty Selection ---
func _on_easy_btn_pressed() -> void:
	start_game_with_difficulty(0)

func _on_normal_btn_pressed() -> void:
	start_game_with_difficulty(1)

func _on_hard_btn_pressed() -> void:
	start_game_with_difficulty(2)

func start_game_with_difficulty(diff: int) -> void:
	if GlobalSettings:
		GlobalSettings.set_difficulty(diff)
		GlobalSettings.last_wave = 1
		GlobalSettings.current_score = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# --- Graphics Settings ---
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if GlobalSettings:
		GlobalSettings.set_fullscreen(toggled_on)

func _on_vsync_toggled(toggled_on: bool) -> void:
	if GlobalSettings:
		GlobalSettings.set_vsync(toggled_on)

func _on_msaa_selected(index: int) -> void:
	if GlobalSettings:
		GlobalSettings.set_msaa(index)

func _on_glow_toggled(toggled_on: bool) -> void:
	if GlobalSettings:
		GlobalSettings.set_glow(toggled_on)

func _on_shadows_toggled(toggled_on: bool) -> void:
	if GlobalSettings:
		GlobalSettings.set_shadows(toggled_on)

func _on_back_to_menu_pressed() -> void:
	show_main_menu()
