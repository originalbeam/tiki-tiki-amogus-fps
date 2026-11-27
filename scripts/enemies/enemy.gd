extends CharacterBody3D

const AK47Model = preload("res://scripts/weapons/models/ak47_model.gd")
const PistolModel = preload("res://scripts/weapons/models/pistol_model.gd")
const AxeModel = preload("res://scripts/weapons/models/axe_model.gd")
const SniperModel = preload("res://scripts/weapons/models/sniper_model.gd")
const PreviewCrewmateScript = preload("res://scripts/ui/previews/preview_crewmate.gd")
const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")
const EngineerTurretScript = preload("res://scripts/enemies/engineer_turret.gd")

signal died(points)

enum EnemyType {
	RED_STANDARD,
	BLUE_SCOUT,
	YELLOW_HEAVY,
	GREEN_SNIPER,
	ORANGE_ENGINEER,
	BLACK_SHIELD,
	GRAY_SABOTEUR,
	GRAY_CLOAKER
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

# Stage 2 Special Class States (Engineer, Shield, Saboteur, Cloaker)
var engineer_deployed: bool = false
var engineer_deploy_timer: float = 3.2
var shield_body: StaticBody3D = null
var flank_dir_sign: float = 1.0
var is_cloaker_charging: bool = false
var cloaker_charge_cd: float = 1.8
var cloaker_retreat_timer: float = 0.0
var cloaker_siren_player: AudioStreamPlayer3D = null

enum TargetType {
	PLAYER
}
var current_target_type: TargetType = TargetType.PLAYER
var player: Node3D = null
var nav_manager: Node3D = null

var nav_path: PackedVector3Array = PackedVector3Array()
var nav_path_index: int = 0
var repath_timer: float = 0.0
var stuck_timer: float = 0.0
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
var suit_flash_meshes: Array[MeshInstance3D] = []
var flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	if audio_player:
		audio_player.bus = "Weapons"
	setup_type_attributes()
	health = max_health
	apply_materials()
	setup_weapon_visuals()
	
	shoot_timer = randf_range(0.5, shoot_interval)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	var navs = get_tree().get_nodes_in_group("nav_manager")
	if navs.size() > 0:
		nav_manager = navs[0]
		
	repath_timer = randf_range(0.1, 0.4)
	current_target_type = TargetType.PLAYER
		
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
			score_value = 6
			preferred_distance = 7.0
			is_melee = false
			is_sniper = false
			
		EnemyType.BLUE_SCOUT:
			crewmate_color = Color(0.15, 0.45, 0.95)
			laser_color = Color(0.3, 0.7, 1.0)
			move_speed = 6.2
			shoot_interval = 0.75
			bullet_damage = 8.0
			score_value = 10
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
			score_value = 20
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
			score_value = 16
			preferred_distance = 15.0
			is_melee = false
			is_sniper = true

		EnemyType.ORANGE_ENGINEER:
			crewmate_color = Color(0.95, 0.46, 0.08)
			laser_color = Color(1.0, 0.62, 0.18)
			move_speed = 4.0
			max_health = 135.0
			health = 135.0
			shoot_interval = 1.15
			bullet_damage = 9.0
			score_value = 22
			preferred_distance = 14.0
			is_melee = false
			is_sniper = false
			engineer_deploy_timer = randf_range(2.4, 4.0)

		EnemyType.BLACK_SHIELD:
			crewmate_color = Color(0.13, 0.14, 0.16)
			laser_color = Color(0.95, 0.72, 0.25)
			move_speed = 2.95
			max_health = 220.0
			health = 220.0
			shoot_interval = 1.25
			bullet_damage = 11.0
			score_value = 26
			preferred_distance = 5.0
			is_melee = false
			is_sniper = false

		EnemyType.GRAY_SABOTEUR:
			crewmate_color = Color(0.22, 0.24, 0.27)
			laser_color = Color(0.24, 0.92, 0.42)
			move_speed = 5.6
			max_health = 95.0
			health = 95.0
			shoot_interval = 1.35
			bullet_damage = 11.0
			score_value = 20
			preferred_distance = 10.5
			is_melee = false
			is_sniper = false
			flank_dir_sign = 1.0 if randf() < 0.5 else -1.0

