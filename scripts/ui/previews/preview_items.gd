class_name PreviewItems
extends RefCounted

# High-Fidelity Procedural Player Gear, Consumables, Armor & Equipment Models
# Shared across Field Shop 3D Previews, Handbook Inspector & World Pickups!

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

static func _add_cyl(parent: Node3D, node_name: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, segs: int = 14, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
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

# 1. TACTICAL LIGHT PLATE CARRIER (JPC / 6B45 Style)
static func create_armor() -> Node3D:
	var root := Node3D.new()
	root.name = "TacticalPlateCarrier"
	
	var mat_cordura := StandardMaterial3D.new()
	mat_cordura.albedo_color = Color(0.13, 0.18, 0.26) # Navy/slate ballistic Cordura
	mat_cordura.roughness = 0.78
	
	var mat_cordura_dark := StandardMaterial3D.new()
	mat_cordura_dark.albedo_color = Color(0.08, 0.11, 0.17)
	mat_cordura_dark.roughness = 0.85
	
	var mat_plate := StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.20, 0.25, 0.34)
	mat_plate.metallic = 0.55
	mat_plate.roughness = 0.34
	
	var mat_buckle := StandardMaterial3D.new()
	mat_buckle.albedo_color = Color(0.07, 0.08, 0.09)
	mat_buckle.metallic = 0.45
	mat_buckle.roughness = 0.42
	
	var mat_patch := StandardMaterial3D.new()
	mat_patch.albedo_color = Color(0.76, 0.64, 0.34)
	mat_patch.roughness = 0.7
	
	# Front & Rear contoured ballistic plate bags
	_add_box(root, "FrontBag", Vector3(0.32, 0.38, 0.055), Vector3(0, 0.0, 0.082), mat_cordura)
	_add_box(root, "FrontPlateBevel", Vector3(0.26, 0.30, 0.028), Vector3(0, 0.015, 0.112), mat_plate)
	_add_box(root, "BackBag", Vector3(0.32, 0.38, 0.055), Vector3(0, 0.0, -0.082), mat_cordura)
	_add_box(root, "BackPlateBevel", Vector3(0.26, 0.30, 0.024), Vector3(0, 0.015, -0.110), mat_plate)
	# Skeletonized side cummerbund straps (3 horizontal bands per side)
	for sx in [-0.175, 0.175]:
		for cy in [-0.11, -0.05, 0.01]:
			_add_box(root, "CummerbundBand", Vector3(0.022, 0.028, 0.18), Vector3(sx, cy, 0.0), mat_cordura_dark)
	# Padded ergonomic shoulder straps + quick-release Duraflex buckles
	for sx in [-0.115, 0.115]:
		_add_box(root, "ShoulderStrap", Vector3(0.068, 0.036, 0.21), Vector3(sx, 0.205, 0.0), mat_cordura)
		_add_box(root, "ShoulderPad", Vector3(0.076, 0.022, 0.13), Vector3(sx, 0.222, 0.0), mat_cordura_dark)
		_add_box(root, "Buckle", Vector3(0.048, 0.038, 0.022), Vector3(sx, 0.165, 0.102), mat_buckle)
	# Horizontal MOLLE webbing rows on chest & back
	for my in [0.11, 0.06, 0.01]:
		_add_box(root, "MolleFront", Vector3(0.25, 0.014, 0.008), Vector3(0, my, 0.128), mat_cordura_dark)
		_add_box(root, "MolleBack", Vector3(0.25, 0.014, 0.008), Vector3(0, my, -0.124), mat_cordura_dark)
	# Velcro admin patch on upper chest + rear drag rescue handle
	_add_box(root, "AdminPatch", Vector3(0.11, 0.045, 0.008), Vector3(0, 0.115, 0.130), mat_patch)
	_add_box(root, "DragHandle", Vector3(0.12, 0.022, 0.024), Vector3(0, 0.155, -0.126), mat_buckle)
	# Triple rifle magazine pouches with bungee retention tabs
	for i in range(3):
		var px: float = -0.095 + float(i) * 0.095
		_add_box(root, "MagPouch_%d" % i, Vector3(0.074, 0.135, 0.052), Vector3(px, -0.105, 0.136), mat_cordura_dark)
		_add_box(root, "PouchFlap_%d" % i, Vector3(0.056, 0.016, 0.058), Vector3(px, -0.035, 0.136), mat_buckle)
	return root

