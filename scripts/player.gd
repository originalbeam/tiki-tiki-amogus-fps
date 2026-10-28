extends CharacterBody3D

signal health_changed(current: float, max_val: float)
signal armor_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal score_changed(new_score: int)
signal money_changed(new_money: int)
signal player_died()
signal vodka_count_changed(new_count: int)
signal vodka_buff_updated(is_active: bool, time_left: float)

@export var mouse_sensitivity: float = 0.003
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 9.5
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0

var max_health: float = 100.0
var health: float = 100.0
var max_armor: float = 75.0
var armor: float = 0.0

# Super Heavy Armor ($80, max 150, incoming damage halved then split 50/50, drops don't replenish if > 75, breaks < 76)
var has_heavy_armor: bool = false

# Stamina System: 150 points, 50-point divider, 3s delay, 10/15 pts/s regen
var max_stamina: float = 150.0
var stamina: float = 150.0
var stamina_cooldown: float = 0.0
var normal_max_stamina: float = 150.0

# Vodka "Чекунец 67" (Slot 5, max 3, +6-7 HP, 2x stamina, 1.5x speed, no low-stamina debuffs, 15s)
var vodka_count: int = 0
var is_vodka_active: bool = false
var vodka_timer: float = 0.0

# Currency ($ Dollars)
var money: int = 0
var score: int = 0
var is_dead: bool = false

# 3D Camera Controls
var base_fov: float = 85.0
var sprint_fov: float = 95.0
var target_fov: float = 85.0
var base_cam_y: float = 0.0

# Head Bobbing
var bob_time: float = 0.0
var bob_freq: float = 10.0
var bob_amplitude: float = 0.035

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_manager: Node3D = $Head/Camera3D/WeaponHolder
@onready var hurt_sound_player: AudioStreamPlayer = $HurtSound
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	call_deferred("_ensure_mouse_captured")
	
	base_cam_y = camera.position.y
	base_fov = camera.fov
	
	if GlobalSettings:
		money = GlobalSettings.current_score
		score = money
		if GlobalSettings.mouse_sensitivity > 0.0:
			mouse_sensitivity = GlobalSettings.mouse_sensitivity
		
	health = max_health
	stamina = max_stamina
	
	health_changed.emit(health, max_health)
	armor_changed.emit(armor, max_armor)
	stamina_changed.emit(stamina, max_stamina)
	score_changed.emit(money)
	money_changed.emit(money)
	vodka_count_changed.emit(vodka_count)
	vodka_buff_updated.emit(false, 0.0)
	
	# Connect weapon manager signals
	if weapon_manager and hud:
		weapon_manager.weapon_changed.connect(hud._on_weapon_changed)
		weapon_manager.ammo_updated.connect(hud._on_ammo_updated)
		weapon_manager.hit_enemy.connect(hud.show_hitmarker)
		
		# Immediately push current weapon and ammo to HUD on startup
		if weapon_manager.current_weapon:
			weapon_manager.weapon_changed.emit(weapon_manager.current_weapon)
		weapon_manager.emit_ammo_state()

func _ensure_mouse_captured() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if is_dead:
		if event.is_action_pressed("restart"):
			restart_game()
		return
		
	# Clicking window captures mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hud and hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
			return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		
	# ESC opens / closes menus (Shop -> Handbook -> Pause Menu)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if hud:
			if hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
				hud.close_shop()
				get_viewport().set_input_as_handled()
				return
			elif hud.handbook_panel.visible:
				hud._on_close_handbook_pressed()
				get_viewport().set_input_as_handled()
				return
			elif hud.pause_panel.visible:
				hud.resume_game()
				get_viewport().set_input_as_handled()
				return
			else:
				hud.pause_game()
				get_viewport().set_input_as_handled()
				return

	# Quick Knife Attack [V]
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		if weapon_manager and weapon_manager.has_method("quick_knife_attack"):
			weapon_manager.quick_knife_attack()
			get_viewport().set_input_as_handled()
			return

	# Drink Vodka "Чекунец 67" [5]
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_5:
		use_vodka()
		get_viewport().set_input_as_handled()
		return

	# Wave Warmup Controls: [B] Shop, [F] Fast-forward
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			var spawner = get_parent().get_node_or_null("EnemySpawner")
			if spawner and spawner.is_warming_up:
				if hud and hud.has_method("toggle_shop"):
					hud.toggle_shop()
					get_viewport().set_input_as_handled()
					return
		elif event.keycode == KEY_F:
			var spawner = get_parent().get_node_or_null("EnemySpawner")
			if spawner and spawner.is_warming_up:
				spawner.rush_warmup()
				get_viewport().set_input_as_handled()
				return

	# Standard 3D FPS Mouse Look (Horizontal = Yaw, Vertical = Pitch)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_x: float = -event.relative.x * mouse_sensitivity
		var mouse_y: float = -event.relative.y * mouse_sensitivity
		
		# Turn left / right (Yaw)
		rotate_y(mouse_x)
		
		# Look up / down (Pitch) with clamp
		head.rotate_x(mouse_y)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
		
		# Weapon inertia / sway
		if weapon_manager and weapon_manager.has_method("apply_mouse_sway"):
			weapon_manager.apply_mouse_sway(event.relative)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Vodka "Чекунец 67" Buff processing
	if is_vodka_active:
		vodka_timer -= delta
		vodka_buff_updated.emit(true, vodka_timer)
		if vodka_timer <= 0.0:
			is_vodka_active = false
			max_stamina = normal_max_stamina
			stamina = minf(stamina, max_stamina)
			stamina_changed.emit(stamina, max_stamina)
			vodka_buff_updated.emit(false, 0.0)
		
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Jump (consumes 20 stamina points and resets delay)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		camera.position.y += 0.03
		stamina = maxf(0.0, stamina - 20.0)
		stamina_cooldown = 3.0
		stamina_changed.emit(stamina, max_stamina)
		
	# Sprint check with 50-point divider logic (bypassed if under Чекунец 67 buff)
	var wants_sprint: bool = Input.is_action_pressed("sprint") and is_on_floor() and velocity.length() > 0.8 and stamina > 0.0
	var is_sprinting: bool = false
	var current_speed: float = walk_speed
	
	if wants_sprint:
		is_sprinting = true
		stamina_cooldown = 3.0
		if is_vodka_active:
			# Чекунец 67: 1.5x sprint speed bonus, no fatigue debuffs regardless of stamina!
			current_speed = sprint_speed * 1.5
			stamina = maxf(0.0, stamina - 12.0 * delta)
		elif stamina > 50.0:
			# Normal sprint speed (+3.5 m/s) and standard drain rate (20 pts/s)
			current_speed = sprint_speed
			stamina = maxf(0.0, stamina - 20.0 * delta)
		else:
			# Last 50 points: sprint speed bonus is halved (+1.75 m/s), drain rate is halved (10 pts/s)
			current_speed = walk_speed + 1.75
			stamina = maxf(0.0, stamina - 10.0 * delta)
		stamina_changed.emit(stamina, max_stamina)
	else:
		current_speed = walk_speed
		if stamina_cooldown > 0.0:
			stamina_cooldown -= delta
		elif stamina < max_stamina:
			var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
			# Base regen = 10 pts/s; standing still (< 0.2 m/s) = 15 pts/s (1.5x speed)
			var regen_rate: float = 15.0 if horiz_speed < 0.2 else 10.0
			if is_vodka_active:
				regen_rate *= 1.5
			stamina = minf(max_stamina, stamina + regen_rate * delta)
			stamina_changed.emit(stamina, max_stamina)
	
	# Movement input
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction.length_squared() > 0.001:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Head Bobbing (rhythmic figure-8)
		bob_time += delta * (bob_freq * (1.35 if is_sprinting else 1.0))
		camera.position.y = base_cam_y + sin(bob_time) * bob_amplitude
		camera.position.x = cos(bob_time * 0.5) * (bob_amplitude * 0.5)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 4.5 * delta)
		velocity.z = move_toward(velocity.z, 0, current_speed * 4.5 * delta)
		camera.position.y = lerpf(camera.position.y, base_cam_y, delta * 8.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 8.0)
		bob_time = 0.0
		
	# 3D Camera Strafe Tilt / Roll
	var target_roll: float = -input_dir.x * deg_to_rad(2.2)
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * 8.0)
	
	# 3D Camera Dynamic FOV
	target_fov = sprint_fov if is_sprinting else base_fov
	camera.fov = lerpf(camera.fov, target_fov, delta * 8.0)
		
	move_and_slide()
	
	# Weapon movement bobbing
	if weapon_manager and weapon_manager.has_method("apply_movement_bob"):
		var horiz_vel: float = Vector2(velocity.x, velocity.z).length()
		weapon_manager.apply_movement_bob(horiz_vel, is_sprinting, delta)
		
	# Weapon inputs
	handle_weapon_inputs()

func add_camera_recoil(pitch: float, yaw: float) -> void:
	head.rotation.x = clampf(head.rotation.x - pitch * 0.15, deg_to_rad(-88.0), deg_to_rad(88.0))
	rotate_y(yaw * 0.15)

func handle_weapon_inputs() -> void:
	if not weapon_manager or is_dead or get_tree().paused:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	if Input.is_action_just_pressed("weapon_1"):
		weapon_manager.switch_slot(1)
	elif Input.is_action_just_pressed("weapon_2"):
		weapon_manager.switch_slot(2)
	elif Input.is_action_just_pressed("weapon_3"):
		weapon_manager.switch_slot(3)
	elif Input.is_action_just_pressed("next_weapon"):
		weapon_manager.switch_next()
	elif Input.is_action_just_pressed("prev_weapon"):
		weapon_manager.switch_prev()
		
	if Input.is_action_just_pressed("reload"):
		weapon_manager.start_reload()
		
	var just_shot: bool = Input.is_action_just_pressed("shoot")
	weapon_manager.try_shoot(just_shot)

func use_vodka() -> void:
	if is_dead or vodka_count <= 0:
		return
	vodka_count -= 1
	vodka_count_changed.emit(vodka_count)
	
	# Random 6-7 HP
	var heal_amt := randi_range(6, 7)
	add_health(float(heal_amt))
	
	# Buff: 15s duration, max stamina 300, 1.5x sprint speed, no fatigue debuffs
	is_vodka_active = true
	vodka_timer = 15.0
	max_stamina = normal_max_stamina * 2.0
	stamina = minf(max_stamina, stamina + 150.0)
	stamina_changed.emit(stamina, max_stamina)
	vodka_buff_updated.emit(true, vodka_timer)
	
	play_sfx(SoundEffects.create_vodka_drink_sound())

func add_vodka() -> bool:
	if vodka_count >= 3:
		return false
	vodka_count += 1
	vodka_count_changed.emit(vodka_count)
	return true

func buy_heavy_armor() -> void:
	has_heavy_armor = true
	max_armor = 150.0
	armor = 150.0
	armor_changed.emit(armor, max_armor)
	play_sfx(SoundEffects.create_heavy_armor_equip_sound())

func buy_armor_plate() -> bool:
	if not has_heavy_armor or armor < 76.0:
		return false
	armor = minf(max_armor, armor + 30.0)
	armor_changed.emit(armor, max_armor)
	play_sfx(SoundEffects.create_armor_plate_insert_sound())
	return true

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	# Super heavy armor: incoming damage is halved, then split equally between HP and Armor
	if has_heavy_armor and armor >= 76.0:
		var reduced_dmg: float = amount * 0.5
		var split_dmg: float = reduced_dmg * 0.5
		health = clampf(health - split_dmg, 0.0, max_health)
		armor = maxf(0.0, armor - split_dmg)
		
		# If armor drops below 76, all super heavy armor effects are cancelled
		if armor < 76.0:
			has_heavy_armor = false
			max_armor = 75.0
			armor = minf(armor, 75.0)
			
		armor_changed.emit(armor, max_armor)
	elif armor > 0.0:
		var half_dmg: float = amount * 0.5
		health = clampf(health - half_dmg, 0.0, max_health)
		armor = maxf(0.0, armor - half_dmg)
		armor_changed.emit(armor, max_armor)
	else:
		health = clampf(health - amount, 0.0, max_health)
		
	health_changed.emit(health, max_health)
	
	# Camera shake
	camera.position.x += randf_range(-0.04, 0.04)
	camera.position.y += randf_range(-0.03, 0.03)
	camera.rotation.z += randf_range(-0.04, 0.04)
	
	# Hurt sound
	if hurt_sound_player:
		hurt_sound_player.stream = SoundEffects.create_player_hurt_sound()
		hurt_sound_player.pitch_scale = randf_range(0.9, 1.1)
		hurt_sound_player.play()
		
	# Damage screen flash
	if hud and hud.has_method("flash_damage"):
		hud.flash_damage()
		
	if health <= 0:
		die()

func add_armor(amount: float, is_drop: bool = false) -> void:
	if is_dead:
		return
	if is_drop and armor > 75.0:
		return
	armor = minf(max_armor, armor + amount)
	armor_changed.emit(armor, max_armor)

func play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func add_health(amount: float) -> void:
	if is_dead:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func add_money(amount: int) -> void:
	money += amount
	score = money
	if GlobalSettings:
		GlobalSettings.current_score = money
	score_changed.emit(money)
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		score = money
		if GlobalSettings:
			GlobalSettings.current_score = money
		score_changed.emit(money)
		money_changed.emit(money)
		return true
	return false

func add_score(amount: int) -> void:
	add_money(amount)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	player_died.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var tween: Tween = create_tween()
	tween.tween_property(camera, "position:y", 0.25, 0.5)
	tween.parallel().tween_property(camera, "rotation:z", deg_to_rad(45.0), 0.5)

func restart_game() -> void:
	get_tree().reload_current_scene()