		EnemyType.GRAY_CLOAKER:
			crewmate_color = Color(0.17, 0.19, 0.21)
			laser_color = Color(0.14, 1.0, 0.30)
			move_speed = 5.9
			max_health = 145.0
			health = 145.0
			shoot_interval = 1.2
			melee_damage = 32.0
			score_value = 35
			preferred_distance = 1.4
			is_melee = true
			is_sniper = false
			flank_dir_sign = 1.0 if randf() < 0.5 else -1.0
			cloaker_charge_cd = randf_range(1.2, 2.4)

	# Apply difficulty modifiers from GlobalSettings
	if GlobalSettings:
		move_speed *= GlobalSettings.get_enemy_speed_multiplier()
		bullet_damage *= GlobalSettings.get_enemy_damage_multiplier()
		melee_damage *= GlobalSettings.get_enemy_damage_multiplier()
		max_health *= GlobalSettings.get_enemy_health_multiplier()
		health = max_health
		shoot_interval *= GlobalSettings.get_enemy_shoot_rate_multiplier()

func apply_materials() -> void:
	# Rebuild full high-detail tactical Crewmate visuals (matching Handbook & unique class gear!)
	var visuals := get_node_or_null("Visuals") as Node3D
	if visuals:
		for child in visuals.get_children():
			if child != weapon_holder:
				visuals.remove_child(child)
				child.queue_free()
		var parts := PreviewCrewmateScript.populate_crewmate_visuals(visuals, crewmate_color, int(enemy_type))
		body_mesh = parts["body"]
		backpack_mesh = parts["backpack"]
		left_leg = parts["left_leg"]
		right_leg = parts["right_leg"]
		original_material = parts["suit_material"]
		suit_flash_meshes.clear()
		for sm in parts["suit_meshes"]:
			if sm is MeshInstance3D:
				suit_flash_meshes.append(sm)
	else:
		original_material = StandardMaterial3D.new()
		original_material.albedo_color = crewmate_color
		original_material.roughness = 0.35

func setup_weapon_visuals() -> void:
	if not weapon_holder:
		return
	# Remove any existing children
	for child in weapon_holder.get_children():
		child.queue_free()
		
	weapon_model_root = Node3D.new()
	weapon_holder.add_child(weapon_model_root)
	
	# Visual right hand/glove gripping the weapon (matches enemy crewmate suit color)
	var mat_hand := StandardMaterial3D.new()
	mat_hand.albedo_color = crewmate_color
	mat_hand.roughness = 0.35
	
	var hand := MeshInstance3D.new()
	var hm := CapsuleMesh.new()
	hm.radius = 0.08
	hm.height = 0.22
	hand.mesh = hm
	hand.material_override = mat_hand
	hand.rotation.x = deg_to_rad(25.0)
	hand.position = Vector3(0.02, -0.06, -0.02)
	weapon_model_root.add_child(hand)
	
	match enemy_type:
		EnemyType.RED_STANDARD:
			build_ak_visuals(weapon_model_root)
		EnemyType.BLUE_SCOUT:
			build_pistol_visuals(weapon_model_root)
		EnemyType.YELLOW_HEAVY:
			build_axe_visuals(weapon_model_root)
		EnemyType.GREEN_SNIPER:
			build_awp_visuals(weapon_model_root)
		EnemyType.ORANGE_ENGINEER:
			build_pistol_visuals(weapon_model_root)
		EnemyType.BLACK_SHIELD:
			build_pistol_visuals(weapon_model_root)
			_setup_ballistic_shield()
		EnemyType.GRAY_SABOTEUR:
			build_ak_visuals(weapon_model_root)
			_attach_suppressed_can(weapon_model_root)
		EnemyType.GRAY_CLOAKER:
			_build_cloaker_baton(weapon_model_root)
			cloaker_siren_player = AudioStreamPlayer3D.new()
			cloaker_siren_player.bus = "SFX"
			cloaker_siren_player.stream = SoundEffects.create_cloaker_charge_sound()
			cloaker_siren_player.max_distance = 65.0
			cloaker_siren_player.unit_size = 14.0
			cloaker_siren_player.volume_db = 3.5
			add_child(cloaker_siren_player)

func _setup_ballistic_shield() -> void:
	# Physical steel ballistic shield with narrow upper viewport slit!
	# Lower & upper steel plates deflect non-AP bullets; narrow viewport slit lets precision headshots through!
	shield_body = StaticBody3D.new()
	shield_body.name = "BallisticShield"
	shield_body.collision_layer = 1
	shield_body.collision_mask = 0
	shield_body.position = Vector3(0.06, 0.0, 0.72)
	shield_body.add_to_group("enemy_shield")
	shield_body.set_meta("shield_owner", self)
	add_child(shield_body)