# 2. FIELD DRESSING / STERILE BANDAGE (ИПП-1 / Combat Gauze)
static func create_bandage() -> Node3D:
	var root := Node3D.new()
	root.name = "CombatBandage"
	
	var mat_gauze := StandardMaterial3D.new()
	mat_gauze.albedo_color = Color(0.94, 0.93, 0.90)
	mat_gauze.roughness = 0.88
	
	var mat_gauze_inner := StandardMaterial3D.new()
	mat_gauze_inner.albedo_color = Color(0.84, 0.82, 0.78)
	mat_gauze_inner.roughness = 0.92
	
	var mat_core := StandardMaterial3D.new()
	mat_core.albedo_color = Color(0.58, 0.50, 0.40)
	mat_core.roughness = 0.92
	
	var mat_wrap := StandardMaterial3D.new()
	mat_wrap.albedo_color = Color(0.24, 0.30, 0.21) # Olive military wrapper band
	mat_wrap.roughness = 0.65
	
	var mat_cross := StandardMaterial3D.new()
	mat_cross.albedo_color = Color(0.88, 0.12, 0.12)
	mat_cross.roughness = 0.35
	
	# Rolled sterile gauze cylinder with layered spiral lip
	_add_cyl(root, "GauzeRoll", 0.115, 0.115, 0.165, Vector3.ZERO, mat_gauze, 24)
	_add_cyl(root, "GauzeRing", 0.088, 0.088, 0.168, Vector3.ZERO, mat_gauze_inner, 20)
	_add_cyl(root, "CardboardCore", 0.036, 0.036, 0.171, Vector3.ZERO, mat_core, 16)
	# Loose folded bandage tail unrolling slightly from side
	_add_box(root, "BandageTail", Vector3(0.014, 0.160, 0.095), Vector3(0.112, 0.0, 0.045), mat_gauze, Vector3(0, -14.0, 0))
	# Olive sterile paper belly band around middle + metal pressure clip
	_add_cyl(root, "OliveBand", 0.119, 0.119, 0.072, Vector3.ZERO, mat_wrap, 24)
	# Crisp embossed white badge + Red Cross on front
	_add_box(root, "CrossPlate", Vector3(0.085, 0.064, 0.012), Vector3(0, 0, 0.118), mat_gauze)
	_add_box(root, "CrossV", Vector3(0.018, 0.052, 0.016), Vector3(0, 0, 0.121), mat_cross)
	_add_box(root, "CrossH", Vector3(0.052, 0.018, 0.016), Vector3(0, 0, 0.121), mat_cross)
	return root

