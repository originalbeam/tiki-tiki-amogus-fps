class_name Mi24Boss
extends Node3D

# =============================================================================
# WAVE 10 AIRBORNE BOSS: Mi-24 «Крокодил» (Hind Attack Helicopter)
# - Detailed 3D Tandem-Cockpit Gunship with visible CrewPilot & CrewGunner!
# - 8 Modular Hitboxes: engine_l, engine_r, tail_rotor, pod_l, pod_r,
#   cockpit_gunner (armored glass), cockpit_pilot (armored glass), hull.
# - AI States: ORBITING -> CANNON_STRAFE (laser telegraph + 12.7mm bursts) /
#   ROCKET_BARRAGE (ground red rings + explosive S-8 rockets) / DEPLOYING_TROOPS
#   (drops 2-3 airborne infantry with parachutes) -> CRASHING (tail-rotor flat
#   spin or dual-engine dive -> massive fiery ground explosion!).
# - Thermal FLIR Ready: hot twin ТВ3-117 engines, exhausts, chin barrel & crew.
# =============================================================================

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")
const PreviewCrewmateScript = preload("res://scripts/ui/previews/preview_crewmate.gd")

signal died(points)

enum BossState {
	ORBITING,
	CANNON_STRAFE,
	ROCKET_BARRAGE,
	DEPLOYING_TROOPS,
	CRASHING,
	DESTROYED
}

var boss_state: BossState = BossState.ORBITING
var is_dead: bool = false
var score_value: int = 520

# Structural & Modular Hitpoints
const MAX_HULL_HP: float = 1600.0
const MAX_ENGINE_HP: float = 340.0
const MAX_TAIL_HP: float = 220.0
const MAX_POD_HP: float = 210.0
const MAX_GUNNER_HP: float = 180.0
const MAX_PILOT_HP: float = 220.0

var hull_hp: float = MAX_HULL_HP
var engine_l_hp: float = MAX_ENGINE_HP
var engine_r_hp: float = MAX_ENGINE_HP
var tail_rotor_hp: float = MAX_TAIL_HP
var pod_l_hp: float = MAX_POD_HP
var pod_r_hp: float = MAX_POD_HP
var gunner_hp: float = MAX_GUNNER_HP
var pilot_hp: float = MAX_PILOT_HP

var pilot_alive: bool = true
var gunner_alive: bool = true
var engine_l_dead: bool = false
var engine_r_dead: bool = false
var tail_rotor_dead: bool = false
var pod_l_dead: bool = false
var pod_r_dead: bool = false

# References
var player: Node3D = null
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var bullet_scene: PackedScene = preload("res://scenes/enemy_bullet.tscn")
var model_root: Node3D = null
var main_rotor: Node3D = null
var tail_rotor: Node3D = null
var chin_turret: Node3D = null
var chin_muzzle: Marker3D = null
var laser_beam: MeshInstance3D = null
var rotor_sfx: AudioStreamPlayer3D = null
var engine_smoke_l: CPUParticles3D = null
var engine_smoke_r: CPUParticles3D = null
var crash_smoke: CPUParticles3D = null
var wreck_fire_light: OmniLight3D = null
var wreck_fire_audio: AudioStreamPlayer3D = null
var flying_debris: Array[Dictionary] = []
var wreck_aabb_registered: bool = false

# Flight & Combat AI Timers
var orbit_angle: float = 0.0
var orbit_dir: float = 1.0
var orbit_radius: float = 25.0
var target_altitude: float = 19.5
var state_timer: float = 4.5
var strafe_burst_cd: float = 0.0
var strafe_shots_left: int = 0
var rocket_telegraph_done: bool = false
var pending_rocket_targets: Array[Vector3] = []
var active_warning_rings: Array[Node3D] = []
var flare_cooldown: float = 0.0
var troops_deployed_count: int = 0
var max_troop_drops: int = 2
var crash_spin_speed: float = 0.0
var crash_vel: Vector3 = Vector3.ZERO
var hud_sync_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("mi24_boss")
	_build_full_helicopter()
	_setup_audio()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node3D

	orbit_angle = randf_range(0.0, TAU)
	global_position = Vector3(cos(orbit_angle) * 32.0, 22.0, sin(orbit_angle) * 32.0)

	var hud_ref := _find_mi24_hud()
	if hud_ref and hud_ref.has_method("show_boss"):
		hud_ref.show_boss()
	_sync_boss_hud()

static func _m(col: Color, met: float = 0.35, rough: float = 0.58) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = met
	mat.roughness = rough
	return mat

