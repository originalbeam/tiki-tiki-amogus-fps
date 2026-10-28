extends CharacterBody3D

signal died(points)

enum EnemyType {
	RED_STANDARD,
	BLUE_SCOUT,
	YELLOW_HEAVY,
	GREEN_SNIPER
}

@export var enemy_type: EnemyType = EnemyType.RED_STANDARD
@export var max_health: float = 100.0
var health: float = 100.0
var move_speed: float = 4.5
var shoot_interval: float = 1.4
var shoot_timer: float = 0.0
var bullet_damage: float = 10.0
var score_value: int = 100
var preferred_distance: float = 8.0
var crewmate_color: Color = Color(0.9, 0.15, 0.15)
var laser_color: Color = Color(1.0, 0.2, 0.2)

# Specific attack variables
var is_melee: bool = false
var melee_damage: float = 38.0
var is_swinging_axe: bool = false
var axe_swing_timer: float = 0.0
var axe_hit_registered: bool = false

var is_sniper: bool = false
var glint_active: bool = false
var scope_glint_node: Node3D = null

var is_bursting: bool = false
var burst_shots_left: int = 0
var burst_shot_timer: float = 0.0

var player: Node3D = null
var gravity: float = 14.0
var walk_cycle: float = 0.0

@onready var gibs_scene: PackedScene = preload("res://scenes/crewmate_gibs.tscn")
@onready var bullet_scene: PackedScene = preload("res://scenes/enemy_bullet.tscn")
@onready var pickup_scene: PackedScene = preload("res://scenes/pickup_item.tscn")

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var body_mesh: MeshInstance3D = $Visuals/Body
@onready var backpack_mesh: MeshInstance3D = $Visuals/Backpack
@onready var left_leg: Node3D = $Visuals/LeftLeg
@onready var right_leg: Node3D = $Visuals/RightLeg
@onready var weapon_holder: Node3D = $Visuals/Blaster
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var sprite_3d: Sprite3D = $HealthBarSprite

var muzzle_marker: Marker3D = null
var weapon_model_root: Node3D = null

var original_material: StandardMaterial3D
var flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	setup_type_attributes()
	health = max_health
	apply_materials()
	setup_weapon_visuals()
	
	shoot_timer = randf_range(0.5, shoot_interval)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func setup_type_attributes() -> void:
	match enemy_type:
		EnemyType.RED_STANDARD:
			crewmate_color = Color(0.9, 0.15, 0.15)
			laser_color = Color(1.0, 0.3, 0.3)
			move_speed = 4.2
			shoot_interval = 1.4
			bullet_damage = 10.0
			score_value = 4
			preferred_distance = 7.0
			is_melee = false
			is_sniper = false
			
		EnemyType.BLUE_SCOUT:
			crewmate_color = Color(0.15, 0.45, 0.95)
			laser_color = Color(0.3, 0.7, 1.0)
			move_speed = 6.2
			shoot_interval = 0.75
			bullet_damage = 8.0
			score_value = 6
			preferred_distance = 5.5
			is_melee = false
			is_sniper = false
			
		EnemyType.YELLOW_HEAVY:
			crewmate_color = Color(0.95, 0.75, 0.1)
			laser_color = Color(1.0, 0.85, 0.2)
			move_speed = 3.2
			max_health = 280.0
			health = 280.0
			shoot_interval = 1.5
			melee_damage = 38.0
			score_value = 12
			preferred_distance = 1.1
			is_melee = true
			is_sniper = false
			
		EnemyType.GREEN_SNIPER:
			crewmate_color = Color(0.15, 0.85, 0.25)
			laser_color = Color(0.3, 1.0, 0.4)
			move_speed = 3.5
			max_health = 60.0
			health = 60.0
			shoot_interval = 3.8
			bullet_damage = 48.0
			score_value = 10
			preferred_distance = 15.0
			is_melee = false
			is_sniper = true

	# Apply difficulty modifiers from GlobalSettings
	if GlobalSettings:
		move_speed *= GlobalSettings.get_enemy_speed_multiplier()
		bullet_damage *= GlobalSettings.get_enemy_damage_multiplier()
		melee_damage *= GlobalSettings.get_enemy_damage_multiplier()
		max_health *= GlobalSettings.get_enemy_health_multiplier()
		health = max_health
		shoot_interval *= GlobalSettings.get_enemy_shoot_rate_multiplier()

