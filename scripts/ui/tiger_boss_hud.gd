class_name TigerBossHUD
extends PanelContainer

# Minimalist Tactical Boss Status HUD for Tiger I (Zero Emojis!)
# Placed directly beneath EnemyCounter on the left.
# - Custom vector-drawn silhouettes (DynamicVectorIcon) that dynamically recolor with damage
# - 5 Crew icons: ВОД, РАД, ЗАР, НАВ, КОМ (white -> yellow -> red -> black dynamically)
# - 4 Module icons (hidden until damaged/destroyed): ПУЛ, ОПТ, БАКИ (1..4: light yellow -> yellow -> red -> black), ДВИГ
# - Minimalist flashing "TIGER УНИЧТОЖЕН" overlay + confirmation beep sound

class DynamicVectorIcon extends Control:
	var icon_type: String = "driver"
	var icon_color: Color = Color(0.94, 0.96, 0.98)

	func _init(itype: String, col: Color) -> void:
		icon_type = itype
		icon_color = col
		custom_minimum_size = Vector2(26, 22)

	func set_icon_color(col: Color) -> void:
		if icon_color != col:
			icon_color = col
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var c := Vector2(w * 0.5, h * 0.5)
		var col := icon_color
		var lw := 1.7

		match icon_type:
			"driver":
				# Minimalist steering wheel silhouette
				var r := minf(w, h) * 0.38
				draw_arc(c, r, 0.0, TAU, 20, col, lw, true)
				draw_circle(c, 2.2, col)
				draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), col, lw, true)
				draw_line(c, c + Vector2(0, r), col, lw, true)
			"radio":
				# Minimalist radio / antenna + signal waves
				draw_rect(Rect2(c.x - 5.5, c.y - 1.5, 11.0, 8.5), col, false, lw)
				draw_line(Vector2(c.x - 3.0, c.y - 1.5), Vector2(c.x - 3.0, c.y - 8.5), col, lw, true)
				draw_arc(Vector2(c.x + 1.0, c.y - 5.0), 4.0, -PI * 0.35, PI * 0.35, 10, col, 1.3, true)
				draw_arc(Vector2(c.x + 1.0, c.y - 5.0), 7.2, -PI * 0.35, PI * 0.35, 12, col, 1.3, true)
			"loader":
				# Minimalist 88mm artillery shell silhouette
				var pts := PackedVector2Array([
					Vector2(c.x, c.y - 8.5),
					Vector2(c.x + 3.2, c.y - 3.0),
					Vector2(c.x + 3.2, c.y + 6.5),
					Vector2(c.x + 4.4, c.y + 8.5),
					Vector2(c.x - 4.4, c.y + 8.5),
					Vector2(c.x - 3.2, c.y + 6.5),
					Vector2(c.x - 3.2, c.y - 3.0),
				])
				draw_colored_polygon(pts, col)
			"gunner":
				# Minimalist optical gunsight reticle
				var r := minf(w, h) * 0.37
				draw_arc(c, r, 0.0, TAU, 20, col, 1.5, true)
				draw_line(c + Vector2(-r - 2.5, 0), c + Vector2(-2.2, 0), col, 1.4, true)
				draw_line(c + Vector2(2.2, 0), c + Vector2(r + 2.5, 0), col, 1.4, true)
				draw_line(c + Vector2(0, -r - 2.5), c + Vector2(0, -2.2), col, 1.4, true)
				draw_line(c + Vector2(0, 2.2), c + Vector2(0, r + 2.5), col, 1.4, true)
				draw_circle(c, 1.5, col)
			"commander":
				# Minimalist officer peaked cap silhouette
				var crown := PackedVector2Array([
					Vector2(c.x - 9.0, c.y - 2.5),
					Vector2(c.x - 5.0, c.y - 7.5),
					Vector2(c.x + 5.0, c.y - 7.5),
					Vector2(c.x + 9.0, c.y - 2.5),
					Vector2(c.x + 6.5, c.y + 2.5),
					Vector2(c.x - 6.5, c.y + 2.5),
				])
				draw_colored_polygon(crown, col)
				# Cap peak visor
				draw_rect(Rect2(c.x - 7.5, c.y + 3.2, 15.0, 2.6), col, true)
				# Small dark band cut across crown
				draw_line(Vector2(c.x - 6.5, c.y + 1.0), Vector2(c.x + 6.5, c.y + 1.0), Color(0.06, 0.07, 0.09), 1.6)
			"coax_mg":
				# Minimalist machine gun receiver + barrel + bipod/mag
				draw_rect(Rect2(c.x - 8.5, c.y - 2.5, 9.5, 4.5), col, true)
				draw_rect(Rect2(c.x + 1.0, c.y - 1.2, 9.0, 2.2), col, true)
				draw_rect(Rect2(c.x - 11.0, c.y - 1.5, 2.5, 4.5), col, true)
				draw_rect(Rect2(c.x - 3.5, c.y + 2.0, 3.2, 5.0), col, true)
			"optics":
				# Minimalist armored optic prism & lens glare
				draw_rect(Rect2(c.x - 9.0, c.y - 5.5, 18.0, 11.0), col, false, lw)
				draw_arc(c, 3.8, 0.0, TAU, 16, col, 1.4, true)
				draw_line(Vector2(c.x - 6.5, c.y - 3.5), Vector2(c.x - 4.0, c.y - 1.0), col, 1.2, true)
			"fuel_tanks":
				# Minimalist fuel drum / canister with X-rib
				draw_rect(Rect2(c.x - 6.0, c.y - 6.5, 12.0, 14.0), col, false, lw)
				draw_rect(Rect2(c.x - 3.0, c.y - 9.0, 6.0, 2.5), col, true)
				draw_line(Vector2(c.x - 4.0, c.y - 3.5), Vector2(c.x + 4.0, c.y + 4.5), col, 1.3, true)
				draw_line(Vector2(c.x + 4.0, c.y - 3.5), Vector2(c.x - 4.0, c.y + 4.5), col, 1.3, true)
			"engine":
				# Minimalist engine gear / piston block
				var r_out := 6.8
				var r_in := 3.2
				draw_arc(c, r_out - 1.5, 0.0, TAU, 16, col, 2.0, true)
				draw_arc(c, r_in, 0.0, TAU, 12, col, 1.3, true)
				for ti in range(6):
					var a := float(ti) * (TAU / 6.0)
					var p0 := c + Vector2(cos(a), sin(a)) * (r_out - 1.5)
					var p1 := c + Vector2(cos(a), sin(a)) * (r_out + 2.2)
					draw_line(p0, p1, col, 2.4, true)

