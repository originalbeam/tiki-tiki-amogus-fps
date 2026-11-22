class_name WorkbenchUI
extends Panel

# Escape from Tarkov style Weapon Modification Workbench UI
# Opened via [N] inside the Workbench interaction zone.
# - Screen 1: Owned Weapons List
# - Screen 2: Live 3D Dynamic Weapon Preview + EFT Square Mod Slots + Before/After Graphical Stat Bars
# Pressing [ESC] on Screen 2 returns to Screen 1; pressing [ESC] on Screen 1 closes the Workbench.

const HandbookPreviewScript = preload("res://scripts/handbook_preview.gd")
const WeaponModDBScript = preload("res://scripts/weapons/weapon_mod_db.gd")
const AK47ModelScript = preload("res://scripts/weapons/models/ak47_model.gd")

var hud_ref: Node = null
var slot_entries: Array[Dictionary] = [] # [{btn, slot_type, local_anchor, screen_offset}]

# Views
var list_view: VBoxContainer = null
var mod_view: VBoxContainer = null
var weapon_list_container: VBoxContainer = null

# Modding screen widgets
var mod_title_label: Label = null
var mod_preview: SubViewportContainer = null
var slot_overlay: Control = null
var mod_picker_panel: PanelContainer = null
var mod_picker_title: Label = null
var mod_picker_list: VBoxContainer = null
var mod_desc_label: Label = null
var stats_grid: GridContainer = null

var selected_weapon: Weapon = null
var active_slot_type: String = ""
var hovered_mod_id: String = "__NONE__"
var is_in_mod_view: bool = false

# Stat bar row references
var stat_rows: Dictionary = {} # key -> {label, base_bar, pos_bar, neg_bar}

func setup(hud: Node) -> void:
	hud_ref = hud
	name = "WorkbenchPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	set_anchors_preset(Control.PRESET_CENTER)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -510.0
	offset_top = -310.0
	offset_right = 510.0
	offset_bottom = 310.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 0.98), Color(0.76, 0.64, 0.38, 0.85), 1, 0))
	
	_build_list_view()
	_build_mod_view()
	show_weapon_list()

func _build_list_view() -> void:
	list_view = VBoxContainer.new()
	list_view.name = "WeaponListView"
	list_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_view.offset_left = 20
	list_view.offset_top = 16
	list_view.offset_right = -20
	list_view.offset_bottom = -16
	list_view.add_theme_constant_override("separation", 12)
	add_child(list_view)
	
	var header := HBoxContainer.new()
	list_view.add_child(header)
	
	var title := Label.new()
	title.text = "🔧 ВЕРСТАК МОДИФИКАЦИИ ОРУЖИЯ — ВЫБЕРИТЕ ОРУЖИЕ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.84, 0.72, 0.44))
	header.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ЗАКРЫТЬ (N / ESC)"
	close_btn.custom_minimum_size = Vector2(180, 36)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.13, 0.14, 0.16), Color(0.38, 0.42, 0.46), 1, 6))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_workbench"): hud_ref.close_workbench())
	header.add_child(close_btn)
	
	var sub := Label.new()
	sub.text = "Выберите оружие из вашего арсенала для установки и снятия модификаций (модификации доступны для АК-47; база готова для остальных стволов)."
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.62, 0.66, 0.70))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_view.add_child(sub)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_view.add_child(scroll)
	
	weapon_list_container = VBoxContainer.new()
	weapon_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(weapon_list_container)