static func _add_box(parent: Node3D, n: String, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, n: String, tr: float, br: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var cm := CylinderMesh.new()
	cm.top_radius = tr
	cm.bottom_radius = br
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

# Shared Static 3D Model Builder (used by live Mi-24 Boss AND Handbook 3D Preview!)
static func create_preview_model() -> Node3D:
	var root := Node3D.new()
	root.name = "Mi24Model"

	var m_olive := _m(Color(0.26, 0.31, 0.22), 0.28, 0.62)
	var m_camo := _m(Color(0.36, 0.33, 0.22), 0.25, 0.68)
	var m_belly := _m(Color(0.42, 0.50, 0.54), 0.22, 0.64) # Soviet light-blue underside
	var m_dark := _m(Color(0.14, 0.15, 0.16), 0.72, 0.38)
	var m_steel := _m(Color(0.28, 0.30, 0.33), 0.85, 0.32)
	var m_exhaust := _m(Color(0.22, 0.18, 0.16), 0.88, 0.36)
	var m_star := _m(Color(0.84, 0.12, 0.10), 0.18, 0.45)

	var m_glass := StandardMaterial3D.new()
	m_glass.albedo_color = Color(0.18, 0.32, 0.38, 0.56)
	m_glass.metallic = 0.35
	m_glass.roughness = 0.08
	m_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# 1. Main Armored Fuselage (nose at -Z, tail at +Z)
	_add_box(root, "FuselageMain", Vector3(1.85, 1.75, 5.2), Vector3(0, 0.15, 0.2), m_olive)
	_add_box(root, "FuselageBelly", Vector3(1.70, 0.42, 5.0), Vector3(0, -0.78, 0.15), m_belly)
	_add_box(root, "FuselageCamoPatch", Vector3(1.88, 0.75, 2.2), Vector3(0, 0.45, 0.9), m_camo)
	_add_box(root, "NoseLower", Vector3(1.38, 0.95, 2.25), Vector3(0, -0.25, -3.25), m_olive, Vector3(10.0, 0, 0))
	_add_box(root, "NoseTip", Vector3(0.95, 0.65, 0.95), Vector3(0, -0.45, -4.45), m_dark, Vector3(18.0, 0, 0))

	# 2. Iconic Stepped Tandem Dual-Bubble Cockpit + Visible Crewmates!
	_add_box(root, "CanopyGunnerGlass", Vector3(1.16, 0.86, 1.65), Vector3(0, 0.52, -3.15), m_glass, Vector3(-16.0, 0, 0))
	_add_box(root, "CanopyPilotGlass", Vector3(1.26, 0.96, 1.85), Vector3(0, 1.15, -1.65), m_glass, Vector3(-8.0, 0, 0))
	_add_box(root, "CanopyFrameCenter", Vector3(1.32, 0.14, 0.18), Vector3(0, 0.95, -2.42), m_dark)

	# Front Operator/Gunner Crewmate (Green suit)
	var gunner := PreviewCrewmateScript.create(Color(0.18, 0.72, 0.28), 3)
	gunner.name = "CrewGunner"
	gunner.scale = Vector3(0.46, 0.46, 0.46)
	gunner.position = Vector3(0, 0.08, -3.10)
	gunner.rotation_degrees = Vector3(0, 180.0, 0)
	root.add_child(gunner)

	# Rear Pilot Crewmate (Red suit, elevated seat)
	var pilot := PreviewCrewmateScript.create(Color(0.86, 0.16, 0.14), 0)
	pilot.name = "CrewPilot"
	pilot.scale = Vector3(0.48, 0.48, 0.48)
	pilot.position = Vector3(0, 0.65, -1.62)
	pilot.rotation_degrees = Vector3(0, 180.0, 0)
	root.add_child(pilot)

	# 3. Twin Side ТВ3-117 Turbine Engines + Hot Exhaust Ports (Glow Bright in FLIR!)
	for side_i in [-1, 1]:
		var s_tag: String = "L" if side_i < 0 else "R"
		var sx: float = float(side_i) * 0.92
		_add_cyl(root, "EngineNacelle" + s_tag, 0.46, 0.44, 2.95, Vector3(sx, 1.25, 0.25), m_camo, 12, Vector3(90.0, 0, 0))
		_add_cyl(root, "IntakeRing" + s_tag, 0.36, 0.36, 0.25, Vector3(sx, 1.25, -1.25), m_dark, 12, Vector3(90.0, 0, 0))
		_add_cyl(root, "ExhaustPort" + s_tag, 0.32, 0.28, 0.65, Vector3(float(side_i) * 1.18, 1.22, 1.48), m_exhaust, 10, Vector3(72.0, float(side_i) * 28.0, 0))

	# 4. Anhedral Stubby Weapons Wings + B-8V20 S-8 Rocket Pods!
	for side_i in [-1, 1]:
		var s_tag: String = "L" if side_i < 0 else "R"
		var wx: float = float(side_i) * 2.25
		_add_box(root, "StubWing" + s_tag, Vector3(2.85, 0.22, 1.38), Vector3(wx, 0.10, 0.05), m_olive, Vector3(0, 0, float(side_i) * -12.0))
		_add_box(root, "WingTipEnd" + s_tag, Vector3(0.18, 0.56, 1.05), Vector3(float(side_i) * 3.65, -0.18, 0.05), m_dark)

		var pod_root := Node3D.new()
		pod_root.name = "RocketPod" + s_tag
		pod_root.position = Vector3(float(side_i) * 2.55, -0.46, -0.10)
		root.add_child(pod_root)
		_add_cyl(pod_root, "PodBody", 0.32, 0.32, 1.95, Vector3.ZERO, m_steel, 12, Vector3(90.0, 0, 0))
		_add_cyl(pod_root, "PodNose", 0.22, 0.32, 0.36, Vector3(0, 0, -1.12), m_dark, 12, Vector3(90.0, 0, 0))
		# Outer ATGM missile rails
		_add_cyl(pod_root, "ATGMTube", 0.11, 0.11, 1.65, Vector3(float(side_i) * 0.68, 0.08, 0.0), m_camo, 8, Vector3(90.0, 0, 0))

	# 5. Long Tapered Tail Boom + Vertical Fin + Red Star + Tail Rotor
	_add_cyl(root, "TailBoom", 0.32, 0.68, 6.4, Vector3(0, 0.42, 5.75), m_olive, 10, Vector3(90.0, 0, 0))
	_add_box(root, "TailHStab", Vector3(3.15, 0.12, 0.72), Vector3(0, 0.42, 7.65), m_camo)
	_add_box(root, "TailVFin", Vector3(0.20, 2.25, 1.25), Vector3(0, 1.38, 8.75), m_olive, Vector3(-16.0, 0, 0))
	_add_box(root, "RedStarL", Vector3(0.04, 0.58, 0.58), Vector3(-0.12, 1.42, 8.65), m_star, Vector3(0, 0, 0))
	_add_box(root, "RedStarR", Vector3(0.04, 0.58, 0.58), Vector3(0.12, 1.42, 8.65), m_star, Vector3(0, 0, 0))

	var t_rotor := Node3D.new()
	t_rotor.name = "TailRotor"
	t_rotor.position = Vector3(-0.34, 2.02, 9.05)
	root.add_child(t_rotor)
	_add_cyl(t_rotor, "TailHub", 0.14, 0.14, 0.22, Vector3.ZERO, m_dark, 8, Vector3(0, 0, 90.0))
	for bi in range(3):
		var b_piv := Node3D.new()
		b_piv.rotation_degrees = Vector3(float(bi) * 120.0, 0, 0)
		t_rotor.add_child(b_piv)
		_add_box(b_piv, "TailBlade", Vector3(0.04, 1.35, 0.18), Vector3(0, 0.72, 0), m_dark)

	# 6. Dorsal Rotor Mast + Spinning 5-Blade Main Rotor
	_add_cyl(root, "RotorHub", 0.38, 0.48, 0.85, Vector3(0, 1.92, -0.05), m_dark, 12)
	var m_rotor := Node3D.new()
	m_rotor.name = "MainRotor"
	m_rotor.position = Vector3(0, 2.32, -0.05)
	root.add_child(m_rotor)
	_add_cyl(m_rotor, "SwashPlate", 0.46, 0.46, 0.22, Vector3.ZERO, m_steel, 12)
	for bi in range(5):
		var bp := Node3D.new()
		bp.rotation_degrees = Vector3(0, float(bi) * 72.0, 0)
		m_rotor.add_child(bp)
		_add_box(bp, "MainBlade", Vector3(0.32, 0.05, 5.85), Vector3(0, 0, -3.12), m_dark)

	# 7. Under-Nose YakB-12.7 Rotary Chin Turret
	var turret := Node3D.new()
	turret.name = "ChinTurret"
	turret.position = Vector3(0, -0.78, -4.35)
	root.add_child(turret)
	_add_cyl(turret, "TurretBall", 0.26, 0.26, 0.38, Vector3.ZERO, m_dark, 10)
	_add_cyl(turret, "ChinGunBarrel", 0.08, 0.09, 1.25, Vector3(0, -0.04, -0.68), m_steel, 8, Vector3(90.0, 0, 0))
	var muz := Marker3D.new()
	muz.name = "ChinMuzzle"
	muz.position = Vector3(0, -0.04, -1.35)
	turret.add_child(muz)

	return root

func _build_full_helicopter() -> void:
	model_root = create_preview_model()
	add_child(model_root)
	main_rotor = model_root.get_node_or_null("MainRotor")
	tail_rotor = model_root.get_node_or_null("TailRotor")
	chin_turret = model_root.get_node_or_null("ChinTurret")
	if chin_turret:
		chin_muzzle = chin_turret.get_node_or_null("ChinMuzzle") as Marker3D

	# Red target-lock telegraph laser from chin turret
	laser_beam = MeshInstance3D.new()
	laser_beam.name = "StrafeLaser"
	var lcyl := CylinderMesh.new()
	lcyl.top_radius = 0.045
	lcyl.bottom_radius = 0.045
	lcyl.height = 1.0
	laser_beam.mesh = lcyl
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.albedo_color = Color(1.0, 0.14, 0.10, 0.85)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	laser_beam.material_override = lmat
	laser_beam.visible = false
	add_child(laser_beam)

	# Engine smoke emitters (activated when an engine is damaged/destroyed)
	engine_smoke_l = _create_damage_smoke(Vector3(-1.15, 1.25, 1.55))
	engine_smoke_r = _create_damage_smoke(Vector3(1.15, 1.25, 1.55))
	crash_smoke = _create_damage_smoke(Vector3(0.0, 0.8, 0.4), true)
	model_root.add_child(engine_smoke_l)
	model_root.add_child(engine_smoke_r)
	model_root.add_child(crash_smoke)

	# 8 Modular Physical Hitboxes (in group "mi24_hitbox")
	_add_hitbox("HB_EngineL", "engine_l", Vector3(1.05, 0.95, 3.1), Vector3(-0.95, 1.25, 0.25))
	_add_hitbox("HB_EngineR", "engine_r", Vector3(1.05, 0.95, 3.1), Vector3(0.95, 1.25, 0.25))
	_add_hitbox("HB_TailRotor", "tail_rotor", Vector3(1.4, 2.5, 2.3), Vector3(0.0, 1.55, 8.85))
	_add_hitbox("HB_PodL", "pod_l", Vector3(1.65, 0.95, 2.25), Vector3(-2.65, -0.40, -0.10))
	_add_hitbox("HB_PodR", "pod_r", Vector3(1.65, 0.95, 2.25), Vector3(2.65, -0.40, -0.10))
	_add_hitbox("HB_Gunner", "cockpit_gunner", Vector3(1.35, 1.05, 1.75), Vector3(0.0, 0.52, -3.15))
	_add_hitbox("HB_Pilot", "cockpit_pilot", Vector3(1.40, 1.10, 1.95), Vector3(0.0, 1.15, -1.65))
	_add_hitbox("HB_Hull", "hull", Vector3(2.1, 2.0, 5.6), Vector3(0.0, 0.0, 0.2))
	_add_hitbox("HB_TailBoom", "hull", Vector3(1.25, 1.25, 5.4), Vector3(0.0, 0.42, 5.2))

func _add_hitbox(hb_name: String, zone_id: String, sz: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.name = hb_name
	sb.position = pos
	sb.collision_layer = 2 | 4
	sb.collision_mask = 0
	sb.add_to_group("mi24_hitbox")
	sb.set_meta("mi24_owner", self)
	sb.set_meta("hit_zone", zone_id)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = sz
	cs.shape = sh
	sb.add_child(cs)
	model_root.add_child(sb)

func _create_damage_smoke(pos: Vector3, big: bool = false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.emitting = false
	p.local_coords = false
	p.amount = 34 if big else 22
	p.lifetime = 1.35 if big else 0.95
	p.direction = Vector3(0, 0.4, 1.0)
	p.spread = 32.0
	p.gravity = Vector3(0, 1.2, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	var sm := SphereMesh.new()
	sm.radius = 0.58 if big else 0.36
	sm.height = 1.16 if big else 0.72
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.16, 0.12, 0.10, 0.78) if big else Color(0.18, 0.18, 0.18, 0.65)
	sm.material = smat
	p.mesh = sm
	return p

func _setup_audio() -> void:
	rotor_sfx = AudioStreamPlayer3D.new()
	rotor_sfx.bus = "SFX"
	rotor_sfx.stream = SoundEffects.create_heli_rotor_sound()
	rotor_sfx.volume_db = 2.5
	rotor_sfx.max_distance = 130.0
	rotor_sfx.unit_size = 18.0
	add_child(rotor_sfx)
	rotor_sfx.play()

func _physics_process(delta: float) -> void:
	if flying_debris.size() > 0:
		_update_flying_debris(delta)

	if boss_state == BossState.DESTROYED:
		if wreck_fire_light and is_instance_valid(wreck_fire_light):
			wreck_fire_light.light_energy = randf_range(3.2, 5.4)
		return

	# Spin rotors continuously
	var rotor_mult: float = 0.45 if (engine_l_dead and engine_r_dead) else (0.78 if (engine_l_dead or engine_r_dead) else 1.0)
	if main_rotor:
		main_rotor.rotation.y += delta * 26.0 * rotor_mult
	if tail_rotor and not tail_rotor_dead:
		tail_rotor.rotation.x += delta * 34.0 * rotor_mult

	flare_cooldown = maxf(0.0, flare_cooldown - delta)

	if boss_state == BossState.CRASHING:
		_process_crashing(delta)
		return

	if not is_instance_valid(player):
		var ps := get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			player = ps[0] as Node3D

	var speed_mult: float = 0.68 if (engine_l_dead or engine_r_dead) else 1.0
	state_timer -= delta

	match boss_state:
		BossState.ORBITING:
			if laser_beam:
				laser_beam.visible = false
			_orbit_flight(delta, speed_mult, target_altitude)
			if state_timer <= 0.0:
				_choose_next_attack()
		BossState.CANNON_STRAFE:
			_orbit_flight(delta, speed_mult * 0.72, 17.5)
			_process_cannon_strafe(delta)
		BossState.ROCKET_BARRAGE:
			_orbit_flight(delta, speed_mult * 0.62, 20.5)
			_process_rocket_barrage(delta)
		BossState.DEPLOYING_TROOPS:
			_orbit_flight(delta, speed_mult * 0.35, 11.5)
			if state_timer <= 0.0:
				_drop_airborne_squad()
				boss_state = BossState.ORBITING
				state_timer = 4.2

	# Track chin turret toward player while gunner is alive
	if chin_turret and gunner_alive and is_instance_valid(player):
		var target_pt: Vector3 = player.global_position + Vector3(0, 0.9, 0)
		var local_p: Vector3 = model_root.to_local(target_pt) - chin_turret.position
		var tyaw: float = clampf(atan2(-local_p.x, -local_p.z), deg_to_rad(-65.0), deg_to_rad(65.0))
		var hd: float = maxf(0.2, Vector2(local_p.x, local_p.z).length())
		var tpitch: float = clampf(atan2(local_p.y, hd), deg_to_rad(-60.0), deg_to_rad(15.0))
		chin_turret.rotation.y = lerpf(chin_turret.rotation.y, tyaw, delta * 8.0)
		chin_turret.rotation.x = lerpf(chin_turret.rotation.x, tpitch, delta * 8.0)

	hud_sync_timer += delta
	if hud_sync_timer >= 0.12:
		hud_sync_timer = 0.0
		_sync_boss_hud()

func _orbit_flight(delta: float, speed_mult: float, desired_alt: float) -> void:
	var center := Vector3.ZERO
	if is_instance_valid(player):
		center = Vector3(clampf(player.global_position.x, -16.0, 16.0), 0.0, clampf(player.global_position.z, -16.0, 16.0))
	orbit_angle += delta * 0.42 * speed_mult * orbit_dir
	var goal := Vector3(
		center.x + cos(orbit_angle) * orbit_radius,
		desired_alt + sin(orbit_angle * 2.0) * 1.3,
		center.z + sin(orbit_angle) * orbit_radius
	)
	goal.x = clampf(goal.x, -42.0, 42.0)
	goal.z = clampf(goal.z, -42.0, 42.0)

	var to_goal := goal - global_position
	var step_vel: Vector3 = to_goal.limit_length(15.5 * speed_mult)
	global_position += step_vel * delta

	# Face slightly toward player during attacks, otherwise along flight path!
	var look_dir: Vector3 = step_vel
	if (boss_state == BossState.CANNON_STRAFE or boss_state == BossState.ROCKET_BARRAGE) and is_instance_valid(player):
		look_dir = player.global_position - global_position
	look_dir.y = 0.0
	if look_dir.length_squared() > 0.04:
		var target_yaw: float = atan2(-look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.2)

	# Realistic helicopter pitch & roll banking
	var target_bank: float = -0.24 * orbit_dir if boss_state == BossState.ORBITING else -0.10 * orbit_dir
	var target_pitch: float = -0.14 if boss_state == BossState.ORBITING else -0.22
	rotation.z = lerpf(rotation.z, target_bank, delta * 3.5)
	rotation.x = lerpf(rotation.x, target_pitch, delta * 3.5)

func _choose_next_attack() -> void:
	var has_pods: bool = (not pod_l_dead) or (not pod_r_dead)
	var r: float = randf()
	if troops_deployed_count < max_troop_drops and r < 0.24:
		boss_state = BossState.DEPLOYING_TROOPS
		state_timer = 2.4
		_notify_hud_toast("🚁 МИ-24 СНИЖАЕТСЯ ДЛЯ ВЫСАДКИ ДЕСАНТА!")
	elif has_pods and (r < 0.62 or not gunner_alive):
		boss_state = BossState.ROCKET_BARRAGE
		state_timer = 2.65
		rocket_telegraph_done = false
		_prepare_rocket_telegraph()
	elif gunner_alive:
		boss_state = BossState.CANNON_STRAFE
		state_timer = 2.55
		strafe_shots_left = 10
		strafe_burst_cd = 0.85 # 0.85s laser lock warning before bullets!
	else:
		# All weapons disabled — keep circling menacingly
		boss_state = BossState.ORBITING
		state_timer = 3.0

func _process_cannon_strafe(delta: float) -> void:
	if not gunner_alive or not is_instance_valid(player):
		if laser_beam:
			laser_beam.visible = false
		boss_state = BossState.ORBITING
		state_timer = 2.5
		return

	var muzzle_pos: Vector3 = chin_muzzle.global_position if chin_muzzle else (global_position + Vector3(0, -1.0, 0))
	var target_pt: Vector3 = player.global_position + Vector3(0, 0.85, 0)

	# Update red laser telegraph beam
	if laser_beam:
		laser_beam.visible = true
		var diff: Vector3 = target_pt - muzzle_pos
		var d: float = maxf(0.5, diff.length())
		laser_beam.global_position = muzzle_pos + diff * 0.5
		laser_beam.scale = Vector3(1.0, d, 1.0)
		var up_v := Vector3.UP if absf(diff.normalized().dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
		laser_beam.look_at(target_pt, up_v)
		laser_beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)

	strafe_burst_cd -= delta
	if strafe_burst_cd <= 0.0 and strafe_shots_left > 0:
		strafe_shots_left -= 1
		strafe_burst_cd = 0.13
		_fire_chin_bullet(muzzle_pos, target_pt)

	if strafe_shots_left <= 0 or state_timer <= 0.0:
		if laser_beam:
			laser_beam.visible = false
		boss_state = BossState.ORBITING
		state_timer = randf_range(3.2, 4.8)

func _fire_chin_bullet(from_pos: Vector3, target_pt: Vector3) -> void:
	if not bullet_scene or not get_parent():
		return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = from_pos
	var spread_v := Vector3(randf_range(-0.9, 0.9), randf_range(-0.4, 0.4), randf_range(-0.9, 0.9))
	var dir: Vector3 = ((target_pt + spread_v) - from_pos).normalized()
	b.init(dir, 14.0, Color(1.0, 0.62, 0.18), 46.0)
	VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), from_pos, dir, Color(1.0, 0.72, 0.22), 1.35)
	_play_3d_sfx(SoundEffects.create_pkm_sound(), from_pos, randf_range(0.75, 0.85), 2.5)

func _prepare_rocket_telegraph() -> void:
	_clear_warning_rings()
	pending_rocket_targets.clear()
	if not is_instance_valid(player):
		return
	var num_rockets: int = 0
	if not pod_l_dead: num_rockets += 2
	if not pod_r_dead: num_rockets += 2
	if num_rockets <= 0:
		return
	var base: Vector3 = player.global_position
	for i in range(num_rockets):
		var ang: float = randf_range(0.0, TAU)
		var rad: float = 0.0 if i == 0 else randf_range(2.8, 7.2)
		var pt := Vector3(clampf(base.x + cos(ang) * rad, -42.0, 42.0), 0.08, clampf(base.z + sin(ang) * rad, -42.0, 42.0))
		pending_rocket_targets.append(pt)
		# Red glowing ground target ring warning!
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.65
		tm.outer_radius = 2.95
		ring.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.albedo_color = Color(1.0, 0.18, 0.10, 0.88)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = rmat
		get_tree().root.add_child(ring)
		ring.global_position = pt
		active_warning_rings.append(ring)

func _process_rocket_barrage(_delta: float) -> void:
	if not rocket_telegraph_done and state_timer <= 1.25:
		rocket_telegraph_done = true
		_fire_rocket_barrage()
	if state_timer <= 0.0:
		_clear_warning_rings()
		boss_state = BossState.ORBITING
		state_timer = randf_range(3.8, 5.4)

func _fire_rocket_barrage() -> void:
	if pending_rocket_targets.is_empty():
		return
	_play_3d_sfx(SoundEffects.create_rpg_shot_sound(), global_position, 1.18, 3.0)
	for i in range(pending_rocket_targets.size()):
		var pt: Vector3 = pending_rocket_targets[i]
		var side_x: float = -2.55 if (i % 2 == 0 and not pod_l_dead) or pod_r_dead else 2.55
		var start_p: Vector3 = to_global(Vector3(side_x, -0.45, -1.2))
		_launch_s8_rocket(start_p, pt, float(i) * 0.16)

func _launch_s8_rocket(start_p: Vector3, target_p: Vector3, delay_s: float) -> void:
	if delay_s > 0.0:
		await get_tree().create_timer(delay_s).timeout
	if not is_inside_tree() or boss_state == BossState.DESTROYED:
		return
	var rocket := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.06
	cm.height = 0.72
	rocket.mesh = cm
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(1.0, 0.75, 0.25)
	rocket.material_override = rmat
	get_tree().root.add_child(rocket)
	rocket.global_position = start_p
	var up_v := Vector3.UP if absf((target_p - start_p).normalized().dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	rocket.look_at(target_p, up_v)
	rocket.rotate_object_local(Vector3.RIGHT, PI * 0.5)

	var travel_t: float = clampf(start_p.distance_to(target_p) / 48.0, 0.25, 0.95)
	var tw := rocket.create_tween()
	tw.tween_property(rocket, "global_position", target_p, travel_t)
	await tw.finished
	if is_instance_valid(rocket):
		rocket.queue_free()
	if not is_inside_tree():
		return
	VFXFactoryScript.spawn_explosion(get_tree().root, target_p, Vector3.UP, 0.78)
	_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), target_p, randf_range(1.1, 1.25), 1.5)
	if is_instance_valid(player):
		var pd: float = player.global_position.distance_to(target_p)
		if pd <= 4.4:
			var dmg: float = lerpf(36.0, 12.0, pd / 4.4)
			if player.has_method("take_damage"):
				player.take_damage(dmg)
			if player.has_method("add_camera_shake"):
				player.add_camera_shake(0.18)

