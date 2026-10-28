extends Node3D

signal weapon_changed(weapon: Weapon)
signal ammo_updated(current: int, reserve: int, is_reloading: bool, has_chamber: bool, shotgun_4_plus_1: bool)
signal hit_enemy()

@export var camera: Camera3D
@export var bullet_tracer_scene: PackedScene = preload("res://scenes/bullet_tracer.tscn")
@export var bullet_impact_scene: PackedScene = preload("res://scenes/bullet_impact.tscn")
@export var shell_casing_scene: PackedScene = preload("res://scenes/shell_casing.tscn")

var weapons: Array[Weapon] = []
var current_weapon_idx: int = 0
var current_weapon: Weapon

var can_shoot: bool = true
var is_reloading: bool = false
var is_switching: bool = false
var shoot_timer: float = 0.0

# Shotgun reload state
var shotgun_cancel_reload: bool = false
var shotgun_started_empty: bool = false
var shotgun_is_4_plus_1: bool = false

# AK Sparks counter
var ak_shot_counter: int = 0

@onready var ak47_model: Node3D = $AK47
@onready var shotgun_model: Node3D = $Shotgun
@onready var pistol_model: Node3D = $Pistol

@onready var ak_charging_handle: MeshInstance3D = $AK47/ChargingHandle
@onready var ak_magazine: MeshInstance3D = $AK47/Magazine

@onready var shotgun_pump: MeshInstance3D = $Shotgun/Pump
@onready var shotgun_bolt: MeshInstance3D = $Shotgun/Bolt
@onready var shotgun_shell: Node3D = $Shotgun/LoadingShell

@onready var pistol_slide: MeshInstance3D = $Pistol/Slide
@onready var pistol_magazine: MeshInstance3D = $Pistol/Magazine

@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var flash_light: OmniLight3D = $MuzzleFlash/OmniLight3D

@onready var muzzle_smoke: CPUParticles3D = $MuzzleSmoke
@onready var ak_sparks: CPUParticles3D = $AK_Sparks

@onready var shoot_sound_player: AudioStreamPlayer = $ShootSound
@onready var reload_sound_player: AudioStreamPlayer = $ReloadSound
@onready var hit_sound_player: AudioStreamPlayer = $HitSound

# Procedural Animation Transforms
var initial_pos: Vector3
var target_pos: Vector3

var recoil_pos: Vector3 = Vector3.ZERO
var recoil_rot: Vector3 = Vector3.ZERO

var sway_pos: Vector3 = Vector3.ZERO
var sway_rot: Vector3 = Vector3.ZERO

var bob_pos: Vector3 = Vector3.ZERO
var bob_rot: Vector3 = Vector3.ZERO

var idle_timer: float = 0.0
var walk_bob_timer: float = 0.0

var switch_offset_y: float = 0.0
var pump_offset_z: float = 0.0
var initial_pump_z: float = -0.28

var ak_handle_offset_z: float = 0.0
var pistol_slide_offset_z: float = 0.0
var dry_fire_cooldown: float = 0.0

var ak_mag_initial_pos: Vector3 = Vector3(0, -0.12, -0.06)
var pistol_mag_initial_pos: Vector3 = Vector3(0, -0.08, 0.05)

# Knife system
var is_quick_knifing: bool = false
var knife_model: Node3D = null
var knife_idle_pos: Vector3 = Vector3(0.08, -0.16, -0.32)
var knife_idle_rot: Vector3 = Vector3(-8.0, 15.0, -12.0)

func _ready() -> void:
	initial_pos = position
	target_pos = initial_pos
	muzzle_flash.visible = false
	
	if shotgun_pump:
		initial_pump_z = shotgun_pump.position.z
	if shotgun_shell:
		shotgun_shell.visible = false
	if ak_magazine:
		ak_mag_initial_pos = ak_magazine.position
	if pistol_magazine:
		pistol_mag_initial_pos = pistol_magazine.position
	
	# Setup Knife 3D model
	knife_model = get_node_or_null("Knife")
	if not knife_model:
		knife_model = build_knife_model()
		add_child(knife_model)
	knife_model.visible = false
	
	# Initialize weapons
	weapons.append(Weapon.create_ak47())
	weapons.append(Weapon.create_shotgun())
	weapons.append(Weapon.create_pistol())
	
	switch_weapon(0, false)

func emit_ammo_state() -> void:
	if current_weapon:
		ammo_updated.emit(
			current_weapon.current_ammo,
			current_weapon.reserve_ammo,
			is_reloading,
			current_weapon.has_round_in_chamber,
			shotgun_is_4_plus_1
		)

func get_current_weapon() -> Weapon:
	return current_weapon

