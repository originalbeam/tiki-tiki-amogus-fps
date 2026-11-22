class_name PreviewShop
extends RefCounted

# Handbook 3D Minivan Shop Preview
# Faithfully showcases the mobile minivan shop with:
# - Automotive body, hood, angled windshield, bumpers, 4 wheels with rims
# - Chrome grille, headlights, license plates "А 777 МР 77"
# - Side awning canopy, wooden counter & legs
# - Displayed merchandise wares: AK-47, shotgun, pistol, ammo cans, medkits, armor vest, vodka
# - Gray crewmate merchant wearing the classy black top hat with crimson ribbon

static func create() -> Node3D:
	var root := Node3D.new()
	root.name = "MinivanShopPreview"
	root.position = Vector3(0, -0.65, 0)
	
	# Materials
	var mat_van_body := StandardMaterial3D.new()
	mat_van_body.albedo_color = Color(0.22, 0.26, 0.32) # Dark navy / graphite
	mat_van_body.metallic = 0.65
	mat_van_body.roughness = 0.35
	
	var mat_bumper := StandardMaterial3D.new()
	mat_bumper.albedo_color = Color(0.12, 0.12, 0.14)
	mat_bumper.metallic = 0.4
	mat_bumper.roughness = 0.6
	
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.2, 0.45, 0.6, 0.75)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.metallic = 0.8
	mat_glass.roughness = 0.1
	
	var mat_tire := StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.1, 0.1, 0.1)
	mat_tire.roughness = 0.85
	
	var mat_rim := StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.75, 0.78, 0.82)
	mat_rim.metallic = 0.9
	mat_rim.roughness = 0.2
	
	var mat_lights := StandardMaterial3D.new()
	mat_lights.albedo_color = Color(1.0, 0.95, 0.7)
	mat_lights.emission_enabled = true
	mat_lights.emission = Color(1.0, 0.95, 0.7)
	mat_lights.emission_energy_multiplier = 2.0
	
	var mat_taillights := StandardMaterial3D.new()
	mat_taillights.albedo_color = Color(0.9, 0.1, 0.1)
	mat_taillights.emission_enabled = true
	mat_taillights.emission = Color(0.9, 0.1, 0.1)
	mat_taillights.emission_energy_multiplier = 1.6
	
	var mat_wood_counter := StandardMaterial3D.new()
	mat_wood_counter.albedo_color = Color(0.42, 0.24, 0.12)
	mat_wood_counter.roughness = 0.6
	
	var mat_canopy := StandardMaterial3D.new()
	mat_canopy.albedo_color = Color(0.90, 0.65, 0.15)
	mat_canopy.roughness = 0.55
	
	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.92, 0.95, 0.98)
	mat_chrome.metallic = 0.95
	mat_chrome.roughness = 0.12
	
	var mat_grille := StandardMaterial3D.new()
	mat_grille.albedo_color = Color(0.08, 0.08, 0.09)
	mat_grille.metallic = 0.2
	mat_grille.roughness = 0.85
	
	var mat_plate := StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.94, 0.94, 0.94)
	mat_plate.roughness = 0.4

	# 1. Main Van Cargo Body Box
	var body_box := MeshInstance3D.new()
	var bbm := BoxMesh.new()
	bbm.size = Vector3(4.8, 1.8, 2.2)
	body_box.mesh = bbm
	body_box.material_override = mat_van_body
	body_box.position = Vector3(0.0, 1.25, 0.0)
	root.add_child(body_box)
	
	# 2. Front Hood (Engine Bay)
	var hood_box := MeshInstance3D.new()
	var hbm := BoxMesh.new()
	hbm.size = Vector3(1.2, 1.1, 2.15)
	hood_box.mesh = hbm
	hood_box.material_override = mat_van_body
	hood_box.position = Vector3(-2.6, 0.85, 0.0)
	root.add_child(hood_box)
	
	# 3. Front Angled Windshield
	var windshield := MeshInstance3D.new()
	var wsm := BoxMesh.new()
	wsm.size = Vector3(0.7, 0.95, 2.05)
	windshield.mesh = wsm
	windshield.material_override = mat_glass
	windshield.position = Vector3(-2.1, 1.62, 0.0)
	windshield.rotation_degrees = Vector3(0, 0, -28)
	root.add_child(windshield)
	
	# 4. Bumpers
	var front_bumper := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(0.35, 0.35, 2.25)
	front_bumper.mesh = fbm
	front_bumper.material_override = mat_bumper
	front_bumper.position = Vector3(-3.25, 0.45, 0.0)
	root.add_child(front_bumper)
	
	var rear_bumper := MeshInstance3D.new()
	rear_bumper.mesh = fbm
	rear_bumper.material_override = mat_bumper
	rear_bumper.position = Vector3(2.45, 0.45, 0.0)
	root.add_child(rear_bumper)
	
	# 5. 4 Wheels with Rims
	var wheel_coords = [
		Vector3(-1.7, 0.45, 1.12),
		Vector3(-1.7, 0.45, -1.12),
		Vector3(1.6, 0.45, 1.12),
		Vector3(1.6, 0.45, -1.12)
	]
	var cm := CylinderMesh.new()
	cm.top_radius = 0.44
	cm.bottom_radius = 0.44
	cm.height = 0.28
	cm.radial_segments = 16
	
	var rm := CylinderMesh.new()
	rm.top_radius = 0.25
	rm.bottom_radius = 0.25
	rm.height = 0.30
	rm.radial_segments = 14
	
	for wc in wheel_coords:
		var wheel := MeshInstance3D.new()
		wheel.mesh = cm
		wheel.material_override = mat_tire
		wheel.position = wc
		wheel.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(wheel)
		
		var rim := MeshInstance3D.new()
		rim.mesh = rm
		rim.material_override = mat_rim
		wheel.add_child(rim)

	# 6. Radiator Grille & Headlights
	var grille := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.08, 0.46, 1.10)
	grille.mesh = gm
	grille.material_override = mat_grille
	grille.position = Vector3(-3.24, 0.95, 0.0)
	root.add_child(grille)
	
	for gy in [-0.12, 0.12]:
		var slat := MeshInstance3D.new()
		var sm_slat := BoxMesh.new()
		sm_slat.size = Vector3(0.03, 0.03, 1.06)
		slat.mesh = sm_slat
		slat.material_override = mat_chrome
		slat.position = Vector3(-3.27, 0.95 + gy, 0.0)
		root.add_child(slat)
		
	for gz in [-0.82, 0.82]:
		var hl := MeshInstance3D.new()
		var hlm := CylinderMesh.new()
		hlm.top_radius = 0.14
		hlm.bottom_radius = 0.14
		hlm.height = 0.08
		hl.mesh = hlm
		hl.material_override = mat_lights
		hl.rotation_degrees = Vector3(0, 0, 90)
		hl.position = Vector3(-3.24, 0.95, gz)
		root.add_child(hl)

	# Rear Taillights
	for rz in [-0.85, 0.85]:
		var tl := MeshInstance3D.new()
		var tlm := BoxMesh.new()
		tlm.size = Vector3(0.05, 0.35, 0.16)
		tl.mesh = tlm
		tl.material_override = mat_taillights
		tl.position = Vector3(2.43, 1.25, rz)
		root.add_child(tl)

	# 7. License Plates
	var f_plate := MeshInstance3D.new()
	var f_pm := BoxMesh.new()
	f_pm.size = Vector3(0.03, 0.15, 0.52)
	f_plate.mesh = f_pm
	f_plate.material_override = mat_plate
	f_plate.position = Vector3(-3.43, 0.45, 0.0)
	root.add_child(f_plate)
	
	var f_lbl := Label3D.new()
	f_lbl.text = "А 777 МР 77"
	f_lbl.font_size = 18
	f_lbl.modulate = Color(0.08, 0.08, 0.10)
	f_lbl.position = Vector3(-3.45, 0.45, 0.0)
	f_lbl.rotation_degrees = Vector3(0, -90, 0)
	root.add_child(f_lbl)

	# 8. Storefront Canopy & Counter (+Z side)
	var canopy_pivot := Node3D.new()
	canopy_pivot.position = Vector3(0.2, 2.15, 1.10)
	canopy_pivot.rotation_degrees = Vector3(14.0, 0.0, 0.0)
	root.add_child(canopy_pivot)
	
	var canopy := MeshInstance3D.new()
	var canopy_m := BoxMesh.new()
	canopy_m.size = Vector3(2.8, 0.08, 1.3)
	canopy.mesh = canopy_m
	canopy.material_override = mat_canopy
	canopy.position = Vector3(0.0, 0.0, 0.65)
	canopy_pivot.add_child(canopy)
	
	# Counter tabletop
	var counter := MeshInstance3D.new()
	var counter_m := BoxMesh.new()
	counter_m.size = Vector3(2.6, 0.10, 0.65)
	counter.mesh = counter_m
	counter.material_override = mat_wood_counter
	counter.position = Vector3(0.2, 0.95, 1.25)
	root.add_child(counter)
	
	# Counter legs
	for cx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_m := BoxMesh.new()
		leg_m.size = Vector3(0.08, 0.90, 0.08)
		leg.mesh = leg_m
		leg.material_override = mat_bumper
		leg.position = Vector3(0.2 + cx, 0.45, 1.5)
		root.add_child(leg)

	# 9. Roof Neon Sign: "★ ОРУЖЕЙНАЯ ЛАВКА ★"
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
	root.add_child(sign_mesh)

	var sign_lbl := Label3D.new()
	sign_lbl.text = "★ ОРУЖЕЙНАЯ ЛАВКА ★"
	sign_lbl.font_size = 22
	sign_lbl.modulate = Color(0.25, 0.92, 1.0)
	sign_lbl.outline_modulate = Color(0.05, 0.1, 0.15)
	sign_lbl.outline_size = 6
	sign_lbl.position = Vector3(0.0, 2.45, 0.07)
	root.add_child(sign_lbl)

	# 10. Merchandise Wares on the Counter
	_build_preview_wares(root, counter.position)

	# 11. Gray Crewmate Merchant in Top Hat
	_build_preview_merchant(root)
	
	return root

