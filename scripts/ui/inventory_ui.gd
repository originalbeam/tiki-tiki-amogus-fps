class_name InventoryUI
extends Panel

# Escape from Tarkov style Inventory & Equipment Slots UI
# Opened / closed via [I] (or closed via [ESC]).
# Allows equipping/swapping any owned firearm into slots [1], [2], [3], inspecting the
# specialized Melee Slot [V], and viewing Consumable Slot [5].

var hud_ref: Node = null
var slots_container: VBoxContainer = null
var arsenal_container: VBoxContainer = null

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
	offset_left = -460.0
	offset_top = -280.0
	offset_right = 460.0
	offset_bottom = 280.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var bg := _make_box(Color(0.07, 0.08, 0.09, 0.97), Color(0.76, 0.64, 0.38, 0.8), 1)
	add_theme_stylebox_override("panel", bg)
	
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 18
	root_vbox.offset_top = 14
	root_vbox.offset_right = -18
	root_vbox.offset_bottom = -14
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)
	
	# Top Header Bar
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)
	
	var title := Label.new()
	title.text = "🎒 ИНВЕНТАРЬ И СЛОТЫ СНАРЯЖЕНИЯ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.84, 0.72, 0.44))
	header.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "✕ ЗАКРЫТЬ (I / ESC)"
	close_btn.custom_minimum_size = Vector2(180, 34)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", _make_box(Color(0.14, 0.15, 0.17), Color(0.42, 0.45, 0.50), 1))
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_inventory"): hud_ref.close_inventory())
	header.add_child(close_btn)
	
	# Main 2-column split
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	root_vbox.add_child(hbox)
	
	# LEFT: Active Equipment Slots
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(360, 0)
	left_panel.add_theme_stylebox_override("panel", _make_box(Color(0.05, 0.06, 0.07, 0.95), Color(0.26, 0.28, 0.32), 1, 12))
	hbox.add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)
	
	var left_hdr := Label.new()
	left_hdr.text = "── АКТИВНЫЕ СЛОТЫ ──"
	left_hdr.add_theme_font_size_override("font_size", 13)
	left_hdr.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	left_vbox.add_child(left_hdr)
	
	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_scroll)
	
	slots_container = VBoxContainer.new()
	slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_container.add_theme_constant_override("separation", 8)
	left_scroll.add_child(slots_container)
	
	# RIGHT: Owned Arsenal / Stash
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _make_box(Color(0.05, 0.06, 0.07, 0.95), Color(0.26, 0.28, 0.32), 1, 12))
	hbox.add_child(right_panel)
	
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_vbox)
	
	var right_hdr := Label.new()
	right_hdr.text = "── АРСЕНАЛ (НАЗНАЧЕНИЕ В СЛОТЫ 1–3) ──"
	right_hdr.add_theme_font_size_override("font_size", 13)
	right_hdr.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	right_vbox.add_child(right_hdr)
	
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_scroll)
	
	arsenal_container = VBoxContainer.new()
	arsenal_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arsenal_container.add_theme_constant_override("separation", 8)
	right_scroll.add_child(arsenal_container)