	var m_steel := StandardMaterial3D.new()
	m_steel.albedo_color = Color(0.11, 0.12, 0.14)
	m_steel.metallic = 0.84
	m_steel.roughness = 0.36
	var m_stripe := StandardMaterial3D.new()
	m_stripe.albedo_color = Color(0.86, 0.72, 0.24)
	m_stripe.roughness = 0.55
	var m_glass := StandardMaterial3D.new()
	m_glass.albedo_color = Color(0.30, 0.62, 0.76, 0.42)
	m_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Lower steel armor plate (y = 0.14 .. 1.12)
	var low_col := CollisionShape3D.new()
	var low_bs := BoxShape3D.new(); low_bs.size = Vector3(0.94, 0.98, 0.08)
	low_col.shape = low_bs; low_col.position = Vector3(0, 0.63, 0)
	shield_body.add_child(low_col)
	var low_mi := MeshInstance3D.new(); low_mi.name = "ShieldPlate"; var lbm := BoxMesh.new(); lbm.size = Vector3(0.94, 0.98, 0.06)
	low_mi.mesh = lbm; low_mi.material_override = m_steel; low_mi.position = Vector3(0, 0.63, 0)
	shield_body.add_child(low_mi)

	# Upper steel forehead brow above viewport slit (y = 1.32 .. 1.66)
	var top_col := CollisionShape3D.new()
	var top_bs := BoxShape3D.new(); top_bs.size = Vector3(0.94, 0.34, 0.08)
	top_col.shape = top_bs; top_col.position = Vector3(0, 1.49, 0)
	shield_body.add_child(top_col)
	var top_mi := MeshInstance3D.new(); var tbm := BoxMesh.new(); tbm.size = Vector3(0.94, 0.34, 0.06)
	top_mi.mesh = tbm; top_mi.material_override = m_steel; top_mi.position = Vector3(0, 1.49, 0)
	shield_body.add_child(top_mi)

	# Side steel pillars flanking the narrow glass slit (so center viewport y=1.12..1.32, x=-0.26..+0.26 is shootable!)
	for sx in [-0.36, 0.36]:
		var pc := CollisionShape3D.new()
		var pbs := BoxShape3D.new(); pbs.size = Vector3(0.22, 0.22, 0.08)
		pc.shape = pbs; pc.position = Vector3(sx, 1.22, 0)
		shield_body.add_child(pc)
		var pm := MeshInstance3D.new(); var pbm := BoxMesh.new(); pbm.size = Vector3(0.22, 0.22, 0.06)
		pm.mesh = pbm; pm.material_override = m_steel; pm.position = Vector3(sx, 1.22, 0)
		shield_body.add_child(pm)

	# Visual transparent slit window + yellow SWAT trim stripe
	var gl_mi := MeshInstance3D.new(); var gbm := BoxMesh.new(); gbm.size = Vector3(0.50, 0.18, 0.025)
	gl_mi.mesh = gbm; gl_mi.material_override = m_glass; gl_mi.position = Vector3(0, 1.22, 0)
	shield_body.add_child(gl_mi)
	var st_mi := MeshInstance3D.new(); var sbm := BoxMesh.new(); sbm.size = Vector3(0.86, 0.08, 0.07)
	st_mi.mesh = sbm; st_mi.material_override = m_stripe; st_mi.position = Vector3(0, 0.96, 0.005)
	shield_body.add_child(st_mi)

func _attach_suppressed_can(parent: Node3D) -> void:
	var sup := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.026; cm.bottom_radius = 0.026; cm.height = 0.24; cm.radial_segments = 10
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.08, 0.09, 0.10); sm.metallic = 0.80; sm.roughness = 0.35
	sup.mesh = cm; sup.material_override = sm
	sup.position = Vector3(0, 0.02, 0.62)
	sup.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(sup)
	if muzzle_marker:
		muzzle_marker.position = Vector3(0, 0.02, 0.76)

func _build_cloaker_baton(parent: Node3D) -> void:
	var m_bat := StandardMaterial3D.new(); m_bat.albedo_color = Color(0.10, 0.11, 0.12); m_bat.metallic = 0.85; m_bat.roughness = 0.28
	var m_tip := StandardMaterial3D.new(); m_tip.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m_tip.albedo_color = Color(0.14, 1.0, 0.36)
	var b := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.024; cm.bottom_radius = 0.024; cm.height = 0.68
	b.mesh = cm; b.material_override = m_bat; b.position = Vector3(0, 0.06, 0.28); b.rotation_degrees = Vector3(62, 0, 0)
	parent.add_child(b)
	var tip := MeshInstance3D.new(); var tcm := CylinderMesh.new(); tcm.top_radius = 0.028; tcm.bottom_radius = 0.028; tcm.height = 0.10
	tip.mesh = tcm; tip.material_override = m_tip; tip.position = Vector3(0, 0.22, 0.56); tip.rotation_degrees = Vector3(62, 0, 0)
	parent.add_child(tip)

