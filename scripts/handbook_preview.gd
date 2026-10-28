extends SubViewportContainer

@onready var viewport: SubViewport = $SubViewport
@onready var model_pivot: Node3D = $SubViewport/ModelPivot
@onready var camera: Camera3D = $SubViewport/Camera3D

var is_rotating: bool = false
var is_panning: bool = false
var auto_spin: bool = true
var auto_spin_speed: float = 1.0

var min_zoom: float = 0.35
var max_zoom: float = 3.8

# Active model reference
var current_model_node: Node3D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if viewport:
		viewport.own_world_3d = true
	gui_input.connect(_on_gui_input)

func _process(delta: float) -> void:
	if auto_spin and not is_rotating and not is_panning and model_pivot:
		model_pivot.rotation.y += delta * auto_spin_speed

func _input(event: InputEvent) -> void:
	if is_rotating and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_rotating = false
	if is_panning and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		is_panning = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
			if event.pressed:
				auto_spin = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = event.pressed
			if event.pressed:
				auto_spin = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			auto_spin = false
			if camera:
				camera.position.z = clampf(camera.position.z - 0.12, min_zoom, max_zoom)
				clamp_pan_limits()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			auto_spin = false
			if camera:
				camera.position.z = clampf(camera.position.z + 0.12, min_zoom, max_zoom)
				clamp_pan_limits()

	elif event is InputEventMouseMotion:
		if is_rotating and model_pivot:
			model_pivot.rotation.y += event.relative.x * 0.008
			model_pivot.rotation.x += event.relative.y * 0.008
			model_pivot.rotation.x = clampf(model_pivot.rotation.x, deg_to_rad(-65.0), deg_to_rad(65.0))
		elif is_panning and model_pivot and camera:
			var pan_speed: float = camera.position.z * 0.0022
			model_pivot.position.x += event.relative.x * pan_speed
			model_pivot.position.y -= event.relative.y * pan_speed
			clamp_pan_limits()

func clamp_pan_limits() -> void:
	if not model_pivot or not camera:
		return
	var norm: float = clampf((camera.position.z - min_zoom) / maxf(0.01, (max_zoom - min_zoom)), 0.0, 1.0)
	var max_pan_x: float = lerpf(0.95, 0.22, norm)
	var max_pan_y: float = lerpf(0.75, 0.18, norm)
	model_pivot.position.x = clampf(model_pivot.position.x, -max_pan_x, max_pan_x)
	model_pivot.position.y = clampf(model_pivot.position.y, -max_pan_y, max_pan_y)

func show_item(item_id: String) -> void:
	if not model_pivot:
		model_pivot = $SubViewport/ModelPivot
	if not camera:
		camera = $SubViewport/Camera3D
	if not viewport:
		viewport = $SubViewport
		
	if not model_pivot or not camera:
		return
		
	for child in model_pivot.get_children():
		model_pivot.remove_child(child)
		child.queue_free()
	current_model_node = null
		
	model_pivot.position = Vector3.ZERO
	model_pivot.rotation = Vector3.ZERO
	auto_spin = true
	is_rotating = false
	is_panning = false
	
	match item_id:
		"ak", "ak47":
			current_model_node = create_ak47_preview()
			camera.position = Vector3(0, 0.03, 1.05)
		"shotgun":
			current_model_node = create_shotgun_preview()
			camera.position = Vector3(0, 0.03, 1.25)
		"pistol":
			current_model_node = create_pistol_preview()
			camera.position = Vector3(0, 0.01, 0.52)
		"enemy_red":
			current_model_node = create_crewmate_preview(Color(0.9, 0.15, 0.15), 0)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_blue":
			current_model_node = create_crewmate_preview(Color(0.15, 0.45, 0.95), 1)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_yellow":
			current_model_node = create_crewmate_preview(Color(0.95, 0.75, 0.1), 2)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_green":
			current_model_node = create_crewmate_preview(Color(0.15, 0.85, 0.25), 3)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_shahed", "shahed":
			current_model_node = create_shahed_preview()
			camera.position = Vector3(0, 0.4, 2.2)
		"armor_vest":
			current_model_node = create_armor_preview()
			camera.position = Vector3(0, 0.0, 0.95)
		"bandage":
			current_model_node = create_bandage_preview()
			camera.position = Vector3(0, 0.0, 0.48)
		"knife":
			current_model_node = create_knife_preview()
			camera.position = Vector3(0, 0.0, 0.58)
		"medkit":
			current_model_node = create_medkit_preview()
			camera.position = Vector3(0, 0.0, 0.65)
		"vodka":
			current_model_node = create_vodka_preview()
			camera.position = Vector3(0, 0.05, 0.72)
		"heavy_armor":
			current_model_node = create_heavy_armor_preview()
			camera.position = Vector3(0, 0.0, 1.1)
		"armor_plate":
			current_model_node = create_armor_plate_preview()
			camera.position = Vector3(0, 0.0, 0.65)
			
	if current_model_node:
		model_pivot.add_child(current_model_node)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

