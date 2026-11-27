class_name UGLGrenade
extends Node3D

# 40mm Underbarrel Grenade Launcher Projectile (VOG-25 / M406)
# Ballistic arc flight with continuous raycast impact, smoke ribbon trail,
# AoE blast damage (enemies, Busik, Tiger I) & volumetric explosion VFX!

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

var velocity: Vector3 = Vector3.ZERO
var speed: float = 34.0
var gravity: float = 13.5
var max_damage: float = 480.0
var blast_radius: float = 8.5
var self_damage_radius: float = 5.5
var min_arming_distance: float = 14.0 # Realistic 40mm spin-armed fuze minimum arming distance (meters)
var distance_traveled: float = 0.0
var max_lifetime: float = 8.0
var elapsed_time: float = 0.0

var shooter: Node = null
var weapon_manager: Node = null
var exclude_rids: Array[RID] = []
var has_detonated: bool = false
var bounce_count: int = 0
var post_bounce_fuse_active: bool = false
var post_bounce_fuse_timer: float = 0.0
var post_bounce_fuse_duration: float = 2.2 # Detonates via timer even if slowed down before 14m
var tumble_spin: Vector3 = Vector3.ZERO
var last_bounce_sfx_time: float = -1.0

var grenade_visual: Node3D = null
var smoke_trail: CPUParticles3D = null

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	if grenade_visual:
		return
	grenade_visual = Node3D.new()
	add_child(grenade_visual)

	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.22, 0.25, 0.20)
	mat_body.metallic = 0.72
	mat_body.roughness = 0.36

	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.86, 0.70, 0.22)
	mat_gold.metallic = 0.88
	mat_gold.roughness = 0.24

	# 40mm cylindrical warhead + gold ogive nose fuze
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.022
	cm.height = 0.072
	cm.radial_segments = 12
	body.mesh = cm
	body.material_override = mat_body
	body.rotation_degrees = Vector3(-90.0, 0, 0)
	grenade_visual.add_child(body)

	var nose := MeshInstance3D.new()
	var nm := SphereMesh.new()
	nm.radius = 0.022
	nm.height = 0.048
	nm.radial_segments = 12
	nose.mesh = nm
	nose.material_override = mat_gold
	nose.position = Vector3(0, 0, -0.038)
	grenade_visual.add_child(nose)

	# Smoke ribbon trail
	smoke_trail = CPUParticles3D.new()
	smoke_trail.emitting = false
	smoke_trail.local_coords = false
	smoke_trail.amount = 34
	smoke_trail.lifetime = 0.65
	smoke_trail.direction = Vector3(0, 0.1, 1)
	smoke_trail.spread = 14.0
	smoke_trail.gravity = Vector3(0, 0.5, 0)
	smoke_trail.initial_velocity_min = 0.5
	smoke_trail.initial_velocity_max = 1.4
	smoke_trail.position = Vector3(0, 0, 0.04)
	var sm_q := QuadMesh.new()
	sm_q.size = Vector2(0.22, 0.22)
	sm_q.material = VFXFactoryScript.create_soft_smoke_material(Color(0.88, 0.88, 0.86, 0.65))
	smoke_trail.mesh = sm_q
	add_child(smoke_trail)

func init(spawn_pos: Vector3, launch_dir: Vector3, shooter_node: Node, wm_node: Node, dmg: float = 480.0, radius: float = 8.5) -> void:
	_build_visuals()
	global_position = spawn_pos
	shooter = shooter_node
	weapon_manager = wm_node
	max_damage = dmg
	blast_radius = radius
	var dir_n: Vector3 = launch_dir.normalized()
	# Slight natural upward lob so aiming at mid-range targets hits smoothly!
	velocity = (dir_n + Vector3(0, 0.08, 0)).normalized() * speed
	if shooter is CollisionObject3D:
		exclude_rids.append((shooter as CollisionObject3D).get_rid())
	for shop in get_tree().get_nodes_in_group("shop_building"):
		if shop is CollisionObject3D:
			exclude_rids.append((shop as CollisionObject3D).get_rid())
	_orient_along(velocity.normalized())
	if smoke_trail:
		smoke_trail.emitting = true

