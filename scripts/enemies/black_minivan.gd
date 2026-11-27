class_name BlackMinivan
extends Node3D

# Enemy Vehicle (Waves 3+): Black Tactical Assault Minivan
# - Hollow glossy black van with semi-transparent windows & animated sliding side door
# - Full-size Green Crewmate driver in a woven Straw Hat behind the steering wheel
# - 4 to 6 specific random standard enemies (Red/Blue/Yellow/Green — NO Tiger, NO Shahed) visibly seated inside
# - Behavior:
#   1) APPROACHING: Drives to medium distance without attacking
#   2) UNLOADING: Idles, slides side door open, deploys the exact 4-6 squad members inside, closes door
#   3) ORBITING: Circles around player at medium range, then at a random moment lines up and starts RAMMING
#   4) RAMMING: Plays 2 shop-style horns, revs engine, accelerates strictly straight WITHOUT turning;
#      colliding with ANY map object/wall after a hit or miss detonates with full RPG-7 blast damage!
#   5) RUNAWAY (front engine shot out): Front hood smokes heavily, van revs & accelerates strictly straight
#      until colliding with ANY object/wall -> detonates (killing any remaining passengers with full rewards!)
#   6) Instant destruction from an RPG-7 hit to ANY part of the hull (with full rewards for trapped passengers!)
# - Explosion: Vibrant RPG-like fireball + expanding semi-transparent shockwave sphere fading out
# - Wreck: Stays burning on the map for 120s (2 minutes), then smoothly sinks underground and deletes itself

signal died(points: int)

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")

enum VanState { APPROACHING, UNLOADING, ORBITING, RAMMING, RUNAWAY, DESTROYED }
var van_state: VanState = VanState.APPROACHING
var is_dead: bool = false
var is_preview_only: bool = false
var health: float = 150.0 # Kept > 0 while active so EnemySpawner / tools see it alive

# Rewards & Damage
const VAN_SCORE_VALUE: int = 40
const FRONT_MAX_HP: float = 150.0
var front_hp: float = FRONT_MAX_HP

# RPG-7 equivalent blast constants (matches rpg_rocket.gd)
const BLAST_MAX_DAMAGE: float = 900.0
const BLAST_RADIUS: float = 16.5
const PLAYER_BLAST_RADIUS: float = 12.75

# Wreck lifecycle: 2 minutes burning -> smooth sink underground
const WRECK_BURN_DURATION: float = 120.0
const WRECK_SINK_DURATION: float = 3.5
var wreck_timer: float = 0.0
var is_sinking: bool = false

# Movement & AI state
var player: Node3D = null
var spawner_ref: Node = null
var forward_speed: float = 0.0
var steer_angle: float = 0.0
var orbit_sign: float = 1.0
var avoid_turn_bias: float = 1.0
var approach_timer: float = 0.0

var ram_cooldown: float = 5.0
var ram_lineup_timer: float = 0.0
var ram_active_timer: float = 0.0
var ram_hit_player_done: bool = false
var locked_straight_dir: Vector3 = Vector3.FORWARD

# Unloading state
var door_open_t: float = 0.0
var unload_stage: int = 0 # 0=opening door, 1=deploying troops, 2=closing door
var unload_timer: float = 0.0
var passenger_queue: Array[Dictionary] = [] # [{"type": int, "model": Node3D, "reward": int}]

# Visual & Physics nodes
var body_pivot: Node3D = null
var sliding_door_node: Node3D = null
var sliding_door_closed_pos: Vector3 = Vector3(1.13, 1.15, 0.42)
var driver_model: Node3D = null
var wheel_nodes: Array[Node3D] = []
var front_wheel_pivots: Array[Node3D] = []
var glass_meshes: Array[MeshInstance3D] = []
var headlights_spot: SpotLight3D = null
var cabin_light: OmniLight3D = null

var front_smoke_fx: CPUParticles3D = null
var front_sparks_fx: CPUParticles3D = null
var wreck_fire_fx: CPUParticles3D = null
var wreck_smoke_fx: CPUParticles3D = null
var wreck_fire_light: OmniLight3D = null

var all_hitboxes: Array[StaticBody3D] = []
var own_rids: Array[RID] = []

# Audio
var audio_engine: AudioStreamPlayer3D = null
var audio_fx: AudioStreamPlayer3D = null
var current_engine_mode: String = "" # "idle", "move", "accel", "fire", "off"

func _ready() -> void:
	if is_preview_only:
		set_physics_process(false)
		passenger_queue.clear()
		for t in [0, 1, 2, 3]:
			passenger_queue.append({"type": t, "model": null, "reward": _reward_for_enemy_type(t)})
		_build_van_model()
		door_open_t = 0.78
		_apply_sliding_door_transform()
		return
	add_to_group("enemy")
	add_to_group("black_minivan")
	orbit_sign = 1.0 if randf() > 0.5 else -1.0
	avoid_turn_bias = orbit_sign
	ram_cooldown = randf_range(3.6, 7.6)

	_roll_passengers()
	_build_van_model()
	_setup_audio()
	_find_player()

static func create_preview() -> Node3D:
	var holder := Node3D.new()
	var van = new()
	van.is_preview_only = true
	van.scale = Vector3(0.36, 0.36, 0.36)
	van.position = Vector3(0.0, -0.36, 0.0)
	van.rotation_degrees.y = 32.0
	holder.add_child(van)
	return holder

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		player = players[0] as Node3D

static func _reward_for_enemy_type(t: int) -> int:
	match t:
		0: return 6   # Red
		1: return 10  # Blue
		2: return 20  # Yellow Heavy
		3: return 16  # Green Sniper
	return 6

static func _color_for_enemy_type(t: int) -> Color:
	match t:
		0: return Color(0.90, 0.15, 0.15) # Red
		1: return Color(0.15, 0.45, 0.95) # Blue
		2: return Color(0.95, 0.75, 0.10) # Yellow
		3: return Color(0.15, 0.85, 0.25) # Green
	return Color(0.90, 0.15, 0.15)

func _roll_passengers() -> void:
	passenger_queue.clear()
	var count: int = randi_range(4, 6)
	for i in range(count):
		var t: int = randi() % 4 # Strictly 0..3 (Red/Blue/Yellow/Green — NO Tiger, NO Shahed!)
		passenger_queue.append({
			"type": t,
			"model": null,
			"reward": _reward_for_enemy_type(t),
		})

func get_remaining_passengers_reward() -> int:
	var total: int = 0
	for p in passenger_queue:
		total += int(p.get("reward", 4))
	return total

# ==========================================
# AUDIO SETUP & MODE SWITCHING
# ==========================================
func _setup_audio() -> void:
	audio_engine = AudioStreamPlayer3D.new()
	audio_engine.bus = "SFX"
	audio_engine.max_distance = 95.0
	audio_engine.unit_size = 16.0
	audio_engine.position = Vector3(0, 1.1, -1.8)
	add_child(audio_engine)

	audio_fx = AudioStreamPlayer3D.new()
	audio_fx.bus = "SFX"
	audio_fx.max_distance = 110.0
	audio_fx.unit_size = 20.0
	audio_fx.position = Vector3(0, 1.4, 0.0)
	add_child(audio_fx)

	_set_engine_audio_mode("move")

