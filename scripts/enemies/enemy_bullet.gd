extends Area3D

# Rebuilt Tapered Incandescent Enemy Tracer Projectile + Wall Spark Burst

var speed: float = 24.0
var damage: float = 12.0
var direction: Vector3 = Vector3.FORWARD
var bullet_color: Color = Color(1.0, 0.25, 0.2)

const BulletImpactScene = preload("res://scenes/bullet_impact.tscn")

func init(dir: Vector3, dmg: float = 12.0, color: Color = Color(1.0, 0.2, 0.2), custom_speed: float = 24.0, _custom_lifetime: float = 0.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = custom_speed
	bullet_color = color
	if is_inside_tree():
		if absf(direction.dot(Vector3.UP)) > 0.99:
			look_at(global_position + direction, Vector3.RIGHT)
		else:
			look_at(global_position + direction, Vector3.UP)
			
	var mesh_inst: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh_inst:
		# Sleek tapered glowing hot bolt + bright inner white core
		var bolt := CylinderMesh.new()
		bolt.top_radius = 0.022
		bolt.bottom_radius = 0.005
		bolt.height = 0.85 if custom_speed > 40.0 else 0.52
		bolt.radial_segments = 8
		mesh_inst.mesh = bolt
		mesh_inst.rotation_degrees = Vector3(-90.0, 0, 0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(minf(1.0, color.r * 1.4), minf(1.0, color.g * 1.4), minf(1.0, color.b * 1.4), 0.95)
		mesh_inst.material_override = mat
		
		# Bright white-hot tip core
		var core := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.011
		cm.bottom_radius = 0.002
		cm.height = bolt.height * 0.72
		cm.radial_segments = 6
		core.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.albedo_color = Color(1.0, 0.98, 0.88)
		core.material_override = cmat
		core.position = Vector3(0, bolt.height * 0.12, 0)
		mesh_inst.add_child(core)
		
	var light: OmniLight3D = get_node_or_null("OmniLight3D")
	if light:
		light.light_color = color
		light.light_energy = 1.6
		light.omni_range = 3.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	if absf(global_position.x) > 130.0 or absf(global_position.z) > 130.0 or global_position.y > 60.0 or global_position.y < -10.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemy"):
		if body.is_in_group("shop_building") and body.has_method("take_damage"):
			body.take_damage(damage)
		# Spawn rich surface spark impact on wall/obstacle hits!
		if BulletImpactScene and get_tree() and get_tree().root:
			var imp := BulletImpactScene.instantiate()
			imp.position = global_position
			get_tree().root.add_child(imp)
			imp.global_position = global_position
			var back := -direction
			if absf(back.dot(Vector3.UP)) > 0.98:
				imp.look_at(global_position + back, Vector3.RIGHT)
			else:
				imp.look_at(global_position + back, Vector3.UP)
			imp.init(false)
		queue_free()