func _orient_along(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var up_v := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	look_at(global_position + dir, up_v)

func _physics_process(delta: float) -> void:
	if has_detonated:
		return
	elapsed_time += delta
	if post_bounce_fuse_active:
		post_bounce_fuse_timer += delta
		if post_bounce_fuse_timer >= post_bounce_fuse_duration:
			detonate(global_position, Vector3.UP)
			return
	if elapsed_time >= max_lifetime:
		detonate(global_position, Vector3.UP)
		return

	velocity.y -= gravity * delta
	var step: Vector3 = velocity * delta
	var next_pos: Vector3 = global_position + step
	if grenade_visual:
		if bounce_count > 0:
			grenade_visual.rotation += tumble_spin * delta
		else:
			grenade_visual.rotation.z += delta * 18.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, next_pos)
	query.exclude = exclude_rids
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var col: Object = result.collider
		if col != shooter and not (col and col.is_in_group("player")):
			var seg_dist: float = global_position.distance_to(result.position)
			var total_dist: float = distance_traveled + seg_dist
			if total_dist < min_arming_distance:
				distance_traveled = total_dist
				_ricochet_bounce(result.position, result.normal, col)
			else:
				detonate(result.position, result.normal, col)
			return

	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node3D) or e.is_in_group("tiger_boss") or e.is_in_group("black_minivan"):
			continue
		var ep: Vector3 = (e as Node3D).global_position
		var ca := ep + Vector3(0, 0.85, 0)
		var closest := Geometry3D.get_closest_point_to_segment(ca, global_position, next_pos)
		if closest.distance_to(ca) <= 0.50:
			var seg_e: float = global_position.distance_to(closest)
			var total_dist_e: float = distance_traveled + seg_e
			if total_dist_e < min_arming_distance:
				distance_traveled = total_dist_e
				_ricochet_bounce(ca, -velocity.normalized(), e)
			else:
				detonate(ca, -velocity.normalized(), e)
			return

	distance_traveled += global_position.distance_to(next_pos)
	global_position = next_pos
	if bounce_count == 0:
		_orient_along(velocity.normalized())
	elif distance_traveled >= min_arming_distance:
		# Reached arming distance while skipping/bouncing -> detonate!
		detonate(global_position, Vector3.UP)

# Close-range impact (< 14m arming distance): ricochets/skips off ground & walls until reaching 14m or fuse timer expires!
func _ricochet_bounce(hit_pos: Vector3, hit_normal: Vector3, direct_collider: Object = null) -> void:
	if has_detonated:
		return
	var n: Vector3 = hit_normal.normalized() if hit_normal.length_squared() > 0.001 else Vector3.UP
	global_position = hit_pos + n * 0.065
	bounce_count += 1
	post_bounce_fuse_active = true

	# Direct blunt kinetic damage if grenade physically struck an enemy or vehicle hitbox
	var hit_enemy_flag: bool = false
	if is_instance_valid(direct_collider):
		if direct_collider.is_in_group("enemy") and direct_collider.has_method("take_damage"):
			direct_collider.take_damage(85.0, false)
			hit_enemy_flag = true
		elif direct_collider.is_in_group("black_van_hitbox"):
			var v_own = direct_collider.get_meta("van_owner") if direct_collider.has_meta("van_owner") else null
			var zone_v: String = str(direct_collider.get_meta("hit_zone")) if direct_collider.has_meta("hit_zone") else "front"
			if is_instance_valid(v_own) and v_own.has_method("on_bullet_hit"):
				v_own.on_bullet_hit(zone_v, 55.0, hit_pos, hit_normal)
				hit_enemy_flag = true
		elif direct_collider.is_in_group("tiger_hitbox"):
			var t_own = direct_collider.get_meta("tiger_owner") if direct_collider.has_meta("tiger_owner") else null
			var zone_t: String = str(direct_collider.get_meta("hit_zone")) if direct_collider.has_meta("hit_zone") else ""
			if is_instance_valid(t_own) and t_own.has_method("on_bullet_hit"):
				if t_own.on_bullet_hit(zone_t, 45.0, hit_pos, hit_normal):
					hit_enemy_flag = true

	if hit_enemy_flag and is_instance_valid(weapon_manager):
		weapon_manager.hit_enemy.emit()
		if weapon_manager.hit_sound_player:
			weapon_manager.hit_sound_player.stream = SoundEffects.create_hit_sound()
			weapon_manager.hit_sound_player.pitch_scale = 0.85
			weapon_manager.hit_sound_player.play()

	if is_instance_valid(weapon_manager) and weapon_manager.has_method("spawn_impact"):
		weapon_manager.spawn_impact(hit_pos, n, hit_enemy_flag)

	# Crisp metallic ricochet bounce clink (throttled so sliding on ground doesn't spam audio)
	if elapsed_time - last_bounce_sfx_time >= 0.08:
		last_bounce_sfx_time = elapsed_time
		var clank := AudioStreamPlayer3D.new()
		clank.bus = "SFX"
		clank.position = hit_pos
		clank.stream = SoundEffects.create_magazine_out_sound()
		clank.pitch_scale = randf_range(1.22, 1.48)
		clank.volume_db = 0.5
		clank.max_distance = 35.0
		get_tree().root.add_child(clank)
		clank.play()
		clank.finished.connect(clank.queue_free)

	# Energetic elastic ricochet bounce preserving forward skip velocity!
	var prev_speed: float = velocity.length()
	var bounced: Vector3 = velocity.bounce(n) * 0.66
	if n.y > 0.45 and prev_speed > 3.5:
		bounced.y = maxf(bounced.y, clampf(prev_speed * 0.28, 2.4, 7.5))
	elif bounced.length() < 1.8 and prev_speed > 2.0:
		bounced = n * 2.2
	velocity = bounced
	tumble_spin = Vector3(randf_range(9.0, 16.0), randf_range(-10.0, 10.0), randf_range(10.0, 18.0))

