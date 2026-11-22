class_name Weapon
extends RefCounted

const WeaponModDBScript = preload("res://scripts/weapons/weapon_mod_db.gd")

var weapon_id: String = "ak47"
var name: String = "Weapon"
var slot: int = 1 # Dynamically assigned (1..3 for active firearm slots, 0 if in stash, 99 for melee)

# Base (unmodified) stats
var base_damage: float = 30.0
var base_fire_rate: float = 0.12
var base_mag_size: int = 30
var base_reload_time: float = 2.0
var base_spread: float = 0.015
var base_recoil_pitch: float = 0.03
var base_recoil_yaw: float = 0.01
var base_ergonomics: float = 55.0

# Effective (post-modification) stats
var damage: float = 30.0
var fire_rate: float = 0.12 # seconds between shots
var is_automatic: bool = true
var mag_size: int = 30
var current_ammo: int = 30
var reserve_ammo: int = 180
var reload_time: float = 2.0
var pellets: int = 1
var spread: float = 0.015
var has_falloff: bool = false
var falloff_min_dist: float = 5.0
var falloff_max_dist: float = 20.0
var min_damage_mult: float = 0.25
var recoil_pitch: float = 0.03
var recoil_yaw: float = 0.01
var ergonomics: float = 55.0

# Weapon type flags
var has_round_in_chamber: bool = true
var is_shotgun: bool = false
var is_rpg: bool = false
var is_melee: bool = false

# Modification system state
var installed_mods: Dictionary = {} # slot_type (String) -> mod_id (String, "" if empty)
var owned_mods: Dictionary = {} # mod_id (String) -> true (vanilla defaults start owned)
var active_mechanics: Dictionary = {} # Aggregated mechanic flags from installed mods

func is_mod_owned(mod_id: String) -> bool:
	if mod_id == "":
		return true
	if owned_mods.has(mod_id):
		return true
	var m = WeaponModDBScript.get_mod(mod_id)
	return m != null and m.is_vanilla_default

func mark_mod_owned(mod_id: String) -> void:
	if mod_id != "":
		owned_mods[mod_id] = true

func get_max_reload_capacity() -> int:
	if is_rpg:
		return 1
	if is_shotgun:
		if not has_round_in_chamber or current_ammo == 0:
			return mag_size
		return mag_size + 1
	if has_round_in_chamber and current_ammo > 0:
		return mag_size + 1
	return mag_size

func can_fire() -> bool:
	var slot_defs: Array[Dictionary] = WeaponModDBScript.get_slot_defs(weapon_id)
	for sd in slot_defs:
		if sd.get("is_vital", false):
			var st: String = sd["slot_type"]
			if str(installed_mods.get(st, "")) == "":
				return false
	return true

func has_mechanic(key: String) -> bool:
	return bool(active_mechanics.get(key, false))

func get_ads_zoom_range() -> Vector2:
	if not has_mechanic("ads_enabled"):
		return Vector2(1.0, 1.0)
	var zmin: float = float(active_mechanics.get("ads_zoom_min", 1.25))
	var zmax: float = float(active_mechanics.get("ads_zoom_max", zmin))
	return Vector2(zmin, maxf(zmin, zmax))

func get_installed_mod_count() -> int:
	var count := 0
	for k in installed_mods.keys():
		var mid := str(installed_mods[k])
		if mid != "":
			var m = WeaponModDBScript.get_mod(mid)
			if m and not m.is_vanilla_default:
				count += 1
	return count

