class_name TigerTank
extends Node3D

# Boss Enemy: Panzerkampfwagen VI Tiger I (Ausf. E) — Rebuilt From Scratch!
# - Authentic Light Panzer Grey finish, enlarged 7.2m x 4.16m proportions
# - Real HOLLOW hull & turret interiors with FULL-SIZE crew models sitting behind semi-transparent optic glass:
#   * Red Commander in Wehrmacht officer peaked cap (фуражка) sitting half-out of open cupola (hitbox strictly on him)
#   * Green Driver behind exact front-left armored glass optic window
#   * Blue Radio Operator behind exact front-right armored glass optic window above hull MG-34
#   * Yellow Gunner visible behind impenetrable turret TZF 9b optic glass (unkillable)
# - 4 external side fuel tanks grouped closely near the rear engine compartment
# - Ultra-detailed 8-axle interleaved Schachtellaufwerk road wheels + 34 animated articulated track links per side
# - Segmented Tiger I track arches/fenders (part of them blow off on explosion & stay on ground forever!)
# - Detaching headlights & Commander MG (fly off & stay on ground forever when shot OR when tank explodes!)
# - Elevating/depressing 88mm KwK 36 main cannon with ballistic lead tracking
# - Stiff, weighty 57-ton torsion-bar suspension rocking + smart multi-angle obstacle avoidance AI
# - RPG-7 3-side-hit kill triggers high-pressure ammo-rack fire jet from Commander's hatch -> catastrophic turret toss (RPG never kills crew); burning -> screaming -> 5s silence -> explosion on Engine + 4 Fuel Tanks

signal died(points: int)

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")
const TigerShellScript = preload("res://scripts/enemies/tiger_shell.gd")
const EnemyBulletScene: PackedScene = preload("res://scenes/enemy_bullet.tscn")

enum BossState { ACTIVE, BURNING, COOKOFF, DESTROYED }
var boss_state: BossState = BossState.ACTIVE
var is_dead: bool = false
var is_preview_only: bool = false
var health: float = 9999.0 # Kept > 0 while active so EnemySpawner counts Tiger as alive
var score_value: int = 440

# ==========================================
# CREW & MODULE STATE
# ==========================================
const CREW_MAX_HP: float = 70.0
const COAX_MAX_HP: float = 60.0
const OPTICS_MAX_HP: float = 55.0
const FUEL_MAX_HP: float = 55.0
const GRILLE_MAX_HP: float = 75.0

var crew_alive: Dictionary = {
	"driver": true,
	"radio": true,
	"loader": true,
	"gunner": true,
	"commander": true,
}
var crew_hp: Dictionary = {
	"driver": CREW_MAX_HP,
	"radio": CREW_MAX_HP,
	"commander": CREW_MAX_HP,
}
var crew_hud_colors: Dictionary = {
	"driver": Color(0.94, 0.96, 0.98),
	"radio": Color(0.94, 0.96, 0.98),
	"loader": Color(0.94, 0.96, 0.98),
	"gunner": Color(0.94, 0.96, 0.98),
	"commander": Color(0.94, 0.96, 0.98),
}

# Modules
var coax_hp: float = COAX_MAX_HP
var coax_destroyed: bool = false

var optics_hp: float = OPTICS_MAX_HP
var optics_destroyed: bool = false

var fuel_hp: Dictionary = {
	"fuel_l1": FUEL_MAX_HP,
	"fuel_l2": FUEL_MAX_HP,
	"fuel_r1": FUEL_MAX_HP,
	"fuel_r2": FUEL_MAX_HP,
}
var fuel_destroyed: Dictionary = {
	"fuel_l1": false,
	"fuel_l2": false,
	"fuel_r1": false,
	"fuel_r2": false,
}
var fuel_tanks_destroyed_count: int = 0

var grille_hp: Dictionary = {
	"grille_l": GRILLE_MAX_HP,
	"grille_r": GRILLE_MAX_HP,
}
var grille_destroyed: Dictionary = {
	"grille_l": false,
	"grille_r": false,
}
var grilles_destroyed_count: int = 0
var engine_destroyed: bool = false
var engine_smoking: bool = false
var engine_burning: bool = false

# Decorative destroyable parts (not shown in HUD; detach permanently on hit OR explosion!)
var headlight_destroyed: Dictionary = {"headlight_l": false, "headlight_r": false}
var cmd_mg_destroyed: bool = false

# RPG-7 side kill tracking (3 hits to ONE side ignites ammo-rack cook-off -> turret toss; 2L + 2R still alive!)
var rpg_hits_left: int = 0
var rpg_hits_right: int = 0

# ==========================================
# MOVEMENT, STIFF SUSPENSION & SMART AI STATE
# ==========================================
var player: Node3D = null
var forward_speed: float = 0.0
var prev_forward_speed: float = 0.0
var turn_rate: float = 0.0
const MAX_SPEED: float = 4.6
const ACCEL_RATE: float = 2.6
const BRAKE_RATE: float = 4.4
const MAX_HULL_TURN: float = 0.66

# Stiffer heavy torsion-bar suspension spring-damper
var susp_pitch: float = 0.0
var susp_pitch_vel: float = 0.0
var susp_roll: float = 0.0
var susp_roll_vel: float = 0.0
var drive_rock_phase: float = 0.0

# Detailed track & wheel animation (perimeter = 14.1m for longer 7.2m Tiger hull)
const TRACK_PERIMETER: float = 14.10
var left_track_dist: float = 0.0
var right_track_dist: float = 0.0
var left_wheels: Array[Node3D] = []
var right_wheels: Array[Node3D] = []
var left_track_pads: Array[Node3D] = []
var right_track_pads: Array[Node3D] = []

# Obstacle-avoidance steering hysteresis
var avoid_turn_bias: float = 1.0
var avoid_reverse_timer: float = 0.0

# Awareness (360 deg with Commander; independent cones + search without Commander)
var last_known_player_pos: Vector3 = Vector3.ZERO
var driver_sees_player: bool = true
var gunner_sees_player: bool = true
var search_timer: float = 0.0
var search_turret_dir: float = 1.0
var gunner_reaction_timer: float = 0.0

# Weapon timers & burst state
var cannon_timer: float = 4.0      # 10.0s reload
var hull_mg_timer: float = 2.5     # 7.0s reload after long burst
var hull_mg_burst_left: int = 0
var hull_mg_shot_cd: float = 0.0

var coax_mg_timer: float = 2.0     # 5.0s reload after 7-shot burst
var coax_mg_burst_left: int = 0
var coax_mg_shot_cd: float = 0.0

var cannon_recoil_offset: float = 0.0

# Destruction sequence state (Engine + 4 Fuel Tanks -> Fire -> Crew Scream -> 5s Silence -> Explosion)
# AND RPG Ammo-Rack Cook-Off state (High pressurized jet flame from Commander hatch -> Catastrophic Turret Toss!)
var burn_phase: int = 0
var burn_timer: float = 0.0
var scream_duration: float = 4.65
var cookoff_timer: float = 0.0
const COOKOFF_DURATION: float = 4.6
var turret_tossed: bool = false
var alive_before_burn: Array[String] = []
var wreck_aabb_registered: bool = false

# ==========================================
# SCENE / VISUAL / DEBRIS / AUDIO NODES
# ==========================================
var suspension_pivot: Node3D = null
var turret_pivot: Node3D = null
var gun_elevation_pivot: Node3D = null
var cannon_recoil_node: Node3D = null
var cannon_muzzle: Marker3D = null
var coax_mg_muzzle: Marker3D = null
var hull_mg_muzzle: Marker3D = null
var cupola_hatch: Node3D = null

var fuel_meshes: Dictionary = {}
var headlight_nodes: Dictionary = {}
var headlight_lights: Dictionary = {}
var headlight_bulbs: Dictionary = {}
var grille_smoke: Dictionary = {}
var engine_smoke_fx: CPUParticles3D = null
var engine_fire_fx: CPUParticles3D = null
var engine_fire_light: OmniLight3D = null
var ammo_jet_outer_fx: CPUParticles3D = null
var ammo_jet_core_fx: CPUParticles3D = null
var ammo_jet_sparks_fx: CPUParticles3D = null
var ammo_jet_light: OmniLight3D = null
var hull_ring_smoke_fx: CPUParticles3D = null
var cmd_mg_node: Node3D = null
var coax_mg_visual: Node3D = null
var optics_glass_mesh: MeshInstance3D = null
var driver_glass_mesh: MeshInstance3D = null
var radio_glass_mesh: MeshInstance3D = null
var crew_models: Dictionary = {} # "commander", "driver", "radio", "gunner" -> Node3D
var detachable_arches: Array[Node3D] = [] # Segmented Tiger I track fenders/arches

var all_hitboxes: Array[StaticBody3D] = []
var own_rids: Array[RID] = []

# Unified permanent battlefield debris physics (headlights, commander MG, blown-off track arches!)
# Each entry: {"node": Node3D, "vel": Vector3, "ang": Vector3, "rest_y": float, "settled": bool}
var flying_debris: Array[Dictionary] = []

# Audio players
var audio_engine: AudioStreamPlayer3D = null
var audio_fire: AudioStreamPlayer3D = null
var audio_weapons: AudioStreamPlayer3D = null
var audio_fx: AudioStreamPlayer3D = null
var current_engine_mode: String = "" # "idle", "move", "broken", "off"

func _ready() -> void:
	if is_preview_only:
		set_physics_process(false)
		_build_tiger_model()
		return
	add_to_group("enemy")
	add_to_group("tiger_boss")
	_build_tiger_model()
	_setup_audio()
	_find_player()
	if player:
		last_known_player_pos = player.global_position
	_push_hud_state()

static func create_preview() -> Node3D:
	var holder := Node3D.new()
	var tank = new()
	tank.is_preview_only = true
	tank.scale = Vector3(0.24, 0.24, 0.24)
	tank.position = Vector3(0.0, -0.34, 0.22)
	tank.rotation_degrees.y = 35.0
	holder.add_child(tank)
	return holder

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		player = players[0] as Node3D

func _get_boss_hud() -> Node:
	if not is_instance_valid(player):
		_find_player()
	if is_instance_valid(player):
		var hud := player.get_node_or_null("HUD")
		if hud and hud.has_method("get_tiger_boss_hud"):
			return hud.get_tiger_boss_hud()
	return null

static func _hp_ratio_to_color(ratio: float) -> Color:
	var r := clampf(ratio, 0.0, 1.0)
	if r <= 0.001:
		return Color(0.11, 0.11, 0.13)
	if r > 0.65:
		return Color(1.0, 0.92, 0.42).lerp(Color(0.94, 0.96, 0.98), (r - 0.65) / 0.35)
	elif r > 0.30:
		return Color(0.96, 0.24, 0.16).lerp(Color(1.0, 0.92, 0.42), (r - 0.30) / 0.35)
	else:
		return Color(0.55, 0.10, 0.08).lerp(Color(0.96, 0.24, 0.16), r / 0.30)

func _push_hud_state() -> void:
	var bhud := _get_boss_hud()
	if bhud and bhud.has_method("update_boss_state"):
		var eng_ratio: float = clampf((maxf(0.0, float(grille_hp["grille_l"])) + maxf(0.0, float(grille_hp["grille_r"]))) / (GRILLE_MAX_HP * 2.0), 0.0, 1.0)
		if engine_destroyed:
			eng_ratio = 0.0
		bhud.update_boss_state({
			"crew_colors": crew_hud_colors.duplicate(),
			"coax_destroyed": coax_destroyed,
			"coax_hp_ratio": clampf(coax_hp / COAX_MAX_HP, 0.0, 1.0),
			"optics_destroyed": optics_destroyed,
			"optics_hp_ratio": clampf(optics_hp / OPTICS_MAX_HP, 0.0, 1.0),
			"fuel_tanks_destroyed": fuel_tanks_destroyed_count,
			"grilles_destroyed": grilles_destroyed_count,
			"engine_hp_ratio": eng_ratio,
			"engine_destroyed": engine_destroyed,
			"engine_burning": engine_burning,
		})

# ==========================================
# AUDIO SETUP & STATE MANAGEMENT
# ==========================================
func _setup_audio() -> void:
	audio_engine = AudioStreamPlayer3D.new()
	audio_engine.bus = "SFX"
	audio_engine.max_distance = 100.0
	audio_engine.unit_size = 18.0
	audio_engine.position = Vector3(0, 1.8, 2.2)
	add_child(audio_engine)

	audio_fire = AudioStreamPlayer3D.new()
	audio_fire.bus = "SFX"
	audio_fire.max_distance = 80.0
	audio_fire.unit_size = 14.0
	audio_fire.position = Vector3(0, 2.2, 2.3)
	add_child(audio_fire)

	audio_weapons = AudioStreamPlayer3D.new()
	audio_weapons.bus = "Weapons"
	audio_weapons.max_distance = 140.0
	audio_weapons.unit_size = 26.0
	audio_weapons.position = Vector3(0, 2.6, -2.0)
	add_child(audio_weapons)

	audio_fx = AudioStreamPlayer3D.new()
	audio_fx.bus = "SFX"
	audio_fx.max_distance = 115.0
	audio_fx.unit_size = 20.0
	audio_fx.position = Vector3(0, 2.4, 0.0)
	add_child(audio_fx)

	_set_engine_audio_mode("idle")

func _set_engine_audio_mode(mode: String) -> void:
	if current_engine_mode == mode or not audio_engine:
		return
	current_engine_mode = mode
	match mode:
		"idle":
			audio_engine.stream = SoundEffects.create_tiger_idle_sound()
			audio_engine.volume_db = -3.0
			audio_engine.pitch_scale = 0.92
			audio_engine.play()
		"move":
			audio_engine.stream = SoundEffects.create_tiger_move_sound()
			audio_engine.volume_db = -1.5
			audio_engine.pitch_scale = 0.98
			audio_engine.play()
		"broken":
			audio_engine.stream = SoundEffects.create_tiger_engine_broken_sound()
			audio_engine.volume_db = -2.0
			audio_engine.pitch_scale = 0.85
			audio_engine.play()
		"off":
			audio_engine.stop()

func _play_3d_sfx(stream: AudioStream, pos: Vector3, bus_name: String = "SFX", vol_db: float = 0.0, pitch: float = 1.0, max_dist: float = 110.0, unit_sz: float = 20.0) -> void:
	if not stream or not is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.bus = bus_name
	p.stream = stream
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	p.unit_size = unit_sz
	get_tree().root.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

# ==========================================
# MAIN PHYSICS & AI LOOP
# ==========================================
func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)

	# Always step detached permanent debris (headlights, commander MG, blown-off track arches)
	if not flying_debris.is_empty():
		_update_flying_debris(dt)

	if boss_state == BossState.DESTROYED:
		if engine_fire_light and engine_fire_light.visible:
			engine_fire_light.light_energy = randf_range(0.8, 1.8)
		return

	if boss_state == BossState.BURNING:
		_process_burning_sequence(dt)
		_update_suspension(dt, 0.0)
		return

	if boss_state == BossState.COOKOFF:
		_process_cookoff_sequence(dt)
		_update_suspension(dt, 0.0)
		return

	# ACTIVE STATE
	if not is_instance_valid(player):
		_find_player()
	if not is_instance_valid(player):
		return

	_update_awareness(dt)
	_update_hull_movement(dt)
	_update_turret_and_weapons(dt)
	_update_suspension(dt, (forward_speed - prev_forward_speed) / maxf(dt, 0.001))
	_update_running_gear(dt)
	prev_forward_speed = forward_speed

	# 88mm Cannon barrel recoil recovery
	if cannon_recoil_offset > 0.001:
		cannon_recoil_offset = lerpf(cannon_recoil_offset, 0.0, dt * 4.8)
		if cannon_recoil_node:
			cannon_recoil_node.position.z = cannon_recoil_offset

