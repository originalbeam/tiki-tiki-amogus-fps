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
var base_pellets: int = 1
var base_has_falloff: bool = false
var base_fire_modes: Array = ["semi"]

# Fire mode & tactical attachment runtime state
var available_fire_modes: Array = ["semi"] # e.g. ["auto", "semi"] or ["auto", "burst", "semi"]
var current_fire_mode: String = "semi"
var ugl_ammo: int = 0
var ugl_reserve: int = 0
var laser_enabled: bool = true
var flashlight_enabled: bool = false

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
var ammo_type: String = "762x39" # Shared caliber pool ID ("762x39", "12ga", "9x19", "pg7v", "792x57", "762x54r", "338lm", "50ae", "")
var has_round_in_chamber: bool = true
var is_shotgun: bool = false
var is_bolt_action: bool = false
var is_belt_fed: bool = false
var is_rpg: bool = false
var is_melee: bool = false

# Modification system state
var installed_mods: Dictionary = {} # slot_type (String) -> mod_id (String, "" if empty)
var owned_mods: Dictionary = {} # mod_id (String) -> true (vanilla defaults start owned)
var active_mechanics: Dictionary = {} # Aggregated mechanic flags from installed mods
var saved_ads_zoom: float = -1.0 # Persisted player-chosen ADS magnification for this weapon (-1 = use optic default)

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

func can_switch_fire_mode() -> bool:
	return available_fire_modes.size() > 1

func cycle_fire_mode() -> String:
	if available_fire_modes.size() <= 1:
		return current_fire_mode
	var idx: int = available_fire_modes.find(current_fire_mode)
	idx = (idx + 1) % available_fire_modes.size()
	current_fire_mode = available_fire_modes[idx]
	is_automatic = (current_fire_mode == "auto")
	return current_fire_mode

func get_fire_mode_label() -> String:
	match current_fire_mode:
		"auto":
			return "АВТО"
		"burst":
			return "ОЧЕРЕДЬ x3"
		"semi":
			return "ОДИН."
	return ""

func get_installed_mod_count() -> int:
	var count := 0
	for k in installed_mods.keys():
		var mid := str(installed_mods[k])
		if mid != "":
			var m = WeaponModDBScript.get_mod(mid)
			if m and not m.is_vanilla_default:
				count += 1
	return count

static func get_default_ammo_mod_id(caliber: String) -> String:
	match caliber:
		"762x39": return "ammo_762x39_fmj"
		"12ga": return "ammo_12ga_buck"
		"9x19": return "ammo_9x19_fmj"
		"pg7v": return "ammo_rpg_pg7v"
		"792x57": return "ammo_792_ss"
		"762x54r": return "ammo_762x54r_lps"
		"338lm": return "ammo_338_match"
		"50ae": return "ammo_50ae_jhp"
	return caliber

