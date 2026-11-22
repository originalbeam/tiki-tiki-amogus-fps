extends Node3D

signal weapon_changed(weapon: Weapon)
signal ammo_updated(current: int, reserve: int, is_reloading: bool, has_chamber: bool, shotgun_4_plus_1: bool)
signal hit_enemy()
signal slots_updated()
signal ads_state_changed(is_aiming: bool, zoom: float, reticle: String)

@export var camera: Camera3D
@export var bullet_tracer_scene: PackedScene = preload("res://scenes/bullet_tracer.tscn")
@export var bullet_impact_scene: PackedScene = preload("res://scenes/bullet_impact.tscn")
@export var shell_casing_scene: PackedScene = preload("res://scenes/shell_casing.tscn")

const AK47ModelScript = preload("res://scripts/weapons/models/ak47_model.gd")
const ShotgunModelScript = preload("res://scripts/weapons/models/shotgun_model.gd")
const PistolModelScript = preload("res://scripts/weapons/models/pistol_model.gd")
const RPGModelScript = preload("res://scripts/weapons/models/rpg_model.gd")
const KnifeModelScript = preload("res://scripts/weapons/models/knife_model.gd")
const RPGRocketScript = preload("res://scripts/weapons/rpg_rocket.gd")
const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

# Dynamic Slot-Based Arsenal
var weapons: Array[Weapon] = []
var weapon_slots: Array = [null, null, null]
var current_weapon_idx: int = 0
var current_weapon: Weapon = null
var melee_slot: Weapon = null
var owned_melee: Array[Weapon] = []

# Cheat & ADS states
var infinite_reserve_ammo: bool = false
var is_aiming: bool = false
var ads_blend: float = 0.0
var current_ads_zoom: float = 1.0

# Picture-in-Picture (PiP) Scope SubViewport & Camera (magnifies ONLY inside magnifying scopes!)
var scope_viewport: SubViewport = null
var scope_camera: Camera3D = null
var active_optic_lens: MeshInstance3D = null

var can_shoot: bool = true
var is_reloading: bool = false
var is_switching: bool = false
var shoot_timer: float = 0.0

# Shotgun reload state
var shotgun_cancel_reload: bool = false
var shotgun_started_empty: bool = false
var shotgun_is_4_plus_1: bool = false

# High-Detail Unified Viewmodel References (rebuilt from scratch in _ready!)
var ak47_model: Node3D = null
var shotgun_model: Node3D = null
var pistol_model: Node3D = null
var rpg_model: Node3D = null
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
	
	# Initialize starting arsenal (AK-47, Shotgun, Pistol in slots 1..3; RPG-7 bought in Shop)
	weapons.clear()
	var w_ak := Weapon.create_ak47()
	var w_sg := Weapon.create_shotgun()
	var w_ps := Weapon.create_pistol()
	weapons.append(w_ak)
	weapons.append(w_sg)
	weapons.append(w_ps)
	
	weapon_slots = [w_ak, w_sg, w_ps]
	w_ak.slot = 1
	w_sg.slot = 2
	w_ps.slot = 3
	
	# Specialized Melee Slot ([V])
	melee_slot = Weapon.create_knife()
	owned_melee.clear()
	owned_melee.append(melee_slot)
	
	refresh_active_weapon_mods()
	_set_viewmodel_layers(self, 2)
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
	
	# 4. RPG-7V Launcher
	rpg_model = RPGModelScript.create(true)
	rpg_model.name = "RPG"
	rpg_model.position = Vector3(0.05, 0.03, 0.14)
	add_child(rpg_model)
	rpg_warhead = rpg_model.get_node_or_null("Warhead")
	if rpg_warhead:
		rpg_warhead_initial_pos = rpg_warhead.position
	rpg_model.visible = false
	
	# 5. Combat Bayonet Knife & Metallic Wind-Shear Slash Arc
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
	scope_viewport.size = Vector2i(512, 512)
	scope_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	scope_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(scope_viewport)
	
	scope_camera = Camera3D.new()
	scope_camera.name = "PiPScopeCamera"
	scope_camera.cull_mask = 1 # World layer only (excludes viewmodel on layer 2)
	scope_camera.near = 0.08
	scope_camera.far = 400.0
	scope_camera.fov = 45.0
	scope_camera.current = true
	scope_viewport.add_child(scope_camera)

