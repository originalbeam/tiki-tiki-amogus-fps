extends SubViewportContainer

# Handbook 3D Interactive Item/Entity Inspector
# EFT-grade 3D Inspection Viewport with soft ambient fill light and direct model preloads

const AK47Model = preload("res://scripts/weapons/models/ak47_model.gd")
const ShotgunModel = preload("res://scripts/weapons/models/shotgun_model.gd")
const PistolModel = preload("res://scripts/weapons/models/pistol_model.gd")
const RPGModel = preload("res://scripts/weapons/models/rpg_model.gd")
const SniperModel = preload("res://scripts/weapons/models/sniper_model.gd")
const KnifeModel = preload("res://scripts/weapons/models/knife_model.gd")
const AxeModel = preload("res://scripts/weapons/models/axe_model.gd")
const PreviewCrewmate = preload("res://scripts/ui/previews/preview_crewmate.gd")
const PreviewDrone = preload("res://scripts/ui/previews/preview_drone.gd")
const PreviewItems = preload("res://scripts/ui/previews/preview_items.gd")
const WeaponWorkbenchScript = preload("res://scripts/shop/weapon_workbench.gd")

@onready var viewport: SubViewport = $SubViewport
@onready var model_pivot: Node3D = $SubViewport/ModelPivot
@onready var camera: Camera3D = $SubViewport/Camera3D

var is_rotating: bool = false
var is_panning: bool = false
var auto_spin: bool = true
var auto_spin_speed: float = 1.0

var min_zoom: float = 0.35
var max_zoom: float = 3.8

var current_model_node: Node3D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not viewport:
		viewport = get_node_or_null("SubViewport")
	if not model_pivot and viewport:
		model_pivot = viewport.get_node_or_null("ModelPivot")
	if not camera and viewport:
		camera = viewport.get_node_or_null("Camera3D")

	if viewport:
		viewport.own_world_3d = true
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_setup_viewport_environment()
		
	gui_input.connect(_on_gui_input)

func _setup_viewport_environment() -> void:
	if not viewport:
		return
	if not viewport.has_node("WorldEnvironment"):
		var we := WorldEnvironment.new()
		we.name = "WorldEnvironment"
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.75, 0.77, 0.80)
		env.ambient_light_energy = 1.3
		we.environment = env
		viewport.add_child(we)
	
	if camera:
		camera.current = true
		camera.fov = 45.0

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
	if not viewport:
		viewport = get_node_or_null("SubViewport")
	if not model_pivot and viewport:
		model_pivot = viewport.get_node_or_null("ModelPivot")
	if not camera and viewport:
		camera = viewport.get_node_or_null("Camera3D")
		
	if not model_pivot or not camera:
		return

	if viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		if viewport.size.x < 100 or viewport.size.y < 100:
			viewport.size = Vector2i(630, 290)
		_setup_viewport_environment()
		
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
			current_model_node = AK47Model.create()
			camera.position = Vector3(0, 0.03, 1.05)
		"shotgun":
			current_model_node = ShotgunModel.create()
			camera.position = Vector3(0, 0.03, 1.25)
		"pistol":
			current_model_node = PistolModel.create()
			camera.position = Vector3(0, 0.01, 0.52)
		"rpg", "rpg7":
			current_model_node = RPGModel.create(true)
			current_model_node.position = Vector3(0, 0.0, 0.165)
			camera.position = Vector3(0, 0.04, 1.48)
		"sniper", "awp":
			current_model_node = SniperModel.create()
			camera.position = Vector3(0, 0.04, 1.35)
		"axe", "fire_axe":
			current_model_node = AxeModel.create()
			camera.position = Vector3(0, 0.05, 0.85)
		"knife":
			current_model_node = KnifeModel.create_preview()
			camera.position = Vector3(0, 0.0, 0.58)
		"enemy_red":
			current_model_node = PreviewCrewmate.create(Color(0.9, 0.15, 0.15), 0)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_blue":
			current_model_node = PreviewCrewmate.create(Color(0.15, 0.45, 0.95), 1)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_yellow":
			current_model_node = PreviewCrewmate.create(Color(0.95, 0.75, 0.1), 2)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_green":
			current_model_node = PreviewCrewmate.create(Color(0.15, 0.85, 0.25), 3)
			camera.position = Vector3(0, 0.0, 2.35)
		"enemy_shahed", "shahed":
			current_model_node = PreviewDrone.create()
			camera.position = Vector3(0, 0.25, 2.2)
		"armor_vest":
			current_model_node = PreviewItems.create_armor()
			camera.position = Vector3(0, 0.0, 0.95)
		"bandage":
			current_model_node = PreviewItems.create_bandage()
			camera.position = Vector3(0, 0.0, 0.48)
		"medkit":
			current_model_node = PreviewItems.create_medkit()
			camera.position = Vector3(0, 0.0, 0.65)
		"vodka":
			current_model_node = PreviewItems.create_vodka()
			camera.position = Vector3(0, 0.05, 0.72)
		"heavy_armor":
			current_model_node = PreviewItems.create_heavy_armor()
			camera.position = Vector3(0, 0.0, 1.1)
		"armor_plate":
			current_model_node = PreviewItems.create_armor_plate()
			camera.position = Vector3(0, 0.0, 0.65)
		"workbench":
			current_model_node = WeaponWorkbenchScript.create_preview()
			camera.position = Vector3(0, 0.25, 2.2)
			
	if current_model_node:
		model_pivot.add_child(current_model_node)
	if camera:
		camera.look_at(Vector3(0, 0, 0), Vector3.UP)

