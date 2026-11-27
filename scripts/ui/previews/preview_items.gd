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

# ==========================================
# 8. WEAPON AMMUNITION 3D MODELS (FIELD SHOP PREVIEWS)
# ==========================================

static func _build_762x39_cartridge(mat_case: Material, mat_copper: Material, mat_lacquer: Material, mat_primer: Material) -> Node3D:
	var c := Node3D.new()
	# Scale ~2.8x life-size so cartridge details (extractor rim, bottleneck shoulder, red sealant, spitzer tip) are razor-sharp in viewport!
	_add_cyl(c, "Rim", 0.0160, 0.0160, 0.0045, Vector3(0, -0.072, 0), mat_case, 14)
	_add_cyl(c, "Primer", 0.0075, 0.0075, 0.0052, Vector3(0, -0.0722, 0), mat_primer, 10)
	_add_cyl(c, "Groove", 0.0132, 0.0132, 0.0045, Vector3(0, -0.0675, 0), mat_case, 12)
	_add_cyl(c, "CaseBody", 0.0145, 0.0160, 0.078, Vector3(0, -0.026, 0), mat_case, 14)
	_add_cyl(c, "Shoulder", 0.0112, 0.0145, 0.014, Vector3(0, 0.020, 0), mat_case, 14)
	_add_cyl(c, "Neck", 0.0110, 0.0112, 0.014, Vector3(0, 0.034, 0), mat_case, 14)
	_add_cyl(c, "LacquerSeal", 0.0113, 0.0113, 0.004, Vector3(0, 0.041, 0), mat_lacquer, 14)
	_add_cyl(c, "BulletBase", 0.0102, 0.0108, 0.022, Vector3(0, 0.052, 0), mat_copper, 14)
	_add_cyl(c, "BulletOgive", 0.0018, 0.0102, 0.028, Vector3(0, 0.077, 0), mat_copper, 14)
	return c

# 8A. AK-47 AMMO PACK (7.62x39mm Carton + Detailed Bottleneck Rifle Cartridges — Dynamic per ammo_mode!)
static func create_ammo_ak(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "AmmoAK47_762x39_" + ammo_mode

	var mat_box := StandardMaterial3D.new()
	mat_box.roughness = 0.82
	var mat_box_dark := StandardMaterial3D.new()
	mat_box_dark.roughness = 0.88
	var mat_label := StandardMaterial3D.new()
	mat_label.albedo_color = Color(0.86, 0.80, 0.66)
	mat_label.roughness = 0.78
	var mat_case := StandardMaterial3D.new()
	mat_case.albedo_color = Color(0.76, 0.62, 0.28)
	mat_case.metallic = 0.88
	mat_case.roughness = 0.22
	var mat_copper := StandardMaterial3D.new()
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.20
	var mat_lacquer := StandardMaterial3D.new()
	mat_lacquer.roughness = 0.32
	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.88, 0.76, 0.42)
	mat_primer.metallic = 0.92
	mat_primer.roughness = 0.18

	var box_txt: String = "7.62×39 ПС\n30 ПАТРОНОВ\nАК-47"
	match ammo_mode:
		"ap":
			mat_box.albedo_color = Color(0.14, 0.15, 0.17)
			mat_box_dark.albedo_color = Color(0.08, 0.09, 0.10)
			mat_case.albedo_color = Color(0.28, 0.31, 0.26) # Dark lacquered steel AP case
			mat_copper.albedo_color = Color(0.12, 0.13, 0.15) # Blackened hardened AP bullet!
			mat_lacquer.albedo_color = Color(0.92, 0.12, 0.10) # Red AP band
			box_txt = "7.62×39 БП\nБРОНЕБОЙНЫЕ\n30 ПАТРОНОВ"
		"hp":
			mat_box.albedo_color = Color(0.42, 0.14, 0.13)
			mat_box_dark.albedo_color = Color(0.26, 0.08, 0.08)
			mat_copper.albedo_color = Color(0.84, 0.86, 0.90) # Bright silver-nickel HP bullet
			mat_lacquer.albedo_color = Color(0.88, 0.72, 0.22)
			box_txt = "7.62×39 HP\nЭКСПАНСИВНЫЕ\n30 ПАТРОНОВ"
		"subsonic":
			mat_box.albedo_color = Color(0.14, 0.26, 0.18)
			mat_box_dark.albedo_color = Color(0.09, 0.18, 0.12)
			mat_case.albedo_color = Color(0.32, 0.36, 0.28)
			mat_copper.albedo_color = Color(0.16, 0.56, 0.22) # Soviet US green-black subsonic tip!
			mat_lacquer.albedo_color = Color(0.06, 0.07, 0.08)
			box_txt = "7.62×39 УС\nДОЗВУКОВЫЕ\n30 ПАТРОНОВ"
		_:
			mat_box.albedo_color = Color(0.36, 0.33, 0.24)
			mat_box_dark.albedo_color = Color(0.24, 0.22, 0.16)
			mat_copper.albedo_color = Color(0.84, 0.44, 0.22)
			mat_lacquer.albedo_color = Color(0.82, 0.12, 0.12)

	# Military 30-round cardboard ammo box with open top flap
	_add_box(root, "AmmoBox", Vector3(0.21, 0.155, 0.115), Vector3(-0.04, -0.02, -0.02), mat_box)
	_add_box(root, "BoxInner", Vector3(0.195, 0.02, 0.10), Vector3(-0.04, 0.052, -0.02), mat_box_dark)
	_add_box(root, "OpenFlap", Vector3(0.208, 0.008, 0.11), Vector3(-0.04, 0.095, -0.095), mat_box, Vector3(-52.0, 0, 0))
	_add_box(root, "BoxLabel", Vector3(0.175, 0.105, 0.004), Vector3(-0.04, -0.02, 0.039), mat_label)

	var lbl := Label3D.new()
	lbl.text = box_txt
	lbl.font_size = 50
	lbl.pixel_size = 0.00044
	lbl.modulate = Color(0.16, 0.14, 0.11)
	lbl.outline_modulate = Color(0.86, 0.80, 0.66)
	lbl.outline_size = 4
	lbl.position = Vector3(-0.04, -0.02, 0.043)
	root.add_child(lbl)

	# Row of cartridges peeking out of the open top of the box
	for i in range(4):
		var r_top := _build_762x39_cartridge(mat_case, mat_copper, mat_lacquer, mat_primer)
		r_top.position = Vector3(-0.105 + float(i) * 0.044, 0.042, -0.02)
		root.add_child(r_top)

	# 3 Hero 7.62x39 cartridges displayed prominently in front & to the right
	var c1 := _build_762x39_cartridge(mat_case, mat_copper, mat_lacquer, mat_primer)
	c1.position = Vector3(0.11, -0.022, 0.02)
	root.add_child(c1)

	var c2 := _build_762x39_cartridge(mat_case, mat_copper, mat_lacquer, mat_primer)
	c2.position = Vector3(0.148, -0.022, -0.015)
	c2.rotation_degrees = Vector3(0, -18.0, -7.0)
	root.add_child(c2)

	var c3 := _build_762x39_cartridge(mat_case, mat_copper, mat_lacquer, mat_primer)
	c3.position = Vector3(0.03, -0.082, 0.082)
	c3.rotation_degrees = Vector3(88.0, 58.0, 0.0)
	root.add_child(c3)

	return root

