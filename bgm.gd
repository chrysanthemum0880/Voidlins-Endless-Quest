extends Node

# Reference to your AudioStreamPlayer nodes
@onready var Musicmainmenu_player: AudioStreamPlayer
@onready var Musicgamestart_player: AudioStreamPlayer 
@onready var Musiclvl1_player: AudioStreamPlayer

# Current playing track
var current_audio: AudioStreamPlayer
var target_audio: AudioStreamPlayer

# Fade settings
var fade_duration: float = 1.5
var is_fading: bool = false

# Music track enum for easy reference
enum MusicTrack {
	mainmenu,
	gamestart,
	level_1
}

func _ready():
	# Get references to your AudioStreamPlayer children
	# Adjust these names to match your actual node names in your scene
	Musicmainmenu_player = get_node("Musicmainmenu")
	Musicgamestart_player = get_node("Musicgamestart")  
	Musiclvl1_player = get_node("Musiclvl1")
	
	# Verify nodes were found
	if Musicmainmenu_player == null:
		print("ERROR: MainMenuMusic node not found!")
		return
	if Musicgamestart_player == null:
		print("ERROR: LobbyMusic node not found!")
		return
	if Musiclvl1_player == null:
		print("ERROR: Level1Music node not found!")
		return
	
	# Stop all players first to prevent auto-playing
	Musicmainmenu_player.stop()
	Musicgamestart_player.stop()
	Musiclvl1_player.stop()
	
	# Set all volumes to silent initially
	Musicmainmenu_player.volume_db = -80
	Musicgamestart_player.volume_db = -80
	Musiclvl1_player.volume_db = -80
	
	# Set autoplay to false for all players
	Musicmainmenu_player.autoplay = false
	Musicgamestart_player.autoplay = false
	Musiclvl1_player.autoplay = false
	
	# Set all to loop (only if stream exists)
	if Musicmainmenu_player.stream:
		Musicmainmenu_player.stream.loop = true
	if Musicgamestart_player.stream:
		Musicgamestart_player.stream.loop = true
	if Musiclvl1_player.stream:
		Musiclvl1_player.stream.loop = true
	
	print("BGM system initialized successfully")

# Main function to play music with fade transition
func play_music(track: MusicTrack, fade_out_current: bool = true):
	if is_fading:
		return # Prevent multiple fade operations
		
	# Get the target player - FIXED: Use the correct enum values
	match track:
		MusicTrack.mainmenu:
			target_audio = Musicmainmenu_player
		MusicTrack.gamestart:
			target_audio = Musicgamestart_player
		MusicTrack.level_1:
			target_audio = Musiclvl1_player
	
	# Don't do anything if same track is already playing
	if current_audio == target_audio and current_audio != null and current_audio.playing:
		return
	
	if fade_out_current and current_audio != null and current_audio.playing:
		# Fade out current, then fade in new
		fade_transition()
	else:
		# Just fade in new track
		fade_in_track()

# Fade transition between tracks
func fade_transition():
	if current_audio == null or target_audio == null:
		fade_in_track()
		return
		
	is_fading = true
	
	# Start the new track at volume 0
	target_audio.volume_db = -80
	target_audio.play()
	
	# Create tweens for fade out and fade in
	var tween_out = create_tween()
	var tween_in = create_tween()
	
	# FIXED: Correct tween method call - pass the audio node first, then the values
	tween_out.tween_method(func(vol): set_volume_db(current_audio, vol), 0, -80, fade_duration)
	
	# Fade in new track (start after a brief delay)
	tween_in.tween_interval(fade_duration * 0.3) # Small overlap
	tween_in.tween_method(func(vol): set_volume_db(target_audio, vol), -80, 0, fade_duration)
	
	# When fade out completes, stop the old track
	tween_out.tween_callback(func(): stop_track(current_audio))
	
	# When fade in completes, update current audio and reset fading flag
	tween_in.tween_callback(finish_transition)

# Fade in a track (no current track playing)
func fade_in_track():
	if target_audio == null:
		return
		
	is_fading = true
	
	# Stop any currently playing tracks
	stop_all_tracks()
	
	# Start new track at low volume
	target_audio.volume_db = -80
	target_audio.play()
	
	# Fade in - FIXED: Correct tween method call
	var tween = create_tween()
	tween.tween_method(func(vol): set_volume_db(target_audio, vol), -80, 0, fade_duration)
	tween.tween_callback(finish_transition)

# Helper function to set volume - FIXED: Takes audio node as parameter
func set_volume_db(audio_node: AudioStreamPlayer, volume: float):
	if audio_node != null:
		audio_node.volume_db = volume

# Stop a specific track
func stop_track(audio_node: AudioStreamPlayer):
	if audio_node != null and audio_node.playing:
		audio_node.stop()

# Stop all music tracks - FIXED: Use correct variable names
func stop_all_tracks():
	Musicmainmenu_player.stop()
	Musicgamestart_player.stop()
	Musiclvl1_player.stop()

# Finish the transition
func finish_transition():
	current_audio = target_audio
	is_fading = false
	print("Music transition completed: ", current_audio.stream.resource_path if current_audio else "None")

# Immediate stop (for special cases)
func stop_music_immediately():
	stop_all_tracks()
	current_audio = null
	is_fading = false

# Set master music volume (0.0 to 1.0)
func set_master_volume(volume: float, is_linear: bool = true):
	if current_audio != null:
		if is_linear:
			current_audio.volume_db = linear_to_db(volume)
		else:
			current_audio.volume_db = volume

# Get current playing track - FIXED: Use correct variable names and enum values
func get_current_track() -> MusicTrack:
	if current_audio == Musicmainmenu_player:
		return MusicTrack.mainmenu
	elif current_audio == Musicgamestart_player:
		return MusicTrack.gamestart
	elif current_audio == Musiclvl1_player:
		return MusicTrack.level_1
	else:
		return MusicTrack.mainmenu # Default
