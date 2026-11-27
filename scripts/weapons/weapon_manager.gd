extends Node3D

signal weapon_changed(weapon: Weapon)
signal ammo_updated(current: int, reserve: int, is_reloading: bool, has_chamber: bool, shotgun_4_plus_1: bool)
signal hit_enemy()
signal slots_updated()
signal ads_state_changed(is_aiming: bool, zoom: float, reticle: String)
signal tactical_state_changed(fire_mode_label: String, can_switch_mode: bool, has_laser: bool, laser_on: bool, has_light: bool, light_on: bool, has_ugl: bool, ugl_ammo: int, ugl_reserve: int, ugl_active: bool)

@export var camera: Camera3D
@export var bullet_tracer_scene: PackedScene = preload("res://scenes/bullet_tracer.tscn")
@export var bullet_impact_scene: PackedScene = preload("res://scenes/bullet_impact.tscn")
@export var shell_casing_scene: PackedScene = preload("res://scenes/shell_casing.tscn")

const AK47ModelScript = preload("res://scripts/weapons/models/ak47_model.gd")
const ShotgunModelScript = preload("res://scripts/weapons/models/shotgun_model.gd")
const PistolModelScript = preload("res://scripts/weapons/models/pistol_model.gd")
const RPGModelScript = preload("res://scripts/weapons/models/rpg_model.gd")
const KnifeModelScript = preload("res://scripts/weapons/models/knife_model.gd")
const Kar98kModelScript = preload("res://scripts/weapons/models/kar98k_model.gd")
const PKMModelScript = preload("res://scripts/weapons/models/pkm_model.gd")
const L96A1ModelScript = preload("res://scripts/weapons/models/l96a1_model.gd")
const DeagleModelScript = preload("res://scripts/weapons/models/deagle_model.gd")
const AA12ModelScript = preload("res://scripts/weapons/models/aa12_model.gd")
const MG42ModelScript = preload("res://scripts/weapons/models/mg42_model.gd")
const RPGRocketScript = preload("res://scripts/weapons/rpg_rocket.gd")
const UGLGrenadeScript = preload("res://scripts/weapons/ugl_grenade.gd")
const WeaponModVisualsScript = preload("res://scripts/weapons/models/weapon_mod_visuals.gd")
const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

# Dynamic Slot-Based Arsenal (Slots 1-3 unlocked at start; Slots 4-5 unlockable for $600 each in Shop!)
var weapons: Array[Weapon] = []
var weapon_slots: Array = [null, null, null, null, null]
var unlocked_weapon_slots: Array = [true, true, true, false, false]
var current_weapon_idx: int = 0
var current_weapon: Weapon = null
var melee_slot: Weapon = null
var owned_melee: Array[Weapon] = []

# Per-Ammo-Type Shared Reserve Pools (weapons sharing caliber + exact ammo_type mod ID share the exact same pool!)
# e.g., Pump Shotgun & AA-12 share "ammo_12ga_buck", "ammo_12ga_slug", etc.; Kar98k & MG 42 share "ammo_792_ss", "ammo_792_smk", etc.
var shared_ammo_reserves: Dictionary = {
	"ammo_762x39_fmj": 90,
	"ammo_12ga_buck": 23,
	"ammo_9x19_fmj": 51,
	"ammo_rpg_pg7v": 0,
	"ammo_792_ss": 0,
	"ammo_762x54r_lps": 0,
	"ammo_338_match": 0,
	"ammo_50ae_jhp": 0
}

# Cheat & ADS states
var infinite_reserve_ammo: bool = false
var is_aiming: bool = false
var ads_blend: float = 0.0
var current_ads_zoom: float = 1.0

# Picture-in-Picture (PiP) Scope SubViewport & Camera (magnifies ONLY inside magnifying scopes!)
var scope_viewport: SubViewport = null
var scope_camera: Camera3D = null
var active_optic_lens: MeshInstance3D = null
var dynamic_optic_lenses: Dictionary = {} # weapon_id -> MeshInstance3D
var rpg_optic_lens: MeshInstance3D = null
var l96a1_optic_lens: MeshInstance3D = null
var _thermal_heat_mats: Dictionary = {} # int(round(heat * 100)) -> StandardMaterial3D
var _thermal_sync_timer: float = 0.0

# Active Tactical Attachments (Laser Beam + Dot, Flashlight SpotLight3D, UGL & Burst state)
var tactical_laser_beam: MeshInstance3D = null
var tactical_laser_dot: MeshInstance3D = null
var tactical_laser_mat: StandardMaterial3D = null
var tactical_flashlight: SpotLight3D = null
var is_ugl_mode: bool = false
var ugl_mode_blend: float = 0.0
var is_reloading_ugl: bool = false
var is_switching_fire_mode: bool = false
var burst_shots_remaining: int = 0
var burst_timer: float = 0.0

var can_shoot: bool = true
var is_reloading: bool = false
var is_switching: bool = false
var shoot_timer: float = 0.0

# Dynamic spread bloom & sustained burst recoil state
var dynamic_spread_bloom: float = 0.0
var consecutive_shots: int = 0
var shot_recovery_timer: float = 0.0
var kar98k_last_reload_clips_loaded: int = 0

# Shotgun reload state
var shotgun_cancel_reload: bool = false
var shotgun_started_empty: bool = false
var shotgun_is_4_plus_1: bool = false

# High-Detail Unified Viewmodel References (rebuilt from scratch in _ready!)
var ak47_model: Node3D = null
var shotgun_model: Node3D = null
var pistol_model: Node3D = null
var rpg_model: Node3D = null
var kar98k_model: Node3D = null
var pkm_model: Node3D = null
var l96a1_model: Node3D = null
var deagle_model: Node3D = null
var aa12_model: Node3D = null
var mg42_model: Node3D = null
var knife_model: Node3D = null
var air_slash_mesh: MeshInstance3D = null

var ak_charging_handle: Node3D = null
var ak_magazine: Node3D = null
var shotgun_pump: Node3D = null
var shotgun_bolt: Node3D = null
var shotgun_elevator: Node3D = null
var shotgun_shell: Node3D = null
var pistol_slide: Node3D = null
var pistol_magazine: Node3D = null
var rpg_warhead: Node3D = null

# New weapon animated sub-part references
var kar98k_bolt: Node3D = null
var kar98k_bolt_rotator: Node3D = null
var kar98k_cocking_piece: Node3D = null
var kar98k_extracted_case: Node3D = null
var kar98k_trigger: Node3D = null
var kar98k_follower_round: Node3D = null
var kar98k_clip: Node3D = null
var kar98k_clip_rail: Node3D = null
var kar98k_clip_rounds: Node3D = null
var kar98k_single_round: Node3D = null
var pkm_top_cover: Node3D = null
var pkm_ammo_box: Node3D = null
var pkm_charging_handle: Node3D = null
var l96a1_bolt: Node3D = null
var l96a1_mag: Node3D = null
var deagle_slide: Node3D = null
var deagle_mag: Node3D = null
var aa12_mag: Node3D = null
var aa12_charging_handle: Node3D = null
var mg42_top_cover: Node3D = null
var mg42_ammo_box: Node3D = null
var mg42_charging_handle: Node3D = null

# Rebuilt Volumetric VFX References
var muzzle_flash: Node3D = null
var flash_light: OmniLight3D = null
var muzzle_smoke: CPUParticles3D = null
var ak_sparks: CPUParticles3D = null

@onready var shoot_sound_player: AudioStreamPlayer = $ShootSound
@onready var reload_sound_player: AudioStreamPlayer = $ReloadSound
@onready var hit_sound_player: AudioStreamPlayer = $HitSound

# ==========================================
# REBUILT MULTI-LAYER PROCEDURAL ANIMATION ENGINE
# Clean separation of layers so animations never fight or clip each other:
# 1) base_pose -> ads_pose -> sprint_pose
# 2) Second-order spring-damper recoil (recoil_pos/vel, recoil_rot/vel)
# 3) Dedicated kinematic action/reload/pump layer (anim_pos, anim_rot)
# 4) Dedicated equip/draw/holster layer (draw_pos, draw_rot)
# 5) Walk figure-8 bob + mouse inertia sway + organic breathing
# ==========================================
var initial_pos: Vector3
var is_sprinting_now: bool = false
var sprint_blend: float = 0.0

# Second-order spring-damper recoil physics
var recoil_pos: Vector3 = Vector3.ZERO
var recoil_vel: Vector3 = Vector3.ZERO
var recoil_rot: Vector3 = Vector3.ZERO
var recoil_rot_vel: Vector3 = Vector3.ZERO

# Dedicated kinematic action/reload layer (independent from spring recoil!)
var anim_pos: Vector3 = Vector3.ZERO
var anim_rot: Vector3 = Vector3.ZERO

# Dedicated equip/draw/holster layer
var draw_pos: Vector3 = Vector3.ZERO
var draw_rot: Vector3 = Vector3.ZERO

# Mouse inertia sway & walk bob
var sway_pos: Vector3 = Vector3.ZERO
var sway_rot: Vector3 = Vector3.ZERO
var bob_pos: Vector3 = Vector3.ZERO
var bob_rot: Vector3 = Vector3.ZERO

var idle_timer: float = 0.0
var walk_bob_timer: float = 0.0
var dry_fire_cooldown: float = 0.0

# Sub-part mechanical offsets
var pump_offset_z: float = 0.0
var initial_pump_z: float = -0.32
var initial_sg_bolt_z: float = -0.035
var elevator_offset_y: float = 0.0
var initial_elevator_y: float = -0.035

var ak_handle_offset_z: float = 0.0
var initial_ak_handle_z: float = -0.040
var ak_mag_initial_pos: Vector3 = Vector3(0, -0.042, -0.055)
var ak_mag_initial_rot: Vector3 = Vector3.ZERO

var pistol_slide_offset_z: float = 0.0
var initial_pistol_slide_z: float = 0.0
var pistol_slide_locked_back: bool = false
var pistol_mag_initial_pos: Vector3 = Vector3(0, -0.068, 0.053)
var pistol_mag_initial_rot: Vector3 = Vector3(deg_to_rad(-20.0), 0, 0)

var rpg_warhead_initial_pos: Vector3 = Vector3(0, 0, -0.45)

# Mechanical sub-part offsets for the 6 new weapons
var kar98k_bolt_initial_pos: Vector3 = Vector3.ZERO
var kar98k_clip_initial_pos: Vector3 = Vector3.ZERO
var kar98k_clip_rail_initial_pos: Vector3 = Vector3.ZERO
var kar98k_cocking_initial_z: float = 0.068
var kar98k_cancel_reload: bool = false
var kar98k_has_spent_case: bool = false
var pkm_box_initial_pos: Vector3 = Vector3.ZERO
var pkm_handle_initial_z: float = 0.0
var pkm_handle_offset_z: float = 0.0
var l96a1_bolt_initial_pos: Vector3 = Vector3.ZERO
var l96a1_mag_initial_pos: Vector3 = Vector3.ZERO
var deagle_slide_initial_z: float = 0.0
var deagle_slide_offset_z: float = 0.0
var deagle_slide_locked_back: bool = false
var deagle_mag_initial_pos: Vector3 = Vector3.ZERO
var aa12_mag_initial_pos: Vector3 = Vector3.ZERO
var aa12_handle_initial_z: float = 0.0
var aa12_handle_offset_z: float = 0.0
var mg42_box_initial_pos: Vector3 = Vector3.ZERO
var mg42_handle_initial_z: float = 0.0
var mg42_handle_offset_z: float = 0.0

# Knife / Melee alternating combo state
var is_quick_knifing: bool = false
var knife_combo_alt: bool = false
var knife_idle_pos: Vector3 = Vector3(0.28, -0.16, -0.22)
var knife_idle_rot: Vector3 = Vector3(-8.0, 15.0, -12.0)

func _ready() -> void:
	initial_pos = position
	_rebuild_all_weapon_models()
	_rebuild_muzzle_vfx()
	_setup_pip_scope_viewport()
	_setup_tactical_attachments_vfx()
	
	# Initialize starting arsenal (AK-47, Shotgun, Pistol in slots 1..3; RPG-7 bought in Shop)
	weapons.clear()
	var w_ak := Weapon.create_ak47()
	var w_sg := Weapon.create_shotgun()
	var w_ps := Weapon.create_pistol()
	weapons.append(w_ak)
	weapons.append(w_sg)
	weapons.append(w_ps)
	
	weapon_slots = [w_ak, w_sg, w_ps, null, null]
	unlocked_weapon_slots = [true, true, true, false, false]
	w_ak.slot = 1
	w_sg.slot = 2
	w_ps.slot = 3
	
	shared_ammo_reserves[w_ak.get_active_ammo_pool_key()] = w_ak.reserve_ammo
	shared_ammo_reserves[w_sg.get_active_ammo_pool_key()] = w_sg.reserve_ammo
	shared_ammo_reserves[w_ps.get_active_ammo_pool_key()] = w_ps.reserve_ammo
	sync_shared_reserves()
	
	# Specialized Melee Slot ([V])
	melee_slot = Weapon.create_knife()
	owned_melee.clear()
	owned_melee.append(melee_slot)
	
	refresh_active_weapon_mods()
	_set_viewmodel_layers(self, 2)
	if shoot_sound_player:
		shoot_sound_player.bus = "Weapons"
	if reload_sound_player:
		reload_sound_player.bus = "Weapons"
	if hit_sound_player:
		hit_sound_player.bus = "SFX"
	switch_weapon(0, false)
	slots_updated.emit()

func _rebuild_all_weapon_models() -> void:
	# Replace legacy primitive scene meshes with our brand-new high-detail procedural models!
	for old_name in ["AK47", "Shotgun", "Pistol", "RPG", "Knife", "AirSlashEffect"]:
		var old_n := get_node_or_null(old_name)
		if old_n:
			remove_child(old_n)
			old_n.queue_free()
			
	# 1. AK-47 (same high-detail procedural model as Workbench & Handbook!)
	ak47_model = AK47ModelScript.create()
	ak47_model.name = "AK47"
	add_child(ak47_model)
	ak_charging_handle = ak47_model.get_node_or_null("ChargingHandle")
	ak_magazine = ak47_model.get_node_or_null("Magazine")
	if ak_charging_handle:
		initial_ak_handle_z = ak_charging_handle.position.z
	if ak_magazine:
		ak_mag_initial_pos = ak_magazine.position
		ak_mag_initial_rot = ak_magazine.rotation
		
	# 2. Pump Shotgun (Remington 870 / Mossberg 590)
	shotgun_model = ShotgunModelScript.create()
	shotgun_model.name = "Shotgun"
	add_child(shotgun_model)
	shotgun_pump = shotgun_model.get_node_or_null("Pump")
	shotgun_bolt = shotgun_model.get_node_or_null("Bolt")
	shotgun_elevator = shotgun_model.get_node_or_null("Elevator")
	shotgun_shell = shotgun_model.get_node_or_null("LoadingShell")
	if shotgun_pump:
		initial_pump_z = shotgun_pump.position.z
	if shotgun_bolt:
		initial_sg_bolt_z = shotgun_bolt.position.z
	if shotgun_elevator:
		initial_elevator_y = shotgun_elevator.position.y
	if shotgun_shell:
		shotgun_shell.visible = false
	shotgun_model.visible = false
	
	# 3. Tactical Sidearm Pistol
	pistol_model = PistolModelScript.create()
	pistol_model.name = "Pistol"
	pistol_model.position = Vector3(-0.02, 0.01, 0.04)
	add_child(pistol_model)
	pistol_slide = pistol_model.get_node_or_null("Slide")
	pistol_magazine = pistol_model.get_node_or_null("Magazine")
	if pistol_slide:
		initial_pistol_slide_z = pistol_slide.position.z
	if pistol_magazine:
		pistol_mag_initial_pos = pistol_magazine.position
		pistol_mag_initial_rot = pistol_magazine.rotation
	pistol_model.visible = false
	
	# 4. RPG-7V Launcher (with built-in PGO-7 PiP optical scope)
	rpg_model = RPGModelScript.create(true)
	rpg_model.name = "RPG"
	rpg_model.position = Vector3(0.05, 0.03, 0.14)
	add_child(rpg_model)
	rpg_warhead = rpg_model.get_node_or_null("Warhead")
	if rpg_warhead:
		rpg_warhead_initial_pos = rpg_warhead.position
	rpg_optic_lens = rpg_model.find_child("OpticLens", true, false) as MeshInstance3D
	rpg_model.visible = false
	
	# 5. Karabiner 98k (Museum-Grade Mauser 98 bolt-action rifle)
	kar98k_model = Kar98kModelScript.create()
	kar98k_model.name = "Kar98k"
	add_child(kar98k_model)
	kar98k_bolt = kar98k_model.get_node_or_null("BoltHandle")
	kar98k_trigger = kar98k_model.get_node_or_null("Trigger")
	kar98k_follower_round = kar98k_model.get_node_or_null("FollowerRound")
	kar98k_clip = kar98k_model.get_node_or_null("ClipStrip")
	kar98k_single_round = kar98k_model.get_node_or_null("SingleRound")
	if kar98k_bolt:
		kar98k_bolt_initial_pos = kar98k_bolt.position
		kar98k_bolt_rotator = kar98k_bolt.get_node_or_null("BoltRotator")
		kar98k_cocking_piece = kar98k_bolt.get_node_or_null("CockingPiece")
		kar98k_extracted_case = kar98k_bolt.get_node_or_null("ExtractedCase")
		if kar98k_cocking_piece:
			kar98k_cocking_initial_z = kar98k_cocking_piece.position.z
	if kar98k_clip:
		kar98k_clip_initial_pos = kar98k_clip.position
		kar98k_clip.visible = false
		kar98k_clip_rail = kar98k_clip.get_node_or_null("ClipRail")
		kar98k_clip_rounds = kar98k_clip.get_node_or_null("ClipRounds")
		if kar98k_clip_rail:
			kar98k_clip_rail_initial_pos = kar98k_clip_rail.position
	if kar98k_single_round:
		kar98k_single_round.visible = false
	kar98k_model.visible = false
	
	# 6. PKM (Belt-fed General-Purpose Machine Gun)
	pkm_model = PKMModelScript.create()
	pkm_model.name = "PKM"
	pkm_model.position = Vector3(0.02, -0.02, 0.04)
	add_child(pkm_model)
	pkm_top_cover = pkm_model.get_node_or_null("TopCover")
	pkm_ammo_box = pkm_model.get_node_or_null("AmmoBox")
	pkm_charging_handle = pkm_model.get_node_or_null("ChargingHandle")
	if pkm_ammo_box:
		pkm_box_initial_pos = pkm_ammo_box.position
	if pkm_charging_handle:
		pkm_handle_initial_z = pkm_charging_handle.position.z
	pkm_model.visible = false
	
	# 7. L96A1 (Accuracy International Sniper Rifle with built-in PiP Scope)
	l96a1_model = L96A1ModelScript.create()
	l96a1_model.name = "L96A1"
	add_child(l96a1_model)
	l96a1_bolt = l96a1_model.get_node_or_null("BoltHandle")
	l96a1_mag = l96a1_model.get_node_or_null("Magazine")
	l96a1_optic_lens = l96a1_model.find_child("OpticLens", true, false) as MeshInstance3D
	if l96a1_bolt:
		l96a1_bolt_initial_pos = l96a1_bolt.position
	if l96a1_mag:
		l96a1_mag_initial_pos = l96a1_mag.position
	l96a1_model.visible = false
	
	# 8. Desert Eagle .50 AE (Heavy Chrome Hand Cannon)
	deagle_model = DeagleModelScript.create()
	deagle_model.name = "Deagle"
	deagle_model.position = Vector3(-0.018, 0.008, 0.04)
	add_child(deagle_model)
	deagle_slide = deagle_model.get_node_or_null("Slide")
	deagle_mag = deagle_model.get_node_or_null("Magazine")
	if deagle_slide:
		deagle_slide_initial_z = deagle_slide.position.z
	if deagle_mag:
		deagle_mag_initial_pos = deagle_mag.position
	deagle_model.visible = false
	
	# 9. AA-12 (Full-Auto Drum Combat Shotgun)
	aa12_model = AA12ModelScript.create()
	aa12_model.name = "AA12"
	aa12_model.position = Vector3(0.01, -0.01, 0.02)
	add_child(aa12_model)
	aa12_mag = aa12_model.get_node_or_null("Magazine")
	aa12_charging_handle = aa12_model.get_node_or_null("ChargingHandle")
	if aa12_mag:
		aa12_mag_initial_pos = aa12_mag.position
	if aa12_charging_handle:
		aa12_handle_initial_z = aa12_charging_handle.position.z
	aa12_model.visible = false
	
	# 10. MG 42 (Hitler's Buzzsaw 1200 RPM Machine Gun)
	mg42_model = MG42ModelScript.create()
	mg42_model.name = "MG42"
	mg42_model.position = Vector3(0.02, -0.02, 0.04)
	add_child(mg42_model)
	mg42_top_cover = mg42_model.get_node_or_null("TopCover")
	mg42_ammo_box = mg42_model.get_node_or_null("AmmoBox")
	mg42_charging_handle = mg42_model.get_node_or_null("ChargingHandle")
	if mg42_ammo_box:
		mg42_box_initial_pos = mg42_ammo_box.position
	if mg42_charging_handle:
		mg42_handle_initial_z = mg42_charging_handle.position.z
	mg42_model.visible = false
	
	# 11. Combat Bayonet Knife & Metallic Wind-Shear Slash Arc
	knife_model = KnifeModelScript.build_knife_model(knife_idle_pos, knife_idle_rot)
	add_child(knife_model)
	knife_model.visible = false
	
	air_slash_mesh = KnifeModelScript.build_air_slash_mesh()
	add_child(air_slash_mesh)

