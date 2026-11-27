class_name CheatMenuUI
extends Panel

# Developer / Testing Cheat Menu toggled via '}' (or ']' / 'Ъ' key)
# Supports: God Mode, Infinite Reserve Ammo, +10 HP, +10 Armor, Kill All Enemies, +$10 / +$50 / +$100

var hud_ref: Node = null
var god_btn: Button = null
var inf_ammo_btn: Button = null
var boss_next_btn: Button = null
var mi24_next_btn: Button = null

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
	offset_left = -245.0
	offset_top = -318.0
	offset_right = 245.0
	offset_bottom = 318.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 1.0), Color(0.82, 0.36, 0.24, 0.9), 2, 14))
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 14
	scroll.offset_top = 12
	scroll.offset_right = -14
	scroll.offset_bottom = -12
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(vbox)
	
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
	
	# Button: Finish Wave (kills alive + unspawned enemies and awards full normal rewards)
	var finish_wave_btn := _make_btn("⚡ ЗАВЕРШИТЬ ВОЛНУ", Color(0.24, 0.16, 0.08), Color(0.92, 0.64, 0.22))
	finish_wave_btn.pressed.connect(_on_finish_wave)
	vbox.add_child(finish_wave_btn)

	# Row: Spawn Tiger I Boss (Next Wave | Instant Now)
	var tiger_row := HBoxContainer.new()
	tiger_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tiger_row)
	boss_next_btn = _make_btn("🪖 TIGER I НА СЛЕД. ВОЛНЕ", Color(0.22, 0.14, 0.10), Color(0.88, 0.40, 0.24))
	boss_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_next_btn.pressed.connect(_on_spawn_tiger_next_wave)
	tiger_row.add_child(boss_next_btn)

	var tiger_now_btn := _make_btn("🪖 СРАЗУ TIGER I", Color(0.30, 0.14, 0.10), Color(0.98, 0.44, 0.24))
	tiger_now_btn.pressed.connect(_on_spawn_tiger_now)
	tiger_row.add_child(tiger_now_btn)

	# Row: Spawn Mi-24 Boss (Next Wave | Instant Now)
	var mi24_row := HBoxContainer.new()
	mi24_row.add_theme_constant_override("separation", 6)
	vbox.add_child(mi24_row)
	mi24_next_btn = _make_btn("🚁 МИ-24 НА СЛЕД. ВОЛНЕ", Color(0.18, 0.15, 0.10), Color(0.92, 0.62, 0.26))
	mi24_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mi24_next_btn.pressed.connect(_on_spawn_mi24_next_wave)
	mi24_row.add_child(mi24_next_btn)

	var mi24_now_btn := _make_btn("🚁 СРАЗУ МИ-24", Color(0.28, 0.14, 0.10), Color(0.98, 0.44, 0.24))
	mi24_now_btn.pressed.connect(_on_spawn_mi24_now)
	mi24_row.add_child(mi24_now_btn)

	# Stage 2 New Enemy Classes Spawn Row
	var sp_lbl := Label.new()
	sp_lbl.text = "── СПАВН НОВЫХ ВРАГОВ И АРЕНЫ ──"
	sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_lbl.add_theme_font_size_override("font_size", 11)
	sp_lbl.add_theme_color_override("font_color", Color(0.70, 0.78, 0.88))
	vbox.add_child(sp_lbl)

	var cls_row := HBoxContainer.new()
	cls_row.add_theme_constant_override("separation", 4)
	vbox.add_child(cls_row)
	for entry in [["🔧 Инж", 6], ["🛡 Щит", 7], ["🥷 Див", 8], ["⚡ Клок", 9]]:
		var cb := _make_btn(entry[0], Color(0.12, 0.15, 0.18), Color(0.46, 0.66, 0.84))
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ptype: int = int(entry[1])
		cb.pressed.connect(func(): _on_spawn_special_enemy(ptype))
		cls_row.add_child(cb)

	var env_row := HBoxContainer.new()
	env_row.add_theme_constant_override("separation", 4)
	vbox.add_child(env_row)
	var b_night := _make_btn("🌙 Ночь/День", Color(0.11, 0.12, 0.18), Color(0.55, 0.62, 0.92))
	b_night.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_night.pressed.connect(_on_toggle_night)
	env_row.add_child(b_night)

	var b_weather := _make_btn("🌧 Погода", Color(0.11, 0.15, 0.18), Color(0.46, 0.74, 0.86))
	b_weather.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_weather.pressed.connect(_on_cycle_weather)
	env_row.add_child(b_weather)

	var b_drop := _make_btn("🪂 Airdrop", Color(0.16, 0.16, 0.10), Color(0.92, 0.78, 0.34))
	b_drop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_drop.pressed.connect(_on_spawn_airdrop)
	env_row.add_child(b_drop)
	
	# Row: +$10 | +$50 | +$100 | +$1000
	var money_lbl := Label.new()
	money_lbl.text = "── ВЫДАТЬ ВАЛЮТУ ($) ──"
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_lbl.add_theme_font_size_override("font_size", 12)
	money_lbl.add_theme_color_override("font_color", Color(0.76, 0.64, 0.38))
	vbox.add_child(money_lbl)
	
	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 6)
	vbox.add_child(money_row)
	
	for amt in [10, 50, 100, 1000]:
		var bg_c: Color = Color(0.22, 0.18, 0.08) if amt >= 1000 else Color(0.16, 0.15, 0.10)
		var brd_c: Color = Color(0.95, 0.78, 0.32) if amt >= 1000 else Color(0.76, 0.64, 0.38)
		var mb := _make_btn("+$%d" % amt, bg_c, brd_c)
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

	if boss_next_btn:
		var spawner := get_tree().root.find_child("EnemySpawner", true, false)
		var queued: bool = false
		if spawner:
			queued = bool(spawner.force_boss_next_wave) or (bool(spawner.tiger_queued_for_current_wave) and bool(spawner.is_warming_up))
		boss_next_btn.text = "🪖 Tiger I на след. волне: %s" % ("ОК ✓" if queued else "НАЖАТЬ")
		boss_next_btn.add_theme_stylebox_override("normal", _make_box(Color(0.28, 0.18, 0.08) if queued else Color(0.22, 0.14, 0.10), Color(0.95, 0.62, 0.22) if queued else Color(0.88, 0.40, 0.24), 1, 8))

	if mi24_next_btn:
		var sp2 := get_tree().root.find_child("EnemySpawner", true, false)
		var q_m: bool = false
		if sp2 and ("force_mi24_next_wave" in sp2):
			q_m = bool(sp2.force_mi24_next_wave) or (bool(sp2.mi24_queued_for_current_wave) and bool(sp2.is_warming_up))
		mi24_next_btn.text = "🚁 Ми-24 на след. волне: %s" % ("ОК ✓" if q_m else "НАЖАТЬ")

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