func build_ak_visuals(parent: Node3D) -> void:
	var ak = AK47Model.create()
	ak.scale = Vector3(1.15, 1.15, 1.15)
	# AK47Model faces -Z by default, rotate 180 deg to point forward (+Z) at the player
	ak.rotation.y = PI
	ak.position = Vector3(0, 0.02, 0.05)
	parent.add_child(ak)
	
	# Muzzle Marker at tip of the forward-facing AK barrel
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.02, 0.52)
	parent.add_child(muzzle_marker)

func build_pistol_visuals(parent: Node3D) -> void:
	var pst = PistolModel.create()
	pst.scale = Vector3(1.25, 1.25, 1.25)
	# PistolModel faces -Z by default, rotate 180 deg to point forward (+Z) at the player
	pst.rotation.y = PI
	pst.position = Vector3(0, 0.01, 0.02)
	parent.add_child(pst)
	
	# Muzzle Marker at tip of the forward-facing slide
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.03, 0.22)
	parent.add_child(muzzle_marker)

func build_axe_visuals(parent: Node3D) -> void:
	# Axe Root container tilted at ready carrying/chopping angle
	var axe_root := Node3D.new()
	axe_root.rotation.x = deg_to_rad(65.0)
	parent.add_child(axe_root)

	var axe = AxeModel.create()
	axe_root.add_child(axe)