func _process(delta: float) -> void:
	if shoot_timer > 0.0:
		shoot_timer -= delta
		if shoot_timer <= 0.0 and not is_reloading and not is_switching and not is_quick_knifing:
			can_shoot = true
			
	# Idle breathing sway
	idle_timer += delta * 2.2
	var idle_x: float = sin(idle_timer) * 0.002
	var idle_y: float = cos(idle_timer * 2.0) * 0.002
	var idle_rot_z: float = sin(idle_timer) * 0.003
	
	if dry_fire_cooldown > 0.0:
		dry_fire_cooldown -= delta
		
	# Spring recovery for mouse sway
	sway_pos = sway_pos.lerp(Vector3.ZERO, delta * 7.0)
	sway_rot = sway_rot.lerp(Vector3.ZERO, delta * 7.0)
	
	# Spring recovery for recoil
	recoil_pos = recoil_pos.lerp(Vector3.ZERO, delta * 14.0)
	recoil_rot = recoil_rot.lerp(Vector3.ZERO, delta * 14.0)
	
	# Movement bob decay
	bob_pos = bob_pos.lerp(Vector3.ZERO, delta * 6.0)
	bob_rot = bob_rot.lerp(Vector3.ZERO, delta * 6.0)
	
	# Combine procedural animation layers
	position = initial_pos + Vector3(idle_x, idle_y, 0) + sway_pos + recoil_pos + bob_pos + Vector3(0, switch_offset_y, 0)
	rotation = sway_rot + recoil_rot + bob_rot + Vector3(0, 0, idle_rot_z)
	
	# Update mechanical sub-mesh animations
	if shotgun_pump and shotgun_model.visible:
		shotgun_pump.position.z = initial_pump_z + pump_offset_z
		if shotgun_bolt:
			shotgun_bolt.position.z = -0.04 + pump_offset_z * 0.9
	if ak_charging_handle and ak47_model.visible:
		ak_charging_handle.position.z = -0.04 + ak_handle_offset_z
	if pistol_slide and pistol_model.visible:
		pistol_slide.position.z = pistol_slide_offset_z

func apply_mouse_sway(mouse_relative: Vector2) -> void:
	if is_switching:
		return
	var sway_amount_rot: float = 0.0016
	var sway_amount_pos: float = 0.0006
	
	sway_rot.y = clampf(sway_rot.y - mouse_relative.x * sway_amount_rot, -0.12, 0.12)
	sway_rot.x = clampf(sway_rot.x - mouse_relative.y * sway_amount_rot, -0.10, 0.10)
	sway_rot.z = clampf(sway_rot.z + mouse_relative.x * sway_amount_rot * 0.7, -0.08, 0.08)
	
	sway_pos.x = clampf(sway_pos.x - mouse_relative.x * sway_amount_pos, -0.035, 0.035)
	sway_pos.y = clampf(sway_pos.y + mouse_relative.y * sway_amount_pos, -0.03, 0.03)

func apply_movement_bob(horiz_speed: float, is_sprinting: bool, delta: float) -> void:
	if horiz_speed > 0.5:
		var speed_mult: float = 1.4 if is_sprinting else 1.0
		walk_bob_timer += delta * (11.0 * speed_mult)
		var amp: float = 0.016 if is_sprinting else 0.010
		
		bob_pos.x = sin(walk_bob_timer * 0.5) * amp * 1.5
		bob_pos.y = absf(sin(walk_bob_timer)) * amp
		bob_rot.z = -sin(walk_bob_timer * 0.5) * 0.04
		bob_rot.x = sin(walk_bob_timer) * 0.02
	else:
		walk_bob_timer = 0.0