# 8B. SHOTGUN 12-GAUGE SHELLS (Картечь / AP-20 Slug / Dragon's Breath / Флешетта)
static func _build_12ga_shell(mat_hull: Material, mat_brass: Material, mat_primer: Material, mat_crimp: Material, shell_txt: String = "12 GA\n8.5 ММ", show_slug_tip: bool = false) -> Node3D:
	var s := Node3D.new()
	_add_cyl(s, "ExtractorRim", 0.0355, 0.0355, 0.007, Vector3(0, -0.095, 0), mat_brass, 18)
	_add_cyl(s, "Primer", 0.012, 0.012, 0.008, Vector3(0, -0.0955, 0), mat_primer, 12)
	_add_cyl(s, "BrassHead", 0.0325, 0.0325, 0.056, Vector3(0, -0.064, 0), mat_brass, 18)
	_add_cyl(s, "PlasticHull", 0.0318, 0.0318, 0.135, Vector3(0, 0.031, 0), mat_hull, 18)
	_add_cyl(s, "TopLip", 0.0318, 0.0285, 0.008, Vector3(0, 0.100, 0), mat_hull, 18)
	_add_cyl(s, "StarCrimp", 0.0275, 0.0275, 0.006, Vector3(0, 0.099, 0), mat_crimp, 6)
	if show_slug_tip:
		_add_cyl(s, "SlugNose", 0.014, 0.024, 0.022, Vector3(0, 0.106, 0), mat_primer, 14)

	var lbl := Label3D.new()
	lbl.text = shell_txt
	lbl.font_size = 44
	lbl.pixel_size = 0.00040
	lbl.modulate = Color(0.96, 0.88, 0.50)
	lbl.outline_modulate = Color(0.10, 0.04, 0.04)
	lbl.outline_size = 5
	lbl.position = Vector3(0, 0.032, 0.0325)
	s.add_child(lbl)
	return s