func _set_engine_audio_mode(mode: String) -> void:
	if current_engine_mode == mode or not audio_engine:
		return
	current_engine_mode = mode
	match mode:
		"idle":
			audio_engine.stream = SoundEffects.create_black_van_idle_sound()
			audio_engine.volume_db = -2.5
			audio_engine.pitch_scale = 0.96
			audio_engine.play()
		"move":
			audio_engine.stream = SoundEffects.create_black_van_move_sound()
			audio_engine.volume_db = -2.0
			audio_engine.pitch_scale = 1.00
			audio_engine.play()
		"accel":
			audio_engine.stream = SoundEffects.create_black_van_accel_sound()
			audio_engine.volume_db = 2.5
			audio_engine.pitch_scale = 1.04
			audio_engine.play()
		"fire":
			audio_engine.stream = SoundEffects.create_tiger_fire_sound()
			audio_engine.volume_db = -7.0
			audio_engine.pitch_scale = 0.94
			audio_engine.play()
		"off":
			audio_engine.stop()

func _play_3d_sfx(stream: AudioStream, pos: Vector3, bus_name: String = "SFX", vol_db: float = 0.0, pitch: float = 1.0, max_dist: float = 120.0, unit_sz: float = 20.0) -> void:
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

func _play_double_horn() -> void:
	if not is_inside_tree():
		return
	var horn_stream := SoundEffects.create_van_horn_sound()
	_play_3d_sfx(horn_stream, global_position + Vector3(0, 1.4, 0), "SFX", 2.5, 1.0, 130.0, 24.0)
	get_tree().create_timer(0.32).timeout.connect(func():
		if is_instance_valid(self) and is_inside_tree() and van_state != VanState.DESTROYED:
			_play_3d_sfx(SoundEffects.create_van_horn_sound(), global_position + Vector3(0, 1.4, 0), "SFX", 2.5, 1.03, 130.0, 24.0)
	)

# ==========================================
# MAIN PHYSICS & AI LOOP
# ==========================================
func _physics_process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)

	if van_state == VanState.DESTROYED:
		_process_destroyed_wreck(dt)
		return

	if not is_instance_valid(player):
		_find_player()
	if not is_instance_valid(player):
		return

	match van_state:
		VanState.APPROACHING:
			_process_approaching(dt)
		VanState.UNLOADING:
			_process_unloading(dt)
		VanState.ORBITING:
			_process_orbiting(dt)
		VanState.RAMMING:
			_process_straight_charge(dt, true)
		VanState.RUNAWAY:
			_process_straight_charge(dt, false)

	_update_wheels_and_body_tilt(dt)

func _process_approaching(dt: float) -> void:
	_set_engine_audio_mode("move")
	approach_timer += dt
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()

	if dist <= 18.5 or approach_timer > 14.0:
		# Smoothly brake and begin unloading squad!
		forward_speed = move_toward(forward_speed, 0.0, 16.0 * dt)
		global_position += (-global_transform.basis.z) * forward_speed * dt
		if absf(forward_speed) <= 0.45:
			forward_speed = 0.0
			_enter_unloading()
		return

	var desired_dir: Vector3 = to_p.normalized()
	_drive_steered(desired_dir, 9.2, 2.2, dt)

func _enter_unloading() -> void:
	van_state = VanState.UNLOADING
	forward_speed = 0.0
	steer_angle = 0.0
	unload_stage = 0
	unload_timer = 0.0
	_set_engine_audio_mode("idle")
	_play_3d_sfx(SoundEffects.create_black_van_deploy_sound(), global_position + Vector3(0, 1.2, 0), "SFX", 1.5, 1.0, 95.0, 16.0)

func _process_unloading(dt: float) -> void:
	_set_engine_audio_mode("idle")
	if unload_stage == 0:
		# Smoothly slide side door open
		door_open_t = move_toward(door_open_t, 1.0, dt / 0.55)
		_apply_sliding_door_transform()
		if door_open_t >= 1.0:
			unload_stage = 1
			unload_timer = 0.15
	elif unload_stage == 1:
		unload_timer -= dt
		if unload_timer <= 0.0:
			if not passenger_queue.is_empty():
				_deploy_next_passenger()
				unload_timer = 0.46
			else:
				unload_stage = 2
				unload_timer = 0.30
	elif unload_stage == 2:
		if unload_timer > 0.0:
			unload_timer -= dt
			return
		# Slide door back shut
		door_open_t = move_toward(door_open_t, 0.0, dt / 0.45)
		_apply_sliding_door_transform()
		if door_open_t <= 0.0:
			# Enemy logistics: Black Minivan leaves a fresh fuel drum / gas canister where it unloaded!
			var drop_p: Vector3 = global_position + global_transform.basis.x.normalized() * 2.4
			for mgr in get_tree().get_nodes_in_group("arena_interactables"):
				if is_instance_valid(mgr) and mgr.has_method("spawn_enemy_dropped_barrel"):
					mgr.spawn_enemy_dropped_barrel(drop_p)
			van_state = VanState.ORBITING
			ram_cooldown = randf_range(3.2, 7.2)
			ram_lineup_timer = 0.0
			_set_engine_audio_mode("move")

func _apply_sliding_door_transform() -> void:
	if not sliding_door_node:
		return
	var out_x: float = minf(door_open_t * 3.0, 1.0) * 0.13
	var slide_z: float = maxf(0.0, (door_open_t - 0.12) / 0.88) * 1.48
	sliding_door_node.position = sliding_door_closed_pos + Vector3(out_x, 0.0, slide_z)

func _deploy_next_passenger() -> void:
	if passenger_queue.is_empty() or not is_inside_tree():
		return
	var p_data: Dictionary = passenger_queue.pop_front()
	var pm = p_data.get("model", null)
	if pm and is_instance_valid(pm):
		(pm as Node3D).visible = false
		(pm as Node3D).queue_free()

	var e_scene: PackedScene = null
	if is_instance_valid(spawner_ref) and "enemy_scene" in spawner_ref and spawner_ref.enemy_scene:
		e_scene = spawner_ref.enemy_scene
	else:
		e_scene = load("res://scenes/enemy.tscn") as PackedScene
	if not e_scene:
		return
	var enemy = e_scene.instantiate()
	enemy.enemy_type = int(p_data.get("type", 0))
	var parent_node: Node = get_parent() if get_parent() else get_tree().root
	parent_node.add_child(enemy)

	# Spawn right outside the open right-side sliding doorway (+X)
	var right_dir: Vector3 = global_transform.basis.x.normalized()
	var fwd_dir: Vector3 = -global_transform.basis.z
	var spawn_pos: Vector3 = global_position + right_dir * 2.15 + fwd_dir * randf_range(-0.45, 0.45)
	spawn_pos.x = clampf(spawn_pos.x, -65.0, 65.0)
	spawn_pos.z = clampf(spawn_pos.z, -65.0, 65.0)
	spawn_pos.y = 0.0
	enemy.global_position = spawn_pos

	if is_instance_valid(spawner_ref) and spawner_ref.has_method("_on_enemy_died"):
		spawner_ref.enemies_alive += 1
		enemy.died.connect(spawner_ref._on_enemy_died)
		if spawner_ref.has_method("update_enemy_count_hud"):
			spawner_ref.update_enemy_count_hud()

	_play_3d_sfx(SoundEffects.create_player_jump_sound(), spawn_pos + Vector3(0, 0.6, 0), "SFX", -4.5, randf_range(0.90, 1.12), 55.0, 10.0)

