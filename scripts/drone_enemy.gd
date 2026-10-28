extends CharacterBody3D

signal died(points: int)

enum State {
	CRUISE,
	DIVE,
	EXPLODING
}

@export var max_health: float = 30.0
var health: float = 30.0
var score_value: int = 8

var current_state: State = State.CRUISE
var player: Node3D = null

# Flight parameters
var cruise_speed: float = 7.0
var dive_speed: float = 18.5
var cruise_altitude: float = 6.5
var flight_timer: float = 0.0
var attack_countdown: float = 3.5

var dive_vector: Vector3 = Vector3.ZERO
var explosion_radius: float = 5.5
var explosion_damage: float = 50.0

# Visual and audio references
@onready var visuals: Node3D = $Visuals
@onready var prop_mesh: MeshInstance3D = $Visuals/Propeller
@onready var body_mesh: MeshInstance3D = $Visuals/Fuselage
@onready var wing_mesh: MeshInstance3D = $Visuals/DeltaWing
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var audio_dive: AudioStreamPlayer3D = $AudioDive

var original_material: StandardMaterial3D
var flash_timer: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	attack_countdown = randf_range(2.5, 5.0)
	
	# Start engine moped buzzing loop
	if audio_engine:
		audio_engine.stream = SoundEffects.create_shahed_engine_sound()
		audio_engine.play()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	flight_timer += delta
	
	# Fast propeller rotation
	if prop_mesh:
		prop_mesh.rotation.z += delta * 60.0
		
	# Damage flash reset
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			reset_materials()
			
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		move_and_slide()
		return
		
	match current_state:
		State.CRUISE:
			process_cruise(delta)
		State.DIVE:
			process_dive(delta)

func process_cruise(delta: float) -> void:
	var target_pos: Vector3 = player.global_position
	var target_altitude: float = target_pos.y + cruise_altitude
	
	var horizontal_dir := Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z)
	var horiz_dist := horizontal_dir.length()
	horizontal_dir = horizontal_dir.normalized()
	
	# Altitude correction with gentle wave
	var desired_y := target_altitude + sin(flight_timer * 1.8) * 0.8
	var diff_y := desired_y - global_position.y
	var vel_y := clampf(diff_y * 2.0, -4.0, 4.0)
	
	# Steer horizontally
	var desired_horiz = horizontal_dir * cruise_speed
	if horiz_dist < 6.0:
		# Circle or fly past
		var tangent = horizontal_dir.cross(Vector3.UP)
		desired_horiz = (horizontal_dir * 0.3 + tangent * 0.95).normalized() * cruise_speed
		
	velocity = Vector3(desired_horiz.x, vel_y, desired_horiz.z)
	
	# Rotate towards velocity with realistic bank/roll
	if desired_horiz.length_squared() > 0.01:
		var target_yaw := atan2(desired_horiz.x, desired_horiz.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.5)
		
		# Bank into turn
		var yaw_diff := wrapf(target_yaw - rotation.y, -PI, PI)
		var target_roll := clampf(-yaw_diff * 0.8, -0.45, 0.45)
		rotation.z = lerpf(rotation.z, target_roll, delta * 4.0)
		rotation.x = lerpf(rotation.x, -vel_y * 0.04, delta * 4.0)
		
	move_and_slide()
	
	# Attack countdown
	attack_countdown -= delta
	if attack_countdown <= 0.0 and horiz_dist < 24.0:
		start_dive_attack()

func start_dive_attack() -> void:
	current_state = State.DIVE
	
	# Stop cruise engine loop and start loud screaming dive audio
	if audio_engine and audio_engine.playing:
		audio_engine.stop()
		
	if audio_dive:
		audio_dive.stream = SoundEffects.create_shahed_dive_sound()
		audio_dive.play()
		
	# Calculate dive lead towards player
	var target_pt: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	if player is CharacterBody3D:
		# Add lead based on player movement
		target_pt += player.velocity * 0.45
		
	dive_vector = (target_pt - global_position).normalized()

func process_dive(delta: float) -> void:
	# Keep updating dive direction with slight tracking homing
	var target_pt: Vector3 = player.global_position + Vector3(0, 0.8, 0)
	var desired_dir := (target_pt - global_position).normalized()
	dive_vector = dive_vector.lerp(desired_dir, delta * 2.8).normalized()
	
	velocity = dive_vector * dive_speed
	
	# Point nose directly along dive_vector
	if dive_vector.length_squared() > 0.01:
		var target_yaw := atan2(dive_vector.x, dive_vector.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 9.0)
		
		var horiz_len := Vector2(dive_vector.x, dive_vector.z).length()
		var target_pitch := -atan2(dive_vector.y, horiz_len)
		rotation.x = lerp_angle(rotation.x, target_pitch, delta * 9.0)
		rotation.z = lerpf(rotation.z, 0.0, delta * 5.0)
		
	var collision = move_and_collide(velocity * delta)
	
	# Check proximity to player or collision with floor/walls
	var dist_to_player := global_position.distance_to(player.global_position + Vector3(0, 0.8, 0))
	if dist_to_player <= 1.8 or collision != null:
		detonate(false)

func take_damage(amount: float, is_shotgun: bool = false) -> void:
	if is_dead:
		return
		
	# Shotgun rule: One-shot kills even with single pellet
	if is_shotgun:
		amount = max_health
		
	health -= amount
	if health_bar:
		health_bar.value = health
		
	# White damage flash
	flash_timer = 0.08
	apply_damage_flash()
	
	if health <= 0:
		is_dead = true
		detonate(true)

func apply_damage_flash() -> void:
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 1.0, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.5, 0.3)
	flash_mat.emission_energy_multiplier = 2.5
	if body_mesh:
		body_mesh.material_override = flash_mat
	if wing_mesh:
		wing_mesh.material_override = flash_mat

func reset_materials() -> void:
	if body_mesh:
		body_mesh.material_override = null
	if wing_mesh:
		wing_mesh.material_override = null

func detonate(killed_by_player: bool) -> void:
	if is_dead and not killed_by_player:
		return
	is_dead = true
	
	if killed_by_player:
		died.emit(score_value)
		
	# 1. Damage Player if within explosion radius (-50 HP)
	if is_instance_valid(player):
		var p_dist := global_position.distance_to(player.global_position)
		if p_dist <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(explosion_damage)
				
	# 2. Damage nearby enemies (-50 HP to enemies in radius)
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for e in all_enemies:
		if is_instance_valid(e) and e != self:
			var e_dist = global_position.distance_to(e.global_position)
			if e_dist <= explosion_radius:
				if e.has_method("take_damage"):
					e.take_damage(explosion_damage)
					
	# 3. Global explosion audio
	var exp_sfx := AudioStreamPlayer.new()
	exp_sfx.stream = SoundEffects.create_shahed_explosion_sound()
	exp_sfx.pitch_scale = randf_range(0.95, 1.05)
	get_tree().root.add_child(exp_sfx)
	exp_sfx.play()
	exp_sfx.finished.connect(exp_sfx.queue_free)
	
	# 4. Explosion Visual Effects (Sparks / Fireball / Smoke)
	spawn_explosion_vfx()
	
	queue_free()

func spawn_explosion_vfx() -> void:
	var vfx := Node3D.new()
	vfx.global_position = global_position
	get_parent().add_child(vfx)
	
	# Blast light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.25)
	light.light_energy = 5.0
	light.omni_range = 10.0
	vfx.add_child(light)
	
	# Fireball mesh sphere
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	sphere.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.1, 0.95)
	sphere.material_override = mat
	vfx.add_child(sphere)
	
	# Animate explosion expansion and fade
	var tween := vfx.create_tween()
	tween.tween_property(sphere, "scale", Vector3(2.4, 2.4, 2.4), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.35)
	tween.tween_property(sphere, "scale", Vector3(0.1, 0.1, 0.1), 0.15)
	tween.finished.connect(vfx.queue_free)