func _has_los_to_player(from_pos: Vector3) -> bool:
	if not is_instance_valid(player):
		return false
	var target_pos: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from_pos, target_pos)
	q.exclude = own_rids
	q.collide_with_bodies = true
	q.collide_with_areas = false
	var res := space.intersect_ray(q)
	if res.is_empty():
		return true
	var col: Object = res.collider
	return col == player or (col != null and col.is_in_group("player"))

func _update_awareness(dt: float) -> void:
	var p_pos: Vector3 = player.global_position
	var eye_hull: Vector3 = global_position + Vector3(0, 1.9, 0)
	var eye_turret: Vector3 = global_position + Vector3(0, 2.9, 0)

	if crew_alive["commander"]:
		driver_sees_player = true
		gunner_sees_player = true
		last_known_player_pos = p_pos
		return

	# Commander DEAD: driver & gunner operate independently in their forward vision cones!
	var to_p := (p_pos - global_position)
	to_p.y = 0.0
	var dir_to_p := to_p.normalized() if to_p.length() > 0.1 else -global_transform.basis.z
	var hull_fwd := -global_transform.basis.z
	hull_fwd.y = 0.0
	hull_fwd = hull_fwd.normalized()

	var turret_fwd := -turret_pivot.global_transform.basis.z
	turret_fwd.y = 0.0
	turret_fwd = turret_fwd.normalized()

	var los_clear := _has_los_to_player(eye_turret) or _has_los_to_player(eye_hull)
	var drv_spot: bool = crew_alive["driver"] and los_clear and (hull_fwd.dot(dir_to_p) > 0.45)
	var gun_spot: bool = los_clear and (turret_fwd.dot(dir_to_p) > 0.60)

	if drv_spot or gun_spot:
		driver_sees_player = true
		gunner_sees_player = true
		last_known_player_pos = p_pos
		search_timer = 0.0
	else:
		driver_sees_player = false
		gunner_sees_player = false
		search_timer += dt
		if search_timer > 3.2:
			search_timer = 0.0
			search_turret_dir = -search_turret_dir

# ==========================================
# SMART OBSTACLE-AVOIDANCE HULL AI
# ==========================================
func _update_hull_movement(dt: float) -> void:
	var can_move: bool = crew_alive["driver"] and not engine_destroyed
	if not can_move:
		forward_speed = move_toward(forward_speed, 0.0, BRAKE_RATE * dt)
		turn_rate = 0.0
		if engine_destroyed:
			_set_engine_audio_mode("broken")
		else:
			_set_engine_audio_mode("idle")
		return

	var target_pos: Vector3 = player.global_position if driver_sees_player else last_known_player_pos
	var to_target := target_pos - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var hull_fwd := -global_transform.basis.z
	hull_fwd.y = 0.0
	hull_fwd = hull_fwd.normalized()

	var desired_turn: float = 0.0
	var desired_speed: float = 0.0

	if avoid_reverse_timer > 0.0:
		avoid_reverse_timer -= dt

	if not driver_sees_player and not crew_alive["commander"]:
		if dist > 7.5:
			var steer_dir := _compute_avoidance_dir(to_target.normalized(), hull_fwd)
			var angle_diff := hull_fwd.signed_angle_to(steer_dir, Vector3.UP)
			desired_turn = clampf(angle_diff * 1.6, -MAX_HULL_TURN * 0.85, MAX_HULL_TURN * 0.85)
			if absf(angle_diff) < 0.55 and _probe_clearance(hull_fwd, 6.0) >= 5.2:
				desired_speed = MAX_SPEED * 0.60
		else:
			desired_turn = MAX_HULL_TURN * 0.55 * search_turret_dir
			desired_speed = 0.0
	else:
		var goal_dir: Vector3 = to_target.normalized() if dist > 0.5 else hull_fwd
		var want_advance: bool = dist > 21.0
		var want_retreat: bool = dist < 11.5
		var fwd_clear: float = _probe_clearance(hull_fwd, 11.0)
		var back_clear: float = _probe_clearance(-hull_fwd, 7.5)

		if avoid_reverse_timer > 0.0 and back_clear > 3.2:
			desired_speed = -MAX_SPEED * 0.52
			desired_turn = MAX_HULL_TURN * avoid_turn_bias
		elif want_advance:
			var steer_dir := _compute_avoidance_dir(goal_dir, hull_fwd)
			var angle_diff := hull_fwd.signed_angle_to(steer_dir, Vector3.UP)
			desired_turn = clampf(angle_diff * 2.0, -MAX_HULL_TURN, MAX_HULL_TURN)
			if fwd_clear < 3.8:
				if back_clear > 3.8 and absf(angle_diff) > 0.85:
					avoid_reverse_timer = 0.90
					desired_speed = -MAX_SPEED * 0.45
				else:
					desired_speed = 0.0
			elif absf(angle_diff) < 0.48:
				var clear_scale: float = clampf((fwd_clear - 3.4) / 7.5, 0.35, 1.0)
				desired_speed = (MAX_SPEED if dist > 26.0 else MAX_SPEED * 0.68) * clear_scale
			elif absf(angle_diff) < 0.85 and fwd_clear > 6.5:
				desired_speed = MAX_SPEED * 0.36
			else:
				desired_speed = 0.0
		elif want_retreat and back_clear > 4.6:
			var angle_diff := hull_fwd.signed_angle_to(goal_dir, Vector3.UP)
			desired_turn = clampf(angle_diff * 1.8, -MAX_HULL_TURN, MAX_HULL_TURN)
			if absf(angle_diff) < 0.7:
				desired_speed = -MAX_SPEED * 0.45
		else:
			var angle_diff := hull_fwd.signed_angle_to(goal_dir, Vector3.UP)
			if absf(angle_diff) > 0.06:
				desired_turn = clampf(angle_diff * 1.8, -MAX_HULL_TURN, MAX_HULL_TURN)
			desired_speed = 0.0

	var rate: float = ACCEL_RATE if absf(desired_speed) > absf(forward_speed) else BRAKE_RATE
	forward_speed = move_toward(forward_speed, desired_speed, rate * dt)
	turn_rate = lerpf(turn_rate, desired_turn, dt * 5.0)

	if absf(turn_rate) > 0.005:
		rotation.y += turn_rate * dt

	if absf(forward_speed) > 0.02:
		var move_vec: Vector3 = (-global_transform.basis.z) * forward_speed * dt
		move_vec.y = 0.0
		var next_pos: Vector3 = global_position + move_vec
		if not _collides_map_obstacles(next_pos):
			global_position = next_pos
		else:
			var slide_x := Vector3(next_pos.x, global_position.y, global_position.z)
			var slide_z := Vector3(global_position.x, global_position.y, next_pos.z)
			if not _collides_map_obstacles(slide_x):
				global_position = slide_x
				forward_speed *= 0.82
			elif not _collides_map_obstacles(slide_z):
				global_position = slide_z
				forward_speed *= 0.82
			else:
				forward_speed = move_toward(forward_speed, 0.0, BRAKE_RATE * 2.5 * dt)
				avoid_reverse_timer = 0.70

	var is_moving: bool = absf(forward_speed) > 0.28 or absf(turn_rate) > 0.14
	_set_engine_audio_mode("move" if is_moving else "idle")
	if audio_engine and audio_engine.playing:
		var spd_ratio: float = clampf(absf(forward_speed) / MAX_SPEED, 0.0, 1.0)
		audio_engine.pitch_scale = lerpf(0.92, 1.12, spd_ratio) if is_moving else 0.92

func _probe_clearance(dir: Vector3, max_dist: float) -> float:
	var step: float = 1.35
	var d: float = step
	var n_dir := Vector3(dir.x, 0.0, dir.z).normalized()
	if n_dir.length_squared() < 0.01:
		return 0.0
	while d <= max_dist:
		if _collides_map_obstacles(global_position + n_dir * d):
			return maxf(0.0, d - step)
		d += step
	return max_dist

func _compute_avoidance_dir(goal_dir: Vector3, hull_fwd: Vector3) -> Vector3:
	if _probe_clearance(goal_dir, 13.0) >= 12.2:
		return goal_dir

	var offsets_deg: Array[float] = [0.0, 20.0, -20.0, 40.0, -40.0, 62.0, -62.0, 86.0, -86.0, 115.0, -115.0]
	var best_dir: Vector3 = goal_dir
	var best_score: float = -9999.0
	var chosen_sign: float = avoid_turn_bias

	for deg in offsets_deg:
		var cand: Vector3 = goal_dir.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
		var clr: float = _probe_clearance(cand, 14.0)
		var goal_align: float = cand.dot(goal_dir)
		var fwd_align: float = cand.dot(hull_fwd)
		var bias_bonus: float = 0.0
		if deg != 0.0 and signf(deg) == avoid_turn_bias:
			bias_bonus = 1.65
		var score: float = clr * 2.5 + goal_align * 4.5 + fwd_align * 1.4 + bias_bonus
		if clr < 4.8:
			score -= 26.0
		if score > best_score:
			best_score = score
			best_dir = cand
			if deg != 0.0:
				chosen_sign = signf(deg)

	avoid_turn_bias = chosen_sign
	return best_dir

func _collides_map_obstacles(cand_pos: Vector3) -> bool:
	if absf(cand_pos.x) > 70.0 or absf(cand_pos.z) > 70.0:
		return true
	var tank_box := AABB(cand_pos - Vector3(3.0, 0.0, 3.0), Vector3(6.0, 3.5, 6.0))
	for obs in MapObstacles.obstacle_aabbs:
		if obs.intersects(tank_box):
			return true
	for v in get_tree().get_nodes_in_group("minivan_shop"):
		if is_instance_valid(v) and v is Node3D and (v as Node3D).visible:
			var vp: Vector3 = (v as Node3D).global_position
			if Vector2(cand_pos.x - vp.x, cand_pos.z - vp.z).length() < 6.8:
				return true
	for wb in get_tree().get_nodes_in_group("weapon_workbench"):
		if is_instance_valid(wb) and wb is Node3D:
			var wp: Vector3 = (wb as Node3D).global_position
			if Vector2(cand_pos.x - wp.x, cand_pos.z - wp.z).length() < 5.2:
				return true
	return false

# ==========================================
# TURRET TRACKING, 88mm GUN ELEVATION/DEPRESSION & WEAPONS
# ==========================================
func _update_turret_and_weapons(dt: float) -> void:
	if not turret_pivot:
		return

	var turret_speed: float = 0.36 if optics_destroyed else 0.96
	var elev_speed: float = 0.35 if optics_destroyed else 0.90

	var turret_fwd := -turret_pivot.global_transform.basis.z
	turret_fwd.y = 0.0
	turret_fwd = turret_fwd.normalized()

	var angle_to_player: float = PI
	var pitch_err: float = 0.0
	var has_los := _has_los_to_player(global_position + Vector3(0, 2.8, 0))

	if gunner_sees_player or crew_alive["commander"]:
		var target_world: Vector3 = player.global_position + Vector3(0, 0.92, 0)
		var to_p := target_world - turret_pivot.global_position
		var horiz_vec := Vector3(to_p.x, 0.0, to_p.z)
		if horiz_vec.length() > 0.1:
			angle_to_player = turret_fwd.signed_angle_to(horiz_vec.normalized(), Vector3.UP)
			var step: float = clampf(angle_to_player, -turret_speed * dt, turret_speed * dt)
			turret_pivot.rotation.y += step

		# Authentic 88mm KwK 36 Gun Elevation & Depression (-9 deg to +18 deg) with gravity drop compensation!
		if gun_elevation_pivot:
			var local_target: Vector3 = turret_pivot.to_local(target_world) - gun_elevation_pivot.position
			var horiz_d: float = maxf(0.5, Vector2(local_target.x, local_target.z).length())
			# Ballistic gravity lead so 88mm shell lands dead-on even at long distance!
			var flight_t: float = horiz_d / 52.0
			var drop_comp: float = 0.5 * 1.6 * flight_t * flight_t
			var desired_pitch: float = atan2(local_target.y + drop_comp, horiz_d)
			desired_pitch = clampf(desired_pitch, deg_to_rad(-9.5), deg_to_rad(18.0))
			gun_elevation_pivot.rotation.x = move_toward(gun_elevation_pivot.rotation.x, desired_pitch, elev_speed * dt)
			pitch_err = absf(gun_elevation_pivot.rotation.x - desired_pitch)
	else:
		turret_pivot.rotation.y += turret_speed * 0.72 * search_turret_dir * dt
		if gun_elevation_pivot:
			gun_elevation_pivot.rotation.x = move_toward(gun_elevation_pivot.rotation.x, 0.0, elev_speed * 0.5 * dt)

	if optics_destroyed:
		if absf(angle_to_player) < 0.22 and has_los and (gunner_sees_player or crew_alive["commander"]):
			gunner_reaction_timer += dt
		else:
			gunner_reaction_timer = maxf(0.0, gunner_reaction_timer - dt * 1.5)
	else:
		gunner_reaction_timer = 2.0

	var gunner_ready_to_fire: bool = (gunner_sees_player or crew_alive["commander"]) and has_los and (not optics_destroyed or gunner_reaction_timer >= 1.35)

	# 1. MAIN 88mm KwK 36 CANNON (10.0s reload)
	if cannon_timer > 0.0:
		cannon_timer -= dt
	if cannon_timer <= 0.0 and gunner_ready_to_fire and absf(angle_to_player) < 0.11 and pitch_err < 0.14:
		_fire_main_cannon()
		cannon_timer = 10.0
		if optics_destroyed:
			gunner_reaction_timer = 0.0

	# 2. COAXIAL TURRET MG-34 (Gunner: 7-shot burst, 5.0s reload; disabled if coax_destroyed)
	if not coax_destroyed:
		if coax_mg_burst_left > 0:
			coax_mg_shot_cd -= dt
			if coax_mg_shot_cd <= 0.0:
				_fire_mg_bullet(coax_mg_muzzle, 0.030 if not optics_destroyed else 0.072, 8.0)
				coax_mg_burst_left -= 1
				coax_mg_shot_cd = 0.085
				if coax_mg_burst_left <= 0:
					coax_mg_timer = 5.0
		else:
			if coax_mg_timer > 0.0:
				coax_mg_timer -= dt
			if coax_mg_timer <= 0.0 and gunner_ready_to_fire and absf(angle_to_player) < 0.18:
				coax_mg_burst_left = 7
				coax_mg_shot_cd = 0.0

	# 3. HULL MG-34 (Radio Operator: long 16-shot burst, 7.0s reload; disabled if radio operator killed)
	if crew_alive["radio"]:
		var hull_fwd := -global_transform.basis.z
		hull_fwd.y = 0.0
		hull_fwd = hull_fwd.normalized()
		var to_p := player.global_position - global_position
		to_p.y = 0.0
		var hull_in_arc: bool = to_p.length() > 1.0 and hull_fwd.dot(to_p.normalized()) > 0.78
		var hull_los: bool = _has_los_to_player(hull_mg_muzzle.global_position) if hull_mg_muzzle else has_los

		if hull_mg_burst_left > 0:
			hull_mg_shot_cd -= dt
			if hull_mg_shot_cd <= 0.0:
				if hull_in_arc:
					_fire_mg_bullet(hull_mg_muzzle, 0.042, 7.0)
				hull_mg_burst_left -= 1
				hull_mg_shot_cd = 0.075
				if hull_mg_burst_left <= 0:
					hull_mg_timer = 7.0
		else:
			if hull_mg_timer > 0.0:
				hull_mg_timer -= dt
			if hull_mg_timer <= 0.0 and hull_in_arc and hull_los and (driver_sees_player or crew_alive["commander"]):
				hull_mg_burst_left = 16
				hull_mg_shot_cd = 0.0

