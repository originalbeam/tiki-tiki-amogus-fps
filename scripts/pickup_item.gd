class_name PickupItem
extends Area3D

enum ItemType {
	ARMOR_VEST,
	BANDAGE
}

@export var item_type: ItemType = ItemType.ARMOR_VEST

var lifetime: float = 30.0
var flash_start_time: float = 7.0
var is_picked_up: bool = false
var bob_timer: float = 0.0

@onready var visual_root: Node3D = $Visuals
@onready var armor_mesh_root: Node3D = $Visuals/ArmorMesh
@onready var bandage_mesh_root: Node3D = $Visuals/BandageMesh

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 # Collide with player
	body_entered.connect(_on_body_entered)
	setup_visuals()

func init(type: ItemType) -> void:
	item_type = type
	if is_node_ready():
		setup_visuals()

func setup_visuals() -> void:
	if armor_mesh_root and bandage_mesh_root:
		armor_mesh_root.visible = (item_type == ItemType.ARMOR_VEST)
		bandage_mesh_root.visible = (item_type == ItemType.BANDAGE)

func _process(delta: float) -> void:
	if is_picked_up:
		return
		
	# Bobbing and rotation animation
	bob_timer += delta * 2.5
	if visual_root:
		visual_root.position.y = sin(bob_timer) * 0.08
		visual_root.rotation.y += delta * 1.5
		
	lifetime -= delta
	
	# Last 7 seconds flashing
	if lifetime <= flash_start_time and lifetime > 0.0:
		var flash_speed := 16.0 if lifetime <= 3.0 else 10.0
		visual_root.visible = sin(lifetime * flash_speed) > 0.0
	elif lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if is_picked_up:
		return
	if body.is_in_group("player"):
		pickup(body)

func pickup(player: Node3D) -> void:
	if is_picked_up:
		return
		
	match item_type:
		ItemType.ARMOR_VEST:
			if player.has_method("add_armor"):
				if "armor" in player and player.armor > 75.0:
					return
				if "armor" in player and "max_armor" in player and player.armor >= player.max_armor:
					return
				player.add_armor(15.0, true)
				play_sound(SoundEffects.create_zipper_sound())
				is_picked_up = true
				queue_free()
		ItemType.BANDAGE:
			if player.has_method("add_health"):
				if "health" in player and "max_health" in player and player.health >= player.max_health:
					return
				player.add_health(10.0)
				play_sound(SoundEffects.create_bandage_sound())
				is_picked_up = true
				queue_free()

func play_sound(stream: AudioStream) -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
