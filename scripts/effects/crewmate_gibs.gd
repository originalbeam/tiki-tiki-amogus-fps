extends Node3D

# Rebuilt Crewmate Death Burst VFX (Arterial Mist + Visor Glass Shards + Flying Gibs)

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

@onready var blood_particles: CPUParticles3D = $BloodParticles

func init(crewmate_color: Color) -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = crewmate_color
	body_mat.roughness = 0.38
	
	for child in get_children():
		if child is RigidBody3D:
			for sub in child.get_children():
				if sub is MeshInstance3D and sub.name != "Bone" and sub.name != "Visor":
					sub.material_override = body_mat
			var random_dir := Vector3(
				randf_range(-1.0, 1.0),
				randf_range(0.9, 1.9),
				randf_range(-1.0, 1.0)
			).normalized()
			child.apply_central_impulse(random_dir * randf_range(6.5, 13.0))
			child.apply_torque_impulse(Vector3(
				randf_range(-10.0, 10.0),
				randf_range(-10.0, 10.0),
				randf_range(-10.0, 10.0)
			))
			
	# Volumetric crimson mist cloud on death
	var mist := CPUParticles3D.new()
	mist.one_shot = true
	mist.explosiveness = 0.90
	mist.amount = 16
	mist.lifetime = 0.95
	mist.position = Vector3(0, 0.9, 0)
	mist.direction = Vector3(0, 1, 0)
	mist.spread = 110.0
	mist.gravity = Vector3(0, -1.8, 0)
	mist.initial_velocity_min = 1.5
	mist.initial_velocity_max = 4.2
	mist.damping_min = 2.5
	mist.damping_max = 4.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.45))
	sc.add_point(Vector2(1.0, 1.95))
	mist.scale_amount_curve = sc
	var gr := Gradient.new()
	gr.set_color(0, Color(0.88, 0.05, 0.05, 0.82))
	gr.set_color(gr.get_point_count() - 1, Color(0.42, 0.02, 0.02, 0.0))
	mist.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(0.65, 0.65)
	qm.material = VFXFactoryScript.create_soft_smoke_material(Color(0.95, 0.08, 0.08, 0.85))
	mist.mesh = qm
	add_child(mist)
	mist.emitting = true
	
	# Sparkling cyan shattered visor glass shards
	var shards := CPUParticles3D.new()
	shards.one_shot = true
	shards.explosiveness = 0.96
	shards.amount = 14
	shards.lifetime = 0.85
	shards.position = Vector3(0, 1.15, 0)
	shards.direction = Vector3(0, 0.6, 0)
	shards.spread = 120.0
	shards.gravity = Vector3(0, -15.0, 0)
	shards.initial_velocity_min = 3.5
	shards.initial_velocity_max = 8.5
	var sm := BoxMesh.new()
	sm.size = Vector3(0.06, 0.04, 0.015)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.45, 0.88, 1.0)
	smat.metallic = 0.7
	smat.roughness = 0.08
	sm.material = smat
	shards.mesh = sm
	add_child(shards)
	shards.emitting = true

func _ready() -> void:
	if blood_particles:
		blood_particles.emitting = true
	await get_tree().create_timer(4.5).timeout
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	queue_free()