func _clear_warning_rings() -> void:
	for r in active_warning_rings:
		if is_instance_valid(r):
			r.queue_free()
	active_warning_rings.clear()

func _drop_airborne_squad() -> void:
	troops_deployed_count += 1
	if not enemy_scene or not get_parent():
		return
	# Cap active infantry so airborne drops stay fair
	if get_tree().get_nodes_in_group("enemy").size() > 14:
		return
	var drop_types: Array[int] = [0, 4, 6] # Red Standard, Orange Engineer, Gray Saboteur
	for k in range(2):
		var e = enemy_scene.instantiate()
		e.enemy_type = drop_types[randi() % drop_types.size()]
		var off := Vector3(randf_range(-2.6, 2.6), 0.0, randf_range(-2.6, 2.6))
		get_parent().add_child(e)
		var drop_p := Vector3(clampf(global_position.x + off.x, -40.0, 40.0), 0.2, clampf(global_position.z + off.z, -40.0, 40.0))
		e.global_position = drop_p
		# Notify spawner if available so enemy stays tracked in wave!
		var spawners := get_tree().get_nodes_in_group("enemy_spawner")
		if spawners.size() > 0 and spawners[0].has_method("register_extra_enemy"):
			spawners[0].register_extra_enemy(e)

# =============================================================================
# MODULAR DAMAGE API (Bullets, DShK 12.7mm, RPG-7 & UGL Grenades!)
# =============================================================================
func on_bullet_hit(zone_id: String, dmg: float, ap_mult: float, hit_pos: Vector3, _hit_normal: Vector3) -> bool:
	if boss_state == BossState.CRASHING or boss_state == BossState.DESTROYED:
		return false

	# Pop countermeasure magnesium flares (ЛТЦ) periodically under fire!
	if flare_cooldown <= 0.0:
		flare_cooldown = 5.5
		_pop_flares()

	match zone_id:
		"cockpit_pilot", "cockpit_gunner":
			# Armored Mi-24 bulletproof canopy glass requires AP ammo (>= 1.35x) OR high-caliber single hit (>= 95 dmg)!
			var base_shot: float = dmg / maxf(0.1, ap_mult)
			var penetrates_glass: bool = (ap_mult >= 1.35) or (base_shot >= 95.0)
			if not penetrates_glass:
				_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), hit_pos, randf_range(1.22, 1.45), -1.0)
				return false
			if zone_id == "cockpit_pilot":
				pilot_hp = maxf(0.0, pilot_hp - dmg)
				if pilot_hp <= 0.0 and pilot_alive:
					pilot_alive = false
					_notify_hud_toast("💀 ПИЛОТ МИ-24 ЛИКВИДИРОВАН — ВЕРТОЛЁТ ПАДАЕТ!")
					_begin_crash(false)
			else:
				gunner_hp = maxf(0.0, gunner_hp - dmg)
				if gunner_hp <= 0.0 and gunner_alive:
					gunner_alive = false
					if laser_beam:
						laser_beam.visible = false
					_notify_hud_toast("🎯 ОПЕРАТОР МИ-24 УНИЧТОЖЕН — ПУШКА ОТКЛЮЧЕНА!")
			hull_hp = maxf(0.0, hull_hp - dmg * 0.35)
		"engine_l":
			engine_l_hp = maxf(0.0, engine_l_hp - dmg)
			hull_hp = maxf(0.0, hull_hp - dmg * 0.45)
			if engine_l_hp <= MAX_ENGINE_HP * 0.55 and engine_smoke_l:
				engine_smoke_l.emitting = true
			if engine_l_hp <= 0.0 and not engine_l_dead:
				engine_l_dead = true
				VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.65)
				_notify_hud_toast("🔥 ЛЕВЫЙ ДВИГАТЕЛЬ МИ-24 ВЫВЕДЕН ИЗ СТРОЯ!")
				if engine_r_dead:
					_begin_crash(false)
		"engine_r":
			engine_r_hp = maxf(0.0, engine_r_hp - dmg)
			hull_hp = maxf(0.0, hull_hp - dmg * 0.45)
			if engine_r_hp <= MAX_ENGINE_HP * 0.55 and engine_smoke_r:
				engine_smoke_r.emitting = true
			if engine_r_hp <= 0.0 and not engine_r_dead:
				engine_r_dead = true
				VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.65)
				_notify_hud_toast("🔥 ПРАВЫЙ ДВИГАТЕЛЬ МИ-24 ВЫВЕДЕН ИЗ СТРОЯ!")
				if engine_l_dead:
					_begin_crash(false)
		"tail_rotor":
			tail_rotor_hp = maxf(0.0, tail_rotor_hp - dmg)
			hull_hp = maxf(0.0, hull_hp - dmg * 0.35)
			if tail_rotor_hp <= 0.0 and not tail_rotor_dead:
				tail_rotor_dead = true
				if tail_rotor:
					tail_rotor.visible = false
				VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.72)
				_notify_hud_toast("🌀 РУЛЕВОЙ ВИНТ МИ-24 РАЗРУШЕН — ШТОПОР!")
				_begin_crash(true)
		"pod_l":
			pod_l_hp = maxf(0.0, pod_l_hp - dmg)
			hull_hp = maxf(0.0, hull_hp - dmg * 0.30)
			if pod_l_hp <= 0.0 and not pod_l_dead:
				pod_l_dead = true
				var pl := model_root.get_node_or_null("RocketPodL")
				if pl: pl.visible = false
				VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.85)
				hull_hp = maxf(0.0, hull_hp - 180.0)
				_notify_hud_toast("💥 ЛЕВЫЙ БЛОК НАР ДЕТОНИРОВАЛ!")
		"pod_r":
			pod_r_hp = maxf(0.0, pod_r_hp - dmg)
			hull_hp = maxf(0.0, hull_hp - dmg * 0.30)
			if pod_r_hp <= 0.0 and not pod_r_dead:
				pod_r_dead = true
				var pr := model_root.get_node_or_null("RocketPodR")
				if pr: pr.visible = false
				VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.85)
				hull_hp = maxf(0.0, hull_hp - 180.0)
				_notify_hud_toast("💥 ПРАВЫЙ БЛОК НАР ДЕТОНИРОВАЛ!")
		_:
			hull_hp = maxf(0.0, hull_hp - dmg * 0.72)

	if hull_hp <= 0.0 and boss_state != BossState.CRASHING:
		_begin_crash(false)

	_sync_boss_hud()
	return true