static func _build_preview_wares(parent: Node3D, c_pos: Vector3) -> void:
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
	
	var mat_vodka_glass := StandardMaterial3D.new()
	mat_vodka_glass.albedo_color = Color(0.85, 0.92, 0.95, 0.7)
	mat_vodka_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vodka_glass.roughness = 0.1

	var mat_label := StandardMaterial3D.new()
	mat_label.albedo_color = Color(0.95, 0.92, 0.85)

	# AK-47 on display rack
	var ak := AK47Model.create()
	ak.scale = Vector3(0.7, 0.7, 0.7)
	ak.position = c_pos + Vector3(-0.65, 0.20, -0.05)
	ak.rotation_degrees = Vector3(15, -45, 0)
	parent.add_child(ak)

	# Stacked Military Ammo Crates
	for ab_i in range(2):
		var abox := MeshInstance3D.new()
		var abm := BoxMesh.new()
		abm.size = Vector3(0.30, 0.16, 0.20)
		abox.mesh = abm
		abox.material_override = mat_ammo_box
		abox.position = c_pos + Vector3(0.55, 0.08 + ab_i * 0.16, 0.05)
		abox.rotation_degrees = Vector3(0, 8 * (ab_i - 0.5), 0)
		parent.add_child(abox)

	# Field Medkit with Red Cross
	var mk := Node3D.new()
	mk.position = c_pos + Vector3(0.95, 0.08, 0.06)
	parent.add_child(mk)
	
	var mk_box := MeshInstance3D.new()
	var mkm := BoxMesh.new()
	mkm.size = Vector3(0.24, 0.15, 0.18)
	mk_box.mesh = mkm
	mk_box.material_override = mat_medkit
	mk.add_child(mk_box)
	
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

	# Vodka Bottle "Чекунец 67"
	var vodka := Node3D.new()
	vodka.position = c_pos + Vector3(-0.05, 0.12, 0.18)
	parent.add_child(vodka)
	
	var vb := MeshInstance3D.new()
	var vbm := CylinderMesh.new()
	vbm.top_radius = 0.038
	vbm.bottom_radius = 0.040
	vbm.height = 0.18
	vb.mesh = vbm
	vb.material_override = mat_vodka_glass
	vodka.add_child(vb)
	
	var lbl := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.041
	lm.bottom_radius = 0.041
	lm.height = 0.09
	lbl.mesh = lm
	lbl.material_override = mat_label
	lbl.position = Vector3(0, -0.01, 0)
	vodka.add_child(lbl)

static func _build_preview_merchant(parent: Node3D) -> void:
	# Unarmed Gray Crewmate with Top Hat
	var merchant := PreviewCrewmate.create(Color(0.55, 0.58, 0.62), -1)
	merchant.position = Vector3(1.35, 0.0, 1.85)
	merchant.rotation_degrees = Vector3(0, -52, 0)
	parent.add_child(merchant)
	
	# Classy Black Top Hat with Crimson Ribbon
	var mat_hat := StandardMaterial3D.new()
	mat_hat.albedo_color = Color(0.08, 0.08, 0.10)
	mat_hat.roughness = 0.45
	mat_hat.metallic = 0.05
	
	var mat_ribbon := StandardMaterial3D.new()
	mat_ribbon.albedo_color = Color(0.80, 0.08, 0.14)
	mat_ribbon.roughness = 0.35
	
	# Brim
	var brim := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.38
	bm.bottom_radius = 0.38
	bm.height = 0.035
	brim.mesh = bm
	brim.material_override = mat_hat
	brim.position = Vector3(0, 1.62, 0)
	merchant.add_child(brim)
	
	# Crown
	var crown := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.25
	cm.height = 0.35
	crown.mesh = cm
	crown.material_override = mat_hat
	crown.position = Vector3(0, 1.81, 0)
	merchant.add_child(crown)
	
	# Ribbon
	var ribbon := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.258
	rm.bottom_radius = 0.253
	rm.height = 0.065
	ribbon.mesh = rm
	ribbon.material_override = mat_ribbon
	ribbon.position = Vector3(0, 1.67, 0)
	merchant.add_child(ribbon)
