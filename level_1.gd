extends Node2D

var current_wave: int
@export var enemy_1_scene = preload("res://Scenes/characters/enemy_1.tscn")
var starting_nodes: int
var current_nodes: int
var wave_spawn_ended: bool = false
var max_waves: int = 3 
var level_complete: bool = false

func _ready() -> void:
	Global.playerWeaponEquip = true
	Bgm.play_music(Bgm.MusicTrack.level_1)
	current_wave = 0
	Global.current_wave = current_wave
	starting_nodes = get_child_count()
	current_nodes = get_child_count()
	position_to_next_wave()

func _process(_delta):
	# Continuously check if enemies have been defeated
	update_node_count()
	check_wave_completion()

func update_node_count():
	current_nodes = get_child_count()

func check_wave_completion():
	# Check if all spawned enemies are defeated and wave spawn has ended
	if current_nodes == starting_nodes and wave_spawn_ended and !level_complete:
		if current_wave >= max_waves:
			# Level complete - transition to next level
			complete_level()
		else:
			# Move to next wave
			position_to_next_wave()

func position_to_next_wave():
	if current_nodes == starting_nodes:
		if current_wave != 0:
			Global.moving_to_next_wave = true
		wave_spawn_ended = false  # Reset for new wave
		current_wave += 1
		Global.current_wave = current_wave
		prepare_spawn("enemy_1", 3.0, 3.0) #type, multiplier, spawns
		print("Starting wave: ", current_wave)

func prepare_spawn(type, multiplier, mob_spawns):
	# Calculate enemies per wave: Wave 1 = 3, Wave 2 = 6, Wave 3 = 9, etc.
	var enemies_this_wave = current_wave * 3.0
	var mob_wait_time: float = 2.0
	print("Wave ", current_wave, " - Spawning ", enemies_this_wave, " enemies")
	
	# Calculate how many spawn rounds we need (3 enemies per round)
	var mob_spawn_rounds = enemies_this_wave / mob_spawns
	spawn_type(type, mob_spawn_rounds, mob_wait_time)

func spawn_type(type, mob_spawn_rounds, mob_wait_time):
	if type == "enemy_1":
		var enemy1spawn1 = $enemy1spawn1
		var enemy1spawn2 = $enemy1spawn2
		var enemy1spawn3 = $enemy1spawn3
		if mob_spawn_rounds >= 1:
			for i in mob_spawn_rounds:
				var enemy1 = enemy_1_scene.instantiate()
				enemy1.global_position = enemy1spawn1.global_position
				var enemy2 = enemy_1_scene.instantiate()
				enemy2.global_position = enemy1spawn2.global_position
				var enemy3 = enemy_1_scene.instantiate()
				enemy3.global_position = enemy1spawn3.global_position
				add_child(enemy1)
				add_child(enemy2)
				add_child(enemy3)
				mob_spawn_rounds -= 1 
		wave_spawn_ended = true

func complete_level():
	level_complete = true
	print("Level 1 Complete! Transitioning to Level 2...")
	
	# Optional: Add a brief delay before transition
	await get_tree().create_timer(2.0).timeout
	
	# Transition to level 2 using call_deferred for safety
	call_deferred("change_to_level_2")

func change_to_level_2():
	# Change to level 2 scene
	var next_scene = load("res://Scenes/level_2.tscn")
	get_tree().change_scene_to_packed(next_scene)
