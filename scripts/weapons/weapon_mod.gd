class_name WeaponMod
extends RefCounted

# Base data definition for a weapon modification (attachment / component / ammo conversion).
# Designed as an extensible skeleton supporting:
# - Numeric stat deltas & multipliers (damage, fire rate, spread, recoil, mag size, reload speed, ergonomics)
# - Dependency & conflict rules (requires_mods, conflicts_with, provides_slots, is_vital)
# - Gameplay mechanic flags (ADS, dynamic variable zoom, reticles, future underbarrel GL, suppressors, lasers, flashlights, ammo conversions)

var id: String = ""
var name: String = ""
var short_name: String = ""
var description: String = ""
var slot_type: String = "" # e.g. "dust_cover", "optic", "magazine", "muzzle", "underbarrel", "ammo_type"
var price: int = 0
var compatible_weapons: Array[String] = [] # e.g. ["ak47"]

# Numeric stat modifiers (additive & multiplicative)
var damage_add: float = 0.0
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0 # < 1.0 = faster fire rate
var spread_mult: float = 1.0    # < 1.0 = better accuracy
var recoil_pitch_mult: float = 1.0
var recoil_yaw_mult: float = 1.0
var mag_size_add: int = 0
var reload_time_mult: float = 1.0 # < 1.0 = faster reload
var ergonomics_add: float = 0.0

# Dependency & structural rules
var requires_mods: Array[String] = []   # All listed mod IDs must be installed on the weapon
var conflicts_with: Array[String] = []  # Cannot coexist with any of these mod IDs
var provides_slots: Array[String] = []  # Unlocks additional child mod slots (e.g. Picatinny cover unlocks "optic")
var is_vanilla_default: bool = false    # True if this is the factory stock component

# Gameplay mechanics dictionary (extensible for future updates):
# Supported keys:
#   "ads_enabled": bool
#   "ads_zoom_min": float (e.g. 1.35)
#   "ads_zoom_max": float (e.g. 4.0 -> enables mouse-wheel variable zoom while aiming!)
#   "ads_reticle": String ("red_dot", "lpvo_crosshair", etc.)
#   "underbarrel_grenade_launcher": bool
#   "suppressed": bool
#   "laser_sight": bool
#   "flashlight": bool
#   "clears_ammo_on_change": bool
#   "shop_ammo_price_override": int
var mechanics: Dictionary = {}

static func make(cfg: Dictionary) -> RefCounted:
	var m := new()
	m.id = cfg.get("id", "")
	m.name = cfg.get("name", "Модификация")
	m.short_name = cfg.get("short_name", m.name)
	m.description = cfg.get("description", "")
	m.slot_type = cfg.get("slot_type", "")
	m.price = cfg.get("price", 0)
	for w in cfg.get("compatible_weapons", []):
		m.compatible_weapons.append(str(w))
	m.damage_add = cfg.get("damage_add", 0.0)
	m.damage_mult = cfg.get("damage_mult", 1.0)
	m.fire_rate_mult = cfg.get("fire_rate_mult", 1.0)
	m.spread_mult = cfg.get("spread_mult", 1.0)
	m.recoil_pitch_mult = cfg.get("recoil_pitch_mult", 1.0)
	m.recoil_yaw_mult = cfg.get("recoil_yaw_mult", 1.0)
	m.mag_size_add = cfg.get("mag_size_add", 0)
	m.reload_time_mult = cfg.get("reload_time_mult", 1.0)
	m.ergonomics_add = cfg.get("ergonomics_add", 0.0)
	for r in cfg.get("requires_mods", []):
		m.requires_mods.append(str(r))
	for c in cfg.get("conflicts_with", []):
		m.conflicts_with.append(str(c))
	for p in cfg.get("provides_slots", []):
		m.provides_slots.append(str(p))
	m.is_vanilla_default = cfg.get("is_vanilla_default", false)
	m.mechanics = cfg.get("mechanics", {}).duplicate(true)
	return m