func _build_mod_view() -> void:
	mod_view = VBoxContainer.new()
	mod_view.name = "ModdingView"
	mod_view.visible = false
	mod_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	mod_view.offset_left = 18
	mod_view.offset_top = 14
	mod_view.offset_right = -18
	mod_view.offset_bottom = -14
	mod_view.add_theme_constant_override("separation", 10)
	add_child(mod_view)
	
	# Top Navigation Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	mod_view.add_child(top_bar)
	
	var back_btn := Button.new()
	back_btn.text = "← К СПИСКУ ОРУЖИЯ (ESC)"
	back_btn.custom_minimum_size = Vector2(220, 34)
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.add_theme_stylebox_override("normal", _make_box(Color(0.15, 0.14, 0.11), Color(0.76, 0.64, 0.38), 1, 6))
	back_btn.pressed.connect(show_weapon_list)
	top_bar.add_child(back_btn)
	
	mod_title_label = Label.new()
	mod_title_label.text = "МОДИФИКАЦИЯ: AK-47"
	mod_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_title_label.add_theme_font_size_override("font_size", 17)
	mod_title_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.45))
	top_bar.add_child(mod_title_label)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ВЫЙТИ (N)"
	close_btn.custom_minimum_size = Vector2(120, 34)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.13, 0.14, 0.16), Color(0.38, 0.42, 0.46), 1, 6))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_workbench"): hud_ref.close_workbench())
	top_bar.add_child(close_btn)
	
	# UPPER HALF: 3D Dynamic Weapon Preview + EFT Square Slots Overlay + Mod Picker Popup
	var top_stage := PanelContainer.new()
	top_stage.custom_minimum_size = Vector2(0, 310)
	top_stage.add_theme_stylebox_override("panel", _make_box(Color(0.04, 0.05, 0.06, 0.98), Color(0.38, 0.34, 0.26, 0.8), 1, 0))
	mod_view.add_child(top_stage)
	
	var stage_layer := Control.new()
	stage_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_stage.add_child(stage_layer)
	
	# 3D SubViewportContainer using exact same HandbookPreviewScript!
	mod_preview = SubViewportContainer.new()
	mod_preview.name = "WorkbenchPreviewContainer"
	mod_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	mod_preview.stretch = true
	mod_preview.set_script(HandbookPreviewScript)
	
	var sv := SubViewport.new()
	sv.name = "SubViewport"
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.handle_input_locally = false
	sv.size = Vector2i(960, 310)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	mod_preview.add_child(sv)
	
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 0.03, 1.02)
	cam.fov = 45.0
	cam.current = true
	sv.add_child(cam)
	
	var dlight := DirectionalLight3D.new()
	dlight.position = Vector3(0, 2, 2)
	dlight.rotation_degrees = Vector3(-35, 30, 0)
	dlight.light_energy = 1.5
	sv.add_child(dlight)
	
	var olight := OmniLight3D.new()
	olight.position = Vector3(-1, -1, 1.5)
	olight.light_energy = 0.7
	olight.omni_range = 10.0
	sv.add_child(olight)
	
	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	sv.add_child(pivot)
	
	stage_layer.add_child(mod_preview)
	
	# EFT Square Mod Slots Overlay (mouse_filter = IGNORE so 3D rotation works everywhere around slots!)
	slot_overlay = Control.new()
	slot_overlay.name = "SlotOverlay"
	slot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(slot_overlay)
	
	# EFT Mod Picker Panel (anchored right side of 3D stage when a square slot is clicked)
	mod_picker_panel = PanelContainer.new()
	mod_picker_panel.name = "ModPickerPanel"
	mod_picker_panel.visible = false
	mod_picker_panel.anchor_left = 1.0
	mod_picker_panel.anchor_right = 1.0
	mod_picker_panel.anchor_top = 0.0
	mod_picker_panel.anchor_bottom = 1.0
	mod_picker_panel.offset_left = -310.0
	mod_picker_panel.offset_right = -8.0
	mod_picker_panel.offset_top = 8.0
	mod_picker_panel.offset_bottom = -28.0
	mod_picker_panel.add_theme_stylebox_override("panel", _make_box(Color(0.07, 0.08, 0.10, 0.96), Color(0.82, 0.68, 0.38, 0.9), 1, 10))
	stage_layer.add_child(mod_picker_panel)
	
	var pk_vbox := VBoxContainer.new()
	pk_vbox.add_theme_constant_override("separation", 6)
	mod_picker_panel.add_child(pk_vbox)
	
	var pk_hdr := HBoxContainer.new()
	pk_vbox.add_child(pk_hdr)
	mod_picker_title = Label.new()
	mod_picker_title.text = "СЛОТ: ПРИЦЕЛ"
	mod_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_picker_title.add_theme_font_size_override("font_size", 13)
	mod_picker_title.add_theme_color_override("font_color", Color(0.86, 0.74, 0.44))
	pk_hdr.add_child(mod_picker_title)
	
	var pk_close := Button.new()
	pk_close.text = "✕"
	pk_close.custom_minimum_size = Vector2(26, 24)
	pk_close.pressed.connect(func():
		mod_picker_panel.visible = false
		active_slot_type = ""
		hovered_mod_id = "__NONE__"
		_refresh_stats()
	)
	pk_hdr.add_child(pk_close)
	
	var pk_scroll := ScrollContainer.new()
	pk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pk_vbox.add_child(pk_scroll)
	
	mod_picker_list = VBoxContainer.new()
	mod_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_picker_list.add_theme_constant_override("separation", 6)
	pk_scroll.add_child(mod_picker_list)
	
	mod_desc_label = Label.new()
	mod_desc_label.text = "Наведите на модуль для сравнения характеристик До / После."
	mod_desc_label.add_theme_font_size_override("font_size", 11)
	mod_desc_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76))
	mod_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pk_vbox.add_child(mod_desc_label)
	
	# Bottom hint on 3D viewport
	var hint := Label.new()
	hint.text = "  🖱 ЛКМ: Вращение 360°  |  ПКМ: Смещение  |  Колесико: Зум  |  Нажмите на квадратный слот для модификации"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.anchor_right = 1.0
	hint.offset_top = -22.0
	hint.offset_bottom = -2.0
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.62, 0.66, 0.70, 0.85))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(hint)
	
	# LOWER HALF: Graphical Before / After Stats Panel
	var stats_panel := PanelContainer.new()
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.09, 0.11, 0.96), Color(0.26, 0.28, 0.32), 1, 12))
	mod_view.add_child(stats_panel)
	
	var st_vbox := VBoxContainer.new()
	st_vbox.add_theme_constant_override("separation", 6)
	stats_panel.add_child(st_vbox)
	
	var st_hdr := Label.new()
	st_hdr.text = "── ХАРАКТЕРИСТИКИ ОРУЖИЯ (ДО / ПОСЛЕ МОДИФИКАЦИИ) ──"
	st_hdr.add_theme_font_size_override("font_size", 13)
	st_hdr.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	st_vbox.add_child(st_hdr)
	
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 8)
	st_vbox.add_child(stats_grid)
	
	var stat_keys := ["damage", "accuracy", "recoil_control", "ergonomics", "rpm", "zoom"]
	for sk in stat_keys:
		stat_rows[sk] = _create_comparison_bar(stats_grid)