func compute_stats_for_mods(test_mods: Dictionary) -> Dictionary:
	var dmg_add := 0.0
	var dmg_mult := 1.0
	var fr_mult := 1.0
	var sp_mult := 1.0
	var rp_mult := 1.0
	var ry_mult := 1.0
	var mag_add := 0
	var rel_mult := 1.0
	var ergo_add := 0.0
	var mech: Dictionary = {}
	
	# Slight ergonomics bonus if non-vital dust cover is stripped (lighter weapon)
	if weapon_id == "ak47" and str(test_mods.get("dust_cover", "")) == "":
		ergo_add += 3.0
		rp_mult *= 1.03
		
	for st in test_mods.keys():
		var mid := str(test_mods[st])
		if mid == "":
			continue
		var m = WeaponModDBScript.get_mod(mid)
		if not m:
			continue
		dmg_add += m.damage_add
		dmg_mult *= m.damage_mult
		fr_mult *= m.fire_rate_mult
		sp_mult *= m.spread_mult
		rp_mult *= m.recoil_pitch_mult
		ry_mult *= m.recoil_yaw_mult
		mag_add += m.mag_size_add
		rel_mult *= m.reload_time_mult
		ergo_add += m.ergonomics_add
		for mk in m.mechanics.keys():
			mech[mk] = m.mechanics[mk]
			
	var eff_dmg := maxf(1.0, (base_damage + dmg_add) * dmg_mult)
	var eff_fr := maxf(0.03, base_fire_rate * fr_mult)
	var eff_sp := maxf(0.001, base_spread * sp_mult)
	var eff_rp := maxf(0.003, base_recoil_pitch * rp_mult)
	var eff_ry := maxf(0.001, base_recoil_yaw * ry_mult)
	var eff_mag := maxi(1, base_mag_size + mag_add)
	var eff_rel := maxf(0.3, base_reload_time * rel_mult)
	var eff_ergo := clampf(base_ergonomics + ergo_add, 5.0, 100.0)
	var zoom_max := float(mech.get("ads_zoom_max", 1.0)) if bool(mech.get("ads_enabled", false)) else 1.0
	var zoom_min := float(mech.get("ads_zoom_min", 1.0)) if bool(mech.get("ads_enabled", false)) else 1.0
	
	return {
		"damage": eff_dmg,
		"fire_rate": eff_fr,
		"rpm": 60.0 / eff_fr,
		"spread": eff_sp,
		"accuracy": clampf(100.0 - eff_sp * 1900.0, 10.0, 99.0),
		"recoil_pitch": eff_rp,
		"recoil_yaw": eff_ry,
		"recoil_control": clampf(100.0 - eff_rp * 600.0, 10.0, 99.0),
		"mag_size": eff_mag,
		"reload_time": eff_rel,
		"ergonomics": eff_ergo,
		"zoom_min": zoom_min,
		"zoom_max": zoom_max,
		"mechanics": mech
	}

func recalculate_stats() -> void:
	var st := compute_stats_for_mods(installed_mods)
	damage = st["damage"]
	fire_rate = st["fire_rate"]
	spread = st["spread"]
	recoil_pitch = st["recoil_pitch"]
	recoil_yaw = st["recoil_yaw"]
	mag_size = st["mag_size"]
	reload_time = st["reload_time"]
	ergonomics = st["ergonomics"]
	active_mechanics = st["mechanics"]
	if current_ammo > get_max_reload_capacity():
		current_ammo = get_max_reload_capacity()

func install_mod(slot_type: String, mod_id: String) -> Dictionary:
	var test_mods := installed_mods.duplicate(true)
	test_mods[slot_type] = mod_id
	if mod_id != "":
		var check: Dictionary = WeaponModDBScript.can_install_mod(test_mods, mod_id)
		if not check["ok"]:
			return check
			
	var prev_id := str(installed_mods.get(slot_type, ""))
	installed_mods[slot_type] = mod_id
	
	# Handle mechanics that clear ammo on ammo-type change
	if mod_id != prev_id and mod_id != "":
		var m = WeaponModDBScript.get_mod(mod_id)
		if m and bool(m.mechanics.get("clears_ammo_on_change", false)):
			current_ammo = 0
			reserve_ammo = 0
			has_round_in_chamber = false
			
	# Strip any child mods whose dependencies are no longer met (e.g. optic if Picatinny removed)
	var removed := WeaponModDBScript.cleanup_invalid_mods(installed_mods)
	recalculate_stats()
	return {"ok": true, "removed": removed}