func _process_orbiting(dt: float) -> void:
	_set_engine_audio_mode("move")
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist: float = maxf(0.1, to_p.length())
	var dir_to_p: Vector3 = to_p / dist

	ram_cooldown -= dt
	if ram_cooldown <= 0.0:
		# Aim cleanly toward player, then launch unstoppable straight ram!
		ram_lineup_timer += dt
		var hull_fwd: Vector3 = (-global_transform.basis.z)
		hull_fwd.y = 0.0
		hull_fwd = hull_fwd.normalized()
		var ang_err: float = absf(hull_fwd.signed_angle_to(dir_to_p, Vector3.UP))
		if ang_err < 0.20 or ram_lineup_timer > 1.85:
			_start_ram_attack(dir_to_p if ang_err < 0.35 else hull_fwd)
			return
		_drive_steered(dir_to_p, 8.0, 2.8, dt)
		return

	# Smooth circling orbit around player at ~15-21m radius
	var tangent: Vector3 = Vector3(-dir_to_p.z * orbit_sign, 0.0, dir_to_p.x * orbit_sign)
	var radial_pull: float = clampf((dist - 17.5) * 0.14, -0.65, 0.65)
	var desired_dir: Vector3 = (tangent + dir_to_p * radial_pull).normalized()
	_drive_steered(desired_dir, 10.5, 2.4, dt)

func _start_ram_attack(ram_dir: Vector3) -> void:
	van_state = VanState.RAMMING
	ram_active_timer = 0.0
	ram_hit_player_done = false
	locked_straight_dir = Vector3(ram_dir.x, 0.0, ram_dir.z).normalized()
	if locked_straight_dir.length_squared() < 0.01:
		locked_straight_dir = (-global_transform.basis.z).normalized()
	# Snap heading cleanly onto locked ram vector — NEVER turns again!
	rotation.y = atan2(-locked_straight_dir.x, -locked_straight_dir.z)
	steer_angle = 0.0
	_play_double_horn()
	_set_engine_audio_mode("accel")

func _start_runaway() -> void:
	if van_state == VanState.DESTROYED or van_state == VanState.RUNAWAY:
		return
	van_state = VanState.RUNAWAY
	ram_active_timer = 0.0
	ram_hit_player_done = false
	var fwd: Vector3 = -global_transform.basis.z
	fwd.y = 0.0
	locked_straight_dir = fwd.normalized() if fwd.length_squared() > 0.01 else Vector3.FORWARD
	steer_angle = 0.0
	if front_smoke_fx:
		front_smoke_fx.emitting = true
	if front_sparks_fx:
		front_sparks_fx.emitting = true
	_set_engine_audio_mode("accel")

func _process_straight_charge(dt: float, is_ram: bool) -> void:
	ram_active_timer += dt
	var max_spd: float = 24.0 if is_ram else 24.5
	var accel: float = 15.5 if is_ram else 16.5
	forward_speed = minf(max_spd, maxf(forward_speed, 7.5) + accel * dt)
	steer_angle = 0.0

	if audio_engine and audio_engine.playing:
		audio_engine.pitch_scale = lerpf(0.95, 1.32, clampf(forward_speed / max_spd, 0.0, 1.0))

	# Keep strictly straight along locked_straight_dir (NO turning!)
	var step: Vector3 = locked_straight_dir * forward_speed * dt
	var next_pos: Vector3 = global_position + step

	# 1. Check collision with Player (ram hit!) — van keeps going straight until it hits an object!
	if not ram_hit_player_done and is_instance_valid(player):
		var p_flat: Vector3 = Vector3(player.global_position.x, 0.0, player.global_position.z)
		var front_bumper_pos: Vector3 = next_pos + locked_straight_dir * 2.15
		if p_flat.distance_to(front_bumper_pos) <= 2.15 or p_flat.distance_to(next_pos) <= 2.35:
			ram_hit_player_done = true
			if player.has_method("take_damage"):
				player.take_damage(55.0)
			if player.has_method("add_camera_shake"):
				player.add_camera_shake(0.38)
			if player is CharacterBody3D:
				var side_kick: Vector3 = locked_straight_dir.cross(Vector3.UP).normalized()
				(player as CharacterBody3D).velocity += locked_straight_dir * 13.0 + side_kick * 5.0 + Vector3(0, 4.5, 0)
			_play_3d_sfx(SoundEffects.create_player_hurt_sound(), p_flat + Vector3(0, 1.0, 0), "SFX", 2.0, 0.92, 60.0, 14.0)

	# 2. Check collision with ANY map object / obstacle / arena boundary -> EXPLODE!
	if _check_charge_object_collision(global_position, next_pos):
		global_position = next_pos
		_explode()
		return

	global_position = next_pos

	# Failsafe if somehow crossing entire map without hitting anything
	if ram_active_timer >= 6.5:
		_explode()

func _check_charge_object_collision(cur_pos: Vector3, next_pos: Vector3) -> bool:
	# A. Arena boundary walls
	var nose_pos: Vector3 = next_pos + locked_straight_dir * 2.65
	if absf(nose_pos.x) >= 67.5 or absf(nose_pos.z) >= 67.5:
		return true

	# B. MapObstacles AABBs (buildings, props, trees, containers, destroyed Tiger wrecks, etc.)
	var front_aabb := AABB(nose_pos - Vector3(1.05, 0.0, 1.05), Vector3(2.10, 2.0, 2.10))
	for obs in MapObstacles.obstacle_aabbs:
		if obs.intersects(front_aabb):
			return true

	# C. Direct 3D physics raycasts along front bumper (catches live Tiger I, Shop Minivan, Workbench, other vans, static walls!)
	var space := get_world_3d().direct_space_state
	var right_v: Vector3 = locked_straight_dir.cross(Vector3.UP).normalized()
	for side_off in [-0.90, 0.0, 0.90]:
		var r_from: Vector3 = cur_pos + Vector3(0, 0.95, 0) + right_v * side_off + locked_straight_dir * 1.4
		var r_to: Vector3 = next_pos + Vector3(0, 0.95, 0) + right_v * side_off + locked_straight_dir * 2.85
		var q := PhysicsRayQueryParameters3D.create(r_from, r_to)
		q.exclude = own_rids
		q.collide_with_bodies = true
		q.collide_with_areas = false
		var res := space.intersect_ray(q)
		if not res.is_empty():
			var col: Object = res.collider
			if col == null:
				continue
			# Ignore player & small foot soldiers so the van plows past them and explodes on solid objects!
			if col.is_in_group("player"):
				continue
			if col is CharacterBody3D and col.is_in_group("enemy"):
				continue
			if col.is_in_group("black_van_hitbox") and col.get_meta("van_owner", null) == self:
				continue
			return true

	return false

