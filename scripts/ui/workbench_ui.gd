class_name WorkbenchUI
extends Panel

# Escape from Tarkov style Gunsmith / Weapon Modification Workbench UI
# Opened via [N] inside the Workbench interaction zone.
# - Huge 3D Interactive Weapon Preview (~76% height)
# - Compact 44x44 EFT Square Slots connected by dynamic 3D-to-2D leader lines!
# - Floating EFT 3D-Icon Tile Grid Popover (no vertical text lists!)
# - Ultra-compact Before/After Graphical Stat Bars at bottom
# Pressing [ESC] closes popover -> Screen 1 -> Close Workbench.

const HandbookPreviewScript = preload("res://scripts/handbook_preview.gd")
const WeaponModDBScript = preload("res://scripts/weapons/weapon_mod_db.gd")
const WeaponModVisualsScript = preload("res://scripts/weapons/models/weapon_mod_visuals.gd")

class SlotConnectorLayer extends Control:
	var lines_data: Array[Dictionary] = []

	func set_lines(data: Array[Dictionary]) -> void:
		lines_data = data
		queue_redraw()

	func _draw() -> void:
		for item in lines_data:
			var anchor: Vector2 = item["anchor"]
			var scenter: Vector2 = item["slot_center"]
			var ssize: Vector2 = item["slot_size"]
			var is_active: bool = item["active"]
			var is_modded: bool = item["modded"]

			var line_col: Color = Color(0.96, 0.80, 0.36, 0.96) if is_active else (Color(0.68, 0.84, 0.52, 0.78) if is_modded else Color(0.76, 0.72, 0.58, 0.62))
			var width: float = 2.0 if is_active else 1.25

			# Find nearest edge point on the slot square toward the 3D anchor
			var half: Vector2 = ssize * 0.5
			var diff: Vector2 = anchor - scenter
			var edge_pt: Vector2 = scenter
			if absf(diff.x) > 0.01 or absf(diff.y) > 0.01:
				var sx: float = half.x / maxf(0.001, absf(diff.x))
				var sy: float = half.y / maxf(0.001, absf(diff.y))
				edge_pt = scenter + diff * minf(sx, sy)

			# EFT bent leader polyline: anchor -> elbow -> slot edge
			var elbow := Vector2(edge_pt.x, lerpf(anchor.y, edge_pt.y, 0.45))
			if absf(anchor.x - edge_pt.x) > absf(anchor.y - edge_pt.y):
				elbow = Vector2(lerpf(anchor.x, edge_pt.x, 0.45), edge_pt.y)

			draw_line(anchor, elbow, Color(0.0, 0.0, 0.0, 0.55), width + 1.6, true)
			draw_line(elbow, edge_pt, Color(0.0, 0.0, 0.0, 0.55), width + 1.6, true)
			draw_line(anchor, elbow, line_col, width, true)
			draw_line(elbow, edge_pt, line_col, width, true)

			# Crisp EFT attachment point dot on the 3D weapon surface
			draw_circle(anchor, 4.0 if is_active else 3.2, Color(0.02, 0.02, 0.03, 0.92))
			draw_circle(anchor, 2.5 if is_active else 2.0, line_col)

var hud_ref: Node = null
var slot_entries: Array[Dictionary] = [] # [{btn, slot_type, local_anchor, screen_offset, modded}]

# Views
var list_view: VBoxContainer = null
var mod_view: VBoxContainer = null
var weapon_list_container: VBoxContainer = null

# Modding screen widgets
var mod_title_label: Label = null
var mod_preview: SubViewportContainer = null
var connector_layer: SlotConnectorLayer = null
var slot_overlay: Control = null
var mod_tile_popover: PanelContainer = null
var mod_popover_title: Label = null
var mod_tile_grid: GridContainer = null
var mod_desc_label: Label = null
var stats_grid: GridContainer = null

var selected_weapon: Weapon = null
var active_slot_type: String = ""
var hovered_mod_id: String = "__NONE__"
var is_in_mod_view: bool = false

var stat_rows: Dictionary = {} # key -> {label, base_fill, pos_fill, neg_fill}

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
	offset_left = -565.0
	offset_top = -335.0
	offset_right = 565.0
	offset_bottom = 335.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 1.0), Color(0.76, 0.64, 0.38, 0.85), 1, 0))
	
	_build_list_view()
	_build_mod_view()
	show_weapon_list()