func apply_materials() -> void:
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = crewmate_color
	original_material.roughness = 0.35
	
	if body_mesh:
		body_mesh.material_override = original_material
	if backpack_mesh:
		backpack_mesh.material_override = original_material
	
	var leg_mesh_l = left_leg.get_node_or_null("Mesh")
	var leg_mesh_r = right_leg.get_node_or_null("Mesh")
	if leg_mesh_l:
		leg_mesh_l.material_override = original_material
	if leg_mesh_r:
		leg_mesh_r.material_override = original_material

func setup_weapon_visuals() -> void:
	if not weapon_holder:
		return
	# Remove any existing children
	for child in weapon_holder.get_children():
		child.queue_free()
		
	weapon_model_root = Node3D.new()
	weapon_holder.add_child(weapon_model_root)
	
	match enemy_type:
		EnemyType.RED_STANDARD:
			build_ak_visuals(weapon_model_root)
		EnemyType.BLUE_SCOUT:
			build_pistol_visuals(weapon_model_root)
		EnemyType.YELLOW_HEAVY:
			build_axe_visuals(weapon_model_root)
		EnemyType.GREEN_SNIPER:
			build_awp_visuals(weapon_model_root)

func build_ak_visuals(parent: Node3D) -> void:
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.18, 0.19, 0.22)
	mat_metal.metallic = 0.85
	mat_metal.roughness = 0.3
	
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.48, 0.22, 0.1)
	mat_wood.roughness = 0.6
	
	var mat_mag = StandardMaterial3D.new()
	mat_mag.albedo_color = Color(0.68, 0.3, 0.12)
	mat_mag.roughness = 0.5
	
	# Receiver
	var rec = MeshInstance3D.new()
	var rec_m = BoxMesh.new()
	rec_m.size = Vector3(0.08, 0.1, 0.38)
	rec.mesh = rec_m
	rec.material_override = mat_metal
	parent.add_child(rec)
	
	# Barrel
	var bar = MeshInstance3D.new()
	var bar_m = CylinderMesh.new()
	bar_m.top_radius = 0.02
	bar_m.bottom_radius = 0.02
	bar_m.height = 0.38
	bar.mesh = bar_m
	bar.material_override = mat_metal
	bar.rotation.x = deg_to_rad(90.0)
	bar.position = Vector3(0, 0.02, 0.35)
	parent.add_child(bar)
	
	# Wood Handguard
	var hg = MeshInstance3D.new()
	var hg_m = BoxMesh.new()
	hg_m.size = Vector3(0.085, 0.09, 0.2)
	hg.mesh = hg_m
	hg.material_override = mat_wood
	hg.position = Vector3(0, 0, 0.22)
	parent.add_child(hg)
	
	# Buttstock
	var st = MeshInstance3D.new()
	var st_m = BoxMesh.new()
	st_m.size = Vector3(0.07, 0.12, 0.26)
	st.mesh = st_m
	st.material_override = mat_wood
	st.position = Vector3(0, -0.02, -0.28)
	parent.add_child(st)
	
	# Curved Magazine
	var mag = MeshInstance3D.new()
	var mag_m = BoxMesh.new()
	mag_m.size = Vector3(0.05, 0.22, 0.1)
	mag.mesh = mag_m
	mag.material_override = mat_mag
	mag.position = Vector3(0, -0.14, 0.08)
	mag.rotation.x = deg_to_rad(16.0)
	parent.add_child(mag)
	
	# Muzzle
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.02, 0.56)
	parent.add_child(muzzle_marker)