func get_active_ammo_pool_key() -> String:
	if ammo_type == "":
		return ""
	var mod_id: String = str(installed_mods.get("ammo_type", ""))
	if mod_id != "":
		return mod_id
	return Weapon.get_default_ammo_mod_id(ammo_type)

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
	
	# Realistic penalties / ergo bonuses when vanilla components are stripped ("Пусто" / "")
	if weapon_id == "ak47" and str(test_mods.get("dust_cover", "")) == "":
		ergo_add += 3.0
		rp_mult *= 1.03
	if weapon_id in ["ak47", "shotgun", "kar98k", "pkm", "l96a1", "mg42"] and str(test_mods.get("stock_adapter", "")) == "":
		ergo_add += 14.0
		rp_mult *= 1.32
		ry_mult *= 1.38
		sp_mult *= 1.25
	if weapon_id in ["ak47", "pkm", "l96a1", "mg42", "aa12"] and str(test_mods.get("muzzle", "")) == "":
		ergo_add += 3.0
		rp_mult *= 1.12
		ry_mult *= 1.10
	if weapon_id in ["ak47", "kar98k", "l96a1", "aa12"] and str(test_mods.get("handguard", "")) == "":
		ergo_add += 6.0
		rp_mult *= 1.10
		ry_mult *= 1.10
		sp_mult *= 1.12
	if weapon_id in ["ak47", "pkm", "deagle", "pistol"] and str(test_mods.get("pistol_grip", "")) == "":
		ergo_add -= 10.0
		rp_mult *= 1.14
		ry_mult *= 1.16
	if weapon_id in ["l96a1", "rpg"] and str(test_mods.get("optic", "")) == "":
		ergo_add += 8.0
		
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
			
	# All firearms support aiming down sights (iron sights when no optic is mounted!)
	if not is_melee and not bool(mech.get("ads_enabled", false)):
		mech["ads_enabled"] = true
		mech["ads_zoom_min"] = 1.0
		mech["ads_zoom_max"] = 1.0
		mech["ads_reticle"] = "iron_sights"
			
	var eff_dmg := maxf(1.0, (base_damage + dmg_add) * dmg_mult)
	var eff_fr := maxf(0.03, base_fire_rate * fr_mult)
	var eff_sp := maxf(0.001, base_spread * sp_mult)
	var eff_rp := maxf(0.003, base_recoil_pitch * rp_mult)
	var eff_ry := maxf(0.001, base_recoil_yaw * ry_mult)
	var eff_mag := maxi(1, base_mag_size + mag_add)
	var eff_rel := maxf(0.3, base_reload_time * rel_mult)
	var eff_ergo := clampf(base_ergonomics + ergo_add, 5.0, 100.0)
	var eff_pellets: int = int(mech.get("pellets_override", base_pellets))
	var eff_falloff: bool = bool(mech.get("has_falloff_override", base_has_falloff))
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
		"pellets": eff_pellets,
		"has_falloff": eff_falloff,
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
	pellets = st["pellets"]
	has_falloff = st["has_falloff"]
	active_mechanics = st["mechanics"]
	
	# Recompute available fire modes (factory modes + any unlocked by internal mods)
	available_fire_modes.clear()
	for fm in base_fire_modes:
		if not (fm in available_fire_modes):
			available_fire_modes.append(fm)
	if active_mechanics.has("unlock_fire_modes"):
		for fm in active_mechanics["unlock_fire_modes"]:
			var fms := str(fm)
			if not (fms in available_fire_modes):
				available_fire_modes.append(fms)
	if available_fire_modes.is_empty():
		available_fire_modes.append("auto" if is_automatic else "semi")
	if not (current_fire_mode in available_fire_modes):
		current_fire_mode = available_fire_modes[0]
	is_automatic = (current_fire_mode == "auto")
	
	# If UGL just installed and has 0 grenades, provide starter 1+5 40mm grenades!
	if has_mechanic("underbarrel_grenade_launcher") and ugl_ammo == 0 and ugl_reserve == 0:
		ugl_ammo = 1
		ugl_reserve = 5
	
	if saved_ads_zoom > 0.0:
		var zr := get_ads_zoom_range()
		if saved_ads_zoom < zr.x - 0.01 or saved_ads_zoom > zr.y + 0.01:
			saved_ads_zoom = -1.0
	if current_ammo > get_max_reload_capacity():
		current_ammo = get_max_reload_capacity()

func install_mod(slot_type: String, mod_id: String) -> Dictionary:
	var test_mods := installed_mods.duplicate(true)
	test_mods[slot_type] = mod_id
	if mod_id != "":
		for sd in WeaponModDBScript.get_slot_defs(weapon_id):
			if sd.get("slot_type", "") == slot_type:
				if not WeaponModDBScript.is_slot_unlocked(installed_mods, sd):
					return {"ok": false, "reason": "Слот '%s' заблокирован (требуется база/планка)" % str(sd.get("label", slot_type))}
				break
		var check: Dictionary = WeaponModDBScript.can_install_mod(test_mods, mod_id)
		if not check["ok"]:
			return check
			
	var prev_id := str(installed_mods.get(slot_type, ""))
	installed_mods[slot_type] = mod_id
	
	# Strip any child mods whose dependencies are no longer met (e.g. optic if Picatinny removed)
	var removed := WeaponModDBScript.cleanup_invalid_mods(installed_mods, weapon_id)
	recalculate_stats()
	return {"ok": true, "removed": removed, "prev_id": prev_id}

