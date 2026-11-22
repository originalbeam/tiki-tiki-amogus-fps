extends Node3D

# Rebuilt Multi-Layer Bullet Impact VFX (World Ricochet Sparks + Dust Cloud + Scorch Hole OR Blood Mist + Droplets)

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

@onready var particles: CPUParticles3D = $CPUParticles3D

func init(is_blood: bool) -> void:
	if particles:
		particles.emitting = false
		particles.visible = false
		
	if is_blood:
		_build_blood_impact()
	else:
		_build_surface_impact()
		
	get_tree().create_timer(4.5 if not is_blood else 1.2).timeout.connect(queue_free)

func _build_blood_impact() -> void:
	# 1. Soft crimson arterial blood-mist puff
	var mist := CPUParticles3D.new()
	mist.one_shot = true
	mist.explosiveness = 0.92
	mist.amount = 10
	mist.lifetime = 0.55
	mist.direction = Vector3(0, 0.2, -1.0) # Impact root looks along normal (-Z faces outward)
	mist.spread = 58.0
	mist.gravity = Vector3(0, -2.5, 0)
	mist.initial_velocity_min = 0.8
	mist.initial_velocity_max = 2.8
	mist.damping_min = 3.0
	mist.damping_max = 5.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.35))
	sc.add_point(Vector2(1.0, 1.45))
	mist.scale_amount_curve = sc
	var gr := Gradient.new()
	gr.set_color(0, Color(0.85, 0.04, 0.04, 0.85))
	gr.set_color(gr.get_point_count() - 1, Color(0.45, 0.02, 0.02, 0.0))
	mist.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(0.32, 0.32)
	qm.material = VFXFactoryScript.create_soft_smoke_material(Color(0.95, 0.08, 0.08, 0.9))
	mist.mesh = qm
	add_child(mist)
	mist.emitting = true
	
	# 2. High-velocity arterial droplet spray
	var drops := CPUParticles3D.new()
	drops.one_shot = true
	drops.explosiveness = 0.96
	drops.amount = 18
	drops.lifetime = 0.48
	drops.direction = Vector3(0, 0.25, -1.0)
	drops.spread = 48.0
	drops.gravity = Vector3(0, -14.0, 0)
	drops.initial_velocity_min = 3.2
	drops.initial_velocity_max = 7.5
	drops.particle_flag_align_y = true
	var dm := CylinderMesh.new()
	dm.top_radius = 0.012
	dm.bottom_radius = 0.004
	dm.height = 0.09
	dm.radial_segments = 5
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.88, 0.05, 0.05)
	dm.material = dmat
	drops.mesh = dm
	add_child(drops)
	drops.emitting = true

func _build_surface_impact() -> void:
	# 1. Brief blinding micro-spark flash + point light
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.82, 0.35)
	flash.light_energy = 2.4
	flash.omni_range = 3.2
	flash.position = Vector3(0, 0, -0.05)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.07)
	
	# 2. Fast glowing gravity-affected ricochet spark streaks
	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.98
	sparks.amount = 16
	sparks.lifetime = 0.42
	sparks.direction = Vector3(0, 0.15, -1.0)
	sparks.spread = 54.0
	sparks.gravity = Vector3(0, -15.0, 0)
	sparks.initial_velocity_min = 4.5
	sparks.initial_velocity_max = 11.5
	sparks.particle_flag_align_y = true
	var sg := Gradient.new()
	sg.set_color(0, Color(1.0, 0.98, 0.75, 1.0))
	sg.add_point(0.5, Color(1.0, 0.58, 0.14, 0.95))
	sg.set_color(sg.get_point_count() - 1, Color(0.8, 0.18, 0.02, 0.0))
	sparks.color_ramp = sg
	var sm := CylinderMesh.new()
	sm.top_radius = 0.008
	sm.bottom_radius = 0.002
	sm.height = 0.16
	sm.radial_segments = 5
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.vertex_color_use_as_albedo = true
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.material = smat
	sparks.mesh = sm
	add_child(sparks)
	sparks.emitting = true
	
	# 3. Soft expanding concrete/dust smoke puff cloud
	var dust := CPUParticles3D.new()
	dust.one_shot = true
	dust.explosiveness = 0.90
	dust.amount = 8
	dust.lifetime = 0.72
	dust.direction = Vector3(0, 0.25, -1.0)
	dust.spread = 65.0
	dust.gravity = Vector3(0, 0.45, 0)
	dust.initial_velocity_min = 0.6
	dust.initial_velocity_max = 2.2
	dust.damping_min = 2.8
	dust.damping_max = 4.5
	var dsc := Curve.new()
	dsc.add_point(Vector2(0.0, 0.3))
	dsc.add_point(Vector2(1.0, 1.5))
	dust.scale_amount_curve = dsc
	var dgr := Gradient.new()
	dgr.set_color(0, Color(0.76, 0.74, 0.70, 0.58))
	dgr.set_color(dgr.get_point_count() - 1, Color(0.55, 0.54, 0.52, 0.0))
	dust.color_ramp = dgr
	var dq := QuadMesh.new()
	dq.size = Vector2(0.36, 0.36)
	dq.material = VFXFactoryScript.create_soft_smoke_material(Color(0.84, 0.82, 0.78, 0.72))
	dust.mesh = dq
	add_child(dust)
	dust.emitting = true
	
	# 4. Crisp scorched bullet-hole impact mark flat against the hit surface
	var hole := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.14, 0.14)
	hole.mesh = hq
	var hmat := ShaderMaterial.new()
	hmat.shader = VFXFactoryScript.get_scorch_shader()
	hmat.set_shader_parameter("opacity", 0.88)
	hole.material_override = hmat
	hole.position = Vector3(0, 0, -0.015)
	hole.rotation.z = randf_range(0.0, TAU)
	add_child(hole)
	var ftw := create_tween()
	ftw.tween_interval(3.0)
	ftw.tween_method(func(v: float):
		if is_instance_valid(hmat):
			hmat.set_shader_parameter("opacity", v)
	, 0.88, 0.0, 1.2)