func on_rpg_hit(hit_pos: Vector3, _hit_normal: Vector3, _direct_collider: Object, max_damage: float, blast_radius: float, ammo_mode: String = "standard") -> bool:
	if boss_state == BossState.CRASHING or boss_state == BossState.DESTROYED:
		return false
	var d: float = global_position.distance_to(hit_pos)
	if d > blast_radius + 3.5:
		return false
	var mult: float = 1.25 if ammo_mode == "tandem" else (1.15 if ammo_mode == "thermobaric" else 1.0)
	var falloff: float = lerpf(1.0, 0.35, clampf(d / maxf(1.0, blast_radius + 3.5), 0.0, 1.0))
	var dmg: float = max_damage * 0.85 * mult * falloff
	hull_hp = maxf(0.0, hull_hp - dmg)
	# Splash also damages closest engine/tail/pod realistically!
	if not engine_l_dead:
		engine_l_hp = maxf(0.0, engine_l_hp - dmg * 0.45)
		if engine_l_hp <= 0.0:
			engine_l_dead = true
			if engine_smoke_l: engine_smoke_l.emitting = true
	if not engine_r_dead:
		engine_r_hp = maxf(0.0, engine_r_hp - dmg * 0.45)
		if engine_r_hp <= 0.0:
			engine_r_dead = true
			if engine_smoke_r: engine_smoke_r.emitting = true
	if (engine_l_dead and engine_r_dead) or hull_hp <= 0.0:
		_begin_crash(tail_rotor_dead or randf() < 0.45)
	else:
		_pop_flares()
	_sync_boss_hud()
	return true

