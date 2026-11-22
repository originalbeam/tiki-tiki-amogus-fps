extends RigidBody3D

# Rebuilt Multi-Part 3D Brass & 12-Gauge Shell Casing Physics & Ejection Wisp

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _add_part_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, y_pos: float, mat: Material, segs: int = 10) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = Vector3(0, y_pos, 0)
	parent.add_child(mi)

func init(casing_type: int, eject_transform: Transform3D) -> void:
	global_transform = eject_transform
	if mesh_instance:
		mesh_instance.visible = false
		
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.70, 0.22)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.20
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.68, 0.70, 0.72) # Spent primer
	mat_steel.metallic = 0.92
	mat_steel.roughness = 0.24
	
	var mat_red_hull := StandardMaterial3D.new()
	mat_red_hull.albedo_color = Color(0.84, 0.11, 0.10) # Ribbed 12G plastic hull
	mat_red_hull.roughness = 0.36
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.03, 0.03, 0.035)
	mat_dark.roughness = 0.95
	
	var visual := Node3D.new()
	visual.name = "ShellVisual"
	add_child(visual)
	
	# casing_type: 1 = 7.62x39mm AK bottleneck brass, 2 = 12G high-brass red hull, 3 = 9x19mm brass
	match casing_type:
		1:
			_add_part_cyl(visual, 0.0062, 0.0068, 0.026, -0.004, mat_brass, 10) # Main tapered body
			_add_part_cyl(visual, 0.0046, 0.0062, 0.006, 0.012, mat_brass, 10)  # Bottleneck shoulder
			_add_part_cyl(visual, 0.0046, 0.0046, 0.006, 0.018, mat_brass, 10)  # Case neck
			_add_part_cyl(visual, 0.0038, 0.0038, 0.003, 0.020, mat_dark, 8)    # Hollow mouth
			_add_part_cyl(visual, 0.0070, 0.0070, 0.003, -0.018, mat_brass, 10) # Extractor rim
		2:
			_add_part_cyl(visual, 0.0115, 0.0115, 0.048, 0.008, mat_red_hull, 12) # Red plastic hull
			_add_part_cyl(visual, 0.0118, 0.0118, 0.018, -0.022, mat_brass, 12)   # High-brass head
			_add_part_cyl(visual, 0.0128, 0.0128, 0.003, -0.031, mat_brass, 12)   # Rim
			_add_part_cyl(visual, 0.0040, 0.0040, 0.002, -0.032, mat_steel, 8)    # Primer
			_add_part_cyl(visual, 0.0095, 0.0095, 0.004, 0.031, mat_dark, 10)     # Open fired crimp
		_:
			_add_part_cyl(visual, 0.0056, 0.0058, 0.020, 0.0, mat_brass, 10)
			_add_part_cyl(visual, 0.0062, 0.0062, 0.0025, -0.010, mat_brass, 10)
			_add_part_cyl(visual, 0.0046, 0.0046, 0.0025, 0.0095, mat_dark, 8)
			
	# Brief wispy hot-casing smoke trail puff
	var wisp := CPUParticles3D.new()
	wisp.one_shot = true
	wisp.amount = 6
	wisp.lifetime = 0.42
	wisp.local_coords = false
	wisp.gravity = Vector3(0, 0.8, 0)
	wisp.initial_velocity_min = 0.05
	wisp.initial_velocity_max = 0.25
	var gr := Gradient.new()
	gr.set_color(0, Color(0.85, 0.84, 0.82, 0.28))
	gr.set_color(gr.get_point_count() - 1, Color(0.7, 0.7, 0.7, 0.0))
	wisp.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(0.06, 0.06)
	qm.material = VFXFactoryScript.create_soft_smoke_material(Color(0.85, 0.84, 0.82, 0.45))
	wisp.mesh = qm
	add_child(wisp)
	wisp.emitting = true
	
	# Realistic ejection arc & energetic spin
	var eject_dir = (eject_transform.basis.x * randf_range(0.85, 1.25) +
					 eject_transform.basis.y * randf_range(0.65, 1.20) +
					 eject_transform.basis.z * randf_range(-0.25, 0.35)).normalized()
	apply_central_impulse(eject_dir * randf_range(3.0, 4.8))
	apply_torque_impulse(Vector3(
		randf_range(-18.0, 18.0),
		randf_range(-18.0, 18.0),
		randf_range(-18.0, 18.0)
	))

func _ready() -> void:
	await get_tree().create_timer(3.2).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.45)
	await tween.finished
	queue_free()
