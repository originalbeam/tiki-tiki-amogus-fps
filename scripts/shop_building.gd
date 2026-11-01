class_name ShopBuilding
extends StaticBody3D

signal health_changed(current_hp: float, max_hp: float)
signal shop_destroyed()

const MAX_HEALTH: float = 5000.0
var health: float = 5000.0
var is_destroyed: bool = false

var front_sign_mat: StandardMaterial3D = null
var flash_timer: float = 0.0
var audio_player: AudioStreamPlayer3D = null

# Wooden sliding doors
var left_door: Node3D = null
var right_door: Node3D = null
var door_collision: CollisionShape3D = null
var are_doors_closed: bool = false

# Shop bounds in local space (width 22m, depth 18m, cozy cabin height 3.6m)
# Global position is (0, 0, 11)
# Front facade is at local Z = -9.0 (global Z = 2.0)
# Back wall is at local Z = +9.0 (global Z = 20.0)

func _ready() -> void:
	add_to_group("shop_building")
	health = MAX_HEALTH
	
	collision_layer = 1
	collision_mask = 7
	
	audio_player = AudioStreamPlayer3D.new()
	audio_player.max_distance = 60.0
	audio_player.unit_size = 12.0
	add_child(audio_player)
	
	build_wooden_shop_geometry()
	build_interior_decorations()
	
	# Initial HUD update
	await get_tree().process_frame
	update_hud_health()

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and front_sign_mat:
			front_sign_mat.emission = Color(1.0, 0.72, 0.35)
			front_sign_mat.emission_energy_multiplier = 1.8

func update_hud_health() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p.get_node_or_null("HUD") and p.get_node("HUD").has_method("update_shop_health"):
			p.get_node("HUD").update_shop_health(health, MAX_HEALTH)