# ==========================================
# OBSTACLE-AVOIDANCE STEERING (APPROACHING & ORBITING)
# ==========================================
func _drive_steered(desired_dir: Vector3, target_speed: float, turn_speed: float, dt: float) -> void:
	var hull_fwd: Vector3 = -global_transform.basis.z
	hull_fwd.y = 0.0
	hull_fwd = hull_fwd.normalized()

	var steer_dir: Vector3 = _compute_avoidance_dir(desired_dir, hull_fwd)
	var angle_diff: float = hull_fwd.signed_angle_to(steer_dir, Vector3.UP)
	var max_turn: float = turn_speed * dt
	var applied_turn: float = clampf(angle_diff, -max_turn, max_turn)
	rotation.y += applied_turn
	steer_angle = lerpf(steer_angle, clampf(angle_diff * 0.7, -0.52, 0.52), dt * 8.0)

	var new_fwd: Vector3 = -global_transform.basis.z
	new_fwd.y = 0.0
	new_fwd = new_fwd.normalized()

	var spd_scale: float = clampf(1.0 - absf(angle_diff) * 0.45, 0.35, 1.0)
	forward_speed = move_toward(forward_speed, target_speed * spd_scale, 9.0 * dt)

	var next_pos: Vector3 = global_position + new_fwd * forward_speed * dt
	if not _is_pos_blocked(next_pos):
		global_position = next_pos
	else:
		# Slide along unobstructed axis or gently back away from tight corner
		var slide_x := Vector3(next_pos.x, 0.0, global_position.z)
		var slide_z := Vector3(global_position.x, 0.0, next_pos.z)
		if not _is_pos_blocked(slide_x):
			global_position = slide_x
		elif not _is_pos_blocked(slide_z):
			global_position = slide_z
		else:
			rotation.y += avoid_turn_bias * turn_speed * 1.15 * dt
			forward_speed = move_toward(forward_speed, 0.0, 12.0 * dt)

	global_position.x = clampf(global_position.x, -64.5, 64.5)
	global_position.z = clampf(global_position.z, -64.5, 64.5)
	global_position.y = 0.0

func _is_pos_blocked(pos: Vector3) -> bool:
	if absf(pos.x) > 65.5 or absf(pos.z) > 65.5:
		return true
	var van_aabb := AABB(pos - Vector3(1.65, 0.0, 1.65), Vector3(3.30, 2.2, 3.30))
	for obs in MapObstacles.obstacle_aabbs:
		if obs.intersects(van_aabb):
			return true
	return false

func _probe_clearance(dir: Vector3, max_dist: float) -> float:
	var steps: int = 5
	for i in range(1, steps + 1):
		var d: float = (float(i) / float(steps)) * max_dist
		if _is_pos_blocked(global_position + dir * d):
			return d - (max_dist / float(steps))
	return max_dist

func _compute_avoidance_dir(goal_dir: Vector3, hull_fwd: Vector3) -> Vector3:
	if _probe_clearance(goal_dir, 8.5) >= 8.0:
		return goal_dir
	var best_dir: Vector3 = goal_dir
	var best_score: float = -999.0
	for deg in [25.0, -25.0, 50.0, -50.0, 80.0, -80.0, 115.0, -115.0]:
		var cand: Vector3 = goal_dir.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
		var clr: float = _probe_clearance(cand, 9.5)
		var align: float = cand.dot(goal_dir)
		var bias: float = 0.22 if (deg * avoid_turn_bias > 0.0) else 0.0
		var score: float = clr * 1.45 + align * 3.0 + cand.dot(hull_fwd) * 0.8 + bias
		if score > best_score:
			best_score = score
			best_dir = cand
	return best_dir

func _update_wheels_and_body_tilt(dt: float) -> void:
	var spin_delta: float = (forward_speed / 0.42) * dt
	for w in wheel_nodes:
		if is_instance_valid(w):
			w.rotation.x -= spin_delta
	for fp in front_wheel_pivots:
		if is_instance_valid(fp):
			fp.rotation.y = steer_angle
	if body_pivot:
		var target_roll: float = clampf(-steer_angle * (forward_speed / 12.0) * 0.14, -0.09, 0.09)
		var target_pitch: float = -0.045 if (van_state == VanState.RAMMING or van_state == VanState.RUNAWAY) else 0.0
		body_pivot.rotation.z = lerpf(body_pivot.rotation.z, target_roll, dt * 6.0)
		body_pivot.rotation.x = lerpf(body_pivot.rotation.x, target_pitch, dt * 6.0)

# ==========================================
# DAMAGE, RPG INSTANT KILL & EXPLOSION
# ==========================================
func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	# Cheat Menu "Kill All" / "Finish Wave" instant kill support!
	if amount >= 9000.0 and van_state != VanState.DESTROYED:
		_explode()

func on_bullet_hit(zone_id: String, dmg: float, hit_pos: Vector3, hit_normal: Vector3) -> bool:
	if van_state == VanState.DESTROYED:
		_spawn_metal_sparks(hit_pos, hit_normal)
		return false

	_spawn_metal_sparks(hit_pos, hit_normal)
	if zone_id == "front":
		if van_state != VanState.RUNAWAY:
			front_hp = maxf(0.0, front_hp - dmg)
			if front_hp <= FRONT_MAX_HP * 0.45 and front_smoke_fx and not front_smoke_fx.emitting:
				front_smoke_fx.emitting = true
			if front_hp <= 0.0:
				_start_runaway()
		return true

	# Body shots spark on armored van panels (front engine or RPG kills it!)
	_play_3d_sfx(SoundEffects.create_tiger_ricochet_sound(), hit_pos, "SFX", -7.5, randf_range(1.08, 1.32), 65.0, 12.0)
	return false

func on_rpg_hit(hit_pos: Vector3, _hit_normal: Vector3, direct_collider: Object) -> bool:
	if van_state == VanState.DESTROYED:
		return false
	var is_direct: bool = false
	if direct_collider and direct_collider is Node and (direct_collider as Node).is_in_group("black_van_hitbox"):
		if (direct_collider as Node).get_meta("van_owner", null) == self:
			is_direct = true
	var center: Vector3 = global_position + Vector3(0, 1.15, 0)
	if is_direct or hit_pos.distance_to(center) <= 6.0:
		_explode()
		return true
	return false

