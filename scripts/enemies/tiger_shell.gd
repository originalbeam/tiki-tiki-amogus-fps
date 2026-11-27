class_name TigerShell
extends Node3D

# High-velocity 88mm KwK 36 Armor-Piercing High-Explosive (APHE) tank shell fired by Tiger I

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

var velocity: Vector3 = Vector3.ZERO
var speed: float = 52.0
var gravity: float = 1.6
var max_damage: float = 55.0
var blast_radius: float = 5.5
var max_lifetime: float = 6.0
var elapsed_time: float = 0.0
var has_detonated: bool = false
var exclude_rids: Array[RID] = []

var shell_mesh: MeshInstance3D = null
var trail_particles: CPUParticles3D = null

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	if shell_mesh:
		return
	shell_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.065
	cm.height = 0.55
	cm.radial_segments = 8
	shell_mesh.mesh = cm
	shell_mesh.rotation.x = deg_to_rad(-90.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.78, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.62, 0.14)
	mat.emission_energy_multiplier = 4.0
	shell_mesh.material_override = mat
	add_child(shell_mesh)

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.68, 0.22)
	glow.light_energy = 3.5
	glow.omni_range = 7.0
	add_child(glow)

	trail_particles = CPUParticles3D.new()
	trail_particles.local_coords = false
	trail_particles.amount = 28
	trail_particles.lifetime = 0.45
	trail_particles.direction = Vector3(0, 0.1, 1)
	trail_particles.spread = 12.0
	trail_particles.gravity = Vector3(0, 0.4, 0)
	trail_particles.initial_velocity_min = 0.5
	trail_particles.initial_velocity_max = 1.6
	trail_particles.scale_amount_min = 0.22
	trail_particles.scale_amount_max = 0.55
	var sm_q := QuadMesh.new()
	sm_q.size = Vector2(0.45, 0.45)
	sm_q.material = VFXFactoryScript.create_soft_smoke_material(Color(0.86, 0.84, 0.80, 0.65))
	trail_particles.mesh = sm_q
	add_child(trail_particles)

func init(start_pos: Vector3, launch_dir: Vector3, owner_rids: Array[RID]) -> void:
	_build_visuals()
	global_position = start_pos
	velocity = launch_dir.normalized() * speed
	exclude_rids = owner_rids.duplicate()
	_orient(launch_dir.normalized())

func _orient(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var up_v := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	look_at(global_position + dir, up_v)

func _physics_process(delta: float) -> void:
	if has_detonated:
		return
	elapsed_time += delta
	if elapsed_time >= max_lifetime:
		detonate(global_position, Vector3.UP)
		return

	velocity.y -= gravity * delta
	var next_pos: Vector3 = global_position + velocity * delta

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position, next_pos)
	q.exclude = exclude_rids
	q.collide_with_bodies = true
	q.collide_with_areas = false
	var res := space.intersect_ray(q)
	if not res.is_empty():
		detonate(res.position, res.normal)
		return

	global_position = next_pos
	_orient(velocity.normalized())

func detonate(hit_pos: Vector3, hit_normal: Vector3) -> void:
	if has_detonated:
		return
	has_detonated = true
	set_physics_process(false)
	global_position = hit_pos
	if shell_mesh:
		shell_mesh.visible = false
	if trail_particles:
		trail_particles.emitting = false

	# Damage player within blast radius & apply heavy camera shake
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node3D:
			var p_center: Vector3 = (p as Node3D).global_position + Vector3(0, 0.9, 0)
			var dist: float = hit_pos.distance_to(p_center)
			if dist <= blast_radius and p.has_method("take_damage"):
				var falloff: float = lerpf(1.0, 0.25, clampf(dist / blast_radius, 0.0, 1.0))
				p.take_damage(max_damage * falloff)
			if dist <= 28.0 and p.has_method("add_camera_shake"):
				var shake: float = clampf(1.0 - dist / 28.0, 0.08, 1.0) * 0.28
				p.add_camera_shake(shake)

	var exp_sfx := AudioStreamPlayer3D.new()
	exp_sfx.bus = "Weapons"
	exp_sfx.position = hit_pos
	exp_sfx.stream = SoundEffects.create_tiger_explosion_sound()
	exp_sfx.volume_db = 1.5
	exp_sfx.max_distance = 100.0
	exp_sfx.unit_size = 18.0
	exp_sfx.pitch_scale = randf_range(1.10, 1.24)
	get_tree().root.add_child(exp_sfx)
	exp_sfx.play()
	exp_sfx.finished.connect(exp_sfx.queue_free)

	VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, hit_normal, 1.05)
	get_tree().create_timer(0.8).timeout.connect(queue_free)
