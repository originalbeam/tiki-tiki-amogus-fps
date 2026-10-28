extends Node3D

@onready var light_beam: MeshInstance3D = $LightBeam
@onready var ground_ring: MeshInstance3D = $GroundRing
@onready var beacon_light: OmniLight3D = $BeaconLight
@onready var info_label: Label3D = $InfoLabel

var pulse_time: float = 0.0

func _ready() -> void:
	visible = true

func _process(delta: float) -> void:
	pulse_time += delta * 6.0
	var pulse: float = 0.6 + sin(pulse_time) * 0.4
	
	if beacon_light:
		beacon_light.light_energy = 1.5 + pulse * 2.0
		
	if ground_ring:
		ground_ring.rotate_y(delta * 2.0)
		ground_ring.scale = Vector3.ONE * (1.0 + sin(pulse_time * 0.5) * 0.15)

func set_spawn_info(total: int, red: int, blue: int, yellow: int, green: int, drone: int = 0) -> void:
	if not info_label:
		return
	var lines: Array[String] = []
	lines.append("⚠ СПАВН: %d ВРАГОВ ⚠" % total)
	var breakdown: Array[String] = []
	if red > 0:
		breakdown.append("🔴 Красных: %d" % red)
	if blue > 0:
		breakdown.append("🔵 Синих: %d" % blue)
	if yellow > 0:
		breakdown.append("🟡 Желтых: %d" % yellow)
	if green > 0:
		breakdown.append("🟢 Зеленых: %d" % green)
	if drone > 0:
		breakdown.append("✈️ Шахедов: %d" % drone)
	if not breakdown.is_empty():
		lines.append(", ".join(breakdown))
	info_label.text = "\n".join(lines)

func dismiss() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 2.0, 0.01), 0.25)
	await tween.finished
	queue_free()