func switch_weapon(idx: int, animate: bool = true) -> void:
	if is_switching or is_quick_knifing:
		return
	if idx < 0 or idx >= weapons.size() or (idx == current_weapon_idx and current_weapon != null):
		return
	if is_reloading:
		is_reloading = false
		shotgun_cancel_reload = true
		
	if animate:
		is_switching = true
		can_shoot = false
		
		var tween_down: Tween = create_tween()
		tween_down.tween_property(self, "switch_offset_y", -0.35, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween_down.finished
		
		set_active_model_visible(idx)
		
		var tween_up: Tween = create_tween()
		tween_up.tween_property(self, "switch_offset_y", 0.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween_up.finished
		
		is_switching = false
		can_shoot = true
	else:
		set_active_model_visible(idx)

func set_active_model_visible(idx: int) -> void:
	current_weapon_idx = idx
	current_weapon = weapons[current_weapon_idx]
	
	ak47_model.visible = (current_weapon.slot == 1)
	shotgun_model.visible = (current_weapon.slot == 2)
	pistol_model.visible = (current_weapon.slot == 3)
	if knife_model:
		knife_model.visible = false
	
	shoot_timer = 0.08
	can_shoot = true
	
	weapon_changed.emit(current_weapon)
	emit_ammo_state()

func switch_next() -> void:
	if is_quick_knifing:
		return
	var next_idx: int = (current_weapon_idx + 1) % weapons.size()
	switch_weapon(next_idx)

func switch_prev() -> void:
	if is_quick_knifing:
		return
	var prev_idx: int = (current_weapon_idx - 1 + weapons.size()) % weapons.size()
	switch_weapon(prev_idx)

func switch_slot(slot: int) -> void:
	if is_quick_knifing:
		return
	for i in range(weapons.size()):
		if weapons[i].slot == slot:
			switch_weapon(i)
			return

func try_shoot(just_pressed: bool) -> void:
	if not current_weapon or is_switching or is_quick_knifing:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	# Logic 1: If shotgun is reloading, fire button cancels reload immediately WITHOUT shooting!
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
	var dry_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	dry_sfx.stream = SoundEffects.create_dry_fire_sound()
	dry_sfx.pitch_scale = randf_range(0.98, 1.02)
	add_child(dry_sfx)
	dry_sfx.play()
	dry_sfx.finished.connect(dry_sfx.queue_free)

func execute_shoot() -> void:
	can_shoot = false
	shoot_timer = current_weapon.fire_rate
	current_weapon.current_ammo -= 1
	if current_weapon.is_shotgun:
		shotgun_is_4_plus_1 = false
	
	if current_weapon.current_ammo <= 0:
		current_weapon.has_round_in_chamber = false
	
	emit_ammo_state()
	
	# Recoil kick on weapon model
	var kick_z: float = 0.08 if current_weapon.slot == 2 else (0.05 if current_weapon.slot == 1 else 0.035)
	var pitch_up: float = current_weapon.recoil_pitch
	var yaw_rnd: float = randf_range(-current_weapon.recoil_yaw, current_weapon.recoil_yaw)
	var roll_rnd: float = randf_range(-0.02, 0.02)
	
	recoil_pos = Vector3(yaw_rnd * 0.5, randf_range(0.01, 0.025), kick_z)
	recoil_rot = Vector3(pitch_up, yaw_rnd, roll_rnd)
	
	# Animated bolt cycling for AK-47 on every shot
	if current_weapon.slot == 1:
		animate_ak_bolt_cycle()
	# Animated slide cycling for Pistol on every shot
	elif current_weapon.slot == 3:
		animate_pistol_slide_cycle()
	
	# Camera recoil
	var player_node: Node = owner
	if player_node and player_node.has_method("add_camera_recoil"):
		player_node.add_camera_recoil(pitch_up * 0.35, yaw_rnd * 0.25)
	
	# Muzzle flash
	show_muzzle_flash()
	
	# Muzzle smoke effect
	trigger_muzzle_smoke()
	
	# AK-47 sparks: bright bursts that streak across the screen in an instant
	if current_weapon.slot == 1:
		ak_shot_counter += 1
		if ak_shot_counter % 3 == 0 or ak_shot_counter % 4 == 0:
			trigger_ak_sparks()
	
	# Play gunshot sound
	play_shoot_sound()
	
	# Eject shell casing
	if current_weapon.slot == 1:
		eject_casing(1, ak47_model.get_node_or_null("EjectMarker"))
	elif current_weapon.slot == 3:
		eject_casing(3, pistol_model.get_node_or_null("EjectMarker"))
	elif current_weapon.slot == 2:
		animate_shotgun_pump_with_ejection()
		
	# Raycast pellets
	var muzzle_pos: Vector3 = get_active_muzzle_pos()
	for i in range(current_weapon.pellets):
		fire_pellet(muzzle_pos)
		
	if current_weapon.current_ammo <= 0:
		start_reload()

func animate_ak_bolt_cycle() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "ak_handle_offset_z", 0.05, 0.03)
	tween.tween_property(self, "ak_handle_offset_z", 0.0, 0.04)

func animate_pistol_slide_cycle() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "pistol_slide_offset_z", 0.04, 0.025)
	tween.tween_property(self, "pistol_slide_offset_z", 0.0, 0.035)

func trigger_muzzle_smoke() -> void:
	if not muzzle_smoke:
		return
	muzzle_smoke.global_position = get_active_muzzle_pos()
	match current_weapon.slot:
		1:
			muzzle_smoke.amount = 10
			muzzle_smoke.lifetime = 0.55
			muzzle_smoke.initial_velocity_max = 2.5
		2:
			muzzle_smoke.amount = 22
			muzzle_smoke.lifetime = 0.85
			muzzle_smoke.initial_velocity_max = 4.2
		3:
			muzzle_smoke.amount = 5
			muzzle_smoke.lifetime = 0.35
			muzzle_smoke.initial_velocity_max = 1.5
	muzzle_smoke.restart()
	muzzle_smoke.emitting = true