func _finalize_base_stats() -> void:
	base_damage = damage
	base_fire_rate = fire_rate
	base_mag_size = mag_size
	base_reload_time = reload_time
	base_spread = spread
	base_recoil_pitch = recoil_pitch
	base_recoil_yaw = recoil_yaw
	base_ergonomics = ergonomics
	base_pellets = pellets
	base_has_falloff = has_falloff
	if base_fire_modes.is_empty():
		base_fire_modes = ["auto"] if is_automatic else ["semi"]
	current_fire_mode = base_fire_modes[0]
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
	w.ammo_type = "762x39"
	w.slot = 1
	w.damage = 32.0
	w.fire_rate = 0.11
	w.is_automatic = true
	w.mag_size = 30
	w.current_ammo = 30
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.reserve_ammo = 90
	w.reload_time = 2.2
	w.pellets = 1
	w.spread = 0.018
	w.has_falloff = false
	w.recoil_pitch = 0.035
	w.recoil_yaw = 0.015
	w.ergonomics = 55.0
	w.base_fire_modes = ["auto", "semi"]
	w.installed_mods = {
		"dust_cover": "ak_cover_std",
		"handguard": "ak_hg_wood",
		"muzzle": "ak_muz_slant",
		"magazine": "ak_mag_30",
		"pistol_grip": "ak_grip_std",
		"stock_adapter": "ak_stock_wood",
		"ammo_type": "ammo_762x39_fmj"
	}
	w._finalize_base_stats()
	return w

static func create_shotgun() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "shotgun"
	w.name = "Pump Shotgun"
	w.ammo_type = "12ga"
	w.slot = 2
	w.damage = 18.0
	w.fire_rate = 0.85
	w.is_automatic = false
	w.mag_size = 5
	w.current_ammo = 5
	w.has_round_in_chamber = true
	w.is_shotgun = true
	w.reserve_ammo = 23
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
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"magazine": "sg_tube_5",
		"handguard": "sg_hg_wood",
		"stock_adapter": "sg_stock_wood",
		"ammo_type": "ammo_12ga_buck"
	}
	w._finalize_base_stats()
	return w

static func create_pistol() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "pistol"
	w.name = "Pistol"
	w.ammo_type = "9x19"
	w.slot = 3
	w.damage = 26.0
	w.fire_rate = 0.075
	w.is_automatic = false
	w.mag_size = 17
	w.current_ammo = 17
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.reserve_ammo = 51
	w.reload_time = 1.6
	w.pellets = 1
	w.spread = 0.008
	w.has_falloff = false
	w.recoil_pitch = 0.025
	w.recoil_yaw = 0.008
	w.ergonomics = 82.0
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"magazine": "ps_mag_17",
		"pistol_grip": "ps_grip_std",
		"ammo_type": "ammo_9x19_fmj"
	}
	w._finalize_base_stats()
	return w

static func create_rpg() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "rpg"
	w.name = "RPG-7"
	w.ammo_type = "pg7v"
	w.slot = 0 # Starts in arsenal/stash when purchased, equippable into slots 1..3
	w.damage = 900.0
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
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"optic": "rpg_opt_pgo7",
		"ammo_type": "ammo_rpg_pg7v"
	}
	w._finalize_base_stats()
	return w

static func create_knife() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "knife"
	w.name = "Штыковой нож"
	w.ammo_type = ""
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

static func create_kar98k() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "kar98k"
	w.name = "Kar98k"
	w.ammo_type = "792x57" # Shared with MG 42
	w.slot = 0
	w.damage = 135.0
	w.fire_rate = 1.15
	w.is_automatic = false
	w.mag_size = 5
	w.current_ammo = 5
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.is_bolt_action = true
	w.reserve_ammo = 15
	w.reload_time = 2.6
	w.pellets = 1
	w.spread = 0.0025
	w.has_falloff = false
	w.recoil_pitch = 0.088
	w.recoil_yaw = 0.014
	w.ergonomics = 52.0
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"magazine": "k98_mag_5",
		"handguard": "k98_hg_wood",
		"stock_adapter": "k98_stock_wood",
		"ammo_type": "ammo_792_ss"
	}
	w._finalize_base_stats()
	return w

static func create_pkm() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "pkm"
	w.name = "ПКМ"
	w.ammo_type = "762x54r"
	w.slot = 0
	w.damage = 40.0
	w.fire_rate = 0.092 # ~650 RPM
	w.is_automatic = true
	w.mag_size = 100
	w.current_ammo = 100
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.is_belt_fed = true
	w.reserve_ammo = 100
	w.reload_time = 4.2
	w.pellets = 1
	w.spread = 0.021
	w.has_falloff = false
	w.recoil_pitch = 0.040
	w.recoil_yaw = 0.018
	w.ergonomics = 28.0
	w.base_fire_modes = ["auto", "burst", "semi"]
	w.installed_mods = {
		"magazine": "pkm_box_100",
		"muzzle": "pkm_muz_std",
		"pistol_grip": "pkm_grip_std",
		"stock_adapter": "pkm_stock_wood",
		"ammo_type": "ammo_762x54r_lps"
	}
	w._finalize_base_stats()
	return w