func _build_list_view() -> void:
	list_view = VBoxContainer.new()
	list_view.name = "WeaponListView"
	list_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_view.offset_left = 18
	list_view.offset_top = 14
	list_view.offset_right = -18
	list_view.offset_bottom = -14
	list_view.add_theme_constant_override("separation", 10)
	add_child(list_view)
	
	var header := HBoxContainer.new()
	list_view.add_child(header)
	
	var title := Label.new()
	title.text = "🔧 ВЕРСТАК МОДИФИКАЦИИ ОРУЖИЯ — ВЫБЕРИТЕ СТВОЛ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.84, 0.72, 0.44))
	header.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ЗАКРЫТЬ (N / ESC)"
	close_btn.custom_minimum_size = Vector2(180, 34)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.13, 0.14, 0.16), Color(0.38, 0.42, 0.46), 1, 6))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_workbench"): hud_ref.close_workbench())
	header.add_child(close_btn)
	
	var sub := Label.new()
	sub.text = "Все 10 видов оружия поддерживают глубокий тюнинг: прицелы (ПНВ / Тепловизор), магазины, цевья, подствольники, ЛЦУ, фонари, трубы и приклады, УСМ, глушители и патроны."
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.62, 0.66, 0.70))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_view.add_child(sub)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_view.add_child(scroll)
	
	weapon_list_container = VBoxContainer.new()
	weapon_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(weapon_list_container)

func _build_mod_view() -> void:
	mod_view = VBoxContainer.new()
	mod_view.name = "ModdingView"
	mod_view.visible = false
	mod_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	mod_view.offset_left = 14
	mod_view.offset_top = 10
	mod_view.offset_right = -14
	mod_view.offset_bottom = -10
	mod_view.add_theme_constant_override("separation", 6)
	add_child(mod_view)
	
	# Compact Top Navigation Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 10)
	mod_view.add_child(top_bar)
	
	var back_btn := Button.new()
	back_btn.text = "← К СПИСКУ (ESC)"
	back_btn.custom_minimum_size = Vector2(165, 28)
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.add_theme_stylebox_override("normal", _make_box(Color(0.15, 0.14, 0.11), Color(0.76, 0.64, 0.38), 1, 4))
	back_btn.pressed.connect(show_weapon_list)
	top_bar.add_child(back_btn)
	
	mod_title_label = Label.new()
	mod_title_label.text = "МОДИФИКАЦИЯ: AK-47"
	mod_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_title_label.add_theme_font_size_override("font_size", 15)
	mod_title_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.45))
	top_bar.add_child(mod_title_label)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ВЫЙТИ (N)"
	close_btn.custom_minimum_size = Vector2(110, 28)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.13, 0.14, 0.16), Color(0.38, 0.42, 0.46), 1, 4))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_workbench"): hud_ref.close_workbench())
	top_bar.add_child(close_btn)
	
	# HUGE 3D WEAPON STAGE (~77% of window height!) + EFT Leader Lines + Compact 44x44 Slots + Floating Tile Grid Popover
	var top_stage := PanelContainer.new()
	top_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_stage.custom_minimum_size = Vector2(0, 490)
	top_stage.add_theme_stylebox_override("panel", _make_box(Color(0.04, 0.05, 0.06, 0.98), Color(0.38, 0.34, 0.26, 0.8), 1, 0))
	mod_view.add_child(top_stage)
	
	var stage_layer := Control.new()
	stage_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_stage.add_child(stage_layer)
	
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
	sv.size = Vector2i(1090, 490)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	mod_preview.add_child(sv)
	
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 0.03, 0.96)
	cam.fov = 45.0
	cam.current = true
	sv.add_child(cam)
	
	var dlight := DirectionalLight3D.new()
	dlight.position = Vector3(0, 2, 2)
	dlight.rotation_degrees = Vector3(-35, 30, 0)
	dlight.light_energy = 1.55
	sv.add_child(dlight)
	
	var olight := OmniLight3D.new()
	olight.position = Vector3(-1, -1, 1.5)
	olight.light_energy = 0.75
	olight.omni_range = 10.0
	sv.add_child(olight)
	
	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	sv.add_child(pivot)
	stage_layer.add_child(mod_preview)

	# EFT Leader Lines Canvas connecting each slot square directly to its 3D point on the weapon!
	connector_layer = SlotConnectorLayer.new()
	connector_layer.name = "SlotConnectorLayer"
	connector_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	connector_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(connector_layer)
	
	# Compact 44x44 EFT Square Mod Slots Overlay
	slot_overlay = Control.new()
	slot_overlay.name = "SlotOverlay"
	slot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(slot_overlay)
	
	# Floating EFT 3D-Icon Tile Grid Popover (replaces vertical text lists completely!)
	mod_tile_popover = PanelContainer.new()
	mod_tile_popover.name = "ModTilePopover"
	mod_tile_popover.visible = false
	mod_tile_popover.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.09, 0.96), Color(0.86, 0.72, 0.38, 0.95), 1, 6))
	stage_layer.add_child(mod_tile_popover)

	var pop_vbox := VBoxContainer.new()
	pop_vbox.add_theme_constant_override("separation", 5)
	mod_tile_popover.add_child(pop_vbox)

	var pop_hdr := HBoxContainer.new()
	pop_vbox.add_child(pop_hdr)
	mod_popover_title = Label.new()
	mod_popover_title.text = "ПРИЦЕЛ"
	mod_popover_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_popover_title.add_theme_font_size_override("font_size", 11)
	mod_popover_title.add_theme_color_override("font_color", Color(0.88, 0.75, 0.44))
	pop_hdr.add_child(mod_popover_title)

	var pop_close := Button.new()
	pop_close.text = "✕"
	pop_close.custom_minimum_size = Vector2(22, 20)
	pop_close.add_theme_font_size_override("font_size", 10)
	pop_close.pressed.connect(func():
		mod_tile_popover.visible = false
		active_slot_type = ""
		hovered_mod_id = "__NONE__"
		_rebuild_eft_slots()
		_refresh_stats()
	)
	pop_hdr.add_child(pop_close)

	mod_tile_grid = GridContainer.new()
	mod_tile_grid.columns = 5
	mod_tile_grid.add_theme_constant_override("h_separation", 4)
	mod_tile_grid.add_theme_constant_override("v_separation", 4)
	pop_vbox.add_child(mod_tile_grid)

	# Bottom hint inside 3D stage
	var hint := Label.new()
	hint.text = "  🖱 ЛКМ: Вращение 360°  |  ПКМ: Смещение  |  Колёсико: Зум  |  Клик по слоту — выбор 3D-плиток"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.anchor_right = 1.0
	hint.offset_top = -18.0
	hint.offset_bottom = -2.0
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.60, 0.64, 0.68, 0.85))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(hint)
	
	# ULTRA-COMPACT BOTTOM STATS STRIP (4 columns x 2 slim rows + 1-line hovered mod info!)
	var stats_panel := PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(0, 96)
	stats_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.09, 0.11, 0.96), Color(0.26, 0.28, 0.32), 1, 7))
	mod_view.add_child(stats_panel)
	
	var st_vbox := VBoxContainer.new()
	st_vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(st_vbox)

	mod_desc_label = Label.new()
	mod_desc_label.text = "Нажмите на любой слот и наведите на плитку модуля для сравнения характеристик До / После."
	mod_desc_label.add_theme_font_size_override("font_size", 11)
	mod_desc_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.62))
	mod_desc_label.clip_text = true
	st_vbox.add_child(mod_desc_label)
	
	stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 4)
	st_vbox.add_child(stats_grid)
	
	var stat_keys := ["damage", "spread", "recoil_pitch", "recoil_yaw", "ergonomics", "rpm", "mag_size", "armor_pen"]
	for sk in stat_keys:
		stat_rows[sk] = _create_comparison_bar(stats_grid)

func _create_comparison_bar(parent: Control) -> Dictionary:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	
	var lbl := Label.new()
	lbl.text = "Характеристика"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88))
	lbl.clip_text = true
	box.add_child(lbl)
	
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 6)
	bar_bg.color = Color(0.14, 0.15, 0.17, 1.0)
	box.add_child(bar_bg)
	
	var base_fill := ColorRect.new()
	base_fill.anchor_top = 0.0
	base_fill.anchor_bottom = 1.0
	base_fill.color = Color(0.72, 0.62, 0.38, 1.0)
	bar_bg.add_child(base_fill)
	
	var pos_fill := ColorRect.new()
	pos_fill.anchor_top = 0.0
	pos_fill.anchor_bottom = 1.0
	pos_fill.color = Color(0.28, 0.78, 0.36, 1.0)
	bar_bg.add_child(pos_fill)
	
	var neg_fill := ColorRect.new()
	neg_fill.anchor_top = 0.0
	neg_fill.anchor_bottom = 1.0
	neg_fill.color = Color(0.82, 0.24, 0.22, 1.0)
	bar_bg.add_child(neg_fill)
	
	return {"label": lbl, "base_fill": base_fill, "pos_fill": pos_fill, "neg_fill": neg_fill}

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
	var use_dec := (suffix == "x" or suffix == "°")
	var improved := (diff > 0.0) if higher_is_better else (diff < 0.0)
	if has_diff:
		var sign_str := "+" if diff > 0.0 else ""
		if use_dec:
			lbl.text = "%s: %.2f%s → %.2f%s (%s%.2f)" % [title, cur_val, suffix, new_val, suffix, sign_str, diff]
		else:
			lbl.text = "%s: %.0f%s → %.0f%s (%s%.1f)" % [title, cur_val, suffix, new_val, suffix, sign_str, diff]
		lbl.add_theme_color_override("font_color", Color(0.45, 0.90, 0.50) if improved else Color(0.92, 0.42, 0.38))
	else:
		lbl.text = "%s: %.2f%s" % [title, cur_val, suffix] if use_dec else "%s: %.0f%s" % [title, cur_val, suffix]
		lbl.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88))
		
	var cur_norm := clampf(cur_val / maxf(0.01, max_val), 0.0, 1.0)
	var new_norm := clampf(new_val / maxf(0.01, max_val), 0.0, 1.0)
	if not has_diff:
		base_fill.anchor_left = 0.0
		base_fill.anchor_right = cur_norm
		pos_fill.visible = false
		neg_fill.visible = false
	else:
		var lo := minf(cur_norm, new_norm)
		var hi := maxf(cur_norm, new_norm)
		base_fill.anchor_left = 0.0
		base_fill.anchor_right = lo
		if improved:
			pos_fill.visible = true
			pos_fill.anchor_left = lo
			pos_fill.anchor_right = hi
			neg_fill.visible = false
		else:
			pos_fill.visible = false
			neg_fill.visible = true
			neg_fill.anchor_left = lo
			neg_fill.anchor_right = hi

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
	mod_tile_popover.visible = false
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
		card.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.11, 0.13), brd, 1, 10))
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
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
		info.add_child(name_lbl)
		
		var detail := Label.new()
		detail.text = "Слотов: %d  |  Модов установлено: %d  |  Урон: %d" % [slot_defs.size(), w.get_installed_mod_count(), int(w.damage)]
		detail.add_theme_color_override("font_color", Color(0.55, 0.82, 0.52))
		detail.add_theme_font_size_override("font_size", 11)
		info.add_child(detail)
		
		var open_btn := Button.new()
		open_btn.text = "🔧 МОДИФИЦИРОВАТЬ"
		open_btn.custom_minimum_size = Vector2(170, 34)
		open_btn.add_theme_font_size_override("font_size", 12)
		open_btn.add_theme_stylebox_override("normal", _make_box(Color(0.18, 0.16, 0.11), brd, 1, 6))
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
	mod_tile_popover.visible = false
	
	mod_title_label.text = "ВЕРСТАК: %s" % w.name.to_upper()
	if mod_preview and mod_preview.has_method("show_weapon_with_mods"):
		mod_preview.show_weapon_with_mods(w, false)
	_rebuild_eft_slots()
	_refresh_stats()

func handle_escape() -> bool:
	if not visible:
		return false
	if is_in_mod_view:
		if mod_tile_popover.visible:
			mod_tile_popover.visible = false
			active_slot_type = ""
			hovered_mod_id = "__NONE__"
			_rebuild_eft_slots()
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
		if connector_layer:
			connector_layer.set_lines([])
		return
	var stage_sz: Vector2 = slot_overlay.size
	if stage_sz.x < 10.0 or stage_sz.y < 10.0:
		return

	var anchors_2d: Array[Vector2] = []
	var centers: Array[Vector2] = []
	var sizes: Array[Vector2] = []
	for entry in slot_entries:
		var btn: Control = entry["btn"]
		var anc: Vector2 = mod_preview.get_projected_slot_pos(entry["local_anchor"])
		anchors_2d.append(anc)
		if not is_instance_valid(btn):
			centers.append(anc)
			sizes.append(Vector2(44.0, 44.0))
			continue
		var proj: Vector2 = anc + entry["screen_offset"]
		var half: Vector2 = btn.size * 0.5
		proj.x = clampf(proj.x, 10.0 + half.x, stage_sz.x - 10.0 - half.x)
		proj.y = clampf(proj.y, 10.0 + half.y, stage_sz.y - 24.0 - half.y)
		centers.append(proj)
		sizes.append(btn.size)

	# 4-pass 2D AABB repulsion so compact 44x44 EFT slot squares NEVER overlap!
	var n: int = centers.size()
	for _it in range(4):
		for i in range(n):
			for j in range(i + 1, n):
				var dx: float = centers[j].x - centers[i].x
				var dy: float = centers[j].y - centers[i].y
				var min_x: float = (sizes[i].x + sizes[j].x) * 0.5 + 5.0
				var min_y: float = (sizes[i].y + sizes[j].y) * 0.5 + 5.0
				var ox: float = min_x - absf(dx)
				var oy: float = min_y - absf(dy)
				if ox > 0.0 and oy > 0.0:
					if ox < oy:
						var push_x: float = (ox * 0.52) * (1.0 if dx >= 0.0 else -1.0)
						centers[i].x -= push_x
						centers[j].x += push_x
					else:
						var push_y: float = (oy * 0.52) * (1.0 if dy >= 0.0 else -1.0)
						centers[i].y -= push_y
						centers[j].y += push_y
		for k in range(n):
			var half_k: Vector2 = sizes[k] * 0.5
			centers[k].x = clampf(centers[k].x, 10.0 + half_k.x, stage_sz.x - 10.0 - half_k.x)
			centers[k].y = clampf(centers[k].y, 10.0 + half_k.y, stage_sz.y - 24.0 - half_k.y)

	var line_payload: Array[Dictionary] = []
	for i in range(n):
		var btn: Control = slot_entries[i]["btn"]
		if is_instance_valid(btn):
			btn.position = centers[i] - sizes[i] * 0.5
			line_payload.append({
				"anchor": anchors_2d[i],
				"slot_center": centers[i],
				"slot_size": sizes[i],
				"active": (slot_entries[i]["slot_type"] == active_slot_type),
				"modded": bool(slot_entries[i]["modded"])
			})
	if connector_layer:
		connector_layer.set_lines(line_payload)

static func _get_slot_screen_offset(slot_type: String) -> Vector2:
	# Radial outer ring offsets around the huge 3D weapon so EFT leader lines fan out cleanly!
	match slot_type:
		"optic": return Vector2(0.0, -148.0)
		"dust_cover": return Vector2(-78.0, -118.0)
		"side_rail": return Vector2(-132.0, -78.0)
		"rail": return Vector2(68.0, -124.0)
		"handguard": return Vector2(36.0, -128.0)
		"muzzle": return Vector2(92.0, -104.0)
		"tactical_laser": return Vector2(126.0, -56.0)
		"flashlight": return Vector2(118.0, 96.0)
		"underbarrel": return Vector2(44.0, 128.0)
		"magazine": return Vector2(-24.0, 128.0)
		"ammo_type": return Vector2(72.0, 152.0)
		"internal": return Vector2(-96.0, 110.0)
		"pistol_grip": return Vector2(-46.0, 154.0)
		"stock_adapter": return Vector2(-94.0, -104.0)
		"buttstock": return Vector2(-128.0, 86.0)
	return Vector2(0.0, 90.0)

func _rebuild_eft_slots() -> void:
	for c in slot_overlay.get_children():
		slot_overlay.remove_child(c)
		c.queue_free()
	slot_entries.clear()
	if not selected_weapon:
		return
		
	var slot_defs: Array[Dictionary] = WeaponModDBScript.get_slot_defs(selected_weapon.weapon_id)
	const SLOT_SIZE := 44.0
	for sd in slot_defs:
		var st: String = sd["slot_type"]
		if not WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, sd):
			continue
			
		var installed_id: String = str(selected_weapon.installed_mods.get(st, ""))
		var installed_mod = WeaponModDBScript.get_mod(installed_id)
		var is_custom_mod: bool = installed_mod != null and not installed_mod.is_vanilla_default
		
		var slot_btn := Button.new()
		slot_btn.name = "SlotBtn_" + st
		slot_btn.text = ""
		slot_btn.tooltip_text = "%s: %s" % [sd["label"], installed_mod.name if installed_mod else "Пусто"]
		slot_btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		
		var bg_col := Color(0.07, 0.08, 0.10, 0.88)
		var brd_col := Color(0.96, 0.80, 0.36, 1.0) if (active_slot_type == st) else (Color(0.56, 0.78, 0.44, 0.94) if is_custom_mod else Color(0.46, 0.49, 0.54, 0.86))
		slot_btn.add_theme_stylebox_override("normal", _make_box(bg_col, brd_col, 2 if active_slot_type == st else 1, 0))
		slot_btn.add_theme_stylebox_override("hover", _make_box(Color(0.14, 0.15, 0.18, 0.94), Color(0.98, 0.84, 0.44, 1.0), 2, 0))
		slot_btn.add_theme_stylebox_override("pressed", _make_box(Color(0.18, 0.16, 0.12, 0.96), Color(0.98, 0.85, 0.48, 1.0), 2, 0))
		
		if installed_mod:
			var thumb_box := _create_mod_slot_3d_icon(installed_id, 2.0, -10.0)
			slot_btn.add_child(thumb_box)
			
			var mini_lbl := Label.new()
			mini_lbl.text = installed_mod.short_name
			mini_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mini_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			mini_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			mini_lbl.offset_left = 1.0
			mini_lbl.offset_right = -1.0
			mini_lbl.offset_top = -11.0
			mini_lbl.offset_bottom = -1.0
			mini_lbl.clip_text = true
			mini_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_lbl.add_theme_font_size_override("font_size", 7)
			mini_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80))
			mini_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
			mini_lbl.add_theme_constant_override("outline_size", 2)
			slot_btn.add_child(mini_lbl)
		else:
			var empty_lbl := Label.new()
			empty_lbl.text = "+" + str(sd["label"]).substr(0, 5)
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			empty_lbl.clip_text = true
			empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_lbl.add_theme_font_size_override("font_size", 7)
			empty_lbl.add_theme_color_override("font_color", Color(0.64, 0.66, 0.70, 0.88))
			slot_btn.add_child(empty_lbl)
		
		var sd_copy: Dictionary = sd
		var btn_ref: Button = slot_btn
		slot_btn.pressed.connect(func(): _open_slot_tile_popover(sd_copy, btn_ref))
		slot_overlay.add_child(slot_btn)
		
		var local_anchor: Vector3 = WeaponModVisualsScript.get_slot_anchor_local(selected_weapon.weapon_id, st)
		var screen_off: Vector2 = _get_slot_screen_offset(st)
		slot_entries.append({
			"btn": slot_btn,
			"slot_type": st,
			"local_anchor": local_anchor,
			"screen_offset": screen_off,
			"modded": is_custom_mod
		})
	
	_process(0.0)

func _create_mod_slot_3d_icon(mod_id: String, pad_x: float = 3.0, pad_bot: float = -12.0) -> SubViewportContainer:
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.offset_left = pad_x
	svc.offset_right = -pad_x
	svc.offset_top = 2.0
	svc.offset_bottom = pad_bot
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.size = Vector2i(80, 70)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	svc.add_child(sv)
	
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.84, 0.86, 0.90)
	env.ambient_light_energy = 1.45
	we.environment = env
	sv.add_child(we)
	
	var dlight := DirectionalLight3D.new()
	dlight.position = Vector3(1, 2, 2)
	dlight.rotation_degrees = Vector3(-35, 30, 0)
	dlight.light_energy = 1.35
	sv.add_child(dlight)
	
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.02, 1.35)
	cam.fov = 38.0
	cam.current = true
	sv.add_child(cam)
	
	var mod_mesh := WeaponModVisualsScript.create_mod_preview(mod_id)
	sv.add_child(mod_mesh)
	return svc