func take_damage(amount: float, attacker = null) -> void:
	if is_destroyed:
		return
		
	health = maxf(0.0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	update_hud_health()
			
	# Red flash on lantern/sign
	if front_sign_mat:
		front_sign_mat.emission = Color(1.0, 0.2, 0.15)
		front_sign_mat.emission_energy_multiplier = 3.5
		flash_timer = 0.18
		
	# Wood splinter impact sound
	if audio_player:
		audio_player.stream = SoundEffects.create_hit_sound()
		audio_player.pitch_scale = randf_range(0.65, 0.85)
		audio_player.play()
		
	if health <= 0.0:
		is_destroyed = true
		shop_destroyed.emit()
		trigger_destruction()

func reset_to_half_health() -> void:
	health = MAX_HEALTH * 0.5
	is_destroyed = false
	health_changed.emit(health, MAX_HEALTH)
	update_hud_health()
	open_doors()

func trigger_destruction() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p.get_node_or_null("HUD") and p.get_node("HUD").has_method("trigger_shop_destroyed"):
			p.get_node("HUD").trigger_shop_destroyed()

func get_attack_target_position(from_pos: Vector3) -> Vector3:
	# Front entrance is at global Z = 2.0 (local Z = -9.0)
	var target_x = clampf(from_pos.x, global_position.x - 8.5, global_position.x + 8.5)
	return Vector3(target_x, global_position.y + 1.2, global_position.z - 8.8)

func get_closest_point(from_pos: Vector3) -> Vector3:
	var x_clamped = clampf(from_pos.x, global_position.x - 11.0, global_position.x + 11.0)
	var z_clamped = clampf(from_pos.z, global_position.z - 9.0, global_position.z + 9.0)
	return Vector3(x_clamped, global_position.y + 1.5, z_clamped)

# Wave lifecycle doors & player ejection
func on_wave_started() -> void:
	teleport_player_outside_if_inside()
	close_doors()

func on_wave_cleared() -> void:
	open_doors()

func teleport_player_outside_if_inside() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var p_pos = player.global_position
	
	# Inside shop bounds check
	var min_z = global_position.z - 8.8 # ~2.2m
	var max_z = global_position.z + 8.8 # ~19.8m
	var half_w = 10.5
	
	if p_pos.z >= min_z and p_pos.z <= max_z and absf(p_pos.x - global_position.x) <= half_w:
		# Teleport player in front of shop doors facing the battlefield
		var exit_pos = Vector3(0.0, 0.1, global_position.z - 11.2) # Z ~ -0.2
		player.global_position = exit_pos
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		if audio_player:
			audio_player.stream = SoundEffects.create_player_jump_sound()
			audio_player.pitch_scale = 1.4
			audio_player.play()

func close_doors() -> void:
	are_doors_closed = true
	if door_collision:
		door_collision.disabled = false
		
	if left_door and right_door:
		var t := create_tween()
		t.tween_property(left_door, "rotation:y", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(right_door, "rotation:y", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if audio_player:
		audio_player.stream = SoundEffects.create_magazine_in_sound()
		audio_player.pitch_scale = 0.50
		audio_player.play()

func open_doors() -> void:
	are_doors_closed = false
	if door_collision:
		door_collision.disabled = true
		
	if left_door and right_door:
		var t := create_tween()
		t.tween_property(left_door, "rotation:y", -deg_to_rad(90.0), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(right_door, "rotation:y", deg_to_rad(90.0), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if audio_player:
		audio_player.stream = SoundEffects.create_magazine_out_sound()
		audio_player.pitch_scale = 0.60
		audio_player.play()

# Procedural Realistic Wood Textures (512x512 High-Res with Organic Grain)
static func _generate_plank_texture(base_col: Color, dark_col: Color, num_planks: int = 8, is_vertical: bool = false) -> ImageTexture:
	var w: int = 512
	var h: int = 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	
	var row_size: float = float(h if not is_vertical else w) / float(num_planks)
	var plank_len: float = row_size * 3.8 # Elongated brick-pattern board proportions
	
	for y in range(h):
		for x in range(w):
			var along_axis: float = float(x if not is_vertical else y)
			var across_axis: float = float(y if not is_vertical else x)
			
			var row_idx: int = int(across_axis / row_size)
			var in_row: float = fmod(across_axis, row_size)
			if in_row < 0.0:
				in_row += row_size
				
			# Staggered running brick bond pattern (half plank shift per row)
			var row_shift: float = float(row_idx % 2) * (plank_len * 0.5)
			var shifted_along: float = along_axis + row_shift
			var col_idx: int = int(shifted_along / plank_len)
			var in_col: float = fmod(shifted_along, plank_len)
			if in_col < 0.0:
				in_col += plank_len
				
			# Seams: horizontal between rows + vertical butt joints between boards
			var is_horizontal_seam: bool = (in_row < 2.5 or in_row > row_size - 2.5)
			var is_vertical_seam: bool = (in_col < 2.5 or in_col > plank_len - 2.5)
			
			if is_horizontal_seam or is_vertical_seam:
				# Dark groove shadow
				img.set_pixel(x, y, Color(0.08, 0.05, 0.02, 1.0))
				continue
				
			# Subtle wrought-iron nail heads near plank ends
			var dist_to_end: float = minf(in_col, plank_len - in_col)
			var nail_dx: float = absf(dist_to_end - 10.0)
			if nail_dx < 2.4:
				var dy1: float = absf(in_row - (row_size * 0.28))
				var dy2: float = absf(in_row - (row_size * 0.72))
				var min_dy: float = minf(dy1, dy2)
				var d_nail: float = sqrt(nail_dx * nail_dx + min_dy * min_dy)
				if d_nail < 2.2:
					if d_nail < 1.0:
						# Metallic nail core highlight
						img.set_pixel(x, y, Color(0.36, 0.33, 0.30, 1.0))
					else:
						# Indented nail rim shadow
						img.set_pixel(x, y, Color(0.12, 0.09, 0.07, 1.0))
					continue
				
			# Lap siding / overlapping board shadow & highlight effect
			var lap_t: float = in_row / row_size # 0.0 at top, 1.0 at bottom
			var lap_factor: float = 1.0
			if lap_t > 0.70:
				# Underside shadow of overlapping board above
				lap_factor = lerpf(1.0, 0.82, (lap_t - 0.70) / 0.30)
			elif lap_t < 0.25:
				# Highlight on top edge of plank
				lap_factor = lerpf(1.08, 1.0, lap_t / 0.25)
				
			# Unique identity per individual board
			var board_id: int = (row_idx * 17 + col_idx * 31) & 0x7FFFFFFF
			var board_shift: float = sin(float(board_id) * 2.1) * 0.08
			
			# Wood grain rings and organic fiber noise
			var n_val: float = noise.get_noise_2d(along_axis * 0.35, across_axis * 2.2 + float(board_id % 37) * 19.0)
			var fine_grain: float = sin(along_axis * 0.85 + n_val * 5.0) * 0.05
			var wave: float = sin(across_axis * 0.5 + n_val * 4.0) * 0.5 + 0.5
			var t: float = clampf(wave * 0.42 + n_val * 0.35 + fine_grain + 0.35, 0.0, 1.0)
			
			var pixel_col := dark_col.lerp(base_col, t)
			pixel_col.r = clampf((pixel_col.r + board_shift) * lap_factor, 0.0, 1.0)
			pixel_col.g = clampf((pixel_col.g + board_shift * 0.8) * lap_factor, 0.0, 1.0)
			pixel_col.b = clampf((pixel_col.b + board_shift * 0.5) * lap_factor, 0.0, 1.0)
			
			img.set_pixel(x, y, pixel_col)
			
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _generate_plank_normal_map(num_planks: int = 8, is_vertical: bool = false) -> ImageTexture:
	var w: int = 512
	var h: int = 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var row_size: float = float(h if not is_vertical else w) / float(num_planks)
	var plank_len: float = row_size * 3.8
	
	for y in range(h):
		for x in range(w):
			var along_axis: float = float(x if not is_vertical else y)
			var across_axis: float = float(y if not is_vertical else x)
			
			var row_idx: int = int(across_axis / row_size)
			var in_row: float = fmod(across_axis, row_size)
			if in_row < 0.0:
				in_row += row_size
				
			var row_shift: float = float(row_idx % 2) * (plank_len * 0.5)
			var shifted_along: float = along_axis + row_shift
			var in_col: float = fmod(shifted_along, plank_len)
			if in_col < 0.0:
				in_col += plank_len
				
			var lap_t: float = in_row / row_size
			
			# Base normal with gentle lap siding tilt
			var nx: float = 0.5
			var ny: float = lerpf(0.53, 0.47, lap_t)
			
			# Beveled edges along horizontal row grooves
			if in_row < 3.5:
				ny = 0.82 if not is_vertical else 0.5
				if is_vertical:
					nx = 0.18
			elif in_row > row_size - 3.5:
				ny = 0.18 if not is_vertical else 0.5
				if is_vertical:
					nx = 0.82
					
			# Beveled edges along vertical brick butt joints
			if in_col < 3.5:
				if not is_vertical:
					nx = 0.20
				else:
					ny = 0.80
			elif in_col > plank_len - 3.5:
				if not is_vertical:
					nx = 0.80
				else:
					ny = 0.20
					
			# Dimple normal for subtle nail heads
			var dist_to_end: float = minf(in_col, plank_len - in_col)
			var nail_dx: float = absf(dist_to_end - 10.0)
			if nail_dx < 2.4:
				var dy1: float = in_row - (row_size * 0.28)
				var dy2: float = in_row - (row_size * 0.72)
				var chosen_dy: float = dy1 if absf(dy1) < absf(dy2) else dy2
				var d_nail: float = sqrt(nail_dx * nail_dx + chosen_dy * chosen_dy)
				if d_nail < 2.4:
					var sign_x: float = 1.0 if in_col < (plank_len * 0.5) else -1.0
					var signed_dx: float = (dist_to_end - 10.0) * sign_x
					var n_factor: float = (2.4 - d_nail) / 2.4
					var ndx: float = (signed_dx / 2.4) * 0.30 * n_factor
					var ndy: float = (chosen_dy / 2.4) * 0.30 * n_factor
					if not is_vertical:
						nx = clampf(nx - ndx, 0.15, 0.85)
						ny = clampf(ny - ndy, 0.15, 0.85)
					else:
						nx = clampf(nx - ndy, 0.15, 0.85)
						ny = clampf(ny - ndx, 0.15, 0.85)
					
			img.set_pixel(x, y, Color(nx, ny, 1.0, 1.0))
			
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func build_wooden_shop_geometry() -> void:
	# 1. Realistic wood plank wall texture & material with seamless triplanar tiling
	var tex_wall_albedo := _generate_plank_texture(Color(0.50, 0.34, 0.20), Color(0.32, 0.20, 0.11), 8, false)
	var tex_wall_normal := _generate_plank_normal_map(8, false)
	
	var mat_wood_wall := StandardMaterial3D.new()
	mat_wood_wall.albedo_texture = tex_wall_albedo
	mat_wood_wall.normal_enabled = true
	mat_wood_wall.normal_texture = tex_wall_normal
	mat_wood_wall.roughness = 0.82
	mat_wood_wall.metallic = 0.0
	mat_wood_wall.uv1_triplanar = true
	mat_wood_wall.uv1_world_triplanar = true
	mat_wood_wall.uv1_triplanar_sharpness = 2.0
	mat_wood_wall.uv1_scale = Vector3(0.8, 0.8, 0.8)
	mat_wood_wall.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# 2. Dark heavy timber beams & posts texture & material
	var tex_dark_albedo := _generate_plank_texture(Color(0.26, 0.16, 0.09), Color(0.14, 0.09, 0.05), 6, true)
	var tex_dark_normal := _generate_plank_normal_map(6, true)
	
	var mat_wood_dark := StandardMaterial3D.new()
	mat_wood_dark.albedo_texture = tex_dark_albedo
	mat_wood_dark.normal_enabled = true
	mat_wood_dark.normal_texture = tex_dark_normal
	mat_wood_dark.roughness = 0.88
	mat_wood_dark.metallic = 0.0
	mat_wood_dark.uv1_triplanar = true
	mat_wood_dark.uv1_world_triplanar = true
	mat_wood_dark.uv1_triplanar_sharpness = 2.0
	mat_wood_dark.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat_wood_dark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# 3. Weathered roof shakes / shingles
	var tex_roof_albedo := _generate_plank_texture(Color(0.24, 0.16, 0.11), Color(0.13, 0.08, 0.05), 10, false)
	var tex_roof_normal := _generate_plank_normal_map(10, false)
	
	var mat_wood_roof := StandardMaterial3D.new()
	mat_wood_roof.albedo_texture = tex_roof_albedo
	mat_wood_roof.normal_enabled = true
	mat_wood_roof.normal_texture = tex_roof_normal
	mat_wood_roof.roughness = 0.90
	mat_wood_roof.uv1_triplanar = true
	mat_wood_roof.uv1_world_triplanar = true
	mat_wood_roof.uv1_triplanar_sharpness = 2.0
	mat_wood_roof.uv1_scale = Vector3(0.8, 0.8, 0.8)
	mat_wood_roof.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# 4. Clean, semi-transparent panoramic glass
	# Crystal clear, without shutters, without dividing mullions or wood overlays
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.72, 0.88, 0.98, 0.18)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.03
	mat_glass.metallic = 0.10
	mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Warm lantern / sign glow
	front_sign_mat = StandardMaterial3D.new()
	front_sign_mat.albedo_color = Color(1.0, 0.72, 0.35)
	front_sign_mat.emission_enabled = true
	front_sign_mat.emission = Color(1.0, 0.72, 0.35)
	front_sign_mat.emission_energy_multiplier = 1.8

	# Dimensions: width 22m (X: -11 to +11), depth 18m (Z: -9 to +9)
	# Cozy ceiling height: H = 3.6m (center Y = 1.8m)
	# All seams mathematically aligned with zero gaps:
	
	# 1. Back Wall (Z = +9.0, X in [-11.0, +11.0], Y in [0.0, 3.6])
	_add_wall_box(Vector3(0, 1.8, 9.0), Vector3(22.0, 3.6, 0.6), mat_wood_wall)
	
	# 2. Left Wall (X = -11.0, Z in [-9.0, +9.0], Y in [0.0, 3.6])
	_add_wall_box(Vector3(-11.0, 1.8, 0), Vector3(0.6, 3.6, 18.0), mat_wood_wall)
	
	# 3. Right Wall (X = +11.0, Z in [-9.0, +9.0], Y in [0.0, 3.6])
	_add_wall_box(Vector3(11.0, 1.8, 0), Vector3(0.6, 3.6, 18.0), mat_wood_wall)
	
	# 4. Front Facade (Z = -9.0):
	# Outer Corner Walls (height 2.75m from Y=0 to Y=2.75, sits neatly beneath header beam at Y=2.75..3.60 to avoid Z-fighting):
	# Left outer corner: X in [-11.0, -8.5] (width 2.5m, center X = -9.75, center Y = 1.375)
	_add_wall_box(Vector3(-9.75, 1.375, -9.0), Vector3(2.5, 2.75, 0.6), mat_wood_wall)
	# Right outer corner: X in [+8.5, +11.0] (width 2.5m, center X = +9.75, center Y = 1.375)
	_add_wall_box(Vector3(9.75, 1.375, -9.0), Vector3(2.5, 2.75, 0.6), mat_wood_wall)
	
	# Sills below panoramic windows (Y in [0.0, 0.75], height 0.75m):
	# Left sill: X in [-8.5, -2.0] (width 6.5m, center X = -5.25)
	_add_wall_box(Vector3(-5.25, 0.375, -9.0), Vector3(6.5, 0.75, 0.6), mat_wood_wall)
	# Right sill: X in [+2.0, +8.5] (width 6.5m, center X = +5.25)
	_add_wall_box(Vector3(5.25, 0.375, -9.0), Vector3(6.5, 0.75, 0.6), mat_wood_wall)
	
	# Continuous Front Header Beam (Y in [2.75, 3.60], height 0.85m, spans full 22m with ZERO seams)
	_add_wall_box(Vector3(0, 3.175, -9.0), Vector3(22.0, 0.85, 0.6), mat_wood_dark)
	
	# Heavy Timber Corner Pillars (overlaps all 4 corners completely, zero gaps)
	for px in [-11.0, 11.0]:
		for pz in [-9.0, 9.0]:
			var pillar := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.8, 3.65, 0.8)
			pillar.mesh = pm
			pillar.material_override = mat_wood_dark
			pillar.position = Vector3(px, 1.825, pz)
			add_child(pillar)
			
	# Timber Entrance Doorframe Posts at X = -2.1 and +2.1 (height 2.75m)
	for dx in [-2.1, 2.1]:
		var post := MeshInstance3D.new()
		var dm := BoxMesh.new()
		dm.size = Vector3(0.28, 2.75, 0.65)
		post.mesh = dm
		post.material_override = mat_wood_dark
		post.position = Vector3(dx, 1.375, -9.0)
		add_child(post)

	# 5. SEMI-TRANSPARENT PANORAMIC WINDOWS with Physical Collision & Zero Z-Fighting
	for wx in [-5.25, 5.25]:
		# Clean, transparent glass pane (slightly recessed from sill/lintel to prevent coplanar Z-fighting)
		var glass := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(6.44, 1.94, 0.04)
		glass.mesh = gm
		glass.material_override = mat_glass
		glass.position = Vector3(wx, 1.75, -9.0)
		add_child(glass)
		
		# Solid physical collision for panoramic window glass
		var glass_body := StaticBody3D.new()
		glass_body.name = "WindowGlassCollision_" + str(int(wx))
		var g_col := CollisionShape3D.new()
		var g_shape := BoxShape3D.new()
		g_shape.size = Vector3(6.46, 2.0, 0.15)
		g_col.shape = g_shape
		g_col.position = Vector3(wx, 1.75, -9.0)
		glass_body.add_child(g_col)
		add_child(glass_body)
		
		# Exterior casing trim seated proudly at facade surface (Z = -9.32), zero Z-fighting with wall structure
		var trim_top := MeshInstance3D.new()
		var tm_h := BoxMesh.new()
		tm_h.size = Vector3(6.46, 0.08, 0.06)
		trim_top.mesh = tm_h
		trim_top.material_override = mat_wood_dark
		trim_top.position = Vector3(wx, 2.71, -9.32)
		add_child(trim_top)
		
		var trim_bot := MeshInstance3D.new()
		var tm_b := BoxMesh.new()
		tm_b.size = Vector3(6.46, 0.08, 0.06)
		trim_bot.mesh = tm_b
		trim_bot.material_override = mat_wood_dark
		trim_bot.position = Vector3(wx, 0.79, -9.32)
		add_child(trim_bot)
		
		var trim_left := MeshInstance3D.new()
		var tm_v := BoxMesh.new()
		tm_v.size = Vector3(0.08, 1.84, 0.06)
		trim_left.mesh = tm_v
		trim_left.material_override = mat_wood_dark
		trim_left.position = Vector3(wx - 3.21, 1.75, -9.32)
		add_child(trim_left)
		
		var trim_right := MeshInstance3D.new()
		trim_right.mesh = tm_v
		trim_right.material_override = mat_wood_dark
		trim_right.position = Vector3(wx + 3.21, 1.75, -9.32)
		add_child(trim_right)

	# 6. Roof System (Low-ceiling, snug fit, zero gaps, zero coplanar overlap)
	_add_wall_box(Vector3(0, 3.70, 0), Vector3(22.6, 0.20, 18.6), mat_wood_roof)
	
	# Overhanging Weathered Timber Eaves
	var eaves := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(23.2, 0.10, 19.2)
	eaves.mesh = em
	eaves.material_override = mat_wood_dark
	eaves.position = Vector3(0, 3.85, 0)
	add_child(eaves)
	
	# Low Gable Roof Ridge
	var ridge := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(22.4, 0.25, 12.0)
	ridge.mesh = rm
	ridge.material_override = mat_wood_roof
	ridge.position = Vector3(0, 4.025, 0)
	add_child(ridge)
	
	# Timber Porch Canopy over entrance (width 22.8m, depth 2.2m, overhangs to Z = -11.2)
	var porch := MeshInstance3D.new()
	var pcm := BoxMesh.new()
	pcm.size = Vector3(22.8, 0.22, 2.4)
	porch.mesh = pcm
	porch.material_override = mat_wood_dark
	porch.position = Vector3(0, 3.05, -10.1)
	porch.rotation_degrees = Vector3(-4.5, 0, 0)
	add_child(porch)
	
	# 4 Wooden Porch Support Beams
	for sx in [-10.8, -2.15, 2.15, 10.8]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 2.85, 0.22)
		beam.mesh = bm
		beam.material_override = mat_wood_dark
		beam.position = Vector3(sx, 1.425, -11.2)
		add_child(beam)

	# 7. Rustic Carved Storefront Sign above entrance
	var sign_board := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(6.5, 0.65, 0.12)
	sign_board.mesh = sbm
	sign_board.material_override = mat_wood_dark
	sign_board.position = Vector3(0, 3.175, -9.35)
	add_child(sign_board)
	
	var sign_label := Label3D.new()
	sign_label.text = "М А Г А З И Н"
	sign_label.font_size = 56
	sign_label.modulate = Color(1.0, 0.92, 0.70)
	sign_label.outline_modulate = Color(0.12, 0.08, 0.04)
	sign_label.outline_size = 10
	sign_label.position = Vector3(0, 3.175, -9.43)
	add_child(sign_label)

	# Warm Entrance Hanging Lanterns
	for lx in [-2.4, 2.4]:
		var lantern := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.30, 0.42, 0.30)
		lantern.mesh = lm
		lantern.material_override = front_sign_mat
		lantern.position = Vector3(lx, 2.45, -9.45)
		add_child(lantern)
		
		var omni := OmniLight3D.new()
		omni.light_color = Color(1.0, 0.78, 0.42)
		omni.light_energy = 2.2
		omni.omni_range = 9.0
		omni.position = Vector3(lx, 2.30, -9.55)
		add_child(omni)

	# 8. Hinged Wooden Double Doors at entrance (Mounted on heavy wrought-iron hinges)
	build_hinged_doors(mat_wood_dark, mat_wood_wall, tex_wall_albedo, tex_wall_normal, tex_dark_albedo, tex_dark_normal)

func build_hinged_doors(mat_frame: Material, mat_planks: Material, tex_wall_albedo: Texture, tex_wall_normal: Texture, tex_dark_albedo: Texture, tex_dark_normal: Texture) -> void:
	# Dedicated materials with local triplanar mapping (texture rotates with door leaf)
	var mat_door_planks := StandardMaterial3D.new()
	mat_door_planks.albedo_texture = tex_wall_albedo
	mat_door_planks.normal_enabled = true
	mat_door_planks.normal_texture = tex_wall_normal
	mat_door_planks.roughness = 0.80
	mat_door_planks.metallic = 0.0
	mat_door_planks.uv1_triplanar = true
	mat_door_planks.uv1_world_triplanar = false
	mat_door_planks.uv1_triplanar_sharpness = 2.0
	mat_door_planks.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat_door_planks.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var mat_door_frame := StandardMaterial3D.new()
	mat_door_frame.albedo_texture = tex_dark_albedo
	mat_door_frame.normal_enabled = true
	mat_door_frame.normal_texture = tex_dark_normal
	mat_door_frame.roughness = 0.85
	mat_door_frame.metallic = 0.0
	mat_door_frame.uv1_triplanar = true
	mat_door_frame.uv1_world_triplanar = false
	mat_door_frame.uv1_triplanar_sharpness = 2.0
	mat_door_frame.uv1_scale = Vector3(1.2, 1.2, 1.2)
	mat_door_frame.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var mat_iron_hardware := StandardMaterial3D.new()
	mat_iron_hardware.albedo_color = Color(0.12, 0.12, 0.13)
	mat_iron_hardware.metallic = 0.85
	mat_iron_hardware.roughness = 0.35

	var mat_door_handle := StandardMaterial3D.new()
	mat_door_handle.albedo_color = Color(0.68, 0.52, 0.22)
	mat_door_handle.metallic = 0.82
	mat_door_handle.roughness = 0.28

	# Door opening: width 4.0m (X: -2.0 to +2.0), height 2.75m
	# Height elevated to Y = 1.43m so door leaf bottom sits cleanly 2cm above floorboards (Y = 0.12m), zero floor clipping!
	left_door = Node3D.new()
	left_door.name = "LeftDoor"
	left_door.position = Vector3(-2.0, 1.43, -9.0)
	left_door.rotation.y = -deg_to_rad(90.0) # Open by default between waves
	add_child(left_door)
	_build_single_hinged_door_leaf(left_door, true, mat_door_planks, mat_door_frame, mat_iron_hardware, mat_door_handle)

	# Right Door: pivot at right hinge post (X = +2.0, Z = -9.0)
	right_door = Node3D.new()
	right_door.name = "RightDoor"
	right_door.position = Vector3(2.0, 1.43, -9.0)
	right_door.rotation.y = deg_to_rad(90.0) # Open by default between waves
	add_child(right_door)
	_build_single_hinged_door_leaf(right_door, false, mat_door_planks, mat_door_frame, mat_iron_hardware, mat_door_handle)

	door_collision = CollisionShape3D.new()
	door_collision.name = "DoorCollision"
	var dcs := BoxShape3D.new()
	dcs.size = Vector3(4.0, 2.58, 0.35)
	door_collision.shape = dcs
	door_collision.position = Vector3(0, 1.43, -9.0)
	door_collision.disabled = true # Initially open
	add_child(door_collision)

func _build_single_hinged_door_leaf(door: Node3D, is_left: bool, mat_planks: Material, mat_frame: Material, mat_iron: Material, mat_brass: Material) -> void:
	var dir_x: float = 1.0 if is_left else -1.0
	var leaf_w: float = 1.98 # Leaves meet neatly at center without overlapping coplanarly
	var leaf_h: float = 2.58 # Fits with 2cm clearance above floor and under lintel
	var leaf_th: float = 0.05
	var frame_th: float = 0.085
	var stile_w: float = 0.12
	var rail_w: float = leaf_w - (stile_w * 2.0)

	# 1. Main vertical plank wooden panel (inset inside the frame)
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(leaf_w, leaf_h, leaf_th)
	panel.mesh = pm
	panel.material_override = mat_planks
	panel.position = Vector3(dir_x * (leaf_w * 0.5), 0, 0)
	door.add_child(panel)

	# 2. Outer Timber Perimeter Frame & Horizontal Rails (strictly non-overlapping joinery)
	# Vertical edge stiles (full door height)
	var stile_hinge := MeshInstance3D.new()
	var sm_h := BoxMesh.new()
	sm_h.size = Vector3(stile_w, leaf_h, frame_th)
	stile_hinge.mesh = sm_h
	stile_hinge.material_override = mat_frame
	stile_hinge.position = Vector3(dir_x * (stile_w * 0.5), 0, 0)
	door.add_child(stile_hinge)

	var stile_meet := MeshInstance3D.new()
	var sm_m := BoxMesh.new()
	sm_m.size = Vector3(stile_w, leaf_h, frame_th)
	stile_meet.mesh = sm_m
	stile_meet.material_override = mat_frame
	stile_meet.position = Vector3(dir_x * (leaf_w - stile_w * 0.5), 0, 0)
	door.add_child(stile_meet)

	# Horizontal rails fitted strictly BETWEEN the stiles (zero overlap, zero Z-fighting)
	var top_rail := MeshInstance3D.new()
	var trm := BoxMesh.new()
	trm.size = Vector3(rail_w, 0.14, frame_th)
	top_rail.mesh = trm
	top_rail.material_override = mat_frame
	top_rail.position = Vector3(dir_x * (leaf_w * 0.5), leaf_h * 0.5 - 0.07, 0)
	door.add_child(top_rail)

	var bot_rail := MeshInstance3D.new()
	var brm := BoxMesh.new()
	brm.size = Vector3(rail_w, 0.16, frame_th)
	bot_rail.mesh = brm
	bot_rail.material_override = mat_frame
	bot_rail.position = Vector3(dir_x * (leaf_w * 0.5), -leaf_h * 0.5 + 0.08, 0)
	door.add_child(bot_rail)

	var mid_rail := MeshInstance3D.new()
	var mrm := BoxMesh.new()
	mrm.size = Vector3(rail_w, 0.12, frame_th)
	mid_rail.mesh = mrm
	mid_rail.material_override = mat_frame
	mid_rail.position = Vector3(dir_x * (leaf_w * 0.5), 0.0, 0)
	door.add_child(mid_rail)

	# Center meeting astragal trim on left door (covers meeting seam from outside cleanly)
	if is_left:
		var astragal := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.04, leaf_h, 0.02)
		astragal.mesh = am
		astragal.material_override = mat_frame
		astragal.position = Vector3(leaf_w, 0, (frame_th * 0.5) + 0.01)
		door.add_child(astragal)

	# 3. Heavy Wrought-Iron Strap Hinges (Петли)
	for y_hinge in [0.80, -0.80]:
		# Hinge Barrel / Knuckle right at the pivot axis (X = 0)
		var knuckle := MeshInstance3D.new()
		var km := CylinderMesh.new()
		km.top_radius = 0.028
		km.bottom_radius = 0.028
		km.height = 0.16
		knuckle.mesh = km
		knuckle.material_override = mat_iron
		knuckle.position = Vector3(0, y_hinge, 0)
		door.add_child(knuckle)

		# Hinge pin center cap
		var cap := MeshInstance3D.new()
		var cpm := SphereMesh.new()
		cpm.radius = 0.028
		cpm.height = 0.04
		cap.mesh = cpm
		cap.material_override = mat_iron
		cap.position = Vector3(0, y_hinge + 0.08, 0)
		door.add_child(cap)

		# Long wrought-iron strap extending onto the door leaf (both faces, placed proud of frame)
		for side_z in [-(frame_th * 0.5 + 0.006), (frame_th * 0.5 + 0.006)]:
			var strap := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.62, 0.065, 0.012)
			strap.mesh = sm
			strap.material_override = mat_iron
			strap.position = Vector3(dir_x * 0.31, y_hinge, side_z)
			door.add_child(strap)

			# Decorative iron dome rivets along the strap
			for ri in range(3):
				var rivet := MeshInstance3D.new()
				var rm := CylinderMesh.new()
				rm.top_radius = 0.015
				rm.bottom_radius = 0.015
				rm.height = 0.016
				rivet.mesh = rm
				rivet.material_override = mat_iron
				rivet.rotation_degrees = Vector3(90, 0, 0)
				rivet.position = Vector3(dir_x * (0.12 + ri * 0.18), y_hinge, side_z + (0.007 if side_z > 0 else -0.007))
				door.add_child(rivet)
				rivet.position = Vector3(dir_x * (0.12 + ri * 0.20), y_hinge, side_z + (0.008 if side_z > 0 else -0.008))
				door.add_child(rivet)

	# 4. Forged Iron Handles (Ручки) near the free edge
	var handle_x: float = dir_x * (leaf_w - 0.18)
	var handle_y: float = -0.05
	for side_z in [-0.052, 0.052]:
		var plate := MeshInstance3D.new()
		var plm := BoxMesh.new()
		plm.size = Vector3(0.06, 0.30, 0.014)
		plate.mesh = plm
		plate.material_override = mat_iron
		plate.position = Vector3(handle_x, handle_y, side_z)
		door.add_child(plate)

		var handle := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.025, 0.20, 0.05)
		handle.mesh = hm
		handle.material_override = mat_brass
		var z_offset: float = 0.035 if side_z > 0 else -0.035
		handle.position = Vector3(handle_x, handle_y, side_z + z_offset)
		door.add_child(handle)

	# Interior slide latch bolt
	var latch := MeshInstance3D.new()
	var ltm := BoxMesh.new()
	ltm.size = Vector3(0.24, 0.04, 0.03)
	latch.mesh = ltm
	latch.material_override = mat_iron
	latch.position = Vector3(dir_x * (leaf_w - 0.12), handle_y + 0.22, 0.055)
	door.add_child(latch)