func trigger_ak_sparks() -> void:
	if not ak_sparks:
		return
	ak_sparks.global_position = get_active_muzzle_pos()
	ak_sparks.restart()
	ak_sparks.emitting = true

func eject_casing(casing_type: int, marker: Marker3D) -> void:
	if not shell_casing_scene:
		return
	var casing: RigidBody3D = shell_casing_scene.instantiate()
	get_tree().root.add_child(casing)
	var xform: Transform3D = marker.global_transform if marker else global_transform
	casing.init(casing_type, xform)

func animate_shotgun_pump_with_ejection() -> void:
	await get_tree().create_timer(0.22).timeout
	if not is_instance_valid(shotgun_pump) or not shotgun_model.visible:
		return
		
	# Slide pump back
	var tween_back: Tween = create_tween()
	tween_back.tween_property(self, "pump_offset_z", 0.10, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween_back.finished
	
	# Eject spent 12G red shell casing on full backward pump!
	eject_casing(2, shotgun_model.get_node_or_null("EjectMarker"))
	
	# Play pump sound
	var pump_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	pump_sfx.stream = SoundEffects.create_pump_sound()
	add_child(pump_sfx)
	pump_sfx.play()
	pump_sfx.finished.connect(pump_sfx.queue_free)
	
	# Slide pump forward
	var tween_fwd: Tween = create_tween()
	tween_fwd.tween_property(self, "pump_offset_z", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func play_shoot_sound() -> void:
	match current_weapon.slot:
		1:
			shoot_sound_player.stream = SoundEffects.create_ak47_sound()
			shoot_sound_player.pitch_scale = randf_range(0.96, 1.04)
			shoot_sound_player.volume_db = 1.0
		2:
			shoot_sound_player.stream = SoundEffects.create_shotgun_sound()
			shoot_sound_player.pitch_scale = randf_range(0.97, 1.03)
			shoot_sound_player.volume_db = 2.0
		3:
			shoot_sound_player.stream = SoundEffects.create_pistol_sound()
			shoot_sound_player.pitch_scale = randf_range(0.98, 1.03)
			shoot_sound_player.volume_db = 0.5
	shoot_sound_player.play()

func show_muzzle_flash() -> void:
	muzzle_flash.visible = true
	flash_light.light_energy = 2.8
	muzzle_flash.rotation.z = randf_range(0, TAU)
	await get_tree().create_timer(0.04).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false

func get_active_muzzle_pos() -> Vector3:
	var muzzle_node: Marker3D = null
	if current_weapon.slot == 1:
		muzzle_node = ak47_model.get_node_or_null("Muzzle")
	elif current_weapon.slot == 2:
		muzzle_node = shotgun_model.get_node_or_null("Muzzle")
	elif current_weapon.slot == 3:
		muzzle_node = pistol_model.get_node_or_null("Muzzle")
		
	if muzzle_node:
		return muzzle_node.global_position
	return global_position

func fire_pellet(from_pos: Vector3) -> void:
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var viewport: Viewport = get_viewport()
	var center: Vector2 = viewport.get_visible_rect().size / 2.0
	
	var spread_offset: Vector2 = Vector2(
		randf_range(-current_weapon.spread, current_weapon.spread),
		randf_range(-current_weapon.spread, current_weapon.spread)
	) * 400.0
	var screen_pos: Vector2 = center + spread_offset
	
	var ray_origin: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)
	var ray_end: Vector3 = ray_origin + ray_dir * 120.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var player_body: CollisionObject3D = owner as CollisionObject3D
	if not player_body:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_body = players[0] as CollisionObject3D
	if player_body:
		query.exclude = [player_body.get_rid()]
	
	var result: Dictionary = space_state.intersect_ray(query)
	var hit_pos: Vector3 = ray_end
	var hit_something: bool = false
	var hit_an_enemy: bool = false
	
	if result:
		hit_pos = result.position
		hit_something = true
		var collider: Object = result.collider
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
			
			var is_sg: bool = (current_weapon.slot == 2)
			collider.take_damage(final_damage, is_sg)
			hit_enemy.emit()
			
			if hit_sound_player:
				hit_sound_player.stream = SoundEffects.create_hit_sound()
				hit_sound_player.pitch_scale = randf_range(1.15, 1.3)
				hit_sound_player.play()
	
	# Spawn 3D beam tracer
	spawn_tracer(from_pos, hit_pos)
	
	if hit_something:
		spawn_impact(hit_pos, result.normal, hit_an_enemy)

func spawn_tracer(from: Vector3, to: Vector3) -> void:
	if not bullet_tracer_scene:
		return
	var tracer: Node3D = bullet_tracer_scene.instantiate()
	get_tree().root.add_child(tracer)
	tracer.init(from, to)

func spawn_impact(pos: Vector3, normal: Vector3, is_blood: bool) -> void:
	if not bullet_impact_scene:
		return
	var impact: Node3D = bullet_impact_scene.instantiate()
	get_tree().root.add_child(impact)
	impact.global_position = pos
	if normal.length_squared() > 0.001:
		var n_dir: Vector3 = normal.normalized()
		if absf(n_dir.dot(Vector3.UP)) > 0.99:
			impact.look_at(pos + normal, Vector3.RIGHT)
		else:
			impact.look_at(pos + normal, Vector3.UP)
	impact.init(is_blood)

# --- RELOAD LOGIC ---

func start_reload() -> void:
	if is_reloading or is_quick_knifing or not current_weapon or current_weapon.slot == 4:
		return
	var max_cap: int = current_weapon.get_max_reload_capacity()
	if current_weapon.current_ammo >= max_cap:
		return
	if current_weapon.reserve_ammo <= 0:
		return
		
	is_reloading = true
	emit_ammo_state()
	
	if current_weapon.is_shotgun:
		reload_shotgun_sequential()
	else:
		reload_magazine_weapon()

# 1) Shotgun sequential shell reload: 1 shell per second with shell loading animation, cancelable anytime by fire button
func reload_shotgun_sequential() -> void:
	shotgun_cancel_reload = false
	shotgun_started_empty = not current_weapon.has_round_in_chamber or (current_weapon.current_ammo == 0)
	
	# Initial tilt up into loading position
	var tween_start: Tween = create_tween()
	tween_start.tween_property(self, "recoil_pos:y", -0.06, 0.25)
	tween_start.parallel().tween_property(self, "recoil_rot:x", deg_to_rad(-18.0), 0.25)
	tween_start.parallel().tween_property(self, "recoil_rot:z", deg_to_rad(15.0), 0.25)
	await tween_start.finished
	
	# If started empty: load basic 5 shells. If already chambered: load up to 6 shells (5 in tube + 1 chambered).
	var max_cap: int = 5 if shotgun_started_empty else 6
	while is_reloading and current_weapon.is_shotgun:
		if shotgun_cancel_reload:
			break
		if current_weapon.current_ammo >= max_cap or current_weapon.reserve_ammo <= 0:
			break
			
		# Animate visible shell entering loading gate
		if shotgun_shell:
			shotgun_shell.position = Vector3(0, -0.16, -0.14)
			shotgun_shell.visible = true
			var shell_tween: Tween = create_tween()
			shell_tween.tween_property(shotgun_shell, "position:y", -0.03, 0.35)
			await shell_tween.finished
			shotgun_shell.visible = false
			
		var elapsed: float = 0.35
		while elapsed < 0.85:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			if shotgun_cancel_reload or not is_reloading:
				break
				
		if shotgun_cancel_reload or not is_reloading:
			break
			
		# Insert 1 shell
		current_weapon.current_ammo += 1
		current_weapon.reserve_ammo -= 1
		emit_ammo_state()
		
		# Play shell insert sound
		var insert_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
		insert_sfx.stream = SoundEffects.create_shell_insert_sound()
		add_child(insert_sfx)
		insert_sfx.play()
		insert_sfx.finished.connect(insert_sfx.queue_free)
		
		# Jolt
		var jolt: Tween = create_tween()
		jolt.tween_property(self, "recoil_pos:y", -0.04, 0.08)
		jolt.tween_property(self, "recoil_pos:y", -0.06, 0.12)
		
	if shotgun_shell:
		shotgun_shell.visible = false
		
	# If shotgun started completely empty and at least 1 shell was loaded, rack pump once to chamber!
	if shotgun_started_empty and current_weapon.current_ammo > 0:
		var pump_tween: Tween = create_tween()
		pump_tween.tween_property(self, "pump_offset_z", 0.10, 0.12)
		await pump_tween.finished
		
		var pump_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
		pump_sfx.stream = SoundEffects.create_pump_sound()
		add_child(pump_sfx)
		pump_sfx.play()
		pump_sfx.finished.connect(pump_sfx.queue_free)
		
		var pump_fwd: Tween = create_tween()
		pump_fwd.tween_property(self, "pump_offset_z", 0.0, 0.12)
		await pump_fwd.finished
		current_weapon.has_round_in_chamber = true
		
		# User requirement: If loaded empty up to 5 shells, after pump rack it should show 4+1!
		if current_weapon.current_ammo == 5:
			shotgun_is_4_plus_1 = true
	elif current_weapon.current_ammo > 0:
		current_weapon.has_round_in_chamber = true
		if current_weapon.current_ammo >= 6:
			shotgun_is_4_plus_1 = false
		
	# Return gun to ready position
	var tween_end: Tween = create_tween()
	tween_end.tween_property(self, "recoil_pos:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_end.parallel().tween_property(self, "recoil_rot:x", 0.0, 0.25)
	tween_end.parallel().tween_property(self, "recoil_rot:z", 0.0, 0.25)
	await tween_end.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

# 2) Magazine reload (AK-47 & Pistol) with animated magazine detach & insert, Chamber (+1) and Bolt/Slide Rack
func reload_magazine_weapon() -> void:
	var is_tactical: bool = current_weapon.has_round_in_chamber and (current_weapon.current_ammo > 0)
	var max_cap: int = current_weapon.mag_size + (1 if is_tactical else 0)
	
	var tween: Tween = create_tween()
	var dip_time: float = 0.3
	
	# Dip down and tilt side
	tween.tween_property(self, "recoil_pos:y", -0.16, dip_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "recoil_rot:z", deg_to_rad(22.0), dip_time)
	tween.parallel().tween_property(self, "recoil_rot:x", deg_to_rad(-10.0), dip_time)
	
	# Animate magazine detach (drops out of weapon)
	if current_weapon.slot == 1 and ak_magazine:
		# Play magazine detach metallic click
		play_sfx(SoundEffects.create_magazine_out_sound())
		var mag_drop: Tween = create_tween()
		mag_drop.tween_property(ak_magazine, "position:y", ak_mag_initial_pos.y - 0.25, 0.25)
		mag_drop.parallel().tween_property(ak_magazine, "rotation:x", deg_to_rad(45.0), 0.25)
		await mag_drop.finished
		
		# New magazine rises from bottom and clicks into magwell
		ak_magazine.position = Vector3(ak_mag_initial_pos.x, ak_mag_initial_pos.y - 0.3, ak_mag_initial_pos.z)
		ak_magazine.rotation.x = deg_to_rad(22.0)
		var mag_insert: Tween = create_tween()
		mag_insert.tween_property(ak_magazine, "position:y", ak_mag_initial_pos.y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await mag_insert.finished
		# Play magazine insert metallic click
		play_sfx(SoundEffects.create_magazine_in_sound())
		
	elif current_weapon.slot == 3 and pistol_magazine:
		# Play magazine detach metallic click
		play_sfx(SoundEffects.create_magazine_out_sound())
		var mag_drop: Tween = create_tween()
		mag_drop.tween_property(pistol_magazine, "position:y", pistol_mag_initial_pos.y - 0.22, 0.22)
		await mag_drop.finished
		
		# New magazine slides into grip
		pistol_magazine.position.y = pistol_mag_initial_pos.y - 0.25
		pistol_magazine.rotation.x = deg_to_rad(-15.0)
		var mag_insert: Tween = create_tween()
		mag_insert.tween_property(pistol_magazine, "position:y", pistol_mag_initial_pos.y, 0.25)
		await mag_insert.finished
		# Play magazine insert metallic click
		play_sfx(SoundEffects.create_magazine_in_sound())
	else:
		await tween.finished
		
	if not is_reloading:
		return
		
	# If empty reload: perform bolt rack / slide release animation!
	if not is_tactical:
		if current_weapon.slot == 1 and ak_charging_handle:
			var bolt_tween: Tween = create_tween()
			bolt_tween.tween_property(self, "ak_handle_offset_z", 0.08, 0.12).set_trans(Tween.TRANS_QUAD)
			await bolt_tween.finished
			
			# Realistic AK bolt pull & trunnion lock sound
			play_sfx(SoundEffects.create_bolt_pull_ak_sound())
			
			var bolt_snap: Tween = create_tween()
			bolt_snap.tween_property(self, "ak_handle_offset_z", 0.0, 0.08).set_trans(Tween.TRANS_BOUNCE)
			await bolt_snap.finished
			
		elif current_weapon.slot == 3 and pistol_slide:
			var slide_tween: Tween = create_tween()
			slide_tween.tween_property(self, "pistol_slide_offset_z", 0.05, 0.10)
			await slide_tween.finished
			
			# Realistic Pistol slide pull & release snap sound
			play_sfx(SoundEffects.create_slide_pull_pistol_sound())
			
			var slide_snap: Tween = create_tween()
			slide_snap.tween_property(self, "pistol_slide_offset_z", 0.0, 0.08)
			await slide_snap.finished
			
		current_weapon.has_round_in_chamber = true
		
	# Calculate and apply reloaded ammo
	var needed: int = max_cap - current_weapon.current_ammo
	var reload_amount: int = mini(needed, current_weapon.reserve_ammo)
	current_weapon.current_ammo += reload_amount
	current_weapon.reserve_ammo -= reload_amount
	
	# Return to ready
	var tween_up: Tween = create_tween()
	tween_up.tween_property(self, "recoil_pos:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_up.parallel().tween_property(self, "recoil_rot:z", 0.0, 0.25)
	tween_up.parallel().tween_property(self, "recoil_rot:x", 0.0, 0.25)
	await tween_up.finished
	
	is_reloading = false
	can_shoot = true
	emit_ammo_state()

func play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx.stream = stream
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

# --- KNIFE & MELEE SYSTEM ---

func reset_knife_idle_transform() -> void:
	if knife_model:
		knife_model.position = knife_idle_pos
		knife_model.rotation_degrees = knife_idle_rot

func quick_knife_attack() -> void:
	if is_quick_knifing or is_switching:
		return
	if is_reloading:
		if current_weapon and current_weapon.is_shotgun:
			shotgun_cancel_reload = true
		else:
			return
	is_quick_knifing = true
	can_shoot = false
	
	var prev_ak_vis: bool = ak47_model.visible
	var prev_sg_vis: bool = shotgun_model.visible
	var prev_pst_vis: bool = pistol_model.visible
	
	ak47_model.visible = false
	shotgun_model.visible = false
	pistol_model.visible = false
	
	var player_node: Node = owner
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
	
	if knife_model:
		knife_model.visible = true
		# Start position on right side of screen (purely horizontal sweeping stroke across screen)
		knife_model.position = Vector3(0.28, 0.02, 0.08)
		# Knife orientation: looking away from player under a small angle to the right
		# (tip pointing forward along -Z, angled slightly rightwards around Y by -18°, with natural slight upward pitch and roll)
		knife_model.rotation_degrees = Vector3(-6.0, -18.0, -10.0)
		
		# Swift cutting whoosh sound
		play_sfx(SoundEffects.create_knife_slash_sound())
		
		# Animate sweeping cutting slice purely horizontally across the screen (Y and Z stay constant)
		# Move from right (+0.28) across to left (-0.62), covering ~60% of horizontal screen view
		# Rotation remains steady throughout the slash (no clockwise twisting or bending)
		var slash_tween: Tween = create_tween()
		slash_tween.tween_property(knife_model, "position", Vector3(-0.62, 0.02, 0.08), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Mid-strike hit detection at peak of the slice
		await get_tree().create_timer(0.08).timeout
		perform_knife_hit_detection()
		
		await slash_tween.finished
	else:
		perform_knife_hit_detection()
		await get_tree().create_timer(0.18).timeout
		
	if knife_model:
		knife_model.visible = false
	ak47_model.visible = prev_ak_vis
	shotgun_model.visible = prev_sg_vis
	pistol_model.visible = prev_pst_vis
	
	if hud_node and hud_node.has_method("set_knife_active_ui"):
		hud_node.set_knife_active_ui(false)
		
	is_quick_knifing = false
	if not is_reloading and not is_switching:
		can_shoot = true

func perform_knife_hit_detection() -> void:
	if not camera:
		return
	var space_state = get_world_3d().direct_space_state
	var cam_pos = camera.global_position
	var forward = -camera.global_transform.basis.z.normalized()
	
	# 1) Direct Ray query 2.8m in front
	var ray_end = cam_pos + forward * 2.8
	var query = PhysicsRayQueryParameters3D.create(cam_pos, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	
	var hit_enemy_target: Node = null
	var hit_pos: Vector3 = ray_end
	var hit_norm: Vector3 = -forward
	
	if not result.is_empty():
		var col = result.collider
		hit_pos = result.position
		hit_norm = result.normal
		if col.is_in_group("enemy"):
			hit_enemy_target = col
		elif col.get_parent() and col.get_parent().is_in_group("enemy"):
			hit_enemy_target = col.get_parent()
			
	# 2) Cone check for nearby enemies within 2.6m
	if not hit_enemy_target:
		var enemies = get_tree().get_nodes_in_group("enemy")
		var closest_dist: float = 999.0
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var to_enemy = enemy.global_position - cam_pos
			to_enemy.y -= 0.5
			var dist = to_enemy.length()
			if dist <= 2.6:
				var dot = forward.dot(to_enemy.normalized())
				if dot > 0.65 and dist < closest_dist:
					closest_dist = dist
					hit_enemy_target = enemy
					hit_pos = enemy.global_position + Vector3(0, 0.8, 0)
					
	if hit_enemy_target:
		if hit_enemy_target.has_method("take_damage"):
			hit_enemy_target.take_damage(70.0)
		play_sfx(SoundEffects.create_knife_hit_sound())
		hit_enemy.emit()
		spawn_impact(hit_pos, hit_norm, true)

func add_reserve_ammo(slot: int, amount: int) -> void:
	for w in weapons:
		if w.slot == slot:
			w.reserve_ammo += amount
			emit_ammo_state()
			return

func build_knife_model() -> Node3D:
	var root := Node3D.new()
	root.name = "Knife"
	root.position = knife_idle_pos
	root.rotation_degrees = knife_idle_rot
	
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.85, 0.88, 0.92)
	steel_mat.metallic = 0.98
	steel_mat.roughness = 0.18
	
	var dark_steel := StandardMaterial3D.new()
	dark_steel.albedo_color = Color(0.18, 0.20, 0.22)
	dark_steel.metallic = 0.9
	dark_steel.roughness = 0.35
	
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.18, 0.22, 0.17)
	grip_mat.roughness = 0.7
	grip_mat.metallic = 0.05
	
	# Main blade
	var blade_inst := MeshInstance3D.new()
	blade_inst.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.008, 0.038, 0.22)
	blade_mesh.material = steel_mat
	blade_inst.mesh = blade_mesh
	blade_inst.position = Vector3(0, 0.005, -0.12)
	root.add_child(blade_inst)
	
	# Lower cutting edge
	var edge_inst := MeshInstance3D.new()
	edge_inst.name = "Edge"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.004, 0.012, 0.22)
	edge_mesh.material = steel_mat
	edge_inst.mesh = edge_mesh
	edge_inst.position = Vector3(0, -0.018, -0.12)
	root.add_child(edge_inst)
	
	# Clip point tip
	var tip_inst := MeshInstance3D.new()
	tip_inst.name = "Tip"
	var tip_mesh := PrismMesh.new()
	tip_mesh.size = Vector3(0.007, 0.036, 0.05)
	tip_mesh.material = steel_mat
	tip_inst.mesh = tip_mesh
	tip_inst.position = Vector3(0, -0.002, -0.245)
	tip_inst.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(tip_inst)
	
	# Fuller / blood groove
	var fuller_inst := MeshInstance3D.new()
	fuller_inst.name = "Fuller"
	var fuller_mesh := BoxMesh.new()
	fuller_mesh.size = Vector3(0.010, 0.010, 0.14)
	fuller_mesh.material = dark_steel
	fuller_inst.mesh = fuller_mesh
	fuller_inst.position = Vector3(0, 0.008, -0.11)
	root.add_child(fuller_inst)
	
	# Crossguard with barrel ring
	var guard_inst := MeshInstance3D.new()
	guard_inst.name = "Crossguard"
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.018, 0.075, 0.016)
	guard_mesh.material = dark_steel
	guard_inst.mesh = guard_mesh
	guard_inst.position = Vector3(0, 0, -0.008)
	root.add_child(guard_inst)
	
	var ring_inst := MeshInstance3D.new()
	ring_inst.name = "BarrelRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.010
	ring_mesh.outer_radius = 0.017
	ring_mesh.material = dark_steel
	ring_inst.mesh = ring_mesh
	ring_inst.position = Vector3(0, 0.045, -0.008)
	ring_inst.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(ring_inst)
	
	# Handle grip
	var handle_inst := MeshInstance3D.new()
	handle_inst.name = "Grip"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.028, 0.038, 0.13)
	handle_mesh.material = grip_mat
	handle_inst.mesh = handle_mesh
	handle_inst.position = Vector3(0, 0, 0.065)
	root.add_child(handle_inst)
	
	# Grip ribs
	for i in range(4):
		var rib := MeshInstance3D.new()
		var rib_mesh := BoxMesh.new()
		rib_mesh.size = Vector3(0.030, 0.040, 0.010)
		rib_mesh.material = dark_steel
		rib.mesh = rib_mesh
		rib.position = Vector3(0, 0, 0.035 + i * 0.024)
		root.add_child(rib)
		
	# Butt pommel
	var pommel_inst := MeshInstance3D.new()
	pommel_inst.name = "Pommel"
	var pommel_mesh := BoxMesh.new()
	pommel_mesh.size = Vector3(0.032, 0.042, 0.022)
	pommel_mesh.material = dark_steel
	pommel_inst.mesh = pommel_mesh
	pommel_inst.position = Vector3(0, 0, 0.14)
	root.add_child(pommel_inst)
	
	return root

