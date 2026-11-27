class_name RPGRocket
extends Node3D

const RPGModel = preload("res://scripts/weapons/models/rpg_model.gd")
const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

var velocity: Vector3 = Vector3.ZERO
var speed: float = 46.0
var gravity: float = 0.55
var max_damage: float = 900.0
var blast_radius: float = 16.5
var self_damage_radius: float = 12.75
var ammo_mode: String = "standard" # "standard" (PG-7V), "tandem" (PG-7VR), "thermobaric" (TBG-7V)
var distance_traveled: float = 0.0
var max_lifetime: float = 10.0
var elapsed_time: float = 0.0

var shooter: Node = null
var weapon_manager: Node = null
var exclude_rids: Array[RID] = []
var has_detonated: bool = false

var warhead_visual: Node3D = null
var flame_mesh: MeshInstance3D = null
var flame_light: OmniLight3D = null
var smoke_trail: CPUParticles3D = null
var flight_sfx: AudioStreamPlayer3D = null

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	if warhead_visual:
		return
		
	warhead_visual = RPGModel.create_warhead_by_type(ammo_mode, true)
	warhead_visual.scale = Vector3(1.15, 1.15, 1.15)
	add_child(warhead_visual)
	
	# Rocket motor exhaust flame cone at rear (+Z) with white-hot Mach diamond core
	flame_mesh = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.052
	cone.bottom_radius = 0.002
	cone.height = 0.44
	cone.radial_segments = 10
	flame_mesh.mesh = cone
	flame_mesh.rotation.x = deg_to_rad(-90.0)
	flame_mesh.position = Vector3(0, 0, 1.24)
	var f_mat := StandardMaterial3D.new()
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.albedo_color = Color(1.0, 0.56, 0.14, 0.92)
	f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame_mesh.material_override = f_mat
	add_child(flame_mesh)
	
	var inner_core := MeshInstance3D.new()
	var ic_m := CylinderMesh.new()
	ic_m.top_radius = 0.025
	ic_m.bottom_radius = 0.002
	ic_m.height = 0.26
	ic_m.radial_segments = 8
	inner_core.mesh = ic_m
	inner_core.position = Vector3(0, 0.06, 0)
	var ic_mat := StandardMaterial3D.new()
	ic_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ic_mat.albedo_color = Color(1.0, 0.97, 0.80, 0.98)
	ic_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ic_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	inner_core.material_override = ic_mat
	flame_mesh.add_child(inner_core)
	
	# Warm dynamic glow light
	flame_light = OmniLight3D.new()
	flame_light.light_color = Color(1.0, 0.62, 0.18)
	flame_light.light_energy = 4.2
	flame_light.omni_range = 8.5
	flame_light.position = Vector3(0, 0, 1.08)
	add_child(flame_light)
	
	# Continuous soft billowing volumetric smoke ribbon trail!
	smoke_trail = CPUParticles3D.new()
	smoke_trail.emitting = false
	smoke_trail.local_coords = false
	smoke_trail.amount = 56
	smoke_trail.lifetime = 1.05
	smoke_trail.direction = Vector3(0, 0.15, 1)
	smoke_trail.spread = 18.0
	smoke_trail.gravity = Vector3(0, 0.7, 0)
	smoke_trail.initial_velocity_min = 0.8
	smoke_trail.initial_velocity_max = 2.4
	smoke_trail.angle_min = 0.0
	smoke_trail.angle_max = 360.0
	smoke_trail.angular_velocity_min = -40.0
	smoke_trail.angular_velocity_max = 40.0
	smoke_trail.position = Vector3(0, 0, 1.08)
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.45))
	sc.add_point(Vector2(0.5, 1.35))
	sc.add_point(Vector2(1.0, 2.35))
	smoke_trail.scale_amount_curve = sc
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.72, 0.38, 0.72))
	gr.add_point(0.15, Color(0.84, 0.82, 0.78, 0.56))
	gr.set_color(gr.get_point_count() - 1, Color(0.60, 0.60, 0.62, 0.0))
	smoke_trail.color_ramp = gr
	var sm_q := QuadMesh.new()
	sm_q.size = Vector2(0.42, 0.42)
	sm_q.material = VFXFactoryScript.create_soft_smoke_material(Color(0.92, 0.90, 0.88, 0.78))
	smoke_trail.mesh = sm_q
	add_child(smoke_trail)
	
	# Rocket motor whoosh audio
	flight_sfx = AudioStreamPlayer3D.new()
	flight_sfx.bus = "Weapons"
	flight_sfx.stream = SoundEffects.create_rpg_flight_sound()
	flight_sfx.volume_db = -3.0
	flight_sfx.max_distance = 40.0
	flight_sfx.unit_size = 6.0
	add_child(flight_sfx)

func init(start_pos: Vector3, launch_dir: Vector3, shooter_node: Node, weapon_mgr: Node, dmg: float = 900.0, radius: float = 16.5, mode: String = "standard") -> void:
	ammo_mode = mode
	if warhead_visual:
		warhead_visual.queue_free()
		warhead_visual = null
		var new_wh := RPGModel.create_warhead_by_type(ammo_mode, true)
		new_wh.scale = Vector3(1.15, 1.15, 1.15)
		add_child(new_wh)
		warhead_visual = new_wh
	else:
		_build_visuals()
	
	global_position = start_pos
	var dir := launch_dir.normalized()
	velocity = dir * speed
	shooter = shooter_node
	weapon_manager = weapon_mgr
	max_damage = dmg
	blast_radius = radius
	self_damage_radius = 16.5 if ammo_mode == "thermobaric" else (8.5 if ammo_mode == "tandem" else 12.75)
	
	exclude_rids.clear()
	if shooter is CollisionObject3D:
		exclude_rids.append((shooter as CollisionObject3D).get_rid())
	
	_orient_along_direction(dir)
	
	if smoke_trail:
		smoke_trail.restart()
		smoke_trail.emitting = true
	if flight_sfx:
		flight_sfx.play()

func _orient_along_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var up_vec := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	look_at(global_position + dir, up_vec)

func _physics_process(delta: float) -> void:
	if has_detonated:
		return
		
	elapsed_time += delta
	if elapsed_time >= max_lifetime:
		detonate(global_position, Vector3.UP)
		return
		
	# Apply gentle ballistic drop
	velocity.y -= gravity * delta
	var step: Vector3 = velocity * delta
	var next_pos: Vector3 = global_position + step
	
	# Spin stabilizer warhead & flicker exhaust flame
	if warhead_visual:
		warhead_visual.rotation.z += delta * 14.0
	if flame_mesh:
		var flk := randf_range(0.85, 1.30)
		flame_mesh.scale = Vector3(1.0, flk, 1.0)
	if flame_light:
		flame_light.light_energy = randf_range(2.8, 4.4)
		
	# Continuous collision raycast along travel step
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, next_pos)
	query.exclude = exclude_rids
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var col: Object = result.collider
		# Ignore player capsule and pickup items — RPG-7 always detonates immediately at any distance!
		if col != shooter and not (col and col.is_in_group("player")):
			detonate(result.position, result.normal, col)
			return
			
	# Proximity direct-hit check against regular enemies, Shahed drones & airborne Mi-24 (skip ground vehicles so exact hitboxes resolve!)
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node3D) or e.is_in_group("tiger_boss") or e.is_in_group("black_minivan"):
			continue
		var enemy_pos: Vector3 = (e as Node3D).global_position
		if e.is_in_group("mi24_boss"):
			var closest_h := Geometry3D.get_closest_point_to_segment(enemy_pos, global_position, next_pos)
			if closest_h.distance_to(enemy_pos) <= 3.1:
				detonate(closest_h, -velocity.normalized(), e)
				return
			continue
		var center_a := enemy_pos + Vector3(0, 0.85, 0)
		var closest_a := Geometry3D.get_closest_point_to_segment(center_a, global_position, next_pos)
		var closest_b := Geometry3D.get_closest_point_to_segment(enemy_pos, global_position, next_pos)
		if closest_a.distance_to(center_a) <= 0.55 or closest_b.distance_to(enemy_pos) <= 0.55:
			detonate(closest_a, -velocity.normalized(), e)
			return
			
	distance_traveled += global_position.distance_to(next_pos)
	global_position = next_pos
	_orient_along_direction(velocity.normalized())

func detonate(hit_pos: Vector3, hit_normal: Vector3, direct_collider: Object = null) -> void:
	if has_detonated:
		return
	has_detonated = true
	set_physics_process(false)
	
	global_position = hit_pos
	
	# Hide flying rocket & stop engine sound, keep smoke trail fading gracefully
	if warhead_visual:
		warhead_visual.visible = false
	if flame_mesh:
		flame_mesh.visible = false
	if flame_light:
		flame_light.visible = false
	if smoke_trail:
		smoke_trail.emitting = false
	if flight_sfx:
		flight_sfx.stop()
		
	# 1. AoE Splash Damage to all regular enemies & Shahed drones, plus specialized armor/side rules for Tiger I boss!
	var hit_any_enemy: bool = false
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node3D):
			continue
		if e.is_in_group("tiger_boss") and e.has_method("on_rpg_hit"):
			if e.on_rpg_hit(hit_pos, hit_normal, direct_collider, max_damage, blast_radius, ammo_mode):
				hit_any_enemy = true
			continue
		if e.is_in_group("mi24_boss") and e.has_method("on_rpg_hit"):
			if e.on_rpg_hit(hit_pos, hit_normal, direct_collider, max_damage, blast_radius, ammo_mode):
				hit_any_enemy = true
			continue
		if e.is_in_group("black_minivan") and e.has_method("on_rpg_hit"):
			if e.on_rpg_hit(hit_pos, hit_normal, direct_collider):
				hit_any_enemy = true
			continue
		var e_pos: Vector3 = (e as Node3D).global_position
		var dist_base := hit_pos.distance_to(e_pos)
		var dist_center := hit_pos.distance_to(e_pos + Vector3(0, 0.85, 0))
		var dist := minf(dist_base, dist_center)
		if dist <= blast_radius:
			var falloff: float = 1.0
			if dist > 5.25:
				falloff = lerpf(1.0, 0.30, clampf((dist - 5.25) / maxf(0.01, blast_radius - 5.25), 0.0, 1.0))
			var final_dmg: float = max_damage * falloff
			if e.has_method("take_damage"):
				e.take_damage(final_dmg, false)
				hit_any_enemy = true
				
	if hit_any_enemy and is_instance_valid(weapon_manager):
		weapon_manager.hit_enemy.emit()
		if weapon_manager.hit_sound_player:
			weapon_manager.hit_sound_player.stream = SoundEffects.create_hit_sound()
			weapon_manager.hit_sound_player.pitch_scale = randf_range(0.95, 1.1)
			weapon_manager.hit_sound_player.play()
			
	# 2. Self-damage (close range) & Explosion Camera Shake for player
	var player_node: Node = shooter
	if not is_instance_valid(player_node):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
	if is_instance_valid(player_node) and player_node is Node3D:
		var p_center := (player_node as Node3D).global_position + Vector3(0, 0.9, 0)
		var p_dist := hit_pos.distance_to(p_center)
		if p_dist <= self_damage_radius and player_node.has_method("take_damage"):
			var self_dmg := lerpf(135.0, 20.0, clampf(p_dist / self_damage_radius, 0.0, 1.0))
			player_node.take_damage(self_dmg)
		if p_dist <= 48.0 and player_node.has_method("add_camera_shake"):
			var shake_strength := clampf(1.0 - (p_dist / 48.0), 0.12, 1.0) * 0.34
			player_node.add_camera_shake(shake_strength)
			
	# 3. Loud 3D Boom Explosion Audio (deep earth-shaking vacuum bass for Thermobaric, sharp crack for Tandem!)
	var exp_sfx := AudioStreamPlayer3D.new()
	exp_sfx.bus = "Weapons"
	exp_sfx.position = hit_pos
	exp_sfx.stream = SoundEffects.create_rpg_explosion_sound()
	if ammo_mode == "thermobaric":
		exp_sfx.volume_db = 7.5
		exp_sfx.max_distance = 160.0
		exp_sfx.unit_size = 32.0
		exp_sfx.pitch_scale = randf_range(0.58, 0.66)
	elif ammo_mode == "tandem":
		exp_sfx.volume_db = 3.5
		exp_sfx.max_distance = 110.0
		exp_sfx.unit_size = 20.0
		exp_sfx.pitch_scale = randf_range(1.18, 1.28)
	else:
		exp_sfx.volume_db = 4.0
		exp_sfx.max_distance = 110.0
		exp_sfx.unit_size = 20.0
		exp_sfx.pitch_scale = randf_range(0.92, 1.06)
	get_tree().root.add_child(exp_sfx)
	exp_sfx.play()
	exp_sfx.finished.connect(exp_sfx.queue_free)
	
	# 4. Multi-layered Explosion Visual Effects tailored to warhead type!
	_spawn_explosion_vfx(hit_pos, hit_normal)
	
	# Allow remaining rocket smoke trail to finish fading before freeing self
	get_tree().create_timer(1.1).timeout.connect(queue_free)

func _spawn_explosion_vfx(pos: Vector3, normal: Vector3) -> void:
	if ammo_mode == "thermobaric":
		VFXFactoryScript.spawn_thermobaric_explosion(get_tree().root, pos, normal)
	elif ammo_mode == "tandem":
		VFXFactoryScript.spawn_tandem_explosion(get_tree().root, pos, normal)
	else:
		VFXFactoryScript.spawn_explosion(get_tree().root, pos, normal, 1.75)
