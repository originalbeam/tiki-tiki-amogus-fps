class_name WeaponWorkbench
extends Node3D

# Tactical Weapon Modification Workbench (Верстак модификации оружия)
# Purchased in the Field Shop for $250 and placed near the center of the map clear of obstacles.
# Entering its Area3D zone enables [N] interaction to open the EFT-style weapon modding menu.

var interaction_zone: Area3D = null
var floating_label: Label3D = null
var float_time: float = 0.0
const LABEL_BASE_Y: float = 2.45

func _ready() -> void:
	add_to_group("weapon_workbench")
	_build_workbench_structure(self, true)
	_build_interaction_zone()
	_build_floating_label()

func _process(delta: float) -> void:
	if floating_label:
		float_time += delta * 2.4
		floating_label.position.y = LABEL_BASE_Y + sin(float_time) * 0.08

func _build_floating_label() -> void:
	floating_label = Label3D.new()
	floating_label.name = "FloatingPrompt"
	floating_label.add_to_group("floating_3d_label")
	floating_label.text = "[N] ВЕРСТАК МОДИФИКАЦИИ"
	floating_label.position = Vector3(0.0, LABEL_BASE_Y, 0.0)
	floating_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	floating_label.pixel_size = 0.0024
	floating_label.font_size = 96
	floating_label.outline_size = 20
	floating_label.modulate = Color(0.92, 0.78, 0.44, 1.0)
	floating_label.outline_modulate = Color(0.05, 0.05, 0.06, 0.95)
	floating_label.shaded = false
	floating_label.double_sided = true
	add_child(floating_label)

static func create_preview() -> Node3D:
	var root := Node3D.new()
	root.name = "WorkbenchPreview"
	_build_workbench_structure(root, false)
	root.position = Vector3(0, -0.75, 0)
	root.scale = Vector3(0.55, 0.55, 0.55)
	return root

static func find_safe_center_pos(tree: SceneTree, player: Node3D) -> Vector3:
	# Candidate positions near map center (0, 0, 0) where ProceduralMap keeps CLEAR_RADIUS = 13m
	var candidates: Array[Vector3] = [
		Vector3(5.5, 0.0, -4.5),
		Vector3(6.0, 0.0, 4.5),
		Vector3(-5.5, 0.0, -6.0),
		Vector3(0.0, 0.0, -7.0),
		Vector3(7.5, 0.0, 0.0),
		Vector3(-6.0, 0.0, 6.5),
		Vector3(4.0, 0.0, 7.5),
		Vector3(8.5, 0.0, -5.5),
		Vector3(-7.5, 0.0, -3.5)
	]
	
	var vans := tree.get_nodes_in_group("minivan_shop")
	var obstacles := MapObstacles.obstacle_aabbs
	
	for pos in candidates:
		var safe := true
		# Stay away from player so it never spawns on top of them
		if is_instance_valid(player):
			var p2 := Vector2(player.global_position.x, player.global_position.z)
			if p2.distance_to(Vector2(pos.x, pos.z)) < 3.5:
				safe = false
		# Stay clear of minivan shop
		if safe:
			for v in vans:
				if is_instance_valid(v) and v is Node3D:
					var vp := (v as Node3D).global_position
					if Vector2(vp.x, vp.z).distance_to(Vector2(pos.x, pos.z)) < 6.0:
						safe = false
						break
		# Stay clear of all generated obstacles
		if safe:
			var test_aabb := AABB(pos - Vector3(2.2, 0.0, 1.6), Vector3(4.4, 2.5, 3.2))
			for obs in obstacles:
				if test_aabb.intersects(obs.grow(1.5)):
					safe = false
					break
		if safe:
			return pos
			
	return Vector3(6.0, 0.0, -5.0)