func _set_viewmodel_layers(node: Node, layer_mask: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = layer_mask
	for child in node.get_children():
		if child == scope_viewport or child == muzzle_smoke or child == ak_sparks:
			continue
		_set_viewmodel_layers(child, layer_mask)

func emit_ammo_state() -> void:
	if current_weapon:
		ammo_updated.emit(
			current_weapon.current_ammo,
			current_weapon.reserve_ammo,
			is_reloading,
			current_weapon.has_round_in_chamber,
			shotgun_is_4_plus_1
		)
	else:
		ammo_updated.emit(0, 0, false, false, false)

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

func grant_weapon(w: Weapon, auto_equip_if_empty: bool = true) -> bool:
	if not w or has_weapon(w.weapon_id):
		return false
	w.slot = 0
	weapons.append(w)
	if auto_equip_if_empty:
		for i in range(weapon_slots.size()):
			if weapon_slots[i] == null:
				equip_weapon_to_slot(w, i)
				return true
	slots_updated.emit()
	return true

func equip_weapon_to_slot(w: Weapon, slot_idx: int) -> void:
	if not w or slot_idx < 0 or slot_idx >= weapon_slots.size():
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

func refresh_active_weapon_mods() -> void:
	var ak := get_weapon_by_id("ak47")
	active_optic_lens = null
	if ak and ak47_model:
		AK47ModelScript.apply_mods_to_node(ak47_model, ak.installed_mods)
		_set_viewmodel_layers(ak47_model, 2)
		var mod_root := ak47_model.get_node_or_null("DynamicMods")
		if mod_root:
			active_optic_lens = mod_root.find_child("OpticLens", true, false) as MeshInstance3D
	if is_aiming and (not current_weapon or not current_weapon.has_mechanic("ads_enabled")):
		set_aiming(false)
	emit_ammo_state()

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
		var zrange := current_weapon.get_ads_zoom_range()
		current_ads_zoom = clampf(current_ads_zoom, zrange.x, zrange.y)
		if current_ads_zoom < zrange.x:
			current_ads_zoom = zrange.x
		var reticle := str(current_weapon.active_mechanics.get("ads_reticle", "red_dot"))
		ads_state_changed.emit(true, current_ads_zoom, reticle)
	else:
		current_ads_zoom = 1.0
		ads_state_changed.emit(false, 1.0, "")

func adjust_ads_zoom(step: float) -> bool:
	if not is_aiming or not current_weapon or not current_weapon.has_mechanic("ads_enabled"):
		return false
	var zrange := current_weapon.get_ads_zoom_range()
	if zrange.y <= zrange.x + 0.01:
		return false
	current_ads_zoom = clampf(current_ads_zoom + step, zrange.x, zrange.y)
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
			
	if is_aiming and (is_reloading or is_switching or is_quick_knifing or not current_weapon or not current_weapon.has_mechanic("ads_enabled")):
		set_aiming(false)
		
	if dry_fire_cooldown > 0.0:
		dry_fire_cooldown -= dt
		
	# 1. Smooth S-curve ADS & Tactical Sprint Low-Ready blending
	var target_ads: float = 1.0 if is_aiming else 0.0
	ads_blend = lerpf(ads_blend, target_ads, dt * 14.0)
	var want_sprint_pose: bool = is_sprinting_now and not is_aiming and not is_reloading and not is_switching and not is_quick_knifing and (shoot_timer <= 0.0)
	sprint_blend = lerpf(sprint_blend, 1.0 if want_sprint_pose else 0.0, dt * 9.0)
	
	# Subtle 12% alive movement in ADS so optic stays clear & readable
	var ads_damp: float = lerpf(1.0, 0.12, ads_blend)
	
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
			"pistol":
				sp_pos = Vector3(-0.035, -0.065, 0.02)
				sp_rot = Vector3(deg_to_rad(-24.0), deg_to_rad(18.0), deg_to_rad(10.0))
			"rpg":
				sp_pos = Vector3(0.02, -0.04, 0.04)
				sp_rot = Vector3(deg_to_rad(12.0), deg_to_rad(14.0), deg_to_rad(-8.0))
	
	# 6. Exact close eye-to-optic ADS alignment per installed optic
	var ads_pos := Vector3(0.0, -0.099, -0.135)
	if current_weapon and str(current_weapon.installed_mods.get("optic", "")) == "optic_lpvo":
		ads_pos = Vector3(0.0, -0.097, -0.195)
	var hip_with_sprint := initial_pos + sp_pos * sprint_blend
	var base_pos := hip_with_sprint.lerp(ads_pos, ads_blend)
	var base_rot := sp_rot * sprint_blend * (1.0 - ads_blend)
	
	# Combine all clean additive layers!
	var rec_mult: float = lerpf(1.0, 0.45, ads_blend)
	position = base_pos + idle_pos + sway_pos * ads_damp + bob_pos * ads_damp + recoil_pos * rec_mult + anim_pos + draw_pos
	rotation = base_rot + idle_rot + sway_rot * ads_damp + bob_rot * ads_damp + recoil_rot * rec_mult + anim_rot + draw_rot
	
	# 7. Update PiP Scope Viewport & Magnifying Lens Shader
	_update_pip_scope()
	
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

func _update_pip_scope() -> void:
	if not scope_viewport or not scope_camera:
		return
	var is_magnifying: bool = current_weapon != null and current_weapon.get_ads_zoom_range().y > 1.05
	var pip_active: bool = (ads_blend > 0.05) and is_magnifying and current_weapon.has_mechanic("ads_enabled") and is_instance_valid(active_optic_lens) and ak47_model and ak47_model.visible
	if pip_active and camera:
		scope_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		scope_camera.global_transform = camera.global_transform
		var eff_zoom: float = lerpf(1.0, maxf(1.0, current_ads_zoom), ads_blend)
		scope_camera.fov = clampf(28.0 / eff_zoom, 5.5, 45.0)
		var mat := active_optic_lens.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("pip_tex", scope_viewport.get_texture())
			mat.set_shader_parameter("use_pip", true)
	else:
		scope_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if is_instance_valid(active_optic_lens):
			var mat := active_optic_lens.material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("use_pip", false)

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
	if idx < 0 or idx >= weapon_slots.size():
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
			"pistol":
				draw_pos = Vector3(0.08, -0.28, 0.06)
				draw_rot = Vector3(deg_to_rad(32.0), deg_to_rad(-14.0), deg_to_rad(24.0))
				draw_dur = 0.17
			"shotgun":
				draw_pos = Vector3(-0.06, -0.36, 0.10)
				draw_rot = Vector3(deg_to_rad(-22.0), deg_to_rad(28.0), deg_to_rad(-18.0))
				draw_dur = 0.26
			"rpg":
				draw_pos = Vector3(0.14, -0.40, 0.16)
				draw_rot = Vector3(deg_to_rad(-34.0), deg_to_rad(-22.0), deg_to_rad(18.0))
				draw_dur = 0.34
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
	if knife_model:
		knife_model.visible = false
		
	if wid == "ak47":
		refresh_active_weapon_mods()
	
	shoot_timer = 0.08
	can_shoot = true
	weapon_changed.emit(current_weapon)
	emit_ammo_state()

func switch_next() -> void:
	if is_quick_knifing:
		return
	for step in range(1, weapon_slots.size() + 1):
		var next_idx: int = (current_weapon_idx + step) % weapon_slots.size()
		if weapon_slots[next_idx] != null:
			switch_weapon(next_idx)
			return

func switch_prev() -> void:
	if is_quick_knifing:
		return
	for step in range(1, weapon_slots.size() + 1):
		var prev_idx: int = (current_weapon_idx - step + weapon_slots.size()) % weapon_slots.size()
		if weapon_slots[prev_idx] != null:
			switch_weapon(prev_idx)
			return

func switch_slot(slot_num: int) -> void:
	if is_quick_knifing:
		return
	var idx: int = slot_num - 1
	if idx >= 0 and idx < weapon_slots.size():
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
		
	if is_reloading:
		if current_weapon.is_shotgun and just_pressed:
			shotgun_cancel_reload = true
			return
		return
			
	if current_weapon.is_automatic:
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
		if just_pressed:
			play_dry_fire_sound()
		start_reload()
		return
		
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
	var pitch_up: float = current_weapon.recoil_pitch * ads_m
	var yaw_rnd: float = randf_range(-current_weapon.recoil_yaw, current_weapon.recoil_yaw) * ads_m
	
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
	
	# Camera recoil + subtle micro-shake on heavy weapons
	var player_node: Node = owner
	if player_node and player_node.has_method("add_camera_recoil"):
		player_node.add_camera_recoil(pitch_up * 0.35, yaw_rnd * 0.25)
	if player_node and player_node.has_method("add_camera_shake") and (wid == "shotgun" or wid == "rpg"):
		player_node.add_camera_shake(0.09 if wid == "rpg" else 0.035)
	
	# Rebuilt volumetric muzzle flash, gunsmoke, sparks & RPG backblast!
	show_muzzle_flash()
	trigger_muzzle_smoke()
	if wid == "ak47" or wid == "shotgun":
		trigger_ak_sparks()
	play_shoot_sound()
	
	if current_weapon.is_rpg:
		if rpg_model:
			var bb: Marker3D = rpg_model.get_node_or_null("BackblastMarker")
			if bb:
				VFXFactoryScript.spawn_rpg_backblast(get_tree().root, bb.global_position, rpg_model.global_transform.basis.z)
		fire_rpg_rocket()
		if current_weapon.current_ammo <= 0 and (current_weapon.reserve_ammo > 0 or infinite_reserve_ammo):
			_schedule_rpg_auto_reload()
		return
	
	if wid == "ak47":
		eject_casing(1, ak47_model.get_node_or_null("EjectMarker"))
	elif wid == "pistol":
		eject_casing(3, pistol_model.get_node_or_null("EjectMarker"))
	elif wid == "shotgun":
		animate_shotgun_pump_with_ejection()
		
	var muzzle_pos: Vector3 = get_active_muzzle_pos()
	for i in range(current_weapon.pellets):
		fire_pellet(muzzle_pos)
		
	if current_weapon.current_ammo <= 0:
		start_reload()

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
	rocket.init(spawn_pos, launch_dir, owner, self, current_weapon.damage, 6.5)

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

func trigger_muzzle_smoke() -> void:
	if not muzzle_smoke or not current_weapon:
		return
	muzzle_smoke.global_position = get_active_muzzle_pos()
	match current_weapon.weapon_id:
		"ak47":
			muzzle_smoke.amount = 10
			muzzle_smoke.lifetime = 0.65
			muzzle_smoke.initial_velocity_max = 2.4
		"shotgun":
			muzzle_smoke.amount = 24
			muzzle_smoke.lifetime = 0.95
			muzzle_smoke.initial_velocity_max = 4.2
		"pistol":
			muzzle_smoke.amount = 6
			muzzle_smoke.lifetime = 0.42
			muzzle_smoke.initial_velocity_max = 1.6
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
			shoot_sound_player.volume_db = -1.5
		"shotgun":
			shoot_sound_player.stream = SoundEffects.create_shotgun_sound()
			shoot_sound_player.pitch_scale = randf_range(0.97, 1.03)
			shoot_sound_player.volume_db = 2.0
		"pistol":
			shoot_sound_player.stream = SoundEffects.create_pistol_sound()
			shoot_sound_player.pitch_scale = randf_range(0.98, 1.03)
			shoot_sound_player.volume_db = 0.5
		"rpg":
			shoot_sound_player.stream = SoundEffects.create_rpg_shot_sound()
			shoot_sound_player.pitch_scale = randf_range(0.95, 1.05)
			shoot_sound_player.volume_db = 1.0
	shoot_sound_player.play()

func show_muzzle_flash() -> void:
	if not muzzle_flash:
		return
	muzzle_flash.global_position = get_active_muzzle_pos()
	muzzle_flash.visible = true
	var wid: String = current_weapon.weapon_id if current_weapon else "ak47"
	var side_jets: Node3D = muzzle_flash.get_node_or_null("SideJets")
	if side_jets:
		side_jets.visible = (wid == "ak47" or wid == "shotgun")
	var sc: float = 1.0
	var energy: float = 3.2
	match wid:
		"rpg":
			sc = 2.4
			energy = 6.8
		"shotgun":
			sc = 1.55
			energy = 4.6
		"pistol":
			sc = 0.72
			energy = 2.2
		_:
			sc = randf_range(0.95, 1.22)
			energy = 3.4
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
	if muzzle_node:
		return muzzle_node.global_position
	return global_position

func fire_pellet(from_pos: Vector3) -> void:
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var center: Vector2 = get_viewport().get_visible_rect().size / 2.0
	
	var eff_spread: float = current_weapon.spread * (0.45 if is_aiming else 1.0)
	var spread_offset := Vector2(
		randf_range(-eff_spread, eff_spread),
		randf_range(-eff_spread, eff_spread)
	) * 400.0
	var screen_pos: Vector2 = center + spread_offset
	
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)
	var ray_origin: Vector3 = camera.project_ray_origin(screen_pos) + ray_dir * 0.45
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
		if collider and collider.is_in_group("enemy"):
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
			collider.take_damage(final_damage, current_weapon.is_shotgun)
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
	if is_reloading or is_quick_knifing or not current_weapon or current_weapon.is_melee:
		return
	var max_cap: int = current_weapon.get_max_reload_capacity()
	if current_weapon.current_ammo >= max_cap:
		return
	if current_weapon.reserve_ammo <= 0 and not infinite_reserve_ammo:
		return
		
	is_reloading = true
	set_aiming(false)
	emit_ammo_state()
	
	if current_weapon.is_shotgun:
		reload_shotgun_sequential()
	elif current_weapon.is_rpg:
		reload_rpg()
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
	
	if (rpg_weapon.reserve_ammo > 0 or infinite_reserve_ammo) and rpg_weapon.current_ammo < 1:
		rpg_weapon.current_ammo = 1
		if not infinite_reserve_ammo:
			rpg_weapon.reserve_ammo -= 1
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
	
	var max_cap: int = 5 if shotgun_started_empty else 6
	while is_reloading and current_weapon and current_weapon.is_shotgun:
		if shotgun_cancel_reload:
			break
		if current_weapon.current_ammo >= max_cap or (current_weapon.reserve_ammo <= 0 and not infinite_reserve_ammo):
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
			current_weapon.reserve_ammo -= 1
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
		if current_weapon.current_ammo == 5:
			shotgun_is_4_plus_1 = true
	elif current_weapon and current_weapon.current_ammo > 0:
		current_weapon.has_round_in_chamber = true
		if current_weapon.current_ammo >= 6:
			shotgun_is_4_plus_1 = false
		
	var tw_end := create_tween()
	tw_end.set_parallel(true)
	tw_end.tween_property(self, "anim_pos", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_end.tween_property(self, "anim_rot", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_end.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 3) AK-47 Rock-and-Lock Reload & Pistol Slide-Lock Reload!
func reload_magazine_weapon() -> void:
	var reloading_w: Weapon = current_weapon
	var wid: String = reloading_w.weapon_id
	var is_tactical: bool = reloading_w.has_round_in_chamber and (reloading_w.current_ammo > 0)
	var max_cap: int = reloading_w.mag_size + (1 if is_tactical else 0)
	
	# Stage 1: Tactical inboard tilt showcasing magwell
	var tw_tilt := create_tween()
	tw_tilt.set_parallel(true)
	if wid == "ak47":
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
			
		reloading_w.has_round_in_chamber = true
		
	# Apply reloaded ammo
	var needed: int = max_cap - reloading_w.current_ammo
	if infinite_reserve_ammo:
		reloading_w.current_ammo += needed
	else:
		var reload_amount: int = mini(needed, reloading_w.reserve_ammo)
		reloading_w.current_ammo += reload_amount
		reloading_w.reserve_ammo -= reload_amount
	
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
		else:
			return
	is_quick_knifing = true
	can_shoot = false
	set_aiming(false)
	
	var prev_ak_vis: bool = ak47_model.visible if ak47_model else false
	var prev_sg_vis: bool = shotgun_model.visible if shotgun_model else false
	var prev_pst_vis: bool = pistol_model.visible if pistol_model else false
	var prev_rpg_vis: bool = rpg_model.visible if rpg_model else false
	
	if ak47_model: ak47_model.visible = false
	if shotgun_model: shotgun_model.visible = false
	if pistol_model: pistol_model.visible = false
	if rpg_model: rpg_model.visible = false
	
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
	if ak47_model: ak47_model.visible = prev_ak_vis
	if shotgun_model: shotgun_model.visible = prev_sg_vis
	if pistol_model: pistol_model.visible = prev_pst_vis
	if rpg_model: rpg_model.visible = prev_rpg_vis
	
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
				if col.is_in_group("enemy"):
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
			w.reserve_ammo += amount
			emit_ammo_state()
			return

func add_reserve_ammo_by_id(wid: String, amount: int) -> void:
	var w := get_weapon_by_id(wid)
	if w:
		w.reserve_ammo += amount
		emit_ammo_state()