func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	on_bullet_hit("hull", amount, 1.0, global_position, Vector3.UP)

func _pop_flares() -> void:
	for side_i in [-1, 1]:
		var fl := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.44
		fl.mesh = sm
		var fmat := StandardMaterial3D.new()
		fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fmat.albedo_color = Color(1.0, 0.94, 0.68)
		fl.material_override = fmat
		var lt := OmniLight3D.new()
		lt.light_color = Color(1.0, 0.82, 0.38)
		lt.light_energy = 5.5
		lt.omni_range = 14.0
		fl.add_child(lt)
		get_tree().root.add_child(fl)
		var start_p: Vector3 = to_global(Vector3(float(side_i) * 1.4, 0.2, 2.5))
		fl.global_position = start_p
		var end_p: Vector3 = start_p + Vector3(float(side_i) * randf_range(5.0, 9.0), -11.0, randf_range(-4.0, 4.0))
		var tw := fl.create_tween()
		tw.tween_property(fl, "global_position", end_p, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(fl.queue_free)

func _begin_crash(is_tail_spin: bool) -> void:
	if boss_state == BossState.CRASHING or boss_state == BossState.DESTROYED:
		return
	boss_state = BossState.CRASHING
	is_dead = true
	_clear_warning_rings()
	if laser_beam:
		laser_beam.visible = false
	if crash_smoke:
		crash_smoke.emitting = true
	if engine_smoke_l:
		engine_smoke_l.emitting = true
	if engine_smoke_r:
		engine_smoke_r.emitting = true
	crash_spin_speed = 6.2 if is_tail_spin else 1.8
	var fwd := -global_transform.basis.z
	crash_vel = Vector3(fwd.x * 7.5, -2.5, fwd.z * 7.5)
	_sync_boss_hud()

func _process_crashing(delta: float) -> void:
	crash_vel.y -= 9.5 * delta
	global_position += crash_vel * delta
	global_position.x = clampf(global_position.x, -44.0, 44.0)
	global_position.z = clampf(global_position.z, -44.0, 44.0)
	rotation.y += crash_spin_speed * delta
	rotation.z = lerpf(rotation.z, 0.72, delta * 2.2)
	rotation.x = lerpf(rotation.x, -0.58, delta * 1.8)
	if rotor_sfx and rotor_sfx.playing:
		rotor_sfx.pitch_scale = maxf(0.45, rotor_sfx.pitch_scale - delta * 0.22)

	if global_position.y <= 1.2:
		_finish_crash_explosion()

func _finish_crash_explosion() -> void:
	if boss_state == BossState.DESTROYED:
		return
	boss_state = BossState.DESTROYED
	is_dead = true
	_clear_warning_rings()
	if laser_beam:
		laser_beam.visible = false
	if rotor_sfx and rotor_sfx.playing:
		rotor_sfx.stop()

	# Place crashed Mi-24 fuselage firmly on the ground with dramatic canted crash pose!
	var crash_x: float = clampf(global_position.x, -43.0, 43.0)
	var crash_z: float = clampf(global_position.z, -43.0, 43.0)
	var crash_pos := Vector3(crash_x, 0.92, crash_z)
	global_position = crash_pos
	rotation.x = deg_to_rad(randf_range(-13.0, -7.0))
	rotation.z = deg_to_rad(randf_range(24.0, 36.0) * (1.0 if randf() < 0.5 else -1.0))

	# 1. Cinematic Multi-Stage Crash Explosion (matching Tiger I's spectacle!)
	VFXFactoryScript.spawn_thermobaric_explosion(get_tree().root, crash_pos + Vector3(0, 0.6, 0), Vector3.UP)
	VFXFactoryScript.spawn_explosion(get_tree().root, crash_pos + Vector3(0, 1.8, 0), Vector3.UP, 2.85)
	_play_3d_sfx(SoundEffects.create_tiger_ammo_explosion_sound(), crash_pos, 0.86, 7.0)
	_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), crash_pos, 0.74, 5.0)
	_schedule_secondary_fuel_cookoff(crash_pos)

	# Shockwave camera shake & close-range blast damage to player
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node3D:
			var dist: float = crash_pos.distance_to((p as Node3D).global_position + Vector3(0, 0.9, 0))
			if dist <= 12.5 and p.has_method("take_damage"):
				var bdmg: float = lerpf(55.0, 18.0, dist / 12.5)
				p.take_damage(bdmg)
			if dist <= 62.0 and p.has_method("add_camera_shake"):
				var shk: float = clampf(1.0 - dist / 62.0, 0.18, 1.0) * 0.62
				p.add_camera_shake(shk)

	# 2. Strip combat hitboxes & hide crewmates inside the burned cockpit
	_strip_mi24_hitboxes(self)
	if model_root:
		for crew_name in ["CrewPilot", "CrewGunner"]:
			var cn := model_root.get_node_or_null(crew_name)
			if cn and cn is Node3D:
				(cn as Node3D).visible = false

	# 3. Char the entire helicopter frame & launch flying permanent wreckage pieces!
	var charred_mat := StandardMaterial3D.new()
	charred_mat.albedo_color = Color(0.085, 0.085, 0.095)
	charred_mat.metallic = 0.34
	charred_mat.roughness = 0.92
	if model_root:
		_apply_material_recursive(model_root, charred_mat)

		# Detach and toss the 5-blade Main Rotor, surviving Rocket Pods & Tail Fin forever onto the ground!
		var detach_names := ["MainRotor", "RocketPodL", "RocketPodR", "TailVFin", "TailHStab"]
		for dname in detach_names:
			var part := model_root.get_node_or_null(dname) as Node3D
			if not part or not part.visible:
				continue
			var p_pos: Vector3 = part.global_position
			var out_v: Vector3 = p_pos - crash_pos
			out_v.y = 0.0
			if out_v.length_squared() < 0.04:
				out_v = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
			var is_rotor: bool = (dname == "MainRotor")
			var launch_dir: Vector3 = (out_v.normalized() + Vector3(randf_range(-0.35, 0.35), randf_range(0.85, 1.45), randf_range(-0.35, 0.35))).normalized()
			var spd: float = randf_range(9.0, 14.5) if is_rotor else randf_range(7.0, 12.5)
			var spin_v := Vector3(randf_range(-4.5, 4.5), randf_range(-5.5, 5.5), randf_range(-4.5, 4.5))
			_launch_permanent_debris(part, launch_dir * spd, spin_v, 0.24 if is_rotor else 0.16)
		main_rotor = null

	# 4. Dark ground scorch crater + permanent crackling wreck fire, light & tall black smoke plume!
	_build_permanent_wreck_effects()

	# 5. Add solid cover StaticBody3D so the permanent Mi-24 hull acts as real battlefield cover!
	_build_wreck_cover_collider()
	if not wreck_aabb_registered:
		wreck_aabb_registered = true
		var wreck_aabb := AABB(Vector3(crash_pos.x, 0.0, crash_pos.z) - Vector3(4.5, 0.0, 4.5), Vector3(9.0, 3.2, 9.0))
		MapObstacles.obstacle_aabbs.append(wreck_aabb)

	# 6. Transition permanently from living boss ("enemy") to permanent map wreck ("mi24_wreck")!
	if is_in_group("enemy"):
		remove_from_group("enemy")
	if is_in_group("mi24_boss"):
		remove_from_group("mi24_boss")
	add_to_group("mi24_wreck")

	var hud_ref := _find_mi24_hud()
	if hud_ref and hud_ref.has_method("trigger_destroyed"):
		hud_ref.trigger_destroyed()

	died.emit(score_value)

