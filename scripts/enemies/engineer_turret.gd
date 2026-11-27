class_name EngineerTurret
extends StaticBody3D

# Portable Automated Sentry Turret deployed on the arena by Orange Crewmate Engineers!
# - Tracks player within 28m, fires short 2-round bursts with red laser sight warning
# - 115 HP, destroyable by bullets/explosions (+$12 reward), glows warm in FLIR thermal!

const VFXFactoryScript = preload("res://scripts/effects/vfx_factory.gd")
const BulletScene = preload("res://scenes/enemy_bullet.tscn")

var max_health: float = 115.0
var health: float = 115.0
var is_dead: bool = false
var fire_timer: float = 1.1
var burst_left: int = 0
var burst_cd: float = 0.0
var lifetime: float = 45.0

var head_pivot: Node3D = null
var muzzle: Marker3D = null
var laser_beam: MeshInstance3D = null
var player: Node3D = null

func _ready() -> void:
	collision_layer = 1
	collision_mask = 7
	add_to_group("enemy_turret")
	add_to_group("arena_shootable")
	set_meta("interact_kind", "enemy_turret")
	_build_model()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _build_model() -> void:
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.75, 1.15, 0.75)
	col.shape = bs
	col.position = Vector3(0, 0.58, 0)
	add_child(col)

	var m_dark := _mat(Color(0.14, 0.15, 0.17), 0.78, 0.38)
	var m_orange := _mat(Color(0.88, 0.44, 0.10), 0.35, 0.48)
	var m_steel := _mat(Color(0.28, 0.30, 0.34), 0.86, 0.30)
	var m_red := StandardMaterial3D.new()
	m_red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_red.albedo_color = Color(1.0, 0.14, 0.10)

	# Tripod legs & central column
	_cyl(self, "CenterPost", 0.06, 0.08, 0.76, Vector3(0, 0.42, 0), m_steel, 10)
	for i in range(3):
		var a: float = float(i) * (TAU / 3.0)
		var leg := _cyl(self, "Leg_%d" % i, 0.025, 0.03, 0.68, Vector3(cos(a) * 0.24, 0.26, sin(a) * 0.24), m_dark, 8)
		leg.rotation = Vector3(sin(a) * 0.55, 0.0, -cos(a) * 0.55)

	# Swiveling gun turret head
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 0.88, 0)
	add_child(head_pivot)

	var housing := _box(head_pivot, "TurretBox", Vector3(0.32, 0.26, 0.46), Vector3(0, 0, 0), m_orange)
	# Warm FLIR thermal heat proxy on electronics/barrel housing
	var th := MeshInstance3D.new()
	th.mesh = housing.mesh
	th.layers = 4
	th.scale = Vector3(1.03, 1.03, 1.03)
	var thm := StandardMaterial3D.new()
	thm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	thm.albedo_color = Color(0.90, 0.0, 1.0, 1.0)
	th.material_override = thm
	housing.add_child(th)

	_box(head_pivot, "SensorPod", Vector3(0.14, 0.10, 0.16), Vector3(0, 0.16, -0.10), m_dark)
	_cyl(head_pivot, "SensorEye", 0.038, 0.038, 0.04, Vector3(0, 0.16, -0.19), m_red, 10, Vector3(90, 0, 0))
	_cyl(head_pivot, "Barrel", 0.024, 0.028, 0.56, Vector3(0, 0.0, -0.44), m_steel, 10, Vector3(90, 0, 0))
	_box(head_pivot, "AmmoDrum", Vector3(0.14, 0.18, 0.22), Vector3(0.22, -0.02, 0.04), m_dark)

	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.0, -0.74)
	head_pivot.add_child(muzzle)

	# Short visible laser designator
	laser_beam = MeshInstance3D.new()
	var lcm := CylinderMesh.new(); lcm.top_radius = 0.006; lcm.bottom_radius = 0.006; lcm.height = 1.0; lcm.radial_segments = 6
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.albedo_color = Color(1.0, 0.12, 0.08, 0.55)
	laser_beam.mesh = lcm; laser_beam.material_override = lmat
	laser_beam.position = Vector3(0, 0.16, -3.2)
	laser_beam.rotation_degrees = Vector3(90, 0, 0)
	laser_beam.scale = Vector3(1, 6.0, 1)
	head_pivot.add_child(laser_beam)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_destroy(false)
		return
	if not is_instance_valid(player):
		var ps := get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			player = ps[0]
		return
	if ("is_dead" in player) and bool(player.get("is_dead")):
		return

	var target_p: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var dist: float = global_position.distance_to(target_p)
	if dist <= 28.0 and head_pivot:
		var local_dir: Vector3 = target_p - head_pivot.global_position
		var tyaw: float = atan2(-local_dir.x, -local_dir.z)
		var hd: float = maxf(0.1, Vector2(local_dir.x, local_dir.z).length())
		var tpitch: float = clampf(atan2(local_dir.y, hd), deg_to_rad(-25.0), deg_to_rad(35.0))
		head_pivot.rotation.y = lerp_angle(head_pivot.rotation.y, tyaw, delta * 6.5)
		head_pivot.rotation.x = lerpf(head_pivot.rotation.x, tpitch, delta * 6.5)

		if burst_left > 0:
			burst_cd -= delta
			if burst_cd <= 0.0:
				burst_cd = 0.14
				burst_left -= 1
				_fire_bullet(target_p)
		else:
			fire_timer -= delta
			if fire_timer <= 0.0:
				if _has_los(target_p):
					fire_timer = 1.45
					burst_left = 2
					burst_cd = 0.0
				else:
					fire_timer = 0.35