func _create_comparison_bar(parent: Control) -> Dictionary:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)
	
	var lbl := Label.new()
	lbl.text = "Характеристика"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.86, 0.88, 0.90))
	box.add_child(lbl)
	
	# Layered visual bar: dark BG + base value fill + green positive delta / red negative delta
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 10)
	bar_bg.color = Color(0.14, 0.15, 0.17, 1.0)
	box.add_child(bar_bg)
	
	var base_fill := ColorRect.new()
	base_fill.anchor_top = 0.0
	base_fill.anchor_bottom = 1.0
	base_fill.color = Color(0.72, 0.62, 0.38, 1.0) # EFT gold-amber base bar
	bar_bg.add_child(base_fill)
	
	var pos_fill := ColorRect.new()
	pos_fill.anchor_top = 0.0
	pos_fill.anchor_bottom = 1.0
	pos_fill.color = Color(0.28, 0.78, 0.36, 1.0) # Bright green improvement delta
	bar_bg.add_child(pos_fill)
	
	var neg_fill := ColorRect.new()
	neg_fill.anchor_top = 0.0
	neg_fill.anchor_bottom = 1.0
	neg_fill.color = Color(0.82, 0.24, 0.22, 1.0) # Crimson negative delta
	bar_bg.add_child(neg_fill)
	
	return {
		"label": lbl,
		"base_fill": base_fill,
		"pos_fill": pos_fill,
		"neg_fill": neg_fill
	}