func _schedule_secondary_fuel_cookoff(crash_pos: Vector3) -> void:
	await get_tree().create_timer(0.36).timeout
	if not is_inside_tree():
		return
	var offset := Vector3(randf_range(-1.8, 1.8), 1.2, randf_range(-1.8, 1.8))
	VFXFactoryScript.spawn_explosion(get_tree().root, crash_pos + offset, Vector3.UP, 1.85)
	_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), crash_pos + offset, 0.85, 3.0)

func _strip_mi24_hitboxes(node: Node) -> void:
	for c in node.get_children():
		if c is StaticBody3D and c.is_in_group("mi24_hitbox"):
			c.queue_free()
		else:
			_strip_mi24_hitboxes(c)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for c in node.get_children():
		if c is CPUParticles3D:
			continue
		_apply_material_recursive(c, mat)

func _launch_permanent_debris(node: Node3D, impulse: Vector3, spin: Vector3, rest_y: float = 0.16) -> void:
	if not node or not is_instance_valid(node) or not is_inside_tree():
		return
	var world_xf: Transform3D = node.global_transform
	var par := node.get_parent()
	if par:
		par.remove_child(node)
	get_tree().root.add_child(node)
	node.global_transform = world_xf
	node.add_to_group("mi24_wreck")
	flying_debris.append({
		"node": node,
		"vel": impulse,
		"ang": spin,
		"rest_y": rest_y,
		"settled": false
	})