func _open_slot_tile_popover(slot_def: Dictionary, anchor_btn: Button = null) -> void:
	if not selected_weapon:
		return
	var st: String = slot_def["slot_type"]
	active_slot_type = st
	hovered_mod_id = "__NONE__"
	mod_popover_title.text = "СЛОТ: %s" % slot_def["label"]
	_rebuild_eft_slots()
	
	for c in mod_tile_grid.get_children():
		c.queue_free()
		
	if not WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, slot_def):
		mod_tile_popover.visible = false
		return
		
	var current_id: String = str(selected_weapon.installed_mods.get(st, ""))
	var tile_count := 0
	if slot_def.get("can_remove", true):
		_add_mod_tile(st, "", "ПУСТО", "Снять деталь с модели оружия и оставить слот пустым.", 0, current_id == "", false)
		tile_count += 1
		
	var mods: Array = WeaponModDBScript.get_mods_for_slot(selected_weapon.weapon_id, st)
	for m in mods:
		var is_owned: bool = selected_weapon.is_mod_owned(m.id)
		_add_mod_tile(st, m.id, m.short_name, "%s — %s" % [m.name, m.description], m.price, current_id == m.id, is_owned)
		tile_count += 1

	mod_tile_grid.columns = mini(5, maxi(1, tile_count))
	mod_tile_popover.visible = true
	mod_tile_popover.reset_size()

	# Position floating EFT tile grid right next to the clicked slot (clamped cleanly inside 3D stage!)
	var stage_sz: Vector2 = slot_overlay.size
	var ref_pos := Vector2(stage_sz.x * 0.5, 48.0)
	for entry in slot_entries:
		if entry["slot_type"] == st and is_instance_valid(entry["btn"]):
			var b: Control = entry["btn"]
			ref_pos = b.position + Vector2(b.size.x + 8.0, -8.0)
			break
	if anchor_btn and is_instance_valid(anchor_btn):
		ref_pos = anchor_btn.position + Vector2(anchor_btn.size.x + 8.0, -8.0)

	var est_w: float = float(mod_tile_grid.columns) * 60.0 + 18.0
	var est_rows: int = int(ceil(float(tile_count) / float(max(1, mod_tile_grid.columns))))
	var est_h: float = float(est_rows) * 60.0 + 38.0
	if ref_pos.x + est_w > stage_sz.x - 10.0:
		ref_pos.x = maxf(10.0, ref_pos.x - est_w - 60.0)
	ref_pos.x = clampf(ref_pos.x, 10.0, maxf(10.0, stage_sz.x - est_w - 10.0))
	ref_pos.y = clampf(ref_pos.y, 10.0, maxf(10.0, stage_sz.y - est_h - 24.0))
	mod_tile_popover.position = ref_pos

func _add_mod_tile(slot_type: String, mod_id: String, short_lbl: String, desc_text: String, price: int, is_installed: bool, is_owned: bool) -> void:
	const TILE_SZ := 56.0
	var tile := Button.new()
	tile.text = ""
	tile.custom_minimum_size = Vector2(TILE_SZ, TILE_SZ)
	tile.tooltip_text = desc_text

	var bg: Color
	var brd: Color
	if is_installed:
		bg = Color(0.36, 0.30, 0.18, 0.96)
		brd = Color(0.96, 0.82, 0.42, 1.0)
	elif is_owned:
		bg = Color(0.24, 0.21, 0.16, 0.94)
		brd = Color(0.72, 0.62, 0.44, 0.92)
	else:
		bg = Color(0.10, 0.11, 0.14, 0.94)
		brd = Color(0.34, 0.38, 0.44, 0.90)
	tile.add_theme_stylebox_override("normal", _make_box(bg, brd, 2 if is_installed else 1, 0))
	tile.add_theme_stylebox_override("hover", _make_box(Color(0.38, 0.32, 0.20, 0.98), Color(0.98, 0.85, 0.48, 1.0), 2, 0))

	if mod_id != "":
		var ico := _create_mod_slot_3d_icon(mod_id, 2.0, -13.0)
		tile.add_child(ico)
	else:
		var x_lbl := Label.new()
		x_lbl.text = "✕"
		x_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		x_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		x_lbl.offset_bottom = -10.0
		x_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		x_lbl.add_theme_font_size_override("font_size", 18)
		x_lbl.add_theme_color_override("font_color", Color(0.86, 0.36, 0.32))
		tile.add_child(x_lbl)

	# Top-right price or installed checkmark badge
	if is_installed:
		var chk := Label.new()
		chk.text = "✓"
		chk.position = Vector2(TILE_SZ - 13.0, 1.0)
		chk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chk.add_theme_font_size_override("font_size", 10)
		chk.add_theme_color_override("font_color", Color(0.45, 0.95, 0.48))
		tile.add_child(chk)
	elif mod_id != "" and not is_owned and price > 0:
		var plbl := Label.new()
		plbl.text = "$%d" % price
		plbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		plbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
		plbl.offset_right = -2.0
		plbl.offset_top = 1.0
		plbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plbl.add_theme_font_size_override("font_size", 8)
		plbl.add_theme_color_override("font_color", Color(0.94, 0.78, 0.36))
		plbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
		plbl.add_theme_constant_override("outline_size", 2)
		tile.add_child(plbl)

	# Tiny bottom caption
	var cap := Label.new()
	cap.text = short_lbl
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	cap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cap.offset_left = 1.0
	cap.offset_right = -1.0
	cap.offset_top = -12.0
	cap.offset_bottom = -1.0
	cap.clip_text = true
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_theme_font_size_override("font_size", 8)
	cap.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84))
	cap.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	cap.add_theme_constant_override("outline_size", 2)
	tile.add_child(cap)

	tile.mouse_entered.connect(func():
		hovered_mod_id = mod_id
		mod_desc_label.text = desc_text
		_refresh_stats()
	)
	tile.mouse_exited.connect(func():
		hovered_mod_id = "__NONE__"
		_refresh_stats()
	)
	tile.pressed.connect(func():
		_apply_mod_selection(slot_type, mod_id)
	)
	mod_tile_grid.add_child(tile)

