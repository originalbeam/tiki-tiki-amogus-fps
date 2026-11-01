class_name NavManager
extends Node3D

# Conical Arena Pathfinding & Navigation AI
# Fast 8-directional AStar3D with obstacle clearance and lane support

const MapObstaclesScript = preload("res://scripts/map_obstacles.gd")

var astar: AStar3D = AStar3D.new()
var grid_step: float = 2.5
var point_id_map: Dictionary = {} # Vector2i -> int
var id_coord_map: Dictionary = {} # int -> Vector2i
var next_id: int = 1

var obstacle_aabbs: Array[AABB] = []

func _ready() -> void:
	add_to_group("nav_manager")
	# Small delay to ensure MapObstacles have registered their AABBs
	await get_tree().process_frame
	build_navigation_grid()

func build_navigation_grid() -> void:
	astar.clear()
	point_id_map.clear()
	id_coord_map.clear()
	next_id = 1
	
	obstacle_aabbs = MapObstaclesScript.obstacle_aabbs.duplicate()
	
	# Add dividing walls as obstacle AABBs
	# Left dividing wall: X = -16, Z = -160 to -94
	obstacle_aabbs.append(AABB(Vector3(-17.2, 0.0, -161.0), Vector3(2.4, 6.0, 68.0)))
	# Right dividing wall: X = +16, Z = -160 to -94
	obstacle_aabbs.append(AABB(Vector3(14.8, 0.0, -161.0), Vector3(2.4, 6.0, 68.0)))
	
	# Shop outer walls
	obstacle_aabbs.append(AABB(Vector3(-11.0, 0.0, 2.0), Vector3(22.0, 4.0, 18.0)))
	# Minivan parking space (further from shop at X = -15.5, Z = -5.5)
	obstacle_aabbs.append(AABB(Vector3(-18.0, 0.0, -7.5), Vector3(5.5, 3.0, 4.5)))
	
	# Generate grid points
	var min_z := -155.0
	var max_z := 4.0
	var min_x := -46.0
	var max_x := 46.0
	
	var z_steps := int((max_z - min_z) / grid_step)
	var x_steps := int((max_x - min_x) / grid_step)
	
	for zi in range(z_steps + 1):
		var z := min_z + zi * grid_step
		var cone_half_width := get_cone_half_width_at_z(z) - 1.2
		
		for xi in range(x_steps + 1):
			var x := min_x + xi * grid_step
			
			# Check within conical arena side walls
			if absf(x) > cone_half_width:
				continue
				
			var pos := Vector3(x, 0.0, z)
			
			# Check against obstacles
			if is_point_blocked(pos):
				continue
				
			var coord := Vector2i(xi, zi)
			var pid := next_id
			next_id += 1
			
			point_id_map[coord] = pid
			id_coord_map[pid] = coord
			astar.add_point(pid, pos)
			
	# Connect neighboring points
	var dirs = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	
	for coord in point_id_map.keys():
		var id1: int = point_id_map[coord]
		var pos1: Vector3 = astar.get_point_position(id1)
		
		for d in dirs:
			var n_coord: Vector2i = coord + d
			if point_id_map.has(n_coord):
				var id2: int = point_id_map[n_coord]
				
				# For diagonal connections, ensure both adjacent cardinal neighbors exist
				# to prevent cutting through wall corners
				if abs(d.x) == 1 and abs(d.y) == 1:
					var card1: Vector2i = Vector2i(coord.x + d.x, coord.y)
					var card2: Vector2i = Vector2i(coord.x, coord.y + d.y)
					if not point_id_map.has(card1) or not point_id_map.has(card2):
						continue
						
				if not astar.are_points_connected(id1, id2):
					var pos2: Vector3 = astar.get_point_position(id2)
					var dist := pos1.distance_to(pos2)
					astar.connect_points(id1, id2, true)

func is_point_blocked(pos: Vector3) -> bool:
	for aabb in obstacle_aabbs:
		# Check if point is inside AABB grown with safety padding
		if aabb.grow(0.65).has_point(pos):
			# Exception: allow walking right in front of the shop entrance
			if pos.z <= 2.2 and pos.z >= 0.5 and absf(pos.x) <= 3.0:
				continue
			return true
	return false

func get_cone_half_width_at_z(z: float) -> float:
	if z >= -14.0:
		return 21.5
	var t := clampf((z - (-160.0)) / (-14.0 - (-160.0)), 0.0, 1.0)
	return lerpf(47.5, 21.5, t)

func get_navigation_path(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	if astar.get_point_count() == 0:
		return PackedVector3Array([to_pos])
		
	var start_id := astar.get_closest_point(from_pos)
	var end_id := astar.get_closest_point(to_pos)
	
	if start_id == -1 or end_id == -1:
		return PackedVector3Array([to_pos])
		
	var path := astar.get_point_path(start_id, end_id)
	if path.size() == 0:
		return PackedVector3Array([to_pos])
		
	# Replace first point with actual from_pos and append exact to_pos
	path[0] = from_pos
	path.append(to_pos)
	return path
