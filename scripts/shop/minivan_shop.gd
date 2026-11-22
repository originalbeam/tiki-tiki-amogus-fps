class_name MinivanShop
extends Node3D

# Minivan Shop with Gray Crewmate & Decorative Inventory
# Arrives forward into donut radius (14m - 22m) around player between waves (No reverse gear!)

const DONUT_RADIUS_MIN: float = 14.0
const DONUT_RADIUS_MAX: float = 22.0

const PARK_POS: Vector3 = Vector3(-14.0, 0.0, 4.0)
const PARK_ROT: Vector3 = Vector3(0.0, 15.0, 0.0)

var van_root: Node3D = null
var crewmate: Node3D = null
var canopy_pivot: Node3D = null
var storefront_root: Node3D = null
var shop_zone: Area3D = null
var floor_marker: Node3D = null
var headlights_light: SpotLight3D = null
var audio_player: AudioStreamPlayer3D = null

var is_parked: bool = true
var is_driving: bool = false
var _sequence_id: int = 0
var _active_tweens: Array[Tween] = []

# Stand positions for crewmate relative to van_root
const CREWMATE_SHOP_POS: Vector3 = Vector3(1.35, 0.0, 1.85)
const CREWMATE_SHOP_ROT: Vector3 = Vector3(0.0, -52.0, 0.0)
const CREWMATE_CABIN_POS: Vector3 = Vector3(-1.15, 0.38, 0.40)
const CREWMATE_CABIN_ROT: Vector3 = Vector3(0.0, 90.0, 0.0)

func _ready() -> void:
	add_to_group("minivan_shop")
	position = PARK_POS
	rotation_degrees = PARK_ROT
	
	build_minivan_and_props()
	build_gray_crewmate()
	build_shop_zone()
	
	audio_player = AudioStreamPlayer3D.new()
	audio_player.max_distance = 60.0
	audio_player.unit_size = 10.0
	add_child(audio_player)
	
	set_parked_state(true)

func _process(delta: float) -> void:
	if is_parked and not is_driving and crewmate:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			var dist = global_position.distance_to(player.global_position)
			if dist < 12.0:
				var local_p = to_local(player.global_position)
				var diff = local_p - crewmate.position
				var target_angle = rad_to_deg(atan2(diff.x, diff.z))
				# Clamp angle within natural head/body facing range towards customer zone
				target_angle = clampf(target_angle, -95.0, 10.0)
				crewmate.rotation_degrees.y = lerp_angle(deg_to_rad(crewmate.rotation_degrees.y), deg_to_rad(target_angle), delta * 4.0) * 180.0 / PI
			else:
				crewmate.rotation_degrees.y = lerp_angle(deg_to_rad(crewmate.rotation_degrees.y), deg_to_rad(CREWMATE_SHOP_ROT.y), delta * 3.0) * 180.0 / PI