func build_pistol_visuals(parent: Node3D) -> void:
	var mat_slide = StandardMaterial3D.new()
	mat_slide.albedo_color = Color(0.2, 0.22, 0.26)
	mat_slide.metallic = 0.8
	mat_slide.roughness = 0.25
	
	var mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.1, 0.11, 0.12)
	mat_frame.roughness = 0.6
	
	# Slide
	var slide = MeshInstance3D.new()
	var s_m = BoxMesh.new()
	s_m.size = Vector3(0.065, 0.06, 0.28)
	slide.mesh = s_m
	slide.material_override = mat_slide
	parent.add_child(slide)
	
	# Grip
	var grip = MeshInstance3D.new()
	var g_m = BoxMesh.new()
	g_m.size = Vector3(0.058, 0.16, 0.085)
	grip.mesh = g_m
	grip.material_override = mat_frame
	grip.position = Vector3(0, -0.09, -0.06)
	grip.rotation.x = deg_to_rad(-14.0)
	parent.add_child(grip)
	
	# Muzzle
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.01, 0.16)
	parent.add_child(muzzle_marker)

func build_axe_visuals(parent: Node3D) -> void:
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

func build_awp_visuals(parent: Node3D) -> void:
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

	# --- 6. GAMEPLAY NODES (Scope glint & Muzzle Marker) ---
	scope_glint_node = Node3D.new()
	scope_glint_node.position = Vector3(0, 0.125, 0.28)
	scope_glint_node.visible = false
	parent.add_child(scope_glint_node)
	
	var glint_quad = MeshInstance3D.new()
	var q_m = QuadMesh.new()
	q_m.size = Vector2(0.9, 0.9)
	glint_quad.mesh = q_m
	
	var g_mat = StandardMaterial3D.new()
	g_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	g_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	g_mat.albedo_color = Color(0.4, 1.0, 0.85, 0.98)
	g_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glint_quad.material_override = g_mat
	scope_glint_node.add_child(glint_quad)
	
	var g_light = OmniLight3D.new()
	g_light.light_color = Color(0.3, 1.0, 0.7)
	g_light.light_energy = 4.5
	g_light.omni_range = 14.0
	scope_glint_node.add_child(g_light)
	
	# Muzzle Marker at tip of the AWP muzzle brake
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.045, 1.11)
	parent.add_child(muzzle_marker)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Damage flash reset
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0 and original_material:
			body_mesh.material_override = original_material
			backpack_mesh.material_override = original_material

	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		move_and_slide()
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position)
	dir_to_player.y = 0
	dir_to_player = dir_to_player.normalized()
	
	# Look towards player
	if dir_to_player.length_squared() > 0.001:
		var target_rot = atan2(dir_to_player.x, dir_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 7.0)

	# Movement logic
	var desired_velocity = Vector3.ZERO
	if is_melee:
		# Berserker Yellow rushes directly at player
		desired_velocity = dir_to_player * move_speed
	else:
		# Ranged enemies maintain preferred distance
		if dist_to_player > preferred_distance + 1.2:
			desired_velocity = dir_to_player * move_speed
		elif dist_to_player < preferred_distance - 2.5:
			desired_velocity = -dir_to_player * (move_speed * 0.7)
		else:
			# Strafe left/right around player
			var strafe_dir = dir_to_player.cross(Vector3.UP)
			desired_velocity = strafe_dir * (move_speed * 0.5)

	# Sniper slows down while aiming with glint
	if is_sniper and glint_active:
		desired_velocity *= 0.15

	velocity.x = lerpf(velocity.x, desired_velocity.x, delta * 5.0)
	velocity.z = lerpf(velocity.z, desired_velocity.z, delta * 5.0)
	
	# Waddling animation
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2:
		walk_cycle += delta * horizontal_speed * 3.5
		left_leg.rotation.x = sin(walk_cycle) * 0.45
		right_leg.rotation.x = -sin(walk_cycle) * 0.45
		$Visuals.rotation.z = sin(walk_cycle) * 0.08
	else:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, delta * 8.0)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, delta * 8.0)
		$Visuals.rotation.z = lerpf($Visuals.rotation.z, 0.0, delta * 8.0)

	move_and_slide()
	
	# Attack Handling
	handle_attacks(delta, dist_to_player)