static func create_ammo_shotgun(ammo_mode: String = "buck") -> Node3D:
	var root := Node3D.new()
	root.name = "AmmoShotgun_12Gauge_" + ammo_mode

	var mat_hull := StandardMaterial3D.new()
	mat_hull.roughness = 0.34
	mat_hull.metallic = 0.08

	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.28)
	mat_brass.metallic = 0.92
	mat_brass.roughness = 0.18

	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.86, 0.88, 0.90)
	mat_primer.metallic = 0.94
	mat_primer.roughness = 0.16

	var mat_crimp := StandardMaterial3D.new()
	mat_crimp.roughness = 0.55

	var shell_txt: String = "12 GA\n8.5 ММ"
	var show_slug: bool = false
	match ammo_mode:
		"slug":
			mat_hull.albedo_color = Color(0.11, 0.12, 0.14) # Tactical black AP-20 Slug hull
			mat_crimp.albedo_color = Color(0.76, 0.78, 0.82)
			mat_crimp.metallic = 0.85
			shell_txt = "12 GA\nAP-20"
			show_slug = true
		"dragons_breath":
			mat_hull.albedo_color = Color(0.96, 0.38, 0.06) # Blazing magnesium orange hull
			mat_crimp.albedo_color = Color(1.0, 0.68, 0.12)
			mat_crimp.emission_enabled = true
			mat_crimp.emission = Color(1.0, 0.48, 0.08)
			mat_crimp.emission_energy_multiplier = 0.85
			shell_txt = "12 GA\nДРАКОН"
		"flechette", "ap":
			mat_hull.albedo_color = Color(0.16, 0.32, 0.56) # Steel-blue flechette hull
			mat_brass.albedo_color = Color(0.76, 0.79, 0.84) # Nickel-plated head
			mat_crimp.albedo_color = Color(0.68, 0.72, 0.78)
			mat_crimp.metallic = 0.88
			shell_txt = "12 GA\nИГЛЫ AP"
		_:
			mat_hull.albedo_color = Color(0.82, 0.11, 0.11) # Classic crimson buckshot hull
			mat_crimp.albedo_color = Color(0.52, 0.06, 0.06)

	var s1 := _build_12ga_shell(mat_hull, mat_brass, mat_primer, mat_crimp, shell_txt, show_slug)
	s1.position = Vector3(-0.025, 0.005, 0.0)
	root.add_child(s1)

	var s2 := _build_12ga_shell(mat_hull, mat_brass, mat_primer, mat_crimp, shell_txt, show_slug)
	s2.position = Vector3(0.055, 0.005, -0.035)
	s2.rotation_degrees = Vector3(0, -24.0, -8.0)
	root.add_child(s2)

	var s3 := _build_12ga_shell(mat_hull, mat_brass, mat_primer, mat_crimp, shell_txt, show_slug)
	s3.position = Vector3(0.015, -0.064, 0.068)
	s3.rotation_degrees = Vector3(76.0, 52.0, 12.0)
	root.add_child(s3)

	return root

# 8C. PISTOL 9x19mm PARABELLUM AMMO TRAY & CARTRIDGES
static func _build_9x19_cartridge(mat_brass: Material, mat_copper: Material, mat_primer: Material) -> Node3D:
	var c := Node3D.new()
	_add_cyl(c, "Rim", 0.0165, 0.0165, 0.0045, Vector3(0, -0.044, 0), mat_brass, 14)
	_add_cyl(c, "Primer", 0.0080, 0.0080, 0.0050, Vector3(0, -0.0443, 0), mat_primer, 10)
	_add_cyl(c, "Groove", 0.0142, 0.0142, 0.0040, Vector3(0, -0.040, 0), mat_brass, 12)
	_add_cyl(c, "Case", 0.0162, 0.0165, 0.056, Vector3(0, -0.010, 0), mat_brass, 14)
	_add_cyl(c, "BulletCyl", 0.0150, 0.0156, 0.018, Vector3(0, 0.026, 0), mat_copper, 14)
	var tip := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.0150
	sm.height = 0.032
	sm.radial_segments = 14
	sm.rings = 8
	tip.mesh = sm
	tip.material_override = mat_copper
	tip.position = Vector3(0, 0.035, 0)
	c.add_child(tip)
	return c