func _fire_main_cannon() -> void:
	if not cannon_muzzle or not is_instance_valid(player):
		return
	var muzzle_pos: Vector3 = cannon_muzzle.global_position
	var barrel_dir: Vector3 = (-cannon_muzzle.global_transform.basis.z).normalized()
	if optics_destroyed:
		barrel_dir = (barrel_dir + Vector3(randf_range(-0.045, 0.045), randf_range(-0.02, 0.02), randf_range(-0.045, 0.045))).normalized()

	var shell := TigerShellScript.new()
	get_tree().root.add_child(shell)
	shell.init(muzzle_pos, barrel_dir, own_rids)

	# Crisp 88mm barrel recoil & stiff weighted hull kickback!
	cannon_recoil_offset = 0.62
	var local_turret_angle: float = turret_pivot.rotation.y if turret_pivot else 0.0
	susp_pitch_vel += cos(local_turret_angle) * 0.44
	susp_roll_vel += sin(local_turret_angle) * 0.34

	VFXFactoryScript.spawn_explosion(get_tree().root, muzzle_pos, barrel_dir, 0.48)
	_play_3d_sfx(SoundEffects.create_tiger_cannon_sound(), muzzle_pos, "Weapons", 7.5, randf_range(0.95, 1.03), 185.0, 38.0)

func _fire_mg_bullet(muzzle: Marker3D, spread: float, dmg: float) -> void:
	if not muzzle or not is_instance_valid(player) or not EnemyBulletScene:
		return
	var muzzle_pos: Vector3 = muzzle.global_position
	var target_pos: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var dir: Vector3 = (target_pos - muzzle_pos).normalized()
	dir.x += randf_range(-spread, spread)
	dir.y += randf_range(-spread * 0.6, spread * 0.6)
	dir.z += randf_range(-spread, spread)
	dir = dir.normalized()

	var bullet := EnemyBulletScene.instantiate()
	if "ignore_owner" in bullet:
		bullet.ignore_owner = self
	get_tree().root.add_child(bullet)
	bullet.global_position = muzzle_pos
	if bullet.has_method("init"):
		bullet.init(dir, dmg, Color(1.0, 0.72, 0.18), 44.0)

	_play_3d_sfx(SoundEffects.create_tiger_mg_sound(), muzzle_pos, "Weapons", -3.0, randf_range(0.95, 1.08), 95.0)

# ==========================================
# STIFFER TORSION-BAR SUSPENSION & DETAILED RUNNING GEAR
# ==========================================
func _update_suspension(dt: float, linear_accel: float) -> void:
	if not suspension_pivot:
		return
	# Stiff, weighty 57-ton Tiger I torsion-bar suspension (controlled, crisp pitch & roll!)
	var accel_torque: float = clampf(linear_accel, -6.0, 6.0) * 0.020
	var drive_bob: float = 0.0
	var drive_roll: float = 0.0
	if absf(forward_speed) > 0.2:
		drive_rock_phase += dt * (5.2 + absf(forward_speed) * 1.5)
		var spd_f: float = clampf(absf(forward_speed) / MAX_SPEED, 0.0, 1.0)
		drive_bob = sin(drive_rock_phase) * 0.011 * spd_f
		drive_roll = cos(drive_rock_phase * 0.74) * 0.009 * spd_f

	var k_spring: float = 46.0
	var k_damp: float = 8.4
	susp_pitch_vel += (-k_spring * (susp_pitch - accel_torque) - k_damp * susp_pitch_vel) * dt
	susp_pitch = clampf(susp_pitch + susp_pitch_vel * dt, -0.075, 0.075)

	var turn_roll_target: float = clampf(turn_rate * forward_speed * 0.009, -0.032, 0.032)
	susp_roll_vel += (-k_spring * (susp_roll - turn_roll_target) - k_damp * susp_roll_vel) * dt
	susp_roll = clampf(susp_roll + susp_roll_vel * dt, -0.055, 0.055)

	suspension_pivot.rotation.x = susp_pitch + drive_bob
	suspension_pivot.rotation.z = susp_roll + drive_roll

func _update_running_gear(dt: float) -> void:
	var half_track_w: float = 1.72
	var v_left: float = forward_speed - turn_rate * half_track_w
	var v_right: float = forward_speed + turn_rate * half_track_w

	var wheel_radius: float = 0.45
	for w in left_wheels:
		w.rotation.x -= (v_left / wheel_radius) * dt
	for w in right_wheels:
		w.rotation.x -= (v_right / wheel_radius) * dt

	left_track_dist = fposmod(left_track_dist + v_left * dt, TRACK_PERIMETER)
	right_track_dist = fposmod(right_track_dist + v_right * dt, TRACK_PERIMETER)
	_position_track_pads(left_track_pads, left_track_dist)
	_position_track_pads(right_track_pads, right_track_dist)

func _position_track_pads(pads: Array[Node3D], dist_offset: float) -> void:
	# Exact closed track loop around 7.2m Tiger I running gear (bottom 6.2m, curves 0.85m each, top 6.2m)
	var perim: float = TRACK_PERIMETER
	var n: int = pads.size()
	if n == 0:
		return
	for i in range(n):
		var s: float = fposmod(dist_offset + (float(i) / float(n)) * perim, perim)
		var pz: float = 0.0
		var py: float = 0.05
		var rx: float = 0.0
		if s < 6.20:
			# Bottom ground contact run (-3.10 -> +3.10)
			pz = -3.10 + s
			py = 0.045
			rx = 0.0
		elif s < 7.05:
			# Rear idler wheel wrap (+Z)
			var u: float = (s - 6.20) / 0.85
			var ang: float = -PI * 0.5 + u * PI
			pz = 3.10 + cos(ang) * 0.50
			py = 0.545 + sin(ang) * 0.50
			rx = ang + PI * 0.5
		elif s < 13.25:
			# Upper return run (+3.10 -> -3.10) with subtle realistic catenary sag over road wheels
			var u_top: float = (s - 7.05) / 6.20
			pz = 3.10 - u_top * 6.20
			py = 1.045 - sin(u_top * PI) * 0.025
			rx = 0.0
		else:
			# Front toothed drive sprocket wrap (-Z)
			var u: float = (s - 13.25) / 0.85
			var ang: float = PI * 0.5 + u * PI
			pz = -3.10 + cos(ang) * 0.50
			py = 0.545 + sin(ang) * 0.50
			rx = ang + PI * 0.5
		pads[i].position.y = py
		pads[i].position.z = pz
		pads[i].rotation.x = rx

# ==========================================
# UNIFIED PERMANENT FLYING DEBRIS PHYSICS
# (Headlights, Commander MG-34, Blown-off Track Fender Arches)
# ==========================================
func _launch_permanent_debris(node: Node3D, impulse: Vector3, spin: Vector3, rest_y: float = 0.08, remove_hb_name: String = "", is_turret: bool = false) -> void:
	if not node or not is_instance_valid(node) or not is_inside_tree():
		return
	if remove_hb_name != "":
		var hb := node.get_node_or_null(remove_hb_name)
		if hb:
			hb.queue_free()
	var world_xf: Transform3D = node.global_transform
	var par := node.get_parent()
	if par:
		par.remove_child(node)
	get_tree().root.add_child(node)
	node.global_transform = world_xf
	flying_debris.append({
		"node": node,
		"vel": impulse,
		"ang": spin,
		"rest_y": rest_y,
		"is_turret": is_turret,
		"settled": false,
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
		var rest_y: float = item["rest_y"]
		var is_turret: bool = bool(item.get("is_turret", false))
		vel.y -= 17.0 * dt
		n.global_position += vel * dt
		n.rotation += ang * dt
		if n.global_position.y <= rest_y:
			n.global_position.y = rest_y
			var impact_speed: float = absf(vel.y)
			if impact_speed > 1.35:
				vel.y = -vel.y * (0.24 if is_turret else 0.34)
				vel.x *= (0.48 if is_turret else 0.62)
				vel.z *= (0.48 if is_turret else 0.62)
				ang *= (0.38 if is_turret else 0.52)
				if is_turret:
					if impact_speed > 5.0:
						# Heavy 11-ton turret slams into the ground with dust cloud & deep metallic thud!
						VFXFactoryScript.spawn_explosion(get_tree().root, n.global_position, Vector3.UP, 0.72)
						_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), n.global_position, "SFX", 1.5, 0.65, 110.0)
				else:
					_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), n.global_position, "SFX", -7.5, randf_range(1.05, 1.40), 55.0)
			else:
				vel = Vector3.ZERO
				ang = Vector3.ZERO
				item["settled"] = true
				if is_turret:
					# Register landed permanent turret wreck in MapObstacles so Minivan & Workbench avoid it!
					var t_aabb := AABB(n.global_position - Vector3(2.8, 0.0, 2.8), Vector3(5.6, 2.2, 5.6))
					MapObstacles.obstacle_aabbs.append(t_aabb)
		item["vel"] = vel
		item["ang"] = ang
	if not any_active and flying_debris.size() > 0:
		# Debris nodes remain on the ground in scene tree FOREVER; clear tracking array once settled
		flying_debris.clear()

# ==========================================
# MODULAR BULLET & RPG DAMAGE SYSTEM
# ==========================================
func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	if amount >= 9000.0 and boss_state != BossState.DESTROYED:
		force_instant_destroy()

func force_instant_destroy() -> void:
	if boss_state == BossState.DESTROYED:
		return
	for k in crew_alive.keys():
		crew_alive[k] = false
		crew_hud_colors[k] = Color(0.11, 0.11, 0.13)
	_push_hud_state()
	_complete_final_explosion()

func on_bullet_hit(zone_id: String, dmg: float, hit_pos: Vector3, hit_normal: Vector3) -> bool:
	if boss_state == BossState.DESTROYED:
		_spawn_ricochet(hit_pos, hit_normal, false)
		return false

	# 1. Decorative destroyable parts (headlights & commander's pintle MG - ANY weapon launches them off forever!)
	if zone_id == "headlight_l" or zone_id == "headlight_r":
		if not headlight_destroyed[zone_id]:
			_destroy_headlight(zone_id, hit_pos, hit_normal)
			return true
		return false

	if zone_id == "mod_cmd_mg":
		if not cmd_mg_destroyed:
			_destroy_commander_mg(hit_pos, hit_normal)
			return true
		return false

	if boss_state == BossState.BURNING or boss_state == BossState.COOKOFF:
		_spawn_ricochet(hit_pos, hit_normal, false)
		return false

	# 2. Killable Crew (Driver via exact glass, Radio via exact glass, Commander via exposed body ONLY!)
	if zone_id == "crew_driver" or zone_id == "crew_radio" or zone_id == "crew_commander":
		var cid: String = zone_id.replace("crew_", "")
		if crew_alive[cid]:
			crew_hp[cid] = maxf(0.0, float(crew_hp[cid]) - dmg)
			if crew_hp[cid] <= 0.0:
				_kill_crew_member(cid)
			else:
				# Dynamic color shift as crew member takes damage!
				crew_hud_colors[cid] = _hp_ratio_to_color(float(crew_hp[cid]) / CREW_MAX_HP)
				_push_hud_state()
			return true
		return false

	# 3. Coaxial Gunner MG
	if zone_id == "mod_coax_mg":
		if not coax_destroyed:
			coax_hp = maxf(0.0, coax_hp - dmg)
			if coax_hp <= 0.0:
				coax_destroyed = true
				if coax_mg_visual:
					coax_mg_visual.rotation.x = deg_to_rad(28.0)
				_spawn_module_break_fx(hit_pos)
			_push_hud_state()
			return true
		return false

	# 4. Gunner Optics (impenetrable glass -> damages optics ONLY, NEVER kills Yellow Gunner!)
	if zone_id == "mod_optics":
		if not optics_destroyed:
			optics_hp = maxf(0.0, optics_hp - dmg)
			if optics_hp <= 0.0:
				optics_destroyed = true
				if optics_glass_mesh:
					var dark_m := StandardMaterial3D.new()
					dark_m.albedo_color = Color(0.04, 0.04, 0.05, 0.90)
					dark_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					dark_m.roughness = 0.88
					optics_glass_mesh.material_override = dark_m
				_spawn_module_break_fx(hit_pos)
			_push_hud_state()
			return true
		return false

	# 5. Attached Side Fuel Tanks (4 total: 2 left, 2 right near rear)
	if fuel_hp.has(zone_id):
		if not fuel_destroyed[zone_id]:
			fuel_hp[zone_id] = maxf(0.0, float(fuel_hp[zone_id]) - dmg)
			if fuel_hp[zone_id] <= 0.0:
				_destroy_fuel_tank(zone_id, hit_pos)
			return true
		return false

	# 6. Rear Engine Cooling Grilles (2 total)
	if grille_hp.has(zone_id):
		if not grille_destroyed[zone_id]:
			grille_hp[zone_id] = maxf(0.0, float(grille_hp[zone_id]) - dmg)
			if grille_hp[zone_id] <= 0.0:
				_destroy_grille(zone_id, hit_pos)
			else:
				_push_hud_state()
			return true
		return false

	# 7. Solid heavy armor face -> metallic ricochet!
	_spawn_ricochet(hit_pos, hit_normal, true)
	return false