func handle_attacks(delta: float, dist_to_player: float) -> void:
	if is_melee:
		handle_melee_axe(delta, dist_to_player)
	elif is_sniper:
		handle_sniper_attack(delta)
	elif enemy_type == EnemyType.RED_STANDARD:
		handle_burst_attack(delta)
	else: # Blue Scout semi-auto
		handle_pistol_attack(delta)

func handle_melee_axe(delta: float, dist_to_player: float) -> void:
	shoot_timer -= delta
	
	if is_swinging_axe:
		axe_swing_timer += delta
		var p: float = axe_swing_timer / 0.48
		
		if p < 0.35: # Windup backwards
			if weapon_holder:
				weapon_holder.rotation.x = lerpf(0.0, deg_to_rad(-55.0), p / 0.35)
		elif p < 0.7: # Violent forward chop
			var chop_p: float = (p - 0.35) / 0.35
			if weapon_holder:
				weapon_holder.rotation.x = lerpf(deg_to_rad(-55.0), deg_to_rad(65.0), chop_p)
			if not axe_hit_registered and chop_p >= 0.5:
				axe_hit_registered = true
				if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 2.4:
					if player.has_method("take_damage"):
						player.take_damage(melee_damage)
					play_sfx(SoundEffects.create_axe_hit_sound())
		else: # Recovery
			if weapon_holder:
				weapon_holder.rotation.x = lerpf(deg_to_rad(65.0), 0.0, (p - 0.7) / 0.3)
				
		if axe_swing_timer >= 0.48:
			is_swinging_axe = false
			if weapon_holder:
				weapon_holder.rotation.x = 0.0
	else:
		if dist_to_player <= 2.2 and shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			is_swinging_axe = true
			axe_swing_timer = 0.0
			axe_hit_registered = false
			play_sfx(SoundEffects.create_axe_swing_sound())

func handle_sniper_attack(delta: float) -> void:
	shoot_timer -= delta
	var has_los: bool = has_line_of_sight()
	
	# Lens Flare / Glint warning debuff active 1.6s before shooting
	if shoot_timer <= 1.6 and has_los:
		if not glint_active:
			glint_active = true
			if scope_glint_node:
				scope_glint_node.visible = true
			play_sfx(SoundEffects.create_sniper_charge_sound())
		if scope_glint_node:
			var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.025) * 0.25
			scope_glint_node.scale = Vector3.ONE * pulse
	else:
		if glint_active:
			glint_active = false
			if scope_glint_node:
				scope_glint_node.visible = false

	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval + randf_range(-0.2, 0.3)
		if has_los:
			spawn_sniper_shot()
		if scope_glint_node:
			scope_glint_node.visible = false
		glint_active = false

func spawn_sniper_shot() -> void:
	if not bullet_scene or not is_instance_valid(player):
		return
	var bullet = bullet_scene.instantiate()
	var spawn_pos: Vector3 = muzzle_marker.global_position if muzzle_marker else (global_position + Vector3(0, 0.8, 0))
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	var target_pos: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var shoot_dir: Vector3 = (target_pos - spawn_pos).normalized()
	# Sniper bullet flies at 55.0 m/s with 48 damage
	bullet.init(shoot_dir, bullet_damage, laser_color, 55.0)
	play_sfx(SoundEffects.create_awp_sound())

func handle_burst_attack(delta: float) -> void:
	if is_bursting:
		burst_shot_timer -= delta
		if burst_shot_timer <= 0.0:
			burst_shot_timer = 0.12
			burst_shots_left -= 1
			if has_line_of_sight():
				spawn_standard_bullet()
			if burst_shots_left <= 0:
				is_bursting = false
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval + randf_range(-0.15, 0.2)
		if has_line_of_sight():
			is_bursting = true
			burst_shots_left = 3
			burst_shot_timer = 0.0

