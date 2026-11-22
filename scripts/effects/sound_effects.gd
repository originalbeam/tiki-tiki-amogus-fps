class_name SoundEffects
extends Node

# Complete Real-World CC0 Audio Effects Engine (Rebuilt from Scratch)
# Every single sound effect in the game is backed by authentic, real-world CC0
# open-access field & studio recordings in res://sounds/real/ (40 OGG Vorbis files).
# Features automatic in-memory caching, multi-variant randomization for automatic
# firearms, and seamless looping for continuous vehicle/drone/rocket motors.

static var _sound_cache: Dictionary = {}

const REAL_BASE := "res://sounds/real/"

# Multi-variant pools for natural gunfire variation
const AK47_SHOT_POOL: Array[String] = [
	REAL_BASE + "weapons/ak47_shot_1.ogg",
	REAL_BASE + "weapons/ak47_shot_2.ogg",
]

const PISTOL_SHOT_POOL: Array[String] = [
	REAL_BASE + "weapons/pistol_shot_1.ogg",
	REAL_BASE + "weapons/pistol_shot_2.ogg",
]

static func load_audio_file(res_path: String, looping: bool = false) -> AudioStream:
	var cache_key := res_path + ("|loop" if looping else "|once")
	if _sound_cache.has(cache_key):
		return _sound_cache[cache_key]
		
	var stream: AudioStream = null
	if res_path.ends_with(".ogg"):
		if FileAccess.file_exists(res_path):
			var ogg := AudioStreamOggVorbis.load_from_file(res_path)
			if ogg:
				ogg.loop = looping
				stream = ogg
		elif ResourceLoader.exists(res_path):
			var res := ResourceLoader.load(res_path)
			if res is AudioStreamOggVorbis:
				var dup: AudioStreamOggVorbis = res.duplicate()
				dup.loop = looping
				stream = dup
			elif res is AudioStream:
				stream = res
	elif res_path.ends_with(".mp3"):
		if FileAccess.file_exists(res_path):
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(res_path)
			mp3.loop = looping
			stream = mp3
	elif res_path.ends_with(".wav"):
		if FileAccess.file_exists(res_path):
			stream = load_wav_file(res_path)
			
	if not stream:
		stream = _create_empty_fallback()
	_sound_cache[cache_key] = stream
	return stream

static func _pick_pool(pool: Array[String]) -> AudioStream:
	if pool.is_empty():
		return _create_empty_fallback()
	var idx: int = randi() % pool.size()
	return load_audio_file(pool[idx], false)

static func _create_empty_fallback() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(64)
	wav.data = data
	return wav

static func load_wav_file(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var channels := 1
	var sample_rate := 44100
	var bits_per_sample := 16
	var pcm_data := PackedByteArray()
	var offset := 12
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(offset + 4)
		offset += 8
		if chunk_id == "fmt " and offset + 16 <= bytes.size():
			channels = bytes.decode_u16(offset + 2)
			sample_rate = bytes.decode_u32(offset + 4)
			bits_per_sample = bytes.decode_u16(offset + 14)
		elif chunk_id == "data":
			var end_idx := mini(offset + chunk_size, bytes.size())
			pcm_data = bytes.slice(offset, end_idx)
			break
		offset += chunk_size
		if chunk_size % 2 == 1:
			offset += 1
	if pcm_data.is_empty():
		return null
	var stream := AudioStreamWAV.new()
	stream.data = pcm_data
	stream.mix_rate = sample_rate
	stream.stereo = (channels >= 2)
	stream.format = AudioStreamWAV.FORMAT_8_BITS if bits_per_sample == 8 else AudioStreamWAV.FORMAT_16_BITS
	return stream

# ==========================================
# 1. FIREARMS & ORDNANCE (REAL CC0 RECORDINGS)
# ==========================================

static func get_ak47_sound(_variant_id: String = "") -> AudioStream:
	return _pick_pool(AK47_SHOT_POOL)

static func create_ak47_sound() -> AudioStream:
	return _pick_pool(AK47_SHOT_POOL)

static func get_enemy_ak47_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/ak47_enemy.ogg", false)

static func create_shotgun_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/shotgun_shot.ogg", false)

static func create_pistol_sound() -> AudioStream:
	return _pick_pool(PISTOL_SHOT_POOL)

static func create_awp_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/sniper_shot.ogg", false)

static func create_rpg_shot_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/rpg_shot.ogg", false)

static func create_rpg_flight_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/rpg_flight.ogg", true)

static func create_laser_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "weapons/laser_fallback.ogg", false)

# ==========================================
# 2. WEAPON MECHANICS & FOLEY (REAL METAL HANDLING)
# ==========================================

static func create_dry_fire_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/dry_fire.ogg", false)

static func create_shell_insert_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/shell_insert.ogg", false)

static func create_pump_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/shotgun_pump.ogg", false)

static func create_magazine_out_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/mag_out.ogg", false)

static func create_magazine_in_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/mag_in.ogg", false)

static func create_bolt_pull_ak_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/ak_bolt_pull.ogg", false)

static func create_slide_pull_pistol_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/pistol_slide.ogg", false)

static func create_rpg_reload_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "handling/rpg_reload.ogg", false)

static func create_bolt_pull_sound() -> AudioStream:
	return create_bolt_pull_ak_sound()

static func create_reload_sound() -> AudioStream:
	return create_magazine_in_sound()

# ==========================================
# 3. EXPLOSIONS (REAL HE & DEBRIS RECORDINGS)
# ==========================================

static func create_rpg_explosion_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "explosions/rpg_explosion.ogg", false)

static func create_shahed_explosion_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "explosions/shahed_explosion.ogg", false)

# ==========================================
# 4. MELEE & COMBAT IMPACTS
# ==========================================

static func create_knife_slash_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/knife_slash.ogg", false)

static func create_knife_hit_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/knife_hit.ogg", false)

static func create_axe_swing_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/axe_swing.ogg", false)

static func create_axe_hit_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/axe_hit.ogg", false)

static func create_hit_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/hitmarker.ogg", false)

static func create_explosion_gib_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/gib_explosion.ogg", false)

static func create_player_hurt_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/player_hurt.ogg", false)

static func create_player_jump_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/player_jump.ogg", false)

static func create_sniper_charge_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "combat/sniper_charge.ogg", false)

# ==========================================
# 5. GEAR, MEDICAL, CONSUMABLES & ECONOMY
# ==========================================

static func create_bandage_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/bandage.ogg", false)

static func create_zipper_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/zipper.ogg", false)

static func create_heavy_armor_equip_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/heavy_armor.ogg", false)

static func create_armor_plate_insert_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/armor_plate.ogg", false)

static func create_vodka_drink_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/vodka_drink.ogg", false)

static func create_buy_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "gear/buy_shop.ogg", false)

# ==========================================
# 6. VEHICLES & SHAHED KAMIKAZE DRONE
# ==========================================

static func create_shahed_engine_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "vehicles/shahed_engine.ogg", true)

static func create_shahed_dive_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "vehicles/shahed_dive.ogg", false)

static func create_van_engine_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "vehicles/van_engine.ogg", true)

static func create_van_horn_sound() -> AudioStream:
	return load_audio_file(REAL_BASE + "vehicles/van_horn.ogg", false)

static func create_van_reverse_beep() -> AudioStream:
	return load_audio_file(REAL_BASE + "vehicles/van_reverse.ogg", false)
