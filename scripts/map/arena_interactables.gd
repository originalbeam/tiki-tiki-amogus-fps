class_name ArenaInteractablesManager
extends Node3D

# =============================================================================
# LIVE INTERACTIVE ARENA OBJECTS & PARACHUTE SUPPLY LOGISTICS (NO BORING TIMERS!)
# 1) FuelBarrel        — Chain-detonating explosive drum + 7s burning NapalmPool (hot in FLIR!)
# 2) GasCylinder       — Pressurized tank: rocket-hisses or vents 14s tactical smoke/gas cloud
# 3) FloodlightGen     — Night sector floodlight tower + generator (shoot -> EMP stun + blackout!)
# 4) AirdropCrate      — Parachute drop with colored signal flare & smoke: Loot [E] OR Supply Pallet!
# 5) MountedDShK       — Sandbag emplacement + 12.7mm heavy MG [E] with heat gauge & destructible HP!
# =============================================================================

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")
const WeaponModDBScript = preload("res://scripts/weapons/weapon_mod_db.gd")

const MAX_BARRELS := 14
const MAX_CYLINDERS := 8
const MAX_FLOODLIGHTS := 6
const MAX_DSHK := 2

var active_map_id: String = "forest"
var interact_root: Node3D = null
var active_barrels: Array[Node3D] = []
var active_cylinders: Array[Node3D] = []
var active_floodlights: Array[Node3D] = []
var active_airdrops: Array[Dictionary] = []
var active_dshks: Array[Node3D] = []
var active_napalm_pools: Array[Dictionary] = [] # {node, pos, radius, time_left, tick_t}
var active_smoke_clouds: Array[Dictionary] = [] # {node, pos, radius, time_left}
var active_rockets: Array[Dictionary] = [] # runaway gas cylinders!

var _midwave_airdrop_timer: float = -1.0
var _thermal_hot_mat: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("arena_interactables")
	interact_root = Node3D.new()
	interact_root.name = "ArenaInteractablesRoot"
	add_child(interact_root)
	_thermal_hot_mat = StandardMaterial3D.new()
	_thermal_hot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_thermal_hot_mat.albedo_color = Color(0.98, 0.0, 1.0, 1.0)

func clear_all() -> void:
	if interact_root:
		for c in interact_root.get_children():
			c.queue_free()
	active_barrels.clear()
	active_cylinders.clear()
	active_floodlights.clear()
	active_airdrops.clear()
	active_dshks.clear()
	active_napalm_pools.clear()
	active_smoke_clouds.clear()
	active_rockets.clear()

func populate_for_biome(map_id: String) -> void:
	active_map_id = map_id
	clear_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = map_id.hash() ^ 0x51A7F3

	var barrel_cnt: int = 10 if map_id == "factory" else 7
	var cyl_cnt: int = 5 if map_id in ["factory", "city"] else 4
	var flood_cnt: int = 5 if map_id == "factory" else 4
	var dshk_cnt: int = 2

	for _i in range(barrel_cnt):
		var p: Vector3 = _find_open_arena_point(rng, 16.0, 58.0, 4.5)
		spawn_fuel_barrel(p)
	for _i in range(cyl_cnt):
		var p: Vector3 = _find_open_arena_point(rng, 18.0, 56.0, 4.5)
		spawn_gas_cylinder(p)
	for i in range(flood_cnt):
		var ang: float = (float(i) / float(maxi(1, flood_cnt))) * TAU + 0.35
		var dist: float = 28.0 if (i % 2 == 0) else 44.0
		var p: Vector3 = _nudge_clear_point(Vector3(cos(ang) * dist, 0.0, sin(ang) * dist))
		spawn_floodlight_generator(p, rad_to_deg(atan2(-p.x, -p.z)))
	for i in range(dshk_cnt):
		var ang: float = (0.75 if i == 0 else -2.35)
		var p: Vector3 = _nudge_clear_point(Vector3(cos(ang) * 20.0, 0.0, sin(ang) * 20.0))
		spawn_mounted_dshk(p, rad_to_deg(atan2(p.x, p.z)))

	_sync_floodlight_power_with_env()

func on_wave_cleared(next_wave: int) -> void:
	_prune_invalid()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Live battlefield logistics: drop parachute supply pallets whenever arena interactables were spent!
	var missing_barrels: int = maxi(0, (9 if active_map_id == "factory" else 6) - active_barrels.size())
	var missing_cyls: int = maxi(0, 4 - active_cylinders.size())
	var missing_floods: int = maxi(0, 3 - active_floodlights.size())
	var missing_dshk: int = maxi(0, 1 - active_dshks.size())

	if missing_barrels >= 2 or missing_cyls >= 1 or missing_floods >= 1 or missing_dshk >= 1:
		var pallets_to_drop: int = 2 if (missing_barrels >= 4 or missing_dshk >= 1) else 1
		for pi in range(pallets_to_drop):
			var drop_pos: Vector3 = _find_open_arena_point(rng, 18.0, 48.0, 5.5)
			var include_dshk: bool = (pi == 0 and missing_dshk >= 1 and next_wave >= 3)
			var include_flood: bool = (not include_dshk and missing_floods >= 1)
			spawn_parachute_drop(drop_pos, "supply_pallet", include_dshk, include_flood)

	# Drop a rewarding Loot Airdrop Crate on Wave 2 and every 2 waves thereafter!
	if next_wave >= 2 and (next_wave % 2 == 0):
		var loot_pos: Vector3 = _find_open_arena_point(rng, 17.0, 46.0, 5.0)
		spawn_parachute_drop(loot_pos, "loot", false, false)

func on_wave_started(wave_num: int) -> void:
	# Chance for an exciting mid-wave emergency Airdrop on waves 3+!
	_midwave_airdrop_timer = randf_range(16.0, 26.0) if wave_num >= 3 else -1.0

func spawn_enemy_dropped_barrel(pos: Vector3) -> void:
	# Called when Black Minivan unloads/explodes or Orange Engineer sets up equipment!
	_prune_invalid()
	var safe_p: Vector3 = Vector3(clampf(pos.x, -64.0, 64.0), 0.0, clampf(pos.z, -64.0, 64.0))
	if active_barrels.size() < MAX_BARRELS:
		spawn_fuel_barrel(safe_p)
	elif active_cylinders.size() < MAX_CYLINDERS:
		spawn_gas_cylinder(safe_p)

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)

	# Mid-wave parachute supply/loot drop
	if _midwave_airdrop_timer > 0.0:
		_midwave_airdrop_timer -= dt
		if _midwave_airdrop_timer <= 0.0:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var p: Vector3 = _find_open_arena_point(rng, 20.0, 48.0, 5.0)
			spawn_parachute_drop(p, "loot", false, false)

	_update_napalm_pools(dt)
	_update_smoke_clouds(dt)
	_update_runaway_cylinders(dt)
	_update_airdrops(dt)
	_update_dshks(dt)