func handle_pistol_attack(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval + randf_range(-0.08, 0.08)
		if has_line_of_sight():
			spawn_standard_bullet()

func spawn_standard_bullet() -> void:
	if not bullet_scene or not is_instance_valid(player):
		return
	var bullet = bullet_scene.instantiate()
	var spawn_pos: Vector3 = muzzle_marker.global_position if muzzle_marker else (global_position + Vector3(0, 0.8, 0))
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	var spread: float = 0.08 if enemy_type == EnemyType.BLUE_SCOUT else 0.12
	var target_pos: Vector3 = player.global_position + Vector3(
		randf_range(-spread, spread),
		0.85 + randf_range(-spread, spread),
		randf_range(-spread, spread)
	)
	var shoot_dir: Vector3 = (target_pos - spawn_pos).normalized()
	bullet.init(shoot_dir, bullet_damage, laser_color, 26.0)
	if enemy_type == EnemyType.RED_STANDARD:
		play_sfx(SoundEffects.create_ak47_sound())
	else:
		play_sfx(SoundEffects.create_pistol_sound())

# Robust raycast check ignoring other enemies and hitting layer 1 (world)
func has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false
	var space_state = get_world_3d().direct_space_state
	var from_pos: Vector3 = global_position + Vector3(0, 1.1, 0)
	var to_pos: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1 # World layer
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return true
	if result.collider == player or (result.collider and result.collider.is_in_group("player")):
		return true
	var dist_to_hit: float = from_pos.distance_to(result.position)
	var dist_to_player: float = from_pos.distance_to(to_pos)
	return dist_to_hit >= (dist_to_player - 0.4)

func play_sfx(stream: AudioStream) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()

func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	if health <= 0:
		return
	health -= amount
	if health_bar:
		health_bar.value = health
		
	# Damage flash
	flash_timer = 0.08
	var hit_mat = StandardMaterial3D.new()
	hit_mat.albedo_color = Color(1.0, 1.0, 1.0)
	hit_mat.emission_enabled = true
	hit_mat.emission = Color(1.0, 0.4, 0.4)
	hit_mat.emission_energy_multiplier = 2.0
	body_mesh.material_override = hit_mat
	backpack_mesh.material_override = hit_mat
	
	if health <= 0:
		die()

func die() -> void:
	died.emit(score_value)
	
	# Spawn Item Drops
	spawn_death_drops()
	
	# Spawn gibs
	if gibs_scene:
		var gibs = gibs_scene.instantiate()
		get_parent().add_child(gibs)
		gibs.global_position = global_position
		gibs.rotation.y = rotation.y
		gibs.init(crewmate_color)
		
	# Play explosion gib sound globally in tree
	var sfx = AudioStreamPlayer.new()
	sfx.stream = SoundEffects.create_explosion_gib_sound()
	sfx.pitch_scale = randf_range(0.95, 1.1)
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	queue_free()

func spawn_death_drops() -> void:
	if not pickup_scene:
		return
		
	# Yellow Heavy: 100% Guaranteed Armor Vest drop
	if enemy_type == EnemyType.YELLOW_HEAVY:
		var vest = pickup_scene.instantiate()
		vest.item_type = 0 # ARMOR_VEST
		get_parent().add_child(vest)
		vest.global_position = global_position + Vector3(0, 0.35, 0)
		return
		
	# Blue Scout and Green Sniper: 12% drop chance for Bandages
	if enemy_type == EnemyType.BLUE_SCOUT or enemy_type == EnemyType.GREEN_SNIPER:
		if randf() <= 0.12:
			var bandage = pickup_scene.instantiate()
			bandage.item_type = 1 # BANDAGE
			get_parent().add_child(bandage)
			bandage.global_position = global_position + Vector3(0, 0.35, 0)