func build_minivan_and_props() -> void:
	van_root = Node3D.new()
	van_root.name = "VanRoot"
	add_child(van_root)
	
	# Materials
	var mat_van_body := StandardMaterial3D.new()
	mat_van_body.albedo_color = Color(0.22, 0.26, 0.32)
	mat_van_body.metallic = 0.65
	mat_van_body.roughness = 0.35
	
	var mat_bumper := StandardMaterial3D.new()
	mat_bumper.albedo_color = Color(0.12, 0.12, 0.14)
	mat_bumper.metallic = 0.4
	mat_bumper.roughness = 0.6
	
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.2, 0.45, 0.6, 0.7)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.metallic = 0.8
	mat_glass.roughness = 0.1
	
	var mat_tire := StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.1, 0.1, 0.1)
	mat_tire.roughness = 0.8
	
	var mat_rim := StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.75, 0.78, 0.82)
	mat_rim.metallic = 0.9
	mat_rim.roughness = 0.2
	
	var mat_lights := StandardMaterial3D.new()
	mat_lights.albedo_color = Color(1.0, 0.95, 0.7)
	mat_lights.emission_enabled = true
	mat_lights.emission = Color(1.0, 0.95, 0.7)
	mat_lights.emission_energy_multiplier = 2.5
	
	var mat_taillights := StandardMaterial3D.new()
	mat_taillights.albedo_color = Color(0.9, 0.1, 0.1)
	mat_taillights.emission_enabled = true
	mat_taillights.emission = Color(0.9, 0.1, 0.1)
	mat_taillights.emission_energy_multiplier = 1.8
	
	var mat_wood_counter := StandardMaterial3D.new()
	mat_wood_counter.albedo_color = Color(0.42, 0.24, 0.12)
	mat_wood_counter.roughness = 0.6
	
	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.92, 0.95, 0.98)
	mat_chrome.metallic = 0.95
	mat_chrome.roughness = 0.12
	
	var mat_grille := StandardMaterial3D.new()
	mat_grille.albedo_color = Color(0.08, 0.08, 0.09)
	mat_grille.metallic = 0.2
	mat_grille.roughness = 0.85
	
	var mat_badge_blue := StandardMaterial3D.new()
	mat_badge_blue.albedo_color = Color(0.06, 0.22, 0.52)
	mat_badge_blue.metallic = 0.8
	mat_badge_blue.roughness = 0.2
	
	var mat_plate := StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.94, 0.94, 0.94)
	mat_plate.roughness = 0.4
	
	# Main Van Cargo Box Body
	var body_box := MeshInstance3D.new()
	var bbm := BoxMesh.new()
	bbm.size = Vector3(4.8, 1.8, 2.2)
	body_box.mesh = bbm
	body_box.material_override = mat_van_body
	body_box.position = Vector3(0.0, 1.25, 0.0)
	van_root.add_child(body_box)
	
	# Van Front Hood (Engine Bay)
	var hood_box := MeshInstance3D.new()
	var hbm := BoxMesh.new()
	hbm.size = Vector3(1.2, 1.1, 2.15)
	hood_box.mesh = hbm
	hood_box.material_override = mat_van_body
	hood_box.position = Vector3(-2.6, 0.85, 0.0)
	van_root.add_child(hood_box)
	
	# Front Windshield
	var windshield := MeshInstance3D.new()
	var wsm := BoxMesh.new()
	wsm.size = Vector3(0.7, 0.95, 2.05)
	windshield.mesh = wsm
	windshield.material_override = mat_glass
	windshield.position = Vector3(-2.1, 1.62, 0.0)
	windshield.rotation_degrees = Vector3(0, 0, -28)
	van_root.add_child(windshield)
	
	# Front Bumpers
	var front_bumper := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(0.35, 0.35, 2.25)
	front_bumper.mesh = fbm
	front_bumper.material_override = mat_bumper
	front_bumper.position = Vector3(-3.25, 0.45, 0.0)
	van_root.add_child(front_bumper)
	
	var rear_bumper := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(0.35, 0.35, 2.25)
	rear_bumper.mesh = rbm
	rear_bumper.material_override = mat_bumper
	rear_bumper.position = Vector3(2.45, 0.45, 0.0)
	van_root.add_child(rear_bumper)
	
	# 4 Wheels
	var wheel_coords = [
		Vector3(-1.7, 0.45, 1.12),
		Vector3(-1.7, 0.45, -1.12),
		Vector3(1.6, 0.45, 1.12),
		Vector3(1.6, 0.45, -1.12)
	]
	for wc in wheel_coords:
		var wheel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.44
		cm.bottom_radius = 0.44
		cm.height = 0.28
		cm.radial_segments = 14
		wheel.mesh = cm
		wheel.material_override = mat_tire
		wheel.position = wc
		wheel.rotation_degrees = Vector3(90, 0, 0)
		van_root.add_child(wheel)
		
		# Rim
		var rim := MeshInstance3D.new()
		var r_mesh := CylinderMesh.new()
		r_mesh.top_radius = 0.25
		r_mesh.bottom_radius = 0.25
		r_mesh.height = 0.30
		rim.mesh = r_mesh
		rim.material_override = mat_rim
		rim.position = Vector3.ZERO
		wheel.add_child(rim)
		
	# Headlights
	for z_pos in [0.75, -0.75]:
		var hl := MeshInstance3D.new()
		var hlm := BoxMesh.new()
		hlm.size = Vector3(0.12, 0.24, 0.42)
		hl.mesh = hlm
		hl.material_override = mat_lights
		hl.position = Vector3(-3.22, 0.95, z_pos)
		van_root.add_child(hl)
		
	# Taillights
	for z_pos in [0.85, -0.85]:
		var tl := MeshInstance3D.new()
		var tlm := BoxMesh.new()
		tlm.size = Vector3(0.10, 0.45, 0.24)
		tl.mesh = tlm
		tl.material_override = mat_taillights
		tl.position = Vector3(2.42, 1.45, z_pos)
		van_root.add_child(tl)
		
	headlights_light = SpotLight3D.new()
	headlights_light.spot_range = 35.0
	headlights_light.spot_angle = 45.0
	headlights_light.light_color = Color(1.0, 0.96, 0.8)
	headlights_light.light_energy = 3.2
	headlights_light.position = Vector3(-3.3, 0.95, 0.0)
	headlights_light.rotation_degrees = Vector3(0, 90, 0)
	van_root.add_child(headlights_light)
	
	# Side Open Shop Counter & Canopy Shutter (on right side facing inside arena, +Z)
	canopy_pivot = Node3D.new()
	canopy_pivot.name = "CanopyPivot"
	canopy_pivot.position = Vector3(0.2, 2.15, 1.10)
	canopy_pivot.rotation_degrees = Vector3(14.0, 0.0, 0.0)
	van_root.add_child(canopy_pivot)
	
	var canopy := MeshInstance3D.new()
	var canopy_m := BoxMesh.new()
	canopy_m.size = Vector3(2.8, 0.08, 1.3)
	canopy.mesh = canopy_m
	var mat_canopy := StandardMaterial3D.new()
	mat_canopy.albedo_color = Color(0.9, 0.65, 0.15)
	canopy.material_override = mat_canopy
	canopy.position = Vector3(0.0, 0.0, 0.65)
	canopy.rotation_degrees = Vector3.ZERO
	canopy_pivot.add_child(canopy)
	
	# Retractable Storefront (Counter tabletop + legs + merchandise wares)
	storefront_root = Node3D.new()
	storefront_root.name = "Storefront"
	van_root.add_child(storefront_root)
	
	# Counter tabletop
	var counter := MeshInstance3D.new()
	var counter_m := BoxMesh.new()
	counter_m.size = Vector3(2.6, 0.10, 0.65)
	counter.mesh = counter_m
	counter.material_override = mat_wood_counter
	counter.position = Vector3(0.2, 0.95, 1.25)
	storefront_root.add_child(counter)
	
	# Counter legs
	for cx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_m := BoxMesh.new()
		leg_m.size = Vector3(0.08, 0.90, 0.08)
		leg.mesh = leg_m
		leg.material_override = mat_bumper
		leg.position = Vector3(0.2 + cx, 0.45, 1.5)
		storefront_root.add_child(leg)
		
	# Roof Neon Sign: "ОРУЖИЕ & СНАРЯЖЕНИЕ"
	var sign_mesh := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.4, 0.45, 0.12)
	sign_mesh.mesh = sm
	var mat_sign := StandardMaterial3D.new()
	mat_sign.albedo_color = Color(0.1, 0.15, 0.22)
	mat_sign.emission_enabled = true
	mat_sign.emission = Color(0.2, 0.85, 1.0)
	mat_sign.emission_energy_multiplier = 0.8
	sign_mesh.material_override = mat_sign
	sign_mesh.position = Vector3(0.0, 2.45, 0.0)
	van_root.add_child(sign_mesh)
	
	# --- MINIVAN AUTOMOTIVE DETAILING ---
	# 1. FRONT RADIATOR GRILLE & HEADLIGHT SURROUND
	var grille := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.08, 0.46, 1.10)
	grille.mesh = gm
	grille.material_override = mat_grille
	grille.position = Vector3(-3.24, 0.95, 0.0)
	van_root.add_child(grille)
	
	for gy in [-0.12, 0.12]:
		var slat := MeshInstance3D.new()
		var sm_slat := BoxMesh.new()
		sm_slat.size = Vector3(0.03, 0.03, 1.06)
		slat.mesh = sm_slat
		slat.material_override = mat_chrome
		slat.position = Vector3(-3.27, 0.95 + gy, 0.0)
		van_root.add_child(slat)
		
	# Front License Plate
	var f_plate := MeshInstance3D.new()
	var f_pm := BoxMesh.new()
	f_pm.size = Vector3(0.03, 0.15, 0.52)
	f_plate.mesh = f_pm
	f_plate.material_override = mat_plate
	f_plate.position = Vector3(-3.43, 0.45, 0.0)
	van_root.add_child(f_plate)
	
	var f_plate_lbl := Label3D.new()
	f_plate_lbl.text = "А 777 МР 77"
	f_plate_lbl.font_size = 18
	f_plate_lbl.modulate = Color(0.08, 0.08, 0.10)
	f_plate_lbl.position = Vector3(-3.45, 0.45, 0.0)
	f_plate_lbl.rotation_degrees = Vector3(0, -90, 0)
	van_root.add_child(f_plate_lbl)

	# 2. REAR CARGO DOORS & DISCREET EASTER EGG
	var rear_seam := MeshInstance3D.new()
	var rsm := BoxMesh.new()
	rsm.size = Vector3(0.02, 1.70, 0.02)
	rear_seam.mesh = rsm
	rear_seam.material_override = mat_bumper
	rear_seam.position = Vector3(2.42, 1.25, 0.0)
	van_root.add_child(rear_seam)
	
	var rear_handle := MeshInstance3D.new()
	var rhm := BoxMesh.new()
	rhm.size = Vector3(0.03, 0.12, 0.04)
	rear_handle.mesh = rhm
	rear_handle.material_override = mat_chrome
	rear_handle.position = Vector3(2.43, 1.20, 0.08)
	van_root.add_child(rear_handle)
	
	# Rear License Plate
	var r_plate := MeshInstance3D.new()
	var r_pm := BoxMesh.new()
	r_pm.size = Vector3(0.03, 0.16, 0.54)
	r_plate.mesh = r_pm
	r_plate.material_override = mat_plate
	r_plate.position = Vector3(2.44, 0.72, 0.0)
	van_root.add_child(r_plate)
	
	var r_plate_lbl := Label3D.new()
	r_plate_lbl.text = "А 777 МР 77"
	r_plate_lbl.font_size = 18
	r_plate_lbl.modulate = Color(0.08, 0.08, 0.10)
	r_plate_lbl.position = Vector3(2.46, 0.72, 0.0)
	r_plate_lbl.rotation_degrees = Vector3(0, 90, 0)
	van_root.add_child(r_plate_lbl)
	
	# Small Easter egg badge on the lower right corner of the rear door
	var egg_badge := MeshInstance3D.new()
	var ebm := BoxMesh.new()
	ebm.size = Vector3(0.015, 0.055, 0.26)
	egg_badge.mesh = ebm
	egg_badge.material_override = mat_chrome
	egg_badge.position = Vector3(2.42, 0.85, 0.65)
	van_root.add_child(egg_badge)
	
	var easter_egg := Label3D.new()
	easter_egg.text = "PIND Transit"
	easter_egg.font_size = 14
	easter_egg.modulate = Color(0.18, 0.20, 0.24)
	easter_egg.position = Vector3(2.43, 0.85, 0.65)
	easter_egg.rotation_degrees = Vector3(0, 90, 0)
	van_root.add_child(easter_egg)

	# 3. CAB FRONT DOORS (Ручки дверей и зеркала заднего вида)
	for side_val in [1.12, -1.12]:
		var is_right: bool = side_val > 0
		# Door handles
		var door_h := MeshInstance3D.new()
		var dhm := BoxMesh.new()
		dhm.size = Vector3(0.18, 0.04, 0.03)
		door_h.mesh = dhm
		door_h.material_override = mat_bumper
		door_h.position = Vector3(-1.35, 1.15, side_val + (0.02 if is_right else -0.02))
		van_root.add_child(door_h)
		
		# Side mirrors
		var mirror_arm := MeshInstance3D.new()
		var mam := BoxMesh.new()
		mam.size = Vector3(0.06, 0.06, 0.18)
		mirror_arm.mesh = mam
		mirror_arm.material_override = mat_bumper
		mirror_arm.position = Vector3(-1.95, 1.52, side_val + (0.10 if is_right else -0.10))
		van_root.add_child(mirror_arm)
		
		var mirror_housing := MeshInstance3D.new()
		var mhm := BoxMesh.new()
		mhm.size = Vector3(0.12, 0.28, 0.16)
		mirror_housing.mesh = mhm
		mirror_housing.material_override = mat_van_body
		mirror_housing.position = Vector3(-1.95, 1.55, side_val + (0.20 if is_right else -0.20))
		van_root.add_child(mirror_housing)

	# 4. LEFT BODY CARGO PANEL: LOWER PROTECTIVE SILL CLADDING
	var side_stripe := MeshInstance3D.new()
	var ssm := BoxMesh.new()
	ssm.size = Vector3(4.70, 0.08, 0.02)
	side_stripe.mesh = ssm
	side_stripe.material_override = mat_chrome
	side_stripe.position = Vector3(0.0, 0.65, -1.11)
	van_root.add_child(side_stripe)

	# 5. CAB INTERIOR: STEERING WHEEL
	var steering_col := MeshInstance3D.new()
	var sc_m := CylinderMesh.new()
	sc_m.top_radius = 0.03
	sc_m.bottom_radius = 0.03
	sc_m.height = 0.35
	steering_col.mesh = sc_m
	steering_col.material_override = mat_bumper
	steering_col.position = Vector3(-1.60, 1.15, -0.42)
	steering_col.rotation_degrees = Vector3(0, 0, 45)
	van_root.add_child(steering_col)
	
	var steering_wheel := MeshInstance3D.new()
	var sw_m := CylinderMesh.new()
	sw_m.top_radius = 0.18
	sw_m.bottom_radius = 0.18
	sw_m.height = 0.03
	steering_wheel.mesh = sw_m
	steering_wheel.material_override = mat_tire
	steering_wheel.position = Vector3(-1.48, 1.27, -0.42)
	steering_wheel.rotation_degrees = Vector3(0, 0, 45)
	van_root.add_child(steering_wheel)

	# 6. ROOF NEON SHOP SIGN (Оружейная лавка на крыше фургона)
	for side in [1, -1]:
		var sign_lbl := Label3D.new()
		sign_lbl.text = "★ ОРУЖЕЙНАЯ ЛАВКА ★"
		sign_lbl.font_size = 24
		sign_lbl.modulate = Color(0.25, 0.92, 1.0)
		sign_lbl.outline_modulate = Color(0.05, 0.1, 0.15)
		sign_lbl.outline_size = 6
		sign_lbl.position = Vector3(0.0, 2.45, 0.07 * side)
		sign_lbl.rotation_degrees = Vector3(0, 0 if side > 0 else 180, 0)
		van_root.add_child(sign_lbl)
	
	# Build Decorative Wares (Item 7)
	build_decorative_wares(counter.position)