# =============================================================================
# 1. FUEL BARREL (EXPLOSION + CHAIN REACTION + 7s BURNING NAPALM POOL)
# =============================================================================
func spawn_fuel_barrel(pos: Vector3) -> Node3D:
	if not interact_root:
		return null
	var body := StaticBody3D.new()
	body.name = "FuelBarrel"
	body.position = Vector3(pos.x, 0.0, pos.z)
	body.collision_layer = 1
	body.collision_mask = 7
	body.add_to_group("arena_shootable")
	body.set_meta("interact_kind", "fuel_barrel")
	body.set_meta("hp", 32.0)
	body.set_meta("detonated", false)

	var col := CollisionShape3D.new()
	var cyl_s := CylinderShape3D.new()
	cyl_s.radius = 0.42
	cyl_s.height = 1.18
	col.shape = cyl_s
	col.position = Vector3(0, 0.59, 0)
	body.add_child(col)

	var m_red := _std_mat(Color(0.76, 0.12, 0.09), 0.35, 0.48)
	var m_stripe := _std_mat(Color(0.92, 0.72, 0.14), 0.15, 0.55)
	var m_dark := _std_mat(Color(0.14, 0.15, 0.16), 0.75, 0.45)

	_add_cyl(body, "DrumBody", 0.38, 0.38, 1.12, Vector3(0, 0.56, 0), m_red, 14)
	_add_cyl(body, "HazardStripe", 0.39, 0.39, 0.22, Vector3(0, 0.62, 0), m_stripe, 14)
	for ry in [0.06, 0.38, 0.78, 1.08]:
		_add_cyl(body, "Rim", 0.405, 0.405, 0.045, Vector3(0, ry, 0), m_dark, 14)
	_add_cyl(body, "Cap", 0.06, 0.06, 0.05, Vector3(0.15, 1.14, 0.08), m_dark, 8)

	interact_root.add_child(body)
	active_barrels.append(body)
	return body

func _detonate_fuel_barrel(barrel: Node3D) -> void:
	if not is_instance_valid(barrel) or bool(barrel.get_meta("detonated", false)):
		return
	barrel.set_meta("detonated", true)
	var pos: Vector3 = barrel.global_position + Vector3(0, 0.6, 0)
	var ground_p := Vector3(pos.x, 0.0, pos.z)
	active_barrels.erase(barrel)
	barrel.queue_free()

	# Dramatic fireball VFX + SFX + camera shake
	VFXFactoryScript.spawn_explosion(get_tree().root, pos, Vector3.UP, 1.12)
	_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), pos, 1.12, 2.0)
	_apply_radial_blast(pos, 11.5, 360.0, 26.0, true)

	# Spawn 7.5s burning Napalm Fire Pool (damages enemies + glows white-hot in FLIR!)
	_spawn_napalm_pool(ground_p, 4.6, 7.5)

	# Staggered chain-reaction on nearby barrels & cylinders!
	_trigger_chain_detonation(pos, 8.5)

func _spawn_napalm_pool(pos: Vector3, radius: float, duration: float) -> void:
	if not interact_root:
		return
	var pool := Node3D.new()
	pool.name = "NapalmPool"
	pool.position = Vector3(pos.x, 0.04, pos.z)
	interact_root.add_child(pool)

	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 1.06
	cm.height = 0.05
	cm.radial_segments = 20
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.42, 0.08, 0.72)
	disc.mesh = cm
	disc.material_override = mat
	pool.add_child(disc)

	# Thermal FLIR Layer-3 hot glow proxy!
	var th := MeshInstance3D.new()
	th.mesh = cm
	th.layers = 4
	th.material_override = _thermal_hot_mat
	th.scale = Vector3(1.02, 1.2, 1.02)
	pool.add_child(th)

	var fire_fx := CPUParticles3D.new()
	fire_fx.amount = 38
	fire_fx.lifetime = 0.75
	fire_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire_fx.emission_sphere_radius = radius * 0.78
	fire_fx.direction = Vector3(0, 1, 0)
	fire_fx.spread = 22.0
	fire_fx.gravity = Vector3(0, 2.2, 0)
	fire_fx.initial_velocity_min = 1.4
	fire_fx.initial_velocity_max = 3.2
	var fb := SphereMesh.new(); fb.radius = 0.32; fb.height = 0.64
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.58, 0.14)
	fb.material = fm
	fire_fx.mesh = fb
	pool.add_child(fire_fx)

	var fl := OmniLight3D.new()
	fl.position = Vector3(0, 1.1, 0)
	fl.light_color = Color(1.0, 0.52, 0.16)
	fl.light_energy = 4.5
	fl.omni_range = radius * 2.8
	pool.add_child(fl)

	active_napalm_pools.append({"node": pool, "pos": pos, "radius": radius, "time_left": duration, "tick_t": 0.0, "light": fl})

func _update_napalm_pools(dt: float) -> void:
	for i in range(active_napalm_pools.size() - 1, -1, -1):
		var d: Dictionary = active_napalm_pools[i]
		d["time_left"] = float(d["time_left"]) - dt
		d["tick_t"] = float(d["tick_t"]) - dt
		var pool_n: Node3D = d["node"]
		var fl: OmniLight3D = d["light"]
		if is_instance_valid(fl):
			fl.light_energy = clampf(float(d["time_left"]) * 0.9, 0.0, 4.5) * randf_range(0.85, 1.15)
		if float(d["tick_t"]) <= 0.0:
			d["tick_t"] = 0.42
			var p: Vector3 = d["pos"]
			var rad: float = float(d["radius"])
			for e in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(e) and e is Node3D:
					var ep: Vector3 = (e as Node3D).global_position
					if Vector2(ep.x - p.x, ep.z - p.z).length() <= rad and ep.y < 2.2:
						if e.has_method("take_damage"):
							e.take_damage(26.0, false)
		if float(d["time_left"]) <= 0.0:
			if is_instance_valid(pool_n):
				pool_n.queue_free()
			active_napalm_pools.remove_at(i)

# =============================================================================
# 2. PRESSURIZED GAS / SMOKE CYLINDER (ROCKET JET OR 14s TACTICAL SMOKE CLOUD)
# =============================================================================
func spawn_gas_cylinder(pos: Vector3) -> Node3D:
	if not interact_root:
		return null
	var body := StaticBody3D.new()
	body.name = "GasCylinder"
	body.position = Vector3(pos.x, 0.0, pos.z)
	body.collision_layer = 1
	body.collision_mask = 7
	body.add_to_group("arena_shootable")
	body.set_meta("interact_kind", "gas_cylinder")
	body.set_meta("hp", 22.0)
	body.set_meta("detonated", false)

	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.24
	cs.height = 1.48
	col.shape = cs
	col.position = Vector3(0, 0.74, 0)
	body.add_child(col)

	var m_cyan := _std_mat(Color(0.16, 0.56, 0.64), 0.45, 0.36)
	var m_yel := _std_mat(Color(0.92, 0.76, 0.18), 0.20, 0.45)
	var m_brass := _std_mat(Color(0.86, 0.68, 0.22), 0.90, 0.22)

	_add_cyl(body, "TankBody", 0.20, 0.20, 1.15, Vector3(0, 0.58, 0), m_cyan, 14)
	_add_cyl(body, "Shoulder", 0.07, 0.20, 0.18, Vector3(0, 1.24, 0), m_yel, 14)
	_add_cyl(body, "ValveNeck", 0.05, 0.05, 0.12, Vector3(0, 1.38, 0), m_brass, 10)
	_add_cyl(body, "ValveWheel", 0.085, 0.085, 0.025, Vector3(0, 1.45, 0), m_brass, 10)

	interact_root.add_child(body)
	active_cylinders.append(body)
	return body

