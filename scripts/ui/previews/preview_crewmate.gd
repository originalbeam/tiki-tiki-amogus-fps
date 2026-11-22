class_name PreviewCrewmate
extends RefCounted

# High-Fidelity Tactical Astronaut Crewmate Builder
# Shared by BOTH live Battlefield Enemies (enemy.gd) AND Handbook 3D Inspector!
# Features:
# - Sculpted EVA astronaut suit with contoured waist belt, metallic buckle & collar ring
# - Rounded beveled reflective glass visor with anodized outer frame & diagonal specular glint
# - Detailed EVA pressurized backpack with dual oxygen valves, pressure strip & chest harness straps
# - Articulated LeftLeg / RightLeg with reinforced tactical combat boots & treaded soles
# - Class-specific combat equipment per EnemyType:
#   0 (RED_STANDARD): Combat helmet with NVG shroud + chest rig with 3 AK mag pouches + AK-47
#   1 (BLUE_SCOUT): Recon comm antenna backpack + tactical headset + chest holster + Tactical Pistol
#   2 (YELLOW_HEAVY): Heavy Juggernaut armor plates, dual shoulder pauldrons, armored visor brow + Fire Axe
#   3 (GREEN_SNIPER): Recon sniper hood/boonie, shoulder ghillie drape, visor rangefinder + AWP Sniper Rifle

const AK47Model = preload("res://scripts/weapons/models/ak47_model.gd")
const PistolModel = preload("res://scripts/weapons/models/pistol_model.gd")
const AxeModel = preload("res://scripts/weapons/models/axe_model.gd")
const SniperModel = preload("res://scripts/weapons/models/sniper_model.gd")

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