func _update_flying_debris(dt: float) -> void:
	var any_active := false
	for item in flying_debris:
		if item["settled"]:
			continue
		var n: Node3D = item["node"]
		if not is_instance_valid(n):
			item["settled"] = true
			continue
		any_active = true
		var vel: Vector3 = item["vel"]
		var ang: Vector3 = item["ang"]
		var rest_y: float = float(item["rest_y"])
		vel.y -= 17.5 * dt
		n.global_position += vel * dt
		n.global_position.x = clampf(n.global_position.x, -46.0, 46.0)
		n.global_position.z = clampf(n.global_position.z, -46.0, 46.0)
		n.rotation += ang * dt
		if n.global_position.y <= rest_y:
			n.global_position.y = rest_y
			var impact_spd: float = absf(vel.y)
			if impact_spd > 1.4:
				vel.y = -vel.y * 0.30
				vel.x *= 0.56
				vel.z *= 0.56
				ang *= 0.48
				_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), n.global_position, randf_range(0.92, 1.25), -6.0)
			else:
				vel = Vector3.ZERO
				ang = Vector3.ZERO
				item["settled"] = true
		item["vel"] = vel
		item["ang"] = ang
	if not any_active and flying_debris.size() > 0:
		flying_debris.clear()

func _build_permanent_wreck_effects() -> void:
	# Ground burn crater disc beneath the crashed helicopter
	var scorch := MeshInstance3D.new()
	scorch.name = "CrashScorchMark"
	var scm := CylinderMesh.new()
	scm.top_radius = 4.6
	scm.bottom_radius = 4.8
	scm.height = 0.04
	scm.radial_segments = 18
	scorch.mesh = scm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.03, 0.03, 0.03, 0.88)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.roughness = 0.98
	scorch.material_override = smat
	add_child(scorch)
	scorch.global_position = Vector3(global_position.x, 0.03, global_position.z)
	scorch.global_rotation = Vector3.ZERO

	# Persistent orange-red wreck fire flames around the engine deck
	var fire_fx := CPUParticles3D.new()
	fire_fx.name = "WreckFireFX"
	fire_fx.position = Vector3(0, 0.85, 0.25)
	fire_fx.local_coords = false
	fire_fx.amount = 24
	fire_fx.lifetime = 0.95
	fire_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fire_fx.emission_box_extents = Vector3(1.4, 0.3, 2.2)
	fire_fx.direction = Vector3(0, 1, 0)
	fire_fx.spread = 22.0
	fire_fx.gravity = Vector3(0, 2.2, 0)
	fire_fx.initial_velocity_min = 1.2
	fire_fx.initial_velocity_max = 2.8
	var fmesh := SphereMesh.new()
	fmesh.radius = 0.42
	fmesh.height = 0.84
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.albedo_color = Color(1.0, 0.48, 0.12, 0.82)
	fmesh.material = fmat
	fire_fx.mesh = fmesh
	add_child(fire_fx)

	# Tall billowing black smoke column rising from the wreckage forever
	var smoke_fx := CPUParticles3D.new()
	smoke_fx.name = "WreckSmokeFX"
	smoke_fx.position = Vector3(0, 1.35, 0.25)
	smoke_fx.local_coords = false
	smoke_fx.amount = 28
	smoke_fx.lifetime = 3.6
	smoke_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke_fx.emission_sphere_radius = 1.1
	smoke_fx.direction = Vector3(0.18, 1.0, 0.12)
	smoke_fx.spread = 18.0
	smoke_fx.gravity = Vector3(0, 0.6, 0)
	smoke_fx.initial_velocity_min = 2.0
	smoke_fx.initial_velocity_max = 3.6
	var smk_mesh := SphereMesh.new()
	smk_mesh.radius = 0.78
	smk_mesh.height = 1.56
	var smk_mat := StandardMaterial3D.new()
	smk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smk_mat.albedo_color = Color(0.10, 0.10, 0.11, 0.62)
	smk_mesh.material = smk_mat
	smoke_fx.mesh = smk_mesh
	add_child(smoke_fx)

	# Flickering warm firelight illuminating the charred hull (looks awesome during night waves!)
	wreck_fire_light = OmniLight3D.new()
	wreck_fire_light.name = "WreckFireLight"
	wreck_fire_light.position = Vector3(0, 1.9, 0.2)
	wreck_fire_light.light_color = Color(1.0, 0.46, 0.14)
	wreck_fire_light.light_energy = 4.2
	wreck_fire_light.omni_range = 15.0
	add_child(wreck_fire_light)

	# Quiet lingering crackling fire audio (same as destroyed Tiger I wreck)
	wreck_fire_audio = AudioStreamPlayer3D.new()
	wreck_fire_audio.name = "WreckFireAudio"
	wreck_fire_audio.bus = "SFX"
	wreck_fire_audio.stream = SoundEffects.create_tiger_fire_sound()
	wreck_fire_audio.pitch_scale = 0.92
	wreck_fire_audio.volume_db = -9.0
	wreck_fire_audio.max_distance = 45.0
	add_child(wreck_fire_audio)
	wreck_fire_audio.play()

