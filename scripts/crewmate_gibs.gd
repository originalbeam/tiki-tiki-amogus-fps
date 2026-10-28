extends Node3D

@onready var blood_particles: CPUParticles3D = $BloodParticles

func init(crewmate_color: Color) -> void:
	# Apply crewmate color to gib parts
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = crewmate_color
	body_mat.roughness = 0.4
	
	for child in get_children():
		if child is RigidBody3D:
			for sub in child.get_children():
				if sub is MeshInstance3D and sub.name != "Bone" and sub.name != "Visor":
					sub.material_override = body_mat
			
			# Apply explosion impulse outward
			var random_dir = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(0.8, 1.8),
				randf_range(-1.0, 1.0)
			).normalized()
			var force = randf_range(6.0, 12.0)
			child.apply_central_impulse(random_dir * force)
			child.apply_torque_impulse(Vector3(
				randf_range(-8.0, 8.0),
				randf_range(-8.0, 8.0),
				randf_range(-8.0, 8.0)
			))

func _ready() -> void:
	if blood_particles:
		blood_particles.emitting = true
	# Fade and free after a few seconds
	await get_tree().create_timer(4.5).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	queue_free()
