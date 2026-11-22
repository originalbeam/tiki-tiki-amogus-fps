class_name NavManager
extends Node3D

# 165m x 165m Arena Pathfinding & Navigation AI
# Fast 8-directional AStar3D with obstacle clearance for open battlefield

var astar: AStar3D = AStar3D.new()
var grid_step: float = 3.0 # 3m resolution gives ~50x50 = 2500 nodes for fast high-precision pathfinding
var point_id_map: Dictionary = {} # Vector2i -> int
var id_coord_map: Dictionary = {} # int -> Vector2i
var next_id: int = 1

var obstacle_aabbs: Array[AABB] = []

func _ready() -> void:
	add_to_group("nav_manager")
	# Delay 2 frames so ProceduralMap and obstacles are built and ready
	await get_tree().process_frame
	await get_tree().process_frame
	build_navigation_grid()

func build_navigation_grid() -> void:
	astar.clear()
	point_id_map.clear()
	id_coord_map.clear()
	next_id = 1
	
	obstacle_aabbs = MapObstacles.obstacle_aabbs.duplicate()
	
	# Minivan parking dynamic AABB can be added if valid
	var minivans = get_tree().get_nodes_in_group("minivan_shop")
	for mv in minivans:
		if is_instance_valid(mv) and mv.visible:
			obstacle_aabbs.append(AABB(mv.global_position - Vector3(3.0, 0.0, 3.0), Vector3(6.0, 3.0, 6.0)))
	
	# Generate grid points across [-74, 74] x [-74, 74]
	var min_coord := -74.0
	var max_coord := 74.0
	var steps := int((max_coord - min_coord) / grid_step)
	
	for zi in range(steps + 1):
		var z := min_coord + zi * grid_step
		for xi in range(steps + 1):
			var x := min_coord + xi * grid_step
			var pos := Vector3(x, 0.0, z)
			
			if is_point_blocked(pos):
				continue
				
			var coord := Vector2i(xi, zi)
			var pid := next_id
			next_id += 1
			
			point_id_map[coord] = pid
			id_coord_map[pid] = coord
			astar.add_point(pid, pos)
			
	# Connect neighboring points (8 directions)
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
				
				# For diagonal connections, ensure adjacent cardinal neighbors exist
				if abs(d.x) == 1 and abs(d.y) == 1:
					var card1: Vector2i = Vector2i(coord.x + d.x, coord.y)
					var card2: Vector2i = Vector2i(coord.x, coord.y + d.y)
					if not point_id_map.has(card1) or not point_id_map.has(card2):
						continue
						
				if not astar.are_points_connected(id1, id2):
					astar.connect_points(id1, id2, true)

func is_point_blocked(pos: Vector3) -> bool:
	for aabb in obstacle_aabbs:
		if aabb.grow(0.8).has_point(pos):
			return true
	return false

func get_navigation_path(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	if astar.get_point_count() == 0:
		return PackedVector3Array([to_pos])
		
	var start_id := astar.get_closest_point(from_pos)
	var end_id := astar.get_closest_point(to_pos)
	
	if start_id == -1 or end_id == -1:
		return PackedVector3Array([to_pos])
		
	var path := astar.get_point_path(start_id, end_id)
	if path.is_empty():
		return PackedVector3Array([to_pos])
		
	# Replace last point with exact target destination
	path.set(path.size() - 1, to_pos)
	return path
