extends Node3D

# Rebuilt Supersonic Incandescent Bullet Tracer (Tapered Hot-Core Ribbon Shader)
# Crossed longitudinal alpha-faded plasma/brass planes — zero blocky box edges!

var start_pos: Vector3
var end_pos: Vector3
var speed: float = 165.0
var current_t: float = 0.0
var total_dist: float = 0.0
var tracer_len: float = 1.6

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

static var _tracer_shader: Shader = null

static func _get_tracer_shader() -> Shader:
	if not _tracer_shader:
		_tracer_shader = Shader.new()
		_tracer_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 head_color : source_color = vec4(1.0, 0.97, 0.82, 1.0);
uniform vec4 tail_color : source_color = vec4(1.0, 0.52, 0.10, 1.0);

void fragment() {
	// UV.x: 0 = leading hot tip, 1 = fading tail
	float along = pow(1.0 - UV.x, 1.65) * smoothstep(0.0, 0.06, UV.x);
	float cross_w = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = pow(clamp(cross_w, 0.0, 1.0), 2.2);
	vec3 col = mix(tail_color.rgb, head_color.rgb, smoothstep(0.55, 0.0, UV.x) * core);
	ALBEDO = col * 2.6;
	ALPHA = clamp(along * core, 0.0, 1.0);
}
"""
	return _tracer_shader

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
			
	tracer_len = clampf(total_dist * 0.32, 0.75, 3.2)
	var mat := ShaderMaterial.new()
	mat.shader = _get_tracer_shader()
	
	# Build crossed X-planes along -Z so tracer looks volumetric from every viewing angle!
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw: float = 0.026
	for plane_idx in range(2):
		var a := Vector3(hw, 0, 0) if plane_idx == 0 else Vector3(0, hw, 0)
		var p_head_l := -a
		var p_head_r := a
		var p_tail_l := Vector3(0, 0, tracer_len) - a * 0.45
		var p_tail_r := Vector3(0, 0, tracer_len) + a * 0.45
		
		st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(p_head_l)
		st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(p_head_r)
		st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(p_tail_r)
		
		st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(p_head_l)
		st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(p_tail_r)
		st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(p_tail_l)
		
	if mesh_instance:
		mesh_instance.mesh = st.commit()
		mesh_instance.material_override = mat
		mesh_instance.position = Vector3.ZERO

func _process(delta: float) -> void:
	if total_dist <= 0.01:
		queue_free()
		return
	current_t += (speed * delta) / total_dist
	if current_t >= 1.0:
		queue_free()
		return
	global_position = start_pos.lerp(end_pos, current_t)