var crew_slots: Dictionary = {} # key -> {"panel", "icon", "lbl", "style"}
var mod_slots: Dictionary = {}  # key -> {"panel", "icon", "lbl", "style"}
var mod_divider: ColorRect = null
var mod_grid: HBoxContainer = null
var root_box: Control = null

var destroyed_overlay: Panel = null
var destroyed_label: Label = null
var is_destroyed_flashing: bool = false
var flash_timer: float = 0.0
var destroy_hide_timer: float = 0.0

func _ready() -> void:
	name = "TigerBossHUD"
	visible = false
	_build_ui()

func _build_ui() -> void:
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = Color(0.05, 0.06, 0.07, 0.84)
	root_style.border_width_left = 2
	root_style.border_width_top = 1
	root_style.border_width_right = 1
	root_style.border_width_bottom = 1
	root_style.border_color = Color(0.74, 0.78, 0.82, 0.45)
	root_style.content_margin_left = 8.0
	root_style.content_margin_right = 8.0
	root_style.content_margin_top = 6.0
	root_style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", root_style)

	root_box = Control.new()
	root_box.custom_minimum_size = Vector2(248, 66)
	add_child(root_box)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	root_box.add_child(vbox)

	# Minimalist single-line header
	var title := Label.new()
	title.text = "TIGER I"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.76, 0.80, 0.85))
	vbox.add_child(title)

	# 5 Crew Vector Icons (compact minimalist row)
	var crew_row := HBoxContainer.new()
	crew_row.add_theme_constant_override("separation", 4)
	vbox.add_child(crew_row)

	var crew_defs := [
		["driver", "ВОД"],
		["radio", "РАД"],
		["loader", "ЗАР"],
		["gunner", "НАВ"],
		["commander", "КОМ"],
	]
	for cd in crew_defs:
		var slot := _create_icon_slot(cd[0], cd[1], Color(0.94, 0.96, 0.98))
		crew_row.add_child(slot["panel"])
		crew_slots[cd[0]] = slot

	# Thin hairline separator + Modules row (hidden until any module takes damage!)
	mod_divider = ColorRect.new()
	mod_divider.custom_minimum_size = Vector2(0, 1)
	mod_divider.color = Color(0.65, 0.70, 0.76, 0.25)
	mod_divider.visible = false
	vbox.add_child(mod_divider)

	mod_grid = HBoxContainer.new()
	mod_grid.add_theme_constant_override("separation", 4)
	mod_grid.visible = false
	vbox.add_child(mod_grid)

	var mod_defs := [
		["coax_mg", "ПУЛ"],
		["optics", "ОПТ"],
		["fuel_tanks", "БАКИ"],
		["engine", "ДВИГ"],
	]
	for md in mod_defs:
		var mslot := _create_icon_slot(md[0], md[1], Color(1.0, 0.94, 0.58))
		mslot["panel"].visible = false
		mod_grid.add_child(mslot["panel"])
		mod_slots[md[0]] = mslot

	# Minimalist Destroyed Flashing Overlay
	destroyed_overlay = Panel.new()
	destroyed_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	destroyed_overlay.visible = false
	var ov_style := StyleBoxFlat.new()
	ov_style.bg_color = Color(0.06, 0.03, 0.03, 0.94)
	ov_style.border_width_left = 2
	ov_style.border_width_top = 1
	ov_style.border_width_right = 1
	ov_style.border_width_bottom = 1
	ov_style.border_color = Color(0.96, 0.28, 0.20, 0.95)
	destroyed_overlay.add_theme_stylebox_override("panel", ov_style)
	root_box.add_child(destroyed_overlay)

	destroyed_label = Label.new()
	destroyed_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	destroyed_label.text = "TIGER УНИЧТОЖЕН"
	destroyed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	destroyed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	destroyed_label.add_theme_font_size_override("font_size", 18)
	destroyed_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.22))
	destroyed_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	destroyed_label.add_theme_constant_override("outline_size", 4)
	destroyed_overlay.add_child(destroyed_label)