static func create_ammo_pistol(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "AmmoPistol_9x19_" + ammo_mode

	var mat_box := StandardMaterial3D.new()
	mat_box.roughness = 0.55
	var mat_tray := StandardMaterial3D.new()
	mat_tray.albedo_color = Color(0.08, 0.09, 0.10)
	mat_tray.roughness = 0.75
	var mat_gold_trim := StandardMaterial3D.new()
	mat_gold_trim.metallic = 0.85
	mat_gold_trim.roughness = 0.25
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.90, 0.74, 0.30)
	mat_brass.metallic = 0.92
	mat_brass.roughness = 0.18
	var mat_copper := StandardMaterial3D.new()
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.20
	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.86, 0.88, 0.90)
	mat_primer.metallic = 0.94
	mat_primer.roughness = 0.16

	var lbl_txt: String = "9×19 PARABELLUM\n17 ПАТРОНОВ"
	match ammo_mode:
		"ap":
			mat_box.albedo_color = Color(0.10, 0.11, 0.13)
			mat_gold_trim.albedo_color = Color(0.86, 0.16, 0.14)
			mat_brass.albedo_color = Color(0.55, 0.57, 0.60) # Steel-cased 7N31
			mat_copper.albedo_color = Color(0.12, 0.13, 0.16) # Blackened AP penetrator nose
			lbl_txt = "9×19 7Н31 AP\nБРОНЕБОЙНЫЕ"
		"hp":
			mat_box.albedo_color = Color(0.32, 0.09, 0.11)
			mat_gold_trim.albedo_color = Color(0.88, 0.90, 0.94)
			mat_copper.albedo_color = Color(0.88, 0.90, 0.94) # Gleaming silver RIP hollow-point
			lbl_txt = "9×19 RIP HP\nЭКСПАНСИВНЫЕ"
		_:
			mat_box.albedo_color = Color(0.11, 0.16, 0.24)
			mat_gold_trim.albedo_color = Color(0.84, 0.70, 0.30)
			mat_copper.albedo_color = Color(0.85, 0.46, 0.24)

	_add_box(root, "BoxLower", Vector3(0.19, 0.085, 0.115), Vector3(-0.03, -0.035, -0.015), mat_box)
	_add_box(root, "GoldStripe", Vector3(0.192, 0.010, 0.117), Vector3(-0.03, -0.002, -0.015), mat_gold_trim)
	_add_box(root, "PlasticTray", Vector3(0.176, 0.025, 0.102), Vector3(-0.03, 0.012, -0.015), mat_tray)

	var lbl := Label3D.new()
	lbl.text = lbl_txt
	lbl.font_size = 46
	lbl.pixel_size = 0.00042
	lbl.modulate = Color(0.94, 0.84, 0.48)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 5
	lbl.position = Vector3(-0.03, -0.038, 0.044)
	root.add_child(lbl)

	for rx in range(4):
		for rz in range(2):
			var r_in := _build_9x19_cartridge(mat_brass, mat_copper, mat_primer)
			r_in.position = Vector3(-0.093 + float(rx) * 0.042, 0.034, -0.036 + float(rz) * 0.042)
			root.add_child(r_in)

	var p1 := _build_9x19_cartridge(mat_brass, mat_copper, mat_primer)
	p1.position = Vector3(0.105, -0.032, 0.02)
	root.add_child(p1)

	var p2 := _build_9x19_cartridge(mat_brass, mat_copper, mat_primer)
	p2.position = Vector3(0.142, -0.032, -0.015)
	p2.rotation_degrees = Vector3(0, -15.0, -8.0)
	root.add_child(p2)

	var p3 := _build_9x19_cartridge(mat_brass, mat_copper, mat_primer)
	p3.position = Vector3(0.035, -0.062, 0.074)
	p3.rotation_degrees = Vector3(88.0, 62.0, 0.0)
	root.add_child(p3)

	return root

# 8D. RPG-7 STANDALONE ROCKET WARHEAD (PG-7V / PG-7VR Tandem / TBG-7V Thermobaric!)
static func create_ammo_rpg(ammo_mode: String = "standard") -> Node3D:
	var root := Node3D.new()
	root.name = "AmmoRPG_" + ammo_mode

	const RPGModelScript = preload("res://scripts/weapons/models/rpg_model.gd")
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(14.0, 52.0, -8.0)
	root.add_child(pivot)

	var mode_clean: String = ammo_mode if ammo_mode in ["standard", "tandem", "thermobaric"] else "standard"
	var rocket: Node3D = RPGModelScript.create_warhead_by_type(mode_clean, true)
	rocket.position = Vector3(0.0, 0.0, -0.24)
	pivot.add_child(rocket)

	return root

# Helper: High-detail rifle cartridge (configurable scale for 7.92x57, 7.62x54R, .338 Lapua)
static func _build_rifle_round(case_r: float, case_h: float, neck_h: float, bullet_h: float, rimmed: bool, mat_case: Material, mat_bullet: Material, mat_primer: Material) -> Node3D:
	var r := Node3D.new()
	var y: float = 0.0
	if rimmed:
		_add_cyl(r, "Rim", case_r * 1.18, case_r * 1.18, case_h * 0.08, Vector3(0, y + case_h * 0.04, 0), mat_case, 14)
	else:
		_add_cyl(r, "Base", case_r * 0.96, case_r * 0.96, case_h * 0.07, Vector3(0, y + case_h * 0.035, 0), mat_case, 14)
	_add_cyl(r, "Primer", case_r * 0.35, case_r * 0.35, 0.002, Vector3(0, y, 0), mat_primer, 10)
	y += case_h * 0.07
	_add_cyl(r, "Body", case_r * 0.92, case_r, case_h * 0.72, Vector3(0, y + case_h * 0.36, 0), mat_case, 14)
	y += case_h * 0.72
	_add_cyl(r, "Shoulder", case_r * 0.68, case_r * 0.92, case_h * 0.21, Vector3(0, y + case_h * 0.105, 0), mat_case, 14)
	y += case_h * 0.21
	_add_cyl(r, "Neck", case_r * 0.66, case_r * 0.68, neck_h, Vector3(0, y + neck_h * 0.5, 0), mat_case, 14)
	y += neck_h
	_add_cyl(r, "BulletBase", case_r * 0.56, case_r * 0.64, bullet_h * 0.45, Vector3(0, y + bullet_h * 0.225, 0), mat_bullet, 14)
	y += bullet_h * 0.45
	_add_cyl(r, "BulletTip", 0.001, case_r * 0.56, bullet_h * 0.55, Vector3(0, y + bullet_h * 0.275, 0), mat_bullet, 14)
	return r