func build_interior_decorations() -> void:
	# Materials with warm wood textures & finishes (with seamless triplanar tiling)
	var tex_floor_albedo := _generate_plank_texture(Color(0.44, 0.28, 0.15), Color(0.28, 0.17, 0.09), 10, true)
	var tex_floor_normal := _generate_plank_normal_map(10, true)
	
	var mat_floor := StandardMaterial3D.new()
	mat_floor.albedo_texture = tex_floor_albedo
	mat_floor.normal_enabled = true
	mat_floor.normal_texture = tex_floor_normal
	mat_floor.roughness = 0.72
	mat_floor.uv1_triplanar = true
	mat_floor.uv1_world_triplanar = true
	mat_floor.uv1_triplanar_sharpness = 2.0
	mat_floor.uv1_scale = Vector3(0.8, 0.8, 0.8)
	mat_floor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var tex_shelf_albedo := _generate_plank_texture(Color(0.28, 0.18, 0.10), Color(0.16, 0.10, 0.06), 6, true)
	var tex_shelf_normal := _generate_plank_normal_map(6, true)
	
	var mat_wood_dark := StandardMaterial3D.new()
	mat_wood_dark.albedo_texture = tex_shelf_albedo
	mat_wood_dark.normal_enabled = true
	mat_wood_dark.normal_texture = tex_shelf_normal
	mat_wood_dark.roughness = 0.85
	mat_wood_dark.uv1_triplanar = true
	mat_wood_dark.uv1_world_triplanar = true
	mat_wood_dark.uv1_triplanar_sharpness = 2.0
	mat_wood_dark.uv1_scale = Vector3(1.2, 1.2, 1.2)
	mat_wood_dark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var mat_counter := StandardMaterial3D.new()
	mat_counter.albedo_color = Color(0.48, 0.30, 0.16)
	mat_counter.roughness = 0.65
	
	var mat_crate := StandardMaterial3D.new()
	mat_crate.albedo_color = Color(0.48, 0.34, 0.20)
	mat_crate.roughness = 0.85
	
	var mat_barrel := StandardMaterial3D.new()
	mat_barrel.albedo_color = Color(0.36, 0.22, 0.12)
	mat_barrel.roughness = 0.80
	
	# Dedicated prop materials
	var mat_gun_metal := StandardMaterial3D.new()
	mat_gun_metal.albedo_color = Color(0.18, 0.19, 0.22)
	mat_gun_metal.metallic = 0.85
	mat_gun_metal.roughness = 0.35
	
	var mat_gun_wood := StandardMaterial3D.new()
	mat_gun_wood.albedo_color = Color(0.45, 0.22, 0.10)
	mat_gun_wood.roughness = 0.60
	
	var mat_gun_gold := StandardMaterial3D.new()
	mat_gun_gold.albedo_color = Color(0.96, 0.80, 0.26)
	mat_gun_gold.metallic = 0.92
	mat_gun_gold.roughness = 0.20
	
	var mat_gun_chrome := StandardMaterial3D.new()
	mat_gun_chrome.albedo_color = Color(0.88, 0.90, 0.92)
	mat_gun_chrome.metallic = 0.95
	mat_gun_chrome.roughness = 0.15
	
	var mat_knife_blade := StandardMaterial3D.new()
	mat_knife_blade.albedo_color = Color(0.86, 0.88, 0.92)
	mat_knife_blade.metallic = 0.95
	mat_knife_blade.roughness = 0.15
	
	var mat_ammo_olive := StandardMaterial3D.new()
	mat_ammo_olive.albedo_color = Color(0.22, 0.30, 0.16)
	mat_ammo_olive.metallic = 0.65
	mat_ammo_olive.roughness = 0.45
	
	var mat_ammo_red := StandardMaterial3D.new()
	mat_ammo_red.albedo_color = Color(0.85, 0.14, 0.10)
	mat_ammo_red.roughness = 0.40
	
	var mat_ammo_brass := StandardMaterial3D.new()
	mat_ammo_brass.albedo_color = Color(0.92, 0.78, 0.25)
	mat_ammo_brass.metallic = 0.90
	mat_ammo_brass.roughness = 0.25
	
	var mat_med_white := StandardMaterial3D.new()
	mat_med_white.albedo_color = Color(0.92, 0.92, 0.90)
	mat_med_white.roughness = 0.35
	
	var mat_med_red := StandardMaterial3D.new()
	mat_med_red.albedo_color = Color(0.92, 0.10, 0.10)
	mat_med_red.roughness = 0.40
	
	var mat_bottle_glass := StandardMaterial3D.new()
	mat_bottle_glass.albedo_color = Color(0.82, 0.92, 0.86, 0.40)
	mat_bottle_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bottle_glass.roughness = 0.08
	
	var mat_bottle_label := StandardMaterial3D.new()
	mat_bottle_label.albedo_color = Color(0.95, 0.95, 0.92)
	mat_bottle_label.roughness = 0.60
	
	var mat_bottle_gold := StandardMaterial3D.new()
	mat_bottle_gold.albedo_color = Color(0.92, 0.76, 0.22)
	mat_bottle_gold.metallic = 0.85
	mat_bottle_gold.roughness = 0.25
	
	var mat_vitrine_glass := StandardMaterial3D.new()
	mat_vitrine_glass.albedo_color = Color(0.82, 0.94, 1.0, 0.18)
	mat_vitrine_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vitrine_glass.roughness = 0.03
	mat_vitrine_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 1. Wooden Floorboards (Elevated cleanly above terrain to prevent Z-fighting)
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(21.8, 0.12, 17.8)
	floor_mesh.mesh = fm
	floor_mesh.material_override = mat_floor
	floor_mesh.position = Vector3(0, 0.06, 0)
	add_child(floor_mesh)

	# 2. Warm Interior Lantern Chandeliers (adjusted for 3.6m ceiling height)
	for lx in [-5.5, 5.5]:
		for lz in [-4.0, 3.0]:
			var chain := MeshInstance3D.new()
			var chm := CylinderMesh.new()
			chm.top_radius = 0.03
			chm.bottom_radius = 0.03
			chm.height = 0.8
			chain.mesh = chm
			chain.material_override = mat_wood_dark
			chain.position = Vector3(lx, 3.2, lz)
			add_child(chain)
			
			var omni := OmniLight3D.new()
			omni.light_color = Color(1.0, 0.82, 0.48)
			omni.light_energy = 2.4
			omni.omni_range = 12.0
			omni.position = Vector3(lx, 2.7, lz)
			add_child(omni)

	# 3. WINDOW DISPLAY VITRINES (Directly behind the left & right panoramic windows, visible from outside!)
	# A) Left Window Vitrine (X = -5.25, Z = -7.6):
	var vitrine_left := _build_glass_vitrine(Vector3(-5.25, 0.0, -7.6), Vector3(5.6, 1.25, 1.0), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_ak(Vector3(-1.4, 0.76, 0.0), Vector3(0, 8.0, 5.0), vitrine_left, mat_gun_metal, mat_gun_wood)
	_build_decorative_knife(Vector3(0.6, 0.72, 0.15), Vector3(0, -25.0, 0), vitrine_left, mat_knife_blade, mat_gun_wood)
	_build_ammo_tin(Vector3(1.7, 0.72, -0.1), 12.0, vitrine_left, mat_ammo_olive, mat_wood_dark)
	_build_shotgun_shell_box(Vector3(-0.1, 0.72, -0.15), vitrine_left, mat_ammo_red, mat_ammo_brass)
	
	# B) Right Window Vitrine (X = +5.25, Z = -7.6):
	var vitrine_right := _build_glass_vitrine(Vector3(5.25, 0.0, -7.6), Vector3(5.6, 1.25, 1.0), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_shotgun(Vector3(-1.3, 0.76, 0.0), Vector3(0, -6.0, 4.0), vitrine_right, mat_gun_metal, mat_gun_wood)
	_build_decorative_pistol(Vector3(0.5, 0.74, 0.12), Vector3(0, 30.0, 15.0), vitrine_right, mat_gun_chrome, mat_gun_wood)
	_build_medkit(Vector3(1.6, 0.72, 0.0), -15.0, vitrine_right, mat_med_white, mat_med_red)
	_build_ammo_tin(Vector3(-0.2, 0.72, -0.15), -10.0, vitrine_right, mat_ammo_olive, mat_wood_dark)

	# 4. MAIN BACK WALL GUN RACK & SHOWCASE (Center Back Wall: X in [-4.5, 4.5], Z = +8.6)
	_build_back_wall_gun_rack(Vector3(0, 0.0, 8.5), self, mat_wood_dark, mat_gun_metal, mat_gun_wood, mat_ammo_olive)

	# 5. BACK-LEFT MEDICAL & RATION SHELF WALL (X in [-9.5, -5.5], Z = 8.5)
	_build_medical_and_provisions_shelf(Vector3(-7.5, 0.0, 8.5), self, mat_wood_dark, mat_med_white, mat_med_red, mat_bottle_glass, mat_bottle_label, mat_bottle_gold, mat_ammo_olive)

	# 6. BACK-RIGHT TACTICAL GEAR & SURPLUS ARMS (X in [5.5, 9.5], Z = 8.5)
	_build_tactical_gear_stand(Vector3(7.5, 0.0, 8.5), self, mat_wood_dark, mat_gun_metal, mat_ammo_olive)

	# 7. LEFT WALL SIDE GLASS SHOWCASE COUNTER (X = -10.2, Z in [-1.5, 4.5])
	var vitrine_side := _build_glass_vitrine(Vector3(-10.1, 0.0, 1.5), Vector3(1.0, 1.25, 4.8), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_pistol(Vector3(0.0, 0.74, -1.5), Vector3(0, 80.0, 15.0), vitrine_side, mat_gun_metal, mat_gun_wood)
	_build_decorative_pistol(Vector3(0.0, 0.74, -0.5), Vector3(0, 95.0, 15.0), vitrine_side, mat_gun_chrome, mat_gun_wood)
	_build_decorative_knife(Vector3(0.0, 0.72, 0.5), Vector3(0, 90.0, 0.0), vitrine_side, mat_knife_blade, mat_wood_dark)
	_build_decorative_knife(Vector3(0.0, 0.72, 1.3), Vector3(0, 105.0, 0.0), vitrine_side, mat_knife_blade, mat_gun_wood)
	_build_field_radio(Vector3(0.0, 0.72, 1.9), vitrine_side, mat_wood_dark, mat_gun_metal)

	# 8. CENTER FREESTANDING LUXURY WEAPON VITRINE (X = 3.2, Z = 0.5)
	var vitrine_center := _build_glass_vitrine(Vector3(3.2, 0.0, 0.5), Vector3(1.8, 1.45, 1.4), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_ak(Vector3(0.0, 0.95, 0.0), Vector3(10.0, 35.0, 15.0), vitrine_center, mat_gun_gold, mat_gun_wood)
	# Center spotlight highlighting gold weapon
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.92, 0.65)
	spot.light_energy = 3.2
	spot.spot_range = 4.0
	spot.spot_angle = 35.0
	spot.position = Vector3(0.0, 1.4, 0.0)
	spot.rotation_degrees = Vector3(-90.0, 0, 0)
	vitrine_center.add_child(spot)

	# 9. RIGHT WALL SIDE GLASS SHOWCASE COUNTER (X = 10.1, Z in [-1.5, 4.5])
	var vitrine_right_side := _build_glass_vitrine(Vector3(10.1, 0.0, 1.5), Vector3(1.0, 1.25, 4.8), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_sniper(Vector3(0.0, 0.74, -1.2), Vector3(0, 90.0, 10.0), vitrine_right_side, mat_gun_metal, mat_gun_wood)
	_build_decorative_pistol(Vector3(0.0, 0.74, 0.2), Vector3(0, 85.0, 15.0), vitrine_right_side, mat_gun_chrome, mat_gun_wood)
	_build_decorative_knife(Vector3(0.0, 0.72, 1.0), Vector3(0, 95.0, 0.0), vitrine_right_side, mat_knife_blade, mat_gun_wood)
	_build_field_radio(Vector3(0.0, 0.72, 1.8), vitrine_right_side, mat_wood_dark, mat_gun_metal)

	# 10. CENTER-LEFT FREESTANDING WEAPON VITRINE (X = -3.2, Z = 1.5)
	var vitrine_center_left := _build_glass_vitrine(Vector3(-3.2, 0.0, 1.5), Vector3(1.8, 1.45, 1.4), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_ak(Vector3(0.0, 0.95, 0.0), Vector3(10.0, -35.0, -15.0), vitrine_center_left, mat_gun_metal, mat_gun_wood)
	_build_decorative_knife(Vector3(-0.4, 0.74, 0.3), Vector3(0, -45.0, 0.0), vitrine_center_left, mat_knife_blade, mat_wood_dark)
	_build_decorative_knife(Vector3(0.4, 0.74, 0.3), Vector3(0, 45.0, 0.0), vitrine_center_left, mat_knife_blade, mat_wood_dark)
	var spot_cl := SpotLight3D.new()
	spot_cl.light_color = Color(0.9, 0.95, 1.0)
	spot_cl.light_energy = 2.6
	spot_cl.spot_range = 4.0
	spot_cl.spot_angle = 35.0
	spot_cl.position = Vector3(0.0, 1.4, 0.0)
	spot_cl.rotation_degrees = Vector3(-90.0, 0, 0)
	vitrine_center_left.add_child(spot_cl)

	# 11. FRONT-CENTER ENTRANCE ISLAND VITRINE (X = 0.0, Z = -3.2)
	var vitrine_front_center := _build_glass_vitrine(Vector3(0.0, 0.0, -3.2), Vector3(2.6, 1.25, 1.1), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_shotgun(Vector3(0.0, 0.74, -0.15), Vector3(0, 15.0, 0.0), vitrine_front_center, mat_gun_metal, mat_gun_wood)
	_build_decorative_pistol(Vector3(-0.7, 0.74, 0.15), Vector3(0, 30.0, 15.0), vitrine_front_center, mat_gun_chrome, mat_gun_wood)
	_build_decorative_pistol(Vector3(0.7, 0.74, 0.15), Vector3(0, -30.0, 15.0), vitrine_front_center, mat_gun_gold, mat_gun_wood)
	_build_shotgun_shell_box(Vector3(0.0, 0.72, 0.2), vitrine_front_center, mat_ammo_red, mat_ammo_brass)

	# 12. FRONT-RIGHT WEAPON & PROVISION VITRINE (X = 6.5, Z = -3.8)
	var vitrine_front_right := _build_glass_vitrine(Vector3(6.5, 0.0, -3.8), Vector3(2.2, 1.30, 1.1), self, mat_wood_dark, mat_vitrine_glass)
	_build_medkit(Vector3(-0.55, 0.72, 0.0), 12.0, vitrine_front_right, mat_med_white, mat_med_red)
	_build_ammo_tin(Vector3(0.55, 0.72, 0.0), -15.0, vitrine_front_right, mat_ammo_olive, mat_wood_dark)
	_build_decorative_knife(Vector3(0.0, 0.72, 0.2), Vector3(0, 0.0, 0.0), vitrine_front_right, mat_knife_blade, mat_gun_wood)

	# 13. FRONT-LEFT WEAPON & PROVISION VITRINE (X = -6.5, Z = -3.8)
	var vitrine_front_left := _build_glass_vitrine(Vector3(-6.5, 0.0, -3.8), Vector3(2.2, 1.30, 1.1), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_sniper(Vector3(0.0, 0.74, 0.0), Vector3(0, 0, 0), vitrine_front_left, mat_gun_metal, mat_gun_wood)
	_build_decorative_knife(Vector3(-0.55, 0.72, 0.15), Vector3(0, 45.0, 0), vitrine_front_left, mat_knife_blade, mat_gun_wood)
	_build_ammo_tin(Vector3(0.55, 0.72, 0.1), 10.0, vitrine_front_left, mat_ammo_olive, mat_wood_dark)

	# 14. CENTRAL CROSSWAY SHOWCASE A (X = -3.2, Z = -1.2)
	var vitrine_aisle_left := _build_glass_vitrine(Vector3(-3.2, 0.0, -1.2), Vector3(1.5, 1.35, 1.2), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_pistol(Vector3(0.0, 0.74, 0.0), Vector3(0, 45.0, 15.0), vitrine_aisle_left, mat_gun_chrome, mat_gun_wood)
	_build_decorative_knife(Vector3(0.0, 0.72, 0.3), Vector3(0, -90.0, 0.0), vitrine_aisle_left, mat_knife_blade, mat_wood_dark)

	# 15. CENTRAL CROSSWAY SHOWCASE B (X = 3.2, Z = -1.2)
	var vitrine_aisle_right := _build_glass_vitrine(Vector3(3.2, 0.0, -1.2), Vector3(1.5, 1.35, 1.2), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_pistol(Vector3(0.0, 0.74, 0.0), Vector3(0, -45.0, 15.0), vitrine_aisle_right, mat_gun_gold, mat_gun_wood)
	_build_shotgun_shell_box(Vector3(0.0, 0.72, 0.3), vitrine_aisle_right, mat_ammo_red, mat_ammo_brass)

	# 16. REAR-CENTER MASTER SHOWCASE (X = 0.0, Z = 5.2)
	var vitrine_rear_center := _build_glass_vitrine(Vector3(0.0, 0.0, 5.2), Vector3(3.4, 1.30, 1.2), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_shotgun(Vector3(-0.9, 0.74, 0.0), Vector3(0, 0, 0), vitrine_rear_center, mat_gun_metal, mat_gun_wood)
	_build_decorative_shotgun(Vector3(0.9, 0.74, 0.0), Vector3(0, 180.0, 0), vitrine_rear_center, mat_gun_metal, mat_gun_wood)
	_build_ammo_tin(Vector3(0.0, 0.72, -0.2), 0.0, vitrine_rear_center, mat_ammo_olive, mat_wood_dark)
	_build_ammo_tin(Vector3(0.0, 0.72, 0.2), 15.0, vitrine_rear_center, mat_ammo_olive, mat_wood_dark)

	# 17. BACK-LEFT PROVISIONS & ARMS SHOWCASE (X = -7.8, Z = 5.2)
	var vitrine_back_left := _build_glass_vitrine(Vector3(-7.8, 0.0, 5.2), Vector3(2.4, 1.30, 1.2), self, mat_wood_dark, mat_vitrine_glass)
	_build_medkit(Vector3(-0.6, 0.72, 0.0), 10.0, vitrine_back_left, mat_med_white, mat_med_red)
	_build_vodka_bottle(Vector3(0.0, 0.72, 0.0), vitrine_back_left, mat_bottle_glass, mat_bottle_gold, mat_bottle_label)
	_build_ammo_tin(Vector3(0.6, 0.72, 0.0), -12.0, vitrine_back_left, mat_ammo_olive, mat_wood_dark)

	# 18. BACK-RIGHT SPECIAL EQUIPMENT SHOWCASE (X = 7.8, Z = 5.2)
	var vitrine_back_right := _build_glass_vitrine(Vector3(7.8, 0.0, 5.2), Vector3(2.4, 1.30, 1.2), self, mat_wood_dark, mat_vitrine_glass)
	_build_decorative_sniper(Vector3(0.0, 0.74, 0.0), Vector3(0, 0, 0), vitrine_back_right, mat_gun_metal, mat_gun_wood)
	_build_decorative_pistol(Vector3(-0.6, 0.74, 0.2), Vector3(0, 30.0, 15.0), vitrine_back_right, mat_gun_chrome, mat_gun_wood)
	_build_decorative_knife(Vector3(0.6, 0.72, 0.2), Vector3(0, -30.0, 0), vitrine_back_right, mat_knife_blade, mat_gun_wood)

	# 13. SALES COUNTER with Cash Register, Bell & Vodka (X = -3.5, Z = -4.5)
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.6, 0.95, 0.85)
	counter.mesh = cm
	counter.material_override = mat_counter
	counter.position = Vector3(-3.5, 0.475, -4.5)
	add_child(counter)

	# Cash Register on counter
	var reg := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.5, 0.28, 0.4)
	reg.mesh = rm
	reg.material_override = mat_wood_dark
	reg.position = Vector3(-3.2, 1.09, -4.5)
	add_child(reg)
	
	# Service Bell on counter
	var bell := MeshInstance3D.new()
	var bm_bell := CylinderMesh.new()
	bm_bell.top_radius = 0.02
	bm_bell.bottom_radius = 0.06
	bm_bell.height = 0.06
	bell.mesh = bm_bell
	bell.material_override = mat_gun_gold
	bell.position = Vector3(-4.4, 0.98, -4.5)
	add_child(bell)
	
	# Bottle of vodka on sales counter
	_build_vodka_bottle(Vector3(-2.3, 0.95, -4.4), self, mat_bottle_glass, mat_bottle_gold, mat_bottle_label)

	# 10. Supply Crates and Wooden Barrels in interior corners
	for bi in range(3):
		var barrel := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.38
		bm.bottom_radius = 0.42
		bm.height = 0.95
		barrel.mesh = bm
		barrel.material_override = mat_barrel
		barrel.position = Vector3(8.5 + (bi % 2) * 0.9, 0.475, 4.5 + bi * 0.9)
		add_child(barrel)
		
	for ci in range(4):
		var crate := MeshInstance3D.new()
		var crm := BoxMesh.new()
		crm.size = Vector3(0.85, 0.75, 0.85)
		crate.mesh = crm
		crate.material_override = mat_crate if ci % 2 == 0 else mat_ammo_olive
		crate.position = Vector3(-8.5 - (ci % 2) * 0.95, 0.375 + int(ci / 2) * 0.75, 4.5 + (ci % 2) * 0.9)
		add_child(crate)

# Helper: Build Glass Display Vitrine Cabinet (All-glass hood, wooden pedestal base, zero Z-fighting, full collision)
func _build_glass_vitrine(pos: Vector3, size: Vector3, parent: Node3D, mat_wood: Material, mat_glass: Material) -> Node3D:
	var vitrine := Node3D.new()
	vitrine.position = pos
	parent.add_child(vitrine)
	
	# Solid physical collision for vitrine cabinet
	var col_body := StaticBody3D.new()
	col_body.name = "VitrineCollision"
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, size.y * 0.5, 0)
	col_body.add_child(col_shape)
	vitrine.add_child(col_body)
	
	var base_h: float = 0.70
	var glass_h: float = size.y - base_h
	
	# Solid wooden pedestal base
	var base := MeshInstance3D.new()
	var b_m := BoxMesh.new()
	b_m.size = Vector3(size.x, base_h, size.z)
	base.mesh = b_m
	base.material_override = mat_wood
	base.position = Vector3(0, base_h * 0.5, 0)
	vitrine.add_child(base)
	
	# All-glass showcase hood on top: pure glass on all 4 sides and top (no wood rim!)
	# Inset by 2cm within the base perimeter and elevated 1.5mm above base_h to completely prevent Z-fighting with the wood top
	var glass := MeshInstance3D.new()
	var g_m := BoxMesh.new()
	g_m.size = Vector3(size.x - 0.04, glass_h, size.z - 0.04)
	glass.mesh = g_m
	glass.material_override = mat_glass
	glass.position = Vector3(0, base_h + 0.0015 + glass_h * 0.5, 0)
	vitrine.add_child(glass)
	
	# Soft display spotlight inside the vitrine
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.90, 0.70)
	light.light_energy = 1.3
	light.omni_range = 3.5
	light.position = Vector3(0, size.y - 0.12, 0)
	vitrine.add_child(light)
	
	return vitrine

# Helper: Back Wall Heavy Gun Rack
func _build_back_wall_gun_rack(pos: Vector3, parent: Node3D, mat_wood: Material, mat_metal: Material, mat_gun_wood: Material, mat_ammo: Material) -> void:
	var rack := Node3D.new()
	rack.position = pos
	parent.add_child(rack)
	
	# Wall backboard
	var backboard := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(7.2, 2.4, 0.08)
	backboard.mesh = bm
	backboard.material_override = mat_wood
	backboard.position = Vector3(0, 1.8, 0)
	rack.add_child(backboard)
	
	# Wooden shelves / brackets
	for si in range(3):
		var shelf := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(7.0, 0.08, 0.28)
		shelf.mesh = sm
		shelf.material_override = mat_wood
		shelf.position = Vector3(0, 1.2 + si * 0.6, 0.12)
		rack.add_child(shelf)
		
	# Top tier: Precision Sniper Rifle (AWP/SVD with telescopic scope)
	_build_decorative_sniper(Vector3(0.0, 2.45, 0.18), Vector3(0, 0, 0), rack, mat_metal, mat_gun_wood)
	
	# Middle tier: 2x AK-47 assault rifles
	_build_decorative_ak(Vector3(-1.8, 1.85, 0.18), Vector3(0, 0, 0), rack, mat_metal, mat_gun_wood)
	_build_decorative_ak(Vector3(1.8, 1.85, 0.18), Vector3(0, 180.0, 0), rack, mat_metal, mat_gun_wood)
	
	# Lower tier: 2x Combat Shotguns
	_build_decorative_shotgun(Vector3(-1.8, 1.25, 0.18), Vector3(0, 0, 0), rack, mat_metal, mat_gun_wood)
	_build_decorative_shotgun(Vector3(1.8, 1.25, 0.18), Vector3(0, 180.0, 0), rack, mat_metal, mat_gun_wood)
	
	# Floor underneath rack: Row of 5 heavy steel ammo cans
	for ai in range(5):
		_build_ammo_tin(Vector3(-2.4 + ai * 1.2, 0.0, 0.25), randf_range(-12.0, 12.0), rack, mat_ammo, mat_wood)

# Helper: Medical & Provisions Shelf
func _build_medical_and_provisions_shelf(pos: Vector3, parent: Node3D, mat_wood: Material, mat_white: Material, mat_red: Material, mat_bottle: Material, mat_label: Material, mat_gold: Material, mat_ammo: Material) -> void:
	var unit := Node3D.new()
	unit.position = pos
	parent.add_child(unit)
	
	# Tall wooden shelving rack
	for si in range(4):
		var shelf := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(3.2, 0.08, 0.45)
		shelf.mesh = sm
		shelf.material_override = mat_wood
		shelf.position = Vector3(0, 0.6 + si * 0.6, 0)
		unit.add_child(shelf)
		
	# Side posts
	for px in [-1.55, 1.55]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.08, 2.5, 0.45)
		post.mesh = pm
		post.material_override = mat_wood
		post.position = Vector3(px, 1.25, 0)
		unit.add_child(post)
		
	# Top shelf (Y = 2.4): 2x Medkits
	_build_medkit(Vector3(-0.7, 2.44, 0), 10.0, unit, mat_white, mat_red)
	_build_medkit(Vector3(0.7, 2.44, 0), -12.0, unit, mat_white, mat_red)
	
	# 2nd shelf (Y = 1.8): Row of 6 Vodka bottles
	for vi in range(6):
		_build_vodka_bottle(Vector3(-1.1 + vi * 0.44, 1.84, randf_range(-0.06, 0.06)), unit, mat_bottle, mat_gold, mat_label)
		
	# 3rd shelf (Y = 1.2): Ammo boxes and ration tins
	for bi in range(3):
		_build_ammo_tin(Vector3(-0.9 + bi * 0.9, 1.24, 0), randf_range(-8.0, 8.0), unit, mat_ammo, mat_wood)
		
	# Bottom shelf (Y = 0.6): Heavy crates
	var c_box := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(0.7, 0.5, 0.4)
	c_box.mesh = cbm
	c_box.material_override = mat_ammo
	c_box.position = Vector3(-0.5, 0.25, 0)
	unit.add_child(c_box)

# Helper: Tactical Gear Stand
func _build_tactical_gear_stand(pos: Vector3, parent: Node3D, mat_wood: Material, mat_metal: Material, mat_ammo: Material) -> void:
	var gear := Node3D.new()
	gear.position = pos
	parent.add_child(gear)
	
	# Mannequin stand (rests cleanly on floor at Y = 0.12)
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.35
	bm.bottom_radius = 0.40
	bm.height = 0.08
	base.mesh = bm
	base.material_override = mat_wood
	base.position = Vector3(0, 0.16, 0)
	gear.add_child(base)
	
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.04
	pm.bottom_radius = 0.04
	pm.height = 1.6
	pole.mesh = pm
	pole.material_override = mat_metal
	pole.position = Vector3(0, 0.92, 0)
	gear.add_child(pole)
	
	# Tactical Body Armor Vest
	var vest := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.55, 0.65, 0.32)
	vest.mesh = vm
	var mat_vest := StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.14, 0.16, 0.18)
	mat_vest.roughness = 0.85
	vest.material_override = mat_vest
	vest.position = Vector3(0, 1.37, 0)
	gear.add_child(vest)
	
	# Tactical Steel Helmet
	var helmet := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.18
	hm.bottom_radius = 0.24
	hm.height = 0.22
	helmet.mesh = hm
	var mat_helmet := StandardMaterial3D.new()
	mat_helmet.albedo_color = Color(0.22, 0.28, 0.18)
	mat_helmet.metallic = 0.7
	mat_helmet.roughness = 0.4
	helmet.material_override = mat_helmet
	helmet.position = Vector3(0, 1.82, 0)
	gear.add_child(helmet)
	
	# Flanking ammo boxes
	_build_ammo_tin(Vector3(-1.1, 0, 0.1), 15.0, gear, mat_ammo, mat_wood)
	_build_ammo_tin(Vector3(1.1, 0, 0.1), -18.0, gear, mat_ammo, mat_wood)

# Helper 3D Prop Builders:
func _build_decorative_ak(pos: Vector3, rot: Vector3, parent: Node3D, mat_metal: Material, mat_wood: Material) -> void:
	var ak := Node3D.new()
	ak.position = pos
	ak.rotation_degrees = rot
	parent.add_child(ak)
	
	# Receiver
	var rec := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.55, 0.10, 0.065)
	rec.mesh = rm
	rec.material_override = mat_metal
	ak.add_child(rec)
	
	# Wooden Stock
	var stock := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.32, 0.11, 0.05)
	stock.mesh = sm
	stock.material_override = mat_wood
	stock.position = Vector3(-0.38, -0.02, 0)
	ak.add_child(stock)
	
	# Barrel
	var barrel := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.018
	bm.bottom_radius = 0.018
	bm.height = 0.44
	barrel.mesh = bm
	barrel.material_override = mat_metal
	barrel.position = Vector3(0.44, 0.01, 0)
	barrel.rotation_degrees = Vector3(0, 0, 90)
	ak.add_child(barrel)
	
	# Wooden Handguard
	var guard := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.24, 0.07, 0.06)
	guard.mesh = gm
	guard.material_override = mat_wood
	guard.position = Vector3(0.26, 0.015, 0)
	ak.add_child(guard)
	
	# Pistol Grip
	var grip := MeshInstance3D.new()
	var gpm := BoxMesh.new()
	gpm.size = Vector3(0.06, 0.14, 0.045)
	grip.mesh = gpm
	grip.material_override = mat_wood
	grip.position = Vector3(-0.16, -0.10, 0)
	grip.rotation_degrees = Vector3(0, 0, 20)
	ak.add_child(grip)
	
	# Curved Magazine (Orange Bakelite / Steel)
	var mag := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.10, 0.22, 0.045)
	mag.mesh = mm
	var mat_mag := StandardMaterial3D.new()
	mat_mag.albedo_color = Color(0.65, 0.32, 0.12)
	mat_mag.metallic = 0.4
	mat_mag.roughness = 0.5
	mag.material_override = mat_mag
	mag.position = Vector3(0.06, -0.13, 0)
	mag.rotation_degrees = Vector3(0, 0, -18)
	ak.add_child(mag)