func create_ak47_preview() -> Node3D:
	var root = Node3D.new()
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.15, 0.16, 0.19)
	mat_metal.metallic = 0.88
	mat_metal.roughness = 0.28
	
	var mat_dark_recess = StandardMaterial3D.new()
	mat_dark_recess.albedo_color = Color(0.06, 0.07, 0.08)
	mat_dark_recess.metallic = 0.6
	mat_dark_recess.roughness = 0.5
	
	var mat_bolt = StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.72, 0.74, 0.78)
	mat_bolt.metallic = 0.95
	mat_bolt.roughness = 0.18
	
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.48, 0.22, 0.1)
	mat_wood.roughness = 0.65
	
	var mat_mag = StandardMaterial3D.new()
	mat_mag.albedo_color = Color(0.18, 0.20, 0.23)
	mat_mag.metallic = 0.88
	mat_mag.roughness = 0.32
	
	var mat_grip = StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.38, 0.18, 0.10)
	mat_grip.roughness = 0.45
	
	# 1. Receiver Lower
	var rec_low = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(0.055, 0.055, 0.32)
	rec_low.mesh = r_mesh
	rec_low.material_override = mat_metal
	root.add_child(rec_low)
	
	# 2. Receiver Top Cover (Ribbed stamped steel cover)
	var rec_top = MeshInstance3D.new()
	var rt_mesh = BoxMesh.new()
	rt_mesh.size = Vector3(0.05, 0.038, 0.3)
	rec_top.mesh = rt_mesh
	rec_top.material_override = mat_metal
	rec_top.position = Vector3(0, 0.038, 0)
	root.add_child(rec_top)
	
	# Top Cover Stiffening Ribs
	for rx in [-0.012, 0.012]:
		var rib = MeshInstance3D.new()
		var rib_m = BoxMesh.new()
		rib_m.size = Vector3(0.005, 0.005, 0.24)
		rib.mesh = rib_m
		rib.material_override = mat_metal
		rib.position = Vector3(rx, 0.054, 0.01)
		root.add_child(rib)
		
	# Fire Selector Lever (Right side)
	var selector = MeshInstance3D.new()
	var sel_m = BoxMesh.new()
	sel_m.size = Vector3(0.004, 0.014, 0.075)
	selector.mesh = sel_m
	selector.material_override = mat_metal
	selector.position = Vector3(0.026, 0.008, 0.02)
	root.add_child(selector)
	
	# Lightening Dimple (Left side milled recess)
	var dimple = MeshInstance3D.new()
	var dim_m = BoxMesh.new()
	dim_m.size = Vector3(0.004, 0.016, 0.035)
	dimple.mesh = dim_m
	dimple.material_override = mat_dark_recess
	dimple.position = Vector3(-0.026, 0.006, -0.05)
	root.add_child(dimple)
	
	# Rear Sight Base & Tangent Ladder Leaf
	var rsb = MeshInstance3D.new()
	var rsb_m = BoxMesh.new()
	rsb_m.size = Vector3(0.036, 0.032, 0.045)
	rsb.mesh = rsb_m
	rsb.material_override = mat_metal
	rsb.position = Vector3(0, 0.038, -0.14)
	root.add_child(rsb)
	
	var leaf = MeshInstance3D.new()
	var leaf_m = BoxMesh.new()
	leaf_m.size = Vector3(0.016, 0.008, 0.04)
	leaf.mesh = leaf_m
	leaf.material_override = mat_metal
	leaf.position = Vector3(0, 0.044, -0.14)
	root.add_child(leaf)
	
	# 3. Ejection Port (Right side cutout)
	var eject_port = MeshInstance3D.new()
	var ep_mesh = BoxMesh.new()
	ep_mesh.size = Vector3(0.012, 0.032, 0.10)
	eject_port.mesh = ep_mesh
	eject_port.material_override = mat_dark_recess
	eject_port.position = Vector3(0.026, 0.03, -0.04)
	root.add_child(eject_port)
	
	# 4. Bolt Carrier (Silver steel visible inside ejection cutout)
	var bolt = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.015, 0.026, 0.09)
	bolt.mesh = b_mesh
	bolt.material_override = mat_bolt
	bolt.position = Vector3(0.024, 0.03, -0.04)
	root.add_child(bolt)
	
	# 5. Charging Handle (Right side curved handle)
	var handle = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.045, 0.016, 0.024)
	handle.mesh = h_mesh
	handle.material_override = mat_metal
	handle.position = Vector3(0.042, 0.03, -0.04)
	root.add_child(handle)
	
	# 6. Gas Piston Tube (Upper tube above barrel)
	var gas_tube = MeshInstance3D.new()
	var gt_mesh = CylinderMesh.new()
	gt_mesh.top_radius = 0.012
	gt_mesh.bottom_radius = 0.012
	gt_mesh.height = 0.22
	gas_tube.mesh = gt_mesh
	gas_tube.material_override = mat_metal
	gas_tube.rotation.x = deg_to_rad(90)
	gas_tube.position = Vector3(0, 0.03, -0.24)
	root.add_child(gas_tube)
	
	# 7. Barrel
	var barrel = MeshInstance3D.new()
	var bar_mesh = CylinderMesh.new()
	bar_mesh.top_radius = 0.011
	bar_mesh.bottom_radius = 0.011
	bar_mesh.height = 0.38
	barrel.mesh = bar_mesh
	barrel.material_override = mat_metal
	barrel.rotation.x = deg_to_rad(90)
	barrel.position = Vector3(0, 0.005, -0.32)
	root.add_child(barrel)
	
	# 8. Gas Block (Angled gas port block connecting barrel & gas tube)
	var gas_block = MeshInstance3D.new()
	var gb_mesh = BoxMesh.new()
	gb_mesh.size = Vector3(0.03, 0.045, 0.038)
	gas_block.mesh = gb_mesh
	gas_block.material_override = mat_metal
	gas_block.position = Vector3(0, 0.02, -0.36)
	root.add_child(gas_block)
	
	# 9. Cleaning Rod (Under barrel)
	var rod = MeshInstance3D.new()
	var rod_mesh = CylinderMesh.new()
	rod_mesh.top_radius = 0.003
	rod_mesh.bottom_radius = 0.003
	rod_mesh.height = 0.32
	rod.mesh = rod_mesh
	rod.material_override = mat_metal
	rod.rotation.x = deg_to_rad(90)
	rod.position = Vector3(0, -0.014, -0.34)
	root.add_child(rod)
	
	# 10. Front Sight Base & Post
	var sight = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.018, 0.045, 0.022)
	sight.mesh = s_mesh
	sight.material_override = mat_metal
	sight.position = Vector3(0, 0.032, -0.48)
	root.add_child(sight)
	
	# 11. Compensator (Slant muzzle brake)
	var comp = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.014
	c_mesh.bottom_radius = 0.014
	c_mesh.height = 0.045
	comp.mesh = c_mesh
	comp.material_override = mat_metal
	comp.rotation.x = deg_to_rad(90)
	comp.position = Vector3(0, 0.005, -0.52)
	root.add_child(comp)
	
	# 12. Lower Handguard (Palm swell wood)
	var wood_low = MeshInstance3D.new()
	var wl_mesh = BoxMesh.new()
	wl_mesh.size = Vector3(0.056, 0.054, 0.16)
	wood_low.mesh = wl_mesh
	wood_low.material_override = mat_wood
	wood_low.position = Vector3(0, -0.01, -0.22)
	root.add_child(wood_low)
	
	# 13. Upper Handguard (Wood heat shield)
	var wood_up = MeshInstance3D.new()
	var wu_mesh = BoxMesh.new()
	wu_mesh.size = Vector3(0.048, 0.034, 0.13)
	wood_up.mesh = wu_mesh
	wood_up.material_override = mat_wood
	wood_up.position = Vector3(0, 0.036, -0.22)
	root.add_child(wood_up)
	
	# 14. Handguard Retainer Rings (Front & Rear steel collars)
	var cap_front = MeshInstance3D.new()
	var cf_mesh = BoxMesh.new()
	cf_mesh.size = Vector3(0.058, 0.058, 0.015)
	cap_front.mesh = cf_mesh
	cap_front.material_override = mat_metal
	cap_front.position = Vector3(0, 0.01, -0.305)
	root.add_child(cap_front)
	
	var cap_rear = MeshInstance3D.new()
	var cr_mesh = BoxMesh.new()
	cr_mesh.size = Vector3(0.058, 0.058, 0.015)
	cap_rear.mesh = cr_mesh
	cap_rear.material_override = mat_metal
	cap_rear.position = Vector3(0, 0.01, -0.135)
	root.add_child(cap_rear)
	
	# 15. Wooden Stock
	var stock = MeshInstance3D.new()
	var st_mesh = BoxMesh.new()
	st_mesh.size = Vector3(0.048, 0.1, 0.24)
	stock.mesh = st_mesh
	stock.material_override = mat_wood
	stock.position = Vector3(0, -0.04, 0.24)
	stock.rotation.x = deg_to_rad(10)
	root.add_child(stock)
	
	# Steel Buttplate
	var buttplate = MeshInstance3D.new()
	var bp_m = BoxMesh.new()
	bp_m.size = Vector3(0.049, 0.102, 0.008)
	buttplate.mesh = bp_m
	buttplate.material_override = mat_metal
	buttplate.position = Vector3(0, 0, 0.12)
	stock.add_child(buttplate)
	
	# 16. Pistol Grip (Authentic backward slant towards stock)
	var grip = MeshInstance3D.new()
	var gr_mesh = BoxMesh.new()
	gr_mesh.size = Vector3(0.034, 0.11, 0.052)
	grip.mesh = gr_mesh
	grip.material_override = mat_grip
	grip.position = Vector3(0, -0.08, 0.065)
	grip.rotation.x = deg_to_rad(-22.0)
	root.add_child(grip)
	
	# 17. Trigger Guard, Trigger & Magazine Release Latch
	var guard = MeshInstance3D.new()
	var gd_mesh = BoxMesh.new()
	gd_mesh.size = Vector3(0.018, 0.04, 0.065)
	guard.mesh = gd_mesh
	guard.material_override = mat_metal
	guard.position = Vector3(0, -0.045, 0.02)
	root.add_child(guard)
	
	var trig = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(0.008, 0.024, 0.012)
	trig.mesh = tr_mesh
	trig.material_override = mat_metal
	trig.position = Vector3(0, -0.042, 0.025)
	trig.rotation.x = deg_to_rad(-18)
	root.add_child(trig)
	
	var mag_latch = MeshInstance3D.new()
	var ml_m = BoxMesh.new()
	ml_m.size = Vector3(0.012, 0.024, 0.008)
	mag_latch.mesh = ml_m
	mag_latch.material_override = mat_metal
	mag_latch.position = Vector3(0, -0.035, -0.018)
	root.add_child(mag_latch)
	
	# 18. Detailed Curved Steel Magazine (Authentic forward curve towards muzzle)
	var mag_node = Node3D.new()
	mag_node.position = Vector3(0, -0.12, -0.07)
	mag_node.rotation.x = deg_to_rad(22.0)
	root.add_child(mag_node)
	
	var mag_body = MeshInstance3D.new()
	var mb_mesh = BoxMesh.new()
	mb_mesh.size = Vector3(0.036, 0.19, 0.09)
	mag_body.mesh = mb_mesh
	mag_body.material_override = mat_mag
	mag_node.add_child(mag_body)
	
	# Magazine Base Plate (Steel)
	var mag_base = MeshInstance3D.new()
	var b_base_mesh = BoxMesh.new()
	b_base_mesh.size = Vector3(0.040, 0.012, 0.096)
	mag_base.mesh = b_base_mesh
	mag_base.material_override = mat_metal
	mag_base.position = Vector3(0, -0.096, 0)
	mag_node.add_child(mag_base)
	
	# Magazine Strengthening Ribs
	var mag_rib1 = MeshInstance3D.new()
	var mr_mesh = BoxMesh.new()
	mr_mesh.size = Vector3(0.038, 0.008, 0.086)
	mag_rib1.mesh = mr_mesh
	mag_rib1.material_override = mat_mag
	mag_rib1.position = Vector3(0, -0.03, 0)
	mag_node.add_child(mag_rib1)
	
	var mag_rib2 = MeshInstance3D.new()
	mag_rib2.mesh = mr_mesh
	mag_rib2.material_override = mat_mag
	mag_rib2.position = Vector3(0, 0.03, 0)
	mag_node.add_child(mag_rib2)
	
	return root