func build_decorative_wares(counter_top: Vector3) -> void:
	var wares_root := Node3D.new()
	wares_root.name = "DecorativeWares"
	storefront_root.add_child(wares_root)
	
	var mat_metal := StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.18, 0.19, 0.22)
	mat_metal.metallic = 0.85
	mat_metal.roughness = 0.25
	
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.5, 0.24, 0.12)
	mat_wood.roughness = 0.6
	
	var mat_ammo_box := StandardMaterial3D.new()
	mat_ammo_box.albedo_color = Color(0.22, 0.38, 0.22)
	mat_ammo_box.metallic = 0.5
	mat_ammo_box.roughness = 0.45
	
	var mat_medkit := StandardMaterial3D.new()
	mat_medkit.albedo_color = Color(0.96, 0.96, 0.96)
	mat_medkit.roughness = 0.3
	
	var mat_cross := StandardMaterial3D.new()
	mat_cross.albedo_color = Color(0.9, 0.15, 0.15)
	mat_cross.emission_enabled = true
	mat_cross.emission = Color(0.9, 0.15, 0.15)
	mat_cross.emission_energy_multiplier = 0.6
	
	var mat_vest := StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.15, 0.16, 0.18)
	mat_vest.roughness = 0.7
	
	var mat_vodka_glass := StandardMaterial3D.new()
	mat_vodka_glass.albedo_color = Color(0.85, 0.92, 0.95, 0.7)
	mat_vodka_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vodka_glass.roughness = 0.1
	
	var mat_vodka_label := StandardMaterial3D.new()
	mat_vodka_label.albedo_color = Color(0.95, 0.92, 0.85)
	
	# 1. Decorative AK-47 on display rack
	var ak_model := Node3D.new()
	ak_model.position = counter_top + Vector3(-0.6, 0.22, -0.05)
	ak_model.rotation_degrees = Vector3(15, -45, 0)
	ak_model.scale = Vector3(0.85, 0.85, 0.85)
	wares_root.add_child(ak_model)
	
	var ak_rec := MeshInstance3D.new()
	var ak_rm := BoxMesh.new()
	ak_rm.size = Vector3(0.045, 0.08, 0.42)
	ak_rec.mesh = ak_rm
	ak_rec.material_override = mat_metal
	ak_model.add_child(ak_rec)
	
	var ak_bar := MeshInstance3D.new()
	var ak_bm := BoxMesh.new()
	ak_bm.size = Vector3(0.02, 0.02, 0.35)
	ak_bar.mesh = ak_bm
	ak_bar.material_override = mat_metal
	ak_bar.position = Vector3(0, 0.015, -0.32)
	ak_model.add_child(ak_bar)
	
	var ak_wood := MeshInstance3D.new()
	var ak_wm := BoxMesh.new()
	ak_wm.size = Vector3(0.04, 0.09, 0.22)
	ak_wood.mesh = ak_wm
	ak_wood.material_override = mat_wood
	ak_wood.position = Vector3(0, -0.02, 0.28)
	ak_model.add_child(ak_wood)
	
	var ak_mag := MeshInstance3D.new()
	var ak_mm := BoxMesh.new()
	ak_mm.size = Vector3(0.03, 0.16, 0.09)
	ak_mag.mesh = ak_mm
	ak_mag.material_override = mat_metal
	ak_mag.position = Vector3(0, -0.11, -0.04)
	ak_mag.rotation_degrees = Vector3(18, 0, 0)
	ak_model.add_child(ak_mag)
	
	var ak_grip := MeshInstance3D.new()
	var ak_gm := BoxMesh.new()
	ak_gm.size = Vector3(0.032, 0.10, 0.048)
	ak_grip.mesh = ak_gm
	ak_grip.material_override = mat_wood
	ak_grip.position = Vector3(0, -0.075, 0.08)
	ak_grip.rotation_degrees = Vector3(-20, 0, 0)
	ak_model.add_child(ak_grip)
	
	# 2. Decorative Shotgun
	var sg_model := Node3D.new()
	sg_model.position = counter_top + Vector3(-0.2, 0.18, 0.12)
	sg_model.rotation_degrees = Vector3(10, -50, 0)
	sg_model.scale = Vector3(0.85, 0.85, 0.85)
	wares_root.add_child(sg_model)
	
	var sg_rec := MeshInstance3D.new()
	var sg_rm := BoxMesh.new()
	sg_rm.size = Vector3(0.042, 0.075, 0.38)
	sg_rec.mesh = sg_rm
	sg_rec.material_override = mat_metal
	sg_model.add_child(sg_rec)
	
	var sg_bar := MeshInstance3D.new()
	var sg_bm := CylinderMesh.new()
	sg_bm.top_radius = 0.016
	sg_bm.bottom_radius = 0.016
	sg_bm.height = 0.42
	sg_bar.mesh = sg_bm
	sg_bar.material_override = mat_metal
	sg_bar.rotation_degrees = Vector3(90, 0, 0)
	sg_bar.position = Vector3(0, 0.02, -0.32)
	sg_model.add_child(sg_bar)
	
	# 3. Decorative Glock Pistol
	var pst_model := Node3D.new()
	pst_model.position = counter_top + Vector3(0.3, 0.08, 0.15)
	pst_model.rotation_degrees = Vector3(90, 0, 25)
	pst_model.scale = Vector3(0.9, 0.9, 0.9)
	wares_root.add_child(pst_model)
	
	var pst_slide := MeshInstance3D.new()
	var pst_sm := BoxMesh.new()
	pst_sm.size = Vector3(0.034, 0.04, 0.19)
	pst_slide.mesh = pst_sm
	pst_slide.material_override = mat_metal
	pst_model.add_child(pst_slide)
	
	var pst_grip := MeshInstance3D.new()
	var pst_gm := BoxMesh.new()
	pst_gm.size = Vector3(0.03, 0.11, 0.05)
	pst_grip.mesh = pst_gm
	pst_grip.material_override = mat_metal
	pst_grip.position = Vector3(0, -0.065, 0.05)
	pst_grip.rotation_degrees = Vector3(-15, 0, 0)
	pst_model.add_child(pst_grip)
	
	# 4. Decorative Military Ammo Boxes (2 boxes stacked)
	for ab_i in range(2):
		var abox := MeshInstance3D.new()
		var abm := BoxMesh.new()
		abm.size = Vector3(0.32, 0.18, 0.22)
		abox.mesh = abm
		abox.material_override = mat_ammo_box
		abox.position = counter_top + Vector3(0.75, 0.09 + ab_i * 0.18, 0.05)
		abox.rotation_degrees = Vector3(0, 8 * (ab_i - 0.5), 0)
		wares_root.add_child(abox)
		
	# 5. Decorative Medkits (White boxes with red cross)
	for mk_i in range(2):
		var mk := Node3D.new()
		mk.position = counter_top + Vector3(1.15, 0.09, 0.08 - mk_i * 0.22)
		mk.rotation_degrees = Vector3(0, -12 * mk_i, 0)
		wares_root.add_child(mk)
		
		var mk_box := MeshInstance3D.new()
		var mkm := BoxMesh.new()
		mkm.size = Vector3(0.24, 0.16, 0.18)
		mk_box.mesh = mkm
		mk_box.material_override = mat_medkit
		mk.add_child(mk_box)
		
		# Red Cross
		var c1 := MeshInstance3D.new()
		var c1m := BoxMesh.new()
		c1m.size = Vector3(0.03, 0.09, 0.005)
		c1.mesh = c1m
		c1.material_override = mat_cross
		c1.position = Vector3(0, 0, 0.092)
		mk.add_child(c1)
		
		var c2 := MeshInstance3D.new()
		var c2m := BoxMesh.new()
		c2m.size = Vector3(0.09, 0.03, 0.005)
		c2.mesh = c2m
		c2.material_override = mat_cross
		c2.position = Vector3(0, 0, 0.092)
		mk.add_child(c2)
		
	# 6. Decorative Body Armor Vest (hanging or folded behind counter)
	var vest := Node3D.new()
	vest.position = counter_top + Vector3(-1.05, 0.35, -0.45)
	vest.rotation_degrees = Vector3(0, 15, 0)
	wares_root.add_child(vest)
	
	var vest_body := MeshInstance3D.new()
	var vbm := BoxMesh.new()
	vbm.size = Vector3(0.48, 0.62, 0.24)
	vest_body.mesh = vbm
	vest_body.material_override = mat_vest
	vest.add_child(vest_body)
	
	# 7. Decorative Vodka Bottle "Чекунец 67"
	var vodka := Node3D.new()
	vodka.position = counter_top + Vector3(0.0, 0.14, 0.22)
	wares_root.add_child(vodka)
	
	var b_body := MeshInstance3D.new()
	var b_bm := CylinderMesh.new()
	b_bm.top_radius = 0.04
	b_bm.bottom_radius = 0.04
	b_bm.height = 0.20
	b_body.mesh = b_bm
	b_body.material_override = mat_vodka_glass
	vodka.add_child(b_body)
	
	var b_label := MeshInstance3D.new()
	var b_lm := CylinderMesh.new()
	b_lm.top_radius = 0.042
	b_lm.bottom_radius = 0.042
	b_lm.height = 0.10
	b_label.mesh = b_lm
	b_label.material_override = mat_vodka_label
	vodka.add_child(b_label)