func on_rpg_hit(hit_pos: Vector3, hit_normal: Vector3, direct_collider: Object, _dmg: float, _blast_radius: float, ammo_mode: String = "standard") -> bool:
	if boss_state != BossState.ACTIVE:
		return false

	var zone_id: String = ""
	if direct_collider and direct_collider is Node and (direct_collider as Node).has_meta("hit_zone"):
		if (direct_collider as Node).get_meta("tiger_owner") == self:
			zone_id = str((direct_collider as Node).get_meta("hit_zone"))

	var local_hit: Vector3 = to_local(hit_pos)
	var max_reach: float = 11.0 if ammo_mode == "thermobaric" else 7.6
	if local_hit.length() > max_reach and zone_id == "":
		return false

	if zone_id == "":
		if local_hit.y > 2.08 and absf(local_hit.x) < 1.75 and absf(local_hit.z) < 2.2:
			zone_id = "turret_armor"
		elif local_hit.z < -2.6:
			zone_id = "hull_front"
		elif local_hit.z > 2.6:
			zone_id = "hull_rear"
		elif local_hit.x < 0.0:
			zone_id = "hull_left"
		else:
			zone_id = "hull_right"

	# THERMOBARIC TBG-7V: Huge fuel-air shockwave shreds exterior modules & kills exposed Commander, but doesn't punch thick hull armor!
	if ammo_mode == "thermobaric":
		susp_pitch_vel += 0.65
		var did_hit: bool = _damage_nearby_modules_from_rpg(hit_pos, 6.5, true)
		if crew_alive.get("commander", false):
			_kill_crew_member("commander")
			did_hit = true
		return did_hit

	# TANDEM PG-7VR: True Anti-Armor Penetration!
	# - Punches straight through FRONT armor & turret (counts toward cook-off & wrecks front modules!)
	# - Side hit counts as 2 hits (only 2 tandem rockets ignite catastrophic ammo cook-off instead of 3!)
	# - Rear hit instantly kills engine + torches rear fuel!
	if ammo_mode == "tandem":
		if zone_id == "hull_rear" or zone_id == "grille_l" or zone_id == "grille_r":
			_destroy_engine_instantly(hit_pos)
			_damage_nearby_modules_from_rpg(hit_pos, 3.8, true)
			return true
		if zone_id in ["hull_front", "turret_armor", "gun_barrel", "mod_coax_mg", "mod_optics", "crew_commander", "mod_cmd_mg", "crew_driver", "crew_radio", "headlight_l", "headlight_r"]:
			susp_pitch_vel -= 0.72
			rpg_hits_left += 1
			rpg_hits_right += 1
			_damage_nearby_modules_from_rpg(hit_pos, 3.2, false)
			if rpg_hits_left >= 3 or rpg_hits_right >= 3:
				_start_ammo_cookoff_sequence()
			return true
		if zone_id == "hull_left" or zone_id == "fuel_l1" or zone_id == "fuel_l2":
			rpg_hits_left += 2
			susp_roll_vel += 0.85
			if rpg_hits_left >= 3:
				_start_ammo_cookoff_sequence()
				return true
			_damage_nearby_modules_from_rpg(hit_pos, 3.4, true)
			return true
		if zone_id == "hull_right" or zone_id == "fuel_r1" or zone_id == "fuel_r2":
			rpg_hits_right += 2
			susp_roll_vel -= 0.85
			if rpg_hits_right >= 3:
				_start_ammo_cookoff_sequence()
				return true
			_damage_nearby_modules_from_rpg(hit_pos, 3.4, true)
			return true

	# STANDARD PG-7V RULES:
	# RULE A: Front armor or ANY part of turret -> ZERO hull kill, ONLY damages nearby modules (NEVER kills crew!)
	if zone_id in ["hull_front", "turret_armor", "gun_barrel", "mod_coax_mg", "mod_optics", "crew_commander", "mod_cmd_mg", "crew_driver", "crew_radio", "headlight_l", "headlight_r"]:
		_spawn_ricochet(hit_pos, hit_normal, true)
		return _damage_nearby_modules_from_rpg(hit_pos, 2.0, false)

	# RULE B: Rear hit -> INSTANTLY destroys engine (does NOT destroy fuel tanks!)
	if zone_id == "hull_rear" or zone_id == "grille_l" or zone_id == "grille_r":
		_destroy_engine_instantly(hit_pos)
		return true

	# RULE C: Side hit -> 3 hits to ONE side ignites AMMO-RACK COOK-OFF (pressurized fire jet from cupola -> catastrophic turret toss!)
	if zone_id == "hull_left" or zone_id == "fuel_l1" or zone_id == "fuel_l2":
		rpg_hits_left += 1
		susp_roll_vel += 0.55
		if rpg_hits_left >= 3:
			_start_ammo_cookoff_sequence()
			return true
		_damage_nearby_modules_from_rpg(hit_pos, 2.2, true)
		return true

	if zone_id == "hull_right" or zone_id == "fuel_r1" or zone_id == "fuel_r2":
		rpg_hits_right += 1
		susp_roll_vel -= 0.55
		if rpg_hits_right >= 3:
			_start_ammo_cookoff_sequence()
			return true
		_damage_nearby_modules_from_rpg(hit_pos, 2.2, true)
		return true

	return false

func _damage_nearby_modules_from_rpg(hit_pos: Vector3, radius: float, include_fuel: bool) -> bool:
	var hit_any := false
	for hb in all_hitboxes:
		if not is_instance_valid(hb):
			continue
		var z: String = str(hb.get_meta("hit_zone"))
		# RPG ONLY destroys modules — NEVER kills individual crew members!
		if z in ["hull_front", "hull_left", "hull_right", "hull_rear", "turret_armor", "gun_barrel", "crew_driver", "crew_radio", "crew_commander"]:
			continue
		if not include_fuel and fuel_hp.has(z):
			continue
		if grille_hp.has(z):
			continue
		if hb.global_position.distance_to(hit_pos) <= radius:
			if on_bullet_hit(z, 95.0, hb.global_position, Vector3.UP):
				hit_any = true
	return hit_any

func _kill_crew_member(cid: String) -> void:
	if not crew_alive.get(cid, false):
		return
	crew_alive[cid] = false
	crew_hud_colors[cid] = Color(0.11, 0.11, 0.13)
	if cid == "driver":
		forward_speed = 0.0
		turn_rate = 0.0
		if driver_glass_mesh and is_instance_valid(driver_glass_mesh):
			var cracked := StandardMaterial3D.new()
			cracked.albedo_color = Color(0.05, 0.06, 0.07, 0.86)
			cracked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cracked.roughness = 0.82
			driver_glass_mesh.material_override = cracked
	elif cid == "radio":
		hull_mg_burst_left = 0
		if radio_glass_mesh and is_instance_valid(radio_glass_mesh):
			var cracked := StandardMaterial3D.new()
			cracked.albedo_color = Color(0.05, 0.06, 0.07, 0.86)
			cracked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cracked.roughness = 0.82
			radio_glass_mesh.material_override = cracked
	if crew_models.has(cid) and is_instance_valid(crew_models[cid]):
		var cm: Node3D = crew_models[cid]
		if cid == "commander":
			cm.position.y -= 0.56
			cm.rotation.x = deg_to_rad(36.0)
			var chb := turret_pivot.get_node_or_null("HB_crew_commander") if turret_pivot else null
			if chb:
				chb.queue_free()
		else:
			cm.position.y -= 0.34
			cm.rotation.x = deg_to_rad(28.0)
	_push_hud_state()

func _destroy_fuel_tank(zone_id: String, hit_pos: Vector3) -> void:
	if fuel_destroyed[zone_id]:
		return
	fuel_destroyed[zone_id] = true
	fuel_tanks_destroyed_count += 1

	if fuel_meshes.has(zone_id) and is_instance_valid(fuel_meshes[zone_id]):
		var fn: Node3D = fuel_meshes[zone_id]
		var charred := StandardMaterial3D.new()
		charred.albedo_color = Color(0.08, 0.07, 0.07)
		charred.roughness = 0.92
		_apply_material_recursive(fn, charred)
		fn.scale = Vector3(0.82, 0.72, 0.88)

	VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 0.45)
	_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), hit_pos, "SFX", -3.0, randf_range(1.25, 1.45), 90.0)

	if fuel_tanks_destroyed_count >= 4:
		VFXFactoryScript.spawn_explosion(get_tree().root, hit_pos, Vector3.UP, 1.10)
		_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), hit_pos, "SFX", 2.0, 1.05, 115.0)
		if engine_destroyed:
			_start_destruction_sequence()
		else:
			_enable_engine_smoke()

	_push_hud_state()

func _destroy_grille(zone_id: String, hit_pos: Vector3) -> void:
	if grille_destroyed[zone_id]:
		return
	grille_destroyed[zone_id] = true
	grille_hp[zone_id] = 0.0
	grilles_destroyed_count += 1
	_spawn_module_break_fx(hit_pos)

	if grille_smoke.has(zone_id) and is_instance_valid(grille_smoke[zone_id]):
		(grille_smoke[zone_id] as CPUParticles3D).emitting = true

	if grilles_destroyed_count >= 2:
		_on_engine_failed()
	_push_hud_state()

func _destroy_engine_instantly(hit_pos: Vector3) -> void:
	for gid in ["grille_l", "grille_r"]:
		if not grille_destroyed[gid]:
			grille_destroyed[gid] = true
			grille_hp[gid] = 0.0
			grilles_destroyed_count += 1
			if grille_smoke.has(gid) and is_instance_valid(grille_smoke[gid]):
				(grille_smoke[gid] as CPUParticles3D).emitting = true
	_spawn_module_break_fx(hit_pos)
	_on_engine_failed()
	_push_hud_state()

func _on_engine_failed() -> void:
	if engine_destroyed:
		return
	engine_destroyed = true
	forward_speed = 0.0
	turn_rate = 0.0
	_set_engine_audio_mode("broken")

	if fuel_tanks_destroyed_count >= 4:
		_start_destruction_sequence()
	else:
		_enable_engine_smoke()

func _enable_engine_smoke() -> void:
	engine_smoking = true
	if engine_smoke_fx:
		engine_smoke_fx.emitting = true

func _destroy_headlight(zone_id: String, hit_pos: Vector3, hit_normal: Vector3) -> void:
	if headlight_destroyed[zone_id]:
		return
	headlight_destroyed[zone_id] = true
	if headlight_lights.has(zone_id) and is_instance_valid(headlight_lights[zone_id]):
		(headlight_lights[zone_id] as SpotLight3D).visible = false
	if headlight_bulbs.has(zone_id) and is_instance_valid(headlight_bulbs[zone_id]):
		var off_m := StandardMaterial3D.new()
		off_m.albedo_color = Color(0.04, 0.04, 0.05)
		off_m.roughness = 0.85
		(headlight_bulbs[zone_id] as MeshInstance3D).material_override = off_m
	_spawn_ricochet(hit_pos, hit_normal, true)
	if headlight_nodes.has(zone_id) and is_instance_valid(headlight_nodes[zone_id]):
		var kick_dir := (hit_normal + Vector3(randf_range(-0.6, 0.6), 0.95, randf_range(-0.6, 0.6))).normalized()
		_launch_permanent_debris(
			headlight_nodes[zone_id],
			kick_dir * randf_range(4.2, 6.8),
			Vector3(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0), randf_range(-9.0, 9.0)),
			0.11,
			"HB_" + zone_id
		)

func _destroy_commander_mg(hit_pos: Vector3, hit_normal: Vector3) -> void:
	if cmd_mg_destroyed:
		return
	cmd_mg_destroyed = true
	_spawn_ricochet(hit_pos, hit_normal, true)
	if cmd_mg_node and is_instance_valid(cmd_mg_node):
		var kick_dir := (hit_normal + Vector3(randf_range(-0.5, 0.5), 1.15, randf_range(-0.5, 0.5))).normalized()
		_launch_permanent_debris(
			cmd_mg_node,
			kick_dir * randf_range(4.8, 7.4),
			Vector3(randf_range(-8.5, 8.5), randf_range(-6.5, 6.5), randf_range(-8.5, 8.5)),
			0.09,
			"HB_mod_cmd_mg"
		)

func _spawn_metal_sparks(pos: Vector3, normal: Vector3) -> void:
	if not is_inside_tree():
		return
	var cp := CPUParticles3D.new()
	cp.one_shot = true
	cp.explosiveness = 0.95
	cp.amount = 14
	cp.lifetime = 0.28
	cp.direction = normal.normalized() if normal.length_squared() > 0.01 else Vector3.UP
	cp.spread = 52.0
	cp.gravity = Vector3(0, -11.0, 0)
	cp.initial_velocity_min = 3.5
	cp.initial_velocity_max = 8.5
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, 0.14)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.86, 0.36)
	bm.material = smat
	cp.mesh = bm
	get_tree().root.add_child(cp)
	cp.global_position = pos
	cp.emitting = true
	get_tree().create_timer(0.45).timeout.connect(cp.queue_free)

func _spawn_ricochet(pos: Vector3, normal: Vector3, play_sound: bool) -> void:
	_spawn_metal_sparks(pos, normal)
	if play_sound:
		_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), pos, "SFX", -3.5, randf_range(0.92, 1.18), 72.0)

func _spawn_module_break_fx(pos: Vector3) -> void:
	_spawn_metal_sparks(pos, Vector3.UP)
	_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), pos, "SFX", -1.5, randf_range(0.78, 0.92), 82.0)

# ==========================================
# BURNING -> CREW SCREAMING -> 5s SILENCE -> FINAL EXPLOSION!
# ==========================================
func _start_destruction_sequence() -> void:
	if boss_state != BossState.ACTIVE:
		return
	boss_state = BossState.BURNING
	engine_burning = true
	engine_destroyed = true
	forward_speed = 0.0
	turn_rate = 0.0
	hull_mg_burst_left = 0
	coax_mg_burst_left = 0

	_set_engine_audio_mode("off")
	if audio_fire:
		audio_fire.stream = SoundEffects.create_tiger_fire_sound()
		audio_fire.volume_db = 1.5
		audio_fire.play()

	_enable_engine_smoke()
	if engine_fire_fx:
		engine_fire_fx.emitting = true
	if engine_fire_light:
		engine_fire_light.visible = true

	alive_before_burn.clear()
	for cid in crew_alive.keys():
		if crew_alive[cid]:
			alive_before_burn.append(cid)

	burn_phase = 1
	burn_timer = 0.0
	if audio_fx:
		audio_fx.stream = SoundEffects.create_tiger_crew_scream_sound()
		audio_fx.volume_db = 3.5
		audio_fx.play()

	_push_hud_state()

func _process_burning_sequence(dt: float) -> void:
	burn_timer += dt
	if engine_fire_light:
		engine_fire_light.light_energy = randf_range(3.5, 6.2)

	if burn_phase == 1:
		var t: float = clampf(burn_timer / scream_duration, 0.0, 1.0)
		var col: Color
		if t < 0.33:
			col = Color(0.94, 0.96, 0.98).lerp(Color(1.0, 0.85, 0.15), t / 0.33)
		elif t < 0.68:
			col = Color(1.0, 0.85, 0.15).lerp(Color(0.96, 0.18, 0.12), (t - 0.33) / 0.35)
		else:
			col = Color(0.96, 0.18, 0.12).lerp(Color(0.11, 0.11, 0.13), (t - 0.68) / 0.32)

		for cid in alive_before_burn:
			crew_hud_colors[cid] = col
		_push_hud_state()

		if burn_timer >= scream_duration:
			for cid in crew_alive.keys():
				crew_alive[cid] = false
				crew_hud_colors[cid] = Color(0.11, 0.11, 0.13)
			_push_hud_state()
			if audio_fx:
				audio_fx.stop()
			burn_phase = 2
			burn_timer = 0.0

	elif burn_phase == 2:
		if burn_timer >= 5.0:
			_complete_final_explosion(false)

# ==========================================
# RPG-7 AMMO-RACK COOK-OFF: HIGH PRESSURIZED FIRE JET FROM COMMANDER'S HATCH
# -> CATASTROPHIC EXPLOSION & TURRET TOSS!
# ==========================================
func _start_ammo_cookoff_sequence() -> void:
	if boss_state != BossState.ACTIVE:
		return
	boss_state = BossState.COOKOFF
	cookoff_timer = 0.0
	forward_speed = 0.0
	turn_rate = 0.0
	hull_mg_burst_left = 0
	coax_mg_burst_left = 0

	# Stop engine audio & launch intense pressurized propellant jet sound!
	_set_engine_audio_mode("off")
	if audio_fire:
		audio_fire.stream = SoundEffects.create_tiger_ammo_cookoff_sound()
		audio_fire.volume_db = 4.5
		audio_fire.pitch_scale = 0.96
		audio_fire.play()

	# Hide commander immediately as the roaring jet erupts out of his cupola hatch!
	if crew_models.has("commander") and is_instance_valid(crew_models["commander"]):
		(crew_models["commander"] as Node3D).visible = false
	var chb := turret_pivot.get_node_or_null("HB_crew_commander") if turret_pivot else null
	if chb:
		chb.queue_free()

	# Track all surviving crew so their icons rapidly burn down during cook-off
	alive_before_burn.clear()
	for cid in crew_alive.keys():
		if crew_alive[cid]:
			alive_before_burn.append(cid)

	# Ignite fierce 7-9m vertical pressurized flame jet straight out of commander's cupola!
	if ammo_jet_outer_fx:
		ammo_jet_outer_fx.emitting = true
	if ammo_jet_core_fx:
		ammo_jet_core_fx.emitting = true
	if ammo_jet_sparks_fx:
		ammo_jet_sparks_fx.emitting = true
	if ammo_jet_light:
		ammo_jet_light.visible = true
	_enable_engine_smoke()

	# Initial pressure burst kick
	susp_pitch_vel -= 0.45
	_push_hud_state()