func create_shotgun_preview() -> Node3D:
	var root = Node3D.new()
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.18, 0.19, 0.22)
	mat_metal.metallic = 0.8
	mat_metal.roughness = 0.35
	
	var mat_recess = StandardMaterial3D.new()
	mat_recess.albedo_color = Color(0.06, 0.07, 0.08)
	mat_recess.metallic = 0.5
	mat_recess.roughness = 0.6
	
	var mat_bolt = StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.72, 0.74, 0.78)
	mat_bolt.metallic = 0.95
	mat_bolt.roughness = 0.18
	
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.38, 0.2, 0.1)
	mat_wood.roughness = 0.7
	
	var mat_rubber = StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.08, 0.08, 0.09)
	mat_rubber.roughness = 0.85
	
	var mat_bead = StandardMaterial3D.new()
	mat_bead.albedo_color = Color(0.9, 0.75, 0.25)
	mat_bead.metallic = 0.9
	mat_bead.roughness = 0.2
	
	# 1. Receiver
	var rec = MeshInstance3D.new()
	var rec_mesh = BoxMesh.new()
	rec_mesh.size = Vector3(0.066, 0.095, 0.30)
	rec.mesh = rec_mesh
	rec.material_override = mat_metal
	root.add_child(rec)
	
	# 2. Ejection Port (Right side)
	var ep = MeshInstance3D.new()
	var ep_mesh = BoxMesh.new()
	ep_mesh.size = Vector3(0.015, 0.042, 0.12)
	ep.mesh = ep_mesh
	ep.material_override = mat_recess
	ep.position = Vector3(0.034, 0.02, -0.04)
	root.add_child(ep)
	
	# 3. Steel Bolt inside port
	var bolt = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.018, 0.038, 0.10)
	bolt.mesh = b_mesh
	bolt.material_override = mat_bolt
	bolt.position = Vector3(0.032, 0.02, -0.04)
	root.add_child(bolt)
	
	# 4. Loading Elevator Gate (Bottom)
	var elev = MeshInstance3D.new()
	var el_mesh = BoxMesh.new()
	el_mesh.size = Vector3(0.045, 0.012, 0.12)
	elev.mesh = el_mesh
	elev.material_override = mat_bolt
	elev.position = Vector3(0, -0.045, -0.06)
	root.add_child(elev)
	
	# 5. Trigger Guard & Trigger
	var tg = MeshInstance3D.new()
	var tg_mesh = BoxMesh.new()
	tg_mesh.size = Vector3(0.02, 0.045, 0.07)
	tg.mesh = tg_mesh
	tg.material_override = mat_metal
	tg.position = Vector3(0, -0.06, 0.06)
	root.add_child(tg)
	
	var tr = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(0.008, 0.026, 0.014)
	tr.mesh = tr_mesh
	tr.material_override = mat_bolt
	tr.position = Vector3(0, -0.055, 0.065)
	tr.rotation.x = deg_to_rad(-18)
	root.add_child(tr)
	
	# 6. Barrel
	var barrel = MeshInstance3D.new()
	var bar_mesh = CylinderMesh.new()
	bar_mesh.top_radius = 0.018
	bar_mesh.bottom_radius = 0.018
	bar_mesh.height = 0.48
	barrel.mesh = bar_mesh
	barrel.material_override = mat_metal
	barrel.rotation.x = deg_to_rad(90)
	barrel.position = Vector3(0, 0.03, -0.36)
	root.add_child(barrel)
	
	# 7. Ventilated Sight Rib
	var rib = MeshInstance3D.new()
	var rib_mesh = BoxMesh.new()
	rib_mesh.size = Vector3(0.016, 0.012, 0.46)
	rib.mesh = rib_mesh
	rib.material_override = mat_metal
	rib.position = Vector3(0, 0.052, -0.36)
	root.add_child(rib)
	
	# 8. Brass Bead Sight
	var bead = MeshInstance3D.new()
	var bead_mesh = SphereMesh.new()
	bead_mesh.radius = 0.005
	bead_mesh.height = 0.01
	bead.mesh = bead_mesh
	bead.material_override = mat_bead
	bead.position = Vector3(0, 0.06, -0.58)
	root.add_child(bead)
	
	# 9. Magazine Tube
	var tube = MeshInstance3D.new()
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.015
	t_mesh.bottom_radius = 0.015
	t_mesh.height = 0.42
	tube.mesh = t_mesh
	tube.material_override = mat_metal
	tube.rotation.x = deg_to_rad(90)
	tube.position = Vector3(0, -0.015, -0.33)
	root.add_child(tube)
	
	# 10. Magazine Cap
	var cap = MeshInstance3D.new()
	var cap_mesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.018
	cap_mesh.bottom_radius = 0.018
	cap_mesh.height = 0.03
	cap.mesh = cap_mesh
	cap.material_override = mat_metal
	cap.rotation.x = deg_to_rad(90)
	cap.position = Vector3(0, -0.015, -0.54)
	root.add_child(cap)
	
	# 11. Barrel & Tube Clamp
	var clamp_node = MeshInstance3D.new()
	var cl_mesh = BoxMesh.new()
	cl_mesh.size = Vector3(0.042, 0.065, 0.025)
	clamp_node.mesh = cl_mesh
	clamp_node.material_override = mat_metal
	clamp_node.position = Vector3(0, 0.008, -0.48)
	root.add_child(clamp_node)
	
	# 12. Ribbed Pump Forend
	var pump = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.072, 0.075, 0.16)
	pump.mesh = p_mesh
	pump.material_override = mat_wood
	pump.position = Vector3(0, -0.015, -0.28)
	root.add_child(pump)
	
	for rib_z in [-0.04, 0.0, 0.04]:
		var pr = MeshInstance3D.new()
		var pr_mesh = BoxMesh.new()
		pr_mesh.size = Vector3(0.076, 0.078, 0.014)
		pr.mesh = pr_mesh
		pr.material_override = mat_wood
		pr.position = Vector3(0, 0, rib_z)
		pump.add_child(pr)
	
	# 13. Wood Stock & Rubber Recoil Pad
	var stock = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.055, 0.115, 0.26)
	stock.mesh = s_mesh
	stock.material_override = mat_wood
	stock.position = Vector3(0, -0.05, 0.25)
	stock.rotation.x = deg_to_rad(10)
	root.add_child(stock)
	
	var pad = MeshInstance3D.new()
	var pad_mesh = BoxMesh.new()
	pad_mesh.size = Vector3(0.058, 0.122, 0.035)
	pad.mesh = pad_mesh
	pad.material_override = mat_rubber
	pad.position = Vector3(0, 0, 0.13)
	stock.add_child(pad)
	
	return root

func create_pistol_preview() -> Node3D:
	var root = Node3D.new()
	var mat_slide = StandardMaterial3D.new()
	mat_slide.albedo_color = Color(0.2, 0.21, 0.24)
	mat_slide.metallic = 0.88
	mat_slide.roughness = 0.25
	
	var mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.11, 0.12, 0.14)
	mat_frame.metallic = 0.35
	mat_frame.roughness = 0.65
	
	var mat_recess = StandardMaterial3D.new()
	mat_recess.albedo_color = Color(0.05, 0.06, 0.07)
	mat_recess.metallic = 0.5
	mat_recess.roughness = 0.6
	
	var mat_dots = StandardMaterial3D.new()
	mat_dots.shading_mode = 0
	mat_dots.albedo_color = Color(0.96, 0.96, 0.96)
	
	var mat_barrel = StandardMaterial3D.new()
	mat_barrel.albedo_color = Color(0.16, 0.17, 0.2)
	mat_barrel.metallic = 0.9
	mat_barrel.roughness = 0.2
	
	# 1. Slide
	var slide = MeshInstance3D.new()
	var sl_mesh = BoxMesh.new()
	sl_mesh.size = Vector3(0.040, 0.038, 0.198)
	slide.mesh = sl_mesh
	slide.material_override = mat_slide
	slide.position = Vector3(0, 0.021, 0)
	root.add_child(slide)
	
	# Ejection Port
	var ep = MeshInstance3D.new()
	var ep_mesh = BoxMesh.new()
	ep_mesh.size = Vector3(0.008, 0.018, 0.052)
	ep.mesh = ep_mesh
	ep.material_override = mat_recess
	ep.position = Vector3(0.019, 0.016, 0.010)
	slide.add_child(ep)
	
	# Slide Serrations (Rear & Front)
	for s_z in [0.06, 0.045, -0.06]:
		var ser = MeshInstance3D.new()
		var ser_mesh = BoxMesh.new()
		ser_mesh.size = Vector3(0.042, 0.034, 0.006)
		ser.mesh = ser_mesh
		ser.material_override = mat_recess
		ser.position = Vector3(0, 0.004, s_z)
		slide.add_child(ser)
		
	# Rear Sight with Dual Green Dots
	var rs = MeshInstance3D.new()
	var rs_mesh = BoxMesh.new()
	rs_mesh.size = Vector3(0.032, 0.018, 0.016)
	rs.mesh = rs_mesh
	rs.material_override = mat_slide
	rs.position = Vector3(0, 0.032, 0.085)
	slide.add_child(rs)
	
	for d_x in [-0.01, 0.01]:
		var dot = MeshInstance3D.new()
		var dot_mesh = BoxMesh.new()
		dot_mesh.size = Vector3(0.004, 0.004, 0.004)
		dot.mesh = dot_mesh
		dot.material_override = mat_dots
		dot.position = Vector3(d_x, 0.003, 0.008)
		rs.add_child(dot)
		
	# Front Sight with Green Dot
	var fs = MeshInstance3D.new()
	var fs_mesh = BoxMesh.new()
	fs_mesh.size = Vector3(0.012, 0.016, 0.018)
	fs.mesh = fs_mesh
	fs.material_override = mat_slide
	fs.position = Vector3(0, 0.032, -0.085)
	slide.add_child(fs)
	
	var fdot = MeshInstance3D.new()
	var fdot_mesh = BoxMesh.new()
	fdot_mesh.size = Vector3(0.004, 0.004, 0.004)
	fdot.mesh = fdot_mesh
	fdot.material_override = mat_dots
	fdot.position = Vector3(0, 0.003, 0.008)
	fs.add_child(fdot)
	
	# 2. Frame & Chamber Block (Clean separation, zero Z-fighting)
	var frame = MeshInstance3D.new()
	var fr_mesh = BoxMesh.new()
	fr_mesh.size = Vector3(0.038, 0.022, 0.176)
	frame.mesh = fr_mesh
	frame.material_override = mat_frame
	frame.position = Vector3(0, -0.012, 0.006)
	root.add_child(frame)
	
	var chamber = MeshInstance3D.new()
	var ch_mesh = BoxMesh.new()
	ch_mesh.size = Vector3(0.032, 0.024, 0.046)
	chamber.mesh = ch_mesh
	chamber.material_override = mat_barrel
	chamber.position = Vector3(0, 0.026, 0.012)
	frame.add_child(chamber)
	
	var btip = MeshInstance3D.new()
	var bt_mesh = CylinderMesh.new()
	bt_mesh.top_radius = 0.011
	bt_mesh.bottom_radius = 0.011
	bt_mesh.height = 0.03
	btip.mesh = bt_mesh
	btip.material_override = mat_barrel
	btip.rotation.x = deg_to_rad(90)
	btip.position = Vector3(0, 0.033, -0.115)
	frame.add_child(btip)
	
	# Picatinny Rail
	var rail = MeshInstance3D.new()
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(0.036, 0.010, 0.075)
	rail.mesh = rail_mesh
	rail.material_override = mat_frame
	rail.position = Vector3(0, -0.018, -0.045)
	frame.add_child(rail)
	
	# Combat Trigger Guard & Trigger
	var tg = MeshInstance3D.new()
	var tg_mesh = BoxMesh.new()
	tg_mesh.size = Vector3(0.016, 0.036, 0.058)
	tg.mesh = tg_mesh
	tg.material_override = mat_frame
	tg.position = Vector3(0, -0.024, -0.015)
	frame.add_child(tg)
	
	var tr = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(0.008, 0.024, 0.012)
	tr.mesh = tr_mesh
	tr.material_override = mat_slide
	tr.position = Vector3(0, -0.020, 0.002)
	tr.rotation.x = deg_to_rad(-18)
	frame.add_child(tr)
	
	# Safe Action Trigger Central Safety Blade (Red)
	var mat_safety = StandardMaterial3D.new()
	mat_safety.albedo_color = Color(0.85, 0.15, 0.12)
	mat_safety.roughness = 0.6
	var tr_safe = MeshInstance3D.new()
	var trs_m = BoxMesh.new()
	trs_m.size = Vector3(0.004, 0.016, 0.006)
	tr_safe.mesh = trs_m
	tr_safe.material_override = mat_safety
	tr_safe.position = Vector3(0, -0.002, -0.006)
	tr.add_child(tr_safe)
	
	# Takedown Catch (Ambidextrous frame lock)
	var td = MeshInstance3D.new()
	var td_m = BoxMesh.new()
	td_m.size = Vector3(0.042, 0.006, 0.008)
	td.mesh = td_m
	td.material_override = mat_slide
	td.position = Vector3(0, 0.006, -0.02)
	frame.add_child(td)
	
	# Slide Stop Release Lever
	var s_rel = MeshInstance3D.new()
	var sr_mesh = BoxMesh.new()
	sr_mesh.size = Vector3(0.004, 0.008, 0.020)
	s_rel.mesh = sr_mesh
	s_rel.material_override = mat_slide
	s_rel.position = Vector3(-0.020, 0.015, 0.030)
	frame.add_child(s_rel)
	
	# 3. Grip & Magazine with Extended Bumper Pad (Authentic backward Glock slant)
	var grip = MeshInstance3D.new()
	var gr_mesh = BoxMesh.new()
	gr_mesh.size = Vector3(0.034, 0.12, 0.058)
	grip.mesh = gr_mesh
	grip.material_override = mat_frame
	grip.position = Vector3(0, -0.08, 0.045)
	grip.rotation.x = deg_to_rad(-22.0)
	root.add_child(grip)
	
	# Gen 4 Ergonomic Finger Grooves on front strap
	for fg_y in [-0.015, -0.045]:
		var fg = MeshInstance3D.new()
		var fg_m = BoxMesh.new()
		fg_m.size = Vector3(0.030, 0.010, 0.006)
		fg.mesh = fg_m
		fg.material_override = mat_frame
		fg.position = Vector3(0, fg_y, -0.030)
		grip.add_child(fg)
	
	var mag_node = Node3D.new()
	mag_node.position = Vector3(0, -0.08, 0.045)
	mag_node.rotation.x = deg_to_rad(-22.0)
	root.add_child(mag_node)
	
	var mag_body = MeshInstance3D.new()
	var mb_mesh = BoxMesh.new()
	mb_mesh.size = Vector3(0.026, 0.11, 0.042)
	mag_body.mesh = mb_mesh
	mag_body.material_override = mat_slide
	mag_node.add_child(mag_body)
	
	var bumper = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.036, 0.016, 0.060)
	bumper.mesh = b_mesh
	bumper.material_override = mat_frame
	bumper.position = Vector3(0, -0.065, 0.004)
	mag_node.add_child(bumper)
	
	return root

func create_crewmate_preview(color: Color, enemy_type: int = 0) -> Node3D:
	var root = Node3D.new()
	root.position = Vector3(0, -0.86, 0)
	
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = color
	mat_body.roughness = 0.35
	
	var mat_visor = StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.45, 0.85, 0.95)
	mat_visor.metallic = 0.5
	mat_visor.roughness = 0.1
	
	# Body Capsule
	var body = MeshInstance3D.new()
	var b_mesh = CapsuleMesh.new()
	b_mesh.radius = 0.44
	b_mesh.height = 1.45
	body.mesh = b_mesh
	body.material_override = mat_body
	body.position = Vector3(0, 0.95, 0)
	root.add_child(body)
	
	# Visor
	var visor = MeshInstance3D.new()
	var v_mesh = BoxMesh.new()
	v_mesh.size = Vector3(0.52, 0.28, 0.24)
	visor.mesh = v_mesh
	visor.material_override = mat_visor
	visor.position = Vector3(0, 1.18, 0.36)
	root.add_child(visor)
	
	# Backpack
	var bp = MeshInstance3D.new()
	var bp_mesh = BoxMesh.new()
	bp_mesh.size = Vector3(0.52, 0.78, 0.3)
	bp.mesh = bp_mesh
	bp.material_override = mat_body
	bp.position = Vector3(0, 0.95, -0.38)
	root.add_child(bp)
	
	# Legs
	var leg_l = MeshInstance3D.new()
	var leg_mesh = CapsuleMesh.new()
	leg_mesh.radius = 0.16
	leg_mesh.height = 0.55
	leg_l.mesh = leg_mesh
	leg_l.material_override = mat_body
	leg_l.position = Vector3(-0.25, 0.32, 0)
	root.add_child(leg_l)
	
	var leg_r = MeshInstance3D.new()
	leg_r.mesh = leg_mesh
	leg_r.material_override = mat_body
	leg_r.position = Vector3(0.25, 0.32, 0)
	root.add_child(leg_r)
	
	# Equip respective weapon
	var weapon_mount = Node3D.new()
	weapon_mount.position = Vector3(0.52, 0.85, 0.22)
	root.add_child(weapon_mount)
	
	match enemy_type:
		0: # Red: AK-47
			equip_preview_ak(weapon_mount)
		1: # Blue: Pistol
			equip_preview_pistol(weapon_mount)
		2: # Yellow: Axe
			equip_preview_axe(weapon_mount)
		3: # Green: AWP Sniper Rifle
			equip_preview_awp(weapon_mount)
	
	return root

func equip_preview_ak(parent: Node3D) -> void:
	var mat_m = StandardMaterial3D.new()
	mat_m.albedo_color = Color(0.18, 0.19, 0.22)
	mat_m.metallic = 0.85
	
	var mat_w = StandardMaterial3D.new()
	mat_w.albedo_color = Color(0.48, 0.22, 0.1)
	
	var mat_mag = StandardMaterial3D.new()
	mat_mag.albedo_color = Color(0.68, 0.3, 0.12)
	
	var rec = MeshInstance3D.new()
	var rec_m = BoxMesh.new()
	rec_m.size = Vector3(0.08, 0.1, 0.38)
	rec.mesh = rec_m
	rec.material_override = mat_m
	parent.add_child(rec)
	
	var bar = MeshInstance3D.new()
	var bar_m = CylinderMesh.new()
	bar_m.top_radius = 0.02
	bar_m.bottom_radius = 0.02
	bar_m.height = 0.38
	bar.mesh = bar_m
	bar.material_override = mat_m
	bar.rotation.x = deg_to_rad(90.0)
	bar.position = Vector3(0, 0.02, 0.35)
	parent.add_child(bar)
	
	var hg = MeshInstance3D.new()
	var hg_m = BoxMesh.new()
	hg_m.size = Vector3(0.085, 0.09, 0.2)
	hg.mesh = hg_m
	hg.material_override = mat_w
	hg.position = Vector3(0, 0, 0.22)
	parent.add_child(hg)
	
	var st = MeshInstance3D.new()
	var st_m = BoxMesh.new()
	st_m.size = Vector3(0.07, 0.12, 0.26)
	st.mesh = st_m
	st.material_override = mat_w
	st.position = Vector3(0, -0.02, -0.28)
	parent.add_child(st)
	
	var mag = MeshInstance3D.new()
	var mag_m = BoxMesh.new()
	mag_m.size = Vector3(0.05, 0.22, 0.1)
	mag.mesh = mag_m
	mag.material_override = mat_mag
	mag.position = Vector3(0, -0.14, 0.08)
	mag.rotation.x = deg_to_rad(16.0)
	parent.add_child(mag)

func equip_preview_pistol(parent: Node3D) -> void:
	var mat_s = StandardMaterial3D.new()
	mat_s.albedo_color = Color(0.2, 0.22, 0.26)
	mat_s.metallic = 0.8
	
	var mat_f = StandardMaterial3D.new()
	mat_f.albedo_color = Color(0.1, 0.11, 0.12)
	
	var slide = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.065, 0.06, 0.28)
	slide.mesh = sm
	slide.material_override = mat_s
	parent.add_child(slide)
	
	var grip = MeshInstance3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(0.058, 0.16, 0.085)
	grip.mesh = gm
	grip.material_override = mat_f
	grip.position = Vector3(0, -0.09, -0.06)
	grip.rotation.x = deg_to_rad(-14.0)
	parent.add_child(grip)