func _has_los(target_p: Vector3) -> bool:
	var ss := get_world_3d().direct_space_state
	var from_p: Vector3 = global_position + Vector3(0, 0.95, 0)
	var q := PhysicsRayQueryParameters3D.create(from_p, target_p)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var r := ss.intersect_ray(q)
	if r.is_empty():
		return true
	return r.collider == player or (r.collider != null and r.collider.is_in_group("player"))

func _fire_bullet(target_p: Vector3) -> void:
	if not BulletScene or not muzzle:
		return
	var b = BulletScene.instantiate()
	get_parent().add_child(b)
	var sp: Vector3 = muzzle.global_position
	b.global_position = sp
	var d: Vector3 = ((target_p + Vector3(randf_range(-0.14, 0.14), randf_range(-0.12, 0.12), randf_range(-0.14, 0.14))) - sp).normalized()
	var dmg: float = 7.0 * (GlobalSettings.get_enemy_damage_multiplier() if GlobalSettings else 1.0)
	b.init(d, dmg, Color(1.0, 0.45, 0.15), 30.0)
	VFXFactoryScript.spawn_enemy_muzzle_flash(get_parent(), sp, d, Color(1.0, 0.55, 0.18), 0.72)

	var ap := AudioStreamPlayer3D.new()
	ap.bus = "Weapons"
	ap.stream = SoundEffects.create_pistol_sound()
	ap.pitch_scale = randf_range(1.22, 1.35)
	ap.volume_db = -4.0
	ap.max_distance = 55.0
	ap.position = sp
	get_tree().root.add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func take_damage(amount: float, _is_shotgun: bool = false) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0.0:
		_destroy(true)

func _destroy(award_player: bool) -> void:
	if is_dead:
		return
	is_dead = true
	var p: Vector3 = global_position + Vector3(0, 0.65, 0)
	VFXFactoryScript.spawn_explosion(get_tree().root, p, Vector3.UP, 0.55)
	var ap := AudioStreamPlayer3D.new()
	ap.bus = "SFX"
	ap.stream = SoundEffects.create_rpg_explosion_sound()
	ap.pitch_scale = 1.45
	ap.volume_db = -4.0
	ap.position = p
	get_tree().root.add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)
	if award_player and is_instance_valid(player) and player.has_method("add_money"):
		player.add_money(12)
	queue_free()

static func _mat(col: Color, met: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col; m.metallic = met; m.roughness = rough
	return m

static func _box(parent: Node3D, nm: String, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = nm
	var bm := BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.material_override = mat; mi.position = pos
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, nm: String, tr: float, br: float, h: float, pos: Vector3, mat: Material, segs: int = 10, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.name = nm
	var cm := CylinderMesh.new(); cm.top_radius = tr; cm.bottom_radius = br; cm.height = h; cm.radial_segments = segs
	mi.mesh = cm; mi.material_override = mat; mi.position = pos
	if rot_deg != Vector3.ZERO: mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi
