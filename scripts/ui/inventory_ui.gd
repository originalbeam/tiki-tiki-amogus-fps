class_name InventoryUI
extends Panel

# Escape from Tarkov style 10-Slot Quickbar + Arsenal Inventory UI ([I])
# - Slots [1], [2], [3]: Firearm slots (unlocked from start)
# - Slots [4], [5]: Reserved Firearm slots (locked initially; unlockable for $600 each in Shop!)
# - Slot  [6]: Usable / Consumable items slot (Водка "Чекунец 67", key [6])
# - Slots [7], [8], [9], [0]: Reserved quick slots (shown as existing / coming soon)
# - Dedicated Melee Slot [V] badge + Owned Arsenal assignment grid below

var hud_ref: Node = null
var quickbar_row: HBoxContainer = null
var melee_info_label: Label = null
var arsenal_grid: GridContainer = null

func setup(hud: Node) -> void:
	hud_ref = hud
	name = "InventoryPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	set_anchors_preset(Control.PRESET_CENTER)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -540.0
	offset_top = -310.0
	offset_right = 540.0
	offset_bottom = 310.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 0.99), Color(0.76, 0.64, 0.38, 0.88), 1, 0))
	
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 16
	root_vbox.offset_top = 14
	root_vbox.offset_right = -16
	root_vbox.offset_bottom = -14
	root_vbox.add_theme_constant_override("separation", 10)
	add_child(root_vbox)
	
	# Top Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)
	
	var title := Label.new()
	title.text = "🎒 ИНВЕНТАРЬ — БЫСТРЫЕ СЛОТЫ [1–0] И АРСЕНАЛ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.86, 0.74, 0.44))
	header.add_child(title)

	melee_info_label = Label.new()
	melee_info_label.text = "[V] НОЖ (70 урона)"
	melee_info_label.add_theme_font_size_override("font_size", 12)
	melee_info_label.add_theme_color_override("font_color", Color(0.54, 0.80, 0.48))
	header.add_child(melee_info_label)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ЗАКРЫТЬ (I / ESC)"
	close_btn.custom_minimum_size = Vector2(165, 32)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.14, 0.15, 0.17), Color(0.42, 0.45, 0.50), 1))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_inventory"): hud_ref.close_inventory())
	header.add_child(close_btn)
	
	# EFT-Style 10-Slot Horizontal Quickbar Container
	var qb_panel := PanelContainer.new()
	qb_panel.add_theme_stylebox_override("panel", _make_box(Color(0.04, 0.05, 0.06, 0.96), Color(0.32, 0.30, 0.24, 0.90), 1, 10))
	root_vbox.add_child(qb_panel)

	var qb_vbox := VBoxContainer.new()
	qb_vbox.add_theme_constant_override("separation", 6)
	qb_panel.add_child(qb_vbox)

	var qb_hdr := Label.new()
	qb_hdr.text = "── БЫСТРЫЕ СЛОТЫ (1–3: ОРУЖИЕ  |  4–5: ДОП. ОРУЖИЕ $600 В МАГАЗИНЕ  |  6: ПРЕДМЕТЫ  |  7–0: В РАЗРАБОТКЕ) ──"
	qb_hdr.add_theme_font_size_override("font_size", 11)
	qb_hdr.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	qb_vbox.add_child(qb_hdr)

	quickbar_row = HBoxContainer.new()
	quickbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	quickbar_row.add_theme_constant_override("separation", 6)
	qb_vbox.add_child(quickbar_row)

	# Owned Arsenal Stash Grid
	var ars_panel := PanelContainer.new()
	ars_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ars_panel.add_theme_stylebox_override("panel", _make_box(Color(0.05, 0.06, 0.07, 0.96), Color(0.26, 0.28, 0.32), 1, 10))
	root_vbox.add_child(ars_panel)

	var ars_vbox := VBoxContainer.new()
	ars_vbox.add_theme_constant_override("separation", 8)
	ars_panel.add_child(ars_vbox)

	var ars_hdr := Label.new()
	ars_hdr.text = "── АРСЕНАЛ (НАЗНАЧЕНИЕ ОРУЖИЯ В ОТКРЫТЫЕ СЛОТЫ 1–5) ──"
	ars_hdr.add_theme_font_size_override("font_size", 12)
	ars_hdr.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	ars_vbox.add_child(ars_hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ars_vbox.add_child(scroll)

	arsenal_grid = GridContainer.new()
	arsenal_grid.columns = 2
	arsenal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arsenal_grid.add_theme_constant_override("h_separation", 10)
	arsenal_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(arsenal_grid)

func refresh() -> void:
	if not hud_ref:
		return
	var player = hud_ref.get_parent()
	if not player or not player.weapon_manager:
		return
	var wm = player.weapon_manager
	
	for c in quickbar_row.get_children():
		c.queue_free()
	for c in arsenal_grid.get_children():
		c.queue_free()

	if melee_info_label and wm.melee_slot:
		melee_info_label.text = "[V] %s (Урон: %d)" % [wm.melee_slot.name.to_upper(), int(wm.melee_slot.damage)]

	# Build ALL 10 EFT Quick Slots: [1] [2] [3] [4] [5] [6] [7] [8] [9] [0]
	var slot_keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	for idx in range(10):
		var key_str: String = slot_keys[idx]
		var slot_box := PanelContainer.new()
		slot_box.name = "InvQuickSlot_%s" % key_str
		slot_box.custom_minimum_size = Vector2(96, 86)
		slot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quickbar_row.add_child(slot_box)

		var inner := Control.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_box.add_child(inner)

		# EFT top-left corner hotbar number badge
		var num_bg := ColorRect.new()
		num_bg.color = Color(0.14, 0.15, 0.17, 0.96)
		num_bg.position = Vector2(0, 0)
		num_bg.size = Vector2(20, 18)
		inner.add_child(num_bg)

		var num_lbl := Label.new()
		num_lbl.text = key_str
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.size = Vector2(20, 18)
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.add_theme_color_override("font_color", Color(0.92, 0.84, 0.56))
		num_bg.add_child(num_lbl)

		if idx < 5:
			# Firearm Slots [1..5] (1-3 unlocked, 4-5 unlockable for $600 each!)
			var unlocked: bool = wm.is_weapon_slot_unlocked(idx)
			var w: Weapon = wm.weapon_slots[idx] if (idx < wm.weapon_slots.size()) else null
			var is_active: bool = unlocked and (idx == wm.current_weapon_idx)

			if not unlocked:
				slot_box.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.06, 0.07, 0.92), Color(0.42, 0.24, 0.22, 0.82), 1, 4))
				num_lbl.add_theme_color_override("font_color", Color(0.60, 0.42, 0.40))
				var lock_lbl := Label.new()
				lock_lbl.text = "🔒 ОРУЖИЕ\n$600\n(Магазин)"
				lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lock_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
				lock_lbl.offset_top = 14
				lock_lbl.add_theme_font_size_override("font_size", 10)
				lock_lbl.add_theme_color_override("font_color", Color(0.76, 0.48, 0.42))
				inner.add_child(lock_lbl)
			else:
				var brd := Color(0.92, 0.78, 0.40, 1.0) if is_active else (Color(0.56, 0.62, 0.54, 0.88) if w else Color(0.28, 0.30, 0.34, 0.85))
				var bg := Color(0.14, 0.13, 0.10, 0.96) if is_active else Color(0.09, 0.10, 0.12, 0.94)
				slot_box.add_theme_stylebox_override("panel", _make_box(bg, brd, 2 if is_active else 1, 4))
				if w:
					var w_lbl := Label.new()
					w_lbl.text = w.name.to_upper()
					w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					w_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
					w_lbl.offset_top = 20
					w_lbl.offset_bottom = 42
					w_lbl.clip_text = true
					w_lbl.add_theme_font_size_override("font_size", 11)
					w_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
					inner.add_child(w_lbl)

					var am_lbl := Label.new()
					am_lbl.text = "%d/%d" % [w.current_ammo, w.reserve_ammo]
					am_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					am_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
					am_lbl.offset_top = 40
					am_lbl.offset_bottom = 56
					am_lbl.add_theme_font_size_override("font_size", 10)
					am_lbl.add_theme_color_override("font_color", Color(0.76, 0.72, 0.58))
					inner.add_child(am_lbl)

					var rm_btn := Button.new()
					rm_btn.text = "СНЯТЬ"
					rm_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
					rm_btn.offset_top = -19
					rm_btn.offset_bottom = -1
					rm_btn.add_theme_font_size_override("font_size", 9)
					rm_btn.add_theme_stylebox_override("normal", _make_box(Color(0.22, 0.11, 0.11), Color(0.55, 0.25, 0.25), 1, 1))
					var s_copy := idx
					rm_btn.pressed.connect(func():
						wm.unequip_slot(s_copy)
						refresh()
					)
					inner.add_child(rm_btn)
				else:
					var emp := Label.new()
					emp.text = "ОРУЖИЕ\n(Пусто)"
					emp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					emp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					emp.set_anchors_preset(Control.PRESET_FULL_RECT)
					emp.offset_top = 14
					emp.add_theme_font_size_override("font_size", 10)
					emp.add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))
					inner.add_child(emp)
		elif idx == 5:
			# Slot [6]: Usable / Consumable Items Slot (Vodka)
			slot_box.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.11, 0.14, 0.95), Color(0.46, 0.68, 0.86, 0.88), 1, 4))
			num_lbl.add_theme_color_override("font_color", Color(0.56, 0.82, 0.98))
			var c_lbl := Label.new()
			c_lbl.text = "ПРЕДМЕТ\nЧекунец 67\n(%d / 3)" % player.vodka_count
			c_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			c_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			c_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			c_lbl.offset_top = 14
			c_lbl.add_theme_font_size_override("font_size", 10)
			c_lbl.add_theme_color_override("font_color", Color(0.84, 0.92, 0.98) if player.vodka_count > 0 else Color(0.50, 0.56, 0.62))
			inner.add_child(c_lbl)
		else:
			# Slots [7], [8], [9], [0]: Existing reserved slots (not yet implemented)
			slot_box.add_theme_stylebox_override("panel", _make_box(Color(0.05, 0.055, 0.065, 0.78), Color(0.22, 0.24, 0.28, 0.65), 1, 4))
			slot_box.tooltip_text = "Слот [%s] зарезервирован для будущих обновлений." % key_str
			num_lbl.add_theme_color_override("font_color", Color(0.42, 0.45, 0.48))
			var res_lbl := Label.new()
			res_lbl.text = "—\nСКОРО\n(Резерв)"
			res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			res_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			res_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			res_lbl.offset_top = 14
			res_lbl.add_theme_font_size_override("font_size", 9)
			res_lbl.add_theme_color_override("font_color", Color(0.38, 0.41, 0.45))
			inner.add_child(res_lbl)

	# Owned Arsenal Assignment Grid (assign any weapon into any UNLOCKED firearm slot 1..5!)
	for w in wm.weapons:
		var card := PanelContainer.new()
		var eq_border := Color(0.76, 0.64, 0.38, 0.85) if w.slot > 0 else Color(0.24, 0.27, 0.31)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.11, 0.13), eq_border, 1, 8))
		arsenal_grid.add_child(card)
		
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 5)
		card.add_child(cv)
		
		var top := HBoxContainer.new()
		cv.add_child(top)
		
		var w_title := Label.new()
		w_title.text = w.name.to_upper()
		w_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w_title.add_theme_font_size_override("font_size", 14)
		w_title.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90))
		top.add_child(w_title)
		
		var status := Label.new()
		if w.slot > 0:
			status.text = "[СЛОТ %d]" % w.slot
			status.add_theme_color_override("font_color", Color(0.84, 0.72, 0.42))
		else:
			status.text = "[В РЮКЗАКЕ]"
			status.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		status.add_theme_font_size_override("font_size", 11)
		top.add_child(status)
		
		var meta := Label.new()
		var mod_cnt: int = w.get_installed_mod_count()
		meta.text = "Патроны: %d / %d  |  Урон: %d  |  Модов: %d" % [w.current_ammo, w.reserve_ammo, int(w.damage), mod_cnt]
		meta.add_theme_font_size_override("font_size", 11)
		meta.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76))
		cv.add_child(meta)
		
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		cv.add_child(btn_row)
		
		for s_idx in range(5):
			var unlocked_s: bool = wm.is_weapon_slot_unlocked(s_idx)
			var sb := Button.new()
			var is_here: bool = (w.slot == s_idx + 1)
			sb.custom_minimum_size = Vector2(72, 26)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sb.add_theme_font_size_override("font_size", 10)
			if not unlocked_s:
				sb.text = "🔒 [%d]" % (s_idx + 1)
				sb.disabled = true
				sb.tooltip_text = "Купите слот [%d] в магазине за $600" % (s_idx + 1)
				sb.add_theme_stylebox_override("disabled", _make_box(Color(0.08, 0.08, 0.09), Color(0.28, 0.22, 0.22), 1, 2))
			else:
				sb.text = "✓ [%d]" % (s_idx + 1) if is_here else "Слот %d" % (s_idx + 1)
				sb.disabled = is_here
				var bcol := Color(0.24, 0.20, 0.12) if is_here else Color(0.14, 0.16, 0.18)
				var brd := Color(0.82, 0.68, 0.38) if is_here else Color(0.32, 0.36, 0.40)
				sb.add_theme_stylebox_override("normal", _make_box(bcol, brd, 1, 2))
				var w_ref: Weapon = w
				var target_slot: int = s_idx
				sb.pressed.connect(func():
					wm.equip_weapon_to_slot(w_ref, target_slot)
					refresh()
				)
			btn_row.add_child(sb)

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