func equip_preview_axe(parent: Node3D) -> void:
	# Authentic Pickhead Fire Axe materials
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.96, 0.78, 0.08) # Fiberglass bright yellow
	mat_yellow.roughness = 0.28
	mat_yellow.metallic = 0.08
	
	var mat_black_grip = StandardMaterial3D.new()
	mat_black_grip.albedo_color = Color(0.11, 0.12, 0.14) # Textured black rubber grip
	mat_black_grip.roughness = 0.88
	mat_black_grip.metallic = 0.02
	
	var mat_fire_red = StandardMaterial3D.new()
	mat_fire_red.albedo_color = Color(0.82, 0.09, 0.09) # Fire rescue red paint
	mat_fire_red.roughness = 0.35
	mat_fire_red.metallic = 0.35
	
	var mat_steel = StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.88, 0.91, 0.94) # Sharpened cutting edge and pick tip
	mat_steel.metallic = 0.98
	mat_steel.roughness = 0.15

	# Axe Root container tilted at carrying/chopping angle
	var axe_root = Node3D.new()
	axe_root.rotation.x = deg_to_rad(65.0)
	parent.add_child(axe_root)

	# 1. Lower Black Rubber Grip (middle-to-bottom of shaft)
	var grip = MeshInstance3D.new()
	var g_m = CylinderMesh.new()
	g_m.top_radius = 0.023
	g_m.bottom_radius = 0.021
	g_m.height = 0.52
	grip.mesh = g_m
	grip.material_override = mat_black_grip
	grip.position = Vector3(0, -0.16, 0)
	axe_root.add_child(grip)

	# 2. Ergonomic Fawn-Foot Butt / Knob at bottom of handle
	var butt = MeshInstance3D.new()
	var bu_m = BoxMesh.new()
	bu_m.size = Vector3(0.040, 0.07, 0.065)
	butt.mesh = bu_m
	butt.material_override = mat_black_grip
	butt.position = Vector3(0, -0.42, 0.015)
	butt.rotation.x = deg_to_rad(15.0)
	axe_root.add_child(butt)

	# 3. Transition collar ring between grip and yellow fiberglass
	var ring = MeshInstance3D.new()
	var r_m = CylinderMesh.new()
	r_m.top_radius = 0.025
	r_m.bottom_radius = 0.025
	r_m.height = 0.02
	ring.mesh = r_m
	ring.material_override = mat_black_grip
	ring.position = Vector3(0, 0.11, 0)
	axe_root.add_child(ring)

	# 4. Upper Yellow Fiberglass Shaft
	var upper_shaft = MeshInstance3D.new()
	var us_m = CylinderMesh.new()
	us_m.top_radius = 0.027
	us_m.bottom_radius = 0.024
	us_m.height = 0.28
	upper_shaft.mesh = us_m
	upper_shaft.material_override = mat_yellow
	upper_shaft.position = Vector3(0, 0.25, 0)
	axe_root.add_child(upper_shaft)

	# 5. Ergonomic throat swell right beneath the head
	var throat = MeshInstance3D.new()
	var th_m = BoxMesh.new()
	th_m.size = Vector3(0.045, 0.06, 0.07)
	throat.mesh = th_m
	throat.material_override = mat_yellow
	throat.position = Vector3(0, 0.34, 0.005)
	axe_root.add_child(throat)

	# 6. Axe Head Center / Eye (Red painted steel sleeve)
	var eye = MeshInstance3D.new()
	var e_m = BoxMesh.new()
	e_m.size = Vector3(0.052, 0.095, 0.085)
	eye.mesh = e_m
	eye.material_override = mat_fire_red
	eye.position = Vector3(0, 0.40, 0)
	axe_root.add_child(eye)

	# 7. Top Eye Socket Cap / Wedge
	var cap = MeshInstance3D.new()
	var cap_m = BoxMesh.new()
	cap_m.size = Vector3(0.038, 0.008, 0.06)
	cap.mesh = cap_m
	cap.material_override = mat_steel
	cap.position = Vector3(0, 0.45, 0)
	axe_root.add_child(cap)

	# 8. Front Blade Body (Red)
	var blade_body = MeshInstance3D.new()
	var bb_m = BoxMesh.new()
	bb_m.size = Vector3(0.036, 0.135, 0.11)
	blade_body.mesh = bb_m
	blade_body.material_override = mat_fire_red
	blade_body.position = Vector3(0, 0.395, 0.085)
	axe_root.add_child(blade_body)

	# 9. Flared cutting bit wedge (Red)
	var blade_flare = MeshInstance3D.new()
	var bf_m = BoxMesh.new()
	bf_m.size = Vector3(0.024, 0.155, 0.055)
	blade_flare.mesh = bf_m
	blade_flare.material_override = mat_fire_red
	blade_flare.position = Vector3(0, 0.39, 0.145)
	axe_root.add_child(blade_flare)

	# 10. Front Sharpened Silver Steel Cutting Edge
	var cutting_edge = MeshInstance3D.new()
	var ce_m = BoxMesh.new()
	ce_m.size = Vector3(0.014, 0.175, 0.04)
	cutting_edge.mesh = ce_m
	cutting_edge.material_override = mat_steel
	cutting_edge.position = Vector3(0, 0.385, 0.185)
	axe_root.add_child(cutting_edge)

	# 11. Rear Pick Horn / Spike Base (Red)
	var pick_base = MeshInstance3D.new()
	var pb_m = BoxMesh.new()
	pb_m.size = Vector3(0.038, 0.065, 0.085)
	pick_base.mesh = pb_m
	pick_base.material_override = mat_fire_red
	pick_base.position = Vector3(0, 0.405, -0.075)
	axe_root.add_child(pick_base)

	# 12. Rear Pick Horn Curved Mid-Section (Red, curving slightly downward)
	var pick_mid = MeshInstance3D.new()
	var pm_m = BoxMesh.new()
	pm_m.size = Vector3(0.028, 0.048, 0.08)
	pick_mid.mesh = pm_m
	pick_mid.material_override = mat_fire_red
	pick_mid.position = Vector3(0, 0.39, -0.145)
	pick_mid.rotation.x = deg_to_rad(14.0)
	axe_root.add_child(pick_mid)

	# 13. Rear Pick Sharpened Steel Point Tip (Polished steel)
	var pick_tip = MeshInstance3D.new()
	var pt_m = PrismMesh.new()
	pt_m.size = Vector3(0.020, 0.055, 0.032)
	pick_tip.mesh = pt_m
	pick_tip.material_override = mat_steel
	pick_tip.position = Vector3(0, 0.375, -0.195)
	pick_tip.rotation.x = deg_to_rad(-90.0)
	axe_root.add_child(pick_tip)