func _explode() -> void:
	if van_state == VanState.DESTROYED:
		return
	van_state = VanState.DESTROYED
	is_dead = true
	health = 0.0
	forward_speed = 0.0
	wreck_timer = 0.0
	is_sinking = false

	# 1. Calculate total reward: Minivan + EVERY passenger still trapped inside!
	var total_reward: int = VAN_SCORE_VALUE + get_remaining_passengers_reward()
	for p_data in passenger_queue:
		var pm = p_data.get("model", null)
		if pm and is_instance_valid(pm):
			(pm as Node3D).visible = false
			(pm as Node3D).queue_free()
	passenger_queue.clear()

	if driver_model and is_instance_valid(driver_model):
		driver_model.visible = false

	if is_in_group("enemy"):
		remove_from_group("enemy")
	add_to_group("black_minivan_wreck")

	# Eject 1 intact spare fuel drum nearby so arena combat stays dynamically interactive!
	var eject_p: Vector3 = global_position + Vector3(randf_range(-4.5, 4.5), 0.0, randf_range(-4.5, 4.5))
	for mgr in get_tree().get_nodes_in_group("arena_interactables"):
		if is_instance_valid(mgr) and mgr.has_method("spawn_enemy_dropped_barrel"):
			mgr.spawn_enemy_dropped_barrel(eject_p)

	var exp_pos: Vector3 = global_position + Vector3(0, 1.35, 0)

	# 2. RPG-7 Equivalent Blast Damage to nearby enemies (including Tiger I & other Black Minivans!)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e == self or not (e is Node3D):
			continue
		if e.is_in_group("tiger_boss") and e.has_method("on_rpg_hit"):
			if exp_pos.distance_to((e as Node3D).global_position) <= BLAST_RADIUS:
				e.on_rpg_hit(exp_pos, Vector3.UP, null, BLAST_MAX_DAMAGE, BLAST_RADIUS)
			continue
		if e.is_in_group("black_minivan") and e.has_method("on_rpg_hit"):
			if exp_pos.distance_to((e as Node3D).global_position) <= 6.5:
				e.on_rpg_hit(exp_pos, Vector3.UP, null)
			continue
		var e_pos: Vector3 = (e as Node3D).global_position
		var dist: float = minf(exp_pos.distance_to(e_pos), exp_pos.distance_to(e_pos + Vector3(0, 0.85, 0)))
		if dist <= BLAST_RADIUS and e.has_method("take_damage"):
			var falloff: float = 1.0
			if dist > 5.25:
				falloff = lerpf(1.0, 0.30, clampf((dist - 5.25) / maxf(0.01, BLAST_RADIUS - 5.25), 0.0, 1.0))
			e.take_damage(BLAST_MAX_DAMAGE * falloff, false)

	# 3. RPG-7 Equivalent Blast Damage & Camera Shake to Player
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node3D:
			var p_dist: float = exp_pos.distance_to((p as Node3D).global_position + Vector3(0, 0.9, 0))
			if p_dist <= PLAYER_BLAST_RADIUS and p.has_method("take_damage"):
				var dmg_p: float = lerpf(135.0, 20.0, clampf(p_dist / PLAYER_BLAST_RADIUS, 0.0, 1.0))
				p.take_damage(dmg_p)
			if p_dist <= 48.0 and p.has_method("add_camera_shake"):
				var shake: float = clampf(1.0 - p_dist / 48.0, 0.14, 1.0) * 0.42
				p.add_camera_shake(shake)

	# 4. Colorful RPG-Style Explosion + Expanding Semi-Transparent Shockwave Sphere!
	VFXFactoryScript.spawn_explosion(get_tree().root, exp_pos, Vector3.UP, 2.35)
	VFXFactoryScript.spawn_explosion(get_tree().root, exp_pos + Vector3(0, 1.2, 0), Vector3.UP, 1.55)
	_spawn_shockwave_sphere(exp_pos)

	# 5. Loud Car Explosion SFX + Lingering Crackling Fire
	_play_3d_sfx(SoundEffects.create_black_van_explosion_sound(), exp_pos, "Weapons", 6.5, randf_range(0.94, 1.05), 175.0, 32.0)
	_set_engine_audio_mode("fire")

	# 6. Char the Minivan Wreck & Ignite Continuous 2-Minute Fire!
	for gm in glass_meshes:
		if is_instance_valid(gm):
			gm.visible = false
	if headlights_spot:
		headlights_spot.visible = false
	if cabin_light:
		cabin_light.visible = false
	if front_sparks_fx:
		front_sparks_fx.emitting = false
	if front_smoke_fx:
		front_smoke_fx.emitting = false

	var charred := StandardMaterial3D.new()
	charred.albedo_color = Color(0.07, 0.07, 0.08)
	charred.metallic = 0.32
	charred.roughness = 0.94
	if body_pivot:
		_apply_material_recursive(body_pivot, charred)
		body_pivot.rotation.z = deg_to_rad(randf_range(-5.0, 5.0))
		body_pivot.rotation.x = deg_to_rad(randf_range(-3.0, 3.0))

	if wreck_fire_fx:
		wreck_fire_fx.emitting = true
	if wreck_smoke_fx:
		wreck_smoke_fx.emitting = true
	if wreck_fire_light:
		wreck_fire_light.visible = true

	died.emit(total_reward)

func _spawn_shockwave_sphere(origin: Vector3) -> void:
	if not is_inside_tree():
		return
	var sw := MeshInstance3D.new()
	sw.name = "MinivanShockwaveSphere"
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 28
	sm.rings = 16
	sw.mesh = sm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = Color(1.0, 0.78, 0.42, 0.56)
	sw.material_override = mat

	get_tree().root.add_child(sw)
	sw.global_position = origin
	sw.scale = Vector3(0.6, 0.6, 0.6)

	var tw := sw.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sw, "scale", Vector3(BLAST_RADIUS, BLAST_RADIUS, BLAST_RADIUS), 0.56).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color", Color(1.0, 0.48, 0.16, 0.0), 0.56).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(sw.queue_free)

func _process_destroyed_wreck(dt: float) -> void:
	wreck_timer += dt
	if not is_sinking:
		if wreck_fire_light:
			wreck_fire_light.light_energy = randf_range(3.2, 5.8)
		if wreck_timer >= WRECK_BURN_DURATION:
			is_sinking = true
			wreck_timer = 0.0
			_set_engine_audio_mode("off")
			if wreck_fire_fx:
				wreck_fire_fx.emitting = false
			if wreck_smoke_fx:
				wreck_smoke_fx.emitting = false
			if wreck_fire_light:
				wreck_fire_light.visible = false
			# Disable hitboxes before sinking so nothing gets pushed down
			for hb in all_hitboxes:
				if is_instance_valid(hb):
					hb.queue_free()
			all_hitboxes.clear()
	else:
		var t: float = clampf(wreck_timer / WRECK_SINK_DURATION, 0.0, 1.0)
		global_position.y = lerpf(0.0, -3.4, t * t)
		if t >= 1.0:
			queue_free()

func _spawn_metal_sparks(pos: Vector3, normal: Vector3) -> void:
	if not is_inside_tree():
		return
	var cp := CPUParticles3D.new()
	cp.one_shot = true
	cp.explosiveness = 0.95
	cp.amount = 10
	cp.lifetime = 0.24
	cp.direction = normal.normalized() if normal.length_squared() > 0.01 else Vector3.UP
	cp.spread = 48.0
	cp.gravity = Vector3(0, -10.0, 0)
	cp.initial_velocity_min = 3.0
	cp.initial_velocity_max = 7.2
	var bm := BoxMesh.new()
	bm.size = Vector3(0.03, 0.03, 0.11)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.85, 0.35)
	bm.material = smat
	cp.mesh = bm
	get_tree().root.add_child(cp)
	cp.global_position = pos
	cp.emitting = true
	get_tree().create_timer(0.40).timeout.connect(cp.queue_free)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for c in node.get_children():
		if c is CPUParticles3D:
			continue
		_apply_material_recursive(c, mat)

