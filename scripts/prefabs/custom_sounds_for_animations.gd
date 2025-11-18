extends AudioStreamPlayer3D

@export var sounds: Dictionary[String, AudioStream]

# if rand pitch is 1 it will randomize it in the range -1 1
func play_sound(_name: String, volume: int, rand_pitch: float = 0.0):
	self.stop()
	self.stream = sounds.get(_name)
	self.volume_db = volume
	
	if rand_pitch > 0.0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		self.pitch_scale = rng.randf_range( max(0.8 - rand_pitch, 0.0), min(0.84 + rand_pitch, 4.0))
	else:
		self.pitch_scale = 1.0
	self.play()

func stop_playing() -> void:
	self.stop()