func equip_preview_awp(parent: Node3D) -> void:
	# Authentic Accuracy International Arctic Warfare (AWP) materials
	var mat_awp_green = StandardMaterial3D.new()
	mat_awp_green.albedo_color = Color(0.24, 0.29, 0.20) # Authentic AI Olive Drab polymer
	mat_awp_green.roughness = 0.58
	mat_awp_green.metallic = 0.06
	
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.11, 0.12, 0.14) # Matte black steel
	mat_metal.metallic = 0.90
	mat_metal.roughness = 0.24
	
	var mat_rubber = StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.07, 0.07, 0.08) # Black rubber pad & cheek rest
	mat_rubber.roughness = 0.92
	mat_rubber.metallic = 0.02
	
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.12, 0.25, 0.28, 0.85)
	mat_glass.metallic = 0.5
	mat_glass.roughness = 0.08

	# --- 1. AWP THUMBHOLE CHASSIS & STOCK ---
	# Forend (long front stock)
	var forend = MeshInstance3D.new()
	var fe_m = BoxMesh.new()
	fe_m.size = Vector3(0.068, 0.085, 0.56)
	forend.mesh = fe_m
	forend.material_override = mat_awp_green
	forend.position = Vector3(0, -0.015, 0.32)
	parent.add_child(forend)

	# Receiver Lower Housing
	var mid_chassis = MeshInstance3D.new()
	var mc_m = BoxMesh.new()
	mc_m.size = Vector3(0.068, 0.08, 0.22)
	mid_chassis.mesh = mc_m
	mid_chassis.material_override = mat_awp_green
	mid_chassis.position = Vector3(0, -0.01, -0.04)
	parent.add_child(mid_chassis)

	# Pistol Grip (front of thumbhole)
	var grip = MeshInstance3D.new()
	var gr_m = BoxMesh.new()
	gr_m.size = Vector3(0.058, 0.13, 0.07)
	grip.mesh = gr_m
	grip.material_override = mat_awp_green
	grip.position = Vector3(0, -0.09, -0.14)
	grip.rotation.x = deg_to_rad(-16.0)
	parent.add_child(grip)

	# Upper Stock Comb (bridge above thumbhole)
	var comb = MeshInstance3D.new()
	var co_m = BoxMesh.new()
	co_m.size = Vector3(0.056, 0.042, 0.24)
	comb.mesh = co_m
	comb.material_override = mat_awp_green
	comb.position = Vector3(0, 0.005, -0.27)
	parent.add_child(comb)

	# Lower Stock Connecting Bar (below thumbhole)
	var lower_bar = MeshInstance3D.new()
	var lb_m = BoxMesh.new()
	lb_m.size = Vector3(0.052, 0.034, 0.20)
	lower_bar.mesh = lb_m
	lower_bar.material_override = mat_awp_green
	lower_bar.position = Vector3(0, -0.155, -0.25)
	parent.add_child(lower_bar)

	# Rear Buttstock Block (behind thumbhole)
	var buttstock = MeshInstance3D.new()
	var bs_m = BoxMesh.new()
	bs_m.size = Vector3(0.062, 0.145, 0.14)
	buttstock.mesh = bs_m
	buttstock.material_override = mat_awp_green
	buttstock.position = Vector3(0, -0.07, -0.37)
	parent.add_child(buttstock)

	# Adjustable Black Cheek Rest
	var cheek_rest = MeshInstance3D.new()
	var cr_m = BoxMesh.new()
	cr_m.size = Vector3(0.064, 0.032, 0.15)
	cheek_rest.mesh = cr_m
	cheek_rest.material_override = mat_rubber
	cheek_rest.position = Vector3(0, 0.032, -0.28)
	parent.add_child(cheek_rest)

	# Thick Black Recoil Buttpad
	var buttpad = MeshInstance3D.new()
	var bp_m = BoxMesh.new()
	bp_m.size = Vector3(0.066, 0.155, 0.04)
	buttpad.mesh = bp_m
	buttpad.material_override = mat_rubber
	buttpad.position = Vector3(0, -0.07, -0.45)
	parent.add_child(buttpad)

	# --- 2. RECEIVER, BOLT & MAGAZINE ---
	# Steel Receiver
	var receiver = MeshInstance3D.new()
	var rec_m = BoxMesh.new()
	rec_m.size = Vector3(0.064, 0.065, 0.34)
	receiver.mesh = rec_m
	receiver.material_override = mat_metal
	receiver.position = Vector3(0, 0.042, 0.06)
	parent.add_child(receiver)

	# Ejection Port (Right side)
	var eject_port = MeshInstance3D.new()
	var ep_m = BoxMesh.new()
	ep_m.size = Vector3(0.016, 0.028, 0.09)
	eject_port.mesh = ep_m
	eject_port.material_override = mat_metal
	eject_port.position = Vector3(0.028, 0.052, 0.08)
	parent.add_child(eject_port)

	# Cylindrical Bolt Shroud
	var bolt = MeshInstance3D.new()
	var bo_m = CylinderMesh.new()
	bo_m.top_radius = 0.014
	bo_m.bottom_radius = 0.014
	bo_m.height = 0.16
	bolt.mesh = bo_m
	bolt.material_override = mat_metal
	bolt.rotation.x = deg_to_rad(90.0)
	bolt.position = Vector3(0, 0.052, -0.11)
	parent.add_child(bolt)

	# Bolt Handle (Curved stem to the right)
	var bolt_stem = MeshInstance3D.new()
	var bs_stem_m = CylinderMesh.new()
	bs_stem_m.top_radius = 0.005
	bs_stem_m.bottom_radius = 0.005
	bs_stem_m.height = 0.06
	bolt_stem.mesh = bs_stem_m
	bolt_stem.material_override = mat_metal
	bolt_stem.rotation.z = deg_to_rad(45.0)
	bolt_stem.position = Vector3(0.045, 0.042, -0.07)
	parent.add_child(bolt_stem)

	# Round Ball Bolt Knob
	var bolt_knob = MeshInstance3D.new()
	var bk_m = SphereMesh.new()
	bk_m.radius = 0.012
	bk_m.height = 0.024
	bolt_knob.mesh = bk_m
	bolt_knob.material_override = mat_metal
	bolt_knob.position = Vector3(0.075, 0.025, -0.07)
	parent.add_child(bolt_knob)

	# Detachable Box Magazine
	var mag = MeshInstance3D.new()
	var mag_m = BoxMesh.new()
	mag_m.size = Vector3(0.046, 0.08, 0.10)
	mag.mesh = mag_m
	mag.material_override = mat_metal
	mag.position = Vector3(0, -0.07, 0.03)
	parent.add_child(mag)

	# Trigger Guard & Trigger
	var tg = MeshInstance3D.new()
	var tg_m = BoxMesh.new()
	tg_m.size = Vector3(0.02, 0.042, 0.065)
	tg.mesh = tg_m
	tg.material_override = mat_metal
	tg.position = Vector3(0, -0.075, -0.08)
	parent.add_child(tg)

	var trg = MeshInstance3D.new()
	var trg_m = BoxMesh.new()
	trg_m.size = Vector3(0.008, 0.024, 0.012)
	trg.mesh = trg_m
	trg.material_override = mat_metal
	trg.position = Vector3(0, -0.07, -0.07)
	parent.add_child(trg)

	# --- 3. BARREL & DUAL-CHAMBER MUZZLE BRAKE ---
	# Free-floating heavy steel barrel
	var barrel = MeshInstance3D.new()
	var bar_m = CylinderMesh.new()
	bar_m.top_radius = 0.018
	bar_m.bottom_radius = 0.022
	bar_m.height = 0.78
	barrel.mesh = bar_m
	barrel.material_override = mat_metal
	barrel.rotation.x = deg_to_rad(90.0)
	barrel.position = Vector3(0, 0.045, 0.62)
	parent.add_child(barrel)

	# Signature AWP Muzzle Brake
	var mb = MeshInstance3D.new()
	var mb_m = BoxMesh.new()
	mb_m.size = Vector3(0.046, 0.042, 0.095)
	mb.mesh = mb_m
	mb.material_override = mat_metal
	mb.position = Vector3(0, 0.045, 1.055)
	parent.add_child(mb)

	# Muzzle side vent cutouts
	var mb_ports = MeshInstance3D.new()
	var mb_p_m = BoxMesh.new()
	mb_p_m.size = Vector3(0.048, 0.024, 0.035)
	mb_ports.mesh = mb_p_m
	mb_ports.material_override = mat_metal
	mb_ports.position = Vector3(0, 0.045, 1.055)
	parent.add_child(mb_ports)

	# --- 4. FOLDED BIPOD (Under forend) ---
	var bipod_mount = MeshInstance3D.new()
	var bm_m = BoxMesh.new()
	bm_m.size = Vector3(0.04, 0.03, 0.05)
	bipod_mount.mesh = bm_m
	bipod_mount.material_override = mat_metal
	bipod_mount.position = Vector3(0, -0.055, 0.52)
	parent.add_child(bipod_mount)

	for x_side in [-0.028, 0.028]:
		var leg = MeshInstance3D.new()
		var leg_m = CylinderMesh.new()
		leg_m.top_radius = 0.006
		leg_m.bottom_radius = 0.006
		leg_m.height = 0.22
		leg.mesh = leg_m
		leg.material_override = mat_metal
		leg.rotation.x = deg_to_rad(90.0)
		leg.position = Vector3(x_side, -0.065, 0.42)
		parent.add_child(leg)

	# --- 5. TELESCOPIC OPTICAL SNIPER SCOPE ---
	# Mounting rings onto Picatinny rail
	for z_ring in [-0.04, 0.16]:
		var ring = MeshInstance3D.new()
		var rng_m = BoxMesh.new()
		rng_m.size = Vector3(0.048, 0.055, 0.022)
		ring.mesh = rng_m
		ring.material_override = mat_metal
		ring.position = Vector3(0, 0.095, z_ring)
		parent.add_child(ring)

	# Main scope tube
	var scope_tube = MeshInstance3D.new()
	var st_m = CylinderMesh.new()
	st_m.top_radius = 0.022
	st_m.bottom_radius = 0.022
	st_m.height = 0.24
	scope_tube.mesh = st_m
	scope_tube.material_override = mat_metal
	scope_tube.rotation.x = deg_to_rad(90.0)
	scope_tube.position = Vector3(0, 0.125, 0.06)
	parent.add_child(scope_tube)

	# Top Elevation Turret
	var elev_turret = MeshInstance3D.new()
	var et_m = CylinderMesh.new()
	et_m.top_radius = 0.014
	et_m.bottom_radius = 0.014
	et_m.height = 0.022
	elev_turret.mesh = et_m
	elev_turret.material_override = mat_metal
	elev_turret.position = Vector3(0, 0.155, 0.06)
	parent.add_child(elev_turret)

	# Right Windage Turret
	var wind_turret = MeshInstance3D.new()
	var wt_m = CylinderMesh.new()
	wt_m.top_radius = 0.014
	wt_m.bottom_radius = 0.014
	wt_m.height = 0.022
	wind_turret.mesh = wt_m
	wind_turret.material_override = mat_metal
	wind_turret.rotation.z = deg_to_rad(90.0)
	wind_turret.position = Vector3(0.032, 0.125, 0.06)
	parent.add_child(wind_turret)

	# Front Objective Bell (large cone expanding forward)
	var obj_bell = MeshInstance3D.new()
	var ob_m = CylinderMesh.new()
	ob_m.top_radius = 0.034
	ob_m.bottom_radius = 0.024
	ob_m.height = 0.08
	obj_bell.mesh = ob_m
	obj_bell.material_override = mat_metal
	obj_bell.rotation.x = deg_to_rad(90.0)
	obj_bell.position = Vector3(0, 0.125, 0.21)
	parent.add_child(obj_bell)

	# Front Sunshade / Lens Hood
	var sunshade = MeshInstance3D.new()
	var ss_m = CylinderMesh.new()
	ss_m.top_radius = 0.035
	ss_m.bottom_radius = 0.035
	ss_m.height = 0.04
	sunshade.mesh = ss_m
	sunshade.material_override = mat_metal
	sunshade.rotation.x = deg_to_rad(90.0)
	sunshade.position = Vector3(0, 0.125, 0.26)
	parent.add_child(sunshade)

	# Front Objective Lens Glass
	var lens = MeshInstance3D.new()
	var len_m = CylinderMesh.new()
	len_m.top_radius = 0.032
	len_m.bottom_radius = 0.032
	len_m.height = 0.005
	lens.mesh = len_m
	lens.material_override = mat_glass
	lens.rotation.x = deg_to_rad(90.0)
	lens.position = Vector3(0, 0.125, 0.27)
	parent.add_child(lens)

	# Rear Ocular Bell / Eyepiece
	var ocular = MeshInstance3D.new()
	var oc_m = CylinderMesh.new()
	oc_m.top_radius = 0.028
	oc_m.bottom_radius = 0.022
	oc_m.height = 0.07
	ocular.mesh = oc_m
	ocular.material_override = mat_metal
	ocular.rotation.x = deg_to_rad(90.0)
	ocular.position = Vector3(0, 0.125, -0.09)
	parent.add_child(ocular)

	# Rubber Eyecup
	var eyecup = MeshInstance3D.new()
	var ec_m = CylinderMesh.new()
	ec_m.top_radius = 0.030
	ec_m.bottom_radius = 0.030
	ec_m.height = 0.025
	eyecup.mesh = ec_m
	eyecup.material_override = mat_rubber
	eyecup.rotation.x = deg_to_rad(90.0)
	eyecup.position = Vector3(0, 0.125, -0.13)
	parent.add_child(eyecup)

func create_armor_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_vest = StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.12, 0.16, 0.24)
	mat_vest.roughness = 0.65
	
	var mat_plate = StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.22, 0.26, 0.35)
	mat_plate.metallic = 0.65
	mat_plate.roughness = 0.3
	
	var mat_pouch = StandardMaterial3D.new()
	mat_pouch.albedo_color = Color(0.1, 0.13, 0.18)
	mat_pouch.roughness = 0.8
	
	var mat_strap = StandardMaterial3D.new()
	mat_strap.albedo_color = Color(0.08, 0.09, 0.12)
	mat_strap.roughness = 0.9
	
	# Main Torso Vest
	var torso = MeshInstance3D.new()
	var t_m = BoxMesh.new()
	t_m.size = Vector3(0.36, 0.44, 0.18)
	torso.mesh = t_m
	torso.material_override = mat_vest
	root.add_child(torso)
	
	# Ceramic Chest Plate
	var plate = MeshInstance3D.new()
	var p_m = BoxMesh.new()
	p_m.size = Vector3(0.28, 0.32, 0.045)
	plate.mesh = p_m
	plate.material_override = mat_plate
	plate.position = Vector3(0, 0.02, 0.095)
	root.add_child(plate)
	
	# Shoulder Straps
	var strap_l = MeshInstance3D.new()
	var st_m = BoxMesh.new()
	st_m.size = Vector3(0.07, 0.12, 0.22)
	strap_l.mesh = st_m
	strap_l.material_override = mat_strap
	strap_l.position = Vector3(-0.13, 0.22, 0)
	root.add_child(strap_l)
	
	var strap_r = MeshInstance3D.new()
	strap_r.mesh = st_m
	strap_r.material_override = mat_strap
	strap_r.position = Vector3(0.13, 0.22, 0)
	root.add_child(strap_r)
	
	# Ammo Pouches on lower belly
	for i in range(3):
		var pouch = MeshInstance3D.new()
		var po_m = BoxMesh.new()
		po_m.size = Vector3(0.065, 0.12, 0.05)
		pouch.mesh = po_m
		pouch.material_override = mat_pouch
		pouch.position = Vector3(-0.09 + i * 0.09, -0.12, 0.11)
		root.add_child(pouch)
		
	return root