# Populates a crewmate visual root node and returns a dictionary of animated/flashable parts!
static func populate_crewmate_visuals(visuals_root: Node3D, color: Color, enemy_type: int = 0) -> Dictionary:
	var mat_suit := StandardMaterial3D.new()
	mat_suit.albedo_color = color
	mat_suit.roughness = 0.38
	mat_suit.metallic = 0.06
	
	var mat_suit_dark := StandardMaterial3D.new()
	mat_suit_dark.albedo_color = color.darkened(0.32)
	mat_suit_dark.roughness = 0.55
	
	var mat_gear := StandardMaterial3D.new()
	mat_gear.albedo_color = Color(0.11, 0.12, 0.13) # Tactical nylon/Cordura
	mat_gear.roughness = 0.80
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.20, 0.22, 0.25)
	mat_steel.metallic = 0.86
	mat_steel.roughness = 0.30
	
	var mat_visor_glass := StandardMaterial3D.new()
	mat_visor_glass.albedo_color = Color(0.36, 0.82, 0.96) if enemy_type != 2 else Color(0.88, 0.68, 0.22)
	mat_visor_glass.metallic = 0.68
	mat_visor_glass.roughness = 0.06
	
	var mat_visor_glare := StandardMaterial3D.new()
	mat_visor_glare.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_visor_glare.albedo_color = Color(0.92, 0.98, 1.0, 0.78)
	mat_visor_glare.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mat_boot := StandardMaterial3D.new()
	mat_boot.albedo_color = Color(0.09, 0.095, 0.10)
	mat_boot.roughness = 0.82
	
	var suit_meshes: Array[MeshInstance3D] = []

	# ==========================================
	# 1. SCULPTED EVA ASTRONAUT BODY & WAIST BELT
	# ==========================================
	var body := MeshInstance3D.new()
	body.name = "Body"
	var bm := CapsuleMesh.new()
	bm.radius = 0.43
	bm.height = 1.44
	bm.radial_segments = 20
	bm.rings = 8
	body.mesh = bm
	body.material_override = mat_suit
	body.position = Vector3(0, 0.96, 0)
	visuals_root.add_child(body)
	suit_meshes.append(body)
	
	# Neck collar seal ring & tactical waist utility belt with buckle
	var belt := _add_cyl(visuals_root, "WaistBelt", 0.445, 0.445, 0.11, Vector3(0, 0.62, 0), mat_gear, 20)
	_add_box(belt, "BeltBuckle", Vector3(0.14, 0.095, 0.05), Vector3(0, 0, 0.44), mat_steel)
	for px in [-0.36, 0.36]:
		_add_box(belt, "HipPouch", Vector3(0.11, 0.14, 0.14), Vector3(px, -0.02, 0.16), mat_gear)

	# ==========================================
	# 2. BEVELED CURVED GLASS VISOR + ANODIZED FRAME
	# ==========================================
	var visor_root := Node3D.new()
	visor_root.name = "VisorGroup"
	visor_root.position = Vector3(0, 1.21, 0.35)
	visuals_root.add_child(visor_root)
	# Outer dark anodized visor bezel rim (rounded capsule rotated sideways!)
	var frame := MeshInstance3D.new()
	frame.name = "VisorFrame"
	var fm := CapsuleMesh.new()
	fm.radius = 0.175
	fm.height = 0.62
	fm.radial_segments = 16
	fm.rings = 6
	frame.mesh = fm
	frame.material_override = mat_steel
	frame.rotation_degrees = Vector3(0, 0, 90.0)
	frame.scale = Vector3(1.0, 1.0, 0.62)
	visor_root.add_child(frame)
	# Smooth reflective domed visor glass
	var visor := MeshInstance3D.new()
	visor.name = "Visor"
	var vm := CapsuleMesh.new()
	vm.radius = 0.145
	vm.height = 0.56
	vm.radial_segments = 16
	vm.rings = 6
	visor.mesh = vm
	visor.material_override = mat_visor_glass
	visor.rotation_degrees = Vector3(0, 0, 90.0)
	visor.scale = Vector3(1.0, 1.0, 0.68)
	visor.position = Vector3(0, 0, 0.03)
	visor_root.add_child(visor)
	# Crisp specular glass reflection highlight strip
	var glare := _add_box(visor_root, "VisorGlare", Vector3(0.24, 0.045, 0.015), Vector3(-0.08, 0.065, 0.132), mat_visor_glare, Vector3(0, 0, 14.0))
	glare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# ==========================================
	# 3. PRESSURIZED EVA BACKPACK + OXYGEN VALVES + HARNESS
	# ==========================================
	var bp := MeshInstance3D.new()
	bp.name = "Backpack"
	var bpm := BoxMesh.new()
	bpm.size = Vector3(0.50, 0.72, 0.27)
	bp.mesh = bpm
	bp.material_override = mat_suit
	bp.position = Vector3(0, 0.97, -0.39)
	visuals_root.add_child(bp)
	suit_meshes.append(bp)
	# Chamfered top cap, side tanks, vent grille & oxygen status bar
	_add_box(bp, "BpTopCap", Vector3(0.46, 0.06, 0.23), Vector3(0, 0.37, 0), mat_suit_dark)
	_add_box(bp, "BpBotCap", Vector3(0.46, 0.06, 0.23), Vector3(0, -0.37, 0), mat_gear)
	for vx in [-0.14, 0.14]:
		_add_cyl(bp, "OxygenValve", 0.038, 0.044, 0.10, Vector3(vx, 0.43, 0), mat_steel, 10)
	_add_box(bp, "VentGrille", Vector3(0.32, 0.18, 0.03), Vector3(0, -0.14, -0.14), mat_gear)
	var mat_led := StandardMaterial3D.new()
	mat_led.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_led.albedo_color = Color(0.25, 1.0, 0.45)
	_add_box(bp, "StatusLED", Vector3(0.10, 0.025, 0.02), Vector3(0, 0.22, -0.14), mat_led)
	# Shoulder harness straps looping over front shoulders
	for sx in [-0.22, 0.22]:
		_add_box(visuals_root, "HarnessStrap", Vector3(0.08, 0.44, 0.04), Vector3(sx, 0.88, 0.41), mat_gear)

	# ==========================================
	# 4. ARTICULATED LEGS WITH REINFORCED COMBAT BOOTS
	# ==========================================
	var left_leg := Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.24, 0.34, 0)
	visuals_root.add_child(left_leg)
	var right_leg := Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.24, 0.34, 0)
	visuals_root.add_child(right_leg)
	
	for leg_root in [left_leg, right_leg]:
		var leg_m := MeshInstance3D.new()
		leg_m.name = "Mesh"
		var lm := CapsuleMesh.new()
		lm.radius = 0.155
		lm.height = 0.48
		lm.radial_segments = 14
		leg_m.mesh = lm
		leg_m.material_override = mat_suit
		leg_root.add_child(leg_m)
		suit_meshes.append(leg_m)
		# Heavy tactical boot cuff, toe cap & treaded sole
		_add_cyl(leg_root, "BootCuff", 0.165, 0.168, 0.16, Vector3(0, -0.18, 0.01), mat_boot, 12)
		_add_box(leg_root, "BootToe", Vector3(0.25, 0.14, 0.34), Vector3(0, -0.25, 0.07), mat_boot)
		_add_box(leg_root, "BootSole", Vector3(0.27, 0.045, 0.37), Vector3(0, -0.32, 0.07), mat_steel)

	# ==========================================
	# 5. CLASS-SPECIFIC TACTICAL GEAR PER ENEMY TYPE
	# ==========================================
	var mat_olive := StandardMaterial3D.new()
	mat_olive.albedo_color = Color(0.18, 0.24, 0.15)
	mat_olive.roughness = 0.78
	
	match enemy_type:
		0: # RED_STANDARD: Tactical Assault Trooper (Combat Helmet + Chest Rig with AK Mag Pouches)
			var helm := _add_cyl(visuals_root, "CombatHelmet", 0.41, 0.46, 0.22, Vector3(0, 1.56, -0.02), mat_gear, 16)
			_add_box(helm, "NVGShroud", Vector3(0.11, 0.10, 0.06), Vector3(0, 0.02, 0.44), mat_steel)
			_add_box(visuals_root, "ChestRig", Vector3(0.54, 0.28, 0.12), Vector3(0, 0.84, 0.40), mat_gear)
			for i in range(3):
				_add_box(visuals_root, "AKPouch_%d" % i, Vector3(0.12, 0.21, 0.08), Vector3(-0.16 + float(i) * 0.16, 0.80, 0.47), mat_olive)
		1: # BLUE_SCOUT: Recon Scout (Radio Comm Antenna + Headset + Lightweight Chest Harness)
			_add_cyl(bp, "CommAntenna", 0.012, 0.018, 0.72, Vector3(0.20, 0.65, -0.04), mat_steel, 8)
			_add_box(visuals_root, "HeadsetBand", Vector3(0.88, 0.06, 0.10), Vector3(0, 1.48, 0.0), mat_gear)
			for ex in [-0.44, 0.44]:
				_add_cyl(visuals_root, "EarCup", 0.10, 0.10, 0.08, Vector3(ex, 1.24, 0.0), mat_gear, 10, Vector3(0, 0, 90))
			_add_box(visuals_root, "ScoutBandolier", Vector3(0.52, 0.12, 0.12), Vector3(0, 0.86, 0.41), mat_gear, Vector3(0, 0, -24.0))
		2: # YELLOW_HEAVY: Juggernaut Berserker (Armored Altyn Brow, Heavy Chest Plate & Pauldrons!)
			_add_box(visuals_root, "HeavyPlateFront", Vector3(0.56, 0.44, 0.14), Vector3(0, 0.84, 0.42), mat_steel)
			_add_box(visuals_root, "HeavyCollar", Vector3(0.58, 0.14, 0.56), Vector3(0, 1.06, 0.05), mat_gear)
			_add_box(visor_root, "AltynBrowGuard", Vector3(0.66, 0.11, 0.28), Vector3(0, 0.18, 0.02), mat_steel)
			_add_box(visor_root, "AltynChinGuard", Vector3(0.62, 0.09, 0.24), Vector3(0, -0.17, 0.02), mat_steel)
			for sx in [-1.0, 1.0]:
				_add_box(visuals_root, "HeavyPauldron", Vector3(0.22, 0.34, 0.42), Vector3(0.49 * sx, 1.02, 0.0), mat_steel, Vector3(0, 0, -18.0 * sx))
		3: # GREEN_SNIPER: Recon Marksman (Ghillie Hood, Shoulder Cape & Optical Rangefinder)
			_add_cyl(visuals_root, "BoonieBrim", 0.54, 0.58, 0.04, Vector3(0, 1.54, 0.0), mat_olive, 16)
			_add_cyl(visuals_root, "BoonieCrown", 0.40, 0.44, 0.20, Vector3(0, 1.64, 0.0), mat_olive, 16)
			_add_box(visuals_root, "GhillieCape", Vector3(0.86, 0.18, 0.58), Vector3(0, 1.08, -0.14), mat_olive, Vector3(12.0, 0, 0))
			# Side-mounted tactical rangefinder lens next to visor
			_add_box(visor_root, "RangefinderBody", Vector3(0.11, 0.11, 0.18), Vector3(0.35, 0.02, 0.02), mat_gear)
			var mat_rf := StandardMaterial3D.new()
			mat_rf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat_rf.albedo_color = Color(0.2, 1.0, 0.65)
			_add_cyl(visor_root, "RangefinderLens", 0.036, 0.036, 0.03, Vector3(0.35, 0.02, 0.12), mat_rf, 10, Vector3(90, 0, 0))

	return {
		"body": body,
		"backpack": bp,
		"left_leg": left_leg,
		"right_leg": right_leg,
		"suit_meshes": suit_meshes,
		"suit_material": mat_suit
	}