func build_awp_visuals(parent: Node3D) -> void:
	var awp = SniperModel.create()
	# SniperModel points forward (+Z)
	awp.scale = Vector3(1.05, 1.05, 1.05)
	parent.add_child(awp)

	# Telescopic Scope Glint indicator (blinks before shooting)
	scope_glint_node = Node3D.new()
	scope_glint_node.position = Vector3(0, 0.128, 0.285)
	scope_glint_node.visible = false
	parent.add_child(scope_glint_node)
	
	var glint_quad := MeshInstance3D.new()
	var q_m := QuadMesh.new()
	q_m.size = Vector2(0.9, 0.9)
	glint_quad.mesh = q_m
	
	var g_mat := StandardMaterial3D.new()
	g_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	g_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	g_mat.albedo_color = Color(0.4, 1.0, 0.85, 0.98)
	g_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glint_quad.material_override = g_mat
	scope_glint_node.add_child(glint_quad)
	
	var g_light := OmniLight3D.new()
	g_light.light_color = Color(0.3, 1.0, 0.7)
	g_light.light_energy = 4.5
	g_light.omni_range = 14.0
	scope_glint_node.add_child(g_light)
	
	# Muzzle Marker at tip of the AWP muzzle brake
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.046, 1.13)
	parent.add_child(muzzle_marker)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Damage flash reset
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0 and original_material:
			for sm in suit_flash_meshes:
				if is_instance_valid(sm):
					sm.material_override = original_material

	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	if not is_instance_valid(nav_manager):
		var navs = get_tree().get_nodes_in_group("nav_manager")
		if navs.size() > 0:
			nav_manager = navs[0]

	# --- TARGETING SYSTEM ---
	var dist_to_player := 999.0
	if is_instance_valid(player):
		dist_to_player = global_position.distance_to(player.global_position)
		
	current_target_type = TargetType.PLAYER
	var target_dest := Vector3.ZERO
	if is_instance_valid(player):
		target_dest = player.global_position
	else:
		move_and_slide()
		return

	# --- PATHFINDING & NAVIGATION AI ---
	repath_timer -= delta
	if repath_timer <= 0.0:
		repath_timer = randf_range(0.45, 0.75)
		if nav_manager and nav_manager.has_method("get_navigation_path"):
			nav_path = nav_manager.get_navigation_path(global_position, target_dest)
			nav_path_index = 0

	var move_dir := Vector3.ZERO
	if nav_path.size() > 0 and nav_path_index < nav_path.size():
		var wp := nav_path[nav_path_index]
		var to_wp := wp - global_position
		to_wp.y = 0
		var wp_len := to_wp.length()
		if wp_len < 1.4:
			nav_path_index += 1
			if nav_path_index < nav_path.size():
				wp = nav_path[nav_path_index]
				to_wp = wp - global_position
				to_wp.y = 0
				wp_len = to_wp.length()
		if wp_len > 0.05:
			move_dir = to_wp.normalized()
	else:
		var direct := target_dest - global_position
		direct.y = 0
		if direct.length_squared() > 0.05:
			move_dir = direct.normalized()

	# Dynamic Whisker Obstacle Avoidance
	var space_state = get_world_3d().direct_space_state
	var forward = move_dir if move_dir.length_squared() > 0.01 else -transform.basis.z
	var whisker_l = forward.rotated(Vector3.UP, deg_to_rad(32.0)) * 2.2
	var whisker_r = forward.rotated(Vector3.UP, deg_to_rad(-32.0)) * 2.2
	
	var whisker_excl: Array[RID] = [get_rid()]
	if is_instance_valid(shield_body):
		whisker_excl.append(shield_body.get_rid())
	var ray_l = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.6, 0), global_position + Vector3(0, 0.6, 0) + whisker_l)
	ray_l.collision_mask = 1 # World / obstacles
	ray_l.exclude = whisker_excl
	var ray_r = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.6, 0), global_position + Vector3(0, 0.6, 0) + whisker_r)
	ray_r.collision_mask = 1
	ray_r.exclude = whisker_excl
	
	var hit_l = space_state.intersect_ray(ray_l)
	var hit_r = space_state.intersect_ray(ray_r)
	if not hit_l.is_empty():
		move_dir = (move_dir + forward.cross(Vector3.UP) * 0.8).normalized()
	elif not hit_r.is_empty():
		move_dir = (move_dir - forward.cross(Vector3.UP) * 0.8).normalized()

	# Look towards player
	var look_target := target_dest
	if is_instance_valid(player):
		look_target = player.global_position
	var dir_to_look := (look_target - global_position)
	dir_to_look.y = 0
	if dir_to_look.length_squared() > 0.01:
		var target_rot = atan2(dir_to_look.x, dir_to_look.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 7.0)

	# Movement logic
	var desired_velocity = Vector3.ZERO
	var active_dist = dist_to_player

	if enemy_type == EnemyType.GRAY_CLOAKER:
		cloaker_charge_cd = maxf(0.0, cloaker_charge_cd - delta)
		if cloaker_retreat_timer > 0.0:
			cloaker_retreat_timer -= delta
			var away_dir: Vector3 = -dir_to_look.normalized() if dir_to_look.length_squared() > 0.01 else -move_dir
			desired_velocity = (away_dir + away_dir.cross(Vector3.UP) * flank_dir_sign * 0.45).normalized() * 7.6
		elif is_cloaker_charging:
			desired_velocity = move_dir * 9.8
			if active_dist <= 2.25 and is_instance_valid(player):
				if player.has_method("apply_cloaker_knockdown"):
					player.apply_cloaker_knockdown(global_position, melee_damage)
				elif player.has_method("take_damage"):
					player.take_damage(melee_damage)
				is_cloaker_charging = false
				cloaker_retreat_timer = 1.25
				cloaker_charge_cd = 4.4
				if cloaker_siren_player and cloaker_siren_player.playing:
					cloaker_siren_player.stop()
				var leap_dir: Vector3 = -dir_to_look.normalized() if dir_to_look.length_squared() > 0.01 else -move_dir
				velocity.x = leap_dir.x * 8.4
				velocity.z = leap_dir.z * 8.4
				velocity.y = 4.2
			elif active_dist > 34.0:
				is_cloaker_charging = false
				if cloaker_siren_player and cloaker_siren_player.playing:
					cloaker_siren_player.stop()
		else:
			if active_dist <= 24.0 and cloaker_charge_cd <= 0.0 and has_line_of_sight():
				is_cloaker_charging = true
				if cloaker_siren_player:
					cloaker_siren_player.pitch_scale = randf_range(0.96, 1.05)
					cloaker_siren_player.play()
				desired_velocity = move_dir * 9.8
			else:
				# Stalk sideways while closing distance
				var stalk_side: Vector3 = dir_to_look.normalized().cross(Vector3.UP) * flank_dir_sign if dir_to_look.length_squared() > 0.01 else Vector3.ZERO
				desired_velocity = (move_dir * 0.80 + stalk_side * 0.55).normalized() * move_speed
	elif is_melee:
		# Berserker Yellow rushes directly along path to player
		if active_dist > 2.0:
			desired_velocity = move_dir * move_speed
		else:
			desired_velocity = move_dir * (move_speed * 0.3)
	elif enemy_type == EnemyType.BLACK_SHIELD:
		# Heavy Ballistic Shield advances steadily head-on, keeping steel shield angled toward player
		if dist_to_player > preferred_distance + 0.8:
			desired_velocity = move_dir * move_speed
		elif dist_to_player < 3.6:
			desired_velocity = -move_dir * (move_speed * 0.45)
		else:
			var shield_strafe: Vector3 = dir_to_look.normalized().cross(Vector3.UP) * flank_dir_sign if dir_to_look.length_squared() > 0.01 else Vector3.ZERO
			desired_velocity = shield_strafe * (move_speed * 0.35)
	elif enemy_type == EnemyType.GRAY_SABOTEUR:
		# Night Saboteur flanks wide around the player in silence
		var flank_side: Vector3 = dir_to_look.normalized().cross(Vector3.UP) * flank_dir_sign if dir_to_look.length_squared() > 0.01 else Vector3.ZERO
		if dist_to_player > preferred_distance + 2.0:
			desired_velocity = (move_dir * 0.72 + flank_side * 0.68).normalized() * move_speed
		elif dist_to_player < preferred_distance - 3.5:
			desired_velocity = (-move_dir * 0.65 + flank_side * 0.75).normalized() * (move_speed * 0.88)
		else:
			desired_velocity = flank_side * (move_speed * 0.85)
	else:
		# Ranged enemies (Red, Blue, Green, Orange Engineer) maintain preferred distance
		if dist_to_player > preferred_distance + 1.2:
			desired_velocity = move_dir * move_speed
		elif dist_to_player < preferred_distance - 2.5:
			desired_velocity = -move_dir * (move_speed * 0.7)
		else:
			var strafe_player = dir_to_look.normalized().cross(Vector3.UP)
			desired_velocity = strafe_player * (move_speed * 0.5)

	# Orange Engineer deploys a portable Sentry Turret + drops 1 fresh Fuel Barrel once in range!
	if enemy_type == EnemyType.ORANGE_ENGINEER and not engineer_deployed and dist_to_player <= 26.0:
		engineer_deploy_timer -= delta
		if engineer_deploy_timer <= 0.0:
			_deploy_engineer_gear()

	# Sniper slows down while aiming with glint
	if is_sniper and glint_active:
		desired_velocity *= 0.15

	# Stuck recovery
	var horiz_vel = Vector2(velocity.x, velocity.z).length()
	if horiz_vel < 0.25 and desired_velocity.length_squared() > 0.5:
		stuck_timer += delta
		if stuck_timer > 0.75:
			stuck_timer = 0.0
			repath_timer = 0.0
			velocity.x += randf_range(-2.5, 2.5)
			velocity.z += randf_range(-2.5, 2.5)
	else:
		stuck_timer = 0.0

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
	handle_attacks(delta, active_dist)