# 8E. 7.92x57mm MAUSER (SHARED AMMO FOR KAR98K & MG 42: German Paper Box + 5-Round Brass Stripper Clip!)
static func create_ammo_792x57(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "Ammo_792x57_Mauser_" + ammo_mode
	var mat_box := StandardMaterial3D.new()
	mat_box.roughness = 0.85
	var mat_band := StandardMaterial3D.new()
	mat_band.roughness = 0.78
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.84, 0.68, 0.24)
	mat_brass.metallic = 0.92
	mat_brass.roughness = 0.22
	var mat_copper := StandardMaterial3D.new()
	mat_copper.metallic = 0.88
	mat_copper.roughness = 0.24
	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.32, 0.34, 0.36)
	mat_steel.metallic = 0.86
	mat_steel.roughness = 0.34
	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.86, 0.88, 0.90)
	mat_primer.metallic = 0.92
	mat_primer.roughness = 0.18

	var txt: String = "7.92×57 sS\nKAR98K / MG 42"
	match ammo_mode:
		"ap":
			mat_box.albedo_color = Color(0.24, 0.26, 0.29)
			mat_band.albedo_color = Color(0.82, 0.14, 0.12)
			mat_copper.albedo_color = Color(0.11, 0.12, 0.15) # Blackened SmK AP tip
			txt = "7.92×57 SmK AP\nБРОНЕБОЙНЫЕ"
		"hp":
			mat_box.albedo_color = Color(0.44, 0.16, 0.14)
			mat_band.albedo_color = Color(0.86, 0.72, 0.32)
			mat_copper.albedo_color = Color(0.84, 0.86, 0.90) # Silver HP tip
			txt = "7.92×57 HP\nЭКСПАНСИВНЫЕ"
		_:
			mat_box.albedo_color = Color(0.72, 0.62, 0.44)
			mat_band.albedo_color = Color(0.18, 0.22, 0.16)
			mat_copper.albedo_color = Color(0.82, 0.46, 0.22)

	_add_box(root, "MauserBox", Vector3(0.20, 0.12, 0.10), Vector3(-0.05, -0.02, -0.02), mat_box)
	_add_box(root, "BoxBand", Vector3(0.203, 0.024, 0.103), Vector3(-0.05, 0.015, -0.02), mat_band)
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.font_size = 46
	lbl.pixel_size = 0.00044
	lbl.modulate = Color(0.95, 0.92, 0.86) if ammo_mode != "fmj" else Color(0.14, 0.12, 0.10)
	lbl.outline_modulate = Color.BLACK if ammo_mode != "fmj" else Color(0.88, 0.82, 0.68)
	lbl.outline_size = 5
	lbl.position = Vector3(-0.05, -0.024, 0.032)
	root.add_child(lbl)

	var clip_root := Node3D.new()
	clip_root.position = Vector3(0.105, -0.068, 0.022)
	clip_root.rotation_degrees = Vector3(0, -18.0, 0)
	root.add_child(clip_root)
	_add_box(clip_root, "ClipRail", Vector3(0.115, 0.018, 0.024), Vector3(0, 0.009, 0), mat_steel)
	for i in range(5):
		var c := _build_rifle_round(0.010, 0.095, 0.016, 0.048, false, mat_brass, mat_copper, mat_primer)
		c.position = Vector3(-0.044 + float(i) * 0.022, 0.006, 0)
		clip_root.add_child(c)

	var loose := _build_rifle_round(0.0105, 0.095, 0.016, 0.048, false, mat_brass, mat_copper, mat_primer)
	loose.position = Vector3(-0.07, -0.068, 0.068)
	loose.rotation_degrees = Vector3(88.0, 72.0, 0)
	root.add_child(loose)
	return root