func _create_icon_slot(itype: String, short_name: String, initial_col: Color) -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(44, 38)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.10, 0.12, 0.88)
	st.border_width_left = 1
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = Color(initial_col.r, initial_col.g, initial_col.b, 0.45)
	st.content_margin_left = 3.0
	st.content_margin_right = 3.0
	st.content_margin_top = 2.0
	st.content_margin_bottom = 2.0
	p.add_theme_stylebox_override("panel", st)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 1)
	p.add_child(vb)

	var center := CenterContainer.new()
	vb.add_child(center)

	var ic := DynamicVectorIcon.new(itype, initial_col)
	center.add_child(ic)

	var lb := Label.new()
	lb.text = short_name
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", 9)
	lb.add_theme_color_override("font_color", initial_col)
	vb.add_child(lb)

	return {"panel": p, "icon": ic, "lbl": lb, "style": st}

static func _damage_ratio_to_color(hp_ratio: float) -> Color:
	# Smooth dynamic color curve: 1.0 = white, 0.65 = light yellow, 0.35 = orange/red, 0.0 = black
	var r := clampf(hp_ratio, 0.0, 1.0)
	if r <= 0.001:
		return Color(0.11, 0.11, 0.13)
	if r > 0.65:
		return Color(1.0, 0.92, 0.42).lerp(Color(0.94, 0.96, 0.98), (r - 0.65) / 0.35)
	elif r > 0.30:
		return Color(0.96, 0.24, 0.16).lerp(Color(1.0, 0.92, 0.42), (r - 0.30) / 0.35)
	else:
		return Color(0.55, 0.10, 0.08).lerp(Color(0.96, 0.24, 0.16), r / 0.30)