func _deploy_engineer_gear() -> void:
	engineer_deployed = true
	if not is_inside_tree() or not get_parent():
		return
	var side_vec: Vector3 = transform.basis.x
	side_vec.y = 0.0
	if side_vec.length_squared() < 0.01:
		side_vec = Vector3.RIGHT
	side_vec = side_vec.normalized()
	var turret_pos: Vector3 = global_position + side_vec * 1.55
	turret_pos.x = clampf(turret_pos.x, -42.0, 42.0)
	turret_pos.z = clampf(turret_pos.z, -42.0, 42.0)
	turret_pos.y = 0.0
	var turret: Node3D = EngineerTurretScript.new()
	get_parent().add_child(turret)
	turret.global_position = turret_pos
	play_sfx(SoundEffects.create_turret_deploy_sound(), 1.0)
	# Also drop 1 fresh Fuel Barrel onto the arena for dynamic logistics!
	var mgrs := get_tree().get_nodes_in_group("arena_interactables")
	if mgrs.size() > 0 and mgrs[0].has_method("spawn_enemy_dropped_barrel"):
		var barrel_pos: Vector3 = global_position - side_vec * 1.45
		barrel_pos.x = clampf(barrel_pos.x, -42.0, 42.0)
		barrel_pos.z = clampf(barrel_pos.z, -42.0, 42.0)
		barrel_pos.y = 0.0
		mgrs[0].spawn_enemy_dropped_barrel(barrel_pos)