func refresh() -> void:
	if not hud_ref:
		return
	var player = hud_ref.get_parent()
	if not player or not player.weapon_manager:
		return
	var wm = player.weapon_manager
	
	for c in slots_container.get_children():
		c.queue_free()
	for c in arsenal_container.get_children():
		c.queue_free()
		
	# 1. Active Firearm Slots [1], [2], [3]
	for i in range(wm.weapon_slots.size()):
		var w: Weapon = wm.weapon_slots[i]
		var card := PanelContainer.new()
		var is_active: bool = (i == wm.current_weapon_idx)
		var border_col := Color(0.82, 0.68, 0.38) if is_active else Color(0.28, 0.31, 0.36)
		card.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.11, 0.13), border_col, 2 if is_active else 1, 10))
		slots_container.add_child(card)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		
		var lbl_slot := Label.new()
		lbl_slot.text = "СЛОТ [%d] %s" % [i + 1, "(В РУКАХ)" if is_active else ""]
		lbl_slot.add_theme_font_size_override("font_size", 11)
		lbl_slot.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
		info.add_child(lbl_slot)
		
		var lbl_name := Label.new()
		if w:
			var mod_cnt := w.get_installed_mod_count()
			var mod_str := "  [Модов: %d]" % mod_cnt if mod_cnt > 0 else ""
			lbl_name.text = "%s  (%d / %d)%s" % [w.name.to_upper(), w.current_ammo, w.reserve_ammo, mod_str]
			lbl_name.add_theme_color_override("font_color", Color(0.94, 0.94, 0.92))
		else:
			lbl_name.text = "— ПУСТОЙ СЛОТ —"
			lbl_name.add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))
		lbl_name.add_theme_font_size_override("font_size", 14)
		info.add_child(lbl_name)
		
		if w:
			var unequip_btn := Button.new()
			unequip_btn.text = "СНЯТЬ"
			unequip_btn.custom_minimum_size = Vector2(72, 30)
			unequip_btn.add_theme_font_size_override("font_size", 12)
			unequip_btn.add_theme_stylebox_override("normal", _make_box(Color(0.24, 0.12, 0.12), Color(0.55, 0.25, 0.25), 1))
			var slot_idx_copy := i
			unequip_btn.pressed.connect(func():
				wm.unequip_slot(slot_idx_copy)
				refresh()
			)
			row.add_child(unequip_btn)
			
	# 2. Specialized Melee Slot [V]
	var melee_card := PanelContainer.new()
	melee_card.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.11, 0.10), Color(0.38, 0.56, 0.36), 1, 10))
	slots_container.add_child(melee_card)
	
	var m_vbox := VBoxContainer.new()
	melee_card.add_child(m_vbox)
	var m_hdr := Label.new()
	m_hdr.text = "СПЕЦ-СЛОТ БЛИЖНЕГО БОЯ [V]"
	m_hdr.add_theme_font_size_override("font_size", 11)
	m_hdr.add_theme_color_override("font_color", Color(0.52, 0.78, 0.46))
	m_vbox.add_child(m_hdr)
	var m_name := Label.new()
	var mw: Weapon = wm.melee_slot
	m_name.text = "%s  (Урон: %d)" % [mw.name if mw else "Нет", int(mw.damage) if mw else 0]
	m_name.add_theme_font_size_override("font_size", 14)
	m_vbox.add_child(m_name)
	var m_hint := Label.new()
	m_hint.text = "Выделенный слот для оружия ближнего боя"
	m_hint.add_theme_font_size_override("font_size", 11)
	m_hint.add_theme_color_override("font_color", Color(0.55, 0.60, 0.58))
	m_vbox.add_child(m_hint)
	
	# 3. Quick Consumable Slot [5]
	var vod_card := PanelContainer.new()
	vod_card.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.10, 0.12), Color(0.32, 0.36, 0.42), 1, 10))
	slots_container.add_child(vod_card)
	var v_vbox := VBoxContainer.new()
	vod_card.add_child(v_vbox)
	var v_hdr := Label.new()
	v_hdr.text = "БЫСТРЫЙ СЛОТ [5]"
	v_hdr.add_theme_font_size_override("font_size", 11)
	v_hdr.add_theme_color_override("font_color", Color(0.65, 0.72, 0.80))
	v_vbox.add_child(v_hdr)
	var v_lbl := Label.new()
	v_lbl.text = "Водка \"Чекунец 67\" (%d / 3)" % player.vodka_count
	v_lbl.add_theme_font_size_override("font_size", 14)
	v_vbox.add_child(v_lbl)
	
	# 4. Owned Weapons Arsenal (Right Column)
	for w in wm.weapons:
		var card := PanelContainer.new()
		var eq_border := Color(0.76, 0.64, 0.38, 0.8) if w.slot > 0 else Color(0.24, 0.27, 0.31)
		card.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.11, 0.13), eq_border, 1, 10))
		arsenal_container.add_child(card)
		
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)
		
		var top := HBoxContainer.new()
		cv.add_child(top)
		
		var w_title := Label.new()
		w_title.text = w.name.to_upper()
		w_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w_title.add_theme_font_size_override("font_size", 15)
		w_title.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90))
		top.add_child(w_title)
		
		var status := Label.new()
		if w.slot > 0:
			status.text = "[СЛОТ %d]" % w.slot
			status.add_theme_color_override("font_color", Color(0.84, 0.72, 0.42))
		else:
			status.text = "[В РЮКЗАКЕ]"
			status.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		status.add_theme_font_size_override("font_size", 12)
		top.add_child(status)
		
		var meta := Label.new()
		var ads_txt := " | Прицел ПКМ" if w.has_mechanic("ads_enabled") else ""
		meta.text = "Патроны: %d / %d  |  Урон: %d%s" % [w.current_ammo, w.reserve_ammo, int(w.damage), ads_txt]
		meta.add_theme_font_size_override("font_size", 12)
		meta.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76))
		cv.add_child(meta)
		
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		cv.add_child(btn_row)
		
		for s_idx in range(3):
			var sb := Button.new()
			var is_here: bool = (w.slot == s_idx + 1)
			sb.text = "✓ СЛОТ %d" % (s_idx + 1) if is_here else "В СЛОТ %d" % (s_idx + 1)
			sb.custom_minimum_size = Vector2(96, 30)
			sb.add_theme_font_size_override("font_size", 12)
			sb.disabled = is_here
			var bcol := Color(0.24, 0.20, 0.12) if is_here else Color(0.14, 0.16, 0.18)
			var brd := Color(0.82, 0.68, 0.38) if is_here else Color(0.32, 0.36, 0.40)
			sb.add_theme_stylebox_override("normal", _make_box(bcol, brd, 1))
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