func show_for_boss() -> void:
	visible = true
	is_destroyed_flashing = false
	destroy_hide_timer = 0.0
	if destroyed_overlay:
		destroyed_overlay.visible = false
	for k in crew_slots.keys():
		set_crew_color(k, Color(0.94, 0.96, 0.98))
	for mk in mod_slots.keys():
		mod_slots[mk]["panel"].visible = false
	if mod_divider:
		mod_divider.visible = false
	if mod_grid:
		mod_grid.visible = false
	if root_box:
		root_box.custom_minimum_size.y = 66.0

func set_crew_color(crew_id: String, col: Color) -> void:
	if not crew_slots.has(crew_id):
		return
	var slot: Dictionary = crew_slots[crew_id]
	(slot["icon"] as DynamicVectorIcon).set_icon_color(col)
	var is_black: bool = (col.r + col.g + col.b) < 0.45
	slot["lbl"].add_theme_color_override("font_color", Color(0.45, 0.46, 0.50) if is_black else col)
	var st: StyleBoxFlat = slot["style"]
	st.bg_color = Color(0.03, 0.03, 0.04, 0.96) if is_black else Color(0.09, 0.10, 0.12, 0.88)
	st.border_color = Color(0.36, 0.14, 0.14, 0.75) if is_black else Color(col.r, col.g, col.b, 0.55)

func update_boss_state(state: Dictionary) -> void:
	if not visible:
		show_for_boss()

	# 1. Dynamic crew colors (damaged white->yellow->red, burning white->yellow->red->black, dead black)
	var crew_colors: Dictionary = state.get("crew_colors", {})
	for cid in crew_colors.keys():
		set_crew_color(cid, crew_colors[cid])

	# 2. Damaged / destroyed modules (hidden while 100% intact; dynamic color from damage!)
	var any_mod_visible := false

	var coax_ratio: float = float(state.get("coax_hp_ratio", 0.0 if bool(state.get("coax_destroyed", false)) else 1.0))
	var coax_dead: bool = bool(state.get("coax_destroyed", false))
	var show_coax: bool = coax_dead or coax_ratio < 0.99
	mod_slots["coax_mg"]["panel"].visible = show_coax
	if show_coax:
		any_mod_visible = true
		var c_col := Color(0.11, 0.11, 0.13) if coax_dead else _damage_ratio_to_color(coax_ratio)
		_set_mod_color("coax_mg", c_col, Color(0.85, 0.22, 0.18) if coax_dead else c_col, "ПУЛ")

	var opt_ratio: float = float(state.get("optics_hp_ratio", 0.0 if bool(state.get("optics_destroyed", false)) else 1.0))
	var opt_dead: bool = bool(state.get("optics_destroyed", false))
	var show_opt: bool = opt_dead or opt_ratio < 0.99
	mod_slots["optics"]["panel"].visible = show_opt
	if show_opt:
		any_mod_visible = true
		var o_col := Color(0.11, 0.11, 0.13) if opt_dead else _damage_ratio_to_color(opt_ratio)
		_set_mod_color("optics", o_col, Color(0.85, 0.22, 0.18) if opt_dead else o_col, "ОПТ")

	# Attached fuel tanks: hidden until 1st of 4 destroyed!
	# Exact progression: 1 = light yellow, 2 = yellow, 3 = red, 4 = black!
	var tanks_dead: int = int(state.get("fuel_tanks_destroyed", 0))
	mod_slots["fuel_tanks"]["panel"].visible = (tanks_dead > 0)
	if tanks_dead > 0:
		any_mod_visible = true
		var tc := Color(1.0, 0.96, 0.62) # 1: light yellow
		var tb := Color(0.95, 0.90, 0.52)
		if tanks_dead == 2:
			tc = Color(1.0, 0.80, 0.12) # 2: yellow
			tb = Color(1.0, 0.78, 0.15)
		elif tanks_dead == 3:
			tc = Color(0.96, 0.22, 0.16) # 3: red
			tb = Color(0.96, 0.22, 0.16)
		elif tanks_dead >= 4:
			tc = Color(0.11, 0.11, 0.13) # 4: black
			tb = Color(0.85, 0.22, 0.18)
		_set_mod_color("fuel_tanks", tc, tb, "БАКИ %d/4" % tanks_dead)

	# Engine: hidden until damaged/grille hit; dynamic color yellow -> red -> black!
	var grilles_dead: int = int(state.get("grilles_destroyed", 0))
	var eng_ratio: float = float(state.get("engine_hp_ratio", 1.0))
	var engine_dead: bool = bool(state.get("engine_destroyed", false))
	var engine_burning: bool = bool(state.get("engine_burning", false))
	var show_eng: bool = (grilles_dead > 0) or engine_dead or engine_burning or (eng_ratio < 0.99)
	mod_slots["engine"]["panel"].visible = show_eng
	if show_eng:
		any_mod_visible = true
		if engine_burning:
			_set_mod_color("engine", Color(0.11, 0.11, 0.13), Color(1.0, 0.34, 0.12), "ДВИГ")
		elif engine_dead:
			_set_mod_color("engine", Color(0.96, 0.22, 0.16), Color(0.96, 0.22, 0.16), "ДВИГ")
		else:
			var e_col := _damage_ratio_to_color(minf(eng_ratio, 0.72))
			_set_mod_color("engine", e_col, e_col, "ДВИГ")

	if mod_divider:
		mod_divider.visible = any_mod_visible
	if mod_grid:
		mod_grid.visible = any_mod_visible
	if root_box:
		root_box.custom_minimum_size.y = 112.0 if any_mod_visible else 66.0