func handle_attacks(delta: float, active_dist: float) -> void:
	if enemy_type == EnemyType.GRAY_CLOAKER:
		# Cloaker attacks purely via sprint-charge knockdown in _physics_process
		return
	elif is_melee:
		handle_melee_axe(delta, active_dist)
	elif is_sniper:
		handle_sniper_attack(delta, active_dist)
	elif enemy_type == EnemyType.RED_STANDARD or enemy_type == EnemyType.GRAY_SABOTEUR:
		handle_burst_attack(delta, active_dist)
	else: # Blue Scout, Orange Engineer, Black Shield semi-auto
		handle_pistol_attack(delta, active_dist)

func handle_melee_axe(delta: float, active_dist: float) -> void:
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
		var can_swing := false
		if is_instance_valid(player):
			can_swing = global_position.distance_to(player.global_position) <= 2.2
			
		if can_swing and shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			is_swinging_axe = true
			axe_swing_timer = 0.0
			axe_hit_registered = false
			play_sfx(SoundEffects.create_axe_swing_sound())

func handle_sniper_attack(delta: float, active_dist: float) -> void:
	const MAX_ENGAGE_DIST_SNIPER: float = 45.0
	shoot_timer -= delta
	var in_range: bool = (active_dist <= MAX_ENGAGE_DIST_SNIPER)
	var has_los: bool = in_range and has_line_of_sight()
	
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
		if has_los:
			shoot_timer = shoot_interval + randf_range(-0.2, 0.3)
			spawn_sniper_shot()
		else:
			# Not in range or blocked: keep rifle primed with short reaction buffer
			shoot_timer = 0.35
		if scope_glint_node:
			scope_glint_node.visible = false
		glint_active = false

func spawn_sniper_shot() -> void:
	if not bullet_scene:
		return
	var target_pos := get_current_target_center()
	var spawn_pos: Vector3 = muzzle_marker.global_position if muzzle_marker else (global_position + Vector3(0, 0.8, 0))
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	var shoot_dir: Vector3 = (target_pos - spawn_pos).normalized()
	# Sniper bullet flies at 55.0 m/s with 48 damage (travels until collision or boundary)
	bullet.init(shoot_dir, bullet_damage, laser_color, 55.0)
	VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), spawn_pos, shoot_dir, Color(1.0, 0.85, 0.35), 1.35)
	play_sfx(SoundEffects.create_awp_sound())

func handle_burst_attack(delta: float, active_dist: float) -> void:
	const MAX_ENGAGE_DIST_AK: float = 26.0
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
		var max_rng: float = 30.0 if enemy_type == EnemyType.GRAY_SABOTEUR else MAX_ENGAGE_DIST_AK
		if active_dist <= max_rng and has_line_of_sight():
			shoot_timer = shoot_interval + randf_range(-0.15, 0.2)
			is_bursting = true
			burst_shots_left = 2 if enemy_type == EnemyType.GRAY_SABOTEUR else 3
			burst_shot_timer = 0.0
		else:
			# Not in range or blocked: keep weapon primed with small reaction delay
			shoot_timer = 0.25

func handle_pistol_attack(delta: float, active_dist: float) -> void:
	const MAX_ENGAGE_DIST_PISTOL: float = 18.0
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		if active_dist <= MAX_ENGAGE_DIST_PISTOL and has_line_of_sight():
			shoot_timer = shoot_interval + randf_range(-0.08, 0.08)
			spawn_standard_bullet()
		else:
			# Not in range or blocked: keep weapon primed with small reaction delay
			shoot_timer = 0.20

func get_current_target_center() -> Vector3:
	if is_instance_valid(player):
		return player.global_position + Vector3(0, 0.85, 0)
	return global_position + Vector3(0, 1.0, 5.0)

func spawn_standard_bullet() -> void:
	if not bullet_scene:
		return
	var target_center := get_current_target_center()
	var spawn_pos: Vector3 = muzzle_marker.global_position if muzzle_marker else (global_position + Vector3(0, 0.8, 0))
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	var spread: float = 0.06 if enemy_type == EnemyType.GRAY_SABOTEUR else (0.08 if enemy_type == EnemyType.BLUE_SCOUT else 0.12)
	var target_pos: Vector3 = target_center + Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		randf_range(-spread, spread)
	)
	var shoot_dir: Vector3 = (target_pos - spawn_pos).normalized()
	var spd: float = 31.0 if enemy_type == EnemyType.GRAY_SABOTEUR else 26.0
	bullet.init(shoot_dir, bullet_damage, laser_color, spd)
	if enemy_type == EnemyType.GRAY_SABOTEUR:
		# Quiet suppressed carbine: tiny subdued dark-green flash + hushed -13 dB thump!
		VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), spawn_pos, shoot_dir, Color(0.28, 0.72, 0.42), 0.32)
		play_sfx(SoundEffects.create_pistol_sound(), -13.0)
	elif enemy_type == EnemyType.RED_STANDARD:
		VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), spawn_pos, shoot_dir, Color(1.0, 0.72, 0.25), 0.95)
		play_sfx(SoundEffects.get_enemy_ak47_sound(), -6.0)
	else:
		VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), spawn_pos, shoot_dir, Color(1.0, 0.72, 0.25), 0.72)
		play_sfx(SoundEffects.create_pistol_sound(), -2.0)

# Robust raycast check ignoring other enemies & own ballistic shield and hitting layer 1 (world)
func has_line_of_sight() -> bool:
	var target_center := get_current_target_center()
	var space_state = get_world_3d().direct_space_state
	var from_pos: Vector3 = global_position + Vector3(0, 1.1, 0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, target_center)
	query.collision_mask = 1 # World layer
	var excl: Array[RID] = [get_rid()]
	if is_instance_valid(shield_body):
		excl.append(shield_body.get_rid())
	query.exclude = excl
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return true
	if is_instance_valid(player) and (result.collider == player or (result.collider and result.collider.is_in_group("player"))):
		return true
	var dist_to_hit: float = from_pos.distance_to(result.position)
	var dist_to_target: float = from_pos.distance_to(target_center)
	return dist_to_hit >= (dist_to_target - 0.6)

func play_sfx(stream: AudioStream, vol_db: float = 0.0) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.pitch_scale = randf_range(0.93, 1.07)
		audio_player.volume_db = vol_db
		audio_player.play()

func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	if health <= 0:
		return
	health -= amount
	if health_bar:
		health_bar.value = health
		
	# Damage flash across all suit parts
	flash_timer = 0.08
	var hit_mat = StandardMaterial3D.new()
	hit_mat.albedo_color = Color(1.0, 1.0, 1.0)
	hit_mat.emission_enabled = true
	hit_mat.emission = Color(1.0, 0.4, 0.4)
	hit_mat.emission_energy_multiplier = 2.0
	for sm in suit_flash_meshes:
		if is_instance_valid(sm):
			sm.material_override = hit_mat
	
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
	sfx.bus = "SFX"
	sfx.stream = SoundEffects.create_explosion_gib_sound()
	sfx.pitch_scale = randf_range(0.95, 1.1)
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	queue_free()

func spawn_death_drops() -> void:
	if not pickup_scene:
		return
		
	# Yellow Heavy & Black Shield: 100% Guaranteed Armor Vest drop
	if enemy_type == EnemyType.YELLOW_HEAVY or enemy_type == EnemyType.BLACK_SHIELD:
		var vest = pickup_scene.instantiate()
		vest.item_type = 0 # ARMOR_VEST
		get_parent().add_child(vest)
		vest.global_position = global_position + Vector3(0, 0.35, 0)
		return

	# Orange Engineer: 55% chance for Armor Vest or Bandage
	if enemy_type == EnemyType.ORANGE_ENGINEER:
		if randf() <= 0.55:
			var item = pickup_scene.instantiate()
			item.item_type = 0 if randf() <= 0.45 else 1
			get_parent().add_child(item)
			item.global_position = global_position + Vector3(0, 0.35, 0)
		return

	# Gray Cloaker: 65% chance for Bandage
	if enemy_type == EnemyType.GRAY_CLOAKER:
		if randf() <= 0.65:
			var bandage_c = pickup_scene.instantiate()
			bandage_c.item_type = 1 # BANDAGE
			get_parent().add_child(bandage_c)
			bandage_c.global_position = global_position + Vector3(0, 0.35, 0)
		return

	# Blue Scout, Green Sniper & Gray Saboteur: 14% drop chance for Bandages
	if enemy_type == EnemyType.BLUE_SCOUT or enemy_type == EnemyType.GREEN_SNIPER or enemy_type == EnemyType.GRAY_SABOTEUR:
		if randf() <= 0.14:
			var bandage = pickup_scene.instantiate()
			bandage.item_type = 1 # BANDAGE
			get_parent().add_child(bandage)
			bandage.global_position = global_position + Vector3(0, 0.35, 0)
