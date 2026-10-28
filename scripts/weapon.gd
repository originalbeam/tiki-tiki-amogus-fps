class_name Weapon
extends RefCounted

var name: String = "Weapon"
var slot: int = 1
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

# Chamber logic
var has_round_in_chamber: bool = true
var is_shotgun: bool = false

func get_max_reload_capacity() -> int:
	if is_shotgun:
		if not has_round_in_chamber or current_ammo == 0:
			return 5
		return 6
	# If there's already a round in the chamber, capacity is mag_size + 1 (e.g. 31 or 18)
	if has_round_in_chamber and current_ammo > 0:
		return mag_size + 1
	return mag_size

static func create_ak47() -> Weapon:
	var w = Weapon.new()
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
	w.reload_time = 2.2 # tactical reload is ~1.5s, empty is ~2.2s with bolt rack
	w.pellets = 1
	w.spread = 0.018
	w.has_falloff = false
	w.recoil_pitch = 0.035
	w.recoil_yaw = 0.015
	return w

static func create_shotgun() -> Weapon:
	var w = Weapon.new()
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
	w.reload_time = 0.85 # per shell
	w.pellets = 8
	w.spread = 0.075
	w.has_falloff = true
	w.falloff_min_dist = 4.0
	w.falloff_max_dist = 18.0
	w.min_damage_mult = 0.2
	w.recoil_pitch = 0.10
	w.recoil_yaw = 0.02
	return w

static func create_pistol() -> Weapon:
	var w = Weapon.new()
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
	w.reload_time = 1.6 # tactical ~1.1s, empty ~1.6s with slide release
	w.pellets = 1
	w.spread = 0.008
	w.has_falloff = false
	w.recoil_pitch = 0.025
	w.recoil_yaw = 0.008
	return w

static func create_knife() -> Weapon:
	var w = Weapon.new()
	w.name = "Штыковой нож"
	w.slot = 4
	w.damage = 70.0
	w.fire_rate = 0.55
	w.is_automatic = false
	w.mag_size = 1
	w.current_ammo = 1
	w.has_round_in_chamber = false
	w.is_shotgun = false
	w.reserve_ammo = 0
	w.reload_time = 0.1
	w.pellets = 1
	w.spread = 0.0
	w.has_falloff = false
	w.recoil_pitch = 0.0
	w.recoil_yaw = 0.0
	return w