# 3. MILITARY FIELD MEDKIT (Hard-Case Trauma / Salewa Style)
static func create_medkit() -> Node3D:
	var root := Node3D.new()
	root.name = "FieldMedkit"
	
	var mat_case := StandardMaterial3D.new()
	mat_case.albedo_color = Color(0.92, 0.93, 0.94) # Impact-resistant medical ABS
	mat_case.roughness = 0.36
	mat_case.metallic = 0.05
	
	var mat_trim := StandardMaterial3D.new()
	mat_trim.albedo_color = Color(0.76, 0.11, 0.11) # Trauma crimson accents
	mat_trim.roughness = 0.42
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.18, 0.20, 0.22)
	mat_steel.metallic = 0.88
	mat_steel.roughness = 0.28
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.08, 0.09, 0.10)
	mat_rubber.roughness = 0.88
	
	var mat_cross := StandardMaterial3D.new()
	mat_cross.albedo_color = Color(0.92, 0.12, 0.12)
	mat_cross.emission_enabled = true
	mat_cross.emission = Color(0.85, 0.10, 0.10)
	mat_cross.emission_energy_multiplier = 0.35
	
	# Main waterproof hard shell + waterproof rubber perimeter gasket seam
	_add_box(root, "CaseMain", Vector3(0.34, 0.24, 0.135), Vector3.ZERO, mat_case)
	_add_box(root, "CaseGasket", Vector3(0.348, 0.248, 0.018), Vector3.ZERO, mat_rubber)
	# Corner shock bumpers
	for sx in [-0.155, 0.155]:
		for sy in [-0.105, 0.105]:
			_add_box(root, "CornerBumper", Vector3(0.045, 0.045, 0.144), Vector3(sx, sy, 0), mat_rubber)
	# Structural reinforcement ribs on front & back
	for z_dir in [-1.0, 1.0]:
		for rx in [-0.11, 0.11]:
			_add_box(root, "Rib", Vector3(0.018, 0.19, 0.010), Vector3(rx, 0, 0.070 * z_dir), mat_case)
		# Recessed crimson emblem plate + crisp 3D medical cross
		_add_box(root, "BadgeBg", Vector3(0.14, 0.14, 0.008), Vector3(0, 0, 0.070 * z_dir), mat_trim)
		_add_box(root, "BadgeInner", Vector3(0.124, 0.124, 0.010), Vector3(0, 0, 0.071 * z_dir), mat_case)
		_add_box(root, "CrossV", Vector3(0.032, 0.096, 0.014), Vector3(0, 0, 0.073 * z_dir), mat_cross)
		_add_box(root, "CrossH", Vector3(0.096, 0.032, 0.014), Vector3(0, 0, 0.073 * z_dir), mat_cross)
	# Twin steel flip latches on top
	for lx in [-0.10, 0.10]:
		_add_box(root, "Latch", Vector3(0.036, 0.026, 0.148), Vector3(lx, 0.124, 0), mat_steel)
		_add_box(root, "LatchClip", Vector3(0.028, 0.016, 0.154), Vector3(lx, 0.116, 0), mat_trim)
	# Ergonomic hinged carry handle
	_add_box(root, "HandlePostL", Vector3(0.016, 0.046, 0.020), Vector3(-0.048, 0.142, 0), mat_steel)
	_add_box(root, "HandlePostR", Vector3(0.016, 0.046, 0.020), Vector3(0.048, 0.142, 0), mat_steel)
	_add_cyl(root, "HandleGrip", 0.013, 0.013, 0.112, Vector3(0, 0.165, 0), mat_rubber, 12, Vector3(0, 0, 90))
	return root