# ==========================================
# HOLLOW GLOSSY BLACK MINIVAN MODEL + VISIBLE INTERIOR CREW & DRIVER IN STRAW HAT
# (Forward is -Z, Right is +X, Up is +Y)
# ==========================================
func _build_van_model() -> void:
	body_pivot = Node3D.new()
	body_pivot.name = "VanBodyPivot"
	add_child(body_pivot)

	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.055, 0.060, 0.070) # Glossy Tactical Black
	mat_black.metallic = 0.68
	mat_black.roughness = 0.25

	var mat_trim := StandardMaterial3D.new()
	mat_trim.albedo_color = Color(0.11, 0.11, 0.13) # Matte black bumper/trim
	mat_trim.metallic = 0.35
	mat_trim.roughness = 0.62

	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.85, 0.88, 0.92)
	mat_chrome.metallic = 0.92
	mat_chrome.roughness = 0.18

	var mat_interior := StandardMaterial3D.new()
	mat_interior.albedo_color = Color(0.14, 0.15, 0.17)
	mat_interior.roughness = 0.88

	var mat_seat := StandardMaterial3D.new()
	mat_seat.albedo_color = Color(0.20, 0.18, 0.16)
	mat_seat.roughness = 0.82

	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.32, 0.44, 0.54, 0.22) # Lightly tinted so interior squad & driver are clearly visible!
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.metallic = 0.45
	mat_glass.roughness = 0.06
	mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_tire := StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.08, 0.08, 0.09)
	mat_tire.roughness = 0.86

	var mat_hl := StandardMaterial3D.new()
	mat_hl.albedo_color = Color(1.0, 0.95, 0.72)
	mat_hl.emission_enabled = true
	mat_hl.emission = Color(1.0, 0.95, 0.72)
	mat_hl.emission_energy_multiplier = 2.8

	var mat_tl := StandardMaterial3D.new()
	mat_tl.albedo_color = Color(0.95, 0.12, 0.10)
	mat_tl.emission_enabled = true
	mat_tl.emission = Color(0.95, 0.12, 0.10)
	mat_tl.emission_energy_multiplier = 2.2

	# 1. CHASSIS FLOOR, ROOF & HOLLOW SIDE/REAR STRUCTURE (Width 2.24m, Length 5.45m, Height 2.15m)
	_add_box(body_pivot, "ChassisFloor", Vector3(2.16, 0.16, 5.20), Vector3(0, 0.44, 0.05), mat_interior)
	_add_box(body_pivot, "Roof", Vector3(2.22, 0.11, 4.10), Vector3(0, 2.14, 0.55), mat_black)

	# Front Engine Hood & Grille (z = -2.68 to -1.55)
	_add_box(body_pivot, "FrontHood", Vector3(2.16, 0.78, 1.18), Vector3(0, 0.90, -2.10), mat_black)
	_add_box(body_pivot, "FrontHoodSlope", Vector3(2.14, 0.12, 1.16), Vector3(0, 1.29, -2.08), mat_black, Vector3(6.0, 0, 0))
	_add_box(body_pivot, "FrontGrille", Vector3(1.22, 0.34, 0.08), Vector3(0, 0.88, -2.70), mat_trim)
	for gi in range(3):
		_add_box(body_pivot, "GrilleBar_%d" % gi, Vector3(1.16, 0.035, 0.10), Vector3(0, 0.78 + float(gi) * 0.10, -2.71), mat_chrome)
	# Heavy Tactical Front Push-Bumper & Rear Bumper
	_add_box(body_pivot, "FrontBumper", Vector3(2.28, 0.34, 0.28), Vector3(0, 0.48, -2.76), mat_trim)
	_add_box(body_pivot, "BullBarTop", Vector3(1.56, 0.08, 0.08), Vector3(0, 0.96, -2.86), mat_trim)
	for bx in [-0.62, 0.62]:
		_add_box(body_pivot, "BullBarPost", Vector3(0.08, 0.52, 0.08), Vector3(bx, 0.72, -2.86), mat_trim)
	_add_box(body_pivot, "RearBumper", Vector3(2.28, 0.32, 0.28), Vector3(0, 0.48, 2.74), mat_trim)
	_add_cyl(body_pivot, "RearExhaustPipe", 0.055, 0.055, 0.48, Vector3(-0.74, 0.32, 2.66), mat_chrome, 10, Vector3(90.0, 0, 0))

	# Headlights & Taillights
	for hx in [-0.82, 0.82]:
		_add_box(body_pivot, "Headlight", Vector3(0.40, 0.22, 0.10), Vector3(hx, 0.98, -2.69), mat_hl)
		_add_box(body_pivot, "Taillight", Vector3(0.24, 0.46, 0.10), Vector3(hx, 1.26, 2.66), mat_tl)

	headlights_spot = SpotLight3D.new()
	headlights_spot.spot_range = 34.0
	headlights_spot.spot_angle = 46.0
	headlights_spot.light_color = Color(1.0, 0.96, 0.82)
	headlights_spot.light_energy = 3.2
	headlights_spot.position = Vector3(0, 0.98, -2.76)
	body_pivot.add_child(headlights_spot)

	# Left Wall (-X): lower solid side panel + pillars + clear side windows
	_add_box(body_pivot, "LeftLowerWall", Vector3(0.11, 0.78, 4.18), Vector3(-1.07, 0.91, 0.56), mat_black)
	for pz in [-1.42, -0.34, 1.22, 2.58]:
		_add_box(body_pivot, "LeftPillar", Vector3(0.12, 0.86, 0.14), Vector3(-1.07, 1.72, pz), mat_black)
	glass_meshes.append(_add_box(body_pivot, "LeftGlass", Vector3(0.03, 0.76, 3.86), Vector3(-1.08, 1.72, 0.58), mat_glass))

	# Right Wall (+X): front door lower + rear quarter lower + OPEN SLIDING DOORWAY (z = -0.32..+1.22)
	_add_box(body_pivot, "RightFrontLower", Vector3(0.11, 0.78, 1.18), Vector3(1.07, 0.91, -0.94), mat_black)
	_add_box(body_pivot, "RightRearLower", Vector3(0.11, 0.78, 1.44), Vector3(1.07, 0.91, 1.94), mat_black)
	for pz in [-1.42, -0.36, 1.24, 2.58]:
		_add_box(body_pivot, "RightPillar", Vector3(0.12, 0.86, 0.14), Vector3(1.07, 1.72, pz), mat_black)
	# Visible metallic sliding-door rail on exterior right side
	_add_box(body_pivot, "DoorSlideRail", Vector3(0.05, 0.06, 2.85), Vector3(1.13, 1.22, 1.15), mat_chrome)
	glass_meshes.append(_add_box(body_pivot, "RightFrontGlass", Vector3(0.03, 0.76, 0.94), Vector3(1.08, 1.72, -0.88), mat_glass))
	glass_meshes.append(_add_box(body_pivot, "RightRearGlass", Vector3(0.03, 0.76, 1.22), Vector3(1.08, 1.72, 1.92), mat_glass))

	# Animated Sliding Side Door covering z = -0.32..+1.22 on +X side!
	sliding_door_node = Node3D.new()
	sliding_door_node.name = "SlidingDoor"
	sliding_door_node.position = sliding_door_closed_pos
	body_pivot.add_child(sliding_door_node)
	_add_box(sliding_door_node, "DoorLower", Vector3(0.09, 0.78, 1.54), Vector3(0, -0.24, 0.0), mat_black)
	_add_box(sliding_door_node, "DoorTopFrame", Vector3(0.09, 0.11, 1.54), Vector3(0, 0.92, 0.0), mat_black)
	_add_box(sliding_door_node, "DoorEdgeF", Vector3(0.09, 0.78, 0.09), Vector3(0, 0.54, -0.72), mat_black)
	_add_box(sliding_door_node, "DoorEdgeR", Vector3(0.09, 0.78, 0.09), Vector3(0, 0.54, 0.72), mat_black)
	_add_box(sliding_door_node, "DoorHandle", Vector3(0.06, 0.06, 0.22), Vector3(0.06, 0.04, -0.52), mat_chrome)
	glass_meshes.append(_add_box(sliding_door_node, "DoorGlass", Vector3(0.03, 0.72, 1.34), Vector3(0, 0.54, 0.0), mat_glass))

	# Rear Tailgate + Clear Rear Window
	_add_box(body_pivot, "RearLower", Vector3(2.22, 0.80, 0.12), Vector3(0, 0.92, 2.62), mat_black)
	_add_box(body_pivot, "RearTopBar", Vector3(2.22, 0.14, 0.12), Vector3(0, 2.08, 2.62), mat_black)
	glass_meshes.append(_add_box(body_pivot, "RearGlass", Vector3(1.94, 0.76, 0.03), Vector3(0, 1.66, 2.62), mat_glass))

	# Angled Front Windshield (lightly tinted so Green Driver in Straw Hat is super clear!)
	glass_meshes.append(_add_box(body_pivot, "Windshield", Vector3(2.00, 0.88, 0.04), Vector3(0, 1.70, -1.56), mat_glass, Vector3(-22.0, 0, 0)))

	# 2. INTERIOR CABIN: DASHBOARD, STEERING WHEEL, BENCHES & DOME LIGHT
	_add_box(body_pivot, "Dashboard", Vector3(2.00, 0.42, 0.46), Vector3(0, 1.02, -1.36), mat_interior)
	_add_cyl(body_pivot, "SteeringCol", 0.04, 0.04, 0.42, Vector3(-0.52, 1.14, -1.16), mat_trim, 8, Vector3(-55, 0, 0))
	_add_cyl(body_pivot, "SteeringWheel", 0.22, 0.22, 0.04, Vector3(-0.52, 1.24, -1.00), mat_trim, 14, Vector3(-62, 0, 0))
	_add_box(body_pivot, "DriverSeat", Vector3(0.68, 0.36, 0.62), Vector3(-0.52, 0.70, -0.82), mat_seat)
	_add_box(body_pivot, "LeftBench", Vector3(0.56, 0.34, 2.55), Vector3(-0.74, 0.68, 1.05), mat_seat)
	_add_box(body_pivot, "RightBench", Vector3(0.56, 0.34, 1.20), Vector3(0.74, 0.68, 1.85), mat_seat)

	cabin_light = OmniLight3D.new()
	cabin_light.light_color = Color(1.0, 0.94, 0.80)
	cabin_light.light_energy = 1.15
	cabin_light.omni_range = 3.8
	cabin_light.position = Vector3(0, 1.96, 0.35)
	body_pivot.add_child(cabin_light)

	# 3. FULL-SIZE GREEN DRIVER IN WOVEN STRAW HAT (СОЛОМЕННАЯ ШЛЯПА)!
	driver_model = _build_crewmate_model(Color(0.16, 0.84, 0.25), true)
	driver_model.name = "DriverGreenStrawHat"
	driver_model.position = Vector3(-0.52, 1.06, -0.82)
	body_pivot.add_child(driver_model)

	# 4. VISIBLE SPECIFIC SQUAD PASSENGERS INSIDE THE CABIN (4-6 exact colored crewmates!)
	var seat_slots: Array[Dictionary] = [
		{"pos": Vector3(-0.68, 1.04, 0.20), "yaw": -85.0},
		{"pos": Vector3(-0.68, 1.04, 1.05), "yaw": -88.0},
		{"pos": Vector3(-0.68, 1.04, 1.92), "yaw": -78.0},
		{"pos": Vector3(0.56,  1.04, 1.88), "yaw": 88.0},
		{"pos": Vector3(0.54,  1.04, 1.15), "yaw": 100.0},
		{"pos": Vector3(0.50,  1.04, -0.78), "yaw": 0.0}, # Front shotgun seat for 6th troop!
	]
	for i in range(passenger_queue.size()):
		var p_data: Dictionary = passenger_queue[i]
		var slot: Dictionary = seat_slots[i % seat_slots.size()]
		var pm: Node3D = _build_crewmate_model(_color_for_enemy_type(int(p_data["type"])), false)
		pm.name = "Passenger_%d" % i
		pm.position = slot["pos"]
		pm.rotation_degrees.y = float(slot["yaw"])
		body_pivot.add_child(pm)
		p_data["model"] = pm

	# 5. 4 WHEELS WITH SILVER RIMS (Front 2 steer visibly!)
	wheel_nodes.clear()
	front_wheel_pivots.clear()
	var wheel_specs: Array[Dictionary] = [
		{"pos": Vector3(-1.12, 0.42, -1.72), "front": true},
		{"pos": Vector3(1.12,  0.42, -1.72), "front": true},
		{"pos": Vector3(-1.12, 0.42, 1.68),  "front": false},
		{"pos": Vector3(1.12,  0.42, 1.68),  "front": false},
	]
	for ws in wheel_specs:
		var piv := Node3D.new()
		piv.position = ws["pos"]
		add_child(piv)
		if ws["front"]:
			front_wheel_pivots.append(piv)
		var w_spin := Node3D.new()
		piv.add_child(w_spin)
		_add_cyl(w_spin, "Tire", 0.42, 0.42, 0.28, Vector3.ZERO, mat_tire, 14, Vector3(0, 0, 90))
		_add_cyl(w_spin, "Rim", 0.24, 0.24, 0.30, Vector3.ZERO, mat_chrome, 10, Vector3(0, 0, 90))
		_add_box(w_spin, "Spoke", Vector3(0.31, 0.40, 0.055), Vector3.ZERO, mat_trim)
		wheel_nodes.append(w_spin)

	# 6. PARTICLE EMITTERS (Front engine smoke/sparks on shot-out front + 2-min wreck fire/smoke!)
	front_smoke_fx = _create_smoke_emitter(Color(0.14, 0.14, 0.16, 0.90), 34, 1.65)
	front_smoke_fx.position = Vector3(0, 1.32, -2.18)
	body_pivot.add_child(front_smoke_fx)

	front_sparks_fx = _create_sparks_emitter()
	front_sparks_fx.position = Vector3(0, 1.24, -2.35)
	body_pivot.add_child(front_sparks_fx)

	wreck_fire_fx = _create_fire_emitter()
	wreck_fire_fx.position = Vector3(0, 1.25, -0.35)
	body_pivot.add_child(wreck_fire_fx)

	wreck_smoke_fx = _create_smoke_emitter(Color(0.06, 0.06, 0.07, 0.94), 44, 2.5)
	wreck_smoke_fx.position = Vector3(0, 1.55, -0.25)
	body_pivot.add_child(wreck_smoke_fx)

	wreck_fire_light = OmniLight3D.new()
	wreck_fire_light.light_color = Color(1.0, 0.50, 0.14)
	wreck_fire_light.light_energy = 4.5
	wreck_fire_light.omni_range = 16.0
	wreck_fire_light.position = Vector3(0, 2.35, -0.25)
	wreck_fire_light.visible = false
	body_pivot.add_child(wreck_fire_light)

	# 7. HITBOXES ("front" engine zone vs general "body" zone)
	_add_hitbox(body_pivot, "front", Vector3(2.30, 1.20, 1.40), Vector3(0, 0.94, -2.14))
	_add_hitbox(body_pivot, "body",  Vector3(2.30, 1.80, 4.18), Vector3(0, 1.28, 0.62))