func _process_cookoff_sequence(dt: float) -> void:
	cookoff_timer += dt
	var progress: float = clampf(cookoff_timer / COOKOFF_DURATION, 0.0, 1.0)

	# Violent turret shudder & climbing jet pressure pitch right before the turret blows off!
	if turret_pivot:
		var shake_amp: float = lerpf(0.008, 0.026, progress)
		turret_pivot.position.y = 1.00 + sin(cookoff_timer * 72.0) * shake_amp
	if ammo_jet_light:
		ammo_jet_light.light_energy = randf_range(6.5, 11.5) * lerpf(0.85, 1.35, progress)
	if audio_fire and audio_fire.playing:
		audio_fire.pitch_scale = lerpf(0.95, 1.24, progress)

	# Rapidly transition all surviving crew icons White -> Yellow -> Red -> Black over first 2.6s
	var ct: float = clampf(cookoff_timer / 2.6, 0.0, 1.0)
	var col: Color
	if ct < 0.30:
		col = Color(0.94, 0.96, 0.98).lerp(Color(1.0, 0.85, 0.15), ct / 0.30)
	elif ct < 0.65:
		col = Color(1.0, 0.85, 0.15).lerp(Color(0.96, 0.18, 0.12), (ct - 0.30) / 0.35)
	else:
		col = Color(0.96, 0.18, 0.12).lerp(Color(0.11, 0.11, 0.13), (ct - 0.65) / 0.35)
	for cid in alive_before_burn:
		crew_hud_colors[cid] = col
	if ct >= 1.0:
		for cid in crew_alive.keys():
			crew_alive[cid] = false
			crew_hud_colors[cid] = Color(0.11, 0.11, 0.13)
	_push_hud_state()

	if cookoff_timer >= COOKOFF_DURATION:
		_complete_final_explosion(true)

func _strip_hitboxes_recursive(node: Node) -> void:
	for c in node.get_children():
		if c is StaticBody3D and c.is_in_group("tiger_hitbox"):
			c.queue_free()
		else:
			_strip_hitboxes_recursive(c)

func _complete_final_explosion(is_ammo_detonation: bool = false) -> void:
	if boss_state == BossState.DESTROYED:
		return
	boss_state = BossState.DESTROYED
	burn_phase = 3
	is_dead = true
	health = 0.0
	_set_engine_audio_mode("off")
	if audio_fx:
		audio_fx.stop()

	# Shut off pressurized cook-off jet emitters once turret explodes
	if ammo_jet_outer_fx:
		ammo_jet_outer_fx.emitting = false
	if ammo_jet_core_fx:
		ammo_jet_core_fx.emitting = false
	if ammo_jet_sparks_fx:
		ammo_jet_sparks_fx.emitting = false
	if ammo_jet_light:
		ammo_jet_light.visible = false

	# Switch roaring cook-off / fire audio to quiet lingering smolder
	if audio_fire:
		audio_fire.stream = SoundEffects.create_tiger_fire_sound()
		audio_fire.pitch_scale = 0.90
		audio_fire.volume_db = -9.0
		audio_fire.play()

	var exp_pos: Vector3 = global_position + Vector3(0, 2.5, 0)
	if is_ammo_detonation:
		# CATASTROPHIC AMMO-RACK EXPLOSION (much stronger than regular Tiger destruction!)
		VFXFactoryScript.spawn_explosion(get_tree().root, exp_pos, Vector3.UP, 3.65)
		VFXFactoryScript.spawn_explosion(get_tree().root, exp_pos + Vector3(0, 2.2, 0), Vector3.UP, 2.60)
		_play_3d_sfx(SoundEffects.create_tiger_ammo_explosion_sound(), exp_pos, "Weapons", 7.5, 0.88, 200.0)
		_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), exp_pos, "Weapons", 5.0, 0.74, 200.0)
	else:
		# Standard destruction explosion
		VFXFactoryScript.spawn_explosion(get_tree().root, exp_pos, Vector3.UP, 2.45)
		_play_3d_sfx(SoundEffects.create_tiger_explosion_sound(), exp_pos, "Weapons", 6.0, 0.92, 165.0)

	# Player explosion blast damage & shockwave camera shake (stronger & farther on ammo-rack detonation!)
	var blast_dmg: float = 85.0 if is_ammo_detonation else 50.0
	var blast_rad: float = 19.5 if is_ammo_detonation else 14.5
	var shake_rad: float = 65.0 if is_ammo_detonation else 48.0
	var shake_amp: float = 0.68 if is_ammo_detonation else 0.45
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node3D:
			var dist: float = exp_pos.distance_to((p as Node3D).global_position + Vector3(0, 0.9, 0))
			if dist <= blast_rad and p.has_method("take_damage"):
				p.take_damage(blast_dmg)
			if dist <= shake_rad and p.has_method("add_camera_shake"):
				var shake: float = clampf(1.0 - dist / shake_rad, 0.15, 1.0) * shake_amp
				p.add_camera_shake(shake)

	# 1. Blast off any still-attached headlights & commander MG so they fly away and stay on ground forever!
	for hl_id in ["headlight_l", "headlight_r"]:
		if not headlight_destroyed[hl_id] and headlight_nodes.has(hl_id) and is_instance_valid(headlight_nodes[hl_id]):
			var hl_pos: Vector3 = (headlight_nodes[hl_id] as Node3D).global_position
			var blast_dir := (hl_pos - exp_pos + Vector3(0, 2.2, 0)).normalized()
			_destroy_headlight(hl_id, hl_pos, blast_dir)
	if not cmd_mg_destroyed and cmd_mg_node and is_instance_valid(cmd_mg_node):
		var mg_pos: Vector3 = cmd_mg_node.global_position
		var blast_dir := (mg_pos - exp_pos + Vector3(0, 3.0, 0)).normalized()
		_destroy_commander_mg(mg_pos, blast_dir)

	# 2. Blast off a realistic subset of the Tiger I track fender arches forever onto the ground!
	var arch_pool: Array[Node3D] = detachable_arches.duplicate()
	arch_pool.shuffle()
	var detach_count: int = mini(arch_pool.size(), randi_range(6, 9) if is_ammo_detonation else randi_range(5, 8))
	for ai in range(detach_count):
		var arch: Node3D = arch_pool[ai]
		if not is_instance_valid(arch):
			continue
		var a_pos: Vector3 = arch.global_position
		var out_dir: Vector3 = (a_pos - exp_pos)
		out_dir.y = 0.0
		if out_dir.length() < 0.2:
			out_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		out_dir = (out_dir.normalized() + Vector3(randf_range(-0.25, 0.25), randf_range(0.75, 1.45), randf_range(-0.25, 0.25))).normalized()
		var char_a := StandardMaterial3D.new()
		char_a.albedo_color = Color(0.11, 0.11, 0.12)
		char_a.metallic = 0.45
		char_a.roughness = 0.88
		_apply_material_recursive(arch, char_a)
		_launch_permanent_debris(
			arch,
			out_dir * randf_range(8.0, 14.0) if is_ammo_detonation else out_dir * randf_range(6.5, 11.5),
			Vector3(randf_range(-6.5, 6.5), randf_range(-5.5, 5.5), randf_range(-6.5, 6.5)),
			0.09
		)

	# 3. Char the permanent Tiger wreck & hide crew models
	var charred_steel := StandardMaterial3D.new()
	charred_steel.albedo_color = Color(0.08, 0.08, 0.09)
	charred_steel.metallic = 0.35
	charred_steel.roughness = 0.92
	_apply_material_recursive(suspension_pivot, charred_steel)

	for cm in crew_models.values():
		if is_instance_valid(cm):
			(cm as Node3D).visible = false
	if cupola_hatch:
		cupola_hatch.rotation.x = deg_to_rad(-118.0)

	if is_ammo_detonation and turret_pivot and is_instance_valid(turret_pivot):
		# TURRET TOSS ("БАШНЮ ОТРЫВАЕТ")! Strip live combat hitboxes and blow the entire 11-ton turret sky-high!
		turret_tossed = true
		_strip_hitboxes_recursive(turret_pivot)
		var toss_ang: float = randf_range(0.0, TAU)
		var toss_horiz: float = randf_range(4.2, 6.2)
		var toss_vel := Vector3(cos(toss_ang) * toss_horiz, randf_range(13.0, 16.5), sin(toss_ang) * toss_horiz)
		var toss_spin := Vector3(randf_range(-2.6, 2.6), randf_range(-1.8, 1.8), randf_range(-2.6, 2.6))
		_launch_permanent_debris(turret_pivot, toss_vel, toss_spin, 0.62, "", true)
		# Dark blown-out turret ring crater + rising smoke on the headless hull!
		var crater_mat := StandardMaterial3D.new()
		crater_mat.albedo_color = Color(0.02, 0.02, 0.025)
		crater_mat.roughness = 0.98
		_add_cyl(suspension_pivot, "BlownTurretCrater", 1.32, 1.32, 0.10, Vector3(0, 1.02, -0.22), crater_mat, 18)
		if hull_ring_smoke_fx:
			hull_ring_smoke_fx.emitting = true
	elif turret_pivot:
		turret_pivot.rotation.z = deg_to_rad(randf_range(-7.0, 7.0))
		turret_pivot.rotation.x = deg_to_rad(randf_range(-5.0, 5.0))
		turret_pivot.position.y += 0.08

	if engine_fire_fx:
		engine_fire_fx.amount = 16
	if engine_smoke_fx:
		engine_smoke_fx.emitting = true

	# 4. Register permanent wreck AABB in MapObstacles for MinivanShop & WeaponWorkbench
	_register_permanent_wreck_obstacle()

	if is_in_group("enemy"):
		remove_from_group("enemy")
	add_to_group("tiger_wreck")

	var bhud := _get_boss_hud()
	if bhud and bhud.has_method("show_tiger_destroyed"):
		bhud.show_tiger_destroyed()

	died.emit(score_value)

func _register_permanent_wreck_obstacle() -> void:
	if wreck_aabb_registered:
		return
	wreck_aabb_registered = true
	var wreck_aabb := AABB(global_position - Vector3(4.6, 0.0, 4.6), Vector3(9.2, 3.8, 9.2))
	MapObstacles.obstacle_aabbs.append(wreck_aabb)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for c in node.get_children():
		if c is CPUParticles3D:
			continue
		_apply_material_recursive(c, mat)