func _trigger_gas_cylinder(cyl: Node3D, hit_dir: Vector3) -> void:
	if not is_instance_valid(cyl) or bool(cyl.get_meta("detonated", false)):
		return
	cyl.set_meta("detonated", true)
	var start_pos: Vector3 = cyl.global_position
	active_cylinders.erase(cyl)
	cyl.queue_free()

	# 50% chance: pressurized runaway rocket jet (1.1s) then smoke+concussion burst!
	# 50% chance: immediate dense 14s smoke/tear-gas cloud (blinds enemies, FLIR sees right through!)
	if randf() < 0.50:
		_launch_runaway_cylinder(start_pos + Vector3(0, 0.7, 0), hit_dir)
	else:
		_spawn_smoke_gas_cloud(start_pos, 9.5, 14.0)
		_play_3d_sfx(SoundEffects.create_rpg_shot_sound(), start_pos, 1.45, -1.0)

func _launch_runaway_cylinder(start_pos: Vector3, hit_dir: Vector3) -> void:
	if not interact_root:
		return
	var r := Node3D.new()
	r.name = "RunawayGasCylinder"
	r.position = start_pos
	interact_root.add_child(r)
	var m_cyan := _std_mat(Color(0.18, 0.62, 0.70), 0.45, 0.35)
	_add_cyl(r, "FlyingTank", 0.19, 0.19, 1.15, Vector3.ZERO, m_cyan, 12, Vector3(90, 0, 0))
	var jet := CPUParticles3D.new()
	jet.amount = 36; jet.lifetime = 0.45
	jet.direction = Vector3(0, 0, 1); jet.spread = 18.0
	jet.initial_velocity_min = 6.0; jet.initial_velocity_max = 10.0
	var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.44
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color = Color(0.84, 0.90, 0.92, 0.65)
	sm.material = mat; jet.mesh = sm
	jet.position = Vector3(0, 0, 0.65)
	r.add_child(jet)

	var flat_d := Vector3(hit_dir.x, 0.08, hit_dir.z)
	if flat_d.length_squared() < 0.01:
		flat_d = Vector3(randf_range(-1, 1), 0.08, randf_range(-1, 1))
	flat_d = flat_d.normalized()
	_play_3d_sfx(SoundEffects.create_rpg_shot_sound(), start_pos, 1.55, 0.0)
	active_rockets.append({"node": r, "vel": flat_d * 24.0, "time_left": 1.05})

func _update_runaway_cylinders(dt: float) -> void:
	for i in range(active_rockets.size() - 1, -1, -1):
		var rd: Dictionary = active_rockets[i]
		var n: Node3D = rd["node"]
		rd["time_left"] = float(rd["time_left"]) - dt
		if not is_instance_valid(n):
			active_rockets.remove_at(i)
			continue
		var vel: Vector3 = rd["vel"]
		# Erratic pressurized corkscrew wobble
		vel = vel.rotated(Vector3.UP, randf_range(-1.8, 1.8) * dt)
		rd["vel"] = vel
		var next_p: Vector3 = n.position + vel * dt
		next_p.y = clampf(next_p.y, 0.35, 3.2)
		n.position = next_p
		n.look_at(next_p + vel.normalized(), Vector3.UP)
		n.rotate_z(dt * 12.0)

		var hit_enemy_close: bool = false
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and e is Node3D and (e as Node3D).global_position.distance_to(n.global_position) < 2.2:
				hit_enemy_close = true
				break
		if float(rd["time_left"]) <= 0.0 or hit_enemy_close or absf(next_p.x) > 74.0 or absf(next_p.z) > 74.0:
			var bp: Vector3 = n.global_position
			n.queue_free()
			active_rockets.remove_at(i)
			VFXFactoryScript.spawn_explosion(get_tree().root, bp, Vector3.UP, 0.72)
			_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), bp, 1.32, -2.0)
			_apply_radial_blast(bp, 7.5, 210.0, 14.0, false)
			_spawn_smoke_gas_cloud(Vector3(bp.x, 0.0, bp.z), 9.0, 14.0)

func _spawn_smoke_gas_cloud(pos: Vector3, radius: float, duration: float) -> void:
	if not interact_root:
		return
	var cloud := Node3D.new()
	cloud.name = "SmokeGasCloud"
	cloud.position = Vector3(pos.x, 1.2, pos.z)
	interact_root.add_child(cloud)

	var pfx := CPUParticles3D.new()
	pfx.amount = 46
	pfx.lifetime = 3.2
	pfx.preprocess = 1.0
	pfx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	pfx.emission_sphere_radius = radius * 0.62
	pfx.direction = Vector3(0, 0.35, 0)
	pfx.spread = 80.0
	pfx.gravity = Vector3(0, 0.12, 0)
	pfx.initial_velocity_min = 0.5
	pfx.initial_velocity_max = 1.4
	var sm := SphereMesh.new(); sm.radius = 1.65; sm.height = 3.1
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.76, 0.82, 0.78, 0.42)
	sm.material = mat
	pfx.mesh = sm
	# Layer 1 only: main camera sees thick smoke; FLIR thermal sees Layer 3 hot silhouettes right through!
	pfx.layers = 1
	cloud.add_child(pfx)

	active_smoke_clouds.append({"node": cloud, "pos": Vector3(pos.x, 0.0, pos.z), "radius": radius, "time_left": duration, "pfx": pfx})

func _update_smoke_clouds(dt: float) -> void:
	for i in range(active_smoke_clouds.size() - 1, -1, -1):
		var d: Dictionary = active_smoke_clouds[i]
		d["time_left"] = float(d["time_left"]) - dt
		var pfx: CPUParticles3D = d["pfx"]
		if float(d["time_left"]) < 3.0 and is_instance_valid(pfx):
			pfx.emitting = false
		# Disorient/slow infantry enemies standing inside tear-gas/smoke cloud!
		var cp: Vector3 = d["pos"]
		var rad: float = float(d["radius"])
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and e is CharacterBody3D:
				var ep: Vector3 = (e as Node3D).global_position
				if Vector2(ep.x - cp.x, ep.z - cp.z).length() <= rad:
					(e as CharacterBody3D).velocity.x *= 0.72
					(e as CharacterBody3D).velocity.z *= 0.72
		if float(d["time_left"]) <= 0.0:
			if is_instance_valid(d["node"]):
				(d["node"] as Node3D).queue_free()
			active_smoke_clouds.remove_at(i)

# =============================================================================
# 3. FLOODLIGHT TOWER + DIESEL GENERATOR (NIGHT LIGHTING + EMP SHOCK ON HIT!)
# =============================================================================
func spawn_floodlight_generator(pos: Vector3, yaw_deg: float) -> Node3D:
	if not interact_root:
		return null
	var body := StaticBody3D.new()
	body.name = "FloodlightGenerator"
	body.position = Vector3(pos.x, 0.0, pos.z)
	body.rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
	body.collision_layer = 1
	body.collision_mask = 7
	body.add_to_group("arena_shootable")
	body.add_to_group("arena_floodlight")
	body.set_meta("interact_kind", "floodlight_gen")
	body.set_meta("hp", 45.0)
	body.set_meta("destroyed", false)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(1.15, 1.05, 0.85)
	col.shape = bs; col.position = Vector3(0, 0.52, 0)
	body.add_child(col)

	var m_gen := _std_mat(Color(0.76, 0.56, 0.14), 0.38, 0.52)
	var m_steel := _std_mat(Color(0.22, 0.24, 0.26), 0.82, 0.38)
	var m_bulb := StandardMaterial3D.new()
	m_bulb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_bulb.albedo_color = Color(1.0, 0.96, 0.82)

	var gen_box: MeshInstance3D = _add_box(body, "GeneratorBox", Vector3(1.05, 0.78, 0.72), Vector3(0, 0.39, 0), m_gen)
	# Warm diesel generator visible in FLIR thermal!
	var th := MeshInstance3D.new()
	th.mesh = gen_box.mesh
	th.layers = 4
	th.scale = Vector3(1.02, 1.02, 1.02)
	var warm_m := StandardMaterial3D.new()
	warm_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	warm_m.albedo_color = Color(0.82, 0.0, 1.0, 1.0)
	th.material_override = warm_m
	gen_box.add_child(th)

	_add_cyl(body, "Mast", 0.055, 0.075, 4.6, Vector3(0, 2.5, 0), m_steel, 8)
	_add_box(body, "CrossBar", Vector3(1.1, 0.08, 0.08), Vector3(0, 4.78, 0), m_steel)
	var lamps_node := Node3D.new()
	lamps_node.name = "LampHeads"
	lamps_node.position = Vector3(0, 4.82, 0)
	body.add_child(lamps_node)
	for lx in [-0.36, 0.36]:
		_add_box(lamps_node, "LampHousing", Vector3(0.32, 0.22, 0.16), Vector3(lx, 0, 0), m_steel, Vector3(-24, 0, 0))
		var lens := _add_box(lamps_node, "LampLens", Vector3(0.26, 0.16, 0.03), Vector3(lx, -0.02, -0.08), m_bulb, Vector3(-24, 0, 0))
		lens.name = "LampLens"

	var spot := SpotLight3D.new()
	spot.name = "FloodSpot"
	spot.position = Vector3(0, 4.75, -0.15)
	spot.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	spot.light_color = Color(1.0, 0.94, 0.78)
	spot.light_energy = 11.0
	spot.spot_range = 46.0
	spot.spot_angle = 48.0
	spot.visible = false
	body.add_child(spot)

	var halo := OmniLight3D.new()
	halo.name = "FloodHalo"
	halo.position = Vector3(0, 4.5, -0.5)
	halo.light_color = Color(1.0, 0.92, 0.74)
	halo.light_energy = 2.6
	halo.omni_range = 14.0
	halo.visible = false
	body.add_child(halo)

	# Helper closure via metadata + method-less helper on manager
	body.set_meta("spot", spot)
	body.set_meta("halo", halo)
	interact_root.add_child(body)
	active_floodlights.append(body)
	return body

func set_all_floodlights_powered(powered: bool) -> void:
	for fl in active_floodlights:
		if not is_instance_valid(fl) or bool(fl.get_meta("destroyed", false)):
			continue
		var sp: SpotLight3D = fl.get_meta("spot", null) as SpotLight3D
		var hl: OmniLight3D = fl.get_meta("halo", null) as OmniLight3D
		if sp: sp.visible = powered
		if hl: hl.visible = powered

func _sync_floodlight_power_with_env() -> void:
	var envs := get_tree().get_nodes_in_group("environment_controller")
	var want_on: bool = false
	if envs.size() > 0:
		var ec: Node = envs[0]
		want_on = bool(ec.get("is_night_wave")) or str(ec.get("current_weather")) in ["fog", "storm"]
	set_all_floodlights_powered(want_on)

func _short_circuit_floodlight(gen: Node3D) -> void:
	if not is_instance_valid(gen) or bool(gen.get_meta("destroyed", false)):
		return
	gen.set_meta("destroyed", true)
	var pos: Vector3 = gen.global_position + Vector3(0, 0.7, 0)
	var sp: SpotLight3D = gen.get_meta("spot", null) as SpotLight3D
	var hl: OmniLight3D = gen.get_meta("halo", null) as OmniLight3D
	if sp: sp.visible = false
	if hl: hl.visible = false
	active_floodlights.erase(gen)

	# Electric EMP arc flash + crackling burst + stun nearby enemies & fry drones!
	var emp_light := OmniLight3D.new()
	emp_light.position = pos
	emp_light.light_color = Color(0.28, 0.72, 1.0)
	emp_light.light_energy = 14.0
	emp_light.omni_range = 18.0
	get_tree().root.add_child(emp_light)
	var tw := emp_light.create_tween()
	tw.tween_property(emp_light, "light_energy", 0.0, 0.45)
	tw.tween_callback(emp_light.queue_free)

	var sparks := CPUParticles3D.new()
	sparks.position = pos
	sparks.one_shot = true; sparks.explosiveness = 0.92; sparks.amount = 42; sparks.lifetime = 0.65
	sparks.spread = 180.0; sparks.initial_velocity_min = 4.0; sparks.initial_velocity_max = 12.0
	var sb := BoxMesh.new(); sb.size = Vector3(0.08, 0.08, 0.24)
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.35, 0.85, 1.0); sb.material = sm
	sparks.mesh = sb
	get_tree().root.add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(0.9).timeout.connect(func(): if is_instance_valid(sparks): sparks.queue_free())

	_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), pos, 1.65, -3.0)

	# EMP Shock damages & stuns nearby enemies (instantly fries Shahed drones!)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e is Node3D:
			var d: float = (e as Node3D).global_position.distance_to(pos)
			if d <= 12.0:
				if e.has_method("take_damage"):
					var dmg: float = 95.0 if ("prop_node" in e) else 45.0
					e.take_damage(dmg, false)
				if e is CharacterBody3D:
					(e as CharacterBody3D).velocity = Vector3.ZERO
	# Remove wrecked tower after short delay so sector goes dark
	gen.queue_free()

# =============================================================================
# 4. PARACHUTE AIRDROPS: LOOT CRATE [E] & SUPPLY PALLET (LIVE REPLENISHMENT!)
# =============================================================================
func spawn_parachute_drop(land_pos: Vector3, drop_mode: String = "loot", include_dshk: bool = false, include_flood: bool = false) -> Node3D:
	if not interact_root:
		return null
	var root := Node3D.new()
	root.name = "Airdrop_" + drop_mode
	root.position = Vector3(land_pos.x, 38.0, land_pos.z)
	interact_root.add_child(root)

	var is_loot: bool = (drop_mode == "loot")
	var m_crate := _std_mat(Color(0.22, 0.34, 0.18) if is_loot else Color(0.46, 0.34, 0.20), 0.25, 0.65)
	var m_trim := _std_mat(Color(0.88, 0.72, 0.26) if is_loot else Color(0.24, 0.26, 0.28), 0.75, 0.38)
	var m_chute := _std_mat(Color(0.92, 0.90, 0.84) if is_loot else Color(0.42, 0.46, 0.34), 0.05, 0.88)

	if is_loot:
		_add_box(root, "CrateBody", Vector3(1.25, 0.82, 0.92), Vector3(0, 0.41, 0), m_crate)
		_add_box(root, "CrateBandL", Vector3(0.10, 0.86, 0.96), Vector3(-0.38, 0.41, 0), m_trim)
		_add_box(root, "CrateBandR", Vector3(0.10, 0.86, 0.96), Vector3(0.38, 0.41, 0), m_trim)
		_add_box(root, "CrateLid", Vector3(1.30, 0.12, 0.98), Vector3(0, 0.84, 0), m_trim)
	else:
		# Supply Pallet visual with miniature strapped barrels!
		_add_box(root, "PalletBase", Vector3(1.85, 0.14, 1.55), Vector3(0, 0.07, 0), m_crate)
		var m_red := _std_mat(Color(0.76, 0.12, 0.09), 0.35, 0.48)
		_add_cyl(root, "PalletDrum1", 0.32, 0.32, 0.92, Vector3(-0.42, 0.60, -0.22), m_red, 10)
		_add_cyl(root, "PalletDrum2", 0.32, 0.32, 0.92, Vector3(0.42, 0.60, 0.22), m_red, 10)

	# Billowing 3D Parachute Canopy + Suspension Ropes
	var chute := Node3D.new()
	chute.name = "Parachute"
	chute.position = Vector3(0, 4.4, 0)
	root.add_child(chute)
	var dome := MeshInstance3D.new()
	var spm := SphereMesh.new(); spm.radius = 2.6; spm.height = 2.2; spm.is_hemisphere = true
	dome.mesh = spm; dome.material_override = m_chute
	chute.add_child(dome)
	for rx in [-1.4, 1.4]:
		for rz in [-1.4, 1.4]:
			var rope_pos := Vector3(rx * 0.45, -1.8, rz * 0.45)
			_add_cyl(chute, "Rope", 0.014, 0.014, 3.8, rope_pos, m_trim, 5, Vector3(rz * 12.0, 0.0, -rx * 12.0))

	# Signal Flare + Rising Colored Smoke Beacon!
	var flare_col := Color(0.98, 0.72, 0.18) if is_loot else Color(0.24, 0.85, 0.44)
	var flare_light := OmniLight3D.new()
	flare_light.position = Vector3(0, 1.2, 0)
	flare_light.light_color = flare_col
	flare_light.light_energy = 5.5
	flare_light.omni_range = 16.0
	root.add_child(flare_light)

	var smoke := CPUParticles3D.new()
	smoke.position = Vector3(0, 0.9, 0)
	smoke.amount = 28; smoke.lifetime = 2.6
	smoke.direction = Vector3(0.15, 1.0, 0.1); smoke.spread = 14.0
	smoke.gravity = Vector3(0, 0.6, 0)
	smoke.initial_velocity_min = 2.6; smoke.initial_velocity_max = 4.2
	var sm := SphereMesh.new(); sm.radius = 0.42; sm.height = 0.84
	var smat := StandardMaterial3D.new(); smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(flare_col.r, flare_col.g, flare_col.b, 0.42)
	sm.material = smat; smoke.mesh = sm
	root.add_child(smoke)

	active_airdrops.append({
		"node": root, "chute": chute, "smoke": smoke, "light": flare_light,
		"mode": drop_mode, "landed": false, "opened": false,
		"include_dshk": include_dshk, "include_flood": include_flood,
		"sway_t": randf_range(0.0, TAU)
	})
	_notify_hud_toast("🪂 СБРОС AIRDROP: %s!" % ("ЯЩИК С ЛУТОМ (ИЩИТЕ ЖЁЛТЫЙ ДЫМ)" if is_loot else "ПАЛЕТА СНАБЖЕНИЯ НА АРЕНУ"))
	return root

func _update_airdrops(dt: float) -> void:
	for i in range(active_airdrops.size() - 1, -1, -1):
		var d: Dictionary = active_airdrops[i]
		var n: Node3D = d["node"]
		if not is_instance_valid(n):
			active_airdrops.remove_at(i)
			continue
		if not bool(d["landed"]):
			d["sway_t"] = float(d["sway_t"]) + dt * 2.2
			n.position.y -= 7.2 * dt
			n.rotation.z = sin(float(d["sway_t"])) * 0.12
			if n.position.y <= 0.0:
				n.position.y = 0.0
				n.rotation = Vector3.ZERO
				d["landed"] = true
				var ch: Node3D = d["chute"]
				if is_instance_valid(ch):
					ch.visible = false
				_play_3d_sfx(SoundEffects.create_heavy_armor_equip_sound(), n.global_position, 0.78, 1.0)
				if str(d["mode"]) == "supply_pallet":
					_unpack_supply_pallet(n.global_position, bool(d["include_dshk"]), bool(d["include_flood"]))
					n.queue_free()
					active_airdrops.remove_at(i)

func _unpack_supply_pallet(center: Vector3, include_dshk: bool, include_flood: bool) -> void:
	_prune_invalid()
	var offsets := [Vector3(-1.6, 0, -1.0), Vector3(1.6, 0, -1.0), Vector3(0.0, 0, 1.7)]
	for k in range(offsets.size()):
		var p: Vector3 = center + offsets[k]
		if k < 2 and active_barrels.size() < MAX_BARRELS:
			spawn_fuel_barrel(p)
		elif k == 2 and active_cylinders.size() < MAX_CYLINDERS:
			spawn_gas_cylinder(p)
	if include_dshk and active_dshks.size() < MAX_DSHK:
		spawn_mounted_dshk(center + Vector3(0, 0, -2.8), rad_to_deg(atan2(center.x, center.z)))
	elif include_flood and active_floodlights.size() < MAX_FLOODLIGHTS:
		spawn_floodlight_generator(center + Vector3(0, 0, -2.4), rad_to_deg(atan2(-center.x, -center.z)))
		_sync_floodlight_power_with_env()

func _open_loot_airdrop(d: Dictionary, player: Node) -> void:
	if bool(d["opened"]):
		return
	d["opened"] = true
	var n: Node3D = d["node"]
	var reward_parts: Array[String] = []

	# 1) Dollars reward ($120..$220)
	var cash: int = randi_range(120, 220)
	if player.has_method("add_money"):
		player.add_money(cash)
	reward_parts.append("+$%d" % cash)

	# 2) Reserve ammo for current weapon + chance for FREE unowned weapon mod!
	var wm = player.weapon_manager if ("weapon_manager" in player) else null
	if wm and wm.current_weapon:
		var cw: Weapon = wm.current_weapon
		if cw.ammo_type != "":
			var bonus_ammo: int = maxi(2, cw.mag_size) if not cw.is_rpg else 2
			wm.add_reserve_ammo_by_type(cw.get_active_ammo_pool_key(), bonus_ammo)
			reward_parts.append("+%d патр." % bonus_ammo)
		# Grant one random unowned mod for current weapon if available!
		var unowned_mods: Array = []
		for sd in WeaponModDBScript.get_slot_defs(cw.weapon_id):
			for m in WeaponModDBScript.get_mods_for_slot(cw.weapon_id, str(sd["slot_type"])):
				if not cw.is_mod_owned(m.id) and m.price > 0:
					unowned_mods.append(m)
		if unowned_mods.size() > 0:
			var picked = unowned_mods[randi() % unowned_mods.size()]
			cw.mark_mod_owned(picked.id)
			reward_parts.append("Модуль: %s (в Верстаке!)" % picked.short_name)

	# 3) Field Medkit (+35 HP) or Vodka if full HP
	if "health" in player and "max_health" in player and float(player.health) < float(player.max_health) - 5.0:
		if player.has_method("add_health"):
			player.add_health(35.0)
			reward_parts.append("+35 HP")
	elif "vodka_count" in player and int(player.vodka_count) < 3 and player.has_method("add_vodka"):
		if player.add_vodka():
			reward_parts.append("+1 Чекунец 67")

	_play_3d_sfx(SoundEffects.create_buy_sound(), n.global_position, 1.0, 2.0)
	_notify_hud_toast("📦 AIRDROP: " + "  |  ".join(reward_parts))
	active_airdrops.erase(d)
	if is_instance_valid(n):
		n.queue_free()

# =============================================================================
# 5. MOUNTED 12.7mm DShKM HEAVY MACHINE GUN ON SANDBAG EMPLACEMENT ([E])
# =============================================================================
func spawn_mounted_dshk(pos: Vector3, yaw_deg: float) -> Node3D:
	if not interact_root:
		return null
	var root := Node3D.new()
	root.name = "MountedDShK"
	root.position = Vector3(pos.x, 0.0, pos.z)
	root.rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
	interact_root.add_child(root)

	# Destructible sandbag cover collider
	var sb_body := StaticBody3D.new()
	sb_body.name = "SandbagBody"
	sb_body.collision_layer = 1
	sb_body.collision_mask = 7
	sb_body.add_to_group("arena_shootable")
	sb_body.set_meta("interact_kind", "dshk_cover")
	sb_body.set_meta("dshk_root", root)
	root.add_child(sb_body)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(2.4, 1.05, 0.72)
	col.shape = bs; col.position = Vector3(0, 0.52, -0.78)
	sb_body.add_child(col)

	var m_bag := _std_mat(Color(0.56, 0.49, 0.34), 0.05, 0.92)
	var m_gun := _std_mat(Color(0.14, 0.15, 0.16), 0.84, 0.34)
	var m_barrel := _std_mat(Color(0.18, 0.19, 0.21), 0.88, 0.28)
	var m_od := _std_mat(Color(0.22, 0.30, 0.17), 0.35, 0.58)

	# 3-tier sandbag bunker arc
	for tier in range(3):
		for bi in range(-2, 3):
			var ang: float = float(bi) * 0.26
			var bpos := Vector3(sin(ang) * 1.15, 0.17 + float(tier) * 0.30, -cos(ang) * 0.92)
			_add_box(sb_body, "Bag_%d_%d" % [tier, bi], Vector3(0.56, 0.28, 0.34), bpos, m_bag, Vector3(0, -rad_to_deg(ang), 0))

	# Tripod legs
	_add_cyl(root, "TripodPost", 0.05, 0.06, 1.12, Vector3(0, 0.62, -0.20), m_gun, 10)
	for lx in [-0.45, 0.45]:
		_add_cyl(root, "Leg", 0.03, 0.03, 1.05, Vector3(lx * 0.5, 0.45, 0.15), m_gun, 8, Vector3(28, 0, -lx * 40.0))

	# Rotating Gun Swivel Pivot (Yaw + Pitch)
	var gun_pivot := Node3D.new()
	gun_pivot.name = "GunPivot"
	gun_pivot.position = Vector3(0, 1.24, -0.20)
	root.add_child(gun_pivot)

	_add_box(gun_pivot, "Receiver", Vector3(0.14, 0.16, 0.66), Vector3(0, 0, -0.10), m_gun)
	_add_box(gun_pivot, "GunShield", Vector3(0.56, 0.42, 0.03), Vector3(0, 0.10, -0.34), m_od)
	_add_box(gun_pivot, "AmmoBox", Vector3(0.18, 0.22, 0.26), Vector3(-0.18, -0.02, -0.10), m_od)
	var barrel_mi := _add_cyl(gun_pivot, "HeavyBarrel", 0.028, 0.034, 0.98, Vector3(0, 0.02, -0.88), m_barrel, 12, Vector3(-90, 0, 0))
	_add_box(gun_pivot, "MuzzleBrake", Vector3(0.085, 0.055, 0.14), Vector3(0, 0.02, -1.42), m_gun)
	# Spade grips at rear
	for sx in [-0.075, 0.075]:
		_add_cyl(gun_pivot, "SpadeGrip", 0.015, 0.015, 0.15, Vector3(sx, -0.01, 0.28), m_gun, 8)
	var muzzle := Marker3D.new()
	muzzle.name = "DShKMuzzle"
	muzzle.position = Vector3(0, 0.02, -1.52)
	gun_pivot.add_child(muzzle)

	var stand_marker := Marker3D.new()
	stand_marker.name = "GunnerStand"
	stand_marker.position = Vector3(0, 0.0, 0.72)
	root.add_child(stand_marker)

	root.set_meta("hp", 420.0)
	root.set_meta("max_hp", 420.0)
	root.set_meta("heat", 0.0)
	root.set_meta("overheated", false)
	root.set_meta("fire_cd", 0.0)
	root.set_meta("gun_pivot", gun_pivot)
	root.set_meta("muzzle", muzzle)
	root.set_meta("stand_marker", stand_marker)
	root.set_meta("barrel_mat", m_barrel)
	root.set_meta("barrel_mi", barrel_mi)

	active_dshks.append(root)
	return root

func _update_dshks(dt: float) -> void:
	for i in range(active_dshks.size() - 1, -1, -1):
		var dshk: Node3D = active_dshks[i]
		if not is_instance_valid(dshk):
			active_dshks.remove_at(i)
			continue
		var heat: float = float(dshk.get_meta("heat", 0.0))
		var overheated: bool = bool(dshk.get_meta("overheated", false))
		var fire_cd: float = maxf(0.0, float(dshk.get_meta("fire_cd", 0.0)) - dt)
		dshk.set_meta("fire_cd", fire_cd)

		# Cool barrel continuously
		var cool_rate: float = 0.28 if overheated else 0.22
		heat = maxf(0.0, heat - cool_rate * dt)
		if overheated and heat <= 0.20:
			overheated = false
		dshk.set_meta("heat", heat)
		dshk.set_meta("overheated", overheated)

		var bmat: StandardMaterial3D = dshk.get_meta("barrel_mat", null) as StandardMaterial3D
		if bmat:
			bmat.emission_enabled = heat > 0.25
			if heat > 0.25:
				bmat.emission = Color(1.0, 0.28, 0.04)
				bmat.emission_energy_multiplier = (heat - 0.25) * 4.0

		var mp = dshk.get_meta("mounted_player") if dshk.has_meta("mounted_player") else null
		if mp != null and is_instance_valid(mp):
			var piv: Node3D = dshk.get_meta("gun_pivot", null) as Node3D
			var cam: Camera3D = mp.camera if ("camera" in mp) else null
			if piv and cam:
				# Align DShK gun barrel smoothly toward player's camera look direction
				var look_pt: Vector3 = cam.global_position - cam.global_transform.basis.z * 35.0
				var local_t: Vector3 = dshk.to_local(look_pt) - piv.position
				var tyaw: float = clampf(atan2(-local_t.x, -local_t.z), deg_to_rad(-78.0), deg_to_rad(78.0))
				var horiz_d: float = maxf(0.1, Vector2(local_t.x, local_t.z).length())
				var tpitch: float = clampf(atan2(local_t.y, horiz_d), deg_to_rad(-20.0), deg_to_rad(42.0))
				piv.rotation.y = lerpf(piv.rotation.y, tyaw, dt * 18.0)
				piv.rotation.x = lerpf(piv.rotation.x, tpitch, dt * 18.0)

			# Fire 12.7mm heavy rounds while LMB held!
			var hud_open: bool = ("hud" in mp and mp.hud != null and mp.hud.has_method("is_any_menu_open") and mp.hud.is_any_menu_open())
			if Input.is_action_pressed("shoot") and not hud_open and not overheated and fire_cd <= 0.0:
				_fire_dshk_shot(dshk, mp)

func _fire_dshk_shot(dshk: Node3D, player: Node) -> void:
	dshk.set_meta("fire_cd", 0.112) # ~535 RPM heavy thump
	var heat: float = minf(1.0, float(dshk.get_meta("heat", 0.0)) + 0.045)
	dshk.set_meta("heat", heat)
	if heat >= 1.0:
		dshk.set_meta("overheated", true)
		_notify_hud_toast("🔥 ДШКМ ПЕРЕГРЕТ — ОХЛАЖДЕНИЕ СТВОЛА!")

	var piv: Node3D = dshk.get_meta("gun_pivot", null) as Node3D
	var muz: Marker3D = dshk.get_meta("muzzle", null) as Marker3D
	var cam: Camera3D = player.camera if ("camera" in player) else null
	if not cam or not muz:
		return

	_play_3d_sfx(SoundEffects.create_pkm_sound(), muz.global_position, randf_range(0.68, 0.76), 5.0)
	if player.has_method("add_camera_recoil"):
		player.add_camera_recoil(0.018, randf_range(-0.009, 0.009))
	if player.has_method("add_camera_shake"):
		player.add_camera_shake(0.025)

	# Heavy 12.7mm AP raycast (78 damage, 1.8x armor pen!)
	var space_state: PhysicsDirectSpaceState3D = cam.get_world_3d().direct_space_state
	var fwd: Vector3 = (-cam.global_transform.basis.z + cam.global_transform.basis.x * randf_range(-0.012, 0.012) + cam.global_transform.basis.y * randf_range(-0.012, 0.012)).normalized()
	var r_orig: Vector3 = cam.global_position + fwd * 0.65
	var r_end: Vector3 = r_orig + fwd * 140.0
	var excl: Array[RID] = []
	if player is CollisionObject3D:
		excl.append((player as CollisionObject3D).get_rid())
	var q := PhysicsRayQueryParameters3D.create(r_orig, r_end)
	q.exclude = excl
	q.collide_with_bodies = true
	var res := space_state.intersect_ray(q)
	var hit_p: Vector3 = r_end
	if not res.is_empty():
		hit_p = res.position
		var col: Object = res.collider
		var wm = player.weapon_manager if ("weapon_manager" in player) else null
		if col and col.is_in_group("arena_shootable"):
			on_bullet_hit_interactable(col as Node3D, 78.0, hit_p, fwd)
		elif col and col.is_in_group("enemy_shield"):
			# 12.7mm heavy DShK punches straight through ballistic shields for 65% damage!
			var sh_o = col.get_meta("shield_owner") if col.has_meta("shield_owner") else null
			if is_instance_valid(sh_o) and sh_o.has_method("take_damage"):
				sh_o.take_damage(78.0 * 0.65, false)
				if wm: wm.hit_enemy.emit()
		elif col and col.is_in_group("mi24_hitbox"):
			var mo = col.get_meta("mi24_owner") if col.has_meta("mi24_owner") else null
			var zm: String = str(col.get_meta("hit_zone")) if col.has_meta("hit_zone") else "hull"
			if is_instance_valid(mo) and mo.has_method("on_bullet_hit"):
				if mo.on_bullet_hit(zm, 78.0 * 1.8, 1.8, hit_p, res.normal) and wm:
					wm.hit_enemy.emit()
		elif col and col.is_in_group("tiger_hitbox"):
			var to = col.get_meta("tiger_owner", null)
			var zid: String = str(col.get_meta("hit_zone", ""))
			if is_instance_valid(to) and to.has_method("on_bullet_hit"):
				if to.on_bullet_hit(zid, 78.0 * 1.8, hit_p, res.normal) and wm:
					wm.hit_enemy.emit()
		elif col and col.is_in_group("black_van_hitbox"):
			var vo = col.get_meta("van_owner", null)
			var zv: String = str(col.get_meta("hit_zone", ""))
			if is_instance_valid(vo) and vo.has_method("on_bullet_hit"):
				if vo.on_bullet_hit(zv, 78.0 * 1.8, hit_p, res.normal) and wm:
					wm.hit_enemy.emit()
		elif col and col.is_in_group("enemy") and col.has_method("take_damage"):
			col.take_damage(78.0, false)
			if wm: wm.hit_enemy.emit()
	var wm2 = player.weapon_manager if ("weapon_manager" in player) else null
	if wm2 and wm2.has_method("spawn_tracer"):
		wm2.spawn_tracer(muz.global_position, hit_p)

func damage_dshk(dshk: Node3D, dmg: float) -> void:
	if not is_instance_valid(dshk):
		return
	var hp: float = float(dshk.get_meta("hp", 420.0)) - dmg
	dshk.set_meta("hp", hp)
	if hp <= 0.0:
		var mp = dshk.get_meta("mounted_player") if dshk.has_meta("mounted_player") else null
		if mp != null and is_instance_valid(mp) and mp.has_method("dismount_turret"):
			mp.dismount_turret()
		var p: Vector3 = dshk.global_position + Vector3(0, 0.8, 0)
		active_dshks.erase(dshk)
		dshk.queue_free()
		VFXFactoryScript.spawn_explosion(get_tree().root, p, Vector3.UP, 0.75)
		_play_3d_sfx(SoundEffects.create_rpg_explosion_sound(), p, 1.15, -2.0)
		_notify_hud_toast("💥 СТАЦИОНАРНЫЙ ДШКМ УНИЧТОЖЕН!")

# =============================================================================
# PUBLIC HIT & [E] INTERACTION API
# =============================================================================
func on_bullet_hit_interactable(collider: Node3D, dmg: float, _hit_pos: Vector3, ray_dir: Vector3) -> bool:
	if not is_instance_valid(collider) or not collider.is_in_group("arena_shootable"):
		return false
	var kind: String = str(collider.get_meta("interact_kind", ""))
	if kind == "enemy_turret":
		if collider.has_method("take_damage"):
			collider.take_damage(dmg, false)
		return true
	if kind == "dshk_cover":
		var dr: Node3D = collider.get_meta("dshk_root", null) as Node3D
		if is_instance_valid(dr):
			damage_dshk(dr, dmg * 0.45)
		return true
	var hp: float = float(collider.get_meta("hp", 30.0)) - dmg
	collider.set_meta("hp", hp)
	if hp <= 0.0:
		match kind:
			"fuel_barrel":
				_detonate_fuel_barrel(collider)
			"gas_cylinder":
				_trigger_gas_cylinder(collider, ray_dir)
			"floodlight_gen":
				_short_circuit_floodlight(collider)
	return true

