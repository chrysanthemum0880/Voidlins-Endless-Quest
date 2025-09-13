extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.playerWeaponEquip = false

	# Play gamestart music with fade transition from previous track
	Bgm.play_music(Bgm.MusicTrack.gamestart)

func _on_startdetect_body_entered(body: Node2D) -> void:
	Global.startgame = true
	print("Body entered startdetect: ", body.name, " (type: ", body.get_class(), ")")

	# More robust player detection - check multiple conditions
	if body == Global.playerBody or (body.is_in_group("player")) or (body.name == "Player" and body is CharacterBody2D):
		print("Player detected! Changing scene...")
		# Fade to level 1 music before changing scene
		Bgm.play_music(Bgm.MusicTrack.level_1)
		# Use call_deferred to change scene safely
		call_deferred("change_scene_safely")
	else:
		print("Not the player body - ignoring. Body class: ", body.get_class())
		print("Global.playerBody is: ", Global.playerBody)
		print("Are they equal? ", body == Global.playerBody)

func change_scene_safely():
	# Try different methods depending on Godot version
	if get_tree().has_method("change_scene_to_file"):
		get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
	elif get_tree().has_method("change_scene"):
		get_tree().change_scene("res://Scenes/level_1.tscn")
	else:
		# Fallback method
		get_tree().change_scene_to_packed(load("res://Scenes/level_1.tscn"))