# ==========================================
# REBUILT FROM SCRATCH: HIGH-DETAIL LIGHT-GREY TIGER I AUSF. E
# (7.2m long x 4.16m wide, hollow crew cabins, 8-axle Schachtellaufwerk,
#  34 track pads/side, segmented track arches, rear-grouped fuel tanks,
#  elevating 88mm KwK 36 cannon, full-size crew behind optic glass!)
# ==========================================
func _build_tiger_model() -> void:
	# Authentic Light Wehrmacht Panzer Grey palette
	var mat_hull := StandardMaterial3D.new()
	mat_hull.albedo_color = Color(0.57, 0.60, 0.63) # Crisp Light Panzer Grey
	mat_hull.metallic = 0.30
	mat_hull.roughness = 0.54

	var mat_trim := StandardMaterial3D.new()
	mat_trim.albedo_color = Color(0.43, 0.46, 0.50) # Mid Steel Grey trim / fenders / mantlet
	mat_trim.metallic = 0.38
	mat_trim.roughness = 0.50

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.17, 0.18, 0.20) # Dark gunmetal steel
	mat_steel.metallic = 0.82
	mat_steel.roughness = 0.38

	var mat_track := StandardMaterial3D.new()
	mat_track.albedo_color = Color(0.14, 0.14, 0.15)
	mat_track.metallic = 0.72
	mat_track.roughness = 0.62

	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.07, 0.07, 0.08)
	mat_rubber.roughness = 0.90

	var mat_grille := StandardMaterial3D.new()
	mat_grille.albedo_color = Color(0.05, 0.05, 0.06)
	mat_grille.metallic = 0.75
	mat_grille.roughness = 0.46

	var mat_interior := StandardMaterial3D.new()
	mat_interior.albedo_color = Color(0.055, 0.06, 0.07) # Dark steel crew compartment interior
	mat_interior.roughness = 0.92

	var mat_fuel := StandardMaterial3D.new()
	mat_fuel.albedo_color = Color(0.40, 0.43, 0.46) # Grey armored fuel drum
	mat_fuel.metallic = 0.55
	mat_fuel.roughness = 0.42

	var mat_fuel_stripe := StandardMaterial3D.new()
	mat_fuel_stripe.albedo_color = Color(0.80, 0.16, 0.12) # Red fuel hazard stripe
	mat_fuel_stripe.roughness = 0.45

	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.03, 0.04, 0.05)
	mat_visor.roughness = 0.18

	var mat_port_glass := StandardMaterial3D.new()
	mat_port_glass.albedo_color = Color(0.62, 0.88, 0.90, 0.26)
	mat_port_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_port_glass.metallic = 0.24
	mat_port_glass.roughness = 0.06

	var mat_gunner_glass := StandardMaterial3D.new()
	mat_gunner_glass.albedo_color = Color(0.32, 0.76, 0.62, 0.30)
	mat_gunner_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_gunner_glass.metallic = 0.32
	mat_gunner_glass.roughness = 0.06

	var mat_bulb := StandardMaterial3D.new()
	mat_bulb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_bulb.albedo_color = Color(1.0, 0.95, 0.74)

	# ==========================================
	# 1. ULTRA-DETAILED 8-AXLE INTERLEAVED RUNNING GEAR (SCHACHTELLAUFWERK)
	# ==========================================
	var gear_root := Node3D.new()
	gear_root.name = "RunningGear"
	add_child(gear_root)

	for side_idx in range(2):
		var sx: float = -1.72 if side_idx == 0 else 1.72
		var out_sign: float = -1.0 if side_idx == 0 else 1.0
		var wheels_arr: Array[Node3D] = left_wheels if side_idx == 0 else right_wheels
		var pads_arr: Array[Node3D] = left_track_pads if side_idx == 0 else right_track_pads

		# 8 Interleaved Torsion-Bar Road Wheels per side (authentic overlapping Tiger I arrangement!)
		for wi in range(8):
			var wz: float = -2.45 + float(wi) * 0.70
			var is_outer: bool = (wi % 2 == 0)
			var wx: float = sx + (0.14 if is_outer else -0.10) * out_sign

			# Visible torsion-bar swing arm connecting lower hull to wheel axle
			_add_box(gear_root, "SwingArm_%d_%d" % [side_idx, wi], Vector3(0.30, 0.11, 0.24), Vector3(sx - out_sign * 0.28, 0.56, wz + 0.14), mat_steel, Vector3(-22.0, 0, 0))
			_add_cyl(gear_root, "TorsionHub_%d_%d" % [side_idx, wi], 0.09, 0.09, 0.18, Vector3(sx - out_sign * 0.42, 0.62, wz + 0.26), mat_trim, 8, Vector3(0, 0, 90))

			var w_pivot := Node3D.new()
			w_pivot.position = Vector3(wx, 0.47, wz)
			gear_root.add_child(w_pivot)
			# Thick rubber rim + recessed light-grey dish wheel + inner steel ring + bolt hubcap + spokes!
			_add_cyl(w_pivot, "Tire", 0.45, 0.45, 0.20, Vector3.ZERO, mat_rubber, 16, Vector3(0, 0, 90))
			_add_cyl(w_pivot, "DishRim", 0.37, 0.37, 0.22, Vector3.ZERO, mat_hull, 14, Vector3(0, 0, 90))
			_add_cyl(w_pivot, "InnerDish", 0.29, 0.29, 0.235, Vector3.ZERO, mat_trim, 12, Vector3(0, 0, 90))
			_add_cyl(w_pivot, "HubCap", 0.115, 0.115, 0.28, Vector3.ZERO, mat_steel, 10, Vector3(0, 0, 90))
			# 4 distinct radial steel ribs / bolt bosses so wheel spin is razor-sharp!
			_add_box(w_pivot, "Rib1", Vector3(0.25, 0.68, 0.045), Vector3.ZERO, mat_steel)
			_add_box(w_pivot, "Rib2", Vector3(0.25, 0.045, 0.68), Vector3.ZERO, mat_steel)
			wheels_arr.append(w_pivot)

		# Detailed Front Toothed Drive Sprocket (-Z) with dual gear-tooth rings!
		var f_sp := Node3D.new()
		f_sp.position = Vector3(sx, 0.60, -3.14)
		gear_root.add_child(f_sp)
		_add_cyl(f_sp, "DriveDrum", 0.38, 0.38, 0.58, Vector3.ZERO, mat_trim, 14, Vector3(0, 0, 90))
		_add_cyl(f_sp, "DriveHub", 0.16, 0.16, 0.66, Vector3.ZERO, mat_steel, 10, Vector3(0, 0, 90))
		for ti in range(4):
			var rot_d: float = float(ti) * 45.0
			_add_box(f_sp, "GearTooth_%d" % ti, Vector3(0.62, 0.90, 0.065), Vector3.ZERO, mat_track, Vector3(rot_d, 0, 0))
		wheels_arr.append(f_sp)

		# Detailed Rear Slatted Idler Wheel (+Z)
		var r_id := Node3D.new()
		r_id.position = Vector3(sx, 0.58, 3.12)
		gear_root.add_child(r_id)
		_add_cyl(r_id, "IdlerWheel", 0.40, 0.40, 0.52, Vector3.ZERO, mat_hull, 14, Vector3(0, 0, 90))
		_add_cyl(r_id, "IdlerRim", 0.33, 0.33, 0.55, Vector3.ZERO, mat_trim, 12, Vector3(0, 0, 90))
		_add_box(r_id, "IdlerSpoke1", Vector3(0.57, 0.72, 0.06), Vector3.ZERO, mat_steel)
		_add_box(r_id, "IdlerSpoke2", Vector3(0.57, 0.06, 0.72), Vector3.ZERO, mat_steel)
		wheels_arr.append(r_id)

		# Continuous dark track belt backing
		_add_box(gear_root, "TrackBeltTop", Vector3(0.72, 0.05, 6.26), Vector3(sx, 1.04, 0.0), mat_track)
		_add_box(gear_root, "TrackBeltBot", Vector3(0.72, 0.05, 6.20), Vector3(sx, 0.045, 0.0), mat_track)

		# 34 Articulated Steel Track Links with Grouser Bars & Dual Center Guide Horns!
		for pi in range(34):
			var pad := Node3D.new()
			pad.position = Vector3(sx, 0.045, 0.0)
			gear_root.add_child(pad)
			_add_box(pad, "ShoePlate", Vector3(0.78, 0.055, 0.25), Vector3.ZERO, mat_track)
			_add_box(pad, "GrouserBar", Vector3(0.76, 0.028, 0.06), Vector3(0, -0.032, 0.0), mat_steel)
			# Iconic Tiger I twin inner guide horns
			_add_box(pad, "GuideHornL", Vector3(0.05, 0.07, 0.14), Vector3(-0.11, 0.05, 0.0), mat_steel)
			_add_box(pad, "GuideHornR", Vector3(0.05, 0.07, 0.14), Vector3(0.11, 0.05, 0.0), mat_steel)
			pads_arr.append(pad)

	_position_track_pads(left_track_pads, 0.0)
	_position_track_pads(right_track_pads, 0.0)

	# ==========================================
	# 2. SUSPENSION PIVOT & HOLLOW LIGHT-GREY TIGER I HULL (7.2m x 4.16m)
	# ==========================================
	suspension_pivot = Node3D.new()
	suspension_pivot.name = "SuspensionPivot"
	suspension_pivot.position = Vector3(0, 1.04, 0)
	add_child(suspension_pivot)

	# Local Y = 0.0 corresponds to 1.04m above ground; hull deck roof at local Y = +1.00 (2.04m above ground)
	# Lower armored tub (between tracks, x = -1.30..+1.30, z = -3.55..+3.55)
	_add_box(suspension_pivot, "LowerTub", Vector3(2.60, 0.68, 7.05), Vector3(0, -0.14, 0.0), mat_hull)
	# Rear & mid solid upper hull superstructure (z = -1.55 to +3.55, keeping z = -3.55..-1.55 HOLLOW for full-size crew!)
	_add_box(suspension_pivot, "MidRearUpperHull", Vector3(3.76, 0.80, 5.10), Vector3(0, 0.60, 1.00), mat_hull)

	# --- HOLLOW FRONT CREW FIGHTING COMPARTMENT (z = -3.55 to -1.55) ---
	# Roof armor plate over driver & radio operator
	_add_box(suspension_pivot, "FrontRoofPlate", Vector3(3.76, 0.10, 2.04), Vector3(0, 0.95, -2.55), mat_hull)
	# Outer left & right hull walls of front fighting compartment
	_add_box(suspension_pivot, "FrontWallL", Vector3(0.28, 0.72, 2.02), Vector3(-1.74, 0.56, -2.55), mat_hull)
	_add_box(suspension_pivot, "FrontWallR", Vector3(0.28, 0.72, 2.02), Vector3(1.74, 0.56, -2.55), mat_hull)
	# Interior dark bulkhead dividing Driver (left) & Radio Operator (right) + interior back wall
	_add_box(suspension_pivot, "CabDivider", Vector3(0.14, 0.70, 1.90), Vector3(0.0, 0.56, -2.55), mat_interior)
	_add_box(suspension_pivot, "CabBackWall", Vector3(3.40, 0.72, 0.10), Vector3(0.0, 0.56, -1.60), mat_interior)
	_add_box(suspension_pivot, "CabFloor", Vector3(3.40, 0.08, 1.98), Vector3(0.0, 0.18, -2.55), mat_interior)

	# Sloped Lower Front Glacis (below viewports) + iconic spare track links + tow shackles!
	_add_box(suspension_pivot, "LowerGlacisSlope", Vector3(2.80, 0.56, 0.24), Vector3(0, 0.02, -3.52), mat_hull, Vector3(24.0, 0, 0))
	_add_box(suspension_pivot, "FrontBowPlateLow", Vector3(3.76, 0.34, 0.16), Vector3(0, 0.33, -3.52), mat_hull)
	for ti in range(6):
		_add_box(suspension_pivot, "SpareTrack_%d" % ti, Vector3(0.38, 0.14, 0.08), Vector3(-1.12 + float(ti) * 0.45, -0.02, -3.65), mat_track)
	for sh_x in [-1.15, 1.15]:
		_add_box(suspension_pivot, "TowShackleF", Vector3(0.12, 0.22, 0.26), Vector3(sh_x, -0.08, -3.66), mat_steel)

	# Upper Front Glacis Pillars framing TWO REAL OPEN VIEWPORTS (Left: Driver, Right: Radio Operator)
	# Center pillar between windows (x = -0.52..+0.52), Left corner pillar (x = -1.88..-1.16), Right corner pillar (x = +1.16..+1.88), Top brow
	_add_box(suspension_pivot, "GlacisCenterPillar", Vector3(1.04, 0.46, 0.16), Vector3(0.0, 0.70, -3.52), mat_hull)
	_add_box(suspension_pivot, "GlacisOuterPillarL", Vector3(0.72, 0.46, 0.16), Vector3(-1.52, 0.70, -3.52), mat_hull)
	_add_box(suspension_pivot, "GlacisOuterPillarR", Vector3(0.72, 0.46, 0.16), Vector3(1.52, 0.70, -3.52), mat_hull)
	_add_box(suspension_pivot, "GlacisTopBrow", Vector3(3.76, 0.16, 0.18), Vector3(0.0, 0.90, -3.52), mat_hull)

	# Hull Armor Hitboxes (strictly behind the exact driver/radio glass hitboxes!)
	_add_hitbox(suspension_pivot, "hull_front", Vector3(3.85, 1.45, 0.65), Vector3(0, 0.40, -3.18))
	_add_hitbox(suspension_pivot, "hull_left", Vector3(0.55, 1.45, 5.95), Vector3(-1.76, 0.40, 0.05))
	_add_hitbox(suspension_pivot, "hull_right", Vector3(0.55, 1.45, 5.95), Vector3(1.76, 0.40, 0.05))
	_add_hitbox(suspension_pivot, "hull_rear", Vector3(3.85, 1.45, 0.65), Vector3(0, 0.40, 3.24))

	# ==========================================
	# 3. FULL-SIZE GREEN DRIVER & BLUE RADIO OPERATOR INSIDE HOLLOW CABINS
	#    BEHIND SEMI-TRANSPARENT ARMORED OPTIC GLASS!
	# ==========================================
	# --- LEFT FRONT: GREEN DRIVER (FULL-SIZE 1.0x!) ---
	var drv_win := Vector3(-0.84, 0.66, -3.56)
	# Heavy bolted armored optic bezel framing the 0.56m x 0.30m viewport
	_add_box(suspension_pivot, "DriverFrameTop", Vector3(0.66, 0.06, 0.20), drv_win + Vector3(0, 0.16, 0.04), mat_steel)
	_add_box(suspension_pivot, "DriverFrameBot", Vector3(0.66, 0.06, 0.20), drv_win + Vector3(0, -0.16, 0.04), mat_steel)
	_add_box(suspension_pivot, "DriverFrameL", Vector3(0.06, 0.34, 0.20), drv_win + Vector3(-0.31, 0, 0.04), mat_steel)
	_add_box(suspension_pivot, "DriverFrameR", Vector3(0.06, 0.34, 0.20), drv_win + Vector3(0.31, 0, 0.04), mat_steel)
	# Full-size Green Driver Crewmate sitting INSIDE the hollow hull right behind the glass!
	var driver_crew := _build_fullsize_crewmate(Color(0.18, 0.82, 0.26), false)
	driver_crew.name = "CrewModel_Driver"
	driver_crew.position = Vector3(-0.84, 0.22, -2.92)
	suspension_pivot.add_child(driver_crew)
	crew_models["driver"] = driver_crew
	# Semi-transparent armored optic glass + EXACT glass-only hitbox!
	driver_glass_mesh = _add_box(suspension_pivot, "DriverOpticGlass", Vector3(0.56, 0.28, 0.025), drv_win + Vector3(0, 0, -0.02), mat_port_glass)
	_add_hitbox(suspension_pivot, "crew_driver", Vector3(0.56, 0.28, 0.06), drv_win + Vector3(0, 0, -0.03))

	# --- RIGHT FRONT: BLUE RADIO OPERATOR (FULL-SIZE 1.0x!) + HULL MG-34 ---
	var rad_win := Vector3(0.84, 0.66, -3.56)
	_add_box(suspension_pivot, "RadioFrameTop", Vector3(0.66, 0.06, 0.20), rad_win + Vector3(0, 0.16, 0.04), mat_steel)
	_add_box(suspension_pivot, "RadioFrameBot", Vector3(0.66, 0.06, 0.20), rad_win + Vector3(0, -0.16, 0.04), mat_steel)
	_add_box(suspension_pivot, "RadioFrameL", Vector3(0.06, 0.34, 0.20), rad_win + Vector3(-0.31, 0, 0.04), mat_steel)
	_add_box(suspension_pivot, "RadioFrameR", Vector3(0.06, 0.34, 0.20), rad_win + Vector3(0.31, 0, 0.04), mat_steel)
	# Full-size Blue Radio Operator Crewmate sitting INSIDE the hollow hull right behind the glass!
	var radio_crew := _build_fullsize_crewmate(Color(0.20, 0.46, 0.96), false)
	radio_crew.name = "CrewModel_Radio"
	radio_crew.position = Vector3(0.84, 0.22, -2.92)
	suspension_pivot.add_child(radio_crew)
	crew_models["radio"] = radio_crew
	radio_glass_mesh = _add_box(suspension_pivot, "RadioOpticGlass", Vector3(0.56, 0.28, 0.025), rad_win + Vector3(0, 0, -0.02), mat_port_glass)
	_add_hitbox(suspension_pivot, "crew_radio", Vector3(0.56, 0.28, 0.06), rad_win + Vector3(0, 0, -0.03))

	# Kugelblende Hull MG-34 ball mount neatly below Radio Operator's optic window
	_add_cyl(suspension_pivot, "HullMGBall", 0.15, 0.17, 0.16, Vector3(0.84, 0.34, -3.58), mat_steel, 12, Vector3(-90, 0, 0))
	_add_cyl(suspension_pivot, "HullMGBarrel", 0.028, 0.032, 0.62, Vector3(0.84, 0.34, -3.90), mat_steel, 8, Vector3(-90, 0, 0))
	hull_mg_muzzle = Marker3D.new()
	hull_mg_muzzle.position = Vector3(0.84, 0.34, -4.26)
	suspension_pivot.add_child(hull_mg_muzzle)

	# ==========================================
	# 4. DETACHABLE FRONT BOSCH HEADLIGHTS (FLY OFF WHEN SHOT OR WHEN TANK EXPLODES!)
	# ==========================================
	for hl_id in ["headlight_l", "headlight_r"]:
		var hx: float = -1.36 if hl_id == "headlight_l" else 1.36
		var hl_node := Node3D.new()
		hl_node.name = "Headlight_" + hl_id
		hl_node.position = Vector3(hx, 1.12, -3.28)
		suspension_pivot.add_child(hl_node)
		# Mounting stalk, armored cylindrical housing, blackout hood & bright reflector bulb
		_add_cyl(hl_node, "Stalk", 0.035, 0.045, 0.16, Vector3(0, -0.10, 0.0), mat_steel, 8)
		_add_cyl(hl_node, "Housing", 0.14, 0.11, 0.24, Vector3.ZERO, mat_trim, 12, Vector3(-90, 0, 0))
		_add_box(hl_node, "BlackoutHood", Vector3(0.28, 0.05, 0.14), Vector3(0, 0.11, -0.10), mat_steel)
		var bulb := _add_cyl(hl_node, "Bulb", 0.115, 0.115, 0.03, Vector3(0, 0, -0.125), mat_bulb, 12, Vector3(-90, 0, 0))
		headlight_bulbs[hl_id] = bulb
		var spot := SpotLight3D.new()
		spot.spot_range = 34.0
		spot.spot_angle = 44.0
		spot.light_color = Color(1.0, 0.94, 0.74)
		spot.light_energy = 4.4
		spot.position = Vector3(0, 0, -0.16)
		hl_node.add_child(spot)
		headlight_lights[hl_id] = spot
		headlight_nodes[hl_id] = hl_node
		_add_hitbox(hl_node, hl_id, Vector3(0.36, 0.36, 0.38), Vector3.ZERO)

	# ==========================================
	# 5. AUTHENTIC TIGER I TRACK ARCHES / SEGMENTED FENDERS (KETTENABDECKUNG)
	#    (6 distinct hinged arch sections per side = 12 total; several blow off forever on explosion!)
	# ==========================================
	detachable_arches.clear()
	for side_idx in range(2):
		var out_sign: float = -1.0 if side_idx == 0 else 1.0
		var arch_x: float = out_sign * 1.78
		var lip_x: float = out_sign * 0.38

		# A. Front angled hinged mudflap arch
		var f_arch := Node3D.new()
		f_arch.name = "FrontTrackArch_%d" % side_idx
		f_arch.position = Vector3(arch_x, 0.14, -3.54)
		suspension_pivot.add_child(f_arch)
		_add_box(f_arch, "ArchTop", Vector3(0.84, 0.06, 0.62), Vector3(0, 0.08, 0.0), mat_trim, Vector3(28.0, 0, 0))
		_add_box(f_arch, "ArchFrontFlap", Vector3(0.82, 0.30, 0.055), Vector3(0, -0.14, -0.26), mat_trim, Vector3(14.0, 0, 0))
		_add_box(f_arch, "ArchSideRim", Vector3(0.055, 0.24, 0.56), Vector3(lip_x, -0.04, 0.0), mat_hull)
		detachable_arches.append(f_arch)

		# B. 4 Individual Hinged Armored Side Track Arches (covering top & outer edge of Tiger tracks!)
		for seg in range(4):
			var seg_z: float = -2.35 + float(seg) * 1.56
			var s_arch := Node3D.new()
			s_arch.name = "SideTrackArch_%d_%d" % [side_idx, seg]
			s_arch.position = Vector3(arch_x, 0.22, seg_z)
			suspension_pivot.add_child(s_arch)
			# Horizontal mudguard roof over track + beveled outer armored skirt lip + hinge brackets
			_add_box(s_arch, "FenderRoof", Vector3(0.84, 0.055, 1.48), Vector3(0, 0.08, 0.0), mat_trim)
			_add_box(s_arch, "SkirtLip", Vector3(0.06, 0.32, 1.46), Vector3(lip_x, -0.08, 0.0), mat_hull, Vector3(0, 0, -out_sign * 12.0))
			_add_box(s_arch, "HingeF", Vector3(0.18, 0.08, 0.10), Vector3(-out_sign * 0.34, 0.10, -0.52), mat_steel)
			_add_box(s_arch, "HingeR", Vector3(0.18, 0.08, 0.10), Vector3(-out_sign * 0.34, 0.10, 0.52), mat_steel)
			detachable_arches.append(s_arch)

		# C. Rear angled mudflap arch
		var r_arch := Node3D.new()
		r_arch.name = "RearTrackArch_%d" % side_idx
		r_arch.position = Vector3(arch_x, 0.14, 3.52)
		suspension_pivot.add_child(r_arch)
		_add_box(r_arch, "ArchTop", Vector3(0.84, 0.06, 0.56), Vector3(0, 0.08, 0.0), mat_trim, Vector3(-24.0, 0, 0))
		_add_box(r_arch, "ArchRearFlap", Vector3(0.82, 0.28, 0.055), Vector3(0, -0.14, 0.24), mat_trim, Vector3(-14.0, 0, 0))
		_add_box(r_arch, "ArchSideRim", Vector3(0.055, 0.22, 0.52), Vector3(lip_x, -0.04, 0.0), mat_hull)
		detachable_arches.append(r_arch)

	# ==========================================
	# 6. 4 ATTACHED EXTERNAL SIDE FUEL TANKS — CLOSER TOGETHER & NEAR REAR ENGINE BAY!
	# ==========================================
	var fuel_defs := [
		["fuel_l1", Vector3(-2.06, 0.64, 1.12)],
		["fuel_l2", Vector3(-2.06, 0.64, 2.30)],
		["fuel_r1", Vector3(2.06, 0.64, 1.12)],
		["fuel_r2", Vector3(2.06, 0.64, 2.30)],
	]
	for fd in fuel_defs:
		var fid: String = fd[0]
		var fpos: Vector3 = fd[1]
		var side_s: float = -1.0 if fpos.x < 0.0 else 1.0
		var f_node := Node3D.new()
		f_node.name = "FuelTank_" + fid
		f_node.position = fpos
		suspension_pivot.add_child(f_node)
		# Compact heavy armored fuel drum with rounded end caps, red hazard stripe, mounting cradles & feed pipe
		_add_cyl(f_node, "Drum", 0.23, 0.23, 1.04, Vector3.ZERO, mat_fuel, 16, Vector3(-90, 0, 0))
		_add_cyl(f_node, "HazardStripe", 0.236, 0.236, 0.20, Vector3.ZERO, mat_fuel_stripe, 16, Vector3(-90, 0, 0))
		for strap_z in [-0.34, 0.34]:
			_add_cyl(f_node, "Strap", 0.244, 0.244, 0.055, Vector3(0, 0, strap_z), mat_steel, 12, Vector3(-90, 0, 0))
			_add_box(f_node, "MountCradle", Vector3(0.22, 0.10, 0.12), Vector3(-side_s * 0.16, -0.14, strap_z), mat_steel)
		# Fuel feed line running up into engine deck
		_add_cyl(f_node, "FuelLine", 0.032, 0.032, 0.36, Vector3(-side_s * 0.14, 0.24, 0.0), mat_steel, 8, Vector3(0, 0, side_s * 38.0))
		fuel_meshes[fid] = f_node
		_add_hitbox(suspension_pivot, fid, Vector3(0.54, 0.56, 1.10), fpos)

	# ==========================================
	# 7. REAR ENGINE DECK, FEIFEL AIR FILTERS, EXHAUSTS & 2 COOLING GRILLES
	# ==========================================
	for ex_x in [-0.52, 0.52]:
		# Armored twin Tiger I vertical exhaust pipes + perforated heat shrouds
		_add_cyl(suspension_pivot, "ExhaustPipe", 0.13, 0.13, 1.06, Vector3(ex_x, 0.54, 3.62), mat_steel, 12)
		_add_box(suspension_pivot, "ExhaustShroud", Vector3(0.36, 0.98, 0.24), Vector3(ex_x, 0.54, 3.68), mat_trim)
		# Iconic Feifel cylindrical dust filter canisters on upper rear bulkhead
		_add_cyl(suspension_pivot, "FeifelFilter", 0.16, 0.16, 0.52, Vector3(ex_x * 2.15, 0.88, 3.50), mat_trim, 12)

	# Armored rear mudguard tow clevises & jack block
	_add_box(suspension_pivot, "RearJack", Vector3(0.24, 0.56, 0.18), Vector3(0.0, 0.42, 3.66), mat_steel)

	for gid in ["grille_l", "grille_r"]:
		var gx: float = -1.16 if gid == "grille_l" else 1.16
		_add_box(suspension_pivot, gid + "_TopFrame", Vector3(0.96, 0.08, 1.48), Vector3(gx, 1.01, 2.48), mat_steel)
		_add_box(suspension_pivot, gid + "_TopMesh", Vector3(0.84, 0.10, 1.36), Vector3(gx, 1.02, 2.48), mat_grille)
		for ts in range(6):
			_add_box(suspension_pivot, gid + "_TopSlat", Vector3(0.86, 0.04, 0.045), Vector3(gx, 1.06, 1.88 + float(ts) * 0.23), mat_steel)
		_add_box(suspension_pivot, gid + "_RearFrame", Vector3(0.92, 0.58, 0.14), Vector3(gx, 0.58, 3.55), mat_steel)
		_add_box(suspension_pivot, gid + "_RearLouvers", Vector3(0.80, 0.46, 0.18), Vector3(gx, 0.58, 3.57), mat_grille)
		for si in range(4):
			_add_box(suspension_pivot, gid + "_Slat", Vector3(0.82, 0.04, 0.20), Vector3(gx, 0.42 + float(si) * 0.11, 3.58), mat_steel)
		_add_hitbox(suspension_pivot, gid, Vector3(1.04, 0.82, 1.56), Vector3(gx, 0.72, 2.86))

		var g_smoke := _create_smoke_emitter(Color(0.16, 0.16, 0.18, 0.85), 24, 1.4)
		g_smoke.position = Vector3(gx, 1.12, 2.55)
		suspension_pivot.add_child(g_smoke)
		grille_smoke[gid] = g_smoke

	engine_smoke_fx = _create_smoke_emitter(Color(0.08, 0.08, 0.09, 0.92), 44, 2.3)
	engine_smoke_fx.position = Vector3(0, 1.16, 2.52)
	suspension_pivot.add_child(engine_smoke_fx)

	engine_fire_fx = _create_fire_emitter()
	engine_fire_fx.position = Vector3(0, 1.12, 2.52)
	suspension_pivot.add_child(engine_fire_fx)

	engine_fire_light = OmniLight3D.new()
	engine_fire_light.light_color = Color(1.0, 0.46, 0.12)
	engine_fire_light.light_energy = 4.5
	engine_fire_light.omni_range = 17.0
	engine_fire_light.position = Vector3(0, 1.88, 2.52)
	engine_fire_light.visible = false
	suspension_pivot.add_child(engine_fire_light)

	# ==========================================
	# 8. HOLLOW LIGHT-GREY HORSESHOE TURRET + ELEVATING 88mm KwK 36 CANNON
	#    + FULL-SIZE YELLOW GUNNER BEHIND IMPENETRABLE OPTIC GLASS
	#    + FULL-SIZE RED COMMANDER IN OFFICER PEAKED CAP (ФУРАЖКА)
	# ==========================================
	turret_pivot = Node3D.new()
	turret_pivot.name = "TurretPivot"
	turret_pivot.position = Vector3(0, 1.00, -0.22)
	suspension_pivot.add_child(turret_pivot)

	# Turret ring collar
	_add_cyl(turret_pivot, "TurretRing", 1.38, 1.42, 0.12, Vector3(0, 0.05, 0.0), mat_steel, 18)

	# HOLLOW HORSESHOE TURRET STRUCTURE (leaving front-left interior cavity open behind Gunner Optics!)
	# Rear curved armored bustle + Rommelkiste stowage bin
	_add_box(turret_pivot, "TurretRearWall", Vector3(2.44, 0.96, 0.92), Vector3(0, 0.56, 1.02), mat_hull)
	_add_cyl(turret_pivot, "TurretBustleCurve", 1.32, 1.35, 0.96, Vector3(0, 0.56, 0.64), mat_hull, 16)
	_add_box(turret_pivot, "Rommelkiste", Vector3(1.62, 0.56, 0.58), Vector3(0, 0.58, 1.88), mat_trim)
	# Side curved/angled turret cheek walls + smoke discharger racks + spare track armor racks!
	_add_box(turret_pivot, "TurretSideL", Vector3(0.32, 0.96, 2.25), Vector3(-1.26, 0.56, -0.25), mat_hull)
	_add_box(turret_pivot, "TurretSideR", Vector3(0.32, 0.96, 2.25), Vector3(1.26, 0.56, -0.25), mat_hull)
	for sd_side in [-1.0, 1.0]:
		# Triple Nebelwerfer smoke grenade discharger tubes on turret front cheeks!
		for si in range(3):
			_add_cyl(turret_pivot, "SmokeTube", 0.045, 0.045, 0.30, Vector3(sd_side * 1.48, 0.88 - float(si) * 0.07, -1.16 - float(si) * 0.04), mat_steel, 8, Vector3(-55.0, sd_side * 14.0, 0))
		# Spare turret-side track links (iconic Tiger I Ausf. E detail!)
		for tk in range(3):
			_add_box(turret_pivot, "TurretSpareTrack", Vector3(0.08, 0.44, 0.24), Vector3(sd_side * 1.46, 0.56, -0.45 + float(tk) * 0.34), mat_track)

	# Turret Roof & Floor plates + dark hollow gunner cavity
	_add_box(turret_pivot, "TurretRoof", Vector3(2.68, 0.12, 2.40), Vector3(0, 1.04, -0.18), mat_hull)
	_add_box(turret_pivot, "TurretFloor", Vector3(2.30, 0.08, 2.10), Vector3(0, 0.10, -0.22), mat_interior)
	_add_box(turret_pivot, "TurretGunnerBack", Vector3(0.90, 0.84, 0.10), Vector3(-0.68, 0.56, -0.25), mat_interior)
	# Right-front turret face (next to mantlet) & left-front framing pillars around Gunner Optic Window!
	_add_box(turret_pivot, "TurretFrontRight", Vector3(1.38, 0.92, 0.24), Vector3(0.68, 0.56, -1.36), mat_hull)
	_add_box(turret_pivot, "TurretFrontLowL", Vector3(1.22, 0.36, 0.24), Vector3(-0.74, 0.28, -1.36), mat_hull)
	_add_box(turret_pivot, "TurretFrontTopL", Vector3(1.22, 0.24, 0.24), Vector3(-0.74, 0.92, -1.36), mat_hull)
	_add_box(turret_pivot, "TurretFrontOuterL", Vector3(0.42, 0.44, 0.24), Vector3(-1.14, 0.62, -1.36), mat_hull)

	# Turret armor hitbox (immune to RPG hull kill!)
	_add_hitbox(turret_pivot, "turret_armor", Vector3(2.85, 1.00, 3.05), Vector3(0, 0.56, 0.08))

	# --- FULL-SIZE YELLOW GUNNER SITTING INSIDE TURRET BEHIND IMPENETRABLE OPTIC GLASS! ---
	var opt_win := Vector3(-0.66, 0.62, -1.48)
	_add_box(turret_pivot, "OpticsFrameTop", Vector3(0.56, 0.055, 0.20), opt_win + Vector3(0, 0.16, 0.04), mat_steel)
	_add_box(turret_pivot, "OpticsFrameBot", Vector3(0.56, 0.055, 0.20), opt_win + Vector3(0, -0.16, 0.04), mat_steel)
	_add_box(turret_pivot, "OpticsFrameL", Vector3(0.055, 0.34, 0.20), opt_win + Vector3(-0.26, 0, 0.04), mat_steel)
	_add_box(turret_pivot, "OpticsFrameR", Vector3(0.055, 0.34, 0.20), opt_win + Vector3(0.26, 0, 0.04), mat_steel)
	# Full-size Yellow Gunner Crewmate sitting inside hollow turret looking straight out (UNKILLABLE!)
	var gunner_crew := _build_fullsize_crewmate(Color(0.96, 0.80, 0.14), false)
	gunner_crew.name = "CrewModel_Gunner"
	gunner_crew.position = Vector3(-0.66, 0.18, -0.88)
	turret_pivot.add_child(gunner_crew)
	crew_models["gunner"] = gunner_crew
	optics_glass_mesh = _add_box(turret_pivot, "OpticsGlass", Vector3(0.48, 0.28, 0.03), opt_win + Vector3(0, 0, -0.02), mat_gunner_glass)
	_add_hitbox(turret_pivot, "mod_optics", Vector3(0.52, 0.30, 0.14), opt_win + Vector3(0, 0, -0.04))

	# --- ELEVATING & DEPRESSING 88mm KwK 36 MAIN CANNON + MANTLET + COAXIAL MG-34 ---
	gun_elevation_pivot = Node3D.new()
	gun_elevation_pivot.name = "GunElevationPivot"
	gun_elevation_pivot.position = Vector3(0.18, 0.56, -1.42)
	turret_pivot.add_child(gun_elevation_pivot)

	# Heavy curved armored gun mantlet moving with elevation!
	_add_box(gun_elevation_pivot, "GunMantlet", Vector3(1.12, 0.64, 0.36), Vector3(0, 0, -0.08), mat_trim)
	_add_cyl(gun_elevation_pivot, "MantletCyl", 0.26, 0.26, 1.08, Vector3(0, 0, -0.18), mat_trim, 12, Vector3(0, 0, 90))

	# Recoiling 88mm KwK 36 L/56 Cannon Barrel + Iconic Slotted Double-Baffle Muzzle Brake
	cannon_recoil_node = Node3D.new()
	cannon_recoil_node.name = "CannonRecoil"
	gun_elevation_pivot.add_child(cannon_recoil_node)

	_add_cyl(cannon_recoil_node, "RecuperatorSleeve", 0.20, 0.23, 1.25, Vector3(0, 0, -0.78), mat_trim, 14, Vector3(-90, 0, 0))
	_add_cyl(cannon_recoil_node, "BarrelRear", 0.13, 0.165, 2.05, Vector3(0, 0, -2.25), mat_hull, 16, Vector3(-90, 0, 0))
	_add_cyl(cannon_recoil_node, "BarrelFront", 0.098, 0.125, 1.95, Vector3(0, 0, -4.05), mat_hull, 16, Vector3(-90, 0, 0))
	_add_cyl(cannon_recoil_node, "MuzzleCollar", 0.125, 0.125, 0.18, Vector3(0, 0, -5.02), mat_steel, 12, Vector3(-90, 0, 0))
	_add_cyl(cannon_recoil_node, "MuzzleBrake", 0.185, 0.175, 0.52, Vector3(0, 0, -5.32), mat_steel, 14, Vector3(-90, 0, 0))
	_add_box(cannon_recoil_node, "BrakeBaffle1", Vector3(0.40, 0.13, 0.12), Vector3(0, 0, -5.22), mat_grille)
	_add_box(cannon_recoil_node, "BrakeBaffle2", Vector3(0.40, 0.13, 0.12), Vector3(0, 0, -5.42), mat_grille)

	cannon_muzzle = Marker3D.new()
	cannon_muzzle.position = Vector3(0, 0, -5.66)
	cannon_recoil_node.add_child(cannon_muzzle)

	# Coaxial Turret MG-34 (mounted clearly forward on right of mantlet so barrel & muzzle never clip turret/hull!)
	coax_mg_visual = Node3D.new()
	coax_mg_visual.position = Vector3(0.42, 0.04, -0.30)
	gun_elevation_pivot.add_child(coax_mg_visual)
	_add_cyl(coax_mg_visual, "CoaxSleeve", 0.08, 0.09, 0.30, Vector3(0, 0, -0.06), mat_steel, 10, Vector3(-90, 0, 0))
	_add_cyl(coax_mg_visual, "CoaxBarrel", 0.032, 0.036, 0.82, Vector3(0, 0, -0.50), mat_steel, 8, Vector3(-90, 0, 0))
	coax_mg_muzzle = Marker3D.new()
	coax_mg_muzzle.position = Vector3(0.42, 0.04, -1.32)
	gun_elevation_pivot.add_child(coax_mg_muzzle)
	_add_hitbox(gun_elevation_pivot, "mod_coax_mg", Vector3(0.36, 0.36, 0.82), Vector3(0.42, 0.04, -0.62))

	# --- COMMANDER'S OPEN CUPOLA + FULL-SIZE RED COMMANDER IN OFFICER PEAKED CAP (ФУРАЖКА) ---
	var cup_pos := Vector3(-0.56, 1.24, 0.36)
	_add_cyl(turret_pivot, "CupolaBase", 0.52, 0.54, 0.38, cup_pos, mat_hull, 16)
	_add_cyl(turret_pivot, "CupolaVisionRing", 0.53, 0.53, 0.11, cup_pos + Vector3(0, 0.08, 0), mat_visor, 16)
	# Cupola itself is armored turret_armor -> ONLY shooting the Red Commander himself deals crew damage!
	_add_hitbox(turret_pivot, "turret_armor", Vector3(1.06, 0.38, 1.06), cup_pos)

	cupola_hatch = Node3D.new()
	cupola_hatch.position = cup_pos + Vector3(0, 0.20, 0.48)
	cupola_hatch.rotation.x = deg_to_rad(-104.0)
	turret_pivot.add_child(cupola_hatch)
	_add_cyl(cupola_hatch, "HatchLid", 0.49, 0.49, 0.08, Vector3(0, 0, -0.46), mat_trim, 14)

	# Full-size Red Commander sitting half-out of cupola with Officer Peaked Cap!
	var cmd_crew := _build_fullsize_crewmate(Color(0.90, 0.14, 0.14), true)
	cmd_crew.name = "CrewModel_Commander"
	cmd_crew.position = Vector3(-0.56, 1.18, 0.36)
	turret_pivot.add_child(cmd_crew)
	crew_models["commander"] = cmd_crew
	# Hitbox STRICTLY around Commander's exposed upper torso & cap (NOT cupola hatch!)
	_add_hitbox(turret_pivot, "crew_commander", Vector3(0.68, 0.80, 0.68), Vector3(-0.56, 1.72, 0.36))

	# --- PRESSURIZED AMMO-RACK COOK-OFF VERTICAL FLAME JET (ERUPTS 7-9m OUT OF COMMANDER'S HATCH!) ---
	var jet_origin: Vector3 = cup_pos + Vector3(0, 0.22, 0)
	ammo_jet_outer_fx = _create_pressurized_jet_emitter(Color(1.0, 0.44, 0.08, 0.94), 95, 0.56, 15.0, 21.0, 7.5, 0.85, 1.65)
	ammo_jet_outer_fx.position = jet_origin
	turret_pivot.add_child(ammo_jet_outer_fx)

	ammo_jet_core_fx = _create_pressurized_jet_emitter(Color(1.0, 0.96, 0.78, 0.98), 75, 0.36, 17.5, 24.0, 3.8, 0.48, 0.92)
	ammo_jet_core_fx.position = jet_origin
	turret_pivot.add_child(ammo_jet_core_fx)

	ammo_jet_sparks_fx = _create_pressurized_jet_emitter(Color(1.0, 0.84, 0.32, 1.0), 60, 0.95, 14.0, 23.0, 14.0, 0.14, 0.26)
	ammo_jet_sparks_fx.gravity = Vector3(0, -8.5, 0)
	ammo_jet_sparks_fx.position = jet_origin
	turret_pivot.add_child(ammo_jet_sparks_fx)

	ammo_jet_light = OmniLight3D.new()
	ammo_jet_light.light_color = Color(1.0, 0.62, 0.18)
	ammo_jet_light.light_energy = 8.5
	ammo_jet_light.omni_range = 24.0
	ammo_jet_light.position = jet_origin + Vector3(0, 3.2, 0)
	ammo_jet_light.visible = false
	turret_pivot.add_child(ammo_jet_light)

	# Smoldering smoke column rising out of blown-out turret ring after turret toss!
	hull_ring_smoke_fx = _create_smoke_emitter(Color(0.06, 0.06, 0.07, 0.94), 48, 2.6)
	hull_ring_smoke_fx.position = Vector3(0, 1.12, -0.22)
	suspension_pivot.add_child(hull_ring_smoke_fx)

	# --- COMMANDER'S PINTLE MG-34 (DETACHES FOREVER WHEN SHOT OR ON TANK EXPLOSION!) ---
	cmd_mg_node = Node3D.new()
	cmd_mg_node.name = "CommanderMG34"
	cmd_mg_node.position = Vector3(-0.06, 1.56, 0.08)
	turret_pivot.add_child(cmd_mg_node)
	_add_box(cmd_mg_node, "PintlePost", Vector3(0.06, 0.30, 0.06), Vector3(0, -0.12, 0.0), mat_steel)
	_add_box(cmd_mg_node, "MGReceiver", Vector3(0.12, 0.15, 0.60), Vector3(0, 0.06, -0.05), mat_steel)
	_add_cyl(cmd_mg_node, "MGBarrel", 0.034, 0.038, 0.74, Vector3(0, 0.08, -0.66), mat_steel, 8, Vector3(-90, 0, 0))
	_add_cyl(cmd_mg_node, "MGDrumMag", 0.12, 0.12, 0.11, Vector3(-0.11, 0.11, -0.08), mat_trim, 10, Vector3(0, 0, 90))
	_add_box(cmd_mg_node, "MGStock", Vector3(0.085, 0.12, 0.36), Vector3(0, 0.03, 0.40), mat_rubber)
	_add_hitbox(cmd_mg_node, "mod_cmd_mg", Vector3(0.46, 0.46, 1.24), Vector3(0, 0.06, -0.24))