func _finalize_base_stats() -> void:
	base_damage = damage
	base_fire_rate = fire_rate
	base_mag_size = mag_size
	base_reload_time = reload_time
	base_spread = spread
	base_recoil_pitch = recoil_pitch
	base_recoil_yaw = recoil_yaw
	base_ergonomics = ergonomics
	# Vanilla starting mods are immediately considered purchased/owned
	for slot_key in installed_mods.keys():
		var mid := str(installed_mods[slot_key])
		if mid != "":
			owned_mods[mid] = true
	recalculate_stats()

static func create_ak47() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "ak47"
	w.name = "AK-47"
	w.slot = 1
	w.damage = 32.0
	w.fire_rate = 0.11
	w.is_automatic = true
	w.mag_size = 30
	w.current_ammo = 30
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.reserve_ammo = 180
	w.reload_time = 2.2
	w.pellets = 1
	w.spread = 0.018
	w.has_falloff = false
	w.recoil_pitch = 0.035
	w.recoil_yaw = 0.015
	w.ergonomics = 55.0
	w.installed_mods = {
		"dust_cover": "ak_cover_std",
		"optic": ""
	}
	w._finalize_base_stats()
	return w

static func create_shotgun() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "shotgun"
	w.name = "Pump Shotgun"
	w.slot = 2
	w.damage = 18.0
	w.fire_rate = 0.85
	w.is_automatic = false
	w.mag_size = 5
	w.current_ammo = 5
	w.has_round_in_chamber = true
	w.is_shotgun = true
	w.reserve_ammo = 35
	w.reload_time = 0.85
	w.pellets = 8
	w.spread = 0.075
	w.has_falloff = true
	w.falloff_min_dist = 4.0
	w.falloff_max_dist = 18.0
	w.min_damage_mult = 0.2
	w.recoil_pitch = 0.10
	w.recoil_yaw = 0.02
	w.ergonomics = 48.0
	w._finalize_base_stats()
	return w

static func create_pistol() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "pistol"
	w.name = "Pistol"
	w.slot = 3
	w.damage = 26.0
	w.fire_rate = 0.075
	w.is_automatic = false
	w.mag_size = 17
	w.current_ammo = 17
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.reserve_ammo = 85
	w.reload_time = 1.6
	w.pellets = 1
	w.spread = 0.008
	w.has_falloff = false
	w.recoil_pitch = 0.025
	w.recoil_yaw = 0.008
	w.ergonomics = 82.0
	w._finalize_base_stats()
	return w

static func create_rpg() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "rpg"
	w.name = "RPG-7"
	w.slot = 0 # Starts in arsenal/stash when purchased, equippable into slots 1..3
	w.damage = 320.0
	w.fire_rate = 1.0
	w.is_automatic = false
	w.mag_size = 1
	w.current_ammo = 1
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.is_rpg = true
	w.reserve_ammo = 0 # Comes with 1 loaded PG-7V warhead; extra rockets cost $100
	w.reload_time = 2.6
	w.pellets = 1
	w.spread = 0.004
	w.has_falloff = false
	w.recoil_pitch = 0.16
	w.recoil_yaw = 0.025
	w.ergonomics = 32.0
	w._finalize_base_stats()
	return w

static func create_knife() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "knife"
	w.name = "Штыковой нож"
	w.slot = 99
	w.damage = 70.0
	w.fire_rate = 0.55
	w.is_automatic = false
	w.mag_size = 1
	w.current_ammo = 1
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.is_melee = true
	w.reserve_ammo = 0
	w.reload_time = 0.1
	w.pellets = 1
	w.spread = 0.0
	w.has_falloff = false
	w.recoil_pitch = 0.0
	w.recoil_yaw = 0.0
	w.ergonomics = 95.0
	w._finalize_base_stats()
	return w