static func create_l96a1() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "l96a1"
	w.name = "L96A1"
	w.ammo_type = "338lm"
	w.slot = 0
	w.damage = 240.0
	w.fire_rate = 1.45
	w.is_automatic = false
	w.mag_size = 5
	w.current_ammo = 5
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.is_bolt_action = true
	w.reserve_ammo = 10
	w.reload_time = 2.8
	w.pellets = 1
	w.spread = 0.0012
	w.has_falloff = false
	w.recoil_pitch = 0.115
	w.recoil_yaw = 0.016
	w.ergonomics = 36.0
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"optic": "l96_opt_pm2",
		"magazine": "l96_mag_5",
		"handguard": "l96_hg_std",
		"muzzle": "l96_muz_std",
		"stock_adapter": "l96_stock_std",
		"ammo_type": "ammo_338_match"
	}
	w._finalize_base_stats()
	return w

static func create_deagle() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "deagle"
	w.name = "Desert Eagle"
	w.ammo_type = "50ae"
	w.slot = 0
	w.damage = 84.0
	w.fire_rate = 0.28
	w.is_automatic = false
	w.mag_size = 7
	w.current_ammo = 7
	w.has_round_in_chamber = true
	w.is_shotgun = false
	w.reserve_ammo = 21
	w.reload_time = 1.85
	w.pellets = 1
	w.spread = 0.006
	w.has_falloff = false
	w.recoil_pitch = 0.078
	w.recoil_yaw = 0.018
	w.ergonomics = 72.0
	w.base_fire_modes = ["semi"]
	w.installed_mods = {
		"magazine": "de_mag_7",
		"pistol_grip": "de_grip_rubber",
		"ammo_type": "ammo_50ae_jhp"
	}
	w._finalize_base_stats()
	return w

static func create_aa12() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "aa12"
	w.name = "AA-12"
	w.ammo_type = "12ga" # Shared with Pump Shotgun
	w.slot = 0
	w.damage = 16.0
	w.fire_rate = 0.20 # 300 RPM full-auto
	w.is_automatic = true
	w.mag_size = 20
	w.current_ammo = 20
	w.has_round_in_chamber = false
	w.is_shotgun = false # Uses drum magazine reload, not shell-by-shell pump
	w.reserve_ammo = 20
	w.reload_time = 2.6
	w.pellets = 8
	w.spread = 0.082
	w.has_falloff = true
	w.falloff_min_dist = 4.0
	w.falloff_max_dist = 18.0
	w.min_damage_mult = 0.22
	w.recoil_pitch = 0.068
	w.recoil_yaw = 0.022
	w.ergonomics = 44.0
	w.base_fire_modes = ["auto", "semi"]
	w.installed_mods = {
		"magazine": "aa_mag_20",
		"handguard": "aa_hg_std",
		"muzzle": "aa_muz_std",
		"ammo_type": "ammo_12ga_buck"
	}
	w._finalize_base_stats()
	return w

static func create_mg42() -> Weapon:
	var w = Weapon.new()
	w.weapon_id = "mg42"
	w.name = "MG 42"
	w.ammo_type = "792x57" # Shared with Kar98k
	w.slot = 0
	w.damage = 30.0
	w.fire_rate = 0.050 # 1200 RPM buzzsaw
	w.is_automatic = true
	w.mag_size = 100
	w.current_ammo = 100
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.is_belt_fed = true
	w.reserve_ammo = 100
	w.reload_time = 4.0
	w.pellets = 1
	w.spread = 0.026
	w.has_falloff = false
	w.recoil_pitch = 0.036
	w.recoil_yaw = 0.020
	w.ergonomics = 26.0
	w.base_fire_modes = ["auto", "burst"]
	w.installed_mods = {
		"magazine": "mg_box_100",
		"muzzle": "mg_muz_std",
		"stock_adapter": "mg_stock_bakelite",
		"ammo_type": "ammo_792_ss"
	}
	w._finalize_base_stats()
	return w