func _set_mod_color(mod_id: String, fg_col: Color, border_col: Color, label_txt: String) -> void:
	var slot: Dictionary = mod_slots[mod_id]
	var is_black: bool = (fg_col.r + fg_col.g + fg_col.b) < 0.45
	(slot["icon"] as DynamicVectorIcon).set_icon_color(Color(0.24, 0.24, 0.28) if is_black else fg_col)
	slot["lbl"].text = label_txt
	slot["lbl"].add_theme_color_override("font_color", Color(0.76, 0.28, 0.22) if is_black else fg_col)
	var st: StyleBoxFlat = slot["style"]
	st.bg_color = Color(0.03, 0.03, 0.04, 0.96) if is_black else Color(0.09, 0.10, 0.12, 0.88)
	st.border_color = Color(border_col.r, border_col.g, border_col.b, 0.80)

func show_tiger_destroyed() -> void:
	visible = true
	is_destroyed_flashing = true
	flash_timer = 0.0
	destroy_hide_timer = 9.0
	if destroyed_overlay:
		destroyed_overlay.visible = true
	var beep := AudioStreamPlayer.new()
	beep.bus = "SFX"
	beep.stream = SoundEffects.create_tiger_destroyed_beep_sound()
	beep.volume_db = 1.0
	add_child(beep)
	beep.play()
	beep.finished.connect(beep.queue_free)

func _process(delta: float) -> void:
	if is_destroyed_flashing:
		flash_timer += delta * 7.5
		if destroyed_label:
			var pulse: float = 0.5 + 0.5 * sin(flash_timer)
			destroyed_label.modulate = Color(1.0, 0.35 + 0.65 * pulse, 0.25 + 0.65 * pulse, 0.35 + 0.65 * pulse)
		destroy_hide_timer -= delta
		if destroy_hide_timer <= 0.0:
			is_destroyed_flashing = false
			visible = false