func _add_hitbox(parent: Node3D, zone_id: String, sz: Vector3, pos: Vector3) -> StaticBody3D:
	if is_preview_only:
		return null
	var sb := StaticBody3D.new()
	sb.name = "HB_" + zone_id
	sb.position = pos
	sb.add_to_group("tiger_hitbox")
	sb.set_meta("hit_zone", zone_id)
	sb.set_meta("tiger_owner", self)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = sz
	col.shape = sh
	sb.add_child(col)
	parent.add_child(sb)
	all_hitboxes.append(sb)
	own_rids.append(sb.get_rid())
	return sb

func _create_smoke_emitter(col: Color, amt: int, life: float) -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = amt
	cp.lifetime = life
	cp.direction = Vector3(0, 1, 0)
	cp.spread = 22.0
	cp.gravity = Vector3(0, 1.4, 0)
	cp.initial_velocity_min = 1.6
	cp.initial_velocity_max = 3.4
	cp.scale_amount_min = 0.75
	cp.scale_amount_max = 2.4
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.0)
	qm.material = VFXFactoryScript.create_soft_smoke_material(col)
	cp.mesh = qm
	return cp

func _create_fire_emitter() -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = 38
	cp.lifetime = 0.78
	cp.direction = Vector3(0, 1, 0)
	cp.spread = 28.0
	cp.gravity = Vector3(0, 2.2, 0)
	cp.initial_velocity_min = 1.8
	cp.initial_velocity_max = 4.4
	cp.scale_amount_min = 0.65
	cp.scale_amount_max = 1.75
	var qm := QuadMesh.new()
	qm.size = Vector2(0.95, 0.95)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.albedo_color = Color(1.0, 0.52, 0.12, 0.90)
	qm.material = fmat
	cp.mesh = qm
	return cp

