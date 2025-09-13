extends Control

func _ready():
	# Start main menu music when scene loads
	Bgm.play_music(Bgm.MusicTrack.mainmenu, false)

func _on_playbutton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/gamestart.tscn")

func _on_quitbutton_pressed() -> void:
	get_tree().quit()

func _on_loadbutton_pressed() -> void:
	pass # Replace with function body.

func _on_optionbutton_pressed() -> void:
	# Use the global options manager instead of loading a separate scene
	OptionsManager.show_options_menu()
