class_name Mi24BossHUD
extends PanelContainer

# Minimalist Tactical Boss Status HUD for Mi-24 "Крокодил" (Matches TigerBossHUD Style!)
# Displays:
# - Compact Header + Structural Hull Bar
# - 2 Crew Vector Icons: ПИЛ (Pilot), ОПЕР (Gunner/Operator)
# - 5 Module Vector Icons: ДВ-Л, ДВ-П, ХВОСТ, НАР-Л, НАР-П (white -> yellow -> red -> black)
# - Flashing "МИ-24 СБИТ!" overlay + confirmation tone on destruction

class HeliVectorIcon extends Control:
	var icon_type: String = "pilot"
	var icon_color: Color = Color(0.94, 0.96, 0.98)

	func _init(itype: String, col: Color) -> void:
		icon_type = itype
		icon_color = col
		custom_minimum_size = Vector2(26, 20)

	func set_icon_color(col: Color) -> void:
		if icon_color != col:
			icon_color = col
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var c := Vector2(w * 0.5, h * 0.5)
		var col := icon_color
		var lw := 1.6

		match icon_type:
			"pilot":
				# Flight helmet silhouette + visor band
				draw_arc(c + Vector2(0, -1), 6.8, PI, TAU, 16, col, lw, true)
				draw_rect(Rect2(c.x - 6.8, c.y - 1.5, 13.6, 5.5), col, false, lw)
				draw_rect(Rect2(c.x - 4.8, c.y - 3.2, 9.6, 3.4), col, true)
			"gunner":
				# Optical chin-turret targeting reticle
				var r := 6.8
				draw_arc(c, r, 0.0, TAU, 18, col, 1.4, true)
				draw_line(c + Vector2(-r - 2.2, 0), c + Vector2(-2.2, 0), col, 1.4, true)
				draw_line(c + Vector2(2.2, 0), c + Vector2(r + 2.2, 0), col, 1.4, true)
				draw_line(c + Vector2(0, -r - 2.2), c + Vector2(0, -2.2), col, 1.4, true)
				draw_line(c + Vector2(0, 2.2), c + Vector2(0, r + 2.2), col, 1.4, true)
				draw_circle(c, 1.6, col)
			"engine":
				# Turbine fan blades inside intake ring
				var r := 6.6
				draw_arc(c, r, 0.0, TAU, 16, col, 1.6, true)
				draw_circle(c, 2.0, col)
				for i in range(4):
					var a := float(i) * (PI * 0.5) + 0.4
					draw_line(c + Vector2(cos(a), sin(a)) * 2.0, c + Vector2(cos(a), sin(a)) * (r - 0.5), col, 1.5, true)
			"tail_rotor":
				# 3-blade tail rotor X-hub
				draw_circle(c, 2.2, col)
				for i in range(3):
					var a := float(i) * (TAU / 3.0) - PI * 0.5
					draw_line(c, c + Vector2(cos(a), sin(a)) * 7.8, col, 2.0, true)
			"rocket_pod":
				# B-8V20 rocket pod muzzle tubes
				draw_arc(c, 6.8, 0.0, TAU, 16, col, 1.5, true)
				draw_circle(c, 1.4, col)
				for i in range(6):
					var a := float(i) * (TAU / 6.0)
					draw_circle(c + Vector2(cos(a), sin(a)) * 3.8, 1.2, col)

var crew_slots: Dictionary = {}
var mod_slots: Dictionary = {}
var hull_bar: ProgressBar = null
var root_box: Control = null

var destroyed_overlay: Panel = null
var destroyed_label: Label = null
var is_destroyed_flashing: bool = false
var flash_timer: float = 0.0
var destroy_hide_timer: float = 0.0

func _ready() -> void:
	name = "Mi24BossHUD"
	visible = false
	_build_ui()

func _build_ui() -> void:
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = Color(0.05, 0.06, 0.07, 0.86)
	root_style.border_width_left = 2
	root_style.border_width_top = 1
	root_style.border_width_right = 1
	root_style.border_width_bottom = 1
	root_style.border_color = Color(0.86, 0.54, 0.24, 0.60)
	root_style.content_margin_left = 8.0
	root_style.content_margin_right = 8.0
	root_style.content_margin_top = 6.0
	root_style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", root_style)

	root_box = Control.new()
	root_box.custom_minimum_size = Vector2(248, 114)
	add_child(root_box)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	root_box.add_child(vbox)

	# Header + Crew inline row
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 3)
	top_row.add_child(title_box)

	var title := Label.new()
	title.text = "МИ-24 «КРОКОДИЛ»"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
	title_box.add_child(title)

	hull_bar = ProgressBar.new()
	hull_bar.custom_minimum_size = Vector2(0, 8)
	hull_bar.max_value = 100.0
	hull_bar.value = 100.0
	hull_bar.show_percentage = false
	var hb_bg := StyleBoxFlat.new()
	hb_bg.bg_color = Color(0.14, 0.15, 0.17, 0.95)
	var hb_fg := StyleBoxFlat.new()
	hb_fg.bg_color = Color(0.88, 0.34, 0.22, 0.95)
	hull_bar.add_theme_stylebox_override("background", hb_bg)
	hull_bar.add_theme_stylebox_override("fill", hb_fg)
	title_box.add_child(hull_bar)

	var crew_defs := [
		["pilot", "pilot", "ПИЛ"],
		["gunner", "gunner", "ОПЕР"],
	]
	for cd in crew_defs:
		var slot := _create_icon_slot(cd[1], cd[2], Color(0.94, 0.96, 0.98))
		top_row.add_child(slot["panel"])
		crew_slots[cd[0]] = slot

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.75, 0.65, 0.55, 0.28)
	vbox.add_child(sep)

	# 5 Key Subsystems Row
	var mod_row := HBoxContainer.new()
	mod_row.add_theme_constant_override("separation", 4)
	vbox.add_child(mod_row)

	var mod_defs := [
		["engine_l", "engine", "ДВ-Л"],
		["engine_r", "engine", "ДВ-П"],
		["tail_rotor", "tail_rotor", "ХВОСТ"],
		["pod_l", "rocket_pod", "НАР-Л"],
		["pod_r", "rocket_pod", "НАР-П"],
	]
	for md in mod_defs:
		var mslot := _create_icon_slot(md[1], md[2], Color(0.84, 0.88, 0.92))
		mod_row.add_child(mslot["panel"])
		mod_slots[md[0]] = mslot

	# Destroyed Overlay
	destroyed_overlay = Panel.new()
	destroyed_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	destroyed_overlay.visible = false
	var ov_style := StyleBoxFlat.new()
	ov_style.bg_color = Color(0.06, 0.03, 0.03, 0.94)
	ov_style.border_width_left = 2
	ov_style.border_width_top = 1
	ov_style.border_width_right = 1
	ov_style.border_width_bottom = 1
	ov_style.border_color = Color(0.98, 0.36, 0.20, 0.95)
	destroyed_overlay.add_theme_stylebox_override("panel", ov_style)
	root_box.add_child(destroyed_overlay)

	destroyed_label = Label.new()
	destroyed_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	destroyed_label.text = "МИ-24 СБИТ!"
	destroyed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	destroyed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	destroyed_label.add_theme_font_size_override("font_size", 20)
	destroyed_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.22))
	destroyed_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	destroyed_label.add_theme_constant_override("outline_size", 4)
	destroyed_overlay.add_child(destroyed_label)

func _create_icon_slot(itype: String, short_name: String, initial_col: Color) -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(44, 36)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.10, 0.12, 0.88)
	st.border_width_left = 1
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = Color(initial_col.r, initial_col.g, initial_col.b, 0.45)
	st.content_margin_left = 2.0
	st.content_margin_right = 2.0
	st.content_margin_top = 2.0
	st.content_margin_bottom = 2.0
	p.add_theme_stylebox_override("panel", st)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 1)
	p.add_child(vb)

	var center := CenterContainer.new()
	vb.add_child(center)

	var ic := HeliVectorIcon.new(itype, initial_col)
	center.add_child(ic)

	var lb := Label.new()
	lb.text = short_name
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", 9)
	lb.add_theme_color_override("font_color", initial_col)
	vb.add_child(lb)

	return {"panel": p, "icon": ic, "lbl": lb, "style": st}

static func _ratio_to_color(ratio: float) -> Color:
	if ratio <= 0.0:
		return Color(0.14, 0.14, 0.16)
	if ratio >= 0.99:
		return Color(0.92, 0.95, 0.98)
	if ratio > 0.55:
		return Color(1.0, 0.88, 0.28)
	if ratio > 0.25:
		return Color(1.0, 0.48, 0.18)
	return Color(0.96, 0.20, 0.16)

func _apply_slot_color(slot: Dictionary, col: Color, dead: bool) -> void:
	var ic: HeliVectorIcon = slot["icon"]
	var lb: Label = slot["lbl"]
	var st: StyleBoxFlat = slot["style"]
	ic.set_icon_color(col)
	lb.add_theme_color_override("font_color", col if not dead else Color(0.36, 0.36, 0.40))
	st.bg_color = Color(0.04, 0.04, 0.05, 0.92) if dead else Color(0.09, 0.10, 0.12, 0.88)
	st.border_color = Color(0.28, 0.28, 0.32, 0.55) if dead else Color(col.r, col.g, col.b, 0.58)

func show_boss() -> void:
	is_destroyed_flashing = false
	if destroyed_overlay:
		destroyed_overlay.visible = false
	visible = true

func hide_boss() -> void:
	is_destroyed_flashing = false
	visible = false

func update_status(hull_ratio: float, crew_ratios: Dictionary, mod_ratios: Dictionary) -> void:
	if is_destroyed_flashing:
		return
	if not visible:
		visible = true
	if hull_bar:
		hull_bar.value = clampf(hull_ratio * 100.0, 0.0, 100.0)
	for ck in crew_slots.keys():
		var r: float = float(crew_ratios.get(ck, 1.0))
		_apply_slot_color(crew_slots[ck], _ratio_to_color(r), r <= 0.0)
	for mk in mod_slots.keys():
		var r: float = float(mod_ratios.get(mk, 1.0))
		_apply_slot_color(mod_slots[mk], _ratio_to_color(r), r <= 0.0)

func trigger_destroyed() -> void:
	visible = true
	is_destroyed_flashing = true
	flash_timer = 0.0
	destroy_hide_timer = 4.2
	if destroyed_overlay:
		destroyed_overlay.visible = true
	var beep := AudioStreamPlayer.new()
	beep.bus = "SFX"
	beep.stream = SoundEffects.create_tiger_destroyed_beep_sound()
	beep.volume_db = 1.5
	get_tree().root.add_child(beep)
	beep.play()
	beep.finished.connect(beep.queue_free)

func _process(delta: float) -> void:
	if not is_destroyed_flashing:
		return
	flash_timer += delta * 10.0
	destroy_hide_timer -= delta
	if destroyed_label:
		var pulse: float = 0.55 + 0.45 * sin(flash_timer)
		destroyed_label.modulate = Color(1.0, 1.0, 1.0, pulse)
	if destroy_hide_timer <= 0.0:
		is_destroyed_flashing = false
		visible = false