func create_bandage_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_wrap = StandardMaterial3D.new()
	mat_wrap.albedo_color = Color(0.92, 0.93, 0.95)
	mat_wrap.roughness = 0.8
	
	var mat_core = StandardMaterial3D.new()
	mat_core.albedo_color = Color(0.65, 0.6, 0.52)
	mat_core.roughness = 0.9
	
	var mat_cross = StandardMaterial3D.new()
	mat_cross.albedo_color = Color(0.9, 0.15, 0.15)
	mat_cross.roughness = 0.35
	
	# Bandage Cylindrical Roll
	var roll = MeshInstance3D.new()
	var r_m = CylinderMesh.new()
	r_m.top_radius = 0.13
	r_m.bottom_radius = 0.13
	r_m.height = 0.16
	r_m.radial_segments = 24
	roll.mesh = r_m
	roll.material_override = mat_wrap
	root.add_child(roll)
	
	# Hollow cardboard core
	var core = MeshInstance3D.new()
	var c_m = CylinderMesh.new()
	c_m.top_radius = 0.04
	c_m.bottom_radius = 0.04
	c_m.height = 0.165
	core.mesh = c_m
	core.material_override = mat_core
	root.add_child(core)
	
	# 3D Red Cross on the front of roll
	var cross_v = MeshInstance3D.new()
	var cv_m = BoxMesh.new()
	cv_m.size = Vector3(0.025, 0.09, 0.015)
	cross_v.mesh = cv_m
	cross_v.material_override = mat_cross
	cross_v.position = Vector3(0, 0, 0.132)
	root.add_child(cross_v)
	
	var cross_h = MeshInstance3D.new()
	var ch_m = BoxMesh.new()
	ch_m.size = Vector3(0.075, 0.025, 0.015)
	cross_h.mesh = ch_m
	cross_h.material_override = mat_cross
	cross_h.position = Vector3(0, 0, 0.132)
	root.add_child(cross_h)
	
	return root

func create_knife_preview() -> Node3D:
	var root := Node3D.new()
	root.name = "KnifePreview"
	
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.88, 0.9, 0.94)
	steel_mat.metallic = 0.98
	steel_mat.roughness = 0.15
	
	var dark_steel := StandardMaterial3D.new()
	dark_steel.albedo_color = Color(0.18, 0.20, 0.22)
	dark_steel.metallic = 0.9
	dark_steel.roughness = 0.35
	
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.18, 0.22, 0.16)
	grip_mat.roughness = 0.7
	grip_mat.metallic = 0.05
	
	# Main blade
	var blade_inst := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.012, 0.048, 0.28)
	blade_mesh.material = steel_mat
	blade_inst.mesh = blade_mesh
	blade_inst.position = Vector3(0, 0.005, -0.15)
	root.add_child(blade_inst)
	
	# Edge bevel
	var edge_inst := MeshInstance3D.new()
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.005, 0.015, 0.28)
	edge_mesh.material = steel_mat
	edge_inst.mesh = edge_mesh
	edge_inst.position = Vector3(0, -0.022, -0.15)
	root.add_child(edge_inst)
	
	# Clip point
	var tip_inst := MeshInstance3D.new()
	var tip_mesh := PrismMesh.new()
	tip_mesh.size = Vector3(0.010, 0.046, 0.065)
	tip_mesh.material = steel_mat
	tip_inst.mesh = tip_mesh
	tip_inst.position = Vector3(0, -0.003, -0.31)
	tip_inst.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(tip_inst)
	
	# Fuller
	var fuller_inst := MeshInstance3D.new()
	var fuller_mesh := BoxMesh.new()
	fuller_mesh.size = Vector3(0.014, 0.014, 0.18)
	fuller_mesh.material = dark_steel
	fuller_inst.mesh = fuller_mesh
	fuller_inst.position = Vector3(0, 0.009, -0.14)
	root.add_child(fuller_inst)
	
	# Crossguard with ring
	var guard_inst := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.024, 0.09, 0.02)
	guard_mesh.material = dark_steel
	guard_inst.mesh = guard_mesh
	guard_inst.position = Vector3(0, 0, -0.01)
	root.add_child(guard_inst)
	
	var ring_inst := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.012
	ring_mesh.outer_radius = 0.022
	ring_mesh.material = dark_steel
	ring_inst.mesh = ring_mesh
	ring_inst.position = Vector3(0, 0.055, -0.01)
	ring_inst.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(ring_inst)
	
	# Grip
	var handle_inst := MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.035, 0.048, 0.16)
	handle_mesh.material = grip_mat
	handle_inst.mesh = handle_mesh
	handle_inst.position = Vector3(0, 0, 0.08)
	root.add_child(handle_inst)
	
	# Grip ribs
	for i in range(5):
		var rib := MeshInstance3D.new()
		var rib_mesh := BoxMesh.new()
		rib_mesh.size = Vector3(0.038, 0.052, 0.012)
		rib_mesh.material = dark_steel
		rib.mesh = rib_mesh
		rib.position = Vector3(0, 0, 0.035 + i * 0.024)
		root.add_child(rib)
		
	# Butt pommel
	var pommel_inst := MeshInstance3D.new()
	var pommel_mesh := BoxMesh.new()
	pommel_mesh.size = Vector3(0.04, 0.052, 0.028)
	pommel_mesh.material = dark_steel
	pommel_inst.mesh = pommel_mesh
	pommel_inst.position = Vector3(0, 0, 0.175)
	root.add_child(pommel_inst)
	
	return root

func create_medkit_preview() -> Node3D:
	var root := Node3D.new()
	root.name = "MedkitPreview"
	
	var case_mat := StandardMaterial3D.new()
	case_mat.albedo_color = Color(0.92, 0.94, 0.96)
	case_mat.roughness = 0.4
	
	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.95, 0.15, 0.15)
	red_mat.emission_enabled = true
	red_mat.emission = Color(0.95, 0.15, 0.15)
	red_mat.emission_energy_multiplier = 0.5
	
	var latch_mat := StandardMaterial3D.new()
	latch_mat.albedo_color = Color(0.2, 0.22, 0.25)
	latch_mat.metallic = 0.85
	latch_mat.roughness = 0.3
	
	# Case body
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.24, 0.14)
	body.mesh = bm
	body.material_override = case_mat
	root.add_child(body)
	
	# Handle
	var handle := MeshInstance3D.new()
	var hm := TorusMesh.new()
	hm.inner_radius = 0.025
	hm.outer_radius = 0.04
	handle.mesh = hm
	handle.material_override = latch_mat
	handle.position = Vector3(0, 0.13, 0)
	handle.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(handle)
	
	# Latches (raised cleanly above top face to eliminate coplanar Z-fighting)
	for x in [-0.09, 0.09]:
		var latch := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.035, 0.02, 0.146)
		latch.mesh = lm
		latch.material_override = latch_mat
		latch.position = Vector3(x, 0.122, 0)
		root.add_child(latch)
		
	# Red Cross on front and back (segmented wings to eliminate coplanar Z-fighting at intersection)
	for z_dir in [1.0, -1.0]:
		var cross_v := MeshInstance3D.new()
		var cv_m := BoxMesh.new()
		cv_m.size = Vector3(0.04, 0.12, 0.006)
		cross_v.mesh = cv_m
		cross_v.material_override = red_mat
		cross_v.position = Vector3(0, 0, 0.0735 * z_dir)
		root.add_child(cross_v)
		
		# Left horizontal arm
		var cross_hl := MeshInstance3D.new()
		var chl_m := BoxMesh.new()
		chl_m.size = Vector3(0.04, 0.04, 0.006)
		cross_hl.mesh = chl_m
		cross_hl.material_override = red_mat
		cross_hl.position = Vector3(-0.04, 0, 0.0735 * z_dir)
		root.add_child(cross_hl)
		
		# Right horizontal arm
		var cross_hr := MeshInstance3D.new()
		var chr_m := BoxMesh.new()
		chr_m.size = Vector3(0.04, 0.04, 0.006)
		cross_hr.mesh = chr_m
		cross_hr.material_override = red_mat
		cross_hr.position = Vector3(0.04, 0, 0.0735 * z_dir)
		root.add_child(cross_hr)
		
	return root

