class_name WeaponModDB
extends RefCounted

const WeaponModScript = preload("res://scripts/weapons/weapon_mod.gd")

static var _mods: Dictionary = {}
static var _initialized: bool = false

# Slot definitions per weapon_id.
# Each entry defines:
# - "slot_type": unique slot key on the weapon
# - "label": short EFT square slot title
# - "ui_pos": normalized (0..1, 0..1) visual anchor over the 3D weapon preview
# - "is_vital": if true, weapon cannot fire when this slot is empty
# - "can_remove": if true, player can strip this slot completely (e.g. AK-47 without dust cover!)
# - "requires_mods": optional array of mod IDs required for this slot to be unlocked
static func get_slot_defs(weapon_id: String) -> Array[Dictionary]:
	match weapon_id:
		"ak47":
			return [
				{
					"slot_type": "dust_cover",
					"label": "КРЫШКА СК",
					"ui_pos": Vector2(0.56, 0.24),
					"is_vital": false,
					"can_remove": true,
					"requires_mods": []
				},
				{
					"slot_type": "optic",
					"label": "ПРИЦЕЛ",
					"ui_pos": Vector2(0.56, 0.08),
					"is_vital": false,
					"can_remove": true,
					"requires_mods": ["ak_cover_picatinny"]
				}
			]
		_:
			return []

static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_mods.clear()
	
	# ==========================================
	# AK-47 DUST COVERS (КРЫШКИ СТВОЛЬНОЙ КОРОБКИ)
	# ==========================================
	_register({
		"id": "ak_cover_std",
		"name": "Штатная крышка СК АК-47",
		"short_name": "ШТАТНАЯ СК",
		"description": "Стандартная штампованная стальная крышка ствольной коробки АК-47 с ребрами жесткости. Защищает затворную группу, но не имеет крепления для оптики.",
		"slot_type": "dust_cover",
		"price": 0,
		"compatible_weapons": ["ak47"],
		"is_vanilla_default": true
	})
	
	_register({
		"id": "ak_cover_picatinny",
		"name": "Крышка СК с планкой Пикатинни",
		"short_name": "ПИКАТИННИ",
		"description": "Тактическая крышка ствольной коробки (Бастион / ТВС) с интегрированной верхней планкой Пикатинни 20 мм. Открывает слот установки коллиматорных и оптических прицелов.",
		"slot_type": "dust_cover",
		"price": 0,
		"compatible_weapons": ["ak47"],
		"recoil_pitch_mult": 0.97,
		"recoil_yaw_mult": 0.97,
		"ergonomics_add": 2.0,
		"provides_slots": ["optic"]
	})
	
	# ==========================================
	# AK-47 OPTICS (ПРИЦЕЛЫ — ТРЕБУЮТ ПЛАНКУ ПИКАТИННИ)
	# ==========================================
	_register({
		"id": "optic_red_dot",
		"name": "Коллиматорный прицел EOTech / ОКП",
		"short_name": "КОЛЛИМАТОР",
		"description": "Открытый голографический коллиматор с яркой красной прицельной маркой 1x. Позволяет переходить в точное прицеливание на ПКМ без искажения обзора и заметно снижает разброс.",
		"slot_type": "optic",
		"price": 0,
		"compatible_weapons": ["ak47"],
		"requires_mods": ["ak_cover_picatinny"],
		"spread_mult": 0.78,
		"recoil_pitch_mult": 0.94,
		"recoil_yaw_mult": 0.94,
		"ergonomics_add": 4.0,
		"mechanics": {
			"ads_enabled": true,
			"ads_zoom_min": 1.0,
			"ads_zoom_max": 1.0,
			"ads_reticle": "red_dot"
		}
	})
	
	_register({
		"id": "optic_lpvo",
		"name": "Оптический прицел LPVO 1.5x–4x",
		"short_name": "LPVO 1.5-4x",
		"description": "Тактический прицел переменной кратности (1.5x–4.0x). Нажмите ПКМ для прицеливания и крутите колесико мыши для плавного изменения приближения! Высокая точность на средних и дальних дистанциях.",
		"slot_type": "optic",
		"price": 0,
		"compatible_weapons": ["ak47"],
		"requires_mods": ["ak_cover_picatinny"],
		"spread_mult": 0.62,
		"recoil_pitch_mult": 0.90,
		"recoil_yaw_mult": 0.90,
		"ergonomics_add": -3.0,
		"mechanics": {
			"ads_enabled": true,
			"ads_zoom_min": 1.5,
			"ads_zoom_max": 4.0,
			"ads_reticle": "lpvo_crosshair"
		}
	})

static func _register(cfg: Dictionary) -> void:
	var m = WeaponModScript.make(cfg)
	_mods[m.id] = m

static func get_mod(mod_id: String) -> RefCounted:
	_ensure_init()
	if mod_id == "":
		return null
	return _mods.get(mod_id, null)

static func get_mods_for_slot(weapon_id: String, slot_type: String) -> Array:
	_ensure_init()
	var result: Array = []
	for m in _mods.values():
		if m.slot_type == slot_type and weapon_id in m.compatible_weapons:
			result.append(m)
	return result

static func is_mod_installed(installed_mods: Dictionary, mod_id: String) -> bool:
	for v in installed_mods.values():
		if str(v) == mod_id:
			return true
	return false

static func get_missing_requirements(installed_mods: Dictionary, req_list: Array) -> Array[String]:
	_ensure_init()
	var missing: Array[String] = []
	for req_id in req_list:
		var r_str := str(req_id)
		if not is_mod_installed(installed_mods, r_str):
			var rm := get_mod(r_str)
			missing.append(rm.name if rm else r_str)
	return missing

static func is_slot_unlocked(installed_mods: Dictionary, slot_def: Dictionary) -> bool:
	var reqs: Array = slot_def.get("requires_mods", [])
	return get_missing_requirements(installed_mods, reqs).is_empty()

static func can_install_mod(installed_mods: Dictionary, mod_id: String) -> Dictionary:
	_ensure_init()
	if mod_id == "":
		return {"ok": true, "reason": ""}
	var m := get_mod(mod_id)
	if not m:
		return {"ok": false, "reason": "Модификация не найдена"}
	var missing := get_missing_requirements(installed_mods, m.requires_mods)
	if missing.size() > 0:
		return {"ok": false, "reason": "Требуется: " + ", ".join(missing)}
	for conf_id in m.conflicts_with:
		if is_mod_installed(installed_mods, conf_id):
			var cm := get_mod(conf_id)
			return {"ok": false, "reason": "Конфликт с: " + (cm.name if cm else conf_id)}
	return {"ok": true, "reason": ""}

# Removes any installed mods whose requirements are no longer satisfied (e.g. removing Picatinny cover strips the optic)
static func cleanup_invalid_mods(installed_mods: Dictionary) -> Array[String]:
	_ensure_init()
	var removed: Array[String] = []
	var changed := true
	while changed:
		changed = false
		for slot_key in installed_mods.keys():
			var mid := str(installed_mods[slot_key])
			if mid == "":
				continue
			var m := get_mod(mid)
			if m and not get_missing_requirements(installed_mods, m.requires_mods).is_empty():
				installed_mods[slot_key] = ""
				removed.append(mid)
				changed = true
	return removed