func _build_wreck_cover_collider() -> void:
	var cover := StaticBody3D.new()
	cover.name = "WreckSolidCover"
	cover.collision_layer = 1
	cover.collision_mask = 7
	var cs_hull := CollisionShape3D.new()
	var sh_hull := BoxShape3D.new()
	sh_hull.size = Vector3(2.2, 2.0, 5.8)
	cs_hull.shape = sh_hull
	cs_hull.position = Vector3(0, 0.15, 0.1)
	cover.add_child(cs_hull)
	var cs_tail := CollisionShape3D.new()
	var sh_tail := BoxShape3D.new()
	sh_tail.size = Vector3(1.1, 1.1, 5.4)
	cs_tail.shape = sh_tail
	cs_tail.position = Vector3(0, 0.4, 5.3)
	cover.add_child(cs_tail)
	add_child(cover)

func _sync_boss_hud() -> void:
	var hud_ref := _find_mi24_hud()
	if not hud_ref or not hud_ref.has_method("update_status"):
		return
	hud_ref.update_status(
		clampf(hull_hp / MAX_HULL_HP, 0.0, 1.0),
		{
			"pilot": clampf(pilot_hp / MAX_PILOT_HP, 0.0, 1.0) if pilot_alive else 0.0,
			"gunner": clampf(gunner_hp / MAX_GUNNER_HP, 0.0, 1.0) if gunner_alive else 0.0,
		},
		{
			"engine_l": clampf(engine_l_hp / MAX_ENGINE_HP, 0.0, 1.0) if not engine_l_dead else 0.0,
			"engine_r": clampf(engine_r_hp / MAX_ENGINE_HP, 0.0, 1.0) if not engine_r_dead else 0.0,
			"tail_rotor": clampf(tail_rotor_hp / MAX_TAIL_HP, 0.0, 1.0) if not tail_rotor_dead else 0.0,
			"pod_l": clampf(pod_l_hp / MAX_POD_HP, 0.0, 1.0) if not pod_l_dead else 0.0,
			"pod_r": clampf(pod_r_hp / MAX_POD_HP, 0.0, 1.0) if not pod_r_dead else 0.0,
		}
	)

func _find_mi24_hud() -> Node:
	if not is_inside_tree():
		return null
	var hud := get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("get_mi24_boss_hud"):
		return hud.get_mi24_boss_hud()
	return null

func _notify_hud_toast(msg: String) -> void:
	if not is_inside_tree():
		return
	var hud := get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_arena_toast"):
		hud.show_arena_toast(msg)

func _play_3d_sfx(stream: AudioStream, pos: Vector3, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not stream or not is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.bus = "SFX"
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.max_distance = 110.0
	get_tree().root.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

func _exit_tree() -> void:
	_clear_warning_rings()