func create_shahed_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.24, 0.26, 0.28)
	mat_body.roughness = 0.55
	mat_body.metallic = 0.2
	
	var mat_nose = StandardMaterial3D.new()
	mat_nose.albedo_color = Color(0.16, 0.17, 0.18)
	mat_nose.roughness = 0.4
	mat_nose.metallic = 0.35
	
	var mat_engine = StandardMaterial3D.new()
	mat_engine.albedo_color = Color(0.12, 0.12, 0.14)
	mat_engine.roughness = 0.4
	mat_engine.metallic = 0.7
	
	var mat_prop = StandardMaterial3D.new()
	mat_prop.albedo_color = Color(0.1, 0.1, 0.1)
	mat_prop.roughness = 0.3
	mat_prop.metallic = 0.8
	
	# Fuselage
	var fuse = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(0.28, 0.22, 1.35)
	fuse.mesh = fm
	fuse.material_override = mat_body
	root.add_child(fuse)
	
	# Nose cone
	var nose = MeshInstance3D.new()
	var nm = CylinderMesh.new()
	nm.top_radius = 0.04
	nm.bottom_radius = 0.13
	nm.height = 0.42
	nm.radial_segments = 8
	nose.mesh = nm
	nose.material_override = mat_nose
	nose.position = Vector3(0, 0, -0.85)
	nose.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(nose)
	
	# Delta wing main
	var wing_main = MeshInstance3D.new()
	var wmm = BoxMesh.new()
	wmm.size = Vector3(2.1, 0.045, 0.85)
	wing_main.mesh = wmm
	wing_main.material_override = mat_body
	wing_main.position = Vector3(0, 0, 0.22)
	root.add_child(wing_main)
	
	# Delta wing forward
	var wing_fwd = MeshInstance3D.new()
	var wfm = BoxMesh.new()
	wfm.size = Vector3(1.2, 0.04, 0.6)
	wing_fwd.mesh = wfm
	wing_fwd.material_override = mat_body
	wing_fwd.position = Vector3(0, 0, -0.28)
	root.add_child(wing_fwd)
	
	# Vertical wingtip fins
	for x_pos in [-1.04, 1.04]:
		var fin = MeshInstance3D.new()
		var fnm = BoxMesh.new()
		fnm.size = Vector3(0.04, 0.32, 0.48)
		fin.mesh = fnm
		fin.material_override = mat_body
		fin.position = Vector3(x_pos, 0.1, 0.26)
		root.add_child(fin)
		
	# Rear Engine Nacelle
	var engine = MeshInstance3D.new()
	var em = CylinderMesh.new()
	em.top_radius = 0.09
	em.bottom_radius = 0.09
	em.height = 0.22
	em.radial_segments = 8
	engine.mesh = em
	engine.material_override = mat_engine
	engine.position = Vector3(0, 0.02, 0.72)
	engine.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(engine)
	
	# Propeller
	var prop1 = MeshInstance3D.new()
	var pm1 = BoxMesh.new()
	pm1.size = Vector3(0.55, 0.035, 0.015)
	prop1.mesh = pm1
	prop1.material_override = mat_prop
	prop1.position = Vector3(0, 0.02, 0.84)
	root.add_child(prop1)
	
	var prop2 = MeshInstance3D.new()
	var pm2 = BoxMesh.new()
	pm2.size = Vector3(0.035, 0.55, 0.015)
	prop2.mesh = pm2
	prop2.material_override = mat_prop
	prop2.position = Vector3(0, 0.02, 0.84)
	root.add_child(prop2)
	
	return root

func create_vodka_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.85, 0.92, 0.95, 0.75)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.12
	mat_glass.metallic = 0.1
	mat_glass.specular = 0.8
	
	var mat_liquid = StandardMaterial3D.new()
	mat_liquid.albedo_color = Color(0.9, 0.95, 0.98, 0.5)
	mat_liquid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_liquid.roughness = 0.05
	
	var mat_cap = StandardMaterial3D.new()
	mat_cap.albedo_color = Color(0.8, 0.15, 0.15)
	mat_cap.roughness = 0.35
	mat_cap.metallic = 0.7
	
	var mat_label = StandardMaterial3D.new()
	mat_label.albedo_color = Color(0.96, 0.95, 0.92)
	mat_label.roughness = 0.75
	
	# Flat flask body ("Чекушка" / "Чекунец")
	var bottle = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.18, 0.22, 0.09)
	bottle.mesh = bm
	bottle.material_override = mat_glass
	bottle.position = Vector3(0, 0, 0)
	root.add_child(bottle)
	
	# Liquid inside
	var liquid = MeshInstance3D.new()
	var lm = BoxMesh.new()
	lm.size = Vector3(0.165, 0.19, 0.075)
	liquid.mesh = lm
	liquid.material_override = mat_liquid
	liquid.position = Vector3(0, -0.01, 0)
	root.add_child(liquid)
	
	# Tapered shoulders
	var shoulder = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.04
	sm.bottom_radius = 0.08
	sm.height = 0.06
	shoulder.mesh = sm
	shoulder.material_override = mat_glass
	shoulder.position = Vector3(0, 0.14, 0)
	root.add_child(shoulder)
	
	# Neck
	var neck = MeshInstance3D.new()
	var n_m = CylinderMesh.new()
	n_m.top_radius = 0.032
	n_m.bottom_radius = 0.032
	n_m.height = 0.07
	neck.mesh = n_m
	neck.material_override = mat_glass
	neck.position = Vector3(0, 0.19, 0)
	root.add_child(neck)
	
	# Cap (Red metallic screwcap)
	var cap = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.035
	cm.bottom_radius = 0.035
	cm.height = 0.04
	cap.mesh = cm
	cap.material_override = mat_cap
	cap.position = Vector3(0, 0.23, 0)
	root.add_child(cap)
	
	# Label plate on front
	var label_plate = MeshInstance3D.new()
	var lpm = BoxMesh.new()
	lpm.size = Vector3(0.14, 0.15, 0.004)
	label_plate.mesh = lpm
	label_plate.material_override = mat_label
	label_plate.position = Vector3(0, -0.01, 0.046)
	root.add_child(label_plate)
	
	# Label Text
	var lbl = Label3D.new()
	lbl.text = "ЧЕКУНЕЦ\n67\nВОДКА"
	lbl.font_size = 28
	lbl.modulate = Color(0.75, 0.12, 0.12)
	lbl.outline_modulate = Color(0.1, 0.1, 0.1)
	lbl.outline_size = 3
	lbl.position = Vector3(0, -0.01, 0.049)
	lbl.pixel_size = 0.0012
	root.add_child(lbl)
	
	return root

func create_heavy_armor_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_vest = StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.12, 0.14, 0.13)
	mat_vest.roughness = 0.7
	
	var mat_plate = StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.18, 0.2, 0.22)
	mat_plate.metallic = 0.75
	mat_plate.roughness = 0.25
	
	var mat_pauldron = StandardMaterial3D.new()
	mat_pauldron.albedo_color = Color(0.15, 0.17, 0.18)
	mat_pauldron.metallic = 0.65
	mat_pauldron.roughness = 0.35
	
	var mat_strap = StandardMaterial3D.new()
	mat_strap.albedo_color = Color(0.08, 0.09, 0.09)
	mat_strap.roughness = 0.9
	
	# Main Torso Carrier (Bulky)
	var torso = MeshInstance3D.new()
	var tm = BoxMesh.new()
	tm.size = Vector3(0.44, 0.48, 0.22)
	torso.mesh = tm
	torso.material_override = mat_vest
	root.add_child(torso)
	
	# Front Heavy Titanium/Ceramic Plate
	var front_plate = MeshInstance3D.new()
	var fpm = BoxMesh.new()
	fpm.size = Vector3(0.32, 0.36, 0.06)
	front_plate.mesh = fpm
	front_plate.material_override = mat_plate
	front_plate.position = Vector3(0, 0.02, 0.12)
	root.add_child(front_plate)
	
	# Back Heavy Plate
	var back_plate = MeshInstance3D.new()
	var bpm = BoxMesh.new()
	bpm.size = Vector3(0.32, 0.36, 0.06)
	back_plate.mesh = bpm
	back_plate.material_override = mat_plate
	back_plate.position = Vector3(0, 0.02, -0.12)
	root.add_child(back_plate)
	
	# High Ballistic Collar / Neck Guard
	var collar = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(0.26, 0.10, 0.18)
	collar.mesh = cm
	collar.material_override = mat_vest
	collar.position = Vector3(0, 0.27, 0)
	root.add_child(collar)
	
	# Shoulder Pauldrons (Heavy armor feature)
	for x_side in [-0.27, 0.27]:
		var pauldron = MeshInstance3D.new()
		var pam = BoxMesh.new()
		pam.size = Vector3(0.14, 0.18, 0.22)
		pauldron.mesh = pam
		pauldron.material_override = mat_pauldron
		pauldron.position = Vector3(x_side, 0.16, 0)
		root.add_child(pauldron)
		
	# Groin Flap (Kevlar)
	var flap = MeshInstance3D.new()
	var flm = BoxMesh.new()
	flm.size = Vector3(0.24, 0.16, 0.04)
	flap.mesh = flm
	flap.material_override = mat_vest
	flap.position = Vector3(0, -0.30, 0.08)
	root.add_child(flap)
	
	# Front Ammo & Molle Pouches
	for i in range(4):
		var pouch = MeshInstance3D.new()
		var po_m = BoxMesh.new()
		po_m.size = Vector3(0.06, 0.13, 0.05)
		pouch.mesh = po_m
		pouch.material_override = mat_strap
		pouch.position = Vector3(-0.105 + i * 0.07, -0.12, 0.155)
		root.add_child(pouch)
		
	# Stencil Text on Front
	var lbl = Label3D.new()
	lbl.text = "СВЕРХТЯЖЕЛЫЙ\n150 БРОНЯ"
	lbl.font_size = 22
	lbl.modulate = Color(0.9, 0.8, 0.2)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 2
	lbl.position = Vector3(0, 0.05, 0.152)
	lbl.pixel_size = 0.0014
	root.add_child(lbl)
	
	return root

func create_armor_plate_preview() -> Node3D:
	var root = Node3D.new()
	
	var mat_plate = StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.2, 0.22, 0.24)
	mat_plate.metallic = 0.8
	mat_plate.roughness = 0.25
	
	var mat_rim = StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.08, 0.08, 0.09)
	mat_rim.roughness = 0.85
	
	# Main Composite Armor Plate (Shooter's cut)
	var plate = MeshInstance3D.new()
	var pm = BoxMesh.new()
	pm.size = Vector3(0.28, 0.36, 0.035)
	plate.mesh = pm
	plate.material_override = mat_plate
	root.add_child(plate)
	
	# Rubber Edge Rim / Shock Absorber
	var rim = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(0.295, 0.375, 0.02)
	rim.mesh = rm
	rim.material_override = mat_rim
	rim.position = Vector3(0, 0, -0.008)
	root.add_child(rim)
	
	# Stencil on plate
	var lbl = Label3D.new()
	lbl.text = "БРОНЕПЛИТА\n+30 БРОНЯ\nBR-5+ TITAN"
	lbl.font_size = 24
	lbl.modulate = Color(0.85, 0.85, 0.85)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 3
	lbl.position = Vector3(0, 0, 0.02)
	lbl.pixel_size = 0.0014
	root.add_child(lbl)
	
	return root