func _rebuild_muzzle_vfx() -> void:
	# Replace legacy scene VFX nodes with rebuilt shader-driven volumetric muzzle flash & gunsmoke
	for old_name in ["MuzzleFlash", "MuzzleSmoke", "AK_Sparks"]:
		var old_n := get_node_or_null(old_name)
		if old_n:
			remove_child(old_n)
			old_n.queue_free()
			
	muzzle_flash = VFXFactoryScript.build_muzzle_flash_rig()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.visible = false
	add_child(muzzle_flash)
	flash_light = muzzle_flash.get_node_or_null("OmniLight3D")
	
	muzzle_smoke = VFXFactoryScript.build_muzzle_smoke_emitter()
	add_child(muzzle_smoke)
	
	ak_sparks = VFXFactoryScript.build_muzzle_sparks_emitter()
	add_child(ak_sparks)

func _setup_pip_scope_viewport() -> void:
	scope_viewport = SubViewport.new()
	scope_viewport.name = "PiPScopeViewport"
	scope_viewport.size = Vector2i(640, 640)
	scope_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	scope_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(scope_viewport)
	
	scope_camera = Camera3D.new()
	scope_camera.name = "PiPScopeCamera"
	scope_camera.cull_mask = 1 # World layer only (excludes viewmodel on layer 2)
	scope_camera.near = 0.08
	scope_camera.far = 500.0
	scope_camera.fov = 45.0
	scope_camera.current = true
	scope_viewport.add_child(scope_camera)

func _setup_tactical_attachments_vfx() -> void:
	tactical_laser_mat = StandardMaterial3D.new()
	tactical_laser_mat.albedo_color = Color(1.0, 0.12, 0.10, 0.78)
	tactical_laser_mat.emission_enabled = true
	tactical_laser_mat.emission = Color(1.0, 0.12, 0.10)
	tactical_laser_mat.emission_energy_multiplier = 3.2
	tactical_laser_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tactical_laser_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tactical_laser_mat.no_depth_test = false

	tactical_laser_beam = MeshInstance3D.new()
	tactical_laser_beam.name = "TacticalLaserBeam"
	var beam_cyl := CylinderMesh.new()
	beam_cyl.top_radius = 0.0022
	beam_cyl.bottom_radius = 0.0022
	beam_cyl.height = 1.0
	beam_cyl.radial_segments = 8
	tactical_laser_beam.mesh = beam_cyl
	tactical_laser_beam.material_override = tactical_laser_mat
	tactical_laser_beam.layers = 1
	tactical_laser_beam.top_level = true
	tactical_laser_beam.visible = false
	add_child(tactical_laser_beam)

	tactical_laser_dot = MeshInstance3D.new()
	tactical_laser_dot.name = "TacticalLaserDot"
	var dot_sph := SphereMesh.new()
	dot_sph.radius = 0.024
	dot_sph.height = 0.048
	dot_sph.radial_segments = 10
	dot_sph.rings = 6
	tactical_laser_dot.mesh = dot_sph
	tactical_laser_dot.material_override = tactical_laser_mat
	tactical_laser_dot.layers = 1
	tactical_laser_dot.top_level = true
	tactical_laser_dot.visible = false
	add_child(tactical_laser_dot)

	tactical_flashlight = SpotLight3D.new()
	tactical_flashlight.name = "TacticalFlashlight"
	tactical_flashlight.light_color = Color(1.0, 0.96, 0.88)
	tactical_flashlight.light_energy = 8.0
	tactical_flashlight.spot_range = 36.0
	tactical_flashlight.spot_angle = 26.0
	tactical_flashlight.spot_angle_attenuation = 1.6
	tactical_flashlight.shadow_enabled = false
	tactical_flashlight.top_level = true
	tactical_flashlight.visible = false
	add_child(tactical_flashlight)

