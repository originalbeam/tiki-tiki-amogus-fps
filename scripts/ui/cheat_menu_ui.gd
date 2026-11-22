class_name CheatMenuUI
extends Panel

# Developer / Testing Cheat Menu toggled via '}' (or ']' / 'Ъ' key)
# Supports: God Mode, Infinite Reserve Ammo, +10 HP, +10 Armor, Kill All Enemies, +$10 / +$50 / +$100

var hud_ref: Node = null
var god_btn: Button = null
var inf_ammo_btn: Button = null

func setup(hud: Node) -> void:
	hud_ref = hud
	name = "CheatMenuPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	set_anchors_preset(Control.PRESET_CENTER)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -220.0
	offset_top = -215.0
	offset_right = 220.0
	offset_bottom = 215.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 0.97), Color(0.82, 0.36, 0.24, 0.9), 2, 16))
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18
	vbox.offset_top = 14
	vbox.offset_right = -18
	vbox.offset_bottom = -14
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)
	var title := Label.new()
	title.text = "⚙ ЧИТ-МЕНЮ ТЕСТИРОВАНИЯ [ } ]"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.92, 0.52, 0.32))
	hdr.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(func(): if hud_ref and hud_ref.has_method("close_cheat_menu"): hud_ref.close_cheat_menu())
	hdr.add_child(close_btn)
	
	# Toggle 1: God Mode
	god_btn = _make_btn("🛡 Неуязвимость: ВЫКЛ")
	god_btn.pressed.connect(_on_toggle_god)
	vbox.add_child(god_btn)
	
	# Toggle 2: Infinite Reserve Ammo
	inf_ammo_btn = _make_btn("∞ Бесконечные патроны в запасе: ВЫКЛ")
	inf_ammo_btn.pressed.connect(_on_toggle_inf_ammo)
	vbox.add_child(inf_ammo_btn)
	
	# Row: +10 HP | +10 Armor
	var vitals_row := HBoxContainer.new()
	vitals_row.add_theme_constant_override("separation", 8)
	vbox.add_child(vitals_row)
	
	var hp_btn := _make_btn("+10 HP")
	hp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_btn.pressed.connect(func():
		var p = _get_player()
		if p and p.has_method("add_health"):
			p.add_health(10.0)
	)
	vitals_row.add_child(hp_btn)
	
	var arm_btn := _make_btn("+10 БРОНИ")
	arm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arm_btn.pressed.connect(func():
		var p = _get_player()
		if p and p.has_method("add_armor"):
			p.add_armor(10.0, false)
	)
	vitals_row.add_child(arm_btn)
	
	# Button: Kill All Enemies
	var kill_btn := _make_btn("💀 УБИТЬ ВСЕХ ВРАГОВ", Color(0.32, 0.11, 0.11), Color(0.75, 0.25, 0.25))
	kill_btn.pressed.connect(_on_kill_all_enemies)
	vbox.add_child(kill_btn)
	
	# Row: +$10 | +$50 | +$100
	var money_lbl := Label.new()
	money_lbl.text = "── ВЫДАТЬ ВАЛЮТУ ($) ──"
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_lbl.add_theme_font_size_override("font_size", 12)
	money_lbl.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	vbox.add_child(money_lbl)
	
	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 8)
	vbox.add_child(money_row)
	
	for amt in [10, 50, 100]:
		var mb := _make_btn("+$%d" % amt, Color(0.16, 0.15, 0.10), Color(0.76, 0.64, 0.38))
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val: int = amt
		mb.pressed.connect(func():
			var p = _get_player()
			if p and p.has_method("add_money"):
				p.add_money(val)
		)
		money_row.add_child(mb)
		
	var hint := Label.new()
	hint.text = "Закрыть: клавиша } (или ] / ESC)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
	vbox.add_child(hint)

func refresh() -> void:
	var p = _get_player()
	if not p:
		return
	var is_god: bool = bool(p.is_invincible) if ("is_invincible" in p) else false
	god_btn.text = "🛡 Неуязвимость: %s" % ("ВКЛ ✓" if is_god else "ВЫКЛ")
	god_btn.add_theme_stylebox_override("normal", _make_box(Color(0.14, 0.24, 0.14) if is_god else Color(0.12, 0.13, 0.15), Color(0.42, 0.80, 0.42) if is_god else Color(0.32, 0.35, 0.40), 1, 8))
	
	var is_inf: bool = bool(p.weapon_manager.infinite_reserve_ammo) if (p.weapon_manager and "infinite_reserve_ammo" in p.weapon_manager) else false
	inf_ammo_btn.text = "∞ Бесконечные патроны в запасе: %s" % ("ВКЛ ✓" if is_inf else "ВЫКЛ")
	inf_ammo_btn.add_theme_stylebox_override("normal", _make_box(Color(0.14, 0.24, 0.14) if is_inf else Color(0.12, 0.13, 0.15), Color(0.42, 0.80, 0.42) if is_inf else Color(0.32, 0.35, 0.40), 1, 8))

func _on_toggle_god() -> void:
	var p = _get_player()
	if p and "is_invincible" in p:
		p.is_invincible = not p.is_invincible
		refresh()

func _on_toggle_inf_ammo() -> void:
	var p = _get_player()
	if p and p.weapon_manager:
		p.weapon_manager.infinite_reserve_ammo = not p.weapon_manager.infinite_reserve_ammo
		p.weapon_manager.emit_ammo_state()
		refresh()

func _on_kill_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(99999.0, false)

func _get_player() -> Node:
	if hud_ref:
		return hud_ref.get_parent()
	return null

func _make_btn(txt: String, bg: Color = Color(0.12, 0.13, 0.15), brd: Color = Color(0.32, 0.35, 0.40)) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", _make_box(bg, brd, 1, 8))
	b.add_theme_stylebox_override("hover", _make_box(bg.lightened(0.08), Color(0.84, 0.72, 0.42), 1, 8))
	return b

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
