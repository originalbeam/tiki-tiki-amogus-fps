extends Node3D

@onready var particles: CPUParticles3D = $CPUParticles3D

func init(is_blood: bool) -> void:
	if is_blood:
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.9, 0.08, 0.08)
		particles.material_override = mat
		particles.amount = 16
		particles.spread = 45.0
		particles.initial_velocity_min = 3.0
		particles.initial_velocity_max = 6.0
	else:
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.9, 0.3)
		particles.material_override = mat

func _ready() -> void:
	particles.emitting = true
	await get_tree().create_timer(0.45).timeout
	queue_free()