func build_gray_crewmate() -> void:
	crewmate = Node3D.new()
	crewmate.name = "GrayCrewmateMerchant"
	add_child(crewmate)
	
	var mat_gray := StandardMaterial3D.new()
	mat_gray.albedo_color = Color(0.55, 0.55, 0.58)
	mat_gray.roughness = 0.35
	
	var mat_visor := StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.45, 0.85, 0.95)
	mat_visor.metallic = 0.4
	mat_visor.roughness = 0.1
	
	# Top Hat Materials
	var mat_hat := StandardMaterial3D.new()
	mat_hat.albedo_color = Color(0.08, 0.08, 0.10) # Classy matte/satin black
	mat_hat.roughness = 0.45
	mat_hat.metallic = 0.05
	
	var mat_ribbon := StandardMaterial3D.new()
	mat_ribbon.albedo_color = Color(0.80, 0.08, 0.14) # Hat crimson ribbon
	mat_ribbon.roughness = 0.35
	
	# 1. Crewmate Body Capsule
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.36
	bm.height = 1.25
	bm.radial_segments = 14
	bm.rings = 4
	body.mesh = bm
	body.material_override = mat_gray
	body.position = Vector3(0, 0.78, 0)
	crewmate.add_child(body)
	
	# 2. Visor (looking forward +Z)
	var visor := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.44, 0.24, 0.20)
	visor.mesh = vm
	visor.material_override = mat_visor
	visor.position = Vector3(0, 0.98, 0.28)
	crewmate.add_child(visor)
	
	# 3. Backpack (-Z)
	var bp := MeshInstance3D.new()
	var bpm := BoxMesh.new()
	bpm.size = Vector3(0.44, 0.62, 0.24)
	bp.mesh = bpm
	bp.material_override = mat_gray
	bp.position = Vector3(0, 0.78, -0.30)
	crewmate.add_child(bp)
	
	# 4. Legs
	for lx in [-0.20, 0.20]:
		var leg := MeshInstance3D.new()
		var lm := CapsuleMesh.new()
		lm.radius = 0.14
		lm.height = 0.48
		lm.radial_segments = 10
		leg.mesh = lm
		leg.material_override = mat_gray
		leg.position = Vector3(lx, 0.24, 0)
		crewmate.add_child(leg)

	# --- GENTLEMAN TOP HAT (ШЛЯПА-ЦИЛИНДР) ---
	var hat_root := Node3D.new()
	hat_root.name = "TopHat"
	hat_root.position = Vector3(0.0, 1.36, 0.02)
	hat_root.rotation_degrees = Vector3(-3.0, 0.0, 4.0) # Confident stylish merchant tilt
	crewmate.add_child(hat_root)
	
	# Hat Brim (Поля цилиндра)
	var brim := MeshInstance3D.new()
	var brim_m := CylinderMesh.new()
	brim_m.top_radius = 0.40
	brim_m.bottom_radius = 0.40
	brim_m.height = 0.035
	brim_m.radial_segments = 18
	brim.mesh = brim_m
	brim.material_override = mat_hat
	brim.position = Vector3(0, 0, 0)
	hat_root.add_child(brim)
	
	# Hat Silk Ribbon Band (Шелковая красная лента)
	var ribbon := MeshInstance3D.new()
	var ribbon_m := CylinderMesh.new()
	ribbon_m.top_radius = 0.272
	ribbon_m.bottom_radius = 0.272
	ribbon_m.height = 0.075
	ribbon_m.radial_segments = 16
	ribbon.mesh = ribbon_m
	ribbon.material_override = mat_ribbon
	ribbon.position = Vector3(0, 0.055, 0)
	hat_root.add_child(ribbon)
	
	# Hat Crown (Высокая тулья цилиндра)
	var crown := MeshInstance3D.new()
	var crown_m := CylinderMesh.new()
	crown_m.top_radius = 0.270
	crown_m.bottom_radius = 0.262
	crown_m.height = 0.46
	crown_m.radial_segments = 16
	crown.mesh = crown_m
	crown.material_override = mat_hat
	crown.position = Vector3(0, 0.245, 0)
	hat_root.add_child(crown)
	
	# Top rim cap (Верхушка цилиндра)
	var crown_top := MeshInstance3D.new()
	var ct_m := CylinderMesh.new()
	ct_m.top_radius = 0.275
	ct_m.bottom_radius = 0.275
	ct_m.height = 0.02
	ct_m.radial_segments = 16
	crown_top.mesh = ct_m
	crown_top.material_override = mat_hat
	crown_top.position = Vector3(0, 0.475, 0)
	hat_root.add_child(crown_top)
	
	crewmate.position = CREWMATE_SHOP_POS
	crewmate.rotation_degrees = CREWMATE_SHOP_ROT

func build_shop_zone() -> void:
	shop_zone = Area3D.new()
	shop_zone.name = "ShopZone"
	shop_zone.collision_layer = 0
	shop_zone.collision_mask = 1 # Player layer
	
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.2, 2.5, 2.6)
	col.shape = shape
	col.position = Vector3(0.4, 1.25, 2.4)
	shop_zone.add_child(col)
	
	shop_zone.body_entered.connect(_on_shop_zone_body_entered)
	shop_zone.body_exited.connect(_on_shop_zone_body_exited)
	add_child(shop_zone)
	
	# Floor marker ring / pad with glowing border
	floor_marker = Node3D.new()
	floor_marker.name = "FloorMarker"
	floor_marker.position = Vector3(0.4, 0.02, 2.4)
	add_child(floor_marker)
	
	var mat_neon := StandardMaterial3D.new()
	mat_neon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_neon.albedo_color = Color(0.2, 0.85, 1.0, 0.85)
	mat_neon.emission_enabled = true
	mat_neon.emission = Color(0.2, 0.85, 1.0)
	mat_neon.emission_energy_multiplier = 1.8
	
	# Border strips forming a shopping pad
	var half_w := 1.5
	var half_d := 1.2
	var th := 0.05
	
	var borders = [
		[Vector3(0, 0, -half_d), Vector3(half_w * 2, 0.015, th)],
		[Vector3(0, 0, half_d), Vector3(half_w * 2, 0.015, th)],
		[Vector3(-half_w, 0, 0), Vector3(th, 0.015, half_d * 2)],
		[Vector3(half_w, 0, 0), Vector3(th, 0.015, half_d * 2)]
	]
	for b in borders:
		var edge := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = b[1]
		edge.mesh = em
		edge.material_override = mat_neon
		edge.position = b[0]
		floor_marker.add_child(edge)
		
	# Floating Shop Indicator Label (high-res crisp text, hidden during ADS)
	var lbl := Label3D.new()
	lbl.add_to_group("floating_3d_label")
	lbl.text = "🛒 МАГАЗИН [B]"
	lbl.font_size = 96
	lbl.pixel_size = 0.0022
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(0.25, 0.95, 1.0)
	lbl.outline_modulate = Color(0.05, 0.15, 0.25)
	lbl.outline_size = 20
	lbl.position = Vector3(0, 2.1, 0)
	floor_marker.add_child(lbl)

func _register_tween() -> Tween:
	var tw := create_tween()
	_active_tweens.append(tw)
	return tw

func _kill_active_tweens() -> void:
	for tw in _active_tweens:
		if is_instance_valid(tw) and tw.is_running():
			tw.kill()
	_active_tweens.clear()

func _stop_van_audio() -> void:
	if audio_player:
		audio_player.stop()
		audio_player.volume_db = 0.0

func set_parked_state(parked: bool) -> void:
	is_parked = parked
	if floor_marker:
		floor_marker.visible = parked
	if shop_zone:
		shop_zone.monitoring = parked
	if headlights_light:
		headlights_light.light_energy = 0.8 if parked else 3.5
	if not parked and is_inside_tree():
		for p in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(p) and p.has_method("set_near_shop"):
				p.set_near_shop(false)

func _on_shop_zone_body_entered(body: Node3D) -> void:
	if not is_parked or is_driving or not visible:
		return
	if body.is_in_group("player") and body.has_method("set_near_shop"):
		body.set_near_shop(true)

func _on_shop_zone_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_near_shop"):
		body.set_near_shop(false)

func on_wave_started() -> void:
	# Cancel any in-flight arrival/deployment sequence immediately so starting the wave early
	# NEVER leaves the minivan parked or interactable during the next wave!
	_sequence_id += 1
	var my_seq: int = _sequence_id
	_kill_active_tweens()
	set_parked_state(false)
	
	if not visible:
		_stop_van_audio()
		is_driving = false
		return
		
	is_driving = true
	
	# 1. Gray crewmate hops back into driver cabin (skip wait if already inside cabin)
	var hop_tween: Tween = null
	if crewmate and crewmate.position.distance_to(CREWMATE_CABIN_POS) > 0.05:
		hop_tween = _register_tween()
		hop_tween.tween_property(crewmate, "position", CREWMATE_CABIN_POS + Vector3(0, 0.35, 0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop_tween.tween_property(crewmate, "position", CREWMATE_CABIN_POS, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hop_tween.parallel().tween_property(crewmate, "rotation_degrees", CREWMATE_CABIN_ROT, 0.30)
	elif crewmate:
		crewmate.position = CREWMATE_CABIN_POS
		crewmate.rotation_degrees = CREWMATE_CABIN_ROT
	
	# 2. Storefront and merchandise retract into van cargo bay (only animate if currently extended)
	if storefront_root and absf(storefront_root.position.z - (-1.05)) > 0.03:
		var retract_tween := _register_tween()
		retract_tween.tween_property(storefront_root, "position:z", -1.05, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await retract_tween.finished
		if my_seq != _sequence_id:
			return
	elif storefront_root:
		storefront_root.position.z = -1.05
		
	# 3. Shutter closes down over opening (only animate if currently open)
	if canopy_pivot and absf(canopy_pivot.rotation_degrees.x - 88.0) > 2.0:
		var shutter_tween := _register_tween()
		shutter_tween.tween_property(canopy_pivot, "rotation_degrees:x", 88.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await shutter_tween.finished
		if my_seq != _sequence_id:
			return
	elif canopy_pivot:
		canopy_pivot.rotation_degrees.x = 88.0
		
	# Ensure crewmate has finished hopping inside before driving off
	if hop_tween and is_instance_valid(hop_tween) and hop_tween.is_running():
		await hop_tween.finished
		if my_seq != _sequence_id:
			return
		
	if audio_player:
		var engine_stream := SoundEffects.create_van_engine_sound()
		audio_player.volume_db = 0.0
		if not audio_player.playing or audio_player.stream != engine_stream:
			audio_player.stream = engine_stream
			audio_player.play()
		
	# 4. Minivan drives forward away into distance - strictly forward (local -X direction)
	var forward_dir := -global_transform.basis.x.normalized()
	var max_depart_d: float = 38.0
	if forward_dir.x > 0.001:
		max_depart_d = minf(max_depart_d, (78.0 - global_position.x) / forward_dir.x)
	elif forward_dir.x < -0.001:
		max_depart_d = minf(max_depart_d, (-78.0 - global_position.x) / forward_dir.x)
	if forward_dir.z > 0.001:
		max_depart_d = minf(max_depart_d, (78.0 - global_position.z) / forward_dir.z)
	elif forward_dir.z < -0.001:
		max_depart_d = minf(max_depart_d, (-78.0 - global_position.z) / forward_dir.z)
	max_depart_d = clampf(max_depart_d, 14.0, 42.0)
	var depart_pos := global_position + forward_dir * max_depart_d
	
	var drive_tween := _register_tween()
	drive_tween.tween_property(self, "position", depart_pos, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Smoothly fade out engine audio as the van drives out of sight
	if audio_player:
		var fade_tween := _register_tween()
		fade_tween.tween_interval(1.45)
		fade_tween.tween_property(audio_player, "volume_db", -42.0, 0.72)
	await drive_tween.finished
	if my_seq != _sequence_id:
		return
	
	# Stop looping engine sound completely once invisible!
	_stop_van_audio()
	visible = false
	is_driving = false

func on_wave_cleared() -> void:
	_sequence_id += 1
	var my_seq: int = _sequence_id
	_kill_active_tweens()
	_stop_van_audio()
	set_parked_state(false)
	is_driving = true
	
	# 1. Locate player to build donut parking spot
	var player_pos := Vector3.ZERO
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		player_pos = players[0].global_position
		player_pos.y = 0.0
		
	# Strict arena boundary constraints (Map size is 165x165m, walls at +-82.5m)
	# SAFE_PARK_BOUND = 58.0m guarantees parked van has >=24m buffer from walls
	# SAFE_START_BOUND = 70.0m guarantees spawn position has >=12m buffer from walls
	const SAFE_PARK_BOUND: float = 58.0
	const SAFE_START_BOUND: float = 70.0
	
	var chosen_park_pos := Vector3.ZERO
	var chosen_start_pos := Vector3.ZERO
	var chosen_rot_y: float = 0.0
	var chosen_drive_dist: float = 22.0
	var found_valid_spot: bool = false
	
	var dist_from_center: float = Vector2(player_pos.x, player_pos.z).length()
	var to_center := -player_pos
	to_center.y = 0.0
	var center_angle: float = atan2(to_center.x, to_center.z) if dist_from_center > 0.1 else 0.0
	
	# Try up to 24 candidate angles to find an unobstructed, strictly in-bounds spot
	for attempt in range(24):
		var angle: float
		if dist_from_center > 18.0:
			# When player is near or towards the boundary, strictly pick angles pointing towards the arena interior!
			angle = center_angle + randf_range(-deg_to_rad(65.0), deg_to_rad(65.0))
		else:
			angle = randf_range(0.0, TAU)
			
		var radius := randf_range(DONUT_RADIUS_MIN, DONUT_RADIUS_MAX)
		var cand_park := player_pos + Vector3(sin(angle), 0.0, cos(angle)) * radius
		
		# Clamp park_pos strictly within SAFE_PARK_BOUND
		cand_park.x = clampf(cand_park.x, -SAFE_PARK_BOUND, SAFE_PARK_BOUND)
		cand_park.z = clampf(cand_park.z, -SAFE_PARK_BOUND, SAFE_PARK_BOUND)
		cand_park.y = 0.0
		
		var to_p := (player_pos - cand_park)
		to_p.y = 0.0
		var dist_to_p := to_p.length()
		if dist_to_p < 8.0:
			continue
		to_p = to_p.normalized()
		
		# Check overlap with static obstacle AABBs so van doesn't spawn inside a vehicle or container
		var van_box := AABB(Vector3(cand_park.x - 2.8, 0.0, cand_park.z - 1.8), Vector3(5.6, 2.5, 3.6))
		var collides_obstacle := false
		for o_aabb in MapObstacles.obstacle_aabbs:
			if o_aabb.intersects(van_box):
				collides_obstacle = true
				break
		if collides_obstacle:
			continue
			
		var cand_rot_y := rad_to_deg(atan2(to_p.x, to_p.z))
		var front_dir := -Transform3D(Basis(Vector3.UP, deg_to_rad(cand_rot_y)), Vector3.ZERO).basis.x.normalized()
		
		# Analytically calculate maximum safe distance backwards along -front_dir that keeps start_pos <= SAFE_START_BOUND
		var max_safe_d: float = 26.0
		if front_dir.x > 0.001:
			max_safe_d = minf(max_safe_d, (cand_park.x + SAFE_START_BOUND) / front_dir.x)
		elif front_dir.x < -0.001:
			max_safe_d = minf(max_safe_d, (cand_park.x - SAFE_START_BOUND) / front_dir.x)
			
		if front_dir.z > 0.001:
			max_safe_d = minf(max_safe_d, (cand_park.z + SAFE_START_BOUND) / front_dir.z)
		elif front_dir.z < -0.001:
			max_safe_d = minf(max_safe_d, (cand_park.z - SAFE_START_BOUND) / front_dir.z)
			
		if max_safe_d >= 9.0:
			chosen_park_pos = cand_park
			chosen_drive_dist = minf(22.0, max_safe_d)
			chosen_start_pos = cand_park - front_dir * chosen_drive_dist
			chosen_rot_y = cand_rot_y
			found_valid_spot = true
			break
			
	# Guaranteed fallback if all random candidates had obstacles
	if not found_valid_spot:
		var safe_dir := to_center.normalized() if dist_from_center > 0.1 else Vector3(0.0, 0.0, 1.0)
		chosen_park_pos = player_pos + safe_dir * 14.0
		chosen_park_pos.x = clampf(chosen_park_pos.x, -SAFE_PARK_BOUND, SAFE_PARK_BOUND)
		chosen_park_pos.z = clampf(chosen_park_pos.z, -SAFE_PARK_BOUND, SAFE_PARK_BOUND)
		var to_p := (player_pos - chosen_park_pos)
		to_p.y = 0.0
		if to_p.length() < 0.1:
			to_p = Vector3(0.0, 0.0, 1.0)
		to_p = to_p.normalized()
		chosen_rot_y = rad_to_deg(atan2(to_p.x, to_p.z))
		var front_dir := -Transform3D(Basis(Vector3.UP, deg_to_rad(chosen_rot_y)), Vector3.ZERO).basis.x.normalized()
		var max_safe_d: float = 22.0
		if front_dir.x > 0.001:
			max_safe_d = minf(max_safe_d, (chosen_park_pos.x + SAFE_START_BOUND) / front_dir.x)
		elif front_dir.x < -0.001:
			max_safe_d = minf(max_safe_d, (chosen_park_pos.x - SAFE_START_BOUND) / front_dir.x)
		if front_dir.z > 0.001:
			max_safe_d = minf(max_safe_d, (chosen_park_pos.z + SAFE_START_BOUND) / front_dir.z)
		elif front_dir.z < -0.001:
			max_safe_d = minf(max_safe_d, (chosen_park_pos.z - SAFE_START_BOUND) / front_dir.z)
		chosen_drive_dist = clampf(max_safe_d, 8.0, 20.0)
		chosen_start_pos = chosen_park_pos - front_dir * chosen_drive_dist
		
	# Minivan spawns at start_pos and drives strictly forward to park_pos!
	position = chosen_start_pos
	rotation_degrees = Vector3(0.0, chosen_rot_y, 0.0)
	visible = true
	
	if crewmate:
		crewmate.position = CREWMATE_CABIN_POS
		crewmate.rotation_degrees = CREWMATE_CABIN_ROT
		
	if canopy_pivot:
		canopy_pivot.rotation_degrees.x = 88.0 # Shutter closed while driving
	if storefront_root:
		storefront_root.position.z = -1.05 # Storefront tucked inside
		
	if audio_player:
		audio_player.volume_db = 0.0
		audio_player.stream = SoundEffects.create_van_engine_sound()
		audio_player.play()
		
	# 5. Drives directly forward into the parking spot (Smooth deceleration to a stop, NO REVERSE!)
	var drive_duration: float = clampf(chosen_drive_dist / 12.0, 1.2, 1.9)
	var drive_in := _register_tween()
	drive_in.tween_property(self, "position", chosen_park_pos, drive_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await drive_in.finished
	if my_seq != _sequence_id:
		return
	
	# 6. Stopped in parking spot: stop engine loop & play arrival horn beep
	if audio_player:
		audio_player.stop()
		audio_player.volume_db = 0.0
		audio_player.stream = SoundEffects.create_van_horn_sound()
		audio_player.play()
		
	# 7. Open counter shutter
	if canopy_pivot:
		var open_tween := _register_tween()
		open_tween.tween_property(canopy_pivot, "rotation_degrees:x", 14.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await open_tween.finished
		if my_seq != _sequence_id:
			return
		
	# 8. Storefront and merchandise wares slide out smoothly into display position
	if storefront_root:
		var slide_out := _register_tween()
		slide_out.tween_property(storefront_root, "position:z", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await slide_out.finished
		if my_seq != _sequence_id:
			return
		
	# 9. Crewmate steps out to counter and faces customer
	if crewmate:
		var step_tween := _register_tween()
		step_tween.tween_property(crewmate, "position", CREWMATE_SHOP_POS + Vector3(0, 0.35, 0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		step_tween.tween_property(crewmate, "position", CREWMATE_SHOP_POS, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		step_tween.parallel().tween_property(crewmate, "rotation_degrees", CREWMATE_SHOP_ROT, 0.4)
		await step_tween.finished
		if my_seq != _sequence_id:
			return
		
	set_parked_state(true)
	is_driving = false