func _add_hitbox(parent: Node3D, zone_id: String, sz: Vector3, pos: Vector3) -> StaticBody3D:
	if is_preview_only:
		return null
	var sb := StaticBody3D.new()
	sb.name = "HB_" + zone_id
	sb.position = pos
	sb.add_to_group("black_van_hitbox")
	sb.set_meta("hit_zone", zone_id)
	sb.set_meta("van_owner", self)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = sz
	col.shape = sh
	sb.add_child(col)
	parent.add_child(sb)
	all_hitboxes.append(sb)
	own_rids.append(sb.get_rid())
	return sb

static func _build_crewmate_model(suit_color: Color, with_straw_hat: bool = false) -> Node3D:
	var root := Node3D.new()
	var mat_suit := StandardMaterial3D.new()
	mat_suit.albedo_color = suit_color
	mat_suit.roughness = 0.34
	mat_suit.metallic = 0.08

	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.56, 0.92, 1.0)
	mat_visor.emission_enabled = true
	mat_visor.emission = Color(0.24, 0.72, 0.85)
	mat_visor.emission_energy_multiplier = 0.50
	mat_visor.metallic = 0.45
	mat_visor.roughness = 0.08

	var mat_rim := StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.08, 0.10, 0.12)
	mat_rim.roughness = 0.50

	var body := MeshInstance3D.new()
	var cap_m := CapsuleMesh.new()
	cap_m.radius = 0.28
	cap_m.height = 0.92
	cap_m.radial_segments = 14
	cap_m.rings = 4
	body.mesh = cap_m
	body.material_override = mat_suit
	body.position = Vector3(0, 0.20, 0)
	root.add_child(body)

	_add_box(root, "VisorRim", Vector3(0.38, 0.19, 0.12), Vector3(0, 0.36, -0.22), mat_rim)
	_add_box(root, "VisorGlass", Vector3(0.34, 0.15, 0.14), Vector3(0, 0.36, -0.24), mat_visor)
	_add_box(root, "Backpack", Vector3(0.36, 0.46, 0.18), Vector3(0, 0.20, 0.24), mat_suit)

	if with_straw_hat:
		# Detailed Woven Straw Hat (Соломенная шляпа) on the Green Driver!
		var hat := Node3D.new()
		hat.name = "StrawHat"
		hat.position = Vector3(0, 0.62, 0.0)
		hat.rotation.x = deg_to_rad(-6.0)
		root.add_child(hat)

		var mat_straw := StandardMaterial3D.new()
		mat_straw.albedo_color = Color(0.90, 0.77, 0.40) # Warm golden woven straw
		mat_straw.roughness = 0.85

		var mat_straw_dark := StandardMaterial3D.new()
		mat_straw_dark.albedo_color = Color(0.76, 0.62, 0.28)
		mat_straw_dark.roughness = 0.88

		var mat_ribbon := StandardMaterial3D.new()
		mat_ribbon.albedo_color = Color(0.74, 0.14, 0.12) # Classic red straw-hat ribbon band!
		mat_ribbon.roughness = 0.55

		# Wide sun brim + weave trim + ribbon band + domed straw crown
		_add_cyl(hat, "HatBrim", 0.52, 0.55, 0.032, Vector3(0, 0.0, 0), mat_straw, 18)
		_add_cyl(hat, "HatBrimEdge", 0.555, 0.555, 0.022, Vector3(0, -0.004, 0), mat_straw_dark, 18)
		_add_cyl(hat, "HatRibbon", 0.295, 0.305, 0.065, Vector3(0, 0.048, 0), mat_ribbon, 16)
		_add_cyl(hat, "HatCrown", 0.24, 0.29, 0.18, Vector3(0, 0.12, 0), mat_straw, 16)

	return root