# 8F. 7.62x54mm R (PKM: Steel 100-Round Belt Can + Linked Rimmed Brass Rounds!)
static func create_ammo_762x54r(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "Ammo_762x54R_PKM_" + ammo_mode
	var mat_can := StandardMaterial3D.new()
	mat_can.metallic = 0.55
	mat_can.roughness = 0.48
	var mat_link := StandardMaterial3D.new()
	mat_link.albedo_color = Color(0.16, 0.17, 0.18)
	mat_link.metallic = 0.85
	mat_link.roughness = 0.36
	var mat_case := StandardMaterial3D.new()
	mat_case.albedo_color = Color(0.70, 0.54, 0.24)
	mat_case.metallic = 0.88
	mat_case.roughness = 0.26
	var mat_bullet := StandardMaterial3D.new()
	mat_bullet.metallic = 0.90
	mat_bullet.roughness = 0.22
	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.84, 0.86, 0.88)
	mat_primer.metallic = 0.92
	mat_primer.roughness = 0.18

	var txt: String = "7.62×54R ЛПС\nЛЕНТА 100"
	match ammo_mode:
		"ap":
			mat_can.albedo_color = Color(0.14, 0.15, 0.17)
			mat_case.albedo_color = Color(0.32, 0.35, 0.28)
			mat_bullet.albedo_color = Color(0.14, 0.12, 0.14) # Black tungsten AP-I tip
			txt = "7.62×54R БС AP\nВОЛЬФРАМ 100"
		"hp":
			mat_can.albedo_color = Color(0.34, 0.13, 0.13)
			mat_bullet.albedo_color = Color(0.86, 0.88, 0.92) # Silver HP tip
			txt = "7.62×54R HP\nЭКСПАНСИВНЫЕ"
		_:
			mat_can.albedo_color = Color(0.20, 0.28, 0.16)
			mat_bullet.albedo_color = Color(0.82, 0.44, 0.20)

	_add_box(root, "PKMCan", Vector3(0.21, 0.15, 0.105), Vector3(-0.03, -0.02, -0.02), mat_can)
	_add_box(root, "CanLid", Vector3(0.218, 0.022, 0.112), Vector3(-0.03, 0.060, -0.02), mat_can)
	_add_box(root, "CanRib1", Vector3(0.18, 0.014, 0.112), Vector3(-0.03, -0.045, -0.02), mat_can)
	_add_box(root, "CanRib2", Vector3(0.18, 0.014, 0.112), Vector3(-0.03, 0.012, -0.02), mat_can)
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.font_size = 46
	lbl.pixel_size = 0.00044
	lbl.modulate = Color(0.94, 0.88, 0.42)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 6
	lbl.position = Vector3(-0.03, -0.016, 0.038)
	root.add_child(lbl)

	for i in range(6):
		var c := _build_rifle_round(0.010, 0.090, 0.015, 0.044, true, mat_case, mat_bullet, mat_primer)
		c.position = Vector3(0.095 + float(i) * 0.012, 0.02 - float(i) * 0.018, -0.01 + float(i) * 0.014)
		c.rotation_degrees = Vector3(82.0, -20.0 + float(i) * 8.0, -14.0)
		root.add_child(c)
		_add_box(root, "BeltLink_%d" % i, Vector3(0.022, 0.016, 0.024), c.position + Vector3(0, 0.004, 0.035), mat_link)
	return root

# 8G. .338 LAPUA MAGNUM (L96A1: Precision Match Box + Giant Long-Range Rounds!)
static func create_ammo_338lm(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "Ammo_338_LapuaMagnum_" + ammo_mode
	var mat_box := StandardMaterial3D.new()
	mat_box.roughness = 0.55
	var mat_gold := StandardMaterial3D.new()
	mat_gold.metallic = 0.85
	mat_gold.roughness = 0.24
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.26)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18
	var mat_copper := StandardMaterial3D.new()
	mat_copper.metallic = 0.92
	mat_copper.roughness = 0.20
	var mat_primer := StandardMaterial3D.new()
	mat_primer.albedo_color = Color(0.88, 0.90, 0.92)
	mat_primer.metallic = 0.95
	mat_primer.roughness = 0.14

	var txt: String = ".338 LAPUA\nMAGNUM MATCH"
	match ammo_mode:
		"ap":
			mat_box.albedo_color = Color(0.07, 0.08, 0.10)
			mat_gold.albedo_color = Color(0.88, 0.16, 0.12) # Crimson AP stripe
			mat_copper.albedo_color = Color(0.11, 0.12, 0.14) # Black tungsten-core AP tip
			txt = ".338 LAPUA AP\nБРОНЕБОЙНЫЕ"
		"hp":
			mat_box.albedo_color = Color(0.10, 0.15, 0.26)
			mat_gold.albedo_color = Color(0.86, 0.88, 0.94)
			mat_copper.albedo_color = Color(0.86, 0.88, 0.92) # Silver HP tip
			txt = ".338 LAPUA HP\nHOLLOW-POINT"
		_:
			mat_box.albedo_color = Color(0.08, 0.09, 0.11)
			mat_gold.albedo_color = Color(0.88, 0.72, 0.24)
			mat_copper.albedo_color = Color(0.84, 0.44, 0.18)

	_add_box(root, "MatchBox", Vector3(0.21, 0.13, 0.105), Vector3(-0.045, -0.02, -0.02), mat_box)
	_add_box(root, "GoldTrim", Vector3(0.213, 0.014, 0.108), Vector3(-0.045, 0.032, -0.02), mat_gold)
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.font_size = 46
	lbl.pixel_size = 0.00044
	lbl.modulate = Color(0.95, 0.80, 0.30)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 5
	lbl.position = Vector3(-0.045, -0.025, 0.034)
	root.add_child(lbl)

	for i in range(3):
		var c := _build_rifle_round(0.0145, 0.118, 0.020, 0.068, false, mat_brass, mat_copper, mat_primer)
		c.position = Vector3(0.095 + float(i) * 0.034, -0.085, 0.012 - float(i) * 0.018)
		root.add_child(c)
	return root