func _update_bar(key: String, title: String, cur_val: float, new_val: float, max_val: float, suffix: String = "", higher_is_better: bool = true) -> void:
	if not stat_rows.has(key):
		return
	var row: Dictionary = stat_rows[key]
	var lbl: Label = row["label"]
	var base_fill: ColorRect = row["base_fill"]
	var pos_fill: ColorRect = row["pos_fill"]
	var neg_fill: ColorRect = row["neg_fill"]
	
	var diff := new_val - cur_val
	var has_diff := absf(diff) > 0.01
	
	if has_diff:
		var sign_str := "+" if diff > 0.0 else ""
		lbl.text = "%s: %.1f%s  →  %.1f%s (%s%.1f)" % [title, cur_val, suffix, new_val, suffix, sign_str, diff]
		var improved := (diff > 0.0) if higher_is_better else (diff < 0.0)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.90, 0.50) if improved else Color(0.92, 0.42, 0.38))
	else:
		lbl.text = "%s: %.1f%s" % [title, cur_val, suffix]
		lbl.add_theme_color_override("font_color", Color(0.86, 0.88, 0.90))
		
	var cur_norm := clampf(cur_val / maxf(0.01, max_val), 0.0, 1.0)
	var new_norm := clampf(new_val / maxf(0.01, max_val), 0.0, 1.0)
	
	if not has_diff:
		base_fill.anchor_left = 0.0
		base_fill.anchor_right = cur_norm
		pos_fill.visible = false
		neg_fill.visible = false
	elif new_norm >= cur_norm:
		base_fill.anchor_left = 0.0
		base_fill.anchor_right = cur_norm
		pos_fill.visible = true
		pos_fill.anchor_left = cur_norm
		pos_fill.anchor_right = new_norm
		neg_fill.visible = false
	else:
		base_fill.anchor_left = 0.0
		base_fill.anchor_right = new_norm
		pos_fill.visible = false
		neg_fill.visible = true
		neg_fill.anchor_left = new_norm
		neg_fill.anchor_right = cur_norm

func open_workbench() -> void:
	visible = true
	show_weapon_list()

func show_weapon_list() -> void:
	is_in_mod_view = false
	selected_weapon = null
	active_slot_type = ""
	hovered_mod_id = "__NONE__"
	list_view.visible = true
	mod_view.visible = false
	mod_picker_panel.visible = false
	_populate_weapon_list()

func _populate_weapon_list() -> void:
	for c in weapon_list_container.get_children():
		c.queue_free()
	if not hud_ref:
		return
	var player = hud_ref.get_parent()
	if not player or not player.weapon_manager:
		return
		
	for w in player.weapon_manager.weapons:
		var slot_defs: Array[Dictionary] = WeaponModDBScript.get_slot_defs(w.weapon_id)
		var card := PanelContainer.new()
		var has_mods_support := slot_defs.size() > 0
		var brd := Color(0.76, 0.64, 0.38, 0.85) if has_mods_support else Color(0.26, 0.28, 0.32)
		card.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.11, 0.13), brd, 1, 12))
		weapon_list_container.add_child(card)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		
		var name_lbl := Label.new()
		var eq_tag := "  [СЛОТ %d]" % w.slot if w.slot > 0 else "  [В РЮКЗАКЕ]"
		name_lbl.text = "%s%s" % [w.name.to_upper(), eq_tag]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
		info.add_child(name_lbl)
		
		var detail := Label.new()
		if has_mods_support:
			detail.text = "Доступно слотов модификации: %d  |  Установлено модов: %d  |  Урон: %d" % [slot_defs.size(), w.get_installed_mod_count(), int(w.damage)]
			detail.add_theme_color_override("font_color", Color(0.55, 0.82, 0.52))
		else:
			detail.text = "Слоты модификаций появятся в следующих обновлениях  |  Осмотр 3D модели доступен"
			detail.add_theme_color_override("font_color", Color(0.58, 0.62, 0.66))
		detail.add_theme_font_size_override("font_size", 12)
		info.add_child(detail)
		
		var open_btn := Button.new()
		open_btn.text = "🔧 МОДИФИЦИРОВАТЬ" if has_mods_support else "🔍 ОСМОТРЕТЬ"
		open_btn.custom_minimum_size = Vector2(180, 38)
		open_btn.add_theme_font_size_override("font_size", 13)
		open_btn.add_theme_stylebox_override("normal", _make_box(Color(0.18, 0.16, 0.11) if has_mods_support else Color(0.13, 0.14, 0.16), brd, 1, 6))
		var w_ref: Weapon = w
		open_btn.pressed.connect(func(): open_weapon_modding(w_ref))
		row.add_child(open_btn)

func open_weapon_modding(w: Weapon) -> void:
	selected_weapon = w
	is_in_mod_view = true
	active_slot_type = ""
	hovered_mod_id = "__NONE__"
	list_view.visible = false
	mod_view.visible = true
	mod_picker_panel.visible = false
	
	mod_title_label.text = "МОДИФИКАЦИЯ: %s" % w.name.to_upper()
	if mod_preview and mod_preview.has_method("show_weapon_with_mods"):
		mod_preview.show_weapon_with_mods(w, false)
	_rebuild_eft_slots()
	_refresh_stats()

# Handles ESC layered navigation: Screen 2 -> Screen 1 -> Close Workbench
func handle_escape() -> bool:
	if not visible:
		return false
	if is_in_mod_view:
		if mod_picker_panel.visible:
			mod_picker_panel.visible = false
			active_slot_type = ""
			hovered_mod_id = "__NONE__"
			_refresh_stats()
		else:
			show_weapon_list()
		return true
	else:
		if hud_ref and hud_ref.has_method("close_workbench"):
			hud_ref.close_workbench()
		return true

func _process(_delta: float) -> void:
	if not visible or not is_in_mod_view or not selected_weapon or not mod_preview or not slot_overlay:
		return
	if slot_entries.is_empty():
		return
	var stage_sz: Vector2 = slot_overlay.size
	if stage_sz.x < 10.0 or stage_sz.y < 10.0:
		return
	for entry in slot_entries:
		var btn: Control = entry["btn"]
		if not is_instance_valid(btn):
			continue
		var proj: Vector2 = mod_preview.get_projected_slot_pos(entry["local_anchor"]) + entry["screen_offset"]
		var half: Vector2 = btn.size * 0.5
		var clamped := Vector2(
			clampf(proj.x - half.x, 8.0, stage_sz.x - btn.size.x - 8.0),
			clampf(proj.y - half.y, 8.0, stage_sz.y - btn.size.y - 26.0)
		)
		btn.position = clamped

func _rebuild_eft_slots() -> void:
	for c in slot_overlay.get_children():
		slot_overlay.remove_child(c)
		c.queue_free()
	slot_entries.clear()
	if not selected_weapon:
		return
		
	var slot_defs: Array[Dictionary] = WeaponModDBScript.get_slot_defs(selected_weapon.weapon_id)
	if slot_defs.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Для этого оружия пока нет модификаций (скелет готов к расширению)."
		empty_lbl.position = Vector2(20, 16)
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.68, 0.70, 0.74))
		slot_overlay.add_child(empty_lbl)
		return
		
	const SLOT_SIZE := 74.0
	for sd in slot_defs:
		var st: String = sd["slot_type"]
		# Item 6: If a slot requires another mod that isn't installed, hide the slot completely!
		var unlocked: bool = WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, sd)
		if not unlocked:
			continue
			
		var installed_id: String = str(selected_weapon.installed_mods.get(st, ""))
		var installed_mod = WeaponModDBScript.get_mod(installed_id)
		
		# Item 5: Clean square EFT slot (no top header text), dynamically positioned from 3D weapon anchor!
		var slot_btn := Button.new()
		slot_btn.name = "SlotBtn_" + st
		slot_btn.text = ""
		slot_btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		
		var bg_col := Color(0.08, 0.09, 0.11, 0.86)
		var brd_col := Color(0.88, 0.74, 0.40, 0.98) if (active_slot_type == st) else Color(0.46, 0.49, 0.54, 0.88)
		if installed_mod and not installed_mod.is_vanilla_default:
			brd_col = Color(0.84, 0.72, 0.42, 0.96) if active_slot_type == st else Color(0.56, 0.76, 0.46, 0.92)
		slot_btn.add_theme_stylebox_override("normal", _make_box(bg_col, brd_col, 2, 0))
		slot_btn.add_theme_stylebox_override("hover", _make_box(Color(0.14, 0.15, 0.18, 0.94), Color(0.96, 0.82, 0.44, 1.0), 2, 0))
		slot_btn.add_theme_stylebox_override("pressed", _make_box(Color(0.18, 0.16, 0.12, 0.96), Color(0.98, 0.85, 0.48, 1.0), 2, 0))
		
		if installed_mod:
			# Render 3D miniature of the installed modification centered inside the square slot!
			var thumb_box := _create_mod_slot_3d_icon(installed_id)
			slot_btn.add_child(thumb_box)
			
			# Tiny mini-name caption along the bottom of the square slot
			var mini_lbl := Label.new()
			mini_lbl.text = installed_mod.short_name
			mini_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mini_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			mini_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			mini_lbl.offset_left = 2.0
			mini_lbl.offset_right = -2.0
			mini_lbl.offset_top = -15.0
			mini_lbl.offset_bottom = -2.0
			mini_lbl.clip_text = true
			mini_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_lbl.add_theme_font_size_override("font_size", 9)
			mini_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
			mini_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
			mini_lbl.add_theme_constant_override("outline_size", 2)
			slot_btn.add_child(mini_lbl)
		
		var sd_copy: Dictionary = sd
		slot_btn.pressed.connect(func(): _open_slot_picker(sd_copy))
		slot_overlay.add_child(slot_btn)
		
		var local_anchor: Vector3 = AK47ModelScript.get_slot_anchor_local(selected_weapon.weapon_id, st)
		# Small vertical offset so optic & dust_cover squares never overlap each other
		var screen_off := Vector2(0.0, -48.0) if st == "optic" else Vector2(0.0, 22.0)
		slot_entries.append({
			"btn": slot_btn,
			"slot_type": st,
			"local_anchor": local_anchor,
			"screen_offset": screen_off
		})
	
	# Immediately place slots on current frame
	_process(0.0)