func get_nearby_interact_prompt(player_pos: Vector3, mounted_dshk: Node3D = null) -> String:
	if is_instance_valid(mounted_dshk):
		var heat_pct: int = int(round(float(mounted_dshk.get_meta("heat", 0.0)) * 100.0))
		var ov: String = " [ПЕРЕГРЕВ!]" if bool(mounted_dshk.get_meta("overheated", false)) else ""
		var hp_pct: int = int(round((float(mounted_dshk.get_meta("hp", 420.0)) / float(mounted_dshk.get_meta("max_hp", 420.0))) * 100.0))
		return "🔫 ДШКМ 12.7мм  |  Нагрев: %d%%%s  |  Прочность: %d%%  |  [ЛКМ] Огонь   [E] Выйти" % [heat_pct, ov, hp_pct]

	for d in active_airdrops:
		if bool(d["landed"]) and not bool(d["opened"]) and str(d["mode"]) == "loot" and is_instance_valid(d["node"]):
			if (d["node"] as Node3D).global_position.distance_to(player_pos) <= 3.4:
				return "📦 [E] ОТКРЫТЬ ЯЩИК AIRDROP"

	for dshk in active_dshks:
		if is_instance_valid(dshk) and dshk.global_position.distance_to(player_pos) <= 3.1:
			return "🔫 [E] ВСТАТЬ ЗА СТАЦИОНАРНЫЙ ДШКМ (12.7мм)"
	return ""

func try_interact(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	if "mounted_turret" in player and is_instance_valid(player.mounted_turret):
		player.dismount_turret()
		return true

	var ppos: Vector3 = (player as Node3D).global_position
	for d in active_airdrops:
		if bool(d["landed"]) and not bool(d["opened"]) and str(d["mode"]) == "loot" and is_instance_valid(d["node"]):
			if (d["node"] as Node3D).global_position.distance_to(ppos) <= 3.4:
				_open_loot_airdrop(d, player)
				return true

	for dshk in active_dshks:
		if is_instance_valid(dshk) and dshk.global_position.distance_to(ppos) <= 3.1:
			if player.has_method("mount_turret"):
				player.mount_turret(dshk)
				return true
	return false

# =============================================================================
# SHARED HELPERS (BLAST, CHAIN REACTION, GEOMETRY, SAFE PLACEMENT)
# =============================================================================
func _trigger_chain_detonation(origin: Vector3, radius: float) -> void:
	for b in active_barrels.duplicate():
		if is_instance_valid(b) and not bool(b.get_meta("detonated", false)) and b.global_position.distance_to(origin) <= radius:
			var b_ref: Node3D = b
			get_tree().create_timer(0.16).timeout.connect(func(): _detonate_fuel_barrel(b_ref))
	for c in active_cylinders.duplicate():
		if is_instance_valid(c) and not bool(c.get_meta("detonated", false)) and c.global_position.distance_to(origin) <= radius:
			var c_ref: Node3D = c
			var dir: Vector3 = (c.global_position - origin).normalized()
			get_tree().create_timer(0.14).timeout.connect(func(): _trigger_gas_cylinder(c_ref, dir))

func _apply_radial_blast(origin: Vector3, radius: float, max_enemy_dmg: float, max_player_dmg: float, hit_vehicles: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not (e is Node3D):
			continue
		var dist: float = (e as Node3D).global_position.distance_to(origin)
		if dist <= radius:
			var falloff: float = clampf(1.0 - (dist / radius) * 0.72, 0.25, 1.0)
			if hit_vehicles and e.has_method("on_rpg_hit"):
				e.on_rpg_hit(origin, max_enemy_dmg * falloff, "standard")
			elif e.has_method("take_damage"):
				e.take_damage(max_enemy_dmg * falloff, false)
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node3D:
			var dp: float = (p as Node3D).global_position.distance_to(origin)
			if dp <= radius:
				var pf: float = clampf(1.0 - dp / radius, 0.0, 1.0)
				if p.has_method("take_damage") and max_player_dmg * pf > 2.0:
					p.take_damage(max_player_dmg * pf)
				if p.has_method("add_camera_shake"):
					p.add_camera_shake(0.12 * pf)

func _prune_invalid() -> void:
	active_barrels = active_barrels.filter(func(x): return is_instance_valid(x))
	active_cylinders = active_cylinders.filter(func(x): return is_instance_valid(x))
	active_floodlights = active_floodlights.filter(func(x): return is_instance_valid(x))
	active_dshks = active_dshks.filter(func(x): return is_instance_valid(x))

func _find_open_arena_point(rng: RandomNumberGenerator, min_r: float, max_r: float, min_sep: float) -> Vector3:
	for _attempt in range(36):
		var ang: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(min_r, max_r)
		var cand := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		if _is_point_clear(cand, min_sep):
			return cand
	return Vector3(min_r + 2.0, 0.0, 0.0)

func _nudge_clear_point(base_p: Vector3) -> Vector3:
	if _is_point_clear(base_p, 3.0):
		return base_p
	for a in range(12):
		var ang: float = float(a) * (TAU / 12.0)
		var cand := base_p + Vector3(cos(ang) * 4.5, 0.0, sin(ang) * 4.5)
		if _is_point_clear(cand, 2.5):
			return cand
	return base_p

func _is_point_clear(p: Vector3, min_sep: float) -> bool:
	if absf(p.x) > 64.0 or absf(p.z) > 64.0:
		return false
	for aabb in MapObstacles.obstacle_aabbs:
		if aabb.grow(1.6).has_point(Vector3(p.x, 0.5, p.z)):
			return false
	for arr in [active_barrels, active_cylinders, active_floodlights, active_dshks]:
		for item in arr:
			if is_instance_valid(item) and (item as Node3D).global_position.distance_to(p) < min_sep:
				return false
	return true

func _notify_hud_toast(msg: String) -> void:
	if not is_inside_tree():
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].get_node_or_null("HUD"):
		var hud = players[0].get_node("HUD")
		if hud.has_method("show_arena_toast"):
			hud.show_arena_toast(msg)

func _play_3d_sfx(stream: AudioStream, pos: Vector3, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not stream or not is_inside_tree():
		return
	var ap := AudioStreamPlayer3D.new()
	ap.bus = "SFX"
	ap.stream = stream
	ap.pitch_scale = pitch
	ap.volume_db = vol_db
	ap.max_distance = 110.0
	ap.unit_size = 14.0
	ap.position = pos
	get_tree().root.add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

static func _std_mat(col: Color, met: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col; m.metallic = met; m.roughness = rough
	return m

static func _add_box(parent: Node3D, nm: String, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = nm
	var bm := BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.material_override = mat; mi.position = pos
	if rot_deg != Vector3.ZERO: mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, nm: String, tr: float, br: float, h: float, pos: Vector3, mat: Material, segs: int = 12, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = nm
	var cm := CylinderMesh.new(); cm.top_radius = tr; cm.bottom_radius = br; cm.height = h; cm.radial_segments = segs
	mi.mesh = cm; mi.material_override = mat; mi.position = pos
	if rot_deg != Vector3.ZERO: mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi
