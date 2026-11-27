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

const WeaponWorkbenchScript = preload("res://scripts/shop/weapon_workbench.gd")

# Currency ($ Dollars)
var money: int = 0
var score: int = 0
var is_dead: bool = false
var is_invincible: bool = false

# Minivan Shop & Workbench Interaction State
var is_near_shop: bool = false
var is_in_shop: bool = false
var has_workbench: bool = false
var is_near_workbench: bool = false
var is_in_workbench: bool = false
var workbench_node: Node3D = null
var mounted_turret: Node3D = null

# 3D Camera Controls
var base_fov: float = 85.0
var sprint_fov: float = 95.0
var target_fov: float = 85.0
var base_cam_y: float = 0.0

# Head Bobbing
var bob_time: float = 0.0
var bob_freq: float = 10.0
var bob_amplitude: float = 0.035

# Smooth Physical Camera Recoil (vertical climb + horizontal kick + partial settle)
var cam_recoil_rem_pitch: float = 0.0
var cam_recoil_rem_yaw: float = 0.0
var cam_recoil_recover_pitch: float = 0.0

# Cloaker Payday-2 Style Short Knockdown Stun (1.2s tilt + recovery)
var cloaker_stun_timer: float = 0.0
var cloaker_stun_roll_sign: float = 1.0

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
	camera.cull_mask = 1 | 2 # Layers 1 (world) & 2 (viewmodel); Layer 3 (4) is reserved exclusively for FLIR thermal vision!
	if hurt_sound_player:
		hurt_sound_player.bus = "SFX"
	
	var gs = get_node_or_null("/root/GlobalSettings")
	if gs:
		money = gs.current_score
		score = money
		if gs.mouse_sensitivity > 0.0:
			mouse_sensitivity = gs.mouse_sensitivity
		
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
		if weapon_manager.has_signal("slots_updated") and hud.has_method("_on_slots_updated"):
			weapon_manager.slots_updated.connect(hud._on_slots_updated)
		if weapon_manager.has_signal("ads_state_changed") and hud.has_method("_on_ads_state_changed"):
			weapon_manager.ads_state_changed.connect(hud._on_ads_state_changed)
		if weapon_manager.has_signal("tactical_state_changed") and hud.has_method("_on_tactical_state_changed"):
			weapon_manager.tactical_state_changed.connect(hud._on_tactical_state_changed)
		
		# Immediately push current weapon and ammo to HUD on startup
		if weapon_manager.current_weapon:
			weapon_manager.weapon_changed.emit(weapon_manager.current_weapon)
		weapon_manager.emit_ammo_state()
		if weapon_manager.has_method("emit_tactical_state"):
			weapon_manager.emit_tactical_state()
		if hud.has_method("_on_slots_updated"):
			hud._on_slots_updated()

func _ensure_mouse_captured() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_near_shop(near: bool) -> void:
	is_near_shop = near
	if hud and hud.has_method("show_shop_zone_prompt"):
		hud.show_shop_zone_prompt(near)

func set_in_shop(in_shop_state: bool) -> void:
	is_in_shop = in_shop_state
	if is_in_shop:
		velocity.x = 0.0
		velocity.z = 0.0
		if weapon_manager and weapon_manager.has_method("set_aiming"):
			weapon_manager.set_aiming(false)

func set_near_workbench(near: bool) -> void:
	is_near_workbench = near
	if hud and hud.has_method("show_workbench_zone_prompt"):
		hud.show_workbench_zone_prompt(near)

func set_in_workbench(state: bool) -> void:
	is_in_workbench = state
	if is_in_workbench:
		velocity.x = 0.0
		velocity.z = 0.0
		if weapon_manager and weapon_manager.has_method("set_aiming"):
			weapon_manager.set_aiming(false)

func mount_turret(dshk: Node3D) -> void:
	if not is_instance_valid(dshk) or is_dead:
		return
	mounted_turret = dshk
	dshk.set_meta("mounted_player", self)
	velocity = Vector3.ZERO
	if weapon_manager:
		if weapon_manager.has_method("set_aiming"):
			weapon_manager.set_aiming(false)
		weapon_manager.visible = false
	var sm: Marker3D = dshk.get_meta("stand_marker", null) as Marker3D
	if sm:
		global_position = Vector3(sm.global_position.x, global_position.y, sm.global_position.z)
	rotation.y = dshk.rotation.y
	head.rotation.x = 0.0

func dismount_turret() -> void:
	if is_instance_valid(mounted_turret):
		mounted_turret.set_meta("mounted_player", null)
	mounted_turret = null
	if weapon_manager:
		weapon_manager.visible = true

func buy_workbench() -> bool:
	if has_workbench:
		return false
	has_workbench = true
	var spawn_pos: Vector3 = WeaponWorkbenchScript.find_safe_center_pos(get_tree(), self)
	var wb: Node3D = WeaponWorkbenchScript.new()
	wb.name = "WeaponWorkbench"
	wb.position = spawn_pos
	var world_parent: Node = get_parent() if get_parent() else get_tree().root
	world_parent.add_child(wb)
	workbench_node = wb
	play_sfx(SoundEffects.create_heavy_armor_equip_sound())
	return true

func _input(event: InputEvent) -> void:
	if is_dead:
		if event.is_action_pressed("restart"):
			restart_game()
		return
		
	# Clicking window captures mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open():
			return
		if hud and hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
			return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Right Mouse Button -> ADS Aiming (for weapons with optics)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if weapon_manager and weapon_manager.has_method("set_aiming"):
			if not event.pressed:
				weapon_manager.set_aiming(false)
			elif not get_tree().paused and not is_in_shop and not is_in_workbench:
				if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
					weapon_manager.set_aiming(true)

	# Mouse Wheel -> Dynamic Scope Zoom while aiming (overrides weapon cycling!)
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if weapon_manager and weapon_manager.is_aiming and weapon_manager.has_method("adjust_ads_zoom"):
			var step: float = 0.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.5
			if weapon_manager.adjust_ads_zoom(step):
				get_viewport().set_input_as_handled()
				return

	# Cheat Menu toggle on '}' (or ']' / Russian 'Ъ' key)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BRACERIGHT or event.keycode == KEY_BRACKETRIGHT or event.physical_keycode == KEY_BRACKETRIGHT or event.unicode == 125:
			if hud and hud.has_method("toggle_cheat_menu"):
				hud.toggle_cheat_menu()
				get_viewport().set_input_as_handled()
				return

	# Inventory toggle on [I]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.physical_keycode == KEY_I:
			if hud and hud.has_method("toggle_inventory") and not get_tree().paused and not is_in_shop and not is_in_workbench:
				if not (hud.has_method("is_cheat_menu_open") and hud.is_cheat_menu_open()):
					hud.toggle_inventory()
					get_viewport().set_input_as_handled()
					return

	# Workbench toggle on [N] (only when in workbench zone, or closing if already open)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N or event.physical_keycode == KEY_N:
			if hud and hud.has_method("toggle_workbench") and not get_tree().paused and not is_in_shop:
				if is_near_workbench or (hud.has_method("is_workbench_open") and hud.is_workbench_open()):
					hud.toggle_workbench()
					get_viewport().set_input_as_handled()
					return
		
	# ESC layered close: CheatMenu -> MapTravel -> Workbench (Screen 2->1->Close) -> Inventory -> Shop -> Handbook -> Pause Menu
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if hud:
			if hud.has_method("is_cheat_menu_open") and hud.is_cheat_menu_open():
				hud.close_cheat_menu()
				get_viewport().set_input_as_handled()
				return
			elif hud.has_method("is_map_travel_open") and hud.is_map_travel_open():
				hud.close_map_travel()
				get_viewport().set_input_as_handled()
				return
			elif hud.has_method("is_workbench_open") and hud.is_workbench_open():
				hud.handle_workbench_escape()
				get_viewport().set_input_as_handled()
				return
			elif hud.has_method("is_inventory_open") and hud.is_inventory_open():
				hud.close_inventory()
				get_viewport().set_input_as_handled()
				return
			elif hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
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
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_V or event.physical_keycode == KEY_V):
		if not is_dead and not get_tree().paused and not is_in_shop and not is_in_workbench:
			if hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open():
				return
			if weapon_manager and weapon_manager.has_method("quick_knife_attack"):
				weapon_manager.quick_knife_attack()
				get_viewport().set_input_as_handled()
				return

	# Tactical Weapon Controls: [X] Fire Mode, [T] Laser, [L] Flashlight, [G] Underbarrel Grenade Launcher
	if event is InputEventKey and event.pressed and not event.echo:
		if not is_dead and not get_tree().paused and not is_in_shop and not is_in_workbench:
			if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
				if event.keycode == KEY_X or event.physical_keycode == KEY_X:
					if weapon_manager and weapon_manager.has_method("toggle_fire_mode"):
						weapon_manager.toggle_fire_mode()
						get_viewport().set_input_as_handled()
						return
				elif event.keycode == KEY_T or event.physical_keycode == KEY_T:
					if weapon_manager and weapon_manager.has_method("toggle_laser"):
						weapon_manager.toggle_laser()
						get_viewport().set_input_as_handled()
						return
				elif event.keycode == KEY_L or event.physical_keycode == KEY_L:
					if weapon_manager and weapon_manager.has_method("toggle_flashlight"):
						weapon_manager.toggle_flashlight()
						get_viewport().set_input_as_handled()
						return
				elif event.keycode == KEY_G or event.physical_keycode == KEY_G:
					if weapon_manager and weapon_manager.has_method("toggle_ugl_mode"):
						weapon_manager.toggle_ugl_mode()
						get_viewport().set_input_as_handled()
						return

	# Drink Vodka "Чекунец 67" — Usable Item Slot [6] (Slots [4] & [5] are unlockable firearm slots!)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_6 or event.physical_keycode == KEY_6:
			if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
				use_vodka()
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_4 or event.physical_keycode == KEY_4:
			if not is_dead and not get_tree().paused and not is_in_shop and not is_in_workbench:
				if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
					if weapon_manager:
						weapon_manager.switch_slot(4)
						get_viewport().set_input_as_handled()
						return
		elif event.keycode == KEY_5 or event.physical_keycode == KEY_5:
			if not is_dead and not get_tree().paused and not is_in_shop and not is_in_workbench:
				if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
					if weapon_manager:
						weapon_manager.switch_slot(5)
						get_viewport().set_input_as_handled()
						return

	# Wave Warmup, Shop, Paid Map Travel [M] & Arena Interact [E] (Airdrop Crates / Mounted DShK)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B or event.physical_keycode == KEY_B:
			if is_near_shop or (hud and hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible):
				if hud and hud.has_method("toggle_shop") and not is_in_workbench:
					hud.toggle_shop()
					get_viewport().set_input_as_handled()
					return
		elif event.keycode == KEY_M or event.physical_keycode == KEY_M:
			if not is_dead and not get_tree().paused and not is_in_workbench:
				if is_near_shop or (hud and hud.has_method("is_map_travel_open") and hud.is_map_travel_open()):
					if hud and hud.has_method("toggle_map_travel"):
						hud.toggle_map_travel()
						get_viewport().set_input_as_handled()
						return
		elif event.keycode == KEY_E or event.physical_keycode == KEY_E:
			if not is_dead and not get_tree().paused and not is_in_shop and not is_in_workbench:
				if not (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
					var mgrs := get_tree().get_nodes_in_group("arena_interactables")
					if mgrs.size() > 0 and mgrs[0].has_method("try_interact"):
						if mgrs[0].try_interact(self):
							get_viewport().set_input_as_handled()
							return
		elif event.keycode == KEY_F or event.physical_keycode == KEY_F:
			var spawner = get_parent().get_node_or_null("EnemySpawner")
			if spawner and spawner.is_warming_up:
				spawner.start_wave_from_intermission()
				get_viewport().set_input_as_handled()
				return

	# Standard 3D FPS Mouse Look (Horizontal = Yaw, Vertical = Pitch, scaled down when zoomed in ADS)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens_mult: float = 1.0 / pow(maxf(1.0, weapon_manager.current_ads_zoom), 0.72) if (weapon_manager and weapon_manager.is_aiming) else 1.0
		var mouse_x: float = -event.relative.x * mouse_sensitivity * sens_mult
		var mouse_y: float = -event.relative.y * mouse_sensitivity * sens_mult
		
		# Turn left / right (Yaw)
		rotate_y(mouse_x)
		
		# Look up / down (Pitch) with clamp
		head.rotate_x(mouse_y)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
		# Manual downward pull consumes pending auto-recovery so player control never double-drops
		if mouse_y < 0.0 and cam_recoil_recover_pitch > 0.0:
			cam_recoil_recover_pitch = maxf(0.0, cam_recoil_recover_pitch + mouse_y)
		
		# Weapon inertia / sway
		if weapon_manager and weapon_manager.has_method("apply_mouse_sway"):
			weapon_manager.apply_mouse_sway(event.relative)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if is_in_shop or is_in_workbench or (hud and hud.has_method("is_any_menu_open") and hud.is_any_menu_open()):
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Cloaker short knockdown recovery (1.2s camera tilt + dip + gradual upright recovery)
	if cloaker_stun_timer > 0.0:
		cloaker_stun_timer = maxf(0.0, cloaker_stun_timer - delta)
		var stun_u: float = clampf(cloaker_stun_timer / 1.2, 0.0, 1.0)
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 9.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 9.0 * delta)
		camera.position.y = lerpf(camera.position.y, base_cam_y - 0.55 * stun_u, delta * 12.0)
		camera.rotation.z = lerpf(camera.rotation.z, deg_to_rad(32.0 * cloaker_stun_roll_sign * stun_u), delta * 12.0)
		move_and_slide()
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
	
	var aiming_now: bool = weapon_manager != null and weapon_manager.is_aiming
	var ugl_mode_now: bool = weapon_manager != null and ("is_ugl_mode" in weapon_manager) and weapon_manager.is_ugl_mode
	var ugl_cam_y_boost: float = (0.065 if aiming_now else 0.025) if ugl_mode_now else 0.0
	if direction.length_squared() > 0.001:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Head Bobbing (disabled in ADS so the optic / UGL sight stays rock-solid while moving!)
		if aiming_now:
			camera.position.y = lerpf(camera.position.y, base_cam_y + ugl_cam_y_boost, delta * 14.0)
			camera.position.x = lerpf(camera.position.x, 0.0, delta * 14.0)
			bob_time = 0.0
		else:
			bob_time += delta * (bob_freq * (1.35 if is_sprinting else 1.0))
			camera.position.y = base_cam_y + ugl_cam_y_boost + sin(bob_time) * bob_amplitude
			camera.position.x = cos(bob_time * 0.5) * (bob_amplitude * 0.5)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 4.5 * delta)
		velocity.z = move_toward(velocity.z, 0, current_speed * 4.5 * delta)
		camera.position.y = lerpf(camera.position.y, base_cam_y + ugl_cam_y_boost, delta * 8.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 8.0)
		bob_time = 0.0
		
	# 3D Camera Strafe Tilt / Roll (disabled in ADS)
	var target_roll: float = 0.0 if aiming_now else (-input_dir.x * deg_to_rad(2.2))
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * 10.0)
	
	# 3D Camera Dynamic FOV: during UGL mode, narrow FOV slightly for crisp ballistic grenade lobbing;
	# during normal ADS, main camera stays unzoomed (PiP zooms ONLY inside the optic!)
	if ugl_mode_now and aiming_now:
		target_fov = 70.0
	elif ugl_mode_now:
		target_fov = 80.0
	elif aiming_now:
		target_fov = base_fov
	else:
		target_fov = sprint_fov if is_sprinting else base_fov
	camera.fov = lerpf(camera.fov, target_fov, delta * 10.0)
		
	move_and_slide()
	
	# Weapon movement bobbing
	if weapon_manager and weapon_manager.has_method("apply_movement_bob"):
		var horiz_vel: float = Vector2(velocity.x, velocity.z).length()
		weapon_manager.apply_movement_bob(horiz_vel, is_sprinting, delta)
		
	# Smooth camera recoil kick & partial recovery (vertical climb + horizontal drift)
	var rec_blend: float = 1.0 - exp(-24.0 * delta)
	if absf(cam_recoil_rem_pitch) > 0.00005 or absf(cam_recoil_rem_yaw) > 0.00005:
		var dp: float = cam_recoil_rem_pitch * rec_blend
		var dy: float = cam_recoil_rem_yaw * rec_blend
		cam_recoil_rem_pitch -= dp
		cam_recoil_rem_yaw -= dy
		head.rotation.x = clampf(head.rotation.x + dp, deg_to_rad(-88.0), deg_to_rad(88.0))
		rotate_y(dy)
	elif cam_recoil_recover_pitch > 0.0001:
		var rec_down: float = cam_recoil_recover_pitch * minf(1.0, delta * 6.5)
		cam_recoil_recover_pitch = maxf(0.0, cam_recoil_recover_pitch - rec_down)
		head.rotation.x = clampf(head.rotation.x - rec_down, deg_to_rad(-88.0), deg_to_rad(88.0))

	# Update HUD prompt for nearby Airdrop Crate or Mounted DShK 12.7mm
	if hud and hud.has_method("show_arena_interact_prompt"):
		var mgrs := get_tree().get_nodes_in_group("arena_interactables")
		var prompt_txt: String = ""
		if mgrs.size() > 0 and mgrs[0].has_method("get_nearby_interact_prompt"):
			prompt_txt = mgrs[0].get_nearby_interact_prompt(global_position, mounted_turret)
		hud.show_arena_interact_prompt(prompt_txt)

	# If player is manning a Mounted DShK 12.7mm, lock movement smoothly to GunnerStand
	if is_instance_valid(mounted_turret):
		var sm: Marker3D = mounted_turret.get_meta("stand_marker", null) as Marker3D
		if sm:
			global_position.x = lerpf(global_position.x, sm.global_position.x, delta * 14.0)
			global_position.z = lerpf(global_position.z, sm.global_position.z, delta * 14.0)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Weapon inputs
	handle_weapon_inputs()

func add_camera_recoil(pitch: float, yaw: float) -> void:
	# Positive pitch rotates head.rotation.x UPWARD; yaw rotates body left/right horizontally
	var inst_p: float = pitch * 0.45
	var inst_y: float = yaw * 0.45
	head.rotation.x = clampf(head.rotation.x + inst_p, deg_to_rad(-88.0), deg_to_rad(88.0))
	rotate_y(inst_y)
	cam_recoil_rem_pitch += pitch * 0.55
	cam_recoil_rem_yaw += yaw * 0.55
	# Partial (~35%) muzzle snap settles back automatically; remaining ~65% stays as true climb to control!
	if pitch > 0.0:
		cam_recoil_recover_pitch = minf(cam_recoil_recover_pitch + pitch * 0.35, deg_to_rad(12.0))

func apply_cloaker_knockdown(attacker_pos: Vector3, dmg: float) -> void:
	if is_dead:
		return
	dismount_turret()
	take_damage(dmg)
	if is_dead:
		return
	cloaker_stun_timer = 1.2
	cloaker_stun_roll_sign = 1.0 if randf() < 0.5 else -1.0
	play_sfx(SoundEffects.create_cloaker_knockdown_sound())
	add_camera_shake(0.24)
	# Knock player slightly away from the Cloaker's dropkick!
	var push: Vector3 = global_position - attacker_pos
	push.y = 0.0
	if push.length_squared() > 0.01:
		push = push.normalized()
		velocity.x = push.x * 6.5
		velocity.z = push.z * 6.5
	if hud and hud.has_method("show_arena_toast"):
		hud.show_arena_toast("⚡ КЛОКЕР СБИЛ С НОГ! ПОДЪЁМ...")

func add_camera_shake(intensity: float) -> void:
	if is_dead or not camera:
		return
	var amp := clampf(intensity, 0.0, 0.35)
	camera.position.x += randf_range(-amp, amp) * 0.45
	camera.position.y += randf_range(-amp, amp) * 0.35
	camera.rotation.z += randf_range(-amp, amp) * 0.40

func handle_weapon_inputs() -> void:
	if not weapon_manager or is_dead or get_tree().paused or is_in_shop or is_in_workbench:
		return
	if hud:
		if hud.has_method("is_any_menu_open") and hud.is_any_menu_open():
			return
		if hud.has_node("ShopPanel") and hud.get_node("ShopPanel").visible:
			return
		
	if Input.is_action_just_pressed("weapon_1"):
		weapon_manager.switch_slot(1)
	elif Input.is_action_just_pressed("weapon_2"):
		weapon_manager.switch_slot(2)
	elif Input.is_action_just_pressed("weapon_3"):
		weapon_manager.switch_slot(3)
	elif not weapon_manager.is_aiming:
		if Input.is_action_just_pressed("next_weapon"):
			weapon_manager.switch_next()
		elif Input.is_action_just_pressed("prev_weapon"):
			weapon_manager.switch_prev()
		
	if Input.is_action_just_pressed("reload"):
		weapon_manager.start_reload()
		
	var just_shot: bool = Input.is_action_just_pressed("shoot")
	var is_shooting: bool = just_shot or Input.is_action_pressed("shoot")
	if is_shooting and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
	if is_dead or is_invincible:
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
	sfx.bus = "SFX"
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
	var gs = get_node_or_null("/root/GlobalSettings")
	if gs:
		gs.current_score = money
	score_changed.emit(money)
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		score = money
		var gs = get_node_or_null("/root/GlobalSettings")
		if gs:
			gs.current_score = money
		score_changed.emit(money)
		money_changed.emit(money)
		return true
	return false

func add_score(amount: int) -> void:
	add_money(amount)

func die() -> void:
	if is_dead:
		return
	dismount_turret()
	is_dead = true
	
	# Requirement 7: Halve reserve ammo for each shared caliber pool, keeping exact same magazine ammo
	if weapon_manager and weapon_manager.has_method("halve_all_reserves"):
		weapon_manager.halve_all_reserves()
	elif weapon_manager and weapon_manager.weapons:
		for w in weapon_manager.weapons:
			w.reserve_ammo = int(ceil(float(w.reserve_ammo) / 2.0))
		if weapon_manager.has_method("emit_ammo_state"):
			weapon_manager.emit_ammo_state()
			
	# All other inventory items (vodka_count, armor) remain preserved in full
	player_died.emit()
	
	var tween: Tween = create_tween()
	tween.tween_property(camera, "position:y", 0.25, 0.5)
	tween.parallel().tween_property(camera, "rotation:z", deg_to_rad(45.0), 0.5)

func respawn_at_shop() -> void:
	# 1. Reset camera
	camera.position = Vector3(0, 1.6, 0)
	camera.rotation = Vector3.ZERO
	
	# 2. Teleport to safe location near minivan or arena center
	var spawn_pos := Vector3(0.0, 0.1, 0.0)
	var vans = get_tree().get_nodes_in_group("minivan_shop")
	if vans.size() > 0 and is_instance_valid(vans[0]) and vans[0].visible:
		spawn_pos = vans[0].global_position + Vector3(0.0, 0.1, 3.5)
	global_position = spawn_pos
	velocity = Vector3.ZERO
	
	# 3. Restore player health
	health = max_health
	health_changed.emit(health, max_health)
	
	# 4. Clear dead flag and resume controls
	is_dead = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 5. Update weapon HUD
	if weapon_manager and weapon_manager.has_method("emit_ammo_state"):
		weapon_manager.emit_ammo_state()

func reset_after_wave_restart() -> void:
	respawn_at_shop()

func restart_game() -> void:
	get_tree().reload_current_scene()