func _create_mod_slot_3d_icon(mod_id: String) -> SubViewportContainer:
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.offset_left = 4.0
	svc.offset_right = -4.0
	svc.offset_top = 3.0
	svc.offset_bottom = -14.0
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.size = Vector2i(96, 80)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	svc.add_child(sv)
	
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.84, 0.88)
	env.ambient_light_energy = 1.4
	we.environment = env
	sv.add_child(we)
	
	var dlight := DirectionalLight3D.new()
	dlight.position = Vector3(1, 2, 2)
	dlight.rotation_degrees = Vector3(-35, 30, 0)
	dlight.light_energy = 1.3
	sv.add_child(dlight)
	
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.02, 1.35)
	cam.fov = 38.0
	cam.current = true
	sv.add_child(cam)
	
	var mod_mesh := AK47ModelScript.create_mod_preview(mod_id)
	sv.add_child(mod_mesh)
	return svc

func _open_slot_picker(slot_def: Dictionary) -> void:
	if not selected_weapon:
		return
	var st: String = slot_def["slot_type"]
	active_slot_type = st
	hovered_mod_id = "__NONE__"
	mod_picker_panel.visible = true
	mod_picker_title.text = "СЛОТ: %s" % slot_def["label"]
	_rebuild_eft_slots()
	
	for c in mod_picker_list.get_children():
		c.queue_free()
		
	var unlocked: bool = WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, slot_def)
	if not unlocked:
		mod_picker_panel.visible = false
		return
		
	var current_id: String = str(selected_weapon.installed_mods.get(st, ""))
	
	# Option to strip/remove mod (e.g. AK-47 without dust cover!)
	if slot_def.get("can_remove", true):
		_add_picker_option(st, "", "Снять / Пусто", "Оставить слот пустым. Для крышки СК АК-47 оружие продолжит стрелять с открытой затворной группой.", current_id == "", false)
		
	var mods: Array = WeaponModDBScript.get_mods_for_slot(selected_weapon.weapon_id, st)
	for m in mods:
		# Item 7: Purchased / vanilla mods have no price shown and get a warm beige tint!
		var is_owned: bool = selected_weapon.is_mod_owned(m.id)
		var label_txt: String = m.name if is_owned else ("%s ($%d)" % [m.name, m.price])
		_add_picker_option(st, m.id, label_txt, m.description, current_id == m.id, is_owned)