# 4. VODKA "ЧЕКУНЕЦ 67" (Authentic Glass Russian Hip-Flask Bottle)
static func create_vodka() -> Node3D:
	var root := Node3D.new()
	root.name = "VodkaChekunets67"
	
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.84, 0.93, 0.96, 0.52)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.06
	mat_glass.metallic = 0.18
	mat_glass.metallic_specular = 0.95
	
	var mat_glass_thick := StandardMaterial3D.new()
	mat_glass_thick.albedo_color = Color(0.76, 0.88, 0.92, 0.72)
	mat_glass_thick.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass_thick.roughness = 0.08
	mat_glass_thick.metallic = 0.25
	
	var mat_liquid := StandardMaterial3D.new()
	mat_liquid.albedo_color = Color(0.92, 0.97, 1.0, 0.42)
	mat_liquid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_liquid.roughness = 0.04
	
	var mat_cap := StandardMaterial3D.new()
	mat_cap.albedo_color = Color(0.82, 0.12, 0.12) # Classic red aluminum twist cap
	mat_cap.metallic = 0.78
	mat_cap.roughness = 0.26
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.86, 0.72, 0.30)
	mat_gold.metallic = 0.85
	mat_gold.roughness = 0.25
	
	var mat_label := StandardMaterial3D.new()
	mat_label.albedo_color = Color(0.96, 0.94, 0.88)
	mat_label.roughness = 0.78
	
	# Rounded hip-flask glass body (center box + rounded vertical side cylinders!)
	_add_box(root, "FlaskCenter", Vector3(0.115, 0.225, 0.086), Vector3.ZERO, mat_glass)
	for sx in [-0.057, 0.057]:
		_add_cyl(root, "FlaskSide", 0.043, 0.043, 0.225, Vector3(sx, 0.0, 0.0), mat_glass, 14)
	# Heavy thick glass punt bottom base
	_add_box(root, "BaseCenter", Vector3(0.115, 0.024, 0.088), Vector3(0, -0.112, 0), mat_glass_thick)
	for sx in [-0.057, 0.057]:
		_add_cyl(root, "BaseSide", 0.044, 0.044, 0.024, Vector3(sx, -0.112, 0), mat_glass_thick, 14)
	# Clear vodka liquid filled to ~84% inside
	_add_box(root, "LiquidCenter", Vector3(0.104, 0.175, 0.072), Vector3(0, -0.018, 0), mat_liquid)
	for sx in [-0.052, 0.052]:
		_add_cyl(root, "LiquidSide", 0.036, 0.036, 0.175, Vector3(sx, -0.018, 0), mat_liquid, 12)
	# Tapered glass shoulders, collar & neck
	var sh := _add_cyl(root, "Shoulder", 0.030, 0.072, 0.058, Vector3(0, 0.140, 0), mat_glass, 16)
	sh.scale = Vector3(1.25, 1.0, 0.65)
	_add_cyl(root, "Neck", 0.028, 0.030, 0.068, Vector3(0, 0.195, 0), mat_glass, 16)
	_add_cyl(root, "GlassLip", 0.032, 0.032, 0.010, Vector3(0, 0.212, 0), mat_glass_thick, 16)
	# Red aluminum screw cap + gold tamper-evident skirt ring
	_add_cyl(root, "CapRing", 0.033, 0.033, 0.010, Vector3(0, 0.226, 0), mat_gold, 16)
	_add_cyl(root, "CapTop", 0.032, 0.032, 0.034, Vector3(0, 0.246, 0), mat_cap, 16)
	# Front vintage paper label + gold foil border + crisp high-res typography
	_add_box(root, "LabelBorder", Vector3(0.132, 0.156, 0.003), Vector3(0, -0.008, 0.044), mat_gold)
	_add_box(root, "LabelPaper", Vector3(0.122, 0.146, 0.004), Vector3(0, -0.008, 0.045), mat_label)
	var lbl := Label3D.new()
	lbl.text = "ЧЕКУНЕЦ\n67\nВОДКА 40%"
	lbl.font_size = 72
	lbl.pixel_size = 0.00046
	lbl.modulate = Color(0.76, 0.10, 0.10)
	lbl.outline_modulate = Color(0.12, 0.08, 0.05)
	lbl.outline_size = 8
	lbl.position = Vector3(0, -0.008, 0.048)
	root.add_child(lbl)
	return root