func _build_decorative_shotgun(pos: Vector3, rot: Vector3, parent: Node3D, mat_metal: Material, mat_wood: Material) -> void:
	var sg := Node3D.new()
	sg.position = pos
	sg.rotation_degrees = rot
	parent.add_child(sg)
	
	# Receiver
	var rec := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.42, 0.095, 0.065)
	rec.mesh = rm
	rec.material_override = mat_metal
	sg.add_child(rec)
	
	# Stock
	var stock := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.35, 0.10, 0.05)
	stock.mesh = sm
	stock.material_override = mat_wood
	stock.position = Vector3(-0.34, -0.02, 0)
	sg.add_child(stock)
	
	# Long Barrel
	var barrel := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.02
	bm.bottom_radius = 0.02
	bm.height = 0.56
	barrel.mesh = bm
	barrel.material_override = mat_metal
	barrel.position = Vector3(0.45, 0.015, 0)
	barrel.rotation_degrees = Vector3(0, 0, 90)
	sg.add_child(barrel)
	
	# Under-barrel tube
	var tube := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.018
	tm.bottom_radius = 0.018
	tm.height = 0.50
	tube.mesh = tm
	tube.material_override = mat_metal
	tube.position = Vector3(0.42, -0.025, 0)
	tube.rotation_degrees = Vector3(0, 0, 90)
	sg.add_child(tube)
	
	# Pump slide
	var pump := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.03
	pm.bottom_radius = 0.03
	pm.height = 0.18
	pump.mesh = pm
	pump.material_override = mat_wood
	pump.position = Vector3(0.35, -0.025, 0)
	pump.rotation_degrees = Vector3(0, 0, 90)
	sg.add_child(pump)

func _build_decorative_pistol(pos: Vector3, rot: Vector3, parent: Node3D, mat_metal: Material, mat_wood: Material) -> void:
	var pst := Node3D.new()
	pst.position = pos
	pst.rotation_degrees = rot
	parent.add_child(pst)
	
	# Slide
	var slide := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.24, 0.065, 0.045)
	slide.mesh = sm
	slide.material_override = mat_metal
	pst.add_child(slide)
	
	# Grip
	var grip := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.06, 0.15, 0.045)
	grip.mesh = gm
	grip.material_override = mat_wood
	grip.position = Vector3(-0.06, -0.08, 0)
	grip.rotation_degrees = Vector3(0, 0, 18)
	pst.add_child(grip)

func _build_decorative_sniper(pos: Vector3, rot: Vector3, parent: Node3D, mat_metal: Material, mat_wood: Material) -> void:
	var snp := Node3D.new()
	snp.position = pos
	snp.rotation_degrees = rot
	parent.add_child(snp)
	
	# Body & Stock
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.85, 0.10, 0.06)
	body.mesh = bm
	body.material_override = mat_wood
	snp.add_child(body)
	
	# Long precision barrel
	var barrel := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.018
	cm.bottom_radius = 0.022
	cm.height = 0.82
	barrel.mesh = cm
	barrel.material_override = mat_metal
	barrel.position = Vector3(0.65, 0.02, 0)
	barrel.rotation_degrees = Vector3(0, 0, 90)
	snp.add_child(barrel)
	
	# Telescopic Scope
	var scope := MeshInstance3D.new()
	var scm := CylinderMesh.new()
	scm.top_radius = 0.028
	scm.bottom_radius = 0.028
	scm.height = 0.32
	scope.mesh = scm
	scope.material_override = mat_metal
	scope.position = Vector3(0.08, 0.10, 0)
	scope.rotation_degrees = Vector3(0, 0, 90)
	snp.add_child(scope)

func _build_decorative_knife(pos: Vector3, rot: Vector3, parent: Node3D, mat_blade: Material, mat_handle: Material) -> void:
	var knf := Node3D.new()
	knf.position = pos
	knf.rotation_degrees = rot
	parent.add_child(knf)
	
	# Blade
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.038, 0.012)
	blade.mesh = bm
	blade.material_override = mat_blade
	blade.position = Vector3(0.10, 0, 0)
	knf.add_child(blade)
	
	# Guard
	var guard := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.02, 0.08, 0.025)
	guard.mesh = gm
	guard.material_override = mat_blade
	knf.add_child(guard)
	
	# Grip
	var grip := MeshInstance3D.new()
	var gpm := BoxMesh.new()
	gpm.size = Vector3(0.13, 0.035, 0.028)
	grip.mesh = gpm
	grip.material_override = mat_handle
	grip.position = Vector3(-0.075, 0, 0)
	knf.add_child(grip)

func _build_vodka_bottle(pos: Vector3, parent: Node3D, mat_glass: Material, mat_gold: Material, mat_label: Material) -> void:
	var bot := Node3D.new()
	bot.position = pos
	parent.add_child(bot)
	
	# Body
	var body := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.045
	bm.bottom_radius = 0.048
	bm.height = 0.20
	body.mesh = bm
	body.material_override = mat_glass
	body.position = Vector3(0, 0.10, 0)
	bot.add_child(body)
	
	# Label
	var lbl := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.049
	lm.bottom_radius = 0.049
	lm.height = 0.10
	lbl.mesh = lm
	lbl.material_override = mat_label
	lbl.position = Vector3(0, 0.10, 0)
	bot.add_child(lbl)
	
	# Neck & Cap
	var neck := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.018
	nm.bottom_radius = 0.030
	nm.height = 0.09
	neck.mesh = nm
	neck.material_override = mat_glass
	neck.position = Vector3(0, 0.23, 0)
	bot.add_child(neck)
	
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.020
	cm.bottom_radius = 0.020
	cm.height = 0.03
	cap.mesh = cm
	cap.material_override = mat_gold
	cap.position = Vector3(0, 0.28, 0)
	bot.add_child(cap)

func _build_medkit(pos: Vector3, rot_y: float, parent: Node3D, mat_white: Material, mat_red: Material) -> void:
	var med := Node3D.new()
	med.position = pos
	med.rotation_degrees.y = rot_y
	parent.add_child(med)
	
	# Box
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.26, 0.14)
	box.mesh = bm
	box.material_override = mat_white
	box.position = Vector3(0, 0.13, 0)
	med.add_child(box)
	
	# Red Cross Horizontal
	var ch := MeshInstance3D.new()
	var chm := BoxMesh.new()
	chm.size = Vector3(0.16, 0.045, 0.01)
	ch.mesh = chm
	ch.material_override = mat_red
	ch.position = Vector3(0, 0.13, 0.072)
	med.add_child(ch)
	
	# Red Cross Vertical (placed 2mm proud to prevent Z-fighting)
	var cv := MeshInstance3D.new()
	var cvm := BoxMesh.new()
	cvm.size = Vector3(0.045, 0.16, 0.01)
	cv.mesh = cvm
	cv.material_override = mat_red
	cv.position = Vector3(0, 0.13, 0.074)
	med.add_child(cv)

func _build_ammo_tin(pos: Vector3, rot_y: float, parent: Node3D, mat_tin: Material, mat_lid: Material) -> void:
	var can := Node3D.new()
	can.position = pos
	can.rotation_degrees.y = rot_y
	parent.add_child(can)
	
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.20, 0.16)
	box.mesh = bm
	box.material_override = mat_tin
	box.position = Vector3(0, 0.10, 0)
	can.add_child(box)
	
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.33, 0.035, 0.17)
	lid.mesh = lm
	lid.material_override = mat_lid
	lid.position = Vector3(0, 0.21, 0)
	can.add_child(lid)