func _add_picker_option(slot_type: String, mod_id: String, label_text: String, desc_text: String, is_installed: bool, is_owned: bool) -> void:
	var btn := Button.new()
	btn.text = ("✓ " if is_installed else "  ") + label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 12)
	
	# Item 7: Warm beige shade for purchased/vanilla mods!
	var bg: Color
	var brd: Color
	if is_owned:
		bg = Color(0.36, 0.31, 0.22, 0.96) if is_installed else Color(0.28, 0.24, 0.18, 0.94)
		brd = Color(0.92, 0.80, 0.48, 1.0) if is_installed else Color(0.74, 0.64, 0.45, 0.92)
		btn.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	else:
		bg = Color(0.18, 0.22, 0.14) if is_installed else Color(0.11, 0.12, 0.14)
		brd = Color(0.48, 0.80, 0.44) if is_installed else Color(0.30, 0.33, 0.38)
	btn.add_theme_stylebox_override("normal", _make_box(bg, brd, 1, 6))
	btn.add_theme_stylebox_override("hover", _make_box(Color(0.42, 0.36, 0.25, 0.98) if is_owned else Color(0.20, 0.18, 0.12), Color(0.96, 0.84, 0.50), 1, 6))
	
	btn.mouse_entered.connect(func():
		hovered_mod_id = mod_id
		mod_desc_label.text = desc_text
		_refresh_stats()
	)
	btn.mouse_exited.connect(func():
		hovered_mod_id = "__NONE__"
		_refresh_stats()
	)
	btn.pressed.connect(func():
		_apply_mod_selection(slot_type, mod_id)
	)
	mod_picker_list.add_child(btn)

func _apply_mod_selection(slot_type: String, mod_id: String) -> void:
	if not selected_weapon:
		return
		
	# Handle purchase if not yet owned (supports $0 and future paid mods!)
	if mod_id != "" and not selected_weapon.is_mod_owned(mod_id):
		var m = WeaponModDBScript.get_mod(mod_id)
		if m and m.price > 0:
			var player = hud_ref.get_parent() if hud_ref else null
			if player and player.has_method("spend_money"):
				if not player.spend_money(m.price):
					mod_desc_label.text = "⚠ Недостаточно средств ($%d)" % m.price
					return
		selected_weapon.mark_mod_owned(mod_id)
		
	var res: Dictionary = selected_weapon.install_mod(slot_type, mod_id)
	if not res.get("ok", false):
		mod_desc_label.text = "⚠ " + str(res.get("reason", "Невозможно установить"))
		return
		
	# Live-update 3D preview model preserving user's camera angle!
	if mod_preview and mod_preview.has_method("show_weapon_with_mods"):
		mod_preview.show_weapon_with_mods(selected_weapon, true)
		
	# Live-update first-person held weapon & HUD!
	if hud_ref:
		var player = hud_ref.get_parent()
		if player and player.weapon_manager:
			player.weapon_manager.refresh_active_weapon_mods()
		if hud_ref.has_method("play_buy_sfx"):
			hud_ref.play_buy_sfx()
			
	hovered_mod_id = "__NONE__"
	_rebuild_eft_slots()
	# Reopen current slot picker cleanly to reflect purchased beige state & checkmark
	for sd in WeaponModDBScript.get_slot_defs(selected_weapon.weapon_id):
		if sd["slot_type"] == slot_type:
			if WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, sd):
				_open_slot_picker(sd)
			else:
				mod_picker_panel.visible = false
				active_slot_type = ""
			break
	_refresh_stats()

func _refresh_stats() -> void:
	if not selected_weapon:
		return
	var cur_st := selected_weapon.compute_stats_for_mods(selected_weapon.installed_mods)
	var new_st := cur_st
	if active_slot_type != "" and hovered_mod_id != "__NONE__":
		var preview_mods := selected_weapon.installed_mods.duplicate(true)
		preview_mods[active_slot_type] = hovered_mod_id
		WeaponModDBScript.cleanup_invalid_mods(preview_mods)
		new_st = selected_weapon.compute_stats_for_mods(preview_mods)
		
	_update_bar("damage", "Урон", cur_st["damage"], new_st["damage"], 320.0, " ед.", true)
	_update_bar("accuracy", "Точность", cur_st["accuracy"], new_st["accuracy"], 100.0, "%", true)
	_update_bar("recoil_control", "Контроль отдачи", cur_st["recoil_control"], new_st["recoil_control"], 100.0, "%", true)
	_update_bar("ergonomics", "Эргономика", cur_st["ergonomics"], new_st["ergonomics"], 100.0, "", true)
	_update_bar("rpm", "Темп стрельбы", cur_st["rpm"], new_st["rpm"], 900.0, " в/м", true)
	_update_bar("zoom", "Макс. приближение", cur_st["zoom_max"], new_st["zoom_max"], 4.0, "x", true)

static func _make_box(bg: Color, border: Color, bw: int = 1, pad: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb
