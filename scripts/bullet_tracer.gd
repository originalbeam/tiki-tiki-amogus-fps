extends Node3D

var start_pos: Vector3
var end_pos: Vector3
var speed: float = 140.0
var current_t: float = 0.0
var total_dist: float = 0.0
var tracer_len: float = 1.2

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func init(from: Vector3, to: Vector3) -> void:
	start_pos = from
	end_pos = to
	global_position = from
	total_dist = from.distance_to(to)
	
	if total_dist > 0.001:
		var dir: Vector3 = (to - from).normalized()
		if absf(dir.dot(Vector3.UP)) > 0.99:
			look_at(to, Vector3.RIGHT)
		else:
			look_at(to, Vector3.UP)
			
	tracer_len = clampf(total_dist * 0.4, 0.6, 2.5)
	if mesh_instance:
		var box = BoxMesh.new()
		box.size = Vector3(0.015, 0.015, tracer_len)
		mesh_instance.mesh = box
		mesh_instance.position = Vector3(0, 0, -tracer_len * 0.5)

func _process(delta: float) -> void:
	if total_dist <= 0.01:
		queue_free()
		return
		
	current_t += (speed * delta) / total_dist
	if current_t >= 1.0:
		queue_free()
		return
		
	global_position = start_pos.lerp(end_pos, current_t)