static func _build_workbench_structure(parent: Node3D, with_collision: bool) -> void:
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.14, 0.15, 0.17)
	mat_steel.metallic = 0.85
	mat_steel.roughness = 0.38
	
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.45, 0.28, 0.14)
	mat_wood.roughness = 0.68
	
	var mat_mat := StandardMaterial3D.new()
	mat_mat.albedo_color = Color(0.14, 0.24, 0.16) # Gunsmith mat green
	mat_mat.roughness = 0.88
	
	var mat_pegboard := StandardMaterial3D.new()
	mat_pegboard.albedo_color = Color(0.20, 0.22, 0.24)
	mat_pegboard.metallic = 0.6
	mat_pegboard.roughness = 0.55
	
	var mat_vise := StandardMaterial3D.new()
	mat_vise.albedo_color = Color(0.20, 0.34, 0.48)
	mat_vise.metallic = 0.8
	mat_vise.roughness = 0.35
	
	var mat_ammo_box := StandardMaterial3D.new()
	mat_ammo_box.albedo_color = Color(0.22, 0.29, 0.18)
	mat_ammo_box.metallic = 0.45
	mat_ammo_box.roughness = 0.5
	
	var mat_amber := StandardMaterial3D.new()
	mat_amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_amber.albedo_color = Color(0.95, 0.78, 0.38)
	
	var mat_tool_steel := StandardMaterial3D.new()
	mat_tool_steel.albedo_color = Color(0.68, 0.70, 0.74)
	mat_tool_steel.metallic = 0.92
	mat_tool_steel.roughness = 0.22
	
	var mat_tool_red := StandardMaterial3D.new()
	mat_tool_red.albedo_color = Color(0.72, 0.18, 0.16)
	mat_tool_red.roughness = 0.5
	
	var body_parent: Node3D = parent
	if with_collision:
		var static_body := StaticBody3D.new()
		static_body.name = "WorkbenchCollider"
		static_body.collision_layer = 1
		static_body.collision_mask = 7
		parent.add_child(static_body)
		
		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = Vector3(2.1, 1.8, 1.05)
		col.shape = cs
		col.position = Vector3(0, 0.9, 0)
		static_body.add_child(col)
		body_parent = static_body
		
	# 4 Heavy steel legs
	for lx in [-0.94, 0.94]:
		for lz in [-0.42, 0.42]:
			_add_box(body_parent, Vector3(0.08, 0.90, 0.08), Vector3(lx, 0.45, lz), mat_steel)
			
	# Lower steel shelf & crossbars
	_add_box(body_parent, Vector3(1.92, 0.04, 0.86), Vector3(0, 0.26, 0), mat_steel)
	
	# Thick butcher-block wooden tabletop
	_add_box(body_parent, Vector3(2.10, 0.08, 1.00), Vector3(0, 0.94, 0), mat_wood)
	
	# Tactical green gunsmith mat on top
	_add_box(body_parent, Vector3(1.22, 0.012, 0.62), Vector3(0.08, 0.986, 0.04), mat_mat)
	
	# Steel bench vise on left side of tabletop
	_add_box(body_parent, Vector3(0.18, 0.14, 0.22), Vector3(-0.76, 1.05, 0.26), mat_vise)
	_add_box(body_parent, Vector3(0.20, 0.06, 0.06), Vector3(-0.76, 1.13, 0.34), mat_tool_steel)
	_add_box(body_parent, Vector3(0.20, 0.06, 0.06), Vector3(-0.76, 1.13, 0.18), mat_tool_steel)
	
	# Back tool pegboard uprights & panel
	for lx in [-0.94, 0.94]:
		_add_box(body_parent, Vector3(0.06, 0.95, 0.06), Vector3(lx, 1.45, -0.44), mat_steel)
	_add_box(body_parent, Vector3(1.96, 0.72, 0.04), Vector3(0, 1.44, -0.44), mat_pegboard)
	# Top shelf bar above pegboard
	_add_box(body_parent, Vector3(2.04, 0.05, 0.24), Vector3(0, 1.88, -0.36), mat_steel)
	
	# Hanging tools on pegboard (wrenches, screwdrivers, calipers)
	for i in range(4):
		var tx := -0.62 + i * 0.22
		_add_box(body_parent, Vector3(0.025, 0.24, 0.015), Vector3(tx, 1.44, -0.41), mat_tool_steel)
	for i in range(3):
		var tx := 0.25 + i * 0.18
		_add_box(body_parent, Vector3(0.028, 0.10, 0.028), Vector3(tx, 1.54, -0.41), mat_tool_red)
		_add_box(body_parent, Vector3(0.012, 0.18, 0.012), Vector3(tx, 1.40, -0.41), mat_tool_steel)
		
	# Ammo box & toolkit on lower shelf
	_add_box(body_parent, Vector3(0.46, 0.28, 0.26), Vector3(-0.55, 0.42, 0.02), mat_ammo_box)
	_add_box(body_parent, Vector3(0.54, 0.24, 0.30), Vector3(0.48, 0.40, 0.0), mat_tool_red)
	
	# Overhead workshop LED light bar
	_add_box(body_parent, Vector3(1.40, 0.04, 0.08), Vector3(0, 1.84, -0.26), mat_amber)
	if with_collision:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.86, 0.58)
		lamp.light_energy = 2.6
		lamp.omni_range = 7.5
		lamp.position = Vector3(0, 1.72, 0.15)
		parent.add_child(lamp)
		
		# Ground interaction zone ring (Tarkov amber accent)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.45
		tm.outer_radius = 2.55
		tm.rings = 32
		tm.ring_segments = 8
		ring.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(0.85, 0.68, 0.32, 0.55)
		ring.material_override = rmat
		ring.position = Vector3(0, 0.03, 0.25)
		parent.add_child(ring)

func _build_interaction_zone() -> void:
	interaction_zone = Area3D.new()
	interaction_zone.name = "WorkbenchZone"
	interaction_zone.collision_layer = 0
	interaction_zone.collision_mask = 7 # Detect player on layer 1 or 2
	interaction_zone.monitoring = true
	interaction_zone.monitorable = false
	add_child(interaction_zone)
	
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.75
	cyl.height = 3.0
	col.shape = cyl
	col.position = Vector3(0, 1.2, 0.25)
	interaction_zone.add_child(col)
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body and body.is_in_group("player") and body.has_method("set_near_workbench"):
		body.set_near_workbench(true)

func _on_body_exited(body: Node3D) -> void:
	if body and body.is_in_group("player") and body.has_method("set_near_workbench"):
		body.set_near_workbench(false)

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