func _build_shotgun_shell_box(pos: Vector3, parent: Node3D, mat_red: Material, mat_brass: Material) -> void:
	var box := Node3D.new()
	box.position = pos
	parent.add_child(box)
	
	var carton := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.18, 0.12, 0.14)
	carton.mesh = cm
	carton.material_override = mat_red
	carton.position = Vector3(0, 0.06, 0)
	box.add_child(carton)
	
	# Exposed brass shell heads on top
	for si in range(4):
		var shell := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.014
		sm.bottom_radius = 0.014
		sm.height = 0.02
		shell.mesh = sm
		shell.material_override = mat_brass
		shell.position = Vector3(-0.045 + (si % 2) * 0.09, 0.125, -0.03 + int(si / 2) * 0.06)
		box.add_child(shell)

func _build_field_radio(pos: Vector3, parent: Node3D, mat_body: Material, mat_metal: Material) -> void:
	var rad := Node3D.new()
	rad.position = pos
	parent.add_child(rad)
	
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.16, 0.10)
	body.mesh = bm
	body.material_override = mat_body
	body.position = Vector3(0, 0.08, 0)
	rad.add_child(body)
	
	var ant := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.006
	am.bottom_radius = 0.008
	am.height = 0.35
	ant.mesh = am
	ant.material_override = mat_metal
	ant.position = Vector3(0.08, 0.28, 0)
	rad.add_child(ant)

func _add_wall_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box_m := BoxMesh.new()
	box_m.size = size
	mesh_inst.mesh = box_m
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	add_child(mesh_inst)
	
	var col := CollisionShape3D.new()
	var box_s := BoxShape3D.new()
	box_s.size = size
	col.shape = box_s
	col.position = pos
	add_child(col)