func _set_viewmodel_layers(node: Node, layer_mask: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = layer_mask
	for child in node.get_children():
		if child == scope_viewport or child == muzzle_smoke or child == ak_sparks or child == tactical_laser_beam or child == tactical_laser_dot or child == tactical_flashlight:
			continue
		_set_viewmodel_layers(child, layer_mask)

func emit_ammo_state() -> void:
	sync_shared_reserves()
	if current_weapon:
		ammo_updated.emit(
			current_weapon.current_ammo,
			get_reserve_ammo(current_weapon),
			is_reloading,
			current_weapon.has_round_in_chamber,
			shotgun_is_4_plus_1
		)
	else:
		ammo_updated.emit(0, 0, false, false, false)

func _resolve_ammo_pool_key(key_or_caliber: String) -> String:
	if key_or_caliber == "":
		return ""
	if key_or_caliber.begins_with("ammo_"):
		return key_or_caliber
	return Weapon.get_default_ammo_mod_id(key_or_caliber)

func get_reserve_by_pool_key(pool_key: String) -> int:
	var resolved: String = _resolve_ammo_pool_key(pool_key)
	if resolved == "":
		return 0
	return int(shared_ammo_reserves.get(resolved, 0))

func get_reserve_ammo(w: Weapon) -> int:
	if not w or w.ammo_type == "":
		return 0
	var pool_key: String = w.get_active_ammo_pool_key()
	return int(shared_ammo_reserves.get(pool_key, 0))

func consume_reserve_ammo(w: Weapon, amount: int) -> int:
	if not w or w.ammo_type == "" or amount <= 0:
		return 0
	var pool_key: String = w.get_active_ammo_pool_key()
	var cur: int = int(shared_ammo_reserves.get(pool_key, 0))
	var taken: int = mini(cur, amount)
	shared_ammo_reserves[pool_key] = cur - taken
	sync_shared_reserves()
	return taken

func add_reserve_ammo_by_type(ammo_type_or_id: String, amount: int) -> void:
	var pool_key: String = _resolve_ammo_pool_key(ammo_type_or_id)
	if pool_key == "" or amount <= 0:
		return
	shared_ammo_reserves[pool_key] = int(shared_ammo_reserves.get(pool_key, 0)) + amount
	sync_shared_reserves()
	emit_ammo_state()

func on_weapon_ammo_type_changed(w: Weapon, prev_ammo_id: String, new_ammo_id: String) -> void:
	if not w or w.ammo_type == "":
		return
	var old_key: String = _resolve_ammo_pool_key(prev_ammo_id if prev_ammo_id != "" else w.ammo_type)
	var new_key: String = _resolve_ammo_pool_key(new_ammo_id if new_ammo_id != "" else w.ammo_type)
	if old_key == new_key:
		sync_shared_reserves()
		emit_ammo_state()
		return
	# Unload all rounds currently in the weapon magazine/chamber back into the OLD ammo type's reserve pool!
	if w.current_ammo > 0 and old_key != "":
		shared_ammo_reserves[old_key] = int(shared_ammo_reserves.get(old_key, 0)) + w.current_ammo
	w.current_ammo = 0
	w.has_round_in_chamber = false
	if new_key != "" and not shared_ammo_reserves.has(new_key):
		shared_ammo_reserves[new_key] = 0
	if w.weapon_id == "pistol":
		pistol_slide_locked_back = false
	elif w.weapon_id == "deagle":
		deagle_slide_locked_back = false
	sync_shared_reserves()
	emit_ammo_state()

func halve_all_reserves() -> void:
	for k in shared_ammo_reserves.keys():
		shared_ammo_reserves[k] = int(ceil(float(shared_ammo_reserves[k]) / 2.0))
	sync_shared_reserves()
	emit_ammo_state()

func sync_shared_reserves() -> void:
	for w in weapons:
		if w and w.ammo_type != "":
			var pool_key: String = w.get_active_ammo_pool_key()
			w.reserve_ammo = int(shared_ammo_reserves.get(pool_key, 0))

func get_current_weapon() -> Weapon:
	return current_weapon

func has_weapon(wid: String) -> bool:
	for w in weapons:
		if w and w.weapon_id == wid:
			return true
	return false

func get_weapon_by_id(wid: String) -> Weapon:
	for w in weapons:
		if w and w.weapon_id == wid:
			return w
	return null

func is_weapon_slot_unlocked(slot_idx: int) -> bool:
	return slot_idx >= 0 and slot_idx < unlocked_weapon_slots.size() and bool(unlocked_weapon_slots[slot_idx])

func unlock_weapon_slot(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= unlocked_weapon_slots.size():
		return false
	if bool(unlocked_weapon_slots[slot_idx]):
		return false
	unlocked_weapon_slots[slot_idx] = true
	slots_updated.emit()
	return true

func grant_weapon(w: Weapon, auto_equip_if_empty: bool = true) -> bool:
	if not w or has_weapon(w.weapon_id):
		return false
	w.slot = 0
	weapons.append(w)
	# Merge the newly granted weapon's spare ammo into the exact shared ammo-type pool!
	if w.ammo_type != "" and w.reserve_ammo > 0:
		var pool_key: String = w.get_active_ammo_pool_key()
		shared_ammo_reserves[pool_key] = int(shared_ammo_reserves.get(pool_key, 0)) + w.reserve_ammo
	sync_shared_reserves()
	refresh_active_weapon_mods()
	if auto_equip_if_empty:
		for i in range(weapon_slots.size()):
			if is_weapon_slot_unlocked(i) and weapon_slots[i] == null:
				equip_weapon_to_slot(w, i)
				return true
	emit_ammo_state()
	slots_updated.emit()
	return true

func equip_weapon_to_slot(w: Weapon, slot_idx: int) -> void:
	if not w or not is_weapon_slot_unlocked(slot_idx):
		return
	var prev_slot_idx: int = -1
	for i in range(weapon_slots.size()):
		if weapon_slots[i] == w:
			prev_slot_idx = i
			break
	if prev_slot_idx == slot_idx:
		return
	var displaced: Weapon = weapon_slots[slot_idx]
	weapon_slots[slot_idx] = w
	w.slot = slot_idx + 1
	if prev_slot_idx != -1:
		weapon_slots[prev_slot_idx] = displaced
		if displaced:
			displaced.slot = prev_slot_idx + 1
	elif displaced:
		displaced.slot = 0
	if is_reloading:
		is_reloading = false
		shotgun_cancel_reload = true
	set_aiming(false)
	set_active_model_visible(current_weapon_idx)
	slots_updated.emit()

func unequip_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= weapon_slots.size():
		return
	var w: Weapon = weapon_slots[slot_idx]
	if w:
		w.slot = 0
		weapon_slots[slot_idx] = null
	if slot_idx == current_weapon_idx:
		if is_reloading:
			is_reloading = false
			shotgun_cancel_reload = true
		set_aiming(false)
		set_active_model_visible(current_weapon_idx)
	slots_updated.emit()

func _get_model_for_weapon_id(wid: String) -> Node3D:
	match wid:
		"ak47": return ak47_model
		"shotgun": return shotgun_model
		"pistol": return pistol_model
		"rpg": return rpg_model
		"kar98k": return kar98k_model
		"pkm": return pkm_model
		"l96a1": return l96a1_model
		"deagle": return deagle_model
		"aa12": return aa12_model
		"mg42": return mg42_model
	return null

func refresh_active_weapon_mods() -> void:
	dynamic_optic_lenses.clear()
	active_optic_lens = null
	for w in weapons:
		if not w:
			continue
		var mdl: Node3D = _get_model_for_weapon_id(w.weapon_id)
		if mdl:
			WeaponModVisualsScript.apply_mods_to_weapon_node(w.weapon_id, mdl, w.installed_mods)
			_set_viewmodel_layers(mdl, 2)
			if w.weapon_id == "rpg":
				rpg_warhead = mdl.get_node_or_null("Warhead")
				if rpg_warhead:
					rpg_warhead.visible = (w.current_ammo > 0)
					rpg_warhead.position = rpg_warhead_initial_pos
			var lens: MeshInstance3D = null
			var top_mod_root := mdl.get_node_or_null("TopCover/DynamicModsTopCover")
			if top_mod_root:
				lens = top_mod_root.find_child("OpticLens", true, false) as MeshInstance3D
			if not lens:
				var mod_root := mdl.get_node_or_null("DynamicMods")
				if mod_root:
					lens = mod_root.find_child("OpticLens", true, false) as MeshInstance3D
			if lens:
				dynamic_optic_lenses[w.weapon_id] = lens
				if w.weapon_id == "ak47":
					active_optic_lens = lens
	if is_ugl_mode and (not current_weapon or not current_weapon.has_mechanic("underbarrel_grenade_launcher")):
		is_ugl_mode = false
	if is_aiming and (not current_weapon or not current_weapon.has_mechanic("ads_enabled")):
		set_aiming(false)
	emit_ammo_state()
	emit_tactical_state()
	_update_laser_and_flashlight()

func emit_tactical_state() -> void:
	if not current_weapon:
		tactical_state_changed.emit("", false, false, false, false, false, false, 0, 0, false)
		return
	var has_las: bool = current_weapon.has_mechanic("laser_sight")
	var has_fl: bool = current_weapon.has_mechanic("flashlight")
	var has_ugl: bool = current_weapon.has_mechanic("underbarrel_grenade_launcher")
	if not has_ugl and is_ugl_mode:
		is_ugl_mode = false
	tactical_state_changed.emit(
		current_weapon.get_fire_mode_label(),
		current_weapon.can_switch_fire_mode(),
		has_las,
		has_las and current_weapon.laser_enabled,
		has_fl,
		has_fl and current_weapon.flashlight_enabled,
		has_ugl,
		current_weapon.ugl_ammo,
		current_weapon.ugl_reserve,
		has_ugl and is_ugl_mode
	)

func toggle_ugl_mode() -> void:
	if not current_weapon or is_switching or is_quick_knifing or is_reloading or is_reloading_ugl:
		return
	if not current_weapon.has_mechanic("underbarrel_grenade_launcher"):
		return
	burst_shots_remaining = 0
	is_ugl_mode = not is_ugl_mode
	play_sfx(SoundEffects.create_magazine_in_sound(), 1.28 if is_ugl_mode else 1.08)
	if is_aiming:
		if is_ugl_mode:
			current_ads_zoom = 1.0
			ads_state_changed.emit(true, 1.0, "ugl_sight")
		else:
			var zrange := current_weapon.get_ads_zoom_range()
			var default_z: float = float(current_weapon.active_mechanics.get("ads_default_zoom", zrange.x))
			if current_weapon.saved_ads_zoom >= zrange.x - 0.01 and current_weapon.saved_ads_zoom <= zrange.y + 0.01:
				current_ads_zoom = clampf(current_weapon.saved_ads_zoom, zrange.x, zrange.y)
			else:
				current_ads_zoom = clampf(default_z, zrange.x, zrange.y)
			var reticle := str(current_weapon.active_mechanics.get("ads_reticle", "iron_sights"))
			ads_state_changed.emit(true, current_ads_zoom, reticle)
	emit_ammo_state()
	emit_tactical_state()

func toggle_fire_mode() -> void:
	if not current_weapon or is_switching or is_quick_knifing or is_reloading or is_reloading_ugl or is_switching_fire_mode:
		return
	if not current_weapon.can_switch_fire_mode():
		return
	burst_shots_remaining = 0
	var target_w: Weapon = current_weapon
	var new_mode: String = target_w.cycle_fire_mode()
	emit_tactical_state()
	_animate_fire_mode_switch(target_w, new_mode)

func _sync_fire_selector_mesh(w: Weapon) -> void:
	if not w:
		return
	if w.weapon_id == "ak47" and ak47_model:
		var sel := ak47_model.get_node_or_null("FireSelector")
		if sel:
			sel.rotation_degrees.x = 6.0 if w.current_fire_mode == "auto" else 20.0

func _animate_fire_mode_switch(target_w: Weapon, new_mode: String) -> void:
	is_switching_fire_mode = true
	var wid: String = target_w.weapon_id
	var ads_s: float = lerpf(1.0, 0.35, ads_blend)
	# Right-side AK selector tilts weapon left (+Z) to showcase the lever; left-side thumb switches tilt slightly right (-Z)
	var tilt_sign: float = 1.0 if wid == "ak47" else -0.75

	# Stage 1: Cant weapon inward as thumb/finger reaches for the fire selector
	var tw1 := create_tween()
	tw1.set_parallel(true)
	tw1.tween_property(self, "anim_pos", Vector3(-0.016 * tilt_sign * ads_s, -0.014 * ads_s, 0.020 * ads_s), 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw1.tween_property(self, "anim_rot", Vector3(deg_to_rad(5.5 * ads_s), deg_to_rad(5.0 * tilt_sign * ads_s), deg_to_rad(18.0 * tilt_sign * ads_s)), 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw1.finished
	if not is_instance_valid(self) or current_weapon != target_w or is_reloading or is_switching or is_quick_knifing:
		is_switching_fire_mode = false
		return

	# Stage 2: Crisp mechanical selector click + physical lever flip + tactile thumb flick jolt!
	var click_pitch: float = 1.24 if new_mode == "auto" else (1.42 if new_mode == "burst" else 1.58)
	play_sfx(SoundEffects.create_dry_fire_sound(), click_pitch)
	if wid == "ak47" and ak47_model:
		var sel := ak47_model.get_node_or_null("FireSelector")
		if sel:
			var target_deg: float = 6.0 if new_mode == "auto" else 20.0
			var tw_sel := create_tween()
			tw_sel.tween_property(sel, "rotation_degrees:x", target_deg, 0.065).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var flick_dir: float = -1.0 if new_mode == "semi" else 1.0
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(self, "anim_pos:y", (-0.014 + 0.008 * flick_dir) * ads_s, 0.055).set_trans(Tween.TRANS_QUAD)
	tw2.tween_property(self, "anim_rot:z", deg_to_rad((18.0 * tilt_sign + 4.5 * flick_dir) * ads_s), 0.055).set_trans(Tween.TRANS_QUAD)
	await tw2.finished
	if not is_instance_valid(self) or current_weapon != target_w or is_reloading or is_switching or is_quick_knifing:
		is_switching_fire_mode = false
		return

	# Stage 3: Smooth snap back to combat-ready alignment
	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(self, "anim_pos", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw3.tween_property(self, "anim_rot", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw3.finished
	is_switching_fire_mode = false

func toggle_laser() -> void:
	if not current_weapon or is_switching or is_quick_knifing:
		return
	if not current_weapon.has_mechanic("laser_sight"):
		return
	current_weapon.laser_enabled = not current_weapon.laser_enabled
	play_sfx(SoundEffects.create_dry_fire_sound(), 1.56)
	emit_tactical_state()
	_update_laser_and_flashlight()

func toggle_flashlight() -> void:
	if not current_weapon or is_switching or is_quick_knifing:
		return
	if not current_weapon.has_mechanic("flashlight"):
		return
	current_weapon.flashlight_enabled = not current_weapon.flashlight_enabled
	play_sfx(SoundEffects.create_dry_fire_sound(), 1.46)
	emit_tactical_state()
	_update_laser_and_flashlight()

func has_any_ugl() -> bool:
	for w in weapons:
		if w and w.has_mechanic("underbarrel_grenade_launcher"):
			return true
	return false

func add_ugl_grenades(amount: int) -> void:
	if amount <= 0:
		return
	for w in weapons:
		if w and w.has_mechanic("underbarrel_grenade_launcher"):
			w.ugl_reserve += amount
			if w.ugl_ammo <= 0 and w.ugl_reserve > 0:
				w.ugl_ammo = 1
				w.ugl_reserve -= 1
	emit_tactical_state()

func try_fire_ugl() -> void:
	if not current_weapon or is_switching or is_quick_knifing or is_reloading or is_reloading_ugl:
		return
	if not current_weapon.has_mechanic("underbarrel_grenade_launcher"):
		return
	if current_weapon.ugl_ammo <= 0:
		# No automatic reload: only dry-fire click until player presses [R]!
		play_dry_fire_sound()
		return
	if not camera:
		return

	var firing_w: Weapon = current_weapon
	firing_w.ugl_ammo -= 1
	can_shoot = false
	shoot_timer = 0.45
	emit_ammo_state()
	emit_tactical_state()

	# Heavy hollow 40mm UGL thump recoil & sound
	recoil_vel += Vector3(0.0, 0.34, 1.15)
	recoil_rot_vel += Vector3(1.85, randf_range(-0.25, 0.25), randf_range(-0.3, 0.3))
	var player_node: Node = owner
	if player_node and player_node.has_method("add_camera_recoil"):
		player_node.add_camera_recoil(0.055, randf_range(-0.015, 0.015))
	if player_node and player_node.has_method("add_camera_shake"):
		player_node.add_camera_shake(0.05)
	play_sfx(SoundEffects.create_shotgun_sound(), 0.56)

	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var center: Vector2 = get_viewport().get_visible_rect().size / 2.0
	var ray_origin: Vector3 = camera.project_ray_origin(center)
	var ray_dir: Vector3 = camera.project_ray_normal(center)
	var spawn_pos: Vector3 = ray_origin + ray_dir * 0.72 + Vector3(0.0, -0.06, 0.0)
	var exclude_rids: Array[RID] = []
	var player_body: CollisionObject3D = owner as CollisionObject3D
	if player_body:
		exclude_rids.append(player_body.get_rid())
	var q_chk := PhysicsRayQueryParameters3D.create(ray_origin, spawn_pos)
	q_chk.exclude = exclude_rids
	q_chk.collide_with_bodies = true
	var r_chk := space_state.intersect_ray(q_chk)
	if not r_chk.is_empty():
		spawn_pos = ray_origin + ray_dir * maxf(0.35, ray_origin.distance_to(r_chk.position) - 0.12)

	var dmg: float = float(firing_w.active_mechanics.get("ugl_damage", 480.0))
	var rad: float = float(firing_w.active_mechanics.get("ugl_radius", 8.5))
	var gren: Node3D = UGLGrenadeScript.new()
	gren.position = spawn_pos
	get_tree().root.add_child(gren)
	gren.init(spawn_pos, (ray_dir + Vector3(0.0, 0.06, 0.0)).normalized(), owner, self, dmg, rad)

func _reload_ugl_async(target_w: Weapon) -> void:
	if is_reloading_ugl or not target_w:
		return
	if target_w.ugl_ammo >= 1:
		return
	if target_w.ugl_reserve <= 0 and not infinite_reserve_ammo:
		return
	is_reloading_ugl = true
	set_aiming(false)
	emit_ammo_state()
	emit_tactical_state()

	# Tactile 40mm underbarrel loading animation (cant rifle up/inboard, thumb-load VOG-25/M406, latch lock)
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	tw_tilt.tween_property(self, "anim_pos", Vector3(-0.04, -0.09, 0.04), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(14.0), deg_to_rad(16.0), deg_to_rad(28.0)), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_tilt.finished
	if not is_instance_valid(self) or current_weapon != target_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		is_reloading_ugl = false
		emit_ammo_state()
		emit_tactical_state()
		return

	play_sfx(SoundEffects.create_shell_insert_sound(), 0.72)
	var tw_push := create_tween()
	tw_push.tween_property(self, "anim_pos:z", 0.075, 0.22).set_trans(Tween.TRANS_QUAD)
	tw_push.tween_property(self, "anim_pos:z", 0.04, 0.18)
	await tw_push.finished
	await get_tree().create_timer(0.45).timeout
	if not is_instance_valid(self) or current_weapon != target_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		is_reloading_ugl = false
		emit_ammo_state()
		emit_tactical_state()
		return

	if target_w.ugl_ammo <= 0:
		if infinite_reserve_ammo:
			target_w.ugl_ammo = 1
		elif target_w.ugl_reserve > 0:
			target_w.ugl_reserve -= 1
			target_w.ugl_ammo = 1
	play_sfx(SoundEffects.create_magazine_in_sound(), 0.88)

	var tw_back := create_tween()
	tw_back.set_parallel(true)
	tw_back.tween_property(self, "anim_pos", Vector3.ZERO, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_back.tween_property(self, "anim_rot", Vector3.ZERO, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_back.finished

	is_reloading_ugl = false
	can_shoot = true
	emit_ammo_state()
	emit_tactical_state()

func _update_laser_and_flashlight() -> void:
	if not tactical_laser_beam or not tactical_laser_dot or not tactical_flashlight:
		return
	var can_show: bool = (current_weapon != null) and (not is_switching) and (not is_quick_knifing) and (camera != null)
	var mdl: Node3D = _get_model_for_weapon_id(current_weapon.weapon_id) if current_weapon else null
	if not mdl or not mdl.visible:
		can_show = false

	# 1) Tactical Laser Sight (3D beam & surface dot strictly aligned to weapon emitter/barrel direction!)
	var show_laser: bool = can_show and current_weapon.has_mechanic("laser_sight") and current_weapon.laser_enabled
	if show_laser:
		var col_raw = current_weapon.active_mechanics.get("laser_color", Color(1.0, 0.12, 0.10))
		var l_col: Color = col_raw if (col_raw is Color) else (Color(0.14, 1.0, 0.28) if str(col_raw) == "green" else Color(1.0, 0.12, 0.10))
		if tactical_laser_mat:
			tactical_laser_mat.albedo_color = Color(l_col.r, l_col.g, l_col.b, 0.78)
			tactical_laser_mat.emission = l_col

		var emitter := mdl.find_child("LaserEmitter", true, false) as Marker3D
		var laser_dir: Vector3 = (-emitter.global_transform.basis.z).normalized() if emitter else (-mdl.global_transform.basis.z).normalized()
		var origin_pt: Vector3 = emitter.global_position if emitter else (mdl.global_position + laser_dir * 0.45)

		var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
		var exclude_rids: Array[RID] = []
		var player_body: CollisionObject3D = owner as CollisionObject3D
		if player_body:
			exclude_rids.append(player_body.get_rid())
		# Start ray slightly behind emitter along the weapon's bore axis so close walls never pass behind the emitter
		var ray_start: Vector3 = origin_pt - laser_dir * 0.12
		var ray_end: Vector3 = origin_pt + laser_dir * 100.0
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = exclude_rids
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var res := space_state.intersect_ray(query)
		var end_pt: Vector3 = res.position if not res.is_empty() else ray_end
		var forward_dist: float = (end_pt - origin_pt).dot(laser_dir)
		if forward_dist > 0.04:
			tactical_laser_beam.visible = true
			tactical_laser_beam.global_position = origin_pt + laser_dir * (forward_dist * 0.5)
			var up_ref: Vector3 = Vector3.RIGHT if absf(laser_dir.dot(Vector3.UP)) > 0.98 else Vector3.UP
			var x_ax: Vector3 = laser_dir.cross(up_ref).normalized()
			var z_ax: Vector3 = x_ax.cross(laser_dir).normalized()
			tactical_laser_beam.global_basis = Basis(x_ax, laser_dir, z_ax)
			tactical_laser_beam.scale = Vector3(1.0, forward_dist, 1.0)
		else:
			tactical_laser_beam.visible = false

		if not res.is_empty() and forward_dist > 0.02:
			tactical_laser_dot.visible = true
			tactical_laser_dot.global_position = end_pt + res.normal * 0.018
		else:
			tactical_laser_dot.visible = false
	else:
		tactical_laser_beam.visible = false
		tactical_laser_dot.visible = false

	# 2) Tactical Weapon Flashlight (Real 3D SpotLight3D aligned to weapon barrel/emitter direction!)
	var show_light: bool = can_show and current_weapon.has_mechanic("flashlight") and current_weapon.flashlight_enabled
	if show_light:
		var fl_em := mdl.find_child("FlashlightEmitter", true, false) as Marker3D
		var fl_basis: Basis = fl_em.global_transform.basis.orthonormalized() if fl_em else mdl.global_transform.basis.orthonormalized()
		var fl_pos: Vector3 = fl_em.global_position if fl_em else (mdl.global_position - fl_basis.z * 0.45)
		tactical_flashlight.visible = true
		tactical_flashlight.global_position = fl_pos
		tactical_flashlight.global_basis = fl_basis
		tactical_flashlight.light_energy = float(current_weapon.active_mechanics.get("flashlight_energy", 7.5))
		tactical_flashlight.spot_range = float(current_weapon.active_mechanics.get("flashlight_range", 40.0))
	else:
		tactical_flashlight.visible = false

func set_aiming(aim: bool) -> void:
	if aim:
		if not current_weapon or not current_weapon.has_mechanic("ads_enabled"):
			aim = false
		elif is_reloading or is_switching or is_quick_knifing:
			aim = false
	if is_aiming == aim:
		return
	is_aiming = aim
	# Hide floating 3D world labels above objects during ADS
	for fl in get_tree().get_nodes_in_group("floating_3d_label"):
		if is_instance_valid(fl) and fl is Node3D:
			(fl as Node3D).visible = not is_aiming
	if is_aiming and current_weapon:
		if is_ugl_mode:
			current_ads_zoom = 1.0
			ads_state_changed.emit(true, 1.0, "ugl_sight")
		else:
			var zrange := current_weapon.get_ads_zoom_range()
			var default_z: float = float(current_weapon.active_mechanics.get("ads_default_zoom", zrange.x))
			if current_weapon.saved_ads_zoom >= zrange.x - 0.01 and current_weapon.saved_ads_zoom <= zrange.y + 0.01:
				current_ads_zoom = clampf(current_weapon.saved_ads_zoom, zrange.x, zrange.y)
			else:
				current_ads_zoom = clampf(default_z, zrange.x, zrange.y)
				current_weapon.saved_ads_zoom = current_ads_zoom
			var reticle := str(current_weapon.active_mechanics.get("ads_reticle", "iron_sights"))
			ads_state_changed.emit(true, current_ads_zoom, reticle)
	else:
		current_ads_zoom = 1.0
		ads_state_changed.emit(false, 1.0, "")

func adjust_ads_zoom(step: float) -> bool:
	if is_ugl_mode or not is_aiming or not current_weapon or not current_weapon.has_mechanic("ads_enabled"):
		return false
	var zrange := current_weapon.get_ads_zoom_range()
	if zrange.y <= zrange.x + 0.01:
		return false
	current_ads_zoom = clampf(current_ads_zoom + step, zrange.x, zrange.y)
	current_weapon.saved_ads_zoom = current_ads_zoom
	var reticle := str(current_weapon.active_mechanics.get("ads_reticle", "lpvo_crosshair"))
	ads_state_changed.emit(true, current_ads_zoom, reticle)
	return true

# ==========================================
# FRAME-BY-FRAME LAYERED SPRING-DAMPER ANIMATION ENGINE
# ==========================================
func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if shoot_timer > 0.0:
		shoot_timer -= dt
		if shoot_timer <= 0.0 and not is_reloading and not is_switching and not is_quick_knifing:
			can_shoot = true

	# 3-Round Burst automatic follow-up firing
	if burst_shots_remaining > 0:
		if is_reloading or is_switching or is_quick_knifing or not current_weapon or current_weapon.current_ammo <= 0:
			burst_shots_remaining = 0
		else:
			burst_timer -= dt
			if burst_timer <= 0.0 and can_shoot:
				burst_shots_remaining -= 1
				burst_timer = maxf(0.052, current_weapon.fire_rate * 0.88)
				execute_shoot()
			
	if is_aiming and (is_reloading or is_switching or is_quick_knifing or not current_weapon or not current_weapon.has_mechanic("ads_enabled")):
		set_aiming(false)
		
	if dry_fire_cooldown > 0.0:
		dry_fire_cooldown -= dt

	# Dynamic spread bloom & sustained burst recovery (scales with weapon ergonomics)
	if shot_recovery_timer > 0.0:
		shot_recovery_timer -= dt
		if shot_recovery_timer <= 0.0:
			consecutive_shots = 0
	if dynamic_spread_bloom > 0.0:
		var ergo_rec: float = (current_weapon.ergonomics / 55.0) if current_weapon else 1.0
		var decay_spd: float = (0.075 if shot_recovery_timer <= 0.0 else 0.025) * clampf(ergo_rec, 0.6, 1.6)
		dynamic_spread_bloom = maxf(0.0, dynamic_spread_bloom - decay_spd * dt)
		
	# 1. Smooth S-curve ADS, UGL Mode & Tactical Sprint Low-Ready blending
	var target_ads: float = 1.0 if is_aiming else 0.0
	ads_blend = lerpf(ads_blend, target_ads, dt * 14.0)
	ugl_mode_blend = lerpf(ugl_mode_blend, 1.0 if is_ugl_mode else 0.0, dt * 11.0)
	var want_sprint_pose: bool = is_sprinting_now and not is_aiming and not is_reloading and not is_reloading_ugl and not is_switching and not is_quick_knifing and (shoot_timer <= 0.0)
	sprint_blend = lerpf(sprint_blend, 1.0 if want_sprint_pose else 0.0, dt * 9.0)
	
	# Subtle 7% alive movement in ADS across ALL weapons (AK-47, Shotgun, Pistol, RPG-7) so sights & optics stay steady
	var ads_damp: float = lerpf(1.0, 0.07, ads_blend)
	
	# 2. Second-order spring-damper physics for crisp, punchy firing recoil!
	var stiffness: float = 195.0
	var damping: float = 21.0
	recoil_vel += (-stiffness * recoil_pos - damping * recoil_vel) * dt
	recoil_pos += recoil_vel * dt
	recoil_rot_vel += (-stiffness * recoil_rot - damping * recoil_rot_vel) * dt
	recoil_rot += recoil_rot_vel * dt
	
	# 3. Organic idle breathing (figure-8 micro-drift)
	idle_timer += dt * 1.9
	var idle_pos := Vector3(
		sin(idle_timer) * 0.0024 * ads_damp,
		cos(idle_timer * 2.0) * 0.0022 * ads_damp,
		0.0
	)
	var idle_rot := Vector3(
		cos(idle_timer * 1.3) * 0.003 * ads_damp,
		sin(idle_timer * 0.8) * 0.002 * ads_damp,
		sin(idle_timer) * 0.004 * ads_damp
	)
	
	# 4. Sway & walk bob smooth recovery
	var sway_decay: float = 12.0 if is_aiming else 8.0
	sway_pos = sway_pos.lerp(Vector3.ZERO, dt * sway_decay)
	sway_rot = sway_rot.lerp(Vector3.ZERO, dt * sway_decay)
	var bob_decay: float = 11.0 if is_aiming else 7.0
	bob_pos = bob_pos.lerp(Vector3.ZERO, dt * bob_decay)
	bob_rot = bob_rot.lerp(Vector3.ZERO, dt * bob_decay)
	
	# 5. Compute Tactical Sprint Low-Ready Pose tailored to each weapon
	var sp_pos := Vector3(-0.075, -0.055, 0.025)
	var sp_rot := Vector3(deg_to_rad(-16.0), deg_to_rad(32.0), deg_to_rad(14.0))
	if current_weapon:
		match current_weapon.weapon_id:
			"pistol", "deagle":
				sp_pos = Vector3(-0.035, -0.065, 0.02)
				sp_rot = Vector3(deg_to_rad(-24.0), deg_to_rad(18.0), deg_to_rad(10.0))
			"rpg":
				sp_pos = Vector3(0.02, -0.04, 0.04)
				sp_rot = Vector3(deg_to_rad(12.0), deg_to_rad(14.0), deg_to_rad(-8.0))
			"pkm", "mg42":
				sp_pos = Vector3(-0.05, -0.08, 0.05)
				sp_rot = Vector3(deg_to_rad(-12.0), deg_to_rad(24.0), deg_to_rad(10.0))
	
	# 6. Exact close eye-to-sight / eye-to-optic ADS alignment (plus dedicated UGL lob-aiming pose!)
	var ads_pos := _get_active_ads_pos()
	var ugl_hip_pos := Vector3(-0.028, 0.032, 0.022) * ugl_mode_blend
	var ugl_hip_rot := Vector3(deg_to_rad(6.5), deg_to_rad(3.5), deg_to_rad(-6.5)) * ugl_mode_blend
	var ugl_ads_rot := Vector3(deg_to_rad(9.0), deg_to_rad(1.0), deg_to_rad(-4.5)) * ugl_mode_blend
	var hip_with_sprint := initial_pos + sp_pos * sprint_blend + ugl_hip_pos * (1.0 - sprint_blend)
	var base_pos := hip_with_sprint.lerp(ads_pos, ads_blend)
	var base_rot := (sp_rot * sprint_blend + ugl_hip_rot * (1.0 - sprint_blend)).lerp(ugl_ads_rot, ads_blend)
	
	# Combine all clean additive layers!
	var rec_mult: float = lerpf(1.0, 0.45, ads_blend)
	position = base_pos + idle_pos + sway_pos * ads_damp + bob_pos * ads_damp + recoil_pos * rec_mult + anim_pos + draw_pos
	rotation = base_rot + idle_rot + sway_rot * ads_damp + bob_rot * ads_damp + recoil_rot * rec_mult + anim_rot + draw_rot
	
	# 7. Update PiP Scope Viewport, Magnifying/NVG/Thermal Lens Shader & Tactical Laser/Flashlight
	_update_pip_scope()
	_update_laser_and_flashlight()
	
	# 8. Update animated mechanical sub-parts
	if shotgun_pump and shotgun_model and shotgun_model.visible:
		shotgun_pump.position.z = initial_pump_z + pump_offset_z
		if shotgun_bolt:
			shotgun_bolt.position.z = initial_sg_bolt_z + pump_offset_z * 0.92
		if shotgun_elevator:
			shotgun_elevator.position.y = initial_elevator_y + elevator_offset_y
	if ak_charging_handle and ak47_model and ak47_model.visible:
		ak_charging_handle.position.z = initial_ak_handle_z + ak_handle_offset_z
	if pistol_slide and pistol_model and pistol_model.visible:
		var lock_off: float = 0.036 if pistol_slide_locked_back else 0.0
		pistol_slide.position.z = initial_pistol_slide_z + maxf(pistol_slide_offset_z, lock_off)
	if deagle_slide and deagle_model and deagle_model.visible:
		var dlock_off: float = 0.044 if deagle_slide_locked_back else 0.0
		deagle_slide.position.z = deagle_slide_initial_z + maxf(deagle_slide_offset_z, dlock_off)
	if pkm_charging_handle and pkm_model and pkm_model.visible:
		pkm_charging_handle.position.z = pkm_handle_initial_z + pkm_handle_offset_z
	if mg42_charging_handle and mg42_model and mg42_model.visible:
		mg42_charging_handle.position.z = mg42_handle_initial_z + mg42_handle_offset_z
	if aa12_charging_handle and aa12_model and aa12_model.visible:
		aa12_charging_handle.position.z = aa12_handle_initial_z + aa12_handle_offset_z

func _get_active_ads_pos() -> Vector3:
	if not current_weapon:
		return Vector3(0.0, -0.066, -0.185)
	if is_ugl_mode:
		# Lowered, centered quadrant-sight ADS pose giving an unobstructed view through the 40mm ballistic ladder!
		return Vector3(-0.015, -0.145, -0.168)
	var fallback_pos := Vector3(0.0, -0.066, -0.185)
	match current_weapon.weapon_id:
		"ak47":
			fallback_pos = Vector3(0.0, -0.066, -0.240)
		"shotgun":
			fallback_pos = Vector3(0.0, -0.055, -0.235)
		"pistol":
			fallback_pos = Vector3(0.020, -0.054, -0.260)
		"rpg":
			fallback_pos = Vector3(0.012, -0.094, -0.120)
		"kar98k":
			fallback_pos = Vector3(0.0, -0.0485, -0.235)
		"pkm":
			fallback_pos = Vector3(-0.020, -0.052, -0.240)
		"l96a1":
			fallback_pos = Vector3(0.0, -0.082, -0.192)
		"deagle":
			fallback_pos = Vector3(0.018, -0.074, -0.275)
		"aa12":
			fallback_pos = Vector3(-0.010, -0.078, -0.235)
		"mg42":
			fallback_pos = Vector3(-0.020, -0.044, -0.240)
	return WeaponModVisualsScript.get_ads_pos_for_mods(current_weapon.weapon_id, current_weapon.installed_mods, fallback_pos)

func _get_active_pip_lens() -> MeshInstance3D:
	if not current_weapon:
		return null
	var wid: String = current_weapon.weapon_id
	var mdl: Node3D = _get_model_for_weapon_id(wid)
	if not mdl or not mdl.visible:
		return null
	var dyn_lens = dynamic_optic_lenses.get(wid, null)
	if is_instance_valid(dyn_lens) and dyn_lens is MeshInstance3D and dyn_lens.is_visible_in_tree():
		return dyn_lens as MeshInstance3D
	if wid == "rpg" and is_instance_valid(rpg_optic_lens) and rpg_optic_lens.is_visible_in_tree():
		return rpg_optic_lens
	if wid == "l96a1" and is_instance_valid(l96a1_optic_lens) and l96a1_optic_lens.is_visible_in_tree():
		return l96a1_optic_lens
	return null

func _update_pip_scope() -> void:
	if not scope_viewport or not scope_camera:
		return
	var target_lens: MeshInstance3D = _get_active_pip_lens()
	var vis_mode: String = str(current_weapon.active_mechanics.get("vision_mode", "")) if current_weapon else ""
	var is_magnifying: bool = current_weapon != null and (current_weapon.get_ads_zoom_range().y > 1.05 or vis_mode == "nvg" or vis_mode == "thermal")
	var pip_active: bool = (not is_ugl_mode) and (ads_blend > 0.05) and is_magnifying and current_weapon.has_mechanic("ads_enabled") and is_instance_valid(target_lens)
	
	# Always disable PiP on any non-active lens so switching weapons/mods never leaves stale state
	var all_lenses: Array = [active_optic_lens, rpg_optic_lens, l96a1_optic_lens]
	for dl in dynamic_optic_lenses.values():
		if not all_lenses.has(dl):
			all_lenses.append(dl)
	for lens in all_lenses:
		if is_instance_valid(lens) and (not pip_active or lens != target_lens):
			var inactive_mat := lens.material_override as ShaderMaterial
			if inactive_mat:
				inactive_mat.set_shader_parameter("use_pip", false)
				
	if pip_active and camera:
		scope_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		scope_camera.global_transform = camera.global_transform
		var eff_zoom: float = lerpf(1.0, maxf(1.0, current_ads_zoom), ads_blend)
		# True optical angular magnification across full 1.5x..12.0x range!
		var base_scope_fov: float = 30.0
		var half_rad: float = atan(tan(deg_to_rad(base_scope_fov * 0.5)) / maxf(1.0, eff_zoom))
		scope_camera.fov = clampf(rad_to_deg(half_rad * 2.0), 1.4, 45.0)
		var mat := target_lens.material_override as ShaderMaterial
		if vis_mode == "thermal":
			scope_camera.cull_mask = 1 | 4 # World (Layer 1) + 3D Thermal Heat Silhouette Proxies (Layer 3)
			_thermal_sync_timer -= get_process_delta_time()
			if _thermal_sync_timer <= 0.0:
				_thermal_sync_timer = 0.14
				sync_thermal_proxies()
		else:
			scope_camera.cull_mask = 1
		if mat:
			mat.set_shader_parameter("pip_tex", scope_viewport.get_texture())
			mat.set_shader_parameter("use_pip", true)
	else:
		scope_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		scope_camera.cull_mask = 1
		_thermal_sync_timer = 0.0

func _get_thermal_heat_mat(heat: float) -> StandardMaterial3D:
	var key: int = int(round(clampf(heat, 0.50, 1.0) * 100.0))
	if _thermal_heat_mats.has(key):
		return _thermal_heat_mats[key]
	var h: float = float(key) / 100.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(h, 0.0, 1.0, 1.0)
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	_thermal_heat_mats[key] = mat
	return mat

func _set_mesh_thermal_proxy(src: MeshInstance3D, heat: float, active: bool) -> void:
	if not is_instance_valid(src) or not src.mesh:
		return
	var existing := src.get_node_or_null("ThermalHeatProxy") as MeshInstance3D
	if not active:
		if existing:
			existing.visible = false
		return
	if not existing:
		existing = MeshInstance3D.new()
		existing.name = "ThermalHeatProxy"
		existing.mesh = src.mesh
		existing.layers = 4 # Layer 3 ONLY — invisible to main camera, visible to FLIR scope_camera!
		existing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		existing.scale = Vector3(1.018, 1.018, 1.018)
		src.add_child(existing)
	existing.material_override = _get_thermal_heat_mat(heat)
	existing.visible = src.visible

func _set_subtree_thermal_proxies(node: Node, heat: float, active: bool, skip_names: Array[String] = []) -> void:
	if not is_instance_valid(node):
		return
	var nname: String = String(node.name)
	if nname == "ThermalHeatProxy":
		return
	for sk in skip_names:
		if nname == sk or nname.begins_with(sk):
			return
	if node is MeshInstance3D:
		_set_mesh_thermal_proxy(node as MeshInstance3D, heat, active)
	for ch in node.get_children():
		_set_subtree_thermal_proxies(ch, heat, active, skip_names)

func _sync_vehicle_heat_parts(root: Node, is_tiger: bool, vehicle_node: Node) -> void:
	if not is_instance_valid(root):
		return
	var stack: Array[Node] = [root]
	var is_destroyed: bool = bool(vehicle_node.get("is_dead")) if ("is_dead" in vehicle_node) else false
	if is_tiger:
		is_destroyed = vehicle_node.is_in_group("tiger_wreck") or (int(vehicle_node.get("boss_state")) == 3 if ("boss_state" in vehicle_node) else false)
	var tiger_crew_alive: Dictionary = vehicle_node.get("crew_alive") if (is_tiger and "crew_alive" in vehicle_node) else {}
	var tiger_engine_dead: bool = bool(vehicle_node.get("engine_destroyed")) if (is_tiger and "engine_destroyed" in vehicle_node) else false

	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		var cname: String = String(cur.name)
		if cname == "ThermalHeatProxy":
			continue

		if is_tiger:
			# Living crew silhouettes inside hatches / behind optic ports (go cold immediately when killed!)
			if cname == "CrewModel_Commander":
				_set_subtree_thermal_proxies(cur, 0.97, (not is_destroyed) and bool(tiger_crew_alive.get("commander", false)))
				continue
			elif cname == "CrewModel_Driver":
				_set_subtree_thermal_proxies(cur, 0.96, (not is_destroyed) and bool(tiger_crew_alive.get("driver", false)))
				continue
			elif cname == "CrewModel_Radio":
				_set_subtree_thermal_proxies(cur, 0.96, (not is_destroyed) and bool(tiger_crew_alive.get("radio", false)))
				continue
			elif cname == "CrewModel_Gunner":
				_set_subtree_thermal_proxies(cur, 0.96, (not is_destroyed) and bool(tiger_crew_alive.get("gunner", false)))
				continue

			if cur is MeshInstance3D:
				var heat: float = 0.0
				if cname.begins_with("ExhaustPipe") or cname.begins_with("ExhaustShroud"):
					heat = 0.98 if not is_destroyed else 0.72
				elif cname.begins_with("grille_l_") or cname.begins_with("grille_r_"):
					heat = 1.00 if (tiger_engine_dead or is_destroyed) else 0.94
				elif cname == "BlownTurretCrater":
					heat = 0.92
				elif cname in ["BarrelRear", "BarrelFront", "MuzzleCollar", "MuzzleBrake"]:
					heat = 0.72 if not is_destroyed else 0.56
				elif cname in ["CoaxBarrel", "HullMGBarrel"]:
					heat = 0.68 if not is_destroyed else 0.0
				if heat > 0.0:
					_set_mesh_thermal_proxy(cur as MeshInstance3D, heat, true)
				else:
					_set_mesh_thermal_proxy(cur as MeshInstance3D, 0.0, false)
		else:
			# Black Minivan (Busik): living driver & passengers + front engine hood/radiator + warm rolling tires!
			if cname == "DriverGreenStrawHat" or cname.begins_with("Passenger_"):
				_set_subtree_thermal_proxies(cur, 0.97, not is_destroyed)
				continue
			if cur is MeshInstance3D:
				var heat_v: float = 0.0
				if cname in ["FrontHood", "FrontHoodSlope", "FrontGrille"] or cname.begins_with("GrilleBar_"):
					heat_v = 0.96 if is_destroyed else 0.92
				elif cname == "RearExhaustPipe":
					heat_v = 0.96 if not is_destroyed else 0.65
				elif cname == "Tire":
					heat_v = 0.62 if not is_destroyed else 0.0
				elif is_destroyed and cname in ["ChassisFloor", "Roof", "Dashboard"]:
					heat_v = 0.84
				if heat_v > 0.0:
					_set_mesh_thermal_proxy(cur as MeshInstance3D, heat_v, true)
				else:
					_set_mesh_thermal_proxy(cur as MeshInstance3D, 0.0, false)

		for ch in cur.get_children():
			stack.append(ch)

func sync_thermal_proxies() -> void:
	if not is_inside_tree():
		return
	var visited: Dictionary = {}
	var all_targets: Array = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and not visited.has(e.get_instance_id()):
			visited[e.get_instance_id()] = true
			all_targets.append(e)
	for tw in get_tree().get_nodes_in_group("tiger_wreck"):
		if is_instance_valid(tw) and not visited.has(tw.get_instance_id()):
			visited[tw.get_instance_id()] = true
			all_targets.append(tw)
	for mw in get_tree().get_nodes_in_group("mi24_wreck"):
		if is_instance_valid(mw) and not visited.has(mw.get_instance_id()):
			visited[mw.get_instance_id()] = true
			all_targets.append(mw)

	for ent in all_targets:
		if not (ent is Node3D):
			continue
		if ent.is_in_group("tiger_boss") or ent.is_in_group("tiger_wreck"):
			_sync_vehicle_heat_parts(ent, true, ent)
		elif ent.is_in_group("black_minivan"):
			_sync_vehicle_heat_parts(ent, false, ent)
		elif ent.is_in_group("mi24_boss") or ent.is_in_group("mi24_wreck"):
			_sync_mi24_heat_parts(ent)
		elif "prop_node" in ent:
			# Shahed-136 Kamikaze Drone: blazing rear boxer engine/exhausts + mini green pilot silhouette; cold wings!
			var d_alive: bool = not bool(ent.get("is_dead"))
			var vis_d: Node = (ent as Node).get_node_or_null("Visuals")
			if vis_d:
				var pilot: Node = vis_d.get_node_or_null("GreenCrewmatePilot")
				if pilot:
					_set_subtree_thermal_proxies(pilot, 0.96, d_alive)
				for ch in vis_d.get_children():
					var cn: String = String(ch.name)
					if cn == "GreenCrewmatePilot" or cn == "ThermalHeatProxy":
						continue
					if ch is MeshInstance3D:
						if cn == "EngineNacelle" or cn == "CylinderHead" or cn == "ExhaustPipe":
							_set_mesh_thermal_proxy(ch as MeshInstance3D, 0.98, d_alive)
						elif cn == "Fuselage":
							_set_mesh_thermal_proxy(ch as MeshInstance3D, 0.62, d_alive)
						else:
							_set_mesh_thermal_proxy(ch as MeshInstance3D, 0.0, false)
		else:
			# Living Infantry Enemy: full animated 3D model silhouette glows white-hot (cold weapon & ballistic shield excluded!)
			var alive: bool = true
			if "is_dead" in ent and bool(ent.get("is_dead")):
				alive = false
			elif "health" in ent and float(ent.get("health")) <= 0.0:
				alive = false
			var vis: Node = (ent as Node).get_node_or_null("Visuals")
			if vis:
				_set_subtree_thermal_proxies(vis, 0.96, alive, ["Blaster", "HealthBar", "ScopeGlint", "BallisticShield"])
			else:
				_set_subtree_thermal_proxies(ent, 0.96, alive, ["Blaster", "HealthBar", "ScopeGlint", "BallisticShield"])

func _sync_mi24_heat_parts(heli_node: Node) -> void:
	if not is_instance_valid(heli_node):
		return
	var is_down: bool = heli_node.is_in_group("mi24_wreck") or (bool(heli_node.get("is_dead")) if ("is_dead" in heli_node) else false)
	var pilot_alive: bool = bool(heli_node.get("pilot_alive")) if ("pilot_alive" in heli_node) else (not is_down)
	var gunner_alive: bool = bool(heli_node.get("gunner_alive")) if ("gunner_alive" in heli_node) else (not is_down)
	var stack: Array[Node] = [heli_node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		var cname: String = String(cur.name)
		if cname == "ThermalHeatProxy":
			continue
		if cname == "CrewPilot":
			_set_subtree_thermal_proxies(cur, 0.97, pilot_alive and not is_down)
			continue
		elif cname == "CrewGunner":
			_set_subtree_thermal_proxies(cur, 0.97, gunner_alive and not is_down)
			continue
		if cur is MeshInstance3D:
			var heat_h: float = 0.0
			if cname.begins_with("ExhaustPort") or cname.begins_with("EngineNacelle"):
				heat_h = 1.00 if not is_down else 0.88
			elif is_down and cname in ["FuselageMain", "FuselageCamoPatch", "RotorHub"]:
				heat_h = 0.72
			elif cname == "ChinGunBarrel" or cname == "RotorHub":
				heat_h = 0.76 if not is_down else 0.0
			if heat_h > 0.0:
				_set_mesh_thermal_proxy(cur as MeshInstance3D, heat_h, true)
			else:
				_set_mesh_thermal_proxy(cur as MeshInstance3D, 0.0, false)
		for ch in cur.get_children():
			stack.append(ch)

func apply_mouse_sway(mouse_relative: Vector2) -> void:
	if is_switching:
		return
	var sway_amount_rot: float = 0.0017
	var sway_amount_pos: float = 0.00065
	sway_rot.y = clampf(sway_rot.y - mouse_relative.x * sway_amount_rot, -0.13, 0.13)
	sway_rot.x = clampf(sway_rot.x - mouse_relative.y * sway_amount_rot, -0.10, 0.10)
	sway_rot.z = clampf(sway_rot.z + mouse_relative.x * sway_amount_rot * 0.8, -0.09, 0.09)
	sway_pos.x = clampf(sway_pos.x - mouse_relative.x * sway_amount_pos, -0.038, 0.038)
	sway_pos.y = clampf(sway_pos.y + mouse_relative.y * sway_amount_pos, -0.032, 0.032)

func apply_movement_bob(horiz_speed: float, is_sprinting: bool, delta: float) -> void:
	is_sprinting_now = is_sprinting and horiz_speed > 1.2
	if horiz_speed > 0.5:
		var speed_mult: float = 1.42 if is_sprinting else 1.0
		walk_bob_timer += delta * (10.5 * speed_mult)
		var amp: float = 0.019 if is_sprinting else 0.011
		bob_pos.x = sin(walk_bob_timer * 0.5) * amp * 1.55
		bob_pos.y = -absf(cos(walk_bob_timer * 0.5)) * amp * 1.15
		bob_rot.z = -sin(walk_bob_timer * 0.5) * (0.065 if is_sprinting else 0.038)
		bob_rot.x = sin(walk_bob_timer) * (0.032 if is_sprinting else 0.018)
	else:
		walk_bob_timer = 0.0

# ==========================================
# REBUILT UNIQUE EQUIP / DRAW & HOLSTER ANIMATIONS
# ==========================================
func switch_weapon(idx: int, animate: bool = true) -> void:
	if is_switching or is_quick_knifing:
		return
	if not is_weapon_slot_unlocked(idx):
		return
	if idx == current_weapon_idx and current_weapon == weapon_slots[idx] and animate:
		return
	if is_reloading:
		is_reloading = false
		shotgun_cancel_reload = true
	set_aiming(false)
	anim_pos = Vector3.ZERO
	anim_rot = Vector3.ZERO
	
	if animate:
		is_switching = true
		can_shoot = false
		
		# Dynamic holster sweep-down & cant
		var tw_down := create_tween()
		tw_down.set_parallel(true)
		tw_down.tween_property(self, "draw_pos", Vector3(0.06, -0.34, 0.08), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_down.tween_property(self, "draw_rot", Vector3(deg_to_rad(-28.0), deg_to_rad(-18.0), deg_to_rad(-20.0)), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_down.finished
		
		set_active_model_visible(idx)
		
		# Unique weapon draw sweep-up per class!
		var wid: String = current_weapon.weapon_id if current_weapon else ""
		var draw_dur: float = 0.24
		match wid:
			"pistol", "deagle":
				draw_pos = Vector3(0.08, -0.28, 0.06)
				draw_rot = Vector3(deg_to_rad(32.0), deg_to_rad(-14.0), deg_to_rad(24.0))
				draw_dur = 0.19 if wid == "deagle" else 0.17
			"shotgun", "aa12":
				draw_pos = Vector3(-0.06, -0.36, 0.10)
				draw_rot = Vector3(deg_to_rad(-22.0), deg_to_rad(28.0), deg_to_rad(-18.0))
				draw_dur = 0.27
			"rpg", "pkm", "mg42":
				draw_pos = Vector3(0.14, -0.40, 0.16)
				draw_rot = Vector3(deg_to_rad(-34.0), deg_to_rad(-22.0), deg_to_rad(18.0))
				draw_dur = 0.34
			"kar98k", "l96a1":
				draw_pos = Vector3(0.06, -0.35, 0.10)
				draw_rot = Vector3(deg_to_rad(-20.0), deg_to_rad(24.0), deg_to_rad(14.0))
				draw_dur = 0.28
			_: # AK-47
				draw_pos = Vector3(0.04, -0.32, 0.08)
				draw_rot = Vector3(deg_to_rad(-18.0), deg_to_rad(22.0), deg_to_rad(16.0))
				draw_dur = 0.23
				
		var tw_up := create_tween()
		tw_up.set_parallel(true)
		tw_up.tween_property(self, "draw_pos", Vector3.ZERO, draw_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_up.tween_property(self, "draw_rot", Vector3.ZERO, draw_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw_up.finished
		
		is_switching = false
		can_shoot = true
	else:
		draw_pos = Vector3.ZERO
		draw_rot = Vector3.ZERO
		set_active_model_visible(idx)

func set_active_model_visible(idx: int) -> void:
	current_weapon_idx = clampi(idx, 0, weapon_slots.size() - 1)
	current_weapon = weapon_slots[current_weapon_idx]
	
	var wid: String = current_weapon.weapon_id if current_weapon else ""
	if ak47_model:
		ak47_model.visible = (wid == "ak47")
	if shotgun_model:
		shotgun_model.visible = (wid == "shotgun")
	if pistol_model:
		pistol_model.visible = (wid == "pistol")
		pistol_slide_locked_back = (wid == "pistol" and current_weapon and current_weapon.current_ammo <= 0)
	if rpg_model:
		rpg_model.visible = (wid == "rpg")
		if wid == "rpg" and rpg_warhead and current_weapon:
			rpg_warhead.visible = (current_weapon.current_ammo > 0)
			rpg_warhead.position = rpg_warhead_initial_pos
	if kar98k_model:
		kar98k_model.visible = (wid == "kar98k")
		_reset_kar98k_pose_state()
	if pkm_model:
		pkm_model.visible = (wid == "pkm")
	if l96a1_model:
		l96a1_model.visible = (wid == "l96a1")
	if deagle_model:
		deagle_model.visible = (wid == "deagle")
		deagle_slide_locked_back = (wid == "deagle" and current_weapon and current_weapon.current_ammo <= 0)
	if aa12_model:
		aa12_model.visible = (wid == "aa12")
	if mg42_model:
		mg42_model.visible = (wid == "mg42")
	if knife_model:
		knife_model.visible = false
		
	burst_shots_remaining = 0
	is_ugl_mode = false
	is_switching_fire_mode = false
	refresh_active_weapon_mods()
	_sync_fire_selector_mesh(current_weapon)
	
	shoot_timer = 0.08
	can_shoot = true
	weapon_changed.emit(current_weapon)
	emit_ammo_state()
	emit_tactical_state()

func switch_next() -> void:
	if is_quick_knifing:
		return
	for step in range(1, weapon_slots.size() + 1):
		var next_idx: int = (current_weapon_idx + step) % weapon_slots.size()
		if is_weapon_slot_unlocked(next_idx) and weapon_slots[next_idx] != null:
			switch_weapon(next_idx)
			return

func switch_prev() -> void:
	if is_quick_knifing:
		return
	for step in range(1, weapon_slots.size() + 1):
		var prev_idx: int = (current_weapon_idx - step + weapon_slots.size()) % weapon_slots.size()
		if is_weapon_slot_unlocked(prev_idx) and weapon_slots[prev_idx] != null:
			switch_weapon(prev_idx)
			return

func switch_slot(slot_num: int) -> void:
	if is_quick_knifing:
		return
	var idx: int = slot_num - 1
	if is_weapon_slot_unlocked(idx):
		switch_weapon(idx)

# ==========================================
# SHOOTING & SPRING-DAMPER FIRING IMPULSES
# ==========================================
func try_shoot(just_pressed: bool) -> void:
	if not current_weapon or is_switching or is_quick_knifing:
		return
	var p_node: Node = owner
	if p_node:
		if ("is_in_shop" in p_node) and p_node.is_in_shop:
			return
		if ("is_dead" in p_node) and p_node.is_dead:
			return
		var hud = p_node.get_node_or_null("HUD")
		if hud:
			if hud.has_method("is_any_menu_open") and hud.is_any_menu_open():
				return
			if hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
				return
		
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if is_reloading or is_reloading_ugl:
		if not is_ugl_mode and current_weapon.is_shotgun and just_pressed:
			shotgun_cancel_reload = true
			return
		if not is_ugl_mode and current_weapon.weapon_id == "kar98k" and just_pressed and current_weapon.current_ammo > 0:
			kar98k_cancel_reload = true
			return
		return

	# Dedicated Underbarrel Grenade Launcher Mode: LMB fires 40mm grenade only!
	if is_ugl_mode:
		if just_pressed and can_shoot:
			try_fire_ugl()
		return
			
	var fmode: String = current_weapon.current_fire_mode
	if fmode == "auto":
		if not Input.is_action_pressed("shoot"):
			return
	else:
		if not just_pressed:
			return
			
	if not can_shoot:
		return
	if not current_weapon.can_fire():
		if just_pressed:
			play_dry_fire_sound()
		return
	if current_weapon.current_ammo <= 0:
		# Manual reload ONLY on [R] — no automatic reload on empty!
		if just_pressed:
			play_dry_fire_sound()
		return
		
	if fmode == "burst":
		burst_shots_remaining = 2
		burst_timer = maxf(0.052, current_weapon.fire_rate * 0.88)
	execute_shoot()

func play_dry_fire_sound() -> void:
	if dry_fire_cooldown > 0.0:
		return
	dry_fire_cooldown = 0.22
	play_sfx(SoundEffects.create_dry_fire_sound(), randf_range(0.98, 1.02))

func execute_shoot() -> void:
	can_shoot = false
	shoot_timer = current_weapon.fire_rate
	current_weapon.current_ammo -= 1
	if current_weapon.is_shotgun:
		shotgun_is_4_plus_1 = false
	if current_weapon.current_ammo <= 0:
		current_weapon.has_round_in_chamber = false
	emit_ammo_state()
	
	var wid: String = current_weapon.weapon_id
	var ads_m: float = 0.58 if is_aiming else 1.0
	consecutive_shots = mini(consecutive_shots + 1, 20)
	shot_recovery_timer = maxf(current_weapon.fire_rate * 2.2, 0.28)
	# Dynamic spread bloom grows on consecutive shots (reduced by recoil/spread mods & subsonic ammo)
	var bloom_step: float = current_weapon.spread * 0.40 + current_weapon.recoil_pitch * 0.24
	var bloom_cap: float = current_weapon.spread * 2.8 + 0.048
	dynamic_spread_bloom = minf(dynamic_spread_bloom + bloom_step * (0.72 if is_aiming else 1.0), bloom_cap)
	
	var burst_v_mult: float = 1.0 + minf(float(consecutive_shots - 1), 8.0) * 0.055
	var burst_h_mult: float = 1.0 + minf(float(consecutive_shots - 1), 8.0) * 0.095
	var pitch_up: float = current_weapon.recoil_pitch * ads_m * burst_v_mult
	var yaw_rnd: float = randf_range(-current_weapon.recoil_yaw, current_weapon.recoil_yaw) * ads_m * burst_h_mult
	
	# Punchy second-order spring velocity impulses tailored per firearm!
	match wid:
		"ak47":
			recoil_vel += Vector3(yaw_rnd * 4.5, randf_range(0.14, 0.26) * ads_m, 0.85 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 17.0, yaw_rnd * 11.0, randf_range(-0.42, 0.42) * ads_m)
			animate_ak_bolt_cycle()
		"shotgun":
			recoil_vel += Vector3(yaw_rnd * 3.0, 0.48 * ads_m, 1.45 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 22.0, yaw_rnd * 8.0, randf_range(-0.55, 0.55) * ads_m)
		"pistol":
			recoil_vel += Vector3(yaw_rnd * 3.5, 0.16 * ads_m, 0.52 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 26.0, yaw_rnd * 9.0, randf_range(-0.35, 0.35) * ads_m)
			animate_pistol_slide_cycle(current_weapon.current_ammo <= 0)
		"rpg":
			recoil_vel += Vector3(0.0, 0.55, 2.35)
			recoil_rot_vel += Vector3(2.8, randf_range(-0.3, 0.3), randf_range(-0.4, 0.4))
			if rpg_warhead:
				rpg_warhead.visible = false
		"kar98k":
			recoil_vel += Vector3(yaw_rnd * 3.0, 0.44 * ads_m, 1.52 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 22.0, yaw_rnd * 8.5, randf_range(-0.42, -0.18) * ads_m)
			kar98k_has_spent_case = true
			_animate_kar98k_striker_drop()
		"l96a1":
			recoil_vel += Vector3(yaw_rnd * 2.8, 0.46 * ads_m, 1.65 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 22.0, yaw_rnd * 7.0, randf_range(-0.4, 0.4) * ads_m)
		"pkm":
			recoil_vel += Vector3(yaw_rnd * 4.2, randf_range(0.16, 0.28) * ads_m, 0.92 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 16.0, yaw_rnd * 10.0, randf_range(-0.45, 0.45) * ads_m)
			animate_lmg_handle_cycle("pkm")
		"mg42":
			recoil_vel += Vector3(yaw_rnd * 4.8, randf_range(0.12, 0.22) * ads_m, 0.72 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 15.0, yaw_rnd * 12.0, randf_range(-0.55, 0.55) * ads_m)
			animate_lmg_handle_cycle("mg42")
		"deagle":
			recoil_vel += Vector3(yaw_rnd * 4.0, 0.42 * ads_m, 1.20 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 30.0, yaw_rnd * 10.0, randf_range(-0.45, 0.45) * ads_m)
			animate_deagle_slide_cycle(current_weapon.current_ammo <= 0)
		"aa12":
			recoil_vel += Vector3(yaw_rnd * 3.5, 0.34 * ads_m, 1.15 * ads_m)
			recoil_rot_vel += Vector3(pitch_up * 19.0, yaw_rnd * 9.0, randf_range(-0.45, 0.45) * ads_m)
			animate_lmg_handle_cycle("aa12")
	
	# Real physical camera recoil (vertical climb + horizontal kick) + subtle micro-shake on heavy weapons
	var player_node: Node = owner
	if player_node and player_node.has_method("add_camera_recoil"):
		player_node.add_camera_recoil(pitch_up * 0.68, yaw_rnd * 0.80)
	if player_node and player_node.has_method("add_camera_shake") and (wid in ["shotgun", "rpg", "kar98k", "l96a1", "deagle", "aa12"]):
		var shake_amt: float = 0.09 if wid == "rpg" else (0.045 if wid in ["l96a1", "deagle"] else 0.032)
		player_node.add_camera_shake(shake_amt)
	
	# Rebuilt volumetric muzzle flash, gunsmoke, sparks & RPG backblast!
	show_muzzle_flash()
	trigger_muzzle_smoke()
	if wid in ["ak47", "shotgun", "pkm", "mg42", "aa12", "deagle", "kar98k", "l96a1"]:
		trigger_ak_sparks()
	play_shoot_sound()
	
	if current_weapon.is_rpg:
		if rpg_model:
			var bb: Marker3D = rpg_model.get_node_or_null("BackblastMarker")
			if bb:
				VFXFactoryScript.spawn_rpg_backblast(get_tree().root, bb.global_position, rpg_model.global_transform.basis.z)
		fire_rpg_rocket()
		return
	
	if wid == "ak47":
		eject_casing(1, ak47_model.get_node_or_null("EjectMarker"))
	elif wid == "pistol":
		eject_casing(3, pistol_model.get_node_or_null("EjectMarker"))
	elif wid == "shotgun":
		animate_shotgun_pump_with_ejection()
	elif wid == "kar98k":
		animate_kar98k_bolt_cycle()
	elif wid == "l96a1":
		animate_bolt_action_cycle("l96a1")
	elif wid == "pkm" and pkm_model:
		eject_casing(1, pkm_model.get_node_or_null("EjectMarker"))
	elif wid == "mg42" and mg42_model:
		eject_casing(1, mg42_model.get_node_or_null("EjectMarker"))
	elif wid == "deagle" and deagle_model:
		eject_casing(3, deagle_model.get_node_or_null("EjectMarker"))
	elif wid == "aa12" and aa12_model:
		eject_casing(2, aa12_model.get_node_or_null("EjectMarker"))
		
	var muzzle_pos: Vector3 = get_active_muzzle_pos()
	for i in range(current_weapon.pellets):
		fire_pellet(muzzle_pos)

func _schedule_kar98k_auto_reload() -> void:
	await get_tree().create_timer(0.24).timeout
	if not is_instance_valid(self) or not current_weapon or current_weapon.weapon_id != "kar98k":
		return
	if is_reloading or is_switching or is_quick_knifing:
		return
	if current_weapon.current_ammo <= 0 and (get_reserve_ammo(current_weapon) > 0 or infinite_reserve_ammo):
		start_reload()

func _reset_kar98k_pose_state() -> void:
	if kar98k_bolt:
		kar98k_bolt.position = kar98k_bolt_initial_pos
		kar98k_bolt.rotation = Vector3.ZERO
	if kar98k_bolt_rotator:
		kar98k_bolt_rotator.rotation = Vector3.ZERO
	if kar98k_cocking_piece:
		var is_cocked: bool = not kar98k_has_spent_case
		kar98k_cocking_piece.position.z = kar98k_cocking_initial_z if is_cocked else (kar98k_cocking_initial_z - 0.0095)
	if kar98k_extracted_case:
		kar98k_extracted_case.visible = false
	if kar98k_trigger:
		kar98k_trigger.rotation = Vector3.ZERO
	if kar98k_clip:
		kar98k_clip.visible = false
		kar98k_clip.position = kar98k_clip_initial_pos
		kar98k_clip.rotation = Vector3.ZERO
	if kar98k_clip_rail:
		kar98k_clip_rail.position = kar98k_clip_rail_initial_pos
		kar98k_clip_rail.rotation = Vector3.ZERO
		kar98k_clip_rail.visible = true
	if kar98k_clip_rounds:
		kar98k_clip_rounds.position = Vector3.ZERO
		kar98k_clip_rounds.visible = true
	if kar98k_single_round:
		kar98k_single_round.visible = false
		kar98k_single_round.rotation = Vector3.ZERO
	if kar98k_follower_round:
		var k98_ref: Weapon = get_weapon_by_id("kar98k")
		kar98k_follower_round.visible = (k98_ref != null and k98_ref.current_ammo > 0)

func _animate_kar98k_striker_drop() -> void:
	if kar98k_trigger:
		var tw_tr := create_tween()
		tw_tr.tween_property(kar98k_trigger, "rotation:x", deg_to_rad(-18.0), 0.025)
		tw_tr.tween_property(kar98k_trigger, "rotation:x", 0.0, 0.08)
	if kar98k_cocking_piece:
		# Mauser 98 striker spring drops firing pin in ~2ms (instantaneous forward snap!)
		kar98k_cocking_piece.position.z = kar98k_cocking_initial_z - 0.0095

# Museum-Grade 4-Stage Mauser 98 Bolt Cycle (Cocking Cam Lift -> Claw Extraction & Eject -> Controlled-Round Feed -> Lug Lock)
func animate_kar98k_bolt_cycle() -> void:
	var k98_w: Weapon = current_weapon
	if not k98_w or k98_w.weapon_id != "kar98k":
		return

	await get_tree().create_timer(0.18).timeout
	if not is_instance_valid(kar98k_bolt) or not is_instance_valid(kar98k_model) or not kar98k_model.visible or is_reloading or is_switching:
		return

	var ads_scale: float = lerpf(1.0, 0.38, ads_blend)
	play_sfx(SoundEffects.create_kar98k_bolt_open_sound(), randf_range(0.97, 1.03))

	# Show spent brass gripped under Mauser claw extractor & update internal magazine follower round
	if kar98k_extracted_case:
		kar98k_extracted_case.visible = kar98k_has_spent_case
	if kar98k_follower_round:
		kar98k_follower_round.visible = (k98_w.current_ammo > 0)

	# Stage 1: Lift swept Mauser bolt handle +76 deg (BoltShroud & FlagSafety stay non-rotating!) + cam CockingPiece back
	var tw1 := create_tween()
	tw1.set_parallel(true)
	if kar98k_bolt_rotator:
		tw1.tween_property(kar98k_bolt_rotator, "rotation:z", deg_to_rad(76.0), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw1.tween_property(kar98k_bolt, "rotation:z", deg_to_rad(76.0), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if kar98k_cocking_piece:
		tw1.tween_property(kar98k_cocking_piece, "position:z", kar98k_cocking_initial_z, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw1.tween_property(self, "anim_rot:z", deg_to_rad(13.0 * ads_scale), 0.13)
	tw1.tween_property(self, "anim_rot:x", deg_to_rad(4.5 * ads_scale), 0.13)
	await tw1.finished
	if not is_instance_valid(kar98k_model) or not kar98k_model.visible or is_reloading or is_switching:
		_reset_kar98k_pose_state()
		return

	# Stage 2: Brisk rearward bolt throw (+0.102m) to Mauser bolt stop & crisp brass ejection!
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(kar98k_bolt, "position:z", kar98k_bolt_initial_pos.z + 0.102, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "anim_pos:z", 0.028 * ads_scale, 0.15)
	tw2.tween_property(self, "anim_rot:y", deg_to_rad(-3.2 * ads_scale), 0.15)
	await tw2.finished
	if not is_instance_valid(kar98k_model) or not kar98k_model.visible or is_reloading or is_switching:
		_reset_kar98k_pose_state()
		return

	if kar98k_has_spent_case:
		if kar98k_extracted_case:
			kar98k_extracted_case.visible = false
		kar98k_has_spent_case = false
		eject_casing(1, kar98k_model.get_node_or_null("EjectMarker"))

	# Stage 3: Ram bolt forward & strip fresh 7.92x57mm spitzer cartridge from magazine into chamber!
	play_sfx(SoundEffects.create_kar98k_bolt_close_sound(), randf_range(0.97, 1.03))
	if kar98k_single_round and k98_w.current_ammo > 0:
		kar98k_single_round.position = Vector3(0.0, 0.012, -0.028)
		kar98k_single_round.rotation_degrees = Vector3(6.0, 0.0, 0.0)
		kar98k_single_round.visible = true
		if k98_w.current_ammo <= 1 and kar98k_follower_round:
			kar98k_follower_round.visible = false

	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(kar98k_bolt, "position:z", kar98k_bolt_initial_pos.z, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw3.tween_property(self, "anim_pos:z", -0.012 * ads_scale, 0.15)
	tw3.tween_property(self, "anim_rot:y", 0.0, 0.15)
	if kar98k_single_round and kar98k_single_round.visible:
		tw3.tween_property(kar98k_single_round, "position", Vector3(0.0, 0.016, -0.105), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw3.tween_property(kar98k_single_round, "rotation_degrees", Vector3.ZERO, 0.12)
	await tw3.finished
	if kar98k_single_round:
		kar98k_single_round.visible = false
	if not is_instance_valid(kar98k_model) or not kar98k_model.visible or is_reloading or is_switching:
		_reset_kar98k_pose_state()
		return

	# Stage 4: Cam locking lugs down & settle rifle into shoulder pocket
	var tw4 := create_tween()
	tw4.set_parallel(true)
	if kar98k_bolt_rotator:
		tw4.tween_property(kar98k_bolt_rotator, "rotation:z", 0.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw4.tween_property(kar98k_bolt, "rotation:z", 0.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw4.tween_property(self, "anim_rot:z", 0.0, 0.15)
	tw4.tween_property(self, "anim_rot:x", 0.0, 0.15)
	tw4.tween_property(self, "anim_pos:z", 0.0, 0.15)
	await tw4.finished

func _schedule_rpg_auto_reload() -> void:
	await get_tree().create_timer(0.55).timeout
	if not is_instance_valid(self) or not current_weapon or not current_weapon.is_rpg:
		return
	if is_reloading or is_switching or is_quick_knifing:
		return
	if current_weapon.current_ammo <= 0 and (current_weapon.reserve_ammo > 0 or infinite_reserve_ammo):
		start_reload()

func fire_rpg_rocket() -> void:
	if not camera:
		return
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var center: Vector2 = get_viewport().get_visible_rect().size / 2.0
	var ray_origin: Vector3 = camera.project_ray_origin(center)
	var ray_dir: Vector3 = camera.project_ray_normal(center)
	var ray_end: Vector3 = ray_origin + ray_dir * 200.0
	
	var exclude_rids: Array[RID] = []
	var player_body: CollisionObject3D = owner as CollisionObject3D
	if player_body:
		exclude_rids.append(player_body.get_rid())
		
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = exclude_rids
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	var target_point: Vector3 = result.position if not result.is_empty() else ray_end
		
	var muzzle_pos: Vector3 = get_active_muzzle_pos()
	var cam_to_muzzle := PhysicsRayQueryParameters3D.create(ray_origin, muzzle_pos)
	cam_to_muzzle.exclude = exclude_rids
	cam_to_muzzle.collide_with_bodies = true
	cam_to_muzzle.collide_with_areas = true
	var muzzle_check := space_state.intersect_ray(cam_to_muzzle)
	var spawn_pos: Vector3 = muzzle_pos
	if not muzzle_check.is_empty():
		spawn_pos = ray_origin + ray_dir * maxf(0.45, ray_origin.distance_to(muzzle_check.position) - 0.15)
		
	var launch_dir: Vector3 = (target_point - spawn_pos).normalized()
	if launch_dir.dot(ray_dir) < 0.2:
		launch_dir = ray_dir
		
	var rocket: Node3D = RPGRocketScript.new()
	rocket.position = spawn_pos
	get_tree().root.add_child(rocket)
	var rpg_rad: float = float(current_weapon.active_mechanics.get("blast_radius", 16.5))
	var rpg_mode: String = str(current_weapon.active_mechanics.get("ammo_mode", "standard"))
	rocket.init(spawn_pos, launch_dir, owner, self, current_weapon.damage, rpg_rad, rpg_mode)

func animate_ak_bolt_cycle() -> void:
	var tw := create_tween()
	tw.tween_property(self, "ak_handle_offset_z", 0.068, 0.028).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "ak_handle_offset_z", 0.0, 0.048).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_pistol_slide_cycle(lock_back: bool = false) -> void:
	pistol_slide_locked_back = lock_back
	var tw := create_tween()
	tw.tween_property(self, "pistol_slide_offset_z", 0.044, 0.022).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not lock_back:
		tw.tween_property(self, "pistol_slide_offset_z", 0.0, 0.040).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_deagle_slide_cycle(lock_back: bool = false) -> void:
	deagle_slide_locked_back = lock_back
	var tw := create_tween()
	tw.tween_property(self, "deagle_slide_offset_z", 0.056, 0.028).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not lock_back:
		tw.tween_property(self, "deagle_slide_offset_z", 0.0, 0.052).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_lmg_handle_cycle(wid: String) -> void:
	var prop: String = "pkm_handle_offset_z" if wid == "pkm" else ("mg42_handle_offset_z" if wid == "mg42" else "aa12_handle_offset_z")
	var dist: float = 0.055 if wid == "pkm" else (0.042 if wid == "mg42" else 0.062)
	var dur_out: float = 0.022 if wid == "mg42" else 0.032
	var dur_in: float = 0.026 if wid == "mg42" else 0.048
	var tw := create_tween()
	tw.tween_property(self, prop, dist, dur_out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, prop, 0.0, dur_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# Realistic 4-Stage Bolt-Action Cycle (Lift -> Pull & Eject -> Push -> Lock Down) for Kar98k & L96A1!
func animate_bolt_action_cycle(wid: String) -> void:
	var bolt_node: Node3D = kar98k_bolt if wid == "kar98k" else l96a1_bolt
	var init_pos: Vector3 = kar98k_bolt_initial_pos if wid == "kar98k" else l96a1_bolt_initial_pos
	var model_node: Node3D = kar98k_model if wid == "kar98k" else l96a1_model
	await get_tree().create_timer(0.22).timeout
	if not is_instance_valid(bolt_node) or not is_instance_valid(model_node) or not model_node.visible or is_reloading:
		return
	if current_weapon and current_weapon.current_ammo <= 0:
		return
	play_sfx(SoundEffects.create_bolt_cycle_sound(), randf_range(0.96, 1.04))
	# Stage 1: Cant rifle slightly left + Lift bolt handle 62 deg
	var tw1 := create_tween()
	tw1.set_parallel(true)
	tw1.tween_property(bolt_node, "rotation:z", deg_to_rad(62.0), 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw1.tween_property(self, "anim_rot:z", deg_to_rad(10.0), 0.11)
	tw1.tween_property(self, "anim_rot:x", deg_to_rad(4.0), 0.11)
	await tw1.finished
	if not is_instance_valid(model_node) or not model_node.visible or is_reloading:
		bolt_node.position = init_pos; bolt_node.rotation = Vector3.ZERO
		return
	# Stage 2: Pull bolt straight back & eject spent brass casing
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(bolt_node, "position:z", init_pos.z + 0.095, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "anim_pos:z", 0.025, 0.13)
	await tw2.finished
	if not is_instance_valid(model_node) or not model_node.visible or is_reloading:
		bolt_node.position = init_pos; bolt_node.rotation = Vector3.ZERO
		return
	eject_casing(1, model_node.get_node_or_null("EjectMarker"))
	# Stage 3: Push bolt forward to strip fresh round
	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(bolt_node, "position:z", init_pos.z, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw3.tween_property(self, "anim_pos:z", -0.008, 0.13)
	await tw3.finished
	if not is_instance_valid(model_node) or not model_node.visible or is_reloading:
		bolt_node.position = init_pos; bolt_node.rotation = Vector3.ZERO
		return
	# Stage 4: Lock bolt handle down & level rifle
	var tw4 := create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(bolt_node, "rotation:z", 0.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw4.tween_property(self, "anim_rot:z", 0.0, 0.14)
	tw4.tween_property(self, "anim_rot:x", 0.0, 0.14)
	tw4.tween_property(self, "anim_pos:z", 0.0, 0.14)
	await tw4.finished

func trigger_muzzle_smoke() -> void:
	if not muzzle_smoke or not current_weapon:
		return
	muzzle_smoke.global_position = get_active_muzzle_pos()
	match current_weapon.weapon_id:
		"ak47", "pkm", "mg42":
			muzzle_smoke.amount = 11
			muzzle_smoke.lifetime = 0.65
			muzzle_smoke.initial_velocity_max = 2.6
		"shotgun", "aa12":
			muzzle_smoke.amount = 24
			muzzle_smoke.lifetime = 0.95
			muzzle_smoke.initial_velocity_max = 4.2
		"pistol":
			muzzle_smoke.amount = 6
			muzzle_smoke.lifetime = 0.42
			muzzle_smoke.initial_velocity_max = 1.6
		"deagle", "kar98k", "l96a1":
			muzzle_smoke.amount = 16
			muzzle_smoke.lifetime = 0.80
			muzzle_smoke.initial_velocity_max = 3.4
		"rpg":
			muzzle_smoke.amount = 34
			muzzle_smoke.lifetime = 1.25
			muzzle_smoke.initial_velocity_max = 5.4
	muzzle_smoke.restart()
	muzzle_smoke.emitting = true

func trigger_ak_sparks() -> void:
	if not ak_sparks or not current_weapon:
		return
	ak_sparks.global_position = get_active_muzzle_pos()
	if current_weapon.has_mechanic("incendiary"):
		ak_sparks.amount = 30
	else:
		ak_sparks.amount = 14 if current_weapon.is_shotgun else 7
	ak_sparks.restart()
	ak_sparks.emitting = true

func eject_casing(casing_type: int, marker: Marker3D) -> void:
	if not shell_casing_scene:
		return
	var casing: RigidBody3D = shell_casing_scene.instantiate()
	var xform: Transform3D = marker.global_transform if marker else global_transform
	casing.position = xform.origin
	get_tree().root.add_child(casing)
	casing.init(casing_type, xform)

# Cinematic Shotgun Pump Cycle with subtle weapon roll, ejection & forward slam!
func animate_shotgun_pump_with_ejection() -> void:
	await get_tree().create_timer(0.18).timeout
	if not is_instance_valid(shotgun_pump) or not shotgun_model or not shotgun_model.visible or is_reloading:
		return
		
	# Slight left cant + pull forend back
	var tw_back := create_tween()
	tw_back.set_parallel(true)
	tw_back.tween_property(self, "pump_offset_z", 0.115, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_back.tween_property(self, "anim_rot:z", deg_to_rad(8.0), 0.10)
	tw_back.tween_property(self, "anim_rot:x", deg_to_rad(5.0), 0.10)
	tw_back.tween_property(self, "anim_pos:z", 0.022, 0.10)
	await tw_back.finished
	
	if not is_instance_valid(shotgun_model) or not shotgun_model.visible:
		pump_offset_z = 0.0
		return
		
	eject_casing(2, shotgun_model.get_node_or_null("EjectMarker"))
	play_sfx(SoundEffects.create_pump_sound())
	
	# Authoritative forward pump slam + level-out
	var tw_fwd := create_tween()
	tw_fwd.set_parallel(true)
	tw_fwd.tween_property(self, "pump_offset_z", 0.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_fwd.tween_property(self, "anim_rot:z", 0.0, 0.13)
	tw_fwd.tween_property(self, "anim_rot:x", 0.0, 0.13)
	tw_fwd.tween_property(self, "anim_pos:z", -0.010, 0.09)
	await tw_fwd.finished
	
	var tw_settle := create_tween()
	tw_settle.tween_property(self, "anim_pos:z", 0.0, 0.08)

func play_shoot_sound() -> void:
	if not current_weapon:
		return
	match current_weapon.weapon_id:
		"ak47":
			shoot_sound_player.stream = SoundEffects.create_ak47_sound()
			shoot_sound_player.pitch_scale = randf_range(0.93, 1.07)
			shoot_sound_player.volume_db = 4.0
		"shotgun":
			shoot_sound_player.stream = SoundEffects.create_shotgun_sound()
			shoot_sound_player.pitch_scale = randf_range(0.97, 1.03)
			shoot_sound_player.volume_db = 6.5
		"pistol":
			shoot_sound_player.stream = SoundEffects.create_pistol_sound()
			shoot_sound_player.pitch_scale = randf_range(0.98, 1.03)
			shoot_sound_player.volume_db = -11.0
		"rpg":
			shoot_sound_player.stream = SoundEffects.create_rpg_shot_sound()
			shoot_sound_player.pitch_scale = randf_range(0.95, 1.05)
			shoot_sound_player.volume_db = 1.0
		"kar98k":
			shoot_sound_player.stream = SoundEffects.create_kar98k_sound()
			shoot_sound_player.pitch_scale = randf_range(0.96, 1.04)
			shoot_sound_player.volume_db = 5.5
		"pkm":
			shoot_sound_player.stream = SoundEffects.create_pkm_sound()
			shoot_sound_player.pitch_scale = randf_range(0.94, 1.06)
			shoot_sound_player.volume_db = 3.5
		"l96a1":
			shoot_sound_player.stream = SoundEffects.create_l96a1_sound()
			shoot_sound_player.pitch_scale = randf_range(0.96, 1.04)
			shoot_sound_player.volume_db = 6.0
		"deagle":
			shoot_sound_player.stream = SoundEffects.create_deagle_sound()
			shoot_sound_player.pitch_scale = randf_range(0.96, 1.04)
			shoot_sound_player.volume_db = 5.0
		"aa12":
			shoot_sound_player.stream = SoundEffects.create_aa12_sound()
			shoot_sound_player.pitch_scale = randf_range(0.94, 1.06)
			shoot_sound_player.volume_db = 4.5
		"mg42":
			shoot_sound_player.stream = SoundEffects.create_mg42_sound()
			shoot_sound_player.pitch_scale = randf_range(0.95, 1.08)
			shoot_sound_player.volume_db = 2.5
	var is_sup_snd: bool = current_weapon.has_mechanic("suppressed")
	var is_sub_snd: bool = str(current_weapon.active_mechanics.get("ammo_mode", "")) == "subsonic"
	if is_sup_snd and is_sub_snd:
		# Ultra-quiet subsonic + suppressor combo (no supersonic crack, hushed bolt thump!)
		shoot_sound_player.volume_db -= 15.5
		shoot_sound_player.pitch_scale *= 1.10
	elif is_sub_snd:
		# Subsonic without suppressor: noticeably softer and deeper thump without sharp crack!
		shoot_sound_player.volume_db -= 6.5
		shoot_sound_player.pitch_scale *= 0.80
	elif is_sup_snd:
		shoot_sound_player.volume_db -= 9.5
		shoot_sound_player.pitch_scale *= 1.24
	shoot_sound_player.play()

func show_muzzle_flash() -> void:
	if not muzzle_flash:
		return
	muzzle_flash.global_position = get_active_muzzle_pos()
	muzzle_flash.visible = true
	var wid: String = current_weapon.weapon_id if current_weapon else "ak47"
	var is_sup: bool = current_weapon != null and current_weapon.has_mechanic("suppressed")
	var is_sub: bool = current_weapon != null and str(current_weapon.active_mechanics.get("ammo_mode", "")) == "subsonic"
	var is_inc: bool = current_weapon != null and current_weapon.has_mechanic("incendiary")
	var side_jets: Node3D = muzzle_flash.get_node_or_null("SideJets")
	if side_jets:
		side_jets.visible = (not is_sup) and (not is_sub) and (wid in ["ak47", "shotgun", "pkm", "mg42", "l96a1", "aa12"])
	var sc: float = 1.0
	var energy: float = 3.2
	match wid:
		"rpg":
			sc = 2.4
			energy = 6.8
		"shotgun", "aa12", "l96a1":
			sc = 1.55
			energy = 4.8
		"kar98k", "deagle", "pkm", "mg42":
			sc = randf_range(1.15, 1.42)
			energy = 4.2
		"pistol":
			sc = 0.72
			energy = 2.2
		_:
			sc = randf_range(0.95, 1.22)
			energy = 3.4
	if is_sup and is_sub:
		sc *= 0.14
		energy *= 0.12
	elif is_sup:
		sc *= 0.28
		energy *= 0.25
	elif is_sub:
		sc *= 0.55
		energy *= 0.50
	elif is_inc:
		sc *= 1.65
		energy *= 1.50
	muzzle_flash.scale = Vector3(sc, sc, sc)
	if flash_light:
		flash_light.light_energy = energy
	muzzle_flash.rotation.z = randf_range(0.0, TAU)
	await get_tree().create_timer(0.055 if wid == "rpg" else 0.04).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
		muzzle_flash.scale = Vector3.ONE

func get_active_muzzle_pos() -> Vector3:
	if not current_weapon:
		return global_position
	var muzzle_node: Marker3D = null
	match current_weapon.weapon_id:
		"ak47":
			if ak47_model: muzzle_node = ak47_model.get_node_or_null("Muzzle")
		"shotgun":
			if shotgun_model: muzzle_node = shotgun_model.get_node_or_null("Muzzle")
		"pistol":
			if pistol_model: muzzle_node = pistol_model.get_node_or_null("Muzzle")
		"rpg":
			if rpg_model: muzzle_node = rpg_model.get_node_or_null("Muzzle")
		"kar98k":
			if kar98k_model: muzzle_node = kar98k_model.get_node_or_null("Muzzle")
		"pkm":
			if pkm_model: muzzle_node = pkm_model.get_node_or_null("Muzzle")
		"l96a1":
			if l96a1_model: muzzle_node = l96a1_model.get_node_or_null("Muzzle")
		"deagle":
			if deagle_model: muzzle_node = deagle_model.get_node_or_null("Muzzle")
		"aa12":
			if aa12_model: muzzle_node = aa12_model.get_node_or_null("Muzzle")
		"mg42":
			if mg42_model: muzzle_node = mg42_model.get_node_or_null("Muzzle")
	if muzzle_node:
		return muzzle_node.global_position
	return global_position

func fire_pellet(from_pos: Vector3) -> void:
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	
	# Real 3D angular cone spread = (weapon base spread + dynamic firing bloom) * ADS * movement * laser
	var is_shotty: bool = current_weapon.is_shotgun or current_weapon.weapon_id == "aa12"
	var ads_sp_mult: float = (0.78 if is_shotty else 0.32) if is_aiming else 1.0
	var move_sp_mult: float = 1.0
	var p_owner: CharacterBody3D = owner as CharacterBody3D
	if p_owner:
		var h_spd: float = Vector2(p_owner.velocity.x, p_owner.velocity.z).length()
		var move_norm: float = clampf(h_spd / 9.5, 0.0, 1.0)
		move_sp_mult = 1.0 + move_norm * (0.28 if is_aiming else 0.65)
	var eff_spread: float = (current_weapon.spread + dynamic_spread_bloom) * ads_sp_mult * move_sp_mult
	if not is_aiming and current_weapon.laser_enabled and current_weapon.has_mechanic("laser_sight"):
		eff_spread *= float(current_weapon.active_mechanics.get("hipfire_spread_mult", 0.68))
	var ap_mult: float = float(current_weapon.active_mechanics.get("armor_pen_mult", 1.0))
	
	var cam_basis: Basis = camera.global_transform.basis
	var cam_fwd: Vector3 = -cam_basis.z
	var sp_ang: float = randf_range(0.0, TAU)
	var sp_rad: float = sqrt(randf()) * eff_spread
	var ray_dir: Vector3 = (cam_fwd + cam_basis.x * (cos(sp_ang) * sp_rad) + cam_basis.y * (sin(sp_ang) * sp_rad)).normalized()
	var ray_origin: Vector3 = camera.global_position + ray_dir * 0.45
	var ray_end: Vector3 = ray_origin + ray_dir * 120.0
	
	var player_body: CollisionObject3D = owner as CollisionObject3D
	if not player_body:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_body = players[0] as CollisionObject3D
	var exclude_rids: Array[RID] = []
	if player_body:
		exclude_rids.append(player_body.get_rid())
	for shop in get_tree().get_nodes_in_group("shop_building"):
		if shop is CollisionObject3D:
			exclude_rids.append(shop.get_rid())
			
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = exclude_rids
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result: Dictionary = space_state.intersect_ray(query)
	var hit_pos: Vector3 = ray_end
	var hit_something: bool = false
	var hit_an_enemy: bool = false
	
	if result:
		var collider: Object = result.collider
		if collider == player_body or (collider and collider.is_in_group("player")):
			spawn_tracer(from_pos, ray_end)
			return
		if collider and (collider.is_in_group("shop_building") or collider.name == "ShopBuilding"):
			spawn_tracer(from_pos, result.position)
			return
			
		hit_pos = result.position
		hit_something = true
		if collider and collider.is_in_group("arena_shootable"):
			var mgrs := get_tree().get_nodes_in_group("arena_interactables")
			if mgrs.size() > 0 and mgrs[0].has_method("on_bullet_hit_interactable"):
				mgrs[0].on_bullet_hit_interactable(collider as Node3D, current_weapon.damage, hit_pos, ray_dir)
				hit_enemy.emit()
		elif collider and collider.is_in_group("enemy_shield"):
			var sh_owner = collider.get_meta("shield_owner") if collider.has_meta("shield_owner") else null
			if ap_mult >= 1.50 and is_instance_valid(sh_owner) and sh_owner.has_method("take_damage"):
				# Armor-piercing ammo punches through heavy ballistic steel for 55% damage!
				var dist_s: float = from_pos.distance_to(hit_pos)
				var dmg_s: float = current_weapon.damage
				if current_weapon.has_falloff and dist_s > current_weapon.falloff_min_dist:
					var fs: float = clampf((dist_s - current_weapon.falloff_min_dist) / maxf(0.01, current_weapon.falloff_max_dist - current_weapon.falloff_min_dist), 0.0, 1.0)
					dmg_s = lerpf(current_weapon.damage, current_weapon.damage * current_weapon.min_damage_mult, fs)
				sh_owner.take_damage(dmg_s * 0.55, false)
				hit_an_enemy = true
				hit_enemy.emit()
				if hit_sound_player:
					hit_sound_player.stream = SoundEffects.create_hit_sound()
					hit_sound_player.pitch_scale = randf_range(1.12, 1.26)
					hit_sound_player.play()
			else:
				# Standard ammo ricochets harmlessly off steel shield plate with metallic clang!
				var ric := AudioStreamPlayer3D.new()
				ric.bus = "SFX"
				ric.stream = SoundEffects.create_tiger_ricochet_sound()
				ric.pitch_scale = randf_range(1.15, 1.38)
				ric.volume_db = -2.0
				ric.max_distance = 32.0
				get_tree().root.add_child(ric)
				ric.global_position = hit_pos
				ric.play()
				ric.finished.connect(ric.queue_free)
		elif collider and collider.is_in_group("mi24_hitbox"):
			var mi24_owner = collider.get_meta("mi24_owner") if collider.has_meta("mi24_owner") else null
			var zone_m: String = str(collider.get_meta("hit_zone")) if collider.has_meta("hit_zone") else "hull"
			if is_instance_valid(mi24_owner) and mi24_owner.has_method("on_bullet_hit"):
				var dist_m: float = from_pos.distance_to(hit_pos)
				var dmg_m: float = current_weapon.damage
				if current_weapon.has_falloff:
					if dist_m >= current_weapon.falloff_max_dist:
						dmg_m = current_weapon.damage * current_weapon.min_damage_mult
					elif dist_m > current_weapon.falloff_min_dist:
						var f_m: float = (dist_m - current_weapon.falloff_min_dist) / (current_weapon.falloff_max_dist - current_weapon.falloff_min_dist)
						dmg_m = lerpf(current_weapon.damage, current_weapon.damage * current_weapon.min_damage_mult, f_m)
				if mi24_owner.on_bullet_hit(zone_m, dmg_m * ap_mult, ap_mult, hit_pos, result.normal):
					hit_an_enemy = true
					hit_enemy.emit()
					if hit_sound_player:
						hit_sound_player.stream = SoundEffects.create_hit_sound()
						hit_sound_player.pitch_scale = randf_range(1.10, 1.28)
						hit_sound_player.play()
		elif collider and collider.is_in_group("tiger_hitbox"):
			var tiger_owner = collider.get_meta("tiger_owner") if collider.has_meta("tiger_owner") else null
			var zone_id: String = str(collider.get_meta("hit_zone")) if collider.has_meta("hit_zone") else ""
			if is_instance_valid(tiger_owner) and tiger_owner.has_method("on_bullet_hit"):
				var dist_t: float = from_pos.distance_to(hit_pos)
				var dmg_t: float = current_weapon.damage
				if current_weapon.has_falloff:
					if dist_t >= current_weapon.falloff_max_dist:
						dmg_t = current_weapon.damage * current_weapon.min_damage_mult
					elif dist_t > current_weapon.falloff_min_dist:
						var f_t: float = (dist_t - current_weapon.falloff_min_dist) / (current_weapon.falloff_max_dist - current_weapon.falloff_min_dist)
						dmg_t = lerpf(current_weapon.damage, current_weapon.damage * current_weapon.min_damage_mult, f_t)
				var penetrated: bool = tiger_owner.on_bullet_hit(zone_id, dmg_t * ap_mult, hit_pos, result.normal)
				if penetrated:
					hit_an_enemy = true
					hit_enemy.emit()
					if hit_sound_player:
						hit_sound_player.stream = SoundEffects.create_hit_sound()
						hit_sound_player.pitch_scale = randf_range(1.15, 1.3)
						hit_sound_player.play()
		elif collider and collider.is_in_group("black_van_hitbox"):
			var van_owner = collider.get_meta("van_owner") if collider.has_meta("van_owner") else null
			var zone_v: String = str(collider.get_meta("hit_zone")) if collider.has_meta("hit_zone") else ""
			if is_instance_valid(van_owner) and van_owner.has_method("on_bullet_hit"):
				var dist_v: float = from_pos.distance_to(hit_pos)
				var dmg_v: float = current_weapon.damage
				if current_weapon.has_falloff:
					if dist_v >= current_weapon.falloff_max_dist:
						dmg_v = current_weapon.damage * current_weapon.min_damage_mult
					elif dist_v > current_weapon.falloff_min_dist:
						var f_v: float = (dist_v - current_weapon.falloff_min_dist) / (current_weapon.falloff_max_dist - current_weapon.falloff_min_dist)
						dmg_v = lerpf(current_weapon.damage, current_weapon.damage * current_weapon.min_damage_mult, f_v)
				var hit_front: bool = van_owner.on_bullet_hit(zone_v, dmg_v * ap_mult, hit_pos, result.normal)
				if hit_front:
					hit_an_enemy = true
					hit_enemy.emit()
					if hit_sound_player:
						hit_sound_player.stream = SoundEffects.create_hit_sound()
						hit_sound_player.pitch_scale = randf_range(1.15, 1.3)
						hit_sound_player.play()
		elif collider and collider.is_in_group("enemy"):
			hit_an_enemy = true
			var dist: float = from_pos.distance_to(hit_pos)
			var final_damage: float = current_weapon.damage
			if current_weapon.has_falloff:
				if dist <= current_weapon.falloff_min_dist:
					final_damage = current_weapon.damage
				elif dist >= current_weapon.falloff_max_dist:
					final_damage = current_weapon.damage * current_weapon.min_damage_mult
				else:
					var factor: float = (dist - current_weapon.falloff_min_dist) / (current_weapon.falloff_max_dist - current_weapon.falloff_min_dist)
					final_damage = lerpf(current_weapon.damage, current_weapon.damage * current_weapon.min_damage_mult, factor)
			collider.take_damage(final_damage, current_weapon.is_shotgun or current_weapon.weapon_id == "aa12")
			hit_enemy.emit()
			if hit_sound_player:
				hit_sound_player.stream = SoundEffects.create_hit_sound()
				hit_sound_player.pitch_scale = randf_range(1.15, 1.3)
				hit_sound_player.play()
	
	spawn_tracer(from_pos, hit_pos)
	if hit_something:
		spawn_impact(hit_pos, result.normal, hit_an_enemy)

func spawn_tracer(from: Vector3, to: Vector3) -> void:
	if not bullet_tracer_scene:
		return
	var tracer: Node3D = bullet_tracer_scene.instantiate()
	tracer.position = from
	get_tree().root.add_child(tracer)
	tracer.init(from, to)

func spawn_impact(pos: Vector3, normal: Vector3, is_blood: bool) -> void:
	if not bullet_impact_scene:
		return
	var impact: Node3D = bullet_impact_scene.instantiate()
	impact.position = pos
	get_tree().root.add_child(impact)
	impact.global_position = pos
	if normal.length_squared() > 0.001:
		var n_dir: Vector3 = normal.normalized()
		if absf(n_dir.dot(Vector3.UP)) > 0.99:
			impact.look_at(pos + normal, Vector3.RIGHT)
		else:
			impact.look_at(pos + normal, Vector3.UP)
	impact.init(is_blood)

# ==========================================
# REBUILT CINEMATIC RELOAD ANIMATIONS (ALL 4 WEAPONS!)
# Uses dedicated anim_pos / anim_rot layer so recoil never fights reloads!
# ==========================================
func start_reload() -> void:
	if is_reloading or is_reloading_ugl or is_quick_knifing or not current_weapon or current_weapon.is_melee:
		return
	if is_ugl_mode:
		if current_weapon.has_mechanic("underbarrel_grenade_launcher"):
			_reload_ugl_async(current_weapon)
		return
	var max_cap: int = current_weapon.get_max_reload_capacity()
	if current_weapon.current_ammo >= max_cap:
		return
	if get_reserve_ammo(current_weapon) <= 0 and not infinite_reserve_ammo:
		return
		
	is_reloading = true
	set_aiming(false)
	emit_ammo_state()
	
	if current_weapon.is_shotgun:
		reload_shotgun_sequential()
	elif current_weapon.is_rpg:
		reload_rpg()
	elif current_weapon.is_bolt_action:
		reload_bolt_rifle()
	elif current_weapon.is_belt_fed:
		reload_belt_lmg()
	else:
		reload_magazine_weapon()

# 1) RPG-7 Two-Stage Front Warhead Loading Animation
func reload_rpg() -> void:
	var rpg_weapon: Weapon = current_weapon
	
	var tw_dip := create_tween()
	tw_dip.set_parallel(true)
	tw_dip.tween_property(self, "anim_pos", Vector3(-0.04, -0.15, 0.06), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_dip.tween_property(self, "anim_rot", Vector3(deg_to_rad(18.0), deg_to_rad(10.0), deg_to_rad(22.0)), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_dip.finished
	if not is_reloading or current_weapon != rpg_weapon:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	await get_tree().create_timer(0.32).timeout
	if not is_reloading or current_weapon != rpg_weapon:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Slide fresh PG-7V booster into front launch tube
	play_sfx(SoundEffects.create_rpg_reload_sound())
	if rpg_warhead:
		rpg_warhead.position = rpg_warhead_initial_pos + Vector3(0.03, -0.05, -0.46)
		rpg_warhead.rotation_degrees = Vector3(6.0, 0, -18.0)
		rpg_warhead.visible = true
		var tw_align := create_tween()
		tw_align.set_parallel(true)
		tw_align.tween_property(rpg_warhead, "position", rpg_warhead_initial_pos + Vector3(0, 0, -0.26), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_align.tween_property(rpg_warhead, "rotation_degrees", Vector3.ZERO, 0.24)
		await tw_align.finished
		if not is_reloading or current_weapon != rpg_weapon:
			rpg_warhead.position = rpg_warhead_initial_pos; rpg_warhead.rotation = Vector3.ZERO
			rpg_warhead.visible = (rpg_weapon.current_ammo > 0)
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
		var tw_seat := create_tween()
		tw_seat.tween_property(rpg_warhead, "position", rpg_warhead_initial_pos, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tw_seat.finished
	else:
		await get_tree().create_timer(0.68).timeout
		
	if not is_reloading or current_weapon != rpg_weapon:
		if rpg_warhead:
			rpg_warhead.position = rpg_warhead_initial_pos
			rpg_warhead.visible = (rpg_weapon.current_ammo > 0)
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Firm latch-lock push & tube jolt
	play_sfx(SoundEffects.create_magazine_in_sound(), 0.72)
	var tw_jolt := create_tween()
	tw_jolt.tween_property(self, "anim_pos:z", 0.115, 0.07).set_trans(Tween.TRANS_QUAD)
	tw_jolt.tween_property(self, "anim_pos:z", 0.06, 0.14).set_trans(Tween.TRANS_BACK)
	await tw_jolt.finished
	
	if (get_reserve_ammo(rpg_weapon) > 0 or infinite_reserve_ammo) and rpg_weapon.current_ammo < 1:
		rpg_weapon.current_ammo = 1
		if not infinite_reserve_ammo:
			consume_reserve_ammo(rpg_weapon, 1)
	emit_ammo_state()
	
	# Heave launcher back onto shoulder
	var tw_up := create_tween()
	tw_up.set_parallel(true)
	tw_up.tween_property(self, "anim_pos", Vector3.ZERO, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_up.tween_property(self, "anim_rot", Vector3.ZERO, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_up.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 2) Pump Shotgun Tactile Shell-by-Shell Reload (with Elevator Deflection + Empty Rack!)
func reload_shotgun_sequential() -> void:
	shotgun_cancel_reload = false
	shotgun_started_empty = not current_weapon.has_round_in_chamber or (current_weapon.current_ammo == 0)
	
	# Roll shotgun to expose underside loading gate cleanly
	var tw_start := create_tween()
	tw_start.set_parallel(true)
	tw_start.tween_property(self, "anim_pos", Vector3(-0.04, -0.05, 0.04), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_start.tween_property(self, "anim_rot", Vector3(deg_to_rad(-16.0), deg_to_rad(10.0), deg_to_rad(32.0)), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_start.finished
	
	var tube_cap: int = current_weapon.mag_size
	var max_cap: int = tube_cap if shotgun_started_empty else (tube_cap + 1)
	while is_reloading and current_weapon and current_weapon.is_shotgun:
		if shotgun_cancel_reload:
			break
		if current_weapon.current_ammo >= max_cap or (get_reserve_ammo(current_weapon) <= 0 and not infinite_reserve_ammo):
			break
			
		# Arc gleaming 12G red shell up into loading gate & deflect steel elevator!
		if shotgun_shell:
			shotgun_shell.position = Vector3(-0.02, -0.17, -0.10)
			shotgun_shell.rotation_degrees = Vector3(24.0, 0, 0)
			shotgun_shell.visible = true
			var tw_sh := create_tween()
			tw_sh.set_parallel(true)
			tw_sh.tween_property(shotgun_shell, "position", Vector3(0.0, -0.040, -0.045), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_sh.tween_property(shotgun_shell, "rotation_degrees", Vector3.ZERO, 0.26)
			tw_sh.tween_property(self, "elevator_offset_y", 0.012, 0.26)
			await tw_sh.finished
			shotgun_shell.visible = false
			var tw_el := create_tween()
			tw_el.tween_property(self, "elevator_offset_y", 0.0, 0.10)
			
		var elapsed: float = 0.26
		while elapsed < 0.72:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			if shotgun_cancel_reload or not is_reloading:
				break
		if shotgun_cancel_reload or not is_reloading:
			break
			
		current_weapon.current_ammo += 1
		if not infinite_reserve_ammo:
			consume_reserve_ammo(current_weapon, 1)
		emit_ammo_state()
		play_sfx(SoundEffects.create_shell_insert_sound())
		
		# Tactile thumb-push upward jolt
		var tw_j := create_tween()
		tw_j.tween_property(self, "anim_pos:y", -0.025, 0.07)
		tw_j.tween_property(self, "anim_pos:y", -0.05, 0.12)
		
	if shotgun_shell:
		shotgun_shell.visible = false
	elevator_offset_y = 0.0
	
	# If started empty and loaded >= 1 shell: rack pump firmly to chamber!
	if shotgun_started_empty and current_weapon and current_weapon.current_ammo > 0:
		var tw_lv := create_tween()
		tw_lv.tween_property(self, "anim_rot:z", deg_to_rad(10.0), 0.14)
		await tw_lv.finished
		
		var tw_p1 := create_tween()
		tw_p1.set_parallel(true)
		tw_p1.tween_property(self, "pump_offset_z", 0.115, 0.11).set_trans(Tween.TRANS_QUAD)
		tw_p1.tween_property(self, "anim_pos:z", 0.07, 0.11)
		await tw_p1.finished
		play_sfx(SoundEffects.create_pump_sound())
		
		var tw_p2 := create_tween()
		tw_p2.set_parallel(true)
		tw_p2.tween_property(self, "pump_offset_z", 0.0, 0.11).set_trans(Tween.TRANS_QUAD)
		tw_p2.tween_property(self, "anim_pos:z", 0.02, 0.11)
		await tw_p2.finished
		current_weapon.has_round_in_chamber = true
		if current_weapon.current_ammo == tube_cap:
			shotgun_is_4_plus_1 = true
	elif current_weapon and current_weapon.current_ammo > 0:
		current_weapon.has_round_in_chamber = true
		if current_weapon.current_ammo >= tube_cap + 1:
			shotgun_is_4_plus_1 = false
		
	var tw_end := create_tween()
	tw_end.set_parallel(true)
	tw_end.tween_property(self, "anim_pos", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_end.tween_property(self, "anim_rot", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_end.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 3A) Museum-Grade Mauser Kar98k Reload:
#     - Forward Scout optic leaves the Mauser receiver bridge & stripper-clip guides 100% unobstructed!
#     - >=5 missing & >=5 reserve: loads 5-round Stripper Clips (Ladestreifen) in sequence
#       (1 clip for 5-round mag; 2 separate 5-round clips for 10-round trench mag with intermediate clip ejection!)
#     - Remaining 1..4 rounds (or <5 reserve): interruptible single-round hand loading!
func reload_kar98k() -> void:
	var reloading_w: Weapon = current_weapon
	kar98k_cancel_reload = false
	kar98k_last_reload_clips_loaded = 0
	var max_cap: int = reloading_w.get_max_reload_capacity()
	var optic_blocks_clip: bool = false

	# Stage 1: Tilt Kar98k inboard to showcase Mauser 98 receiver bridge, thumb cutout & open action!
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	tw_tilt.tween_property(self, "anim_pos", Vector3(-0.044, -0.066, 0.035), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(-7.0), deg_to_rad(16.0), deg_to_rad(24.0)), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_tilt.finished
	if not is_reloading or current_weapon != reloading_w:
		_reset_kar98k_pose_state()
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return

	# Stage 2: Lift swept Mauser bolt handle (+76 deg, non-rotating shroud!) & pull bolt back to bolt stop
	play_sfx(SoundEffects.create_kar98k_bolt_open_sound(), randf_range(0.97, 1.02))
	if kar98k_extracted_case:
		kar98k_extracted_case.visible = kar98k_has_spent_case
	if kar98k_follower_round:
		kar98k_follower_round.visible = (reloading_w.current_ammo > 0)

	var tw_lift := create_tween()
	tw_lift.set_parallel(true)
	if kar98k_bolt_rotator:
		tw_lift.tween_property(kar98k_bolt_rotator, "rotation:z", deg_to_rad(76.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif kar98k_bolt:
		tw_lift.tween_property(kar98k_bolt, "rotation:z", deg_to_rad(76.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if kar98k_cocking_piece:
		tw_lift.tween_property(kar98k_cocking_piece, "position:z", kar98k_cocking_initial_z, 0.12)
	tw_lift.tween_property(self, "anim_rot:z", deg_to_rad(30.0), 0.12)
	await tw_lift.finished
	if not is_reloading or current_weapon != reloading_w:
		_reset_kar98k_pose_state()
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return

	var tw_pull := create_tween()
	tw_pull.set_parallel(true)
	if kar98k_bolt:
		tw_pull.tween_property(kar98k_bolt, "position:z", kar98k_bolt_initial_pos.z + 0.102, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_pull.tween_property(self, "anim_pos:z", 0.056, 0.14)
	tw_pull.tween_property(self, "anim_rot:z", deg_to_rad(23.0), 0.14)
	await tw_pull.finished
	if not is_reloading or current_weapon != reloading_w:
		_reset_kar98k_pose_state()
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return

	# If the 5th fired brass case was still in the chamber, eject it cleanly at the Mauser bolt stop!
	if kar98k_has_spent_case:
		if kar98k_extracted_case:
			kar98k_extracted_case.visible = false
		kar98k_has_spent_case = false
		eject_casing(1, kar98k_model.get_node_or_null("EjectMarker"))

	# Stage 3: Load ammunition — 5-round Ladestreifen stripper clips (1 clip for 5rd, 2 clips for 10rd trench mag!)
	#          followed by single-round hand loading for any remainder (or all rounds when a scope sits over the bridge).
	var kick_empty_clip: bool = false
	if (not optic_blocks_clip) and kar98k_clip:
		while is_reloading and current_weapon == reloading_w and not kar98k_cancel_reload:
			var missing_now: int = max_cap - reloading_w.current_ammo
			var res_now: int = 999 if infinite_reserve_ammo else get_reserve_ammo(reloading_w)
			if missing_now < 5 or res_now < 5:
				break
			if kar98k_clip_rail:
				kar98k_clip_rail.position = kar98k_clip_rail_initial_pos
				kar98k_clip_rail.rotation = Vector3.ZERO
				kar98k_clip_rail.visible = true
			if kar98k_clip_rounds:
				kar98k_clip_rounds.position = Vector3.ZERO
				kar98k_clip_rounds.visible = true

			# Arc 5-round brass/steel clip from pouch up into receiver bridge clip guides (Ladestreifenführung)
			kar98k_clip.position = kar98k_clip_initial_pos + Vector3(0.055, -0.055, 0.035)
			kar98k_clip.rotation_degrees = Vector3(14.0, -14.0, -24.0)
			kar98k_clip.visible = true

			var tw_approach := create_tween()
			tw_approach.set_parallel(true)
			tw_approach.tween_property(kar98k_clip, "position", kar98k_clip_initial_pos + Vector3(0.0, 0.022, 0.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_approach.tween_property(kar98k_clip, "rotation_degrees", Vector3.ZERO, 0.18)
			await tw_approach.finished
			if not is_reloading or current_weapon != reloading_w:
				_reset_kar98k_pose_state()
				anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
				return

			# Seat clip into steel receiver bridge slot + play real 1936 Kar98k Clip-In + Thumb-Strip audio!
			play_sfx(SoundEffects.create_kar98k_clip_in_sound(), randf_range(0.98, 1.02))
			var tw_seat := create_tween()
			tw_seat.set_parallel(true)
			tw_seat.tween_property(kar98k_clip, "position", kar98k_clip_initial_pos, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_seat.tween_property(self, "anim_pos:y", -0.074, 0.08)
			await tw_seat.finished
			if not is_reloading or current_weapon != reloading_w:
				_reset_kar98k_pose_state()
				anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
				return

			# Authentic Mauser thumb-strip: 5 ClipRounds slide deep into internal magazine while steel ClipRail stays in guides!
			var tw_strip := create_tween()
			tw_strip.set_parallel(true)
			if kar98k_clip_rounds:
				tw_strip.tween_property(kar98k_clip_rounds, "position:y", -0.052, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw_strip.tween_property(self, "anim_pos:y", -0.098, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_strip.tween_property(self, "anim_rot:x", deg_to_rad(-11.0), 0.24)
			await tw_strip.finished
			if not is_reloading or current_weapon != reloading_w:
				_reset_kar98k_pose_state()
				anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
				return

			if kar98k_clip_rounds:
				kar98k_clip_rounds.visible = false
			if kar98k_follower_round:
				kar98k_follower_round.visible = true

			# Commit strictly 5 rounds per stripper clip!
			var clip_load: int = mini(5, max_cap - reloading_w.current_ammo)
			if infinite_reserve_ammo:
				reloading_w.current_ammo += clip_load
			else:
				reloading_w.current_ammo += consume_reserve_ammo(reloading_w, clip_load)
			kar98k_last_reload_clips_loaded += 1
			emit_ammo_state()

			var more_to_load: bool = (reloading_w.current_ammo < max_cap) and (infinite_reserve_ammo or get_reserve_ammo(reloading_w) > 0) and (not kar98k_cancel_reload)
			if more_to_load:
				# Flick spent 1st stripper clip out of the bridge before inserting the 2nd clip or top-off rounds!
				kick_empty_clip = false
				var tw_eject_mid := create_tween()
				tw_eject_mid.set_parallel(true)
				if kar98k_clip_rail:
					tw_eject_mid.tween_property(kar98k_clip_rail, "position", kar98k_clip_rail_initial_pos + Vector3(0.11, 0.08, -0.03), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tw_eject_mid.tween_property(kar98k_clip_rail, "rotation_degrees", Vector3(95.0, 42.0, -140.0), 0.14)
				tw_eject_mid.tween_property(self, "anim_pos:y", -0.068, 0.12)
				tw_eject_mid.tween_property(self, "anim_rot:x", deg_to_rad(-7.0), 0.12)
				await tw_eject_mid.finished
				kar98k_clip.visible = false
				if kar98k_clip_rail:
					kar98k_clip_rail.position = kar98k_clip_rail_initial_pos
					kar98k_clip_rail.rotation = Vector3.ZERO
				if not is_reloading or current_weapon != reloading_w:
					_reset_kar98k_pose_state()
					anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
					return
			else:
				kick_empty_clip = true
				var tw_rel := create_tween()
				tw_rel.set_parallel(true)
				tw_rel.tween_property(self, "anim_pos:y", -0.068, 0.11)
				tw_rel.tween_property(self, "anim_rot:x", deg_to_rad(-7.0), 0.11)
				await tw_rel.finished
				break

	# Single-Round Hand Loading for remaining 1..4 rounds (or full load when scope blocks stripper clips!)
	while is_reloading and current_weapon == reloading_w and not kar98k_cancel_reload:
		if reloading_w.current_ammo >= max_cap:
			break
		if not infinite_reserve_ammo and get_reserve_ammo(reloading_w) <= 0:
			break

		if kar98k_single_round:
			kar98k_single_round.position = Vector3(0.045, -0.038, 0.024)
			kar98k_single_round.rotation_degrees = Vector3(-16.0, -22.0, -24.0)
			kar98k_single_round.visible = true

			var tw_r_up := create_tween()
			tw_r_up.set_parallel(true)
			tw_r_up.tween_property(kar98k_single_round, "position", Vector3(0.002, 0.030, -0.028), 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_r_up.tween_property(kar98k_single_round, "rotation_degrees", Vector3(-6.0, 0.0, 0.0), 0.19)
			await tw_r_up.finished
			if not is_reloading or current_weapon != reloading_w or kar98k_cancel_reload:
				kar98k_single_round.visible = false
				break

			play_sfx(SoundEffects.create_shell_insert_sound(), randf_range(1.18, 1.26))
			var tw_r_in := create_tween()
			tw_r_in.set_parallel(true)
			tw_r_in.tween_property(kar98k_single_round, "position", Vector3(0.0, 0.010, -0.030), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_r_in.tween_property(kar98k_single_round, "rotation_degrees", Vector3.ZERO, 0.15)
			tw_r_in.tween_property(self, "anim_pos:y", -0.084, 0.08)
			await tw_r_in.finished
			kar98k_single_round.visible = false
		else:
			await get_tree().create_timer(0.34).timeout

		if not is_reloading or current_weapon != reloading_w:
			_reset_kar98k_pose_state()
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return

		reloading_w.current_ammo += 1
		if not infinite_reserve_ammo:
			consume_reserve_ammo(reloading_w, 1)
		if kar98k_follower_round:
			kar98k_follower_round.visible = true
		emit_ammo_state()

		var tw_r_rec := create_tween()
		tw_r_rec.tween_property(self, "anim_pos:y", -0.066, 0.09)
		await tw_r_rec.finished
		if kar98k_cancel_reload:
			break

	if not is_reloading or current_weapon != reloading_w:
		_reset_kar98k_pose_state()
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return

	# Stage 4: Slam Mauser bolt forward, fling empty steel stripper clip spinning away (Ladestreifen-Auswurf!),
	#          strip top 7.92x57mm cartridge into chamber, and lock bolt handle down!
	play_sfx(SoundEffects.create_kar98k_bolt_close_sound(), randf_range(0.98, 1.03))
	if kar98k_single_round and reloading_w.current_ammo > 0:
		kar98k_single_round.position = Vector3(0.0, 0.012, -0.028)
		kar98k_single_round.rotation_degrees = Vector3(6.0, 0.0, 0.0)
		kar98k_single_round.visible = true
		if reloading_w.current_ammo <= 1 and kar98k_follower_round:
			kar98k_follower_round.visible = false

	if kick_empty_clip and kar98k_clip and kar98k_clip_rail:
		var tw_kick := create_tween()
		tw_kick.set_parallel(true)
		tw_kick.tween_property(kar98k_clip_rail, "position", kar98k_clip_rail_initial_pos + Vector3(0.14, 0.09, -0.05), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_kick.tween_property(kar98k_clip_rail, "rotation_degrees", Vector3(135.0, 58.0, -190.0), 0.18)

	var tw_fwd := create_tween()
	tw_fwd.set_parallel(true)
	if kar98k_bolt:
		tw_fwd.tween_property(kar98k_bolt, "position:z", kar98k_bolt_initial_pos.z, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_fwd.tween_property(self, "anim_pos:z", 0.015, 0.14)
	if kar98k_single_round and kar98k_single_round.visible:
		tw_fwd.tween_property(kar98k_single_round, "position", Vector3(0.0, 0.016, -0.105), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_fwd.tween_property(kar98k_single_round, "rotation_degrees", Vector3.ZERO, 0.11)
	await tw_fwd.finished
	if kar98k_single_round:
		kar98k_single_round.visible = false
	if kar98k_clip:
		kar98k_clip.visible = false
	if kar98k_clip_rail:
		kar98k_clip_rail.position = kar98k_clip_rail_initial_pos
		kar98k_clip_rail.rotation = Vector3.ZERO

	if not is_reloading or current_weapon != reloading_w:
		_reset_kar98k_pose_state()
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return

	var tw_lock := create_tween()
	tw_lock.set_parallel(true)
	if kar98k_bolt_rotator:
		tw_lock.tween_property(kar98k_bolt_rotator, "rotation:z", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif kar98k_bolt:
		tw_lock.tween_property(kar98k_bolt, "rotation:z", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_lock.tween_property(self, "anim_pos", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_lock.tween_property(self, "anim_rot", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_lock.finished

	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 3) Bolt-Action Rifle Reload (Kar98k Dual-Mode Mauser Stripper Clip / Single-Round & L96A1 Detachable Box Mag)
func reload_bolt_rifle() -> void:
	if current_weapon and current_weapon.weapon_id == "kar98k":
		await reload_kar98k()
		return
	var reloading_w: Weapon = current_weapon
	var wid: String = reloading_w.weapon_id
	var is_tactical: bool = reloading_w.has_round_in_chamber and (reloading_w.current_ammo > 0)
	var max_cap: int = reloading_w.get_max_reload_capacity()
	
	# Tilt rifle to show breech / magwell
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	tw_tilt.tween_property(self, "anim_pos", Vector3(-0.04, -0.075, 0.04), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(-6.0), deg_to_rad(14.0), deg_to_rad(26.0)), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_tilt.finished
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	if wid == "l96a1" and l96a1_mag:
		# Detach 5-round .338 Lapua box magazine
		play_sfx(SoundEffects.create_magazine_out_sound(), 0.88)
		var tw_out := create_tween()
		tw_out.tween_property(l96a1_mag, "position", l96a1_mag_initial_pos + Vector3(0, -0.22, 0.02), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_out.finished
		if not is_reloading or current_weapon != reloading_w:
			l96a1_mag.position = l96a1_mag_initial_pos
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
			
		await get_tree().create_timer(0.16).timeout
		# Insert fresh .338 box magazine
		l96a1_mag.position = l96a1_mag_initial_pos + Vector3(0, -0.22, 0.02)
		var tw_in := create_tween()
		tw_in.tween_property(l96a1_mag, "position", l96a1_mag_initial_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_in.finished
		play_sfx(SoundEffects.create_magazine_in_sound(), 0.85)
		var tw_j := create_tween()
		tw_j.tween_property(self, "anim_pos:y", -0.052, 0.06)
		tw_j.tween_property(self, "anim_pos:y", -0.075, 0.10)
		await tw_j.finished
		
		# If empty: cycle L96A1 bolt to chamber fresh .338 round
		if not is_tactical and l96a1_bolt:
			play_sfx(SoundEffects.create_bolt_cycle_sound(), 0.94)
			var tw_b := create_tween()
			tw_b.tween_property(l96a1_bolt, "rotation:z", deg_to_rad(62.0), 0.10)
			tw_b.tween_property(l96a1_bolt, "position:z", l96a1_bolt_initial_pos.z + 0.095, 0.12)
			tw_b.tween_property(l96a1_bolt, "position:z", l96a1_bolt_initial_pos.z, 0.12)
			tw_b.tween_property(l96a1_bolt, "rotation:z", 0.0, 0.10)
			await tw_b.finished
			reloading_w.has_round_in_chamber = true
			
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	var needed: int = max_cap - reloading_w.current_ammo
	if infinite_reserve_ammo:
		reloading_w.current_ammo += needed
	else:
		var taken: int = consume_reserve_ammo(reloading_w, needed)
		reloading_w.current_ammo += taken
		
	var tw_up := create_tween()
	tw_up.set_parallel(true)
	tw_up.tween_property(self, "anim_pos", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_up.tween_property(self, "anim_rot", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_up.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 4) Belt-Fed Heavy LMG Reload (PKM & MG 42: Hinged Top Cover -> Ammo Box Swap -> Slam Cover -> Rack Handle)
func reload_belt_lmg() -> void:
	var reloading_w: Weapon = current_weapon
	var wid: String = reloading_w.weapon_id
	var top_cover: Node3D = pkm_top_cover if wid == "pkm" else mg42_top_cover
	var ammo_box: Node3D = pkm_ammo_box if wid == "pkm" else mg42_ammo_box
	var box_init: Vector3 = pkm_box_initial_pos if wid == "pkm" else mg42_box_initial_pos
	var handle_prop: String = "pkm_handle_offset_z" if wid == "pkm" else "mg42_handle_offset_z"
	var was_empty: bool = (reloading_w.current_ammo <= 0)
	
	# Stage 1: Heavy tilt showing feed tray & top cover
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	tw_tilt.tween_property(self, "anim_pos", Vector3(-0.04, -0.09, 0.05), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(-10.0), deg_to_rad(12.0), deg_to_rad(20.0)), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_tilt.finished
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Stage 2: Flip hinged top cover open 74 degrees!
	play_sfx(SoundEffects.create_magazine_out_sound(), 0.78)
	if top_cover:
		var tw_cov_open := create_tween()
		tw_cov_open.tween_property(top_cover, "rotation:x", deg_to_rad(74.0), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw_cov_open.finished
	if not is_reloading or current_weapon != reloading_w:
		if top_cover: top_cover.rotation = Vector3.ZERO
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Stage 3: Detach spent ammo box/drum and lock fresh belt box
	if ammo_box:
		play_sfx(SoundEffects.create_magazine_out_sound(), 0.68)
		var drop_off: Vector3 = Vector3(0, -0.28, 0.03) if wid == "pkm" else Vector3(-0.24, -0.22, 0.02)
		var tw_bout := create_tween()
		tw_bout.tween_property(ammo_box, "position", box_init + drop_off, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_bout.finished
		if not is_reloading or current_weapon != reloading_w:
			if top_cover: top_cover.rotation = Vector3.ZERO
			ammo_box.position = box_init
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
		await get_tree().create_timer(0.28).timeout
		ammo_box.position = box_init + drop_off
		var tw_bin := create_tween()
		tw_bin.tween_property(ammo_box, "position", box_init, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_bin.finished
		play_sfx(SoundEffects.create_magazine_in_sound(), 0.72)
		var tw_bj := create_tween()
		tw_bj.tween_property(self, "anim_pos:y", -0.065, 0.07)
		tw_bj.tween_property(self, "anim_pos:y", -0.09, 0.12)
		await tw_bj.finished
		
	if not is_reloading or current_weapon != reloading_w:
		if top_cover: top_cover.rotation = Vector3.ZERO
		if ammo_box: ammo_box.position = box_init
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Stage 4: Slam top cover shut!
	if top_cover:
		var tw_cov_close := create_tween()
		tw_cov_close.tween_property(top_cover, "rotation:x", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_cov_close.finished
		play_sfx(SoundEffects.create_magazine_in_sound(), 0.62)
		var tw_slam := create_tween()
		tw_slam.tween_property(self, "anim_pos:y", -0.115, 0.06)
		tw_slam.tween_property(self, "anim_pos:y", -0.09, 0.12)
		await tw_slam.finished
		
	# Stage 5: Rack charging handle if belt ran dry
	if was_empty:
		play_sfx(SoundEffects.create_bolt_pull_ak_sound(), 0.82)
		var tw_rack := create_tween()
		tw_rack.tween_property(self, handle_prop, 0.095, 0.15).set_trans(Tween.TRANS_QUAD)
		tw_rack.tween_property(self, handle_prop, 0.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_rack.finished
		
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	var needed: int = reloading_w.mag_size - reloading_w.current_ammo
	if infinite_reserve_ammo:
		reloading_w.current_ammo += needed
	else:
		var taken: int = consume_reserve_ammo(reloading_w, needed)
		reloading_w.current_ammo += taken
		
	var tw_up := create_tween()
	tw_up.set_parallel(true)
	tw_up.tween_property(self, "anim_pos", Vector3.ZERO, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_up.tween_property(self, "anim_rot", Vector3.ZERO, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_up.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 5) AK-47 Rock-and-Lock, Pistol/Deagle Slide-Lock & AA-12 Drum Magazine Reloads!
func reload_magazine_weapon() -> void:
	var reloading_w: Weapon = current_weapon
	var wid: String = reloading_w.weapon_id
	var is_tactical: bool = reloading_w.has_round_in_chamber and (reloading_w.current_ammo > 0)
	var max_cap: int = reloading_w.get_max_reload_capacity()
	
	# Stage 1: Tactical inboard tilt showcasing magwell
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	if wid == "ak47" or wid == "aa12":
		tw_tilt.tween_property(self, "anim_pos", Vector3(-0.045, -0.095, 0.04), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(-8.0), deg_to_rad(14.0), deg_to_rad(28.0)), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw_tilt.tween_property(self, "anim_pos", Vector3(-0.04, -0.075, 0.03), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_tilt.tween_property(self, "anim_rot", Vector3(deg_to_rad(14.0), deg_to_rad(12.0), deg_to_rad(32.0)), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_tilt.finished
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Stage 2: Magazine Detach & Fresh Magazine Insertion
	if wid == "ak47" and ak_magazine:
		# Authentic AK rock-and-lock release: mag rocks FORWARD (-X) then pulls down!
		play_sfx(SoundEffects.create_magazine_out_sound())
		var tw_out := create_tween()
		tw_out.tween_property(ak_magazine, "rotation:x", ak_mag_initial_rot.x - deg_to_rad(26.0), 0.13).set_trans(Tween.TRANS_QUAD)
		tw_out.tween_property(ak_magazine, "position", ak_mag_initial_pos + Vector3(0, -0.26, -0.06), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_out.finished
		if not is_reloading or current_weapon != reloading_w:
			ak_magazine.position = ak_mag_initial_pos; ak_magazine.rotation = ak_mag_initial_rot
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
			
		await get_tree().create_timer(0.14).timeout
		# Fresh AK mag hooks front lug angled forward, then rocks back and locks!
		ak_magazine.position = ak_mag_initial_pos + Vector3(0, -0.26, -0.05)
		ak_magazine.rotation.x = ak_mag_initial_rot.x - deg_to_rad(28.0)
		var tw_in := create_tween()
		tw_in.tween_property(ak_magazine, "position", ak_mag_initial_pos, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_in.tween_property(ak_magazine, "rotation:x", ak_mag_initial_rot.x, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw_in.finished
		play_sfx(SoundEffects.create_magazine_in_sound())
		# Upward mag-lock rifle jolt!
		var tw_j := create_tween()
		tw_j.tween_property(self, "anim_pos:y", -0.072, 0.06)
		tw_j.tween_property(self, "anim_pos:y", -0.095, 0.10)
		await tw_j.finished
		
	elif wid == "pistol" and pistol_magazine:
		play_sfx(SoundEffects.create_magazine_out_sound())
		var tw_pout := create_tween()
		tw_pout.tween_property(pistol_magazine, "position", pistol_mag_initial_pos + Vector3(0, -0.22, 0.08), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_pout.finished
		if not is_reloading or current_weapon != reloading_w:
			pistol_magazine.position = pistol_mag_initial_pos; pistol_magazine.rotation = pistol_mag_initial_rot
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
			
		await get_tree().create_timer(0.12).timeout
		pistol_magazine.position = pistol_mag_initial_pos + Vector3(0, -0.22, 0.08)
		var tw_pin := create_tween()
		tw_pin.tween_property(pistol_magazine, "position", pistol_mag_initial_pos, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_pin.finished
		play_sfx(SoundEffects.create_magazine_in_sound())
		# Crisp palm-slap upward jolt
		var tw_pj := create_tween()
		tw_pj.tween_property(self, "anim_pos:y", -0.048, 0.05)
		tw_pj.tween_property(self, "anim_pos:y", -0.075, 0.10)
		await tw_pj.finished
		
	elif wid == "deagle" and deagle_mag:
		play_sfx(SoundEffects.create_magazine_out_sound(), 0.85)
		var tw_dout := create_tween()
		tw_dout.tween_property(deagle_mag, "position", deagle_mag_initial_pos + Vector3(0, -0.24, 0.08), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_dout.finished
		if not is_reloading or current_weapon != reloading_w:
			deagle_mag.position = deagle_mag_initial_pos
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
		await get_tree().create_timer(0.14).timeout
		deagle_mag.position = deagle_mag_initial_pos + Vector3(0, -0.24, 0.08)
		var tw_din := create_tween()
		tw_din.tween_property(deagle_mag, "position", deagle_mag_initial_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_din.finished
		play_sfx(SoundEffects.create_magazine_in_sound(), 0.82)
		var tw_dj := create_tween()
		tw_dj.tween_property(self, "anim_pos:y", -0.045, 0.06)
		tw_dj.tween_property(self, "anim_pos:y", -0.075, 0.10)
		await tw_dj.finished
		
	elif wid == "aa12" and aa12_mag:
		# Detach massive 20-round drum magazine & slap fresh drum into magwell!
		play_sfx(SoundEffects.create_magazine_out_sound(), 0.76)
		var tw_aout := create_tween()
		tw_aout.tween_property(aa12_mag, "position", aa12_mag_initial_pos + Vector3(0, -0.28, 0.04), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_aout.finished
		if not is_reloading or current_weapon != reloading_w:
			aa12_mag.position = aa12_mag_initial_pos
			anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
			return
		await get_tree().create_timer(0.20).timeout
		aa12_mag.position = aa12_mag_initial_pos + Vector3(0, -0.28, 0.04)
		var tw_ain := create_tween()
		tw_ain.tween_property(aa12_mag, "position", aa12_mag_initial_pos, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw_ain.finished
		play_sfx(SoundEffects.create_magazine_in_sound(), 0.72)
		var tw_aj := create_tween()
		tw_aj.tween_property(self, "anim_pos:y", -0.068, 0.06)
		tw_aj.tween_property(self, "anim_pos:y", -0.095, 0.11)
		await tw_aj.finished
		
	if not is_reloading or current_weapon != reloading_w:
		anim_pos = Vector3.ZERO; anim_rot = Vector3.ZERO
		return
		
	# Stage 3: Empty Reload Charging Handle Rack / Slide Release Snap!
	if not is_tactical:
		if wid == "ak47" and ak_charging_handle:
			# Cant rifle left slightly to expose right-side charging handle!
			var tw_cant := create_tween()
			tw_cant.tween_property(self, "anim_rot:z", deg_to_rad(36.0), 0.12)
			await tw_cant.finished
			
			play_sfx(SoundEffects.create_bolt_pull_ak_sound())
			var tw_pull := create_tween()
			tw_pull.set_parallel(true)
			tw_pull.tween_property(self, "ak_handle_offset_z", 0.085, 0.13).set_trans(Tween.TRANS_QUAD)
			tw_pull.tween_property(self, "anim_pos:z", 0.068, 0.13)
			await tw_pull.finished
			
			var tw_snap := create_tween()
			tw_snap.set_parallel(true)
			tw_snap.tween_property(self, "ak_handle_offset_z", 0.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_snap.tween_property(self, "anim_pos:z", 0.028, 0.07)
			await tw_snap.finished
			
		elif wid == "pistol" and pistol_slide:
			play_sfx(SoundEffects.create_slide_pull_pistol_sound())
			pistol_slide_locked_back = false
			pistol_slide_offset_z = 0.042
			var tw_sl := create_tween()
			tw_sl.set_parallel(true)
			tw_sl.tween_property(self, "pistol_slide_offset_z", 0.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_sl.tween_property(self, "anim_rot:x", deg_to_rad(-6.0), 0.075)
			await tw_sl.finished
			
		elif wid == "deagle" and deagle_slide:
			play_sfx(SoundEffects.create_slide_pull_pistol_sound(), 0.78)
			deagle_slide_locked_back = false
			deagle_slide_offset_z = 0.052
			var tw_dsl := create_tween()
			tw_dsl.set_parallel(true)
			tw_dsl.tween_property(self, "deagle_slide_offset_z", 0.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_dsl.tween_property(self, "anim_rot:x", deg_to_rad(-9.0), 0.09)
			await tw_dsl.finished
			
		elif wid == "aa12" and aa12_charging_handle and reloading_w.current_ammo <= 0:
			play_sfx(SoundEffects.create_bolt_pull_ak_sound(), 0.85)
			var tw_aa := create_tween()
			tw_aa.tween_property(self, "aa12_handle_offset_z", 0.088, 0.13).set_trans(Tween.TRANS_QUAD)
			tw_aa.tween_property(self, "aa12_handle_offset_z", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw_aa.finished
			
		if wid != "aa12":
			reloading_w.has_round_in_chamber = true
		
	# Apply reloaded ammo from shared caliber reserve pool
	var needed: int = max_cap - reloading_w.current_ammo
	if infinite_reserve_ammo:
		reloading_w.current_ammo += needed
	else:
		var reload_amount: int = consume_reserve_ammo(reloading_w, needed)
		reloading_w.current_ammo += reload_amount
	
	# Stage 4: Crisp return to combat ready
	var tw_up := create_tween()
	tw_up.set_parallel(true)
	tw_up.tween_property(self, "anim_pos", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_up.tween_property(self, "anim_rot", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_up.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.bus = "Weapons"
	sfx.stream = stream
	sfx.pitch_scale = pitch
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

# ==========================================
# REBUILT QUICK KNIFE ALTERNATING COMBO SLASH ([V])
# ==========================================
func _update_knife_slash(progress: float) -> void:
	if not knife_model:
		return
	var t: float = clampf(progress, 0.0, 1.0)
	var dir_sign: float = -1.0 if knife_combo_alt else 1.0
	var x: float = lerpf(0.28 * dir_sign, -0.28 * dir_sign, t)
	var y: float = -0.02 + sin(t * PI) * 0.07 - (t * t) * 0.14
	var z: float = -0.07 - 0.24 * sin(t * PI) + 0.05 * (t * t)
	knife_model.position = Vector3(x, y, z)
	
	var rx: float = -8.0 + 22.0 * (t * t)
	var ry: float = (22.0 - 38.0 * t) * dir_sign
	var rz: float = (-18.0 + 52.0 * t) * dir_sign
	knife_model.rotation_degrees = Vector3(rx, ry, rz)

func quick_knife_attack() -> void:
	if is_quick_knifing or is_switching:
		return
	var player_node: Node = owner
	if player_node:
		if ("is_in_shop" in player_node) and player_node.is_in_shop:
			return
		var hud = player_node.get_node_or_null("HUD")
		if hud and hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
			return
	if is_reloading:
		if current_weapon and current_weapon.is_shotgun:
			shotgun_cancel_reload = true
		elif current_weapon and current_weapon.weapon_id == "kar98k":
			kar98k_cancel_reload = true
		else:
			return
	is_quick_knifing = true
	can_shoot = false
	set_aiming(false)
	
	var all_firearm_models: Array[Node3D] = [
		ak47_model, shotgun_model, pistol_model, rpg_model,
		kar98k_model, pkm_model, l96a1_model, deagle_model, aa12_model, mg42_model
	]
	var prev_vis: Array[bool] = []
	for fm in all_firearm_models:
		prev_vis.append(fm.visible if fm else false)
		if fm:
			fm.visible = false
	
	var hud_node: Node = null
	if player_node and player_node.has_node("HUD"):
		hud_node = player_node.get_node("HUD")
	elif get_tree() and get_tree().root:
		hud_node = get_tree().root.find_child("HUD", true, false)
	if hud_node:
		if hud_node.has_method("flash_knife_indicator"):
			hud_node.flash_knife_indicator()
		if hud_node.has_method("set_knife_active_ui"):
			hud_node.set_knife_active_ui(true)
	
	knife_combo_alt = not knife_combo_alt
	if knife_model:
		knife_model.visible = true
		_update_knife_slash(0.0)
		play_sfx(SoundEffects.create_knife_slash_sound(), randf_range(0.94, 1.08))
		
		var slash_mat: ShaderMaterial = air_slash_mesh.material_override as ShaderMaterial if air_slash_mesh else null
		if air_slash_mesh:
			air_slash_mesh.visible = true
			air_slash_mesh.scale = Vector3(-1.0 if knife_combo_alt else 1.0, 1.0, 1.0)
			if slash_mat:
				slash_mat.set_shader_parameter("slash_alpha", 0.0)
				
		var slash_dur: float = 0.38
		var tw := create_tween()
		tw.tween_method(_update_knife_slash, 0.0, 1.0, slash_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if slash_mat:
			var ftw := create_tween()
			ftw.tween_method(func(v: float): slash_mat.set_shader_parameter("slash_alpha", v), 0.0, 0.92, 0.09)
			ftw.tween_method(func(v: float): slash_mat.set_shader_parameter("slash_alpha", v), 0.92, 0.0, 0.28).set_ease(Tween.EASE_IN)
			
		await get_tree().create_timer(0.17).timeout
		perform_knife_hit_detection()
		await tw.finished
	else:
		perform_knife_hit_detection()
		await get_tree().create_timer(0.38).timeout
		
	if knife_model: knife_model.visible = false
	if air_slash_mesh: air_slash_mesh.visible = false
	for i in range(all_firearm_models.size()):
		if all_firearm_models[i]:
			all_firearm_models[i].visible = prev_vis[i]
	
	if hud_node and hud_node.has_method("set_knife_active_ui"):
		hud_node.set_knife_active_ui(false)
		
	is_quick_knifing = false
	if not is_reloading and not is_switching:
		can_shoot = true

func perform_knife_hit_detection() -> void:
	if not camera:
		return
	var space_state := get_world_3d().direct_space_state
	var cam_pos := camera.global_position
	var forward := -camera.global_transform.basis.z.normalized()
	
	var ray_origin := cam_pos + forward * 0.45
	var ray_end := cam_pos + forward * 2.8
	var player_body: CollisionObject3D = owner as CollisionObject3D
	var exclude_rids: Array[RID] = []
	if player_body:
		exclude_rids.append(player_body.get_rid())
	for shop in get_tree().get_nodes_in_group("shop_building"):
		if shop is CollisionObject3D:
			exclude_rids.append(shop.get_rid())
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = exclude_rids
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result: Dictionary = space_state.intersect_ray(query)
	
	var hit_enemy_target: Node = null
	var hit_pos: Vector3 = ray_end
	var hit_norm: Vector3 = -forward
	if not result.is_empty():
		var col: Object = result.collider
		if col != player_body and not (col and col.is_in_group("player")):
			if not (col.is_in_group("shop_building") or col.name == "ShopBuilding"):
				hit_pos = result.position
				hit_norm = result.normal
				if col.is_in_group("tiger_hitbox"):
					var t_owner = col.get_meta("tiger_owner") if col.has_meta("tiger_owner") else null
					var t_zone: String = str(col.get_meta("hit_zone")) if col.has_meta("hit_zone") else ""
					if is_instance_valid(t_owner) and t_owner.has_method("on_bullet_hit"):
						var melee_dmg_t: float = melee_slot.damage if melee_slot else 70.0
						if t_owner.on_bullet_hit(t_zone, melee_dmg_t, hit_pos, hit_norm):
							play_sfx(SoundEffects.create_knife_hit_sound())
							hit_enemy.emit()
							spawn_impact(hit_pos, hit_norm, true)
							return
				elif col.is_in_group("black_van_hitbox"):
					var v_owner = col.get_meta("van_owner") if col.has_meta("van_owner") else null
					var v_zone: String = str(col.get_meta("hit_zone")) if col.has_meta("hit_zone") else ""
					if is_instance_valid(v_owner) and v_owner.has_method("on_bullet_hit"):
						var melee_dmg_v: float = melee_slot.damage if melee_slot else 70.0
						if v_owner.on_bullet_hit(v_zone, melee_dmg_v, hit_pos, hit_norm):
							play_sfx(SoundEffects.create_knife_hit_sound())
							hit_enemy.emit()
							spawn_impact(hit_pos, hit_norm, true)
							return
				elif col.is_in_group("enemy"):
					hit_enemy_target = col
				elif col.get_parent() and col.get_parent().is_in_group("enemy"):
					hit_enemy_target = col.get_parent()
	if not hit_enemy_target:
		var closest_dist: float = 999.0
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(enemy):
				continue
			var to_enemy: Vector3 = enemy.global_position - cam_pos
			to_enemy.y -= 0.5
			var dist := to_enemy.length()
			if dist <= 2.6:
				if forward.dot(to_enemy.normalized()) > 0.65 and dist < closest_dist:
					closest_dist = dist
					hit_enemy_target = enemy
					hit_pos = enemy.global_position + Vector3(0, 0.8, 0)
	if hit_enemy_target:
		var melee_dmg: float = melee_slot.damage if melee_slot else 70.0
		if hit_enemy_target.has_method("take_damage"):
			hit_enemy_target.take_damage(melee_dmg)
		play_sfx(SoundEffects.create_knife_hit_sound())
		hit_enemy.emit()
		spawn_impact(hit_pos, hit_norm, true)

func add_reserve_ammo(slot: int, amount: int) -> void:
	for w in weapons:
		if w.slot == slot:
			add_reserve_ammo_by_type(w.get_active_ammo_pool_key(), amount)
			return

func add_reserve_ammo_by_id(wid: String, amount: int) -> void:
	var w := get_weapon_by_id(wid)
	if w:
		add_reserve_ammo_by_type(w.get_active_ammo_pool_key(), amount)