# Handbook 3D Inspector static factory
static func create(color: Color, enemy_type: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "CrewmatePreview"
	root.position = Vector3(0, -0.86, 0)
	
	var parts := populate_crewmate_visuals(root, color, enemy_type)
	if enemy_type < 0:
		return root
		
	var weapon_mount := Node3D.new()
	weapon_mount.position = Vector3(-0.52, 0.86, 0.24)
	root.add_child(weapon_mount)
	
	var mat_hand: Material = parts["suit_material"]
	var hand := MeshInstance3D.new()
	var hm := CapsuleMesh.new()
	hm.radius = 0.08
	hm.height = 0.22
	hand.mesh = hm
	hand.material_override = mat_hand
	hand.rotation.x = deg_to_rad(25.0)
	hand.position = Vector3(0.02, -0.06, -0.02)
	weapon_mount.add_child(hand)
	
	match enemy_type:
		0:
			var ak := AK47Model.create()
			ak.scale = Vector3(1.15, 1.15, 1.15)
			ak.rotation.y = PI
			ak.position = Vector3(0, 0.02, 0.05)
			weapon_mount.add_child(ak)
		1:
			var pst := PistolModel.create()
			pst.scale = Vector3(1.25, 1.25, 1.25)
			pst.rotation.y = PI
			pst.position = Vector3(0, 0.01, 0.02)
			weapon_mount.add_child(pst)
		2:
			var axe_root := Node3D.new()
			axe_root.rotation.x = deg_to_rad(65.0)
			weapon_mount.add_child(axe_root)
			axe_root.add_child(AxeModel.create())
		3:
			var snp := SniperModel.create()
			snp.scale = Vector3(1.05, 1.05, 1.05)
			weapon_mount.add_child(snp)
			
	return root