# 8H. .50 ACTION EXPRESS (DESERT EAGLE: Heavy Box + Chunky .50 AE Rounds!)
static func create_ammo_50ae(ammo_mode: String = "fmj") -> Node3D:
	var root := Node3D.new()
	root.name = "Ammo_50AE_Deagle_" + ammo_mode
	var mat_box := StandardMaterial3D.new()
	mat_box.roughness = 0.58
	var mat_red := StandardMaterial3D.new()
	mat_red.roughness = 0.45
	var mat_brass := StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.88, 0.72, 0.26)
	mat_brass.metallic = 0.94
	mat_brass.roughness = 0.18
	var mat_copper := StandardMaterial3D.new()
	mat_copper.metallic = 0.90
	mat_copper.roughness = 0.22

	var txt: String = ".50 ACTION EXPRESS\nDESERT EAGLE"
	match ammo_mode:
		"ap":
			mat_box.albedo_color = Color(0.09, 0.10, 0.13)
			mat_red.albedo_color = Color(0.88, 0.74, 0.24)
			mat_brass.albedo_color = Color(0.76, 0.78, 0.82)
			mat_copper.albedo_color = Color(0.11, 0.12, 0.15) # Black alloy AP bullet
			txt = ".50 AE AP\nБРОНЕБОЙНЫЕ"
		"incendiary":
			mat_box.albedo_color = Color(0.24, 0.09, 0.06)
			mat_red.albedo_color = Color(1.0, 0.48, 0.08)
			mat_copper.albedo_color = Color(0.98, 0.36, 0.08) # Fiery orange incendiary nose
			mat_copper.emission_enabled = true
			mat_copper.emission = Color(1.0, 0.36, 0.06)
			mat_copper.emission_energy_multiplier = 0.55
			txt = ".50 AE ЗАЖИГ.\nОГНЕННЫЕ 🔥"
		_:
			mat_box.albedo_color = Color(0.11, 0.10, 0.12)
			mat_red.albedo_color = Color(0.78, 0.14, 0.12)
			mat_copper.albedo_color = Color(0.82, 0.46, 0.20)

	_add_box(root, "AEBox", Vector3(0.19, 0.095, 0.11), Vector3(-0.035, -0.03, -0.015), mat_box)
	_add_box(root, "RedStripe", Vector3(0.193, 0.016, 0.113), Vector3(-0.035, 0.008, -0.015), mat_red)
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.font_size = 44
	lbl.pixel_size = 0.00042
	lbl.modulate = Color(0.96, 0.86, 0.42)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 5
	lbl.position = Vector3(-0.035, -0.034, 0.042)
	root.add_child(lbl)

	for i in range(3):
		var r := Node3D.new()
		_add_cyl(r, "Case", 0.015, 0.015, 0.068, Vector3(0, 0.034, 0), mat_brass, 16)
		_add_cyl(r, "Bullet", 0.011, 0.0145, 0.028, Vector3(0, 0.082, 0), mat_copper, 16)
		r.position = Vector3(0.088 + float(i) * 0.034, -0.075, 0.018 - float(i) * 0.018)
		root.add_child(r)
	var r4 := Node3D.new()
	_add_cyl(r4, "Case", 0.015, 0.015, 0.068, Vector3(0, 0.034, 0), mat_brass, 16)
	_add_cyl(r4, "Bullet", 0.011, 0.0145, 0.028, Vector3(0, 0.082, 0), mat_copper, 16)
	r4.position = Vector3(-0.02, -0.060, 0.068)
	r4.rotation_degrees = Vector3(88.0, 58.0, 0)
	root.add_child(r4)
	return root

# 8I. 40mm UNDERBARREL GRENADE PACK (M406 + VOG-25 40mm Grenades for GP-25 / M203!)
static func _build_40mm_m406(mat_case: Material, mat_olive: Material, mat_gold: Material, mat_steel: Material) -> Node3D:
	var g := Node3D.new()
	# Heavy metallic 40x46mm rimmed cartridge case + primer + knurled driving band + olive skirt + bright gold HE ogive dome!
	_add_cyl(g, "CaseRim", 0.034, 0.034, 0.008, Vector3(0, -0.070, 0), mat_case, 18)
	_add_cyl(g, "CaseBody", 0.0315, 0.0315, 0.068, Vector3(0, -0.032, 0), mat_case, 18)
	_add_cyl(g, "CrimpRing", 0.0325, 0.0325, 0.009, Vector3(0, 0.004, 0), mat_steel, 18)
	_add_cyl(g, "WarheadSkirt", 0.030, 0.0305, 0.038, Vector3(0, 0.026, 0), mat_olive, 18)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.030
	sm.height = 0.072
	sm.radial_segments = 18
	sm.rings = 10
	dome.mesh = sm
	dome.material_override = mat_gold
	dome.position = Vector3(0, 0.048, 0)
	g.add_child(dome)
	_add_cyl(g, "FuzeTip", 0.009, 0.013, 0.012, Vector3(0, 0.084, 0), mat_steel, 12)
	return g