func _create_pressurized_jet_emitter(col: Color, amt: int, life: float, v_min: float, v_max: float, spr: float, s_min: float, s_max: float) -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = amt
	cp.lifetime = life
	cp.direction = Vector3(0, 1, 0)
	cp.spread = spr
	cp.gravity = Vector3(0, 2.5, 0)
	cp.initial_velocity_min = v_min
	cp.initial_velocity_max = v_max
	cp.scale_amount_min = s_min
	cp.scale_amount_max = s_max
	var qm := QuadMesh.new()
	qm.size = Vector2(0.85, 1.35)
	var jmat := StandardMaterial3D.new()
	jmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	jmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	jmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	jmat.albedo_color = col
	qm.material = jmat
	cp.mesh = qm
	return cp

static func _build_fullsize_crewmate(suit_color: Color, with_officer_cap: bool = false) -> Node3D:
	# Full-size (1.0x) Among Us crewmate model matching enemy proportions (radius 0.34, height 1.15)
	# Facing forward (-Z). Origin is at seated hip height; visor centered at y = +0.44!
	var root := Node3D.new()

	var mat_suit := StandardMaterial3D.new()
	mat_suit.albedo_color = suit_color
	mat_suit.roughness = 0.34
	mat_suit.metallic = 0.08

	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.56, 0.92, 1.0)
	mat_visor.emission_enabled = true
	mat_visor.emission = Color(0.24, 0.72, 0.85)
	mat_visor.emission_energy_multiplier = 0.55
	mat_visor.metallic = 0.45
	mat_visor.roughness = 0.08

	var mat_visor_rim := StandardMaterial3D.new()
	mat_visor_rim.albedo_color = Color(0.08, 0.10, 0.12)
	mat_visor_rim.roughness = 0.48

	# Full-size torso + head capsule
	var body := MeshInstance3D.new()
	body.name = "Body"
	var cap_m := CapsuleMesh.new()
	cap_m.radius = 0.33
	cap_m.height = 1.08
	cap_m.radial_segments = 16
	cap_m.rings = 4
	body.mesh = cap_m
	body.material_override = mat_suit
	body.position = Vector3(0, 0.24, 0)
	root.add_child(body)

	# Bright cyan visor facing forward (-Z) clearly visible through semi-transparent armored glass!
	_add_box(root, "VisorRim", Vector3(0.45, 0.23, 0.14), Vector3(0, 0.44, -0.26), mat_visor_rim)
	_add_box(root, "VisorGlass", Vector3(0.40, 0.18, 0.16), Vector3(0, 0.44, -0.28), mat_visor)

	# Full-size oxygen backpack behind (+Z)
	_add_box(root, "Backpack", Vector3(0.42, 0.56, 0.22), Vector3(0, 0.26, 0.28), mat_suit)

	if with_officer_cap:
		# Detailed Wehrmacht Panzer Officer Peaked Cap (Фуражка)
		var cap_root := Node3D.new()
		cap_root.name = "OfficerCap"
		cap_root.position = Vector3(0, 0.75, -0.01)
		cap_root.rotation.x = deg_to_rad(-8.0)
		root.add_child(cap_root)

		var mat_cap_dark := StandardMaterial3D.new()
		mat_cap_dark.albedo_color = Color(0.11, 0.12, 0.13)
		mat_cap_dark.roughness = 0.60

		var mat_cap_band := StandardMaterial3D.new()
		mat_cap_band.albedo_color = Color(0.80, 0.10, 0.12)
		mat_cap_band.roughness = 0.42

		var mat_cap_peak := StandardMaterial3D.new()
		mat_cap_peak.albedo_color = Color(0.03, 0.03, 0.04)
		mat_cap_peak.metallic = 0.28
		mat_cap_peak.roughness = 0.12

		var mat_cockade := StandardMaterial3D.new()
		mat_cockade.albedo_color = Color(0.96, 0.82, 0.28)
		mat_cockade.metallic = 0.90
		mat_cockade.roughness = 0.20

		_add_cyl(cap_root, "CapBand", 0.30, 0.30, 0.10, Vector3(0, 0.045, 0), mat_cap_dark, 16)
		_add_cyl(cap_root, "RedPiping", 0.308, 0.308, 0.028, Vector3(0, 0.088, 0), mat_cap_band, 16)
		_add_cyl(cap_root, "CapCrown", 0.39, 0.30, 0.14, Vector3(0, 0.16, 0.02), mat_cap_dark, 16)
		_add_cyl(cap_root, "TopPiping", 0.394, 0.394, 0.018, Vector3(0, 0.228, 0.02), mat_cap_band, 16)
		_add_box(cap_root, "CapVisor", Vector3(0.42, 0.026, 0.25), Vector3(0, 0.018, -0.30), mat_cap_peak, Vector3(14.0, 0, 0))
		_add_box(cap_root, "CapBadge", Vector3(0.09, 0.065, 0.025), Vector3(0, 0.145, -0.345), mat_cockade)

	return root

static func _add_box(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi
