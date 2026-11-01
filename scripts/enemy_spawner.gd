extends Node3D

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

var player: CharacterBody3D = null
var active_beacons: Array[Node3D] = []
var minivan_shop: Node3D = null

# Map: Node3D (spawn point) -> Array[int] (enemy types to spawn at this point)
var spawn_point_assignments: Dictionary = {}
var wave_intel_text: String = ""

func _ready() -> void:
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	minivan_shop = get_parent().get_node_or_null("MinivanShop")
		
	# Find spawn points if not assigned
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
		
	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = randf_range(0.8, 1.8)
			spawn_next_enemy()
			enemies_to_spawn -= 1
	elif enemies_alive <= 0:
		# Wave clear! Next wave after short delay
		is_wave_active = false
		if minivan_shop and minivan_shop.has_method("on_wave_cleared"):
			minivan_shop.on_wave_cleared()
		await get_tree().create_timer(3.0).timeout
		prepare_wave(current_wave + 1)

func prepare_wave(wave_num: int) -> void:
	current_wave = wave_num
	if GlobalSettings:
		GlobalSettings.last_wave = current_wave
		
	is_wave_active = false
	is_warming_up = true
	is_warmup_paused = false
	warmup_time_left = 10.0
	
	if player and player.get_node_or_null("HUD"):
		player.get_node("HUD").set_wave(current_wave)
		
	# Plan wave enemies
	var total_count: int = 4 + current_wave * 2
	var enemy_types_pool: Array[int] = []
	
	var red_count: int = 0
	var blue_count: int = 0
	var yellow_count: int = 0
	var green_count: int = 0
	var drone_count: int = 0
	
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
			
	var intel_parts: Array[String] = []
	if red_count > 0: intel_parts.append("🔴 %d Красных" % red_count)
	if blue_count > 0: intel_parts.append("🔵 %d Синих" % blue_count)
	if yellow_count > 0: intel_parts.append("🟡 %d Желтых" % yellow_count)
	if green_count > 0: intel_parts.append("🟢 %d Зеленых" % green_count)
	if drone_count > 0: intel_parts.append("✈️ %d Шахедов" % drone_count)
	wave_intel_text = ", ".join(intel_parts) + " (Всего: %d)" % total_count
	
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
		player.get_node("HUD").show_wave_warmup(current_wave, int(ceil(warmup_time_left)), wave_intel_text)

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

func start_wave() -> void:
	is_warming_up = false
	is_wave_active = true
	dismiss_holographic_beacons()
	
	if minivan_shop and minivan_shop.has_method("on_wave_started"):
		minivan_shop.on_wave_started()
	
	if player and player.get_node_or_null("HUD"):
		player.get_node("HUD").show_wave_started()
		
	var planned_total: int = 0
	for pt in spawn_point_assignments.keys():
		planned_total += (spawn_point_assignments[pt] as Array).size()
		
	enemies_to_spawn = planned_total
	enemies_alive = 0
	spawn_timer = 0.4

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
	else:
		var enemy = enemy_scene.instantiate()
		enemy.enemy_type = enemy_type_val
		get_parent().add_child(enemy)
		enemy.global_position = chosen_pt.global_position + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
		enemies_alive += 1
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died(points: int) -> void:
	enemies_alive -= 1
	if player and player.has_method("add_money"):
		player.add_money(points)
	elif player and player.has_method("add_score"):
		player.add_score(points)
