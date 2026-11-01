class_name MapObstacles
extends Node3D

# Procedural generation of wrecked cars, containers, barricades, and crates along the conical battlefield
# Provides obstacle AABBs for NavManager pathfinding

static var obstacle_aabbs: Array[AABB] = []

func _ready() -> void:
	build_all_obstacles(self)

static func build_all_obstacles(parent: Node3D) -> Array[AABB]:
	obstacle_aabbs.clear()
	
	# Common Materials
	var mat_rust := StandardMaterial3D.new()
	mat_rust.albedo_color = Color(0.35, 0.22, 0.15)
	mat_rust.metallic = 0.7
	mat_rust.roughness = 0.85
	
	var mat_car_blue := StandardMaterial3D.new()
	mat_car_blue.albedo_color = Color(0.12, 0.22, 0.35)
	mat_car_blue.metallic = 0.8
	mat_car_blue.roughness = 0.5
	
	var mat_car_red := StandardMaterial3D.new()
	mat_car_red.albedo_color = Color(0.45, 0.14, 0.12)
	mat_car_red.metallic = 0.75
	mat_car_red.roughness = 0.6
	
	var mat_car_police := StandardMaterial3D.new()
	mat_car_police.albedo_color = Color(0.15, 0.15, 0.16)
	mat_car_police.metallic = 0.85
	mat_car_police.roughness = 0.4
	
	var mat_glass_dark := StandardMaterial3D.new()
	mat_glass_dark.albedo_color = Color(0.08, 0.10, 0.12, 0.85)
	mat_glass_dark.roughness = 0.2
	
	var mat_tire := StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.08, 0.08, 0.09)
	mat_tire.roughness = 0.95
	
	var mat_concrete := StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.42, 0.44, 0.46)
	mat_concrete.roughness = 0.9
	
	var mat_hazard := StandardMaterial3D.new()
	mat_hazard.albedo_color = Color(0.85, 0.72, 0.1)
	mat_hazard.roughness = 0.6
	
	var mat_crate_wood := StandardMaterial3D.new()
	mat_crate_wood.albedo_color = Color(0.58, 0.38, 0.20)
	mat_crate_wood.roughness = 0.85
	
	var mat_crate_military := StandardMaterial3D.new()
	mat_crate_military.albedo_color = Color(0.24, 0.32, 0.20)
	mat_crate_military.metallic = 0.6
	mat_crate_military.roughness = 0.45
	
	var mat_barrel := StandardMaterial3D.new()
	mat_barrel.albedo_color = Color(0.65, 0.18, 0.12)
	mat_barrel.metallic = 0.7
	mat_barrel.roughness = 0.5

	# === SECTOR 1: Base corridor covers (Z = -135 to -105) ===
	# Left lane covers
	_build_crate_stack(parent, Vector3(-32.0, 0.0, -125.0), 15.0, mat_crate_wood, mat_crate_military)
	_build_jersey_barrier(parent, Vector3(-24.0, 0.0, -112.0), -12.0, mat_concrete, mat_hazard)
	
	# Center lane covers
	_build_wrecked_sedan(parent, Vector3(2.5, 0.0, -130.0), 35.0, mat_car_blue, mat_rust, mat_glass_dark, mat_tire)
	_build_barrel_cluster(parent, Vector3(-4.0, 0.0, -114.0), mat_barrel)
	
	# Right lane covers
	_build_crate_stack(parent, Vector3(28.0, 0.0, -125.0), -20.0, mat_crate_military, mat_crate_wood)
	_build_jersey_barrier(parent, Vector3(22.0, 0.0, -112.0), 15.0, mat_concrete, mat_hazard)

	# === SECTOR 2: Open Convergence Zone (Z = -95 to -60) ===
	_build_wrecked_pickup(parent, Vector3(10.0, 0.0, -85.0), -35.0, mat_rust, mat_glass_dark, mat_tire)
	_build_jersey_barrier_line(parent, Vector3(-8.0, 0.0, -90.0), 10.0, 3, mat_concrete, mat_hazard)
	_build_wrecked_van(parent, Vector3(-16.0, 0.0, -75.0), 75.0, mat_car_red, mat_rust, mat_glass_dark, mat_tire)
	_build_shipping_container(parent, Vector3(2.0, 0.0, -70.0), -18.0, mat_car_blue)
	_build_crate_stack(parent, Vector3(18.0, 0.0, -64.0), 45.0, mat_crate_wood, mat_crate_military)
	_build_barrel_cluster(parent, Vector3(-6.0, 0.0, -66.0), mat_barrel)

	# === SECTOR 3: Midfield Battlefield (Z = -60 to -35) ===
	_build_wrecked_sedan(parent, Vector3(-7.0, 0.0, -52.0), -25.0, mat_car_police, mat_rust, mat_glass_dark, mat_tire)
	_build_jersey_barrier(parent, Vector3(8.0, 0.0, -48.0), 40.0, mat_concrete, mat_hazard)
	_build_crate_stack(parent, Vector3(-10.0, 0.0, -38.0), 10.0, mat_crate_military, mat_crate_wood)
	_build_wrecked_pickup(parent, Vector3(11.0, 0.0, -36.0), 155.0, mat_car_blue, mat_glass_dark, mat_tire)

	# === SECTOR 4: Near Shop Defense Perimeter (Z = -30 to -10) ===
	_build_wrecked_sedan(parent, Vector3(-3.5, 0.0, -22.0), 20.0, mat_rust, mat_rust, mat_glass_dark, mat_tire)
	_build_jersey_barrier_line(parent, Vector3(5.0, 0.0, -18.0), -15.0, 2, mat_concrete, mat_hazard)
	_build_crate_stack(parent, Vector3(-7.5, 0.0, -14.0), -30.0, mat_crate_wood, mat_crate_military)

	return obstacle_aabbs