static func _build_40mm_vog25(mat_steel: Material, mat_copper: Material, mat_fuze: Material) -> Node3D:
	var g := Node3D.new()
	# Authentic Russian caseless VOG-25 40mm grenade: dark pre-fragmented body + copper rifling band + point-detonating nose fuze!
	_add_cyl(g, "PropBase", 0.026, 0.028, 0.024, Vector3(0, -0.064, 0), mat_fuze, 16)
	_add_cyl(g, "BodyLower", 0.031, 0.030, 0.064, Vector3(0, -0.020, 0), mat_steel, 16)
	_add_cyl(g, "CopperBand", 0.0325, 0.0325, 0.012, Vector3(0, 0.002, 0), mat_copper, 16)
	_add_cyl(g, "BodyUpper", 0.024, 0.031, 0.036, Vector3(0, 0.030, 0), mat_steel, 16)
	_add_cyl(g, "NoseFuze", 0.009, 0.022, 0.030, Vector3(0, 0.062, 0), mat_fuze, 14)
	return g

static func create_ammo_ugl() -> Node3D:
	var root := Node3D.new()
	root.name = "Ammo_UGL_40mm"

	var mat_pouch := StandardMaterial3D.new()
	mat_pouch.albedo_color = Color(0.20, 0.24, 0.16) # Olive-drab tactical grenade pouch
	mat_pouch.roughness = 0.86

	var mat_strap := StandardMaterial3D.new()
	mat_strap.albedo_color = Color(0.11, 0.13, 0.10)
	mat_strap.roughness = 0.90

	var mat_case := StandardMaterial3D.new()
	mat_case.albedo_color = Color(0.56, 0.58, 0.50) # Anodized aluminum-brass M406 casing
	mat_case.metallic = 0.84
	mat_case.roughness = 0.28

	var mat_olive := StandardMaterial3D.new()
	mat_olive.albedo_color = Color(0.22, 0.30, 0.18)
	mat_olive.metallic = 0.42
	mat_olive.roughness = 0.44

	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.92, 0.74, 0.16) # High-vis M406 yellow-gold HE warhead dome
	mat_gold.metallic = 0.55
	mat_gold.roughness = 0.28

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.18, 0.20, 0.22) # Dark gunmetal VOG-25 body
	mat_steel.metallic = 0.86
	mat_steel.roughness = 0.34

	var mat_copper := StandardMaterial3D.new()
	mat_copper.albedo_color = Color(0.84, 0.46, 0.22)
	mat_copper.metallic = 0.92
	mat_copper.roughness = 0.22

	var mat_fuze := StandardMaterial3D.new()
	mat_fuze.albedo_color = Color(0.78, 0.68, 0.34)
	mat_fuze.metallic = 0.86
	mat_fuze.roughness = 0.26

	# Tactical 3-cell bandolier holder base
	_add_box(root, "PouchBase", Vector3(0.23, 0.088, 0.095), Vector3(-0.025, -0.048, -0.028), mat_pouch)
	_add_box(root, "PouchStrap", Vector3(0.236, 0.020, 0.100), Vector3(-0.025, -0.042, -0.028), mat_strap)

	var lbl := Label3D.new()
	lbl.text = "40мм ВОГ-25 / M406\n3 ГРАНАТЫ ГП"
	lbl.font_size = 44
	lbl.pixel_size = 0.00042
	lbl.modulate = Color(0.96, 0.84, 0.36)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 5
	lbl.position = Vector3(-0.025, -0.048, 0.024)
	root.add_child(lbl)

	# 2 Upright 40mm M406 grenades seated in bandolier + 1 upright VOG-25
	var g1 := _build_40mm_m406(mat_case, mat_olive, mat_gold, mat_steel)
	g1.position = Vector3(-0.085, 0.022, -0.028)
	root.add_child(g1)

	var g2 := _build_40mm_m406(mat_case, mat_olive, mat_gold, mat_steel)
	g2.position = Vector3(-0.015, 0.028, -0.028)
	root.add_child(g2)

	var g3 := _build_40mm_vog25(mat_steel, mat_copper, mat_fuze)
	g3.position = Vector3(0.056, 0.024, -0.026)
	root.add_child(g3)

	# 1 Hero 40mm VOG-25 lying diagonally in foreground so all details pop!
	var g_front := _build_40mm_vog25(mat_steel, mat_copper, mat_fuze)
	g_front.position = Vector3(0.065, -0.058, 0.065)
	g_front.rotation_degrees = Vector3(84.0, 56.0, 12.0)
	root.add_child(g_front)

	return root
