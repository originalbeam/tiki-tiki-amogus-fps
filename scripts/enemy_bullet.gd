extends Area3D

var speed: float = 24.0
var damage: float = 12.0
var direction: Vector3 = Vector3.FORWARD
var life_time: float = 4.0

func init(dir: Vector3, dmg: float = 12.0, color: Color = Color(1.0, 0.2, 0.2), custom_speed: float = 24.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = custom_speed
	if absf(direction.dot(Vector3.UP)) > 0.99:
		look_at(global_position + direction, Vector3.RIGHT)
	else:
		look_at(global_position + direction, Vector3.UP)
	var mesh_inst = get_node_or_null("MeshInstance3D")
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mesh_inst.material_override = mat
	var light = get_node_or_null("OmniLight3D")
	if light:
		light.light_color = color

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemy"):
		# Hit wall or obstacle
		queue_free()