# ── Obstacle Builder Helpers ──────────────────────────────────────────────────

static func _register_aabb(center: Vector3, size: Vector3) -> void:
	var half := size * 0.5
	obstacle_aabbs.append(AABB(center - half, size))

static func _build_wrecked_sedan(parent: Node3D, pos: Vector3, rot_y: float, mat_body: Material, mat_rust: Material, mat_glass: Material, mat_tire: Material) -> void:
	var car := StaticBody3D.new()
	car.position = pos
	car.rotation_degrees = Vector3(3.0, rot_y, -2.0) # slightly tilted as if crashed
	car.collision_layer = 1
	car.collision_mask = 7
	parent.add_child(car)
	
	# Lower chassis
	var chassis := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.0, 0.65, 4.4)
	chassis.mesh = cm
	chassis.material_override = mat_body
	chassis.position = Vector3(0, 0.55, 0)
	car.add_child(chassis)
	
	# Cabin
	var cabin := MeshInstance3D.new()
	var cabm := BoxMesh.new()
	cabm.size = Vector3(1.7, 0.70, 2.2)
	cabin.mesh = cabm
	cabin.material_override = mat_glass
	cabin.position = Vector3(0, 1.20, -0.2)
	car.add_child(cabin)
	
	# Cabin roof
	var roof := MeshInstance3D.new()
	var rfm := BoxMesh.new()
	rfm.size = Vector3(1.72, 0.08, 2.22)
	roof.mesh = rfm
	roof.material_override = mat_body
	roof.position = Vector3(0, 1.57, -0.2)
	car.add_child(roof)
	
	# Popped / Dented Hood
	var hood := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(1.7, 0.12, 1.3)
	hood.mesh = hm
	hood.material_override = mat_rust
	hood.position = Vector3(0, 0.95, 1.3)
	hood.rotation_degrees.x = 18.0
	car.add_child(hood)
	
	# Wheels (some present, one missing)
	var wheel_offsets = [
		Vector3(-0.98, 0.35, 1.2),
		Vector3(0.98, 0.35, 1.2),
		Vector3(-0.98, 0.35, -1.2)
	]
	for wo in wheel_offsets:
		var wheel := MeshInstance3D.new()
		var wm := CylinderMesh.new()
		wm.top_radius = 0.34
		wm.bottom_radius = 0.34
		wm.height = 0.25
		wheel.mesh = wm
		wheel.material_override = mat_tire
		wheel.rotation_degrees.z = 90.0
		wheel.position = wo
		car.add_child(wheel)
		
	# Solid collision box
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.2, 1.6, 4.6)
	col.shape = cs
	col.position = Vector3(0, 0.8, 0)
	car.add_child(col)
	
	_register_aabb(pos + Vector3(0, 0.8, 0), Vector3(2.8, 2.0, 4.8))