func _on_finish_wave() -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("finish_wave_immediately"):
		spawner.finish_wave_immediately()
	else:
		_on_kill_all_enemies()

func _on_spawn_tiger_next_wave() -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("queue_boss_next_wave"):
		spawner.queue_boss_next_wave()
	refresh()

func _on_spawn_tiger_now() -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("spawn_tiger_now"):
		spawner.spawn_tiger_now()
	if hud_ref and hud_ref.has_method("close_cheat_menu"):
		hud_ref.close_cheat_menu()

func _on_spawn_mi24_next_wave() -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("queue_mi24_next_wave"):
		spawner.queue_mi24_next_wave()
	refresh()

func _on_spawn_mi24_now() -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("spawn_mi24_now"):
		spawner.spawn_mi24_now()
	if hud_ref and hud_ref.has_method("close_cheat_menu"):
		hud_ref.close_cheat_menu()

func _on_spawn_special_enemy(pool_type: int) -> void:
	var spawner := get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("spawn_specific_enemy_near_player"):
		spawner.spawn_specific_enemy_near_player(pool_type)

func _on_toggle_night() -> void:
	for ec in get_tree().get_nodes_in_group("environment_controller"):
		if is_instance_valid(ec) and ec.has_method("set_environment_state"):
			var next_night: bool = not bool(ec.is_night_wave)
			ec.set_environment_state(next_night, str(ec.current_weather), false)
			if hud_ref and hud_ref.has_method("show_arena_toast"):
				hud_ref.show_arena_toast("🌙 ВКЛЮЧЕНА НОЧЬ" if next_night else "☀ ВКЛЮЧЁН ДЕНЬ")

func _on_cycle_weather() -> void:
	var order := ["clear", "fog", "precip", "storm"]
	for ec in get_tree().get_nodes_in_group("environment_controller"):
		if is_instance_valid(ec) and ec.has_method("set_environment_state"):
			var idx: int = order.find(str(ec.current_weather))
			var next_w: String = order[(idx + 1) % order.size()]
			ec.set_environment_state(bool(ec.is_night_wave), next_w, false)
			if hud_ref and hud_ref.has_method("show_arena_toast"):
				hud_ref.show_arena_toast("🌦 ПОГОДА: %s" % ec.get_weather_display_name())

func _on_spawn_airdrop() -> void:
	var p = _get_player()
	var pos := Vector3(12.0, 0.0, 12.0)
	if p and p is Node3D:
		var fwd: Vector3 = -(p as Node3D).global_transform.basis.z
		pos = (p as Node3D).global_position + Vector3(fwd.x, 0.0, fwd.z).normalized() * 14.0
		pos.x = clampf(pos.x, -40.0, 40.0)
		pos.z = clampf(pos.z, -40.0, 40.0)
	for mgr in get_tree().get_nodes_in_group("arena_interactables"):
		if is_instance_valid(mgr) and mgr.has_method("spawn_parachute_drop"):
			mgr.spawn_parachute_drop(pos, "loot")

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
