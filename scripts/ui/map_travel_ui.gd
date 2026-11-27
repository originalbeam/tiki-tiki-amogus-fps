extends Panel

# Paid Map / Biome Transfer UI opened with [M] while standing near the Minivan Shop!

var hud_ref: Node = null
var cards_vbox: VBoxContainer = null
var balance_label: Label = null
var status_label: Label = null

func setup(hud: Node) -> void:
	hud_ref = hud
	name = "MapTravelUI"
	visible = false
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -360
	offset_right = 360
	offset_top = -270
	offset_bottom = 270

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.07, 0.09, 0.96)
	bg.border_color = Color(0.77, 0.65, 0.40, 0.95)
	bg.border_width_left = 2; bg.border_width_top = 2; bg.border_width_right = 2; bg.border_width_bottom = 2
	add_theme_stylebox_override("panel", bg)

	var main_vb := VBoxContainer.new()
	main_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vb.offset_left = 18; main_vb.offset_right = -18
	main_vb.offset_top = 14; main_vb.offset_bottom = -14
	main_vb.add_theme_constant_override("separation", 10)
	add_child(main_vb)

	# Header bar
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	main_vb.add_child(top_hb)

	var title := Label.new()
	title.text = "🚐 ПЕРЕЕЗД НА ДРУГУЮ КАРТУ (ТАКСИ-МИНИВЭН)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.44))
	top_hb.add_child(title)

	balance_label = Label.new()
	balance_label.text = "$ 0"
	balance_label.add_theme_font_size_override("font_size", 16)
	balance_label.add_theme_color_override("font_color", Color(0.55, 0.90, 0.48))
	top_hb.add_child(balance_label)

	var close_btn := Button.new()
	close_btn.text = "✕ [M / ESC]"
	close_btn.custom_minimum_size = Vector2(96, 30)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.pressed.connect(func():
		if hud_ref and hud_ref.has_method("close_map_travel"):
			hud_ref.close_map_travel()
	)
	top_hb.add_child(close_btn)

	var sub := Label.new()
	sub.text = "Смена локации сохраняет всё оружие, модификации, верстак, патроны и текущую волну. Стоимость переезда: $%d." % GlobalSettings.MAP_TRAVEL_COST
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.76, 0.78, 0.82))
	main_vb.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(scroll)

	cards_vbox = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vbox)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.46, 0.36))
	main_vb.add_child(status_label)

func refresh() -> void:
	if not cards_vbox:
		return
	for c in cards_vbox.get_children():
		c.queue_free()
	status_label.text = ""

	var player: Node = hud_ref.get_parent() if hud_ref else null
	var cur_money: int = int(player.money) if (player and "money" in player) else 0
	if balance_label:
		balance_label.text = "$ %d" % cur_money

	var cur_map_id: String = GlobalSettings.selected_map_id if GlobalSettings else "forest"
	var cost: int = GlobalSettings.MAP_TRAVEL_COST if GlobalSettings else 250

	for mid in GlobalSettings.MAP_ORDER:
		var info: Dictionary = GlobalSettings.get_map_info(mid)
		var is_cur: bool = (mid == cur_map_id)
		var acc: Color = info.get("accent", Color(0.77, 0.65, 0.40))

		var card := PanelContainer.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.14, 0.13, 0.10, 0.95) if is_cur else Color(0.09, 0.10, 0.12, 0.94)
		csb.border_color = acc if is_cur else Color(0.28, 0.30, 0.34, 0.85)
		csb.border_width_left = 3; csb.border_width_top = 1; csb.border_width_right = 1; csb.border_width_bottom = 1
		csb.content_margin_left = 12; csb.content_margin_right = 12; csb.content_margin_top = 8; csb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", csb)
		cards_vbox.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var txt_vb := VBoxContainer.new()
		txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt_vb.add_theme_constant_override("separation", 2)
		row.add_child(txt_vb)

		var name_lbl := Label.new()
		var badge: String = "  ✓ ТЕКУЩАЯ КАРТА" if is_cur else ("  [%s]" % str(info["tag"]))
		name_lbl.text = "%s%s" % [str(info["name"]).to_upper(), badge]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", acc if is_cur else Color(0.94, 0.92, 0.88))
		txt_vb.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(info["desc"])
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.74, 0.76, 0.80))
		txt_vb.add_child(desc_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(168, 42)
		btn.add_theme_font_size_override("font_size", 12)
		if is_cur:
			btn.text = "ВЫ УЖЕ ЗДЕСЬ"
			btn.disabled = true
		elif cur_money < cost:
			btn.text = "ПЕРЕЕХАТЬ ($%d)\nНедостаточно $" % cost
			btn.disabled = true
		else:
			btn.text = "🚐 ПЕРЕЕХАТЬ ($%d)" % cost
			btn.disabled = false
		var target_id: String = mid
		btn.pressed.connect(func(): _on_travel_pressed(target_id))
		row.add_child(btn)

func _on_travel_pressed(target_map_id: String) -> void:
	var player: Node = hud_ref.get_parent() if hud_ref else null
	if not player:
		return
	var cost: int = GlobalSettings.MAP_TRAVEL_COST if GlobalSettings else 250
	if GlobalSettings and target_map_id == GlobalSettings.selected_map_id:
		return
	if not player.has_method("spend_money") or not player.spend_money(cost):
		status_label.text = "⚠ Недостаточно средств для переезда ($%d)!" % cost
		return

	var maps := get_tree().get_nodes_in_group("procedural_map")
	if maps.size() > 0 and maps[0].has_method("switch_map"):
		maps[0].switch_map(target_map_id)

	var map_name: String = str(GlobalSettings.get_map_info(target_map_id).get("name", target_map_id))
	if hud_ref:
		if hud_ref.has_method("play_buy_sfx"):
			hud_ref.play_buy_sfx()
		if hud_ref.has_method("show_arena_toast"):
			hud_ref.show_arena_toast("🚐 ПЕРЕЕЗД ЗАВЕРШЁН: %s (-$%d)" % [map_name.to_upper(), cost])
		if hud_ref.has_method("close_map_travel"):
			hud_ref.close_map_travel()