static func _build_wrecked_pickup(parent: Node3D, pos: Vector3, rot_y: float, mat_body: Material, mat_glass: Material, mat_tire: Material) -> void:
	var truck := StaticBody3D.new()
	truck.position = pos
	truck.rotation_degrees = Vector3(0.0, rot_y, 0.0)
	truck.collision_layer = 1
	truck.collision_mask = 7
	parent.add_child(truck)
	
	# Cab
	var cab := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.2, 1.5, 2.2)
	cab.mesh = cm
	cab.material_override = mat_body
	cab.position = Vector3(0, 1.0, 0.9)
	truck.add_child(cab)
	
	# Windshield
	var win := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(1.9, 0.7, 0.1)
	win.mesh = wm
	win.material_override = mat_glass
	win.position = Vector3(0, 1.25, 2.02)
	truck.add_child(win)
	
	# Open Bed
	var bed := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 0.7, 2.6)
	bed.mesh = bm
	bed.material_override = mat_body
	bed.position = Vector3(0, 0.65, -1.3)
	truck.add_child(bed)
	
	# Wheels
	for wx in [-1.05, 1.05]:
		for wz in [-1.3, 1.1]:
			var wh := MeshInstance3D.new()
			var whm := CylinderMesh.new()
			whm.top_radius = 0.40
			whm.bottom_radius = 0.40
			whm.height = 0.28
			wh.mesh = whm
			wh.material_override = mat_tire
			wh.rotation_degrees.z = 90.0
			wh.position = Vector3(wx, 0.40, wz)
			truck.add_child(wh)
			
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.4, 1.8, 5.0)
	col.shape = cs
	col.position = Vector3(0, 0.9, 0)
	truck.add_child(col)
	
	_register_aabb(pos + Vector3(0, 0.9, 0), Vector3(3.0, 2.2, 5.2))

static func _build_wrecked_van(parent: Node3D, pos: Vector3, rot_y: float, mat_body: Material, mat_rust: Material, mat_glass: Material, mat_tire: Material) -> void:
	var van := StaticBody3D.new()
	van.position = pos
	van.rotation_degrees = Vector3(0.0, rot_y, 0.0)
	van.collision_layer = 1
	van.collision_mask = 7
	parent.add_child(van)
	
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.3, 2.1, 5.2)
	body.mesh = bm
	body.material_override = mat_body
	body.position = Vector3(0, 1.25, 0)
	van.add_child(body)
	
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.5, 2.2, 5.4)
	col.shape = cs
	col.position = Vector3(0, 1.25, 0)
	van.add_child(col)
	
	_register_aabb(pos + Vector3(0, 1.25, 0), Vector3(3.2, 2.5, 5.6))

static func _build_shipping_container(parent: Node3D, pos: Vector3, rot_y: float, mat_cont: Material) -> void:
	var cont := StaticBody3D.new()
	cont.position = pos
	cont.rotation_degrees = Vector3(0, rot_y, 0)
	cont.collision_layer = 1
	cont.collision_mask = 7
	parent.add_child(cont)
	
	var mesh := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.6, 2.6, 6.2)
	mesh.mesh = cm
	mesh.material_override = mat_cont
	mesh.position = Vector3(0, 1.3, 0)
	cont.add_child(mesh)
	
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.6, 2.6, 6.2)
	col.shape = cs
	col.position = Vector3(0, 1.3, 0)
	cont.add_child(col)
	
	_register_aabb(pos + Vector3(0, 1.3, 0), Vector3(3.4, 3.0, 6.6))