# Used by the Workbench 3D Modding UI to dynamically display a weapon with its live installed mods.
func show_weapon_with_mods(weapon: Weapon, keep_transform: bool = false) -> void:
	if not weapon:
		return
	if not viewport:
		viewport = get_node_or_null("SubViewport")
	if not model_pivot and viewport:
		model_pivot = viewport.get_node_or_null("ModelPivot")
	if not camera and viewport:
		camera = viewport.get_node_or_null("Camera3D")
	if not model_pivot or not camera:
		return
		
	var saved_rot: Vector3 = model_pivot.rotation
	var saved_pos: Vector3 = model_pivot.position
	var saved_cam_z: float = camera.position.z
	var saved_spin: bool = auto_spin
	
	if viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_setup_viewport_environment()
		
	for child in model_pivot.get_children():
		model_pivot.remove_child(child)
		child.queue_free()
	current_model_node = null
	
	match weapon.weapon_id:
		"ak47":
			current_model_node = AK47Model.create_with_mods(weapon.installed_mods)
			if not keep_transform:
				camera.position = Vector3(0, 0.03, 1.02)
		"shotgun":
			current_model_node = ShotgunModel.create()
			if not keep_transform:
				camera.position = Vector3(0, 0.03, 1.25)
		"pistol":
			current_model_node = PistolModel.create()
			if not keep_transform:
				camera.position = Vector3(0, 0.01, 0.52)
		"rpg":
			current_model_node = RPGModel.create(true)
			current_model_node.position = Vector3(0, 0.0, 0.165)
			if not keep_transform:
				camera.position = Vector3(0, 0.04, 1.48)
		_:
			current_model_node = AK47Model.create()
			
	if current_model_node:
		model_pivot.add_child(current_model_node)
		
	if keep_transform:
		model_pivot.rotation = saved_rot
		model_pivot.position = saved_pos
		camera.position.z = saved_cam_z
		auto_spin = saved_spin
	else:
		# Side profile view initially so EFT mod slots align cleanly over the weapon!
		model_pivot.position = Vector3.ZERO
		model_pivot.rotation = Vector3(0, deg_to_rad(-82.0), 0)
		auto_spin = false
		is_rotating = false
		is_panning = false
	if camera:
		camera.look_at(Vector3(0, 0, 0), Vector3.UP)

# Projects a 3D local anchor point on the displayed weapon into this container's 2D UI space
func get_projected_slot_pos(local_anchor: Vector3) -> Vector2:
	if not camera or not viewport or not is_instance_valid(current_model_node):
		return size * 0.5
	var world_pt: Vector3 = current_model_node.to_global(local_anchor)
	var vp_pt: Vector2 = camera.unproject_position(world_pt)
	var vp_size := Vector2(viewport.size)
	if vp_size.x > 0.0 and vp_size.y > 0.0 and size.x > 0.0 and size.y > 0.0:
		return Vector2(vp_pt.x * (size.x / vp_size.x), vp_pt.y * (size.y / vp_size.y))
	return vp_pt
