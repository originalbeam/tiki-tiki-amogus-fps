extends Control

@onready var main_buttons: VBoxContainer = $CenterContainer/MainButtons
@onready var difficulty_panel: VBoxContainer = $CenterContainer/DifficultyPanel
@onready var settings_panel: VBoxContainer = $CenterContainer/SettingsPanel

# Settings UI controls
@onready var master_vol_slider: HSlider = $CenterContainer/SettingsPanel/Grid/MasterVolBox/MasterVolSlider
@onready var master_vol_value: Label = $CenterContainer/SettingsPanel/Grid/MasterVolBox/MasterVolValue
@onready var weapons_vol_slider: HSlider = $CenterContainer/SettingsPanel/Grid/WeaponsVolBox/WeaponsVolSlider
@onready var weapons_vol_value: Label = $CenterContainer/SettingsPanel/Grid/WeaponsVolBox/WeaponsVolValue
@onready var sfx_vol_slider: HSlider = $CenterContainer/SettingsPanel/Grid/SfxVolBox/SfxVolSlider
@onready var sfx_vol_value: Label = $CenterContainer/SettingsPanel/Grid/SfxVolBox/SfxVolValue
@onready var fullscreen_check: CheckBox = $CenterContainer/SettingsPanel/Grid/FullscreenCheck
@onready var vsync_check: CheckBox = $CenterContainer/SettingsPanel/Grid/VsyncCheck
@onready var msaa_options: OptionButton = $CenterContainer/SettingsPanel/Grid/MsaaOptions
@onready var glow_check: CheckBox = $CenterContainer/SettingsPanel/Grid/GlowCheck
@onready var shadows_check: CheckBox = $CenterContainer/SettingsPanel/Grid/ShadowsCheck

var map_buttons: Dictionary = {}
var map_desc_label: Label = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_map_selector_in_difficulty_panel()
	show_main_menu()
	init_settings_values()

func _setup_map_selector_in_difficulty_panel() -> void:
	if not difficulty_panel:
		return
	difficulty_panel.custom_minimum_size = Vector2(560, 0)
	var sep_box := VBoxContainer.new()
	sep_box.name = "MapSelectorBox"
	sep_box.add_theme_constant_override("separation", 6)

	var hdr := Label.new()
	hdr.text = "ВЫБЕРИТЕ КАРТУ / БИОМ"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", Color(0.77, 0.65, 0.40))
	sep_box.add_child(hdr)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	sep_box.add_child(grid)

	map_buttons.clear()
	for mid in GlobalSettings.MAP_ORDER:
		var info: Dictionary = GlobalSettings.get_map_info(mid)
		var btn := Button.new()
		btn.name = "MapBtn_" + mid
		btn.text = "%s\n[%s]" % [str(info["short"]), str(info["tag"])]
		btn.custom_minimum_size = Vector2(106, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		var captured_id: String = mid
		btn.pressed.connect(func():
			if GlobalSettings:
				GlobalSettings.set_selected_map(captured_id)
			_refresh_map_selector_ui()
		)
		grid.add_child(btn)
		map_buttons[mid] = btn

	map_desc_label = Label.new()
	map_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_desc_label.add_theme_font_size_override("font_size", 12)
	map_desc_label.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
	sep_box.add_child(map_desc_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	sep_box.add_child(spacer)

	difficulty_panel.add_child(sep_box)
	difficulty_panel.move_child(sep_box, 0)
	_refresh_map_selector_ui()

func _refresh_map_selector_ui() -> void:
	var cur_id: String = GlobalSettings.selected_map_id if GlobalSettings else "forest"
	for mid in map_buttons.keys():
		var btn: Button = map_buttons[mid]
		var info: Dictionary = GlobalSettings.get_map_info(str(mid))
		var acc: Color = info.get("accent", Color(0.77, 0.65, 0.40))
		var selected: bool = (str(mid) == cur_id)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.16, 0.12, 0.98) if selected else Color(0.09, 0.10, 0.12, 0.92)
		sb.border_color = acc if selected else Color(0.30, 0.33, 0.38, 0.72)
		var bw: int = 2 if selected else 1
		sb.border_width_left = bw; sb.border_width_top = bw; sb.border_width_right = bw; sb.border_width_bottom = bw
		sb.content_margin_left = 4; sb.content_margin_right = 4; sb.content_margin_top = 4; sb.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86) if selected else Color(0.76, 0.78, 0.80))
	if map_desc_label and GlobalSettings:
		var ci: Dictionary = GlobalSettings.get_map_info(cur_id)
		map_desc_label.text = "%s — %s" % [str(ci["name"]), str(ci["desc"])]

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
	if master_vol_slider:
		master_vol_slider.set_value_no_signal(roundf(GlobalSettings.master_volume * 100.0))
	if master_vol_value:
		master_vol_value.text = "%d%%" % int(roundf(GlobalSettings.master_volume * 100.0))
	if weapons_vol_slider:
		weapons_vol_slider.set_value_no_signal(roundf(GlobalSettings.weapons_volume * 100.0))
	if weapons_vol_value:
		weapons_vol_value.text = "%d%%" % int(roundf(GlobalSettings.weapons_volume * 100.0))
	if sfx_vol_slider:
		sfx_vol_slider.set_value_no_signal(roundf(GlobalSettings.sfx_volume * 100.0))
	if sfx_vol_value:
		sfx_vol_value.text = "%d%%" % int(roundf(GlobalSettings.sfx_volume * 100.0))
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

# --- Audio Settings ---
func _on_master_volume_changed(value: float) -> void:
	if master_vol_value:
		master_vol_value.text = "%d%%" % int(roundf(value))
	if GlobalSettings:
		GlobalSettings.set_master_volume(value / 100.0)

func _on_weapons_volume_changed(value: float) -> void:
	if weapons_vol_value:
		weapons_vol_value.text = "%d%%" % int(roundf(value))
	if GlobalSettings:
		GlobalSettings.set_weapons_volume(value / 100.0)

func _on_sfx_volume_changed(value: float) -> void:
	if sfx_vol_value:
		sfx_vol_value.text = "%d%%" % int(roundf(value))
	if GlobalSettings:
		GlobalSettings.set_sfx_volume(value / 100.0)

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