func detonate(hit_pos: Vector3, hit_normal: Vector3, direct_collider: Object = null) -> void:
	if has_detonated:
		return
	has_detonated = true
	set_physics_process(false)
	global_position = hit_pos
	if grenade_visual:
		grenade_visual.visible = false
	if smoke_trail:
		smoke_trail.emitting = false

	var hit_any: bool = false
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not (e is Node3D):
			continue
		if e.is_in_group("tiger_boss") and e.has_method("on_rpg_hit"):
			if e.on_rpg_hit(hit_pos, hit_normal, direct_collider, max_damage * 0.55, blast_radius):
				hit_any = true
			continue
		if e.is_in_group("mi24_boss") and e.has_method("on_rpg_hit"):
			if e.on_rpg_hit(hit_pos, hit_normal, direct_collider, max_damage * 0.65, blast_radius, "standard"):
				hit_any = true
			continue
		if e.is_in_group("black_minivan") and e.has_method("on_bullet_hit"):
			var dist_v: float = hit_pos.distance_to((e as Node3D).global_position)
			if dist_v <= blast_radius:
				e.on_bullet_hit("front", max_damage * 0.65, hit_pos, hit_normal)
				hit_any = true
			continue
		var ep: Vector3 = (e as Node3D).global_position
		var dist := minf(hit_pos.distance_to(ep), hit_pos.distance_to(ep + Vector3(0, 0.85, 0)))
		if dist <= blast_radius:
			var falloff := 1.0 if dist <= 2.8 else lerpf(1.0, 0.28, clampf((dist - 2.8) / maxf(0.1, blast_radius - 2.8), 0.0, 1.0))
			if e.has_method("take_damage"):
				e.take_damage(max_damage * falloff, false)
				hit_any = true

	if hit_any and is_instance_valid(weapon_manager):
		weapon_manager.hit_enemy.emit()
		if weapon_manager.hit_sound_player:
			weapon_manager.hit_sound_player.stream = SoundEffects.create_hit_sound()
			weapon_manager.hit_sound_player.pitch_scale = randf_range(0.95, 1.1)
			weapon_manager.hit_sound_player.play()

	# Mild close-range self-damage + camera shake
	var p_node: Node = shooter
	if is_instance_valid(p_node) and p_node is Node3D:
		var pdist := hit_pos.distance_to((p_node as Node3D).global_position + Vector3(0, 0.9, 0))
		if pdist <= self_damage_radius and p_node.has_method("take_damage"):
			var self_dmg := lerpf(32.0, 6.0, pdist / self_damage_radius)
			p_node.take_damage(self_dmg)
		if pdist <= 22.0 and p_node.has_method("add_camera_shake"):
			p_node.add_camera_shake(lerpf(0.18, 0.03, pdist / 22.0))

	# Compact fiery explosion VFX & audio!
	var exp_root := Node3D.new()
	exp_root.position = hit_pos
	get_tree().root.add_child(exp_root)
	var sfx := AudioStreamPlayer3D.new()
	sfx.bus = "SFX"
	sfx.stream = SoundEffects.create_rpg_explosion_sound()
	sfx.pitch_scale = randf_range(1.18, 1.32)
	sfx.volume_db = 2.0
	sfx.max_distance = 75.0
	exp_root.add_child(sfx)
	sfx.play()

	# Bright expanding fireball sphere + dynamic flash light + smoke burst
	var fb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.65
	sm.height = 1.3
	fb.mesh = sm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(1.0, 0.62, 0.15, 0.95)
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fb.material_override = fmat
	exp_root.add_child(fb)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.22)
	light.light_energy = 10.0
	light.omni_range = 14.0
	exp_root.add_child(light)

	var tw := exp_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fb, "scale", Vector3(3.6, 3.6, 3.6), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(fmat, "albedo_color:a", 0.0, 0.30)
	tw.tween_property(light, "light_energy", 0.0, 0.28)

	var smoke := CPUParticles3D.new()
	smoke.one_shot = true
	smoke.explosiveness = 0.92
	smoke.amount = 28
	smoke.lifetime = 0.95
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 85.0
	smoke.initial_velocity_min = 3.0
	smoke.initial_velocity_max = 8.5
	smoke.gravity = Vector3(0, 1.5, 0)
	var sq := QuadMesh.new()
	sq.size = Vector2(0.85, 0.85)
	sq.material = VFXFactoryScript.create_soft_smoke_material(Color(0.22, 0.21, 0.20, 0.82))
	smoke.mesh = sq
	exp_root.add_child(smoke)
	smoke.emitting = true

	var cleanup_tw := exp_root.create_tween()
	cleanup_tw.tween_interval(2.2)
	cleanup_tw.tween_callback(exp_root.queue_free)

	var self_tw := create_tween()
	self_tw.tween_interval(0.8)
	self_tw.tween_callback(queue_free)