func _apply_mod_selection(slot_type: String, mod_id: String) -> void:
	if not selected_weapon:
		return
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
	var prev_id: String = str(res.get("prev_id", ""))
		
	if mod_preview and mod_preview.has_method("show_weapon_with_mods"):
		mod_preview.show_weapon_with_mods(selected_weapon, true)
		
	if hud_ref:
		var player = hud_ref.get_parent()
		if player and player.weapon_manager:
			if slot_type == "ammo_type" and prev_id != mod_id:
				player.weapon_manager.on_weapon_ammo_type_changed(selected_weapon, prev_id, mod_id)
			player.weapon_manager.refresh_active_weapon_mods()
		if hud_ref.has_method("play_buy_sfx"):
			hud_ref.play_buy_sfx()
			
	hovered_mod_id = "__NONE__"
	_rebuild_eft_slots()
	for sd in WeaponModDBScript.get_slot_defs(selected_weapon.weapon_id):
		if sd["slot_type"] == slot_type:
			if WeaponModDBScript.is_slot_unlocked(selected_weapon.installed_mods, sd):
				_open_slot_tile_popover(sd)
			else:
				mod_tile_popover.visible = false
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
		WeaponModDBScript.cleanup_invalid_mods(preview_mods, selected_weapon.weapon_id)
		new_st = selected_weapon.compute_stats_for_mods(preview_mods)
		
	var dmg_max: float = 1300.0 if selected_weapon.is_rpg else 320.0
	var mag_max: float = 250.0 if selected_weapon.is_belt_fed else (75.0 if selected_weapon.weapon_id == "ak47" else 35.0)
	_update_bar("damage", "Урон", cur_st["damage"], new_st["damage"], dmg_max, "", true)
	_update_bar("spread", "Разброс", float(cur_st["spread"]) * 100.0, float(new_st["spread"]) * 100.0, 10.0, "°", false)
	_update_bar("recoil_pitch", "Верт. отдача", float(cur_st["recoil_pitch"]) * 1000.0, float(new_st["recoil_pitch"]) * 1000.0, 160.0, "", false)
	_update_bar("recoil_yaw", "Гориз. отдача", float(cur_st["recoil_yaw"]) * 1000.0, float(new_st["recoil_yaw"]) * 1000.0, 45.0, "", false)
	_update_bar("ergonomics", "Эргоном.", cur_st["ergonomics"], new_st["ergonomics"], 100.0, "", true)
	_update_bar("rpm", "Темп", cur_st["rpm"], new_st["rpm"], 1500.0, "", true)
	_update_bar("mag_size", "Магазин", float(cur_st["mag_size"]), float(new_st["mag_size"]), mag_max, "", true)
	var cur_ap: float = float(cur_st["mechanics"].get("armor_pen_mult", 1.0)) * 100.0
	var new_ap: float = float(new_st["mechanics"].get("armor_pen_mult", 1.0)) * 100.0
	_update_bar("armor_pen", "Пробитие", cur_ap, new_ap, 180.0, "%", true)

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