func _create_smoke_emitter(col: Color, amt: int, life: float) -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = amt
	cp.lifetime = life
	cp.direction = Vector3(0, 1, 0)
	cp.spread = 24.0
	cp.gravity = Vector3(0, 1.6, 0)
	cp.initial_velocity_min = 1.6
	cp.initial_velocity_max = 3.6
	cp.scale_amount_min = 0.65
	cp.scale_amount_max = 2.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.95, 0.95)
	qm.material = VFXFactoryScript.create_soft_smoke_material(col)
	cp.mesh = qm
	return cp

func _create_fire_emitter() -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = 42
	cp.lifetime = 0.72
	cp.direction = Vector3(0, 1, 0)
	cp.spread = 32.0
	cp.gravity = Vector3(0, 2.4, 0)
	cp.initial_velocity_min = 1.8
	cp.initial_velocity_max = 4.6
	cp.scale_amount_min = 0.65
	cp.scale_amount_max = 1.85
	var qm := QuadMesh.new()
	qm.size = Vector2(0.95, 0.95)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.albedo_color = Color(1.0, 0.50, 0.12, 0.92)
	qm.material = fmat
	cp.mesh = qm
	return cp

func _create_sparks_emitter() -> CPUParticles3D:
	var cp := CPUParticles3D.new()
	cp.emitting = false
	cp.local_coords = false
	cp.amount = 18
	cp.lifetime = 0.40
	cp.direction = Vector3(0, 1, 0)
	cp.spread = 50.0
	cp.gravity = Vector3(0, -10.0, 0)
	cp.initial_velocity_min = 2.5
	cp.initial_velocity_max = 6.5
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, 0.12)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.85, 0.30)
	bm.material = smat
	cp.mesh = bm
	return cp

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
