extends RigidBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func init(casing_type: int, eject_transform: Transform3D) -> void:
	global_transform = eject_transform
	
	# casing_type: 1 = 7.62mm AK brass, 2 = 12G Shotgun red plastic, 3 = 9mm Pistol brass
	var mat = StandardMaterial3D.new()
	var mesh = CylinderMesh.new()
	mesh.radial_segments = 6
	
	match casing_type:
		1: # AK-47 7.62x39mm brass casing
			mat.albedo_color = Color(0.85, 0.68, 0.22)
			mat.metallic = 0.9
			mat.roughness = 0.25
			mesh.top_radius = 0.009
			mesh.bottom_radius = 0.009
			mesh.height = 0.038
		2: # 12 Gauge Shotgun Shell (Red hull with brass base)
			mat.albedo_color = Color(0.85, 0.12, 0.12)
			mat.metallic = 0.3
			mat.roughness = 0.4
			mesh.top_radius = 0.014
			mesh.bottom_radius = 0.014
			mesh.height = 0.065
		3: # 9mm Pistol brass casing
			mat.albedo_color = Color(0.9, 0.75, 0.25)
			mat.metallic = 0.9
			mat.roughness = 0.25
			mesh.top_radius = 0.007
			mesh.bottom_radius = 0.007
			mesh.height = 0.022
			
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	
	# Eject physics impulse: right and slightly up/back
	var eject_dir = (eject_transform.basis.x * randf_range(0.8, 1.2) + 
					 eject_transform.basis.y * randf_range(0.7, 1.3) + 
					 eject_transform.basis.z * randf_range(-0.3, 0.3)).normalized()
	var force = randf_range(3.2, 5.0)
	apply_central_impulse(eject_dir * force)
	apply_torque_impulse(Vector3(
		randf_range(-15.0, 15.0),
		randf_range(-15.0, 15.0),
		randf_range(-15.0, 15.0)
	))

func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	queue_free()
