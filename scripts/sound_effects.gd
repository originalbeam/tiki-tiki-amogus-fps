class_name SoundEffects
extends Node

# Procedural Sound Generator for FPS
# Creates 16-bit PCM AudioStreamWAV objects in memory

static func create_ak47_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.32
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var crack := (randf() * 2.0 - 1.0) * exp(-t * 50.0) * 1.2
		var snap := sin(t * 1350.0 * TAU) * exp(-t * 70.0) * 0.85
		var punch_freq := 130.0 * exp(-t * 24.0) + 50.0
		var punch := sin(t * punch_freq * TAU) * exp(-t * 14.0) * 1.15
		var mech := sin(t * 860.0 * TAU) * exp(-absf(t - 0.04) * 45.0) * 0.45
		var rumble := sin(t * 55.0 * TAU) * exp(-t * 8.0) * 0.55
		var raw := crack + snap + punch + mech + rumble
		var sample := clampf(raw / (1.0 + absf(raw) * 0.35) * 1.2, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_shotgun_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.55
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var blast := (randf() * 2.0 - 1.0) * exp(-t * 26.0) * 1.45
		var bass_freq := 62.0 * exp(-t * 10.0) + 28.0
		var bass := sin(t * bass_freq * TAU) * exp(-t * 7.0) * 1.35
		var mid := sin(t * 180.0 * TAU) * exp(-t * 16.0) * 0.8
		var echo := (randf() * 2.0 - 1.0) * 0.35 * exp(-t * 5.0)
		var raw := blast + bass + mid + echo
		var sample := clampf(raw / (1.0 + absf(raw) * 0.4) * 1.25, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_pistol_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.22
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var pop := (randf() * 2.0 - 1.0) * exp(-t * 60.0) * 1.0
		var snap_freq := 390.0 * exp(-t * 38.0) + 160.0
		var snap := sin(t * snap_freq * TAU) * exp(-t * 30.0) * 1.15
		var slide := sin(t * 1380.0 * TAU) * exp(-absf(t - 0.02) * 55.0) * 0.45
		var punch := sin(t * 90.0 * TAU) * exp(-t * 20.0) * 0.65
		var raw := pop + snap + slide + punch
		var sample := clampf(raw / (1.0 + absf(raw) * 0.3) * 1.15, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_awp_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.85
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var boom_freq := 52.0 * exp(-t * 8.0) + 20.0
		var boom := sin(t * boom_freq * TAU) * exp(-t * 5.0) * 1.45
		var crack := (randf() * 2.0 - 1.0) * exp(-t * 24.0) * 1.35
		var reverb := (randf() * 2.0 - 1.0) * 0.35 * exp(-t * 3.2)
		var raw := boom + crack + reverb
		var sample := clampf(raw / (1.0 + absf(raw) * 0.35) * 1.25, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_dry_fire_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.12
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var click1 := sin(t * 2800.0 * TAU) * exp(-absf(t - 0.005) * 130.0) * 0.85
		var click2 := sin(t * 1320.0 * TAU) * exp(-absf(t - 0.012) * 85.0) * 0.65
		var snap := (randf() * 2.0 - 1.0) * exp(-t * 85.0) * 0.45
		var steel_ring := sin(t * 3200.0 * TAU) * exp(-t * 38.0) * 0.3
		var sample := clampf(click1 + click2 + snap + steel_ring, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_shell_insert_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.22
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var scrape := 0.0
		if t < 0.08:
			scrape = (randf() * 2.0 - 1.0) * 0.35 * sin(t / 0.08 * PI)
		var spring_thrum := sin(t * 340.0 * TAU) * exp(-absf(t - 0.08) * 45.0) * 0.35
		var gate_snap := sin(t * 1850.0 * TAU) * exp(-absf(t - 0.13) * 85.0) * 0.95
		var gate_thump := sin(t * 520.0 * TAU) * exp(-absf(t - 0.135) * 55.0) * 0.7
		var gate_click := (randf() * 2.0 - 1.0) * exp(-absf(t - 0.13) * 75.0) * 0.5
		var sample := clampf(scrape + spring_thrum + gate_snap + gate_thump + gate_click, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_pump_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.28
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var back_noise := (randf() * 2.0 - 1.0) * 0.45 * exp(-absf(t - 0.05) * 50.0)
		var back_metal := sin(t * 820.0 * TAU) * exp(-absf(t - 0.055) * 45.0) * 0.55
		var fwd_thud := sin(t * 410.0 * TAU) * exp(-absf(t - 0.16) * 55.0) * 0.85
		var fwd_snap := sin(t * 1720.0 * TAU) * exp(-absf(t - 0.155) * 80.0) * 0.75
		var fwd_noise := (randf() * 2.0 - 1.0) * exp(-absf(t - 0.16) * 60.0) * 0.45
		var sample := clampf(back_noise + back_metal + fwd_thud + fwd_snap + fwd_noise, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_magazine_out_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.22
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var latch := sin(t * 2200.0 * TAU) * exp(-absf(t - 0.02) * 80.0) * 0.75
		var scrape := (randf() * 2.0 - 1.0) * 0.4 * exp(-t * 18.0) * (sin(t * 820.0 * TAU) * 0.4 + 0.6)
		var sample := clampf(latch + scrape, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_magazine_in_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.26
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var slide := 0.0
		if t < 0.10:
			slide = (randf() * 2.0 - 1.0) * 0.32 * sin(t / 0.10 * PI)
		var click1 := sin(t * 1480.0 * TAU) * exp(-absf(t - 0.11) * 70.0) * 0.65
		var click2 := sin(t * 2250.0 * TAU) * exp(-absf(t - 0.145) * 85.0) * 0.9
		var lock_body := sin(t * 540.0 * TAU) * exp(-absf(t - 0.145) * 50.0) * 0.75
		var sample := clampf(slide + click1 + click2 + lock_body, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_bolt_pull_ak_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.34
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var pull_scrape := (randf() * 2.0 - 1.0) * 0.4 * exp(-absf(t - 0.06) * 35.0) * sin(t * 680.0 * TAU)
		var slam_crack := sin(t * 1950.0 * TAU) * exp(-absf(t - 0.18) * 75.0) * 0.95
		var trunnion_thud := sin(t * 390.0 * TAU) * exp(-absf(t - 0.185) * 45.0) * 0.85
		var trunnion_ring := sin(t * 2600.0 * TAU) * exp(-absf(t - 0.19) * 30.0) * 0.4
		var slam_noise := (randf() * 2.0 - 1.0) * exp(-absf(t - 0.18) * 60.0) * 0.45
		var sample := clampf(pull_scrape + slam_crack + trunnion_thud + trunnion_ring + slam_noise, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_slide_pull_pistol_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.26
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var draw_glide := (randf() * 2.0 - 1.0) * 0.35 * exp(-absf(t - 0.04) * 40.0) * sin(t * 1150.0 * TAU)
		var release_snap := sin(t * 2450.0 * TAU) * exp(-absf(t - 0.13) * 85.0) * 0.95
		var frame_slap := sin(t * 620.0 * TAU) * exp(-absf(t - 0.135) * 55.0) * 0.75
		var frame_noise := (randf() * 2.0 - 1.0) * exp(-absf(t - 0.13) * 70.0) * 0.4
		var sample := clampf(draw_glide + release_snap + frame_slap + frame_noise, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_bolt_pull_sound() -> AudioStreamWAV:
	return create_bolt_pull_ak_sound()

static func create_reload_sound() -> AudioStreamWAV:
	return create_magazine_in_sound()

static func create_bandage_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.68
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var wrap_rhythm := sin(t * 22.0 * TAU)
		var cloth_noise := 0.0
		var cloth_swish := 0.0
		if t < 0.42:
			cloth_noise = (randf() * 2.0 - 1.0) * 0.45 * (0.6 + wrap_rhythm * 0.4) * exp(-t * 2.0)
			cloth_swish = sin(t * 420.0 * TAU) * (randf() * 0.3) * (0.5 + wrap_rhythm * 0.5)
		var stretch := (randf() * 2.0 - 1.0) * 0.35 * exp(-absf(t - 0.42) * 28.0)
		var tear_noise := (randf() * 2.0 - 1.0) * 0.85 * exp(-absf(t - 0.54) * 32.0)
		var tear_crackle := (1.0 if randf() < 0.28 else -1.0) * 0.65 * exp(-absf(t - 0.55) * 38.0)
		var cloth_rip := sin(t * 1950.0 * TAU * (randf() * 0.3 + 0.85)) * exp(-absf(t - 0.54) * 28.0) * 0.5
		var sample := clampf(cloth_noise + cloth_swish + stretch + tear_noise + tear_crackle + cloth_rip, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_zipper_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.68
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var plate_thud := sin(t * 82.0 * TAU) * exp(-absf(t - 0.08) * 35.0) * 0.8
		var plate_scrape := (randf() * 2.0 - 1.0) * 0.4 * exp(-t * 14.0) * sin(t * 580.0 * TAU)
		var velcro_noise := (randf() * 2.0 - 1.0) * 0.55 * exp(-absf(t - 0.24) * 20.0) * (sin(t * 48.0 * TAU) * 0.4 + 0.6)
		var zip_noise := 0.0
		var zip_teeth := 0.0
		var slider_snap := 0.0
		if t >= 0.32:
			var zip_progress := clampf((t - 0.32) / 0.28, 0.0, 1.0)
			var teeth_freq := 280.0 + zip_progress * 550.0
			zip_teeth = sin((t - 0.32) * teeth_freq * TAU) * 0.6 * (1.0 - zip_progress * 0.2)
			zip_noise = (randf() * 2.0 - 1.0) * 0.35 * sin(zip_progress * PI)
			slider_snap = sin(t * 1850.0 * TAU) * exp(-absf(t - 0.60) * 65.0) * 0.85
		var sample := clampf(plate_thud + plate_scrape + velcro_noise + zip_noise + zip_teeth + slider_snap, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_knife_slash_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.16
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var swish_freq: float = lerpf(980.0, 320.0, t / duration)
		var swish := sin(t * swish_freq * TAU) * 0.65
		var air := (randf() * 2.0 - 1.0) * 0.45 * sin(t / duration * PI)
		var env := sin(t / duration * PI) * exp(-t * 8.0)
		var sample := clampf((swish + air) * env * 1.3, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_knife_hit_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.24
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var env := exp(-t * 15.0)
		var thud := sin(t * 85.0 * TAU) * 0.85
		var slash := (randf() * 2.0 - 1.0) * exp(-t * 26.0) * 0.8
		var squelch := sin(t * 450.0 * TAU) * exp(-absf(t - 0.04) * 45.0) * 0.5
		var sample := clampf((thud + slash + squelch) * env * 1.2, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_buy_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.28
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var chime1 := sin(t * 987.77 * TAU) * exp(-t * 12.0) * 0.6
		var chime2 := 0.0
		if t >= 0.08:
			chime2 = sin((t - 0.08) * 1318.51 * TAU) * exp(-(t - 0.08) * 14.0) * 0.7
		var clink := (randf() * 2.0 - 1.0) * exp(-absf(t - 0.08) * 55.0) * 0.3
		var sample := clampf(chime1 + chime2 + clink, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_laser_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.18
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var freq: float = lerpf(1200.0, 300.0, t / duration)
		var envelope := exp(-t * 18.0)
		var sample := sin(t * freq * TAU) * envelope * 0.7
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_hit_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.08
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var envelope := exp(-t * 45.0)
		var sample := sin(t * 1400.0 * TAU) * envelope * 0.6
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_explosion_gib_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.5
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var env := exp(-t * 8.0)
		var boom := sin(t * 80.0 * TAU) * exp(-t * 10.0) * 0.8
		var splat := (randf() * 2.0 - 1.0) * exp(-t * 12.0) * 0.7
		var squish := sin(t * 400.0 * TAU * (1.0 - t)) * exp(-t * 18.0) * 0.5
		var sample := clampf((boom + splat + squish) * env, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_player_hurt_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.18
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var env := exp(-t * 16.0)
		var low := sin(t * 120.0 * TAU) * 0.7
		var noise := (randf() * 2.0 - 1.0) * 0.3
		var sample := clampf((low + noise) * env, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_axe_swing_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.32
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var whoosh_freq := 90.0 + sin(t / duration * PI) * 160.0
		var whoosh := sin(t * whoosh_freq * TAU) * 0.7
		var air := (randf() * 2.0 - 1.0) * 0.4 * sin(t / duration * PI)
		var env := sin(t / duration * PI)
		var sample := clampf((whoosh + air) * env, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_axe_hit_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.26
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var env := exp(-t * 14.0)
		var thud := sin(t * 75.0 * TAU) * 0.8
		var slash := (randf() * 2.0 - 1.0) * exp(-t * 22.0) * 0.7
		var sample := clampf((thud + slash) * env, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_sniper_charge_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.5
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var pitch := 1200.0 + t * 800.0
		var tone := sin(t * pitch * TAU) * 0.25
		var shimmer := sin(t * 3800.0 * TAU) * (0.1 + sin(t * 18.0 * TAU) * 0.08)
		var env := (t / duration) * 0.4
		var sample := clampf((tone + shimmer) * env, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav



# --- SHAHED DRONE SOUNDS ---

static func create_shahed_engine_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.2
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		# 2-stroke motor buzz (~88 Hz fundamental with rich harmonics)
		var f := 88.0 + sin(t * 3.0 * TAU) * 3.0
		var h1 := sin(t * f * TAU) * 0.45
		var h2 := sin(t * f * 2.0 * TAU) * 0.35
		var h3 := sin(t * f * 3.0 * TAU) * 0.22
		var h4 := sin(t * f * 4.0 * TAU) * 0.15
		var prop_flutter := (randf() * 2.0 - 1.0) * 0.12 * sin(t * f * TAU)
		var sample := clampf((h1 + h2 + h3 + h4 + prop_flutter) * 0.75, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total_samples
	wav.data = byte_array
	return wav

static func create_shahed_dive_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 2.2
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var progress := t / duration
		# Accelerating high-RPM motor pitch rising from 110Hz to 380Hz + piercing siren undertone
		var motor_f := 110.0 + progress * progress * 290.0
		var motor := sin(t * motor_f * TAU) * 0.5 + sin(t * motor_f * 2.0 * TAU) * 0.35
		var howl_f := 420.0 + progress * 680.0
		var howl := sin(t * howl_f * TAU) * 0.3
		var wind := (randf() * 2.0 - 1.0) * 0.25 * progress
		var amp := clampf(0.3 + progress * 0.7, 0.0, 1.0)
		var sample := clampf((motor + howl + wind) * amp * 0.85, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_shahed_explosion_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.8
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var env := exp(-t * 2.8)
		# Deep sub-bass boom (42Hz down to 22Hz)
		var boom := sin(t * (42.0 - t * 12.0) * TAU) * 0.85 * env
		# Mid blast crunch
		var crunch := (randf() * 2.0 - 1.0) * exp(-t * 7.5) * 0.75
		# Low rumble tail
		var rumble := sin(t * 30.0 * TAU) * (randf() * 0.4) * exp(-t * 1.8)
		var sample := clampf(boom + crunch + rumble, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

# --- VODKA & ARMOR SOUNDS ---

static func create_vodka_drink_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.0
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var sample := 0.0
		# 0.0 - 0.18: Cork pop "POP!"
		if t < 0.18:
			var pop_env := exp(-t * 32.0)
			var pop := sin(t * 480.0 * TAU) * pop_env * 0.9
			sample += pop
		# 0.20 - 0.70: Liquid glug/gulp
		if t >= 0.20 and t < 0.75:
			var gt := t - 0.20
			var glug_period := fmod(gt, 0.15)
			var glug_env := sin((glug_period / 0.15) * PI)
			var glug := sin(gt * 320.0 * TAU) * glug_env * 0.55
			sample += glug
		# 0.75 - 1.0: Glass clink / sigh
		if t >= 0.75:
			var ct := t - 0.75
			var clink_env := exp(-ct * 18.0)
			var clink := (sin(ct * 2400.0 * TAU) + sin(ct * 3600.0 * TAU) * 0.4) * clink_env * 0.45
			sample += clink
			
		sample = clampf(sample, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_heavy_armor_equip_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.65
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		# Heavy vest strap click + ceramic thud
		var thud := sin(t * 60.0 * TAU) * exp(-t * 9.0) * 0.8
		var buckle := 0.0
		if t > 0.18 and t < 0.40:
			var bt := t - 0.18
			buckle = (sin(bt * 1100.0 * TAU) + sin(bt * 1750.0 * TAU) * 0.6) * exp(-bt * 30.0) * 0.7
		var rustle := (randf() * 2.0 - 1.0) * exp(-t * 12.0) * 0.25
		var sample := clampf(thud + buckle + rustle, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_armor_plate_insert_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.55
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		# Plate slide into pouch + velcro tear/press
		var slide := sin(t * 180.0 * TAU) * exp(-t * 8.0) * 0.4
		var velcro := (randf() * 2.0 - 1.0) * 0.35 * exp(-absf(t - 0.25) * 16.0)
		var snap := 0.0
		if t > 0.35:
			var st := t - 0.35
			snap = sin(st * 950.0 * TAU) * exp(-st * 28.0) * 0.7
		var sample := clampf(slide + velcro + snap, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav


static func create_van_engine_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 2.5
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var rpm := lerpf(60.0, 140.0, clampf(t / 2.0, 0.0, 1.0))
		var cyl := sin(t * rpm * TAU) * 0.45 + sin(t * rpm * 2.0 * TAU) * 0.3 + sin(t * rpm * 4.0 * TAU) * 0.15
		var rumble := (randf() * 2.0 - 1.0) * 0.08
		var sample := clampf((cyl + rumble) * 0.65, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav

static func create_van_horn_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.45
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var tone1 := sin(t * 370.0 * TAU) * 0.5
		var tone2 := sin(t * 440.0 * TAU) * 0.45
		var env := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var sample := clampf((tone1 + tone2) * env * 0.7, -1.0, 1.0)
		var val16 := int(sample * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav
static func create_van_reverse_beep() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.5
	var total_samples := int(mix_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var cycle := fmod(t, 0.45)
		var beep_active := 1.0 if cycle < 0.22 else 0.0
		var tone := sin(t * 1050.0 * TAU) * 0.45
		var sample := tone * beep_active
		var val16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = byte_array
	return wav