# 5. HEAVY JUGGERNAUT ARMOR VEST (6B43 Zabralo / Fort Defender Style)
static func create_heavy_armor() -> Node3D:
	var root := Node3D.new()
	root.name = "HeavyJuggernautArmor"
	
	var mat_vest := StandardMaterial3D.new()
	mat_vest.albedo_color = Color(0.14, 0.16, 0.13) # Russian tactical olive/charcoal Cordura
	mat_vest.roughness = 0.78
	
	var mat_plate := StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.17, 0.19, 0.21) # Heavy titanium/ceramic strike plates
	mat_plate.metallic = 0.80
	mat_plate.roughness = 0.26
	
	var mat_pauldron := StandardMaterial3D.new()
	mat_pauldron.albedo_color = Color(0.15, 0.17, 0.19)
	mat_pauldron.metallic = 0.72
	mat_pauldron.roughness = 0.32
	
	var mat_strap := StandardMaterial3D.new()
	mat_strap.albedo_color = Color(0.08, 0.09, 0.09)
	mat_strap.roughness = 0.88
	
	var mat_bolt := StandardMaterial3D.new()
	mat_bolt.albedo_color = Color(0.55, 0.58, 0.62)
	mat_bolt.metallic = 0.92
	mat_bolt.roughness = 0.22
	
	# Heavy reinforced torso shell
	_add_box(root, "TorsoCore", Vector3(0.44, 0.46, 0.22), Vector3.ZERO, mat_vest)
	# Layered beveled front & back Class-6 titanium strike plates with bolts
	for z_dir in [1.0, -1.0]:
		_add_box(root, "StrikePlateMain", Vector3(0.32, 0.34, 0.045), Vector3(0, 0.02, 0.118 * z_dir), mat_plate)
		_add_box(root, "StrikePlateUpper", Vector3(0.24, 0.10, 0.042), Vector3(0, 0.16, 0.116 * z_dir), mat_plate)
		for bx in [-0.13, 0.13]:
			for by in [-0.11, 0.14]:
				_add_cyl(root, "PlateBolt", 0.008, 0.008, 0.012, Vector3(bx, by, 0.142 * z_dir), mat_bolt, 6, Vector3(90, 0, 0))
	# Wrap-around armored ballistic neck collar (left, right, rear, front throat flap)
	_add_box(root, "CollarRear", Vector3(0.28, 0.11, 0.045), Vector3(0, 0.275, -0.095), mat_vest)
	_add_box(root, "CollarL", Vector3(0.045, 0.11, 0.21), Vector3(-0.135, 0.275, 0.0), mat_vest)
	_add_box(root, "CollarR", Vector3(0.045, 0.11, 0.21), Vector3(0.135, 0.275, 0.0), mat_vest)
	_add_box(root, "ThroatGuard", Vector3(0.22, 0.085, 0.042), Vector3(0, 0.255, 0.105), mat_plate, Vector3(-12.0, 0, 0))
	# Dual articulated layered shoulder pauldrons with steel rim strips
	for sx in [-1.0, 1.0]:
		var p_root := Node3D.new()
		p_root.position = Vector3(0.27 * sx, 0.16, 0.0)
		p_root.rotation_degrees = Vector3(0, 0, -16.0 * sx)
		root.add_child(p_root)
		_add_box(p_root, "PauldronTop", Vector3(0.14, 0.065, 0.22), Vector3(0, 0.055, 0), mat_pauldron)
		_add_box(p_root, "PauldronLow", Vector3(0.12, 0.125, 0.20), Vector3(0.02 * sx, -0.045, 0), mat_vest)
		_add_box(p_root, "PauldronTrim", Vector3(0.15, 0.016, 0.23), Vector3(0, 0.015, 0), mat_strap)
	# Segmented armored groin flap
	_add_box(root, "GroinFlapUpper", Vector3(0.24, 0.11, 0.042), Vector3(0, -0.285, 0.095), mat_vest, Vector3(6.0, 0, 0))
	_add_box(root, "GroinFlapPlate", Vector3(0.19, 0.09, 0.026), Vector3(0, -0.355, 0.102), mat_plate, Vector3(8.0, 0, 0))
	# 4 heavy magazine pouches + tactical radio + rear hydration pack
	for i in range(4):
		_add_box(root, "HeavyPouch_%d" % i, Vector3(0.064, 0.13, 0.056), Vector3(-0.108 + float(i) * 0.072, -0.12, 0.158), mat_strap)
	_add_box(root, "RadioPack", Vector3(0.065, 0.13, 0.045), Vector3(-0.18, 0.08, 0.135), mat_strap)
	_add_cyl(root, "RadioAntenna", 0.004, 0.005, 0.20, Vector3(-0.19, 0.24, 0.135), mat_strap, 6)
	# Crisp high-res stencil
	var lbl := Label3D.new()
	lbl.text = "6Б43 ЗАБРАЛО\n150 БРОНЯ"
	lbl.font_size = 56
	lbl.pixel_size = 0.00056
	lbl.modulate = Color(0.92, 0.80, 0.28)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 8
	lbl.position = Vector3(0, 0.065, 0.144)
	root.add_child(lbl)
	return root

# 6. COMPOSITE CERAMIC ARMOR PLATE (Shooter's Cut SAPI / Granit BR-5)
static func create_armor_plate() -> Node3D:
	var root := Node3D.new()
	root.name = "CeramicArmorPlate"
	
	var mat_ceramic := StandardMaterial3D.new()
	mat_ceramic.albedo_color = Color(0.18, 0.20, 0.23) # Silicon-carbide composite face
	mat_ceramic.metallic = 0.72
	mat_ceramic.roughness = 0.28
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.07, 0.075, 0.085) # EPDM shock-absorbing perimeter bumper
	mat_rubber.roughness = 0.88
	
	var mat_kevlar := StandardMaterial3D.new()
	mat_kevlar.albedo_color = Color(0.15, 0.14, 0.11) # Aramid spall-liner backing
	mat_kevlar.roughness = 0.82
	
	var mat_stripe := StandardMaterial3D.new()
	mat_stripe.albedo_color = Color(0.84, 0.68, 0.22)
	mat_stripe.roughness = 0.45
	
	# Shooter's cut multi-segment plate silhouette (wide lower + chamfered upper chest!)
	_add_box(root, "PlateLower", Vector3(0.28, 0.24, 0.032), Vector3(0, -0.055, 0), mat_ceramic)
	_add_box(root, "PlateUpper", Vector3(0.17, 0.11, 0.032), Vector3(0, 0.115, 0), mat_ceramic)
	for sx in [-1.0, 1.0]:
		_add_box(root, "PlateChamfer", Vector3(0.085, 0.125, 0.031), Vector3(0.098 * sx, 0.085, 0), mat_ceramic, Vector3(0, 0, 36.0 * sx))
	# Shock-absorbing rubber perimeter rim + aramid rear spall backing
	_add_box(root, "RubberRimLow", Vector3(0.296, 0.252, 0.022), Vector3(0, -0.055, -0.007), mat_rubber)
	_add_box(root, "RubberRimUp", Vector3(0.184, 0.124, 0.022), Vector3(0, 0.115, -0.007), mat_rubber)
	_add_box(root, "AramidBack", Vector3(0.26, 0.22, 0.010), Vector3(0, -0.055, -0.018), mat_kevlar)
	# Yellow certification stripe + crisp high-res stencil
	_add_box(root, "CertStripe", Vector3(0.25, 0.012, 0.004), Vector3(0, -0.145, 0.017), mat_stripe)
	var lbl := Label3D.new()
	lbl.text = "БРОНЕПЛИТА\n+30 БРОНЯ\nBR-5 TITAN"
	lbl.font_size = 58
	lbl.pixel_size = 0.00055
	lbl.modulate = Color(0.90, 0.90, 0.88)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 8
	lbl.position = Vector3(0, -0.02, 0.019)
	root.add_child(lbl)
	return root

# 7. TACTICAL INTEL / SPAWN BEACON (Handbook Preview)
static func create_beacon() -> Node3D:
	var root := Node3D.new()
	root.name = "IntelBeaconPreview"
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.16, 0.18, 0.21)
	mat_dark.metallic = 0.86
	mat_dark.roughness = 0.34
	
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.56, 0.60, 0.64)
	mat_steel.metallic = 0.92
	mat_steel.roughness = 0.22
	
	var mat_cyan := StandardMaterial3D.new()
	mat_cyan.albedo_color = Color(0.2, 0.85, 1.0)
	mat_cyan.emission_enabled = true
	mat_cyan.emission = Color(0.2, 0.85, 1.0)
	mat_cyan.emission_energy_multiplier = 2.2
	
	var mat_orange := StandardMaterial3D.new()
	mat_orange.albedo_color = Color(1.0, 0.5, 0.1)
	mat_orange.emission_enabled = true
	mat_orange.emission = Color(1.0, 0.5, 0.1)
	mat_orange.emission_energy_multiplier = 2.6
	
	_add_cyl(root, "Pedestal", 0.42, 0.48, 0.12, Vector3(0, -0.2, 0), mat_dark, 16)
	_add_cyl(root, "Console", 0.34, 0.40, 0.28, Vector3(0, 0.0, 0), mat_steel, 16)
	_add_cyl(root, "Mast", 0.055, 0.075, 0.86, Vector3(0, 0.55, 0), mat_dark, 12)
	for i in range(3):
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.16 + float(i) * 0.07
		rm.outer_radius = 0.19 + float(i) * 0.07
		ring.mesh = rm
		ring.material_override = mat_cyan
		ring.position = Vector3(0, 0.32 + float(i) * 0.22, 0)
		root.add_child(ring)
	_add_cyl(root, "Dish", 0.24, 0.04, 0.12, Vector3(0, 0.96, 0), mat_steel, 16, Vector3(25, 30, 0))
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.055
	bm.height = 0.11
	bulb.mesh = bm
	bulb.material_override = mat_orange
	bulb.position = Vector3(0, 1.08, 0)
	root.add_child(bulb)
	return root