static func _build_jersey_barrier(parent: Node3D, pos: Vector3, rot_y: float, mat_concrete: Material, mat_hazard: Material) -> void:
	var bar := StaticBody3D.new()
	bar.position = pos
	bar.rotation_degrees = Vector3(0, rot_y, 0)
	bar.collision_layer = 1
	bar.collision_mask = 7
	parent.add_child(bar)
	
	# Base
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.5, 3.0)
	base.mesh = bm
	base.material_override = mat_concrete
	base.position = Vector3(0, 0.25, 0)
	bar.add_child(base)
	
	# Top wedge
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.5, 0.65, 3.0)
	top.mesh = tm
	top.material_override = mat_concrete
	top.position = Vector3(0, 0.75, 0)
	bar.add_child(top)
	
	# Hazard stripe
	var stripe := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.52, 0.22, 2.8)
	stripe.mesh = sm
	stripe.material_override = mat_hazard
	stripe.position = Vector3(0, 0.75, 0)
	bar.add_child(stripe)
	
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.0, 1.15, 3.0)
	col.shape = cs
	col.position = Vector3(0, 0.575, 0)
	bar.add_child(col)
	
	_register_aabb(pos + Vector3(0, 0.6, 0), Vector3(1.8, 1.6, 3.4))

static func _build_jersey_barrier_line(parent: Node3D, pos: Vector3, rot_y: float, count: int, mat_concrete: Material, mat_hazard: Material) -> void:
	var line_root := Node3D.new()
	line_root.position = pos
	line_root.rotation_degrees = Vector3(0, rot_y, 0)
	parent.add_child(line_root)
	
	for i in range(count):
		var offset_z = (i - (count - 1) * 0.5) * 3.0
		_build_jersey_barrier(line_root, Vector3(0, 0, offset_z), 0, mat_concrete, mat_hazard)

static func _build_crate_stack(parent: Node3D, pos: Vector3, rot_y: float, mat_crate1: Material, mat_crate2: Material) -> void:
	var stack := StaticBody3D.new()
	stack.position = pos
	stack.rotation_degrees = Vector3(0, rot_y, 0)
	stack.collision_layer = 1
	stack.collision_mask = 7
	parent.add_child(stack)
	
	# Bottom crates
	var c1 := MeshInstance3D.new()
	var m1 := BoxMesh.new()
	m1.size = Vector3(1.8, 1.4, 1.8)
	c1.mesh = m1
	c1.material_override = mat_crate1
	c1.position = Vector3(-0.5, 0.7, 0)
	stack.add_child(c1)
	
	var c2 := MeshInstance3D.new()
	var m2 := BoxMesh.new()
	m2.size = Vector3(1.5, 1.2, 1.5)
	c2.mesh = m2
	c2.material_override = mat_crate2
	c2.position = Vector3(0.9, 0.6, 0.2)
	stack.add_child(c2)
	
	# Top crate
	var c3 := MeshInstance3D.new()
	var m3 := BoxMesh.new()
	m3.size = Vector3(1.3, 1.1, 1.3)
	c3.mesh = m3
	c3.material_override = mat_crate2
	c3.position = Vector3(-0.2, 1.95, -0.1)
	c3.rotation_degrees = Vector3(0, 15, 0)
	stack.add_child(c3)
	
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(3.0, 2.6, 2.4)
	col.shape = cs
	col.position = Vector3(0.1, 1.3, 0.1)
	stack.add_child(col)
	
	_register_aabb(pos + Vector3(0.1, 1.3, 0.1), Vector3(3.6, 3.0, 3.2))

static func _build_barrel_cluster(parent: Node3D, pos: Vector3, mat_barrel: Material) -> void:
	var cluster := StaticBody3D.new()
	cluster.position = pos
	cluster.collision_layer = 1
	cluster.collision_mask = 7
	parent.add_child(cluster)
	
	var offsets = [
		Vector3(-0.45, 0.55, -0.45),
		Vector3(0.45, 0.55, -0.45),
		Vector3(0.0, 0.55, 0.45)
	]
	for off in offsets:
		var b := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.38
		bm.bottom_radius = 0.38
		bm.height = 1.1
		b.mesh = bm
		b.material_override = mat_barrel
		b.position = off
		cluster.add_child(b)
		
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.6, 1.2, 1.6)
	col.shape = cs
	col.position = Vector3(0, 0.6, 0)
	cluster.add_child(col)
	
	_register_aabb(pos + Vector3(0, 0.6, 0), Vector3(2.2, 1.8, 2.2))
