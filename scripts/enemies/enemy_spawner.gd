extends Node3D

const TigerTankScript = preload("res://scripts/enemies/tiger_tank.gd")
const Mi24BossScript = preload("res://scripts/enemies/mi24_boss.gd")
const BlackMinivanScript = preload("res://scripts/enemies/black_minivan.gd")
const BOSS_WAVE: int = 5
const MI24_BOSS_WAVE: int = 10

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var drone_scene: PackedScene = preload("res://scenes/drone_enemy.tscn")
@export var beacon_scene: PackedScene = preload("res://scenes/spawn_beacon.tscn")
@export var spawn_points: Array[Node3D] = []

var current_wave: int = 1
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_warming_up: bool = false
var warmup_time_left: float = 10.0
var is_warmup_paused: bool = false
var spawn_timer: float = 0.0

var force_boss_next_wave: bool = false
var tiger_queued_for_current_wave: bool = false
var force_mi24_next_wave: bool = false
var mi24_queued_for_current_wave: bool = false

var player: CharacterBody3D = null
var active_beacons: Array[Node3D] = []
var minivan_shop: Node3D = null

# Map: Node3D (spawn point) -> Array[int] (enemy types to spawn at this point)
var spawn_point_assignments: Dictionary = {}
var wave_intel_text: String = ""

func _ready() -> void:
	add_to_group("enemy_spawner")
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	minivan_shop = get_parent().get_node_or_null("MinivanShop")
	if not minivan_shop:
		var vans = get_tree().get_nodes_in_group("minivan_shop")
		if vans.size() > 0:
			minivan_shop = vans[0]
		
	# Find spawn points from procedural map or scene children
	if spawn_points.is_empty():
		var proc_maps = get_tree().get_nodes_in_group("procedural_map")
		if proc_maps.size() > 0 and proc_maps[0].has_method("get_spawn_points"):
			spawn_points = proc_maps[0].get_spawn_points()
		if spawn_points.is_empty():
			for child in get_children():
				if child is Marker3D or child is Node3D:
					spawn_points.append(child)
				
	var initial_wave: int = 1
	if GlobalSettings:
		initial_wave = GlobalSettings.last_wave
	prepare_wave(initial_wave)

func _process(delta: float) -> void:
	if is_warming_up:
		# Intermission break is infinite until [F] is pressed
		return

	if not is_wave_active:
		return
		
	var actual_alive: int = get_alive_enemy_count()
	enemies_alive = actual_alive
	update_enemy_count_hud()
		
	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = randf_range(0.8, 1.8)
			spawn_next_enemy()
			enemies_to_spawn -= 1
			update_enemy_count_hud()
	elif actual_alive <= 0:
		# Wave clear! Clean up leftover engineer turrets, trigger parachute logistics & next wave
		is_wave_active = false
		update_enemy_count_hud()
		for tur in get_tree().get_nodes_in_group("enemy_turret"):
			if is_instance_valid(tur):
				tur.queue_free()
		if minivan_shop and minivan_shop.has_method("on_wave_cleared"):
			minivan_shop.on_wave_cleared()
		for mgr in get_tree().get_nodes_in_group("arena_interactables"):
			if is_instance_valid(mgr) and mgr.has_method("on_wave_cleared"):
				mgr.on_wave_cleared(current_wave + 1)
		await get_tree().create_timer(3.0).timeout
		prepare_wave(current_wave + 1)

func get_alive_enemy_count() -> int:
	var count: int = 0
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for e in all_enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if "is_dead" in e and e.is_dead:
				continue
			if "health" in e and e.health <= 0.0:
				continue
			count += 1
	return count

func update_enemy_count_hud() -> void:
	if player and player.get_node_or_null("HUD"):
		var hud = player.get_node("HUD")
		if hud.has_method("update_enemies_remaining"):
			var remaining: int = enemies_to_spawn + get_alive_enemy_count()
			hud.update_enemies_remaining(remaining, is_wave_active)

func prepare_wave(wave_num: int) -> void:
	current_wave = wave_num
	if GlobalSettings:
		GlobalSettings.last_wave = current_wave
		
	is_wave_active = false
	is_warming_up = true
	is_warmup_paused = false
	warmup_time_left = 10.0
	update_enemy_count_hud()
	
	if player and player.get_node_or_null("HUD"):
		player.get_node("HUD").set_wave(current_wave)
		
	# Determine Boss Waves first: Tiger I (Wave 5, 15, 25...) & Mi-24 «Крокодил» (Wave 10, 20, 30...)
	if force_boss_next_wave:
		tiger_queued_for_current_wave = true
		force_boss_next_wave = false
	elif current_wave >= BOSS_WAVE and (current_wave % 10 == 5):
		tiger_queued_for_current_wave = true
	else:
		tiger_queued_for_current_wave = false

	if force_mi24_next_wave:
		mi24_queued_for_current_wave = true
		force_mi24_next_wave = false
	elif current_wave >= MI24_BOSS_WAVE and (current_wave % 10 == 0):
		mi24_queued_for_current_wave = true
	else:
		mi24_queued_for_current_wave = false

	var is_boss_wave: bool = tiger_queued_for_current_wave or mi24_queued_for_current_wave

	# Sync smooth Day/Night & Weather environment BEFORE building enemy pool (never night on boss waves; waves 1-4 clear!)
	var env_tag: String = ""
	var is_night_or_fog: bool = false
	for ec in get_tree().get_nodes_in_group("environment_controller"):
		if is_instance_valid(ec) and ec.has_method("apply_wave_environment"):
			ec.apply_wave_environment(current_wave, is_boss_wave, current_wave == 1)
			if ec.has_method("get_wave_briefing_tag"):
				env_tag = ec.get_wave_briefing_tag()
			if ("is_night_wave" in ec and bool(ec.is_night_wave)) or ("current_weather" in ec and str(ec.current_weather) == "fog"):
				is_night_or_fog = true

	# Plan wave enemies
	var total_count: int = 4 + current_wave * 2
	var enemy_types_pool: Array[int] = []
	
	var red_count: int = 0
	var blue_count: int = 0
	var yellow_count: int = 0
	var green_count: int = 0
	var drone_count: int = 0
	var engineer_count: int = 0
	var shield_count: int = 0
	var saboteur_count: int = 0
	var cloaker_count: int = 0
	
	for i in range(total_count):
		var roll = randf()
		var type_val = 0
		if current_wave == 1:
			type_val = 0 # Red only
		elif current_wave == 2:
			if roll < 0.55:
				type_val = 0
			elif roll < 0.88:
				type_val = 1
			else:
				type_val = 4 # First Shahed drone appearance!
		elif current_wave == 3:
			if roll < 0.35:
				type_val = 0
			elif roll < 0.62:
				type_val = 1
			elif roll < 0.85:
				type_val = 2
			else:
				type_val = 4 # Shahed drone
		else:
			if roll < 0.28:
				type_val = 0 # Red
			elif roll < 0.48:
				type_val = 1 # Blue
			elif roll < 0.68:
				type_val = 2 # Yellow
			elif roll < 0.84:
				type_val = 3 # Green
			else:
				type_val = 4 # Shahed Drone
				
		enemy_types_pool.append(type_val)
		match type_val:
			0: red_count += 1
			1: blue_count += 1
			2: yellow_count += 1
			3: green_count += 1
			4: drone_count += 1

	# Stage 2 Special Tactical Enemy Classes (Balanced per wave!)
	# 1) Orange Engineer (Wave 3+): deploys sentry turret + drops fresh barrel
	if current_wave >= 3:
		engineer_count = 1 if current_wave <= 4 else mini(2, 1 + int(current_wave >= 6))
		for _ei in range(engineer_count):
			enemy_types_pool.append(6)
			total_count += 1
	# 2) Black Ballistic Shield Heavy (Wave 4+)
	if current_wave >= 4:
		shield_count = 1 if current_wave <= 5 else 2
		for _si in range(shield_count):
			enemy_types_pool.append(7)
			total_count += 1
	# 3) Gray Night Saboteur — Shooter (Wave 4+, extra presence at Night / Fog!)
	if current_wave >= 4:
		saboteur_count = (2 if is_night_or_fog else 1) + (1 if current_wave >= 7 else 0)
		for _sbi in range(saboteur_count):
			enemy_types_pool.append(8)
			total_count += 1
	# 4) Gray Night Cloaker — Payday 2 Style (Wave 4+, strictly rare: 1 max early, 1-2 late!)
	if current_wave >= 4:
		cloaker_count = 1 if current_wave <= 6 else (2 if (is_night_or_fog or current_wave >= 9) else 1)
		for _ci in range(cloaker_count):
			enemy_types_pool.append(9)
			total_count += 1
			
	# Requirement 9: Double the number of Shahed drones spawned every wave!
	var extra_drones = drone_count
	if current_wave >= 2 and extra_drones == 0:
		extra_drones = 2
	for d in range(extra_drones):
		enemy_types_pool.append(4)
		drone_count += 1
		total_count += 1

	# Black Assault Minivans (Waves 3+: max 1 on Wave 3, max 2 on Waves 4-5, max 3 on Waves 6+)
	var van_count: int = 0
	if current_wave == 3:
		van_count = 1
	elif current_wave == 4 or current_wave == 5:
		van_count = 2
	elif current_wave >= 6:
		van_count = 3
	for v in range(van_count):
		enemy_types_pool.append(5)
		total_count += 1
	enemy_types_pool.shuffle()

	var intel_parts: Array[String] = []
	if tiger_queued_for_current_wave: intel_parts.append("🪖 1 БОСС TIGER I")
	if mi24_queued_for_current_wave: intel_parts.append("🚁 1 БОСС МИ-24 «КРОКОДИЛ»")
	if van_count > 0:
		var van_word: String = "Бусик" if van_count == 1 else ("Бусика" if van_count <= 4 else "Бусиков")
		intel_parts.append("🚐 %d %s" % [van_count, van_word])
	if red_count > 0: intel_parts.append("🔴 %d Красных" % red_count)
	if blue_count > 0: intel_parts.append("🔵 %d Синих" % blue_count)
	if yellow_count > 0: intel_parts.append("🟡 %d Желтых" % yellow_count)
	if green_count > 0: intel_parts.append("🟢 %d Зеленых" % green_count)
	if engineer_count > 0: intel_parts.append("🟠 %d Инж." % engineer_count)
	if shield_count > 0: intel_parts.append("🛡 %d Щитов." % shield_count)
	if saboteur_count > 0: intel_parts.append("🥷 %d Диверс." % saboteur_count)
	if cloaker_count > 0: intel_parts.append("⚡ %d Клокер" % cloaker_count)
	if drone_count > 0: intel_parts.append("✈️ %d Шахедов" % drone_count)
	var intel_total: int = total_count + (1 if tiger_queued_for_current_wave else 0) + (1 if mi24_queued_for_current_wave else 0)
	wave_intel_text = ", ".join(intel_parts) + " (Всего: %d)" % intel_total
	if env_tag != "":
		wave_intel_text = env_tag + "\n" + wave_intel_text
	
	# Select spawn points that will ACTUALLY spawn enemies this wave
	spawn_point_assignments.clear()
	var available_pts: Array[Node3D] = spawn_points.duplicate()
	available_pts.shuffle()
	
	# Determine how many spawn points to use (e.g. 2 to 6 points)
	var num_pts_to_use: int = clampi(2 + int(current_wave * 0.7), 2, mini(available_pts.size(), total_count))
	var chosen_pts: Array[Node3D] = []
	for i in range(num_pts_to_use):
		chosen_pts.append(available_pts[i])
		spawn_point_assignments[available_pts[i]] = []
		
	# Distribute enemies across the chosen spawn points
	enemy_types_pool.shuffle()
	for i in range(enemy_types_pool.size()):
		var target_pt: Node3D = chosen_pts[i % chosen_pts.size()]
		(spawn_point_assignments[target_pt] as Array).append(enemy_types_pool[i])
		
	# Spawn beacons ONLY at the chosen points with exact breakdown info
	spawn_holographic_beacons()
	
	if player and player.get_node_or_null("HUD"):
		var hud = player.get_node("HUD")
		hud.show_wave_warmup(current_wave, int(ceil(warmup_time_left)), wave_intel_text)
		_refresh_boss_warning_hud()

func spawn_holographic_beacons() -> void:
	dismiss_holographic_beacons()
	if not beacon_scene:
		return
		
	for pt in spawn_point_assignments.keys():
		var queue: Array = spawn_point_assignments[pt]
		if queue.is_empty():
			continue
			
		var b_total: int = queue.size()
		var b_red: int = 0
		var b_blue: int = 0
		var b_yellow: int = 0
		var b_green: int = 0
		var b_drone: int = 0
		
		for t in queue:
			match t:
				0: b_red += 1
				1: b_blue += 1
				2: b_yellow += 1
				3: b_green += 1
				4: b_drone += 1
				
		var beacon = beacon_scene.instantiate()
		get_parent().add_child(beacon)
		beacon.global_position = pt.global_position
		active_beacons.append(beacon)
		
		if beacon.has_method("set_spawn_info"):
			beacon.set_spawn_info(b_total, b_red, b_blue, b_yellow, b_green, b_drone)

func dismiss_holographic_beacons() -> void:
	for beacon in active_beacons:
		if is_instance_valid(beacon):
			if beacon.has_method("dismiss"):
				beacon.dismiss()
			else:
				beacon.queue_free()
	active_beacons.clear()

func pause_warmup(paused: bool) -> void:
	is_warmup_paused = paused

func rush_warmup() -> void:
	start_wave_from_intermission()

func start_wave_from_intermission() -> void:
	if is_warming_up:
		start_wave()

func on_map_switched() -> void:
	# Rebind warmup spawn assignments & holographic beacons cleanly to the new map's markers!
	if not is_warming_up:
		return
	var pooled: Array = []
	for pt in spawn_point_assignments.keys():
		pooled.append_array(spawn_point_assignments[pt] as Array)
	spawn_point_assignments.clear()
	var available_pts: Array[Node3D] = spawn_points.duplicate()
	available_pts.shuffle()
	if not available_pts.is_empty() and not pooled.is_empty():
		var num_pts: int = clampi(2 + int(current_wave * 0.7), 2, mini(available_pts.size(), pooled.size()))
		var chosen: Array[Node3D] = []
		for i in range(num_pts):
			chosen.append(available_pts[i])
			spawn_point_assignments[available_pts[i]] = []
		for i in range(pooled.size()):
			(spawn_point_assignments[chosen[i % chosen.size()]] as Array).append(pooled[i])
	spawn_holographic_beacons()
	# Refresh biome name in warmup banner!
	var env_tag: String = ""
	for ec in get_tree().get_nodes_in_group("environment_controller"):
		if is_instance_valid(ec) and ec.has_method("get_wave_briefing_tag"):
			env_tag = ec.get_wave_briefing_tag()
	if env_tag != "":
		var lines := wave_intel_text.split("\n")
		var tail: String = lines[lines.size() - 1]
		wave_intel_text = env_tag + "\n" + tail
	if player and player.get_node_or_null("HUD"):
		player.get_node("HUD").show_wave_warmup(current_wave, int(ceil(warmup_time_left)), wave_intel_text)

func start_wave() -> void:
	is_warming_up = false
	is_wave_active = true
	dismiss_holographic_beacons()
	
	if minivan_shop and minivan_shop.has_method("on_wave_started"):
		minivan_shop.on_wave_started()
	for mgr in get_tree().get_nodes_in_group("arena_interactables"):
		if is_instance_valid(mgr) and mgr.has_method("on_wave_started"):
			mgr.on_wave_started(current_wave)
	
	if player and player.get_node_or_null("HUD"):
		player.get_node("HUD").show_wave_started()
		
	var planned_total: int = 0
	for pt in spawn_point_assignments.keys():
		planned_total += (spawn_point_assignments[pt] as Array).size()
		
	enemies_to_spawn = planned_total
	enemies_alive = 0
	spawn_timer = 0.4
	if tiger_queued_for_current_wave:
		tiger_queued_for_current_wave = false
		_spawn_tiger_boss()
	if mi24_queued_for_current_wave:
		mi24_queued_for_current_wave = false
		_spawn_mi24_boss()
	_refresh_boss_warning_hud()
	update_enemy_count_hud()

func queue_boss_next_wave() -> void:
	if is_warming_up:
		tiger_queued_for_current_wave = true
		force_boss_next_wave = false
	else:
		force_boss_next_wave = true
	_refresh_boss_warning_hud()

func queue_mi24_next_wave() -> void:
	if is_warming_up:
		mi24_queued_for_current_wave = true
		force_mi24_next_wave = false
	else:
		force_mi24_next_wave = true
	_refresh_boss_warning_hud()

func spawn_tiger_now() -> Node3D:
	return _spawn_tiger_boss()

func spawn_mi24_now() -> Node3D:
	return _spawn_mi24_boss()

func register_extra_enemy(e: Node) -> void:
	if is_instance_valid(e):
		enemies_alive += 1
		if e.has_signal("died") and not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)
		update_enemy_count_hud()

func spawn_specific_enemy_near_player(pool_type: int) -> Node3D:
	if not enemy_scene or not get_parent():
		return null
	var p_pos := player.global_position if is_instance_valid(player) else Vector3.ZERO
	var fwd := -player.global_transform.basis.z if is_instance_valid(player) else Vector3.FORWARD
	var flat_fwd := Vector3(fwd.x, 0.0, fwd.z)
	if flat_fwd.length_squared() < 0.01:
		flat_fwd = Vector3.FORWARD
	var spawn_p := p_pos + flat_fwd.normalized() * 14.0
	spawn_p.x = clampf(spawn_p.x, -42.0, 42.0)
	spawn_p.z = clampf(spawn_p.z, -42.0, 42.0)
	spawn_p.y = 0.0

	var enemy = enemy_scene.instantiate()
	enemy.enemy_type = _pool_to_enemy_type(pool_type)
	get_parent().add_child(enemy)
	enemy.global_position = spawn_p
	enemies_alive += 1
	enemy.died.connect(_on_enemy_died)
	update_enemy_count_hud()
	return enemy

func _pool_to_enemy_type(pool_type: int) -> int:
	match pool_type:
		6: return 4 # ORANGE_ENGINEER
		7: return 5 # BLACK_SHIELD
		8: return 6 # GRAY_SABOTEUR
		9: return 7 # GRAY_CLOAKER
		_: return clampi(pool_type, 0, 3)

func _refresh_boss_warning_hud() -> void:
	if not player or not player.get_node_or_null("HUD"):
		return
	var hud = player.get_node("HUD")
	if not hud.has_method("show_boss_warning"):
		return
	if not is_warming_up or is_wave_active:
		hud.hide_boss_warning()
		return
	if mi24_queued_for_current_wave:
		hud.show_boss_warning(0, "МИ-24 «КРОКОДИЛ»")
	elif tiger_queued_for_current_wave:
		hud.show_boss_warning(0, "TIGER I")
	elif force_mi24_next_wave:
		hud.show_boss_warning(1, "МИ-24 «КРОКОДИЛ»")
	elif force_boss_next_wave:
		hud.show_boss_warning(1, "TIGER I")
	else:
		# Check upcoming scheduled Boss Waves (5/15/25 = Tiger I, 10/20/30 = Mi-24)
		var next_tiger: int = ((current_wave / 10) * 10) + 5
		if next_tiger < current_wave:
			next_tiger += 10
		var next_mi24: int = ((current_wave / 10) + 1) * 10
		if current_wave % 10 == 0:
			next_mi24 = current_wave
		var d_tiger: int = next_tiger - current_wave
		var d_mi24: int = next_mi24 - current_wave
		if d_mi24 >= 0 and d_mi24 <= 2 and d_mi24 <= d_tiger:
			hud.show_boss_warning(d_mi24, "МИ-24 «КРОКОДИЛ»")
		elif d_tiger >= 0 and d_tiger <= 2:
			hud.show_boss_warning(d_tiger, "TIGER I")
		else:
			hud.hide_boss_warning()

func _find_safe_tiger_spawn_pos() -> Vector3:
	var p_pos := player.global_position if is_instance_valid(player) else Vector3.ZERO
	# Try perimeter spawn points first that are well clear of obstacles & player
	var candidates: Array[Vector3] = []
	for pt in spawn_points:
		if is_instance_valid(pt):
			candidates.append(Vector3(pt.global_position.x, 0.0, pt.global_position.z))
	candidates.shuffle()
	for angle_i in range(16):
		var ang: float = float(angle_i) * (TAU / 16.0)
		candidates.append(Vector3(cos(ang) * 44.0, 0.0, sin(ang) * 44.0))

	for cand in candidates:
		var c := Vector3(clampf(cand.x, -62.0, 62.0), 0.0, clampf(cand.z, -62.0, 62.0))
		if c.distance_to(Vector3(p_pos.x, 0.0, p_pos.z)) < 24.0:
			continue
		var box := AABB(c - Vector3(4.0, 0.0, 4.0), Vector3(8.0, 3.4, 8.0))
		var blocked := false
		for obs in MapObstacles.obstacle_aabbs:
			if obs.intersects(box):
				blocked = true
				break
		if not blocked:
			return c
	return Vector3(0.0, 0.0, -45.0)

func _spawn_tiger_boss() -> Node3D:
	var tiger: Node3D = TigerTankScript.new()
	tiger.name = "TigerI_Boss"
	var spawn_pos: Vector3 = _find_safe_tiger_spawn_pos()
	get_parent().add_child(tiger)
	tiger.global_position = spawn_pos
	if is_instance_valid(player):
		var to_p := player.global_position - spawn_pos
		to_p.y = 0.0
		if to_p.length() > 0.1:
			tiger.rotation.y = atan2(-to_p.x, -to_p.z)
	tiger.died.connect(_on_enemy_died)
	enemies_alive += 1
	update_enemy_count_hud()
	if player and player.get_node_or_null("HUD"):
		var hud = player.get_node("HUD")
		if hud.has_method("get_tiger_boss_hud"):
			var bhud = hud.get_tiger_boss_hud()
			if bhud and bhud.has_method("show_for_boss"):
				bhud.show_for_boss()
	return tiger

func _spawn_mi24_boss() -> Node3D:
	var mi24: Node3D = Mi24BossScript.new()
	mi24.name = "Mi24_Boss"
	get_parent().add_child(mi24)
	mi24.died.connect(_on_enemy_died)
	enemies_alive += 1
	update_enemy_count_hud()
	if player and player.get_node_or_null("HUD"):
		var hud = player.get_node("HUD")
		if hud.has_method("show_arena_toast"):
			hud.show_arena_toast("🚁 ВОЗДУШНАЯ ТРЕВОГА: ПРИБЫЛ МИ-24 «КРОКОДИЛ»!")
	return mi24

func spawn_next_enemy() -> void:
	if not enemy_scene:
		return
		
	var active_pts: Array[Node3D] = []
	for pt in spawn_point_assignments.keys():
		var q: Array = spawn_point_assignments[pt]
		if not q.is_empty():
			active_pts.append(pt)
			
	if active_pts.is_empty():
		return
		
	var chosen_pt: Node3D = active_pts.pick_random()
	var enemy_type_val: int = (spawn_point_assignments[chosen_pt] as Array).pop_front()
	
	if enemy_type_val == 4 and drone_scene:
		var drone = drone_scene.instantiate()
		get_parent().add_child(drone)
		drone.global_position = chosen_pt.global_position + Vector3(randf_range(-1.0, 1.0), 4.0, randf_range(-1.0, 1.0))
		enemies_alive += 1
		drone.died.connect(_on_enemy_died)
	elif enemy_type_val == 5:
		var van: Node3D = BlackMinivanScript.new()
		van.spawner_ref = self
		var v_pos: Vector3 = _find_safe_van_spawn_pos(chosen_pt.global_position)
		get_parent().add_child(van)
		van.global_position = v_pos
		if is_instance_valid(player):
			var to_p := player.global_position - v_pos
			to_p.y = 0.0
			if to_p.length() > 0.1:
				van.rotation.y = atan2(-to_p.x, -to_p.z)
		enemies_alive += 1
		van.died.connect(_on_enemy_died)
	else:
		var enemy = enemy_scene.instantiate()
		enemy.enemy_type = _pool_to_enemy_type(enemy_type_val)
		get_parent().add_child(enemy)
		enemy.global_position = chosen_pt.global_position + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
		enemies_alive += 1
		enemy.died.connect(_on_enemy_died)
	update_enemy_count_hud()

func _find_safe_van_spawn_pos(preferred: Vector3) -> Vector3:
	var p_pos := player.global_position if is_instance_valid(player) else Vector3.ZERO
	var candidates: Array[Vector3] = [Vector3(preferred.x, 0.0, preferred.z)]
	for pt in spawn_points:
		if is_instance_valid(pt):
			candidates.append(Vector3(pt.global_position.x, 0.0, pt.global_position.z))
	for ai in range(12):
		var ang: float = float(ai) * (TAU / 12.0)
		candidates.append(Vector3(cos(ang) * 46.0, 0.0, sin(ang) * 46.0))
	for cand in candidates:
		var c := Vector3(clampf(cand.x, -62.0, 62.0), 0.0, clampf(cand.z, -62.0, 62.0))
		if c.distance_to(Vector3(p_pos.x, 0.0, p_pos.z)) < 20.0:
			continue
		var box := AABB(c - Vector3(2.8, 0.0, 2.8), Vector3(5.6, 2.4, 5.6))
		var blocked := false
		for obs in MapObstacles.obstacle_aabbs:
			if obs.intersects(box):
				blocked = true
				break
		if not blocked:
			return c
	return Vector3(clampf(preferred.x, -60.0, 60.0), 0.0, clampf(preferred.z, -60.0, 60.0))

func _on_enemy_died(points: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	update_enemy_count_hud()
	if points > 0 and player:
		if player.has_method("add_money"):
			player.add_money(points)
		elif player.has_method("add_score"):
			player.add_score(points)

func get_enemy_reward_for_type(enemy_type_val: int) -> int:
	match enemy_type_val:
		0: return 6    # Red
		1: return 10   # Blue
		2: return 20   # Yellow Heavy
		3: return 16   # Green Sniper
		4: return 12   # Shahed Drone
		5: return 104  # Busik ($40) + average 4-6 squad inside
		6: return 24   # Orange Engineer
		7: return 32   # Black Shield Heavy
		8: return 26   # Gray Saboteur
		9: return 38   # Gray Cloaker
	return 6

func finish_wave_immediately() -> void:
	# 1. Award normal rewards for all unspawned enemies remaining in this wave's queues
	for pt in spawn_point_assignments.keys():
		var queue: Array = spawn_point_assignments[pt]
		for enemy_type_val in queue:
			var reward: int = get_enemy_reward_for_type(int(enemy_type_val))
			_on_enemy_died(reward)
	spawn_point_assignments.clear()
	enemies_to_spawn = 0

	# 2. Kill every currently alive enemy (regular, Shahed drones, bosses & turrets) so each emits its normal reward
	var all_enemies := get_tree().get_nodes_in_group("enemy")
	for e in all_enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if "is_dead" in e and e.is_dead:
				continue
			if e.has_method("take_damage"):
				e.take_damage(99999.0, false)
	for tur in get_tree().get_nodes_in_group("enemy_turret"):
		if is_instance_valid(tur):
			tur.queue_free()

	enemies_alive = 0
	update_enemy_count_hud()

	# 3. If triggered during intermission/warmup before wave started, immediately advance to next wave
	if is_warming_up and not is_wave_active:
		dismiss_holographic_beacons()
		prepare_wave(current_wave + 1)

func restart_current_wave(_dummy: bool = false) -> void:
	# Clean up any active alive enemies, turrets & burning black minivan wrecks
	var existing_enemies = get_tree().get_nodes_in_group("enemy")
	for e in existing_enemies:
		if is_instance_valid(e):
			e.queue_free()
	for tur in get_tree().get_nodes_in_group("enemy_turret"):
		if is_instance_valid(tur):
			tur.queue_free()
	for w in get_tree().get_nodes_in_group("black_minivan_wreck"):
		if is_instance_valid(w):
			w.queue_free()
	if player and player.get_node_or_null("HUD"):
		var hud = player.get_node("HUD")
		if hud.has_method("get_mi24_boss_hud"):
			var mhud = hud.get_mi24_boss_hud()
			if mhud and mhud.has_method("hide_boss"):
				mhud.hide_boss()
			
	dismiss_holographic_beacons()
	enemies_alive = 0
	enemies_to_spawn = 0
	is_wave_active = false
	
	if minivan_shop and minivan_shop.has_method("on_wave_cleared"):
		minivan_shop.on_wave_cleared()
		
	# Prepare the current wave afresh
	prepare_wave(current_wave)
