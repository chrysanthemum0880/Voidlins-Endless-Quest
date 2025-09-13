extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	print("player fell off platform")
	# Use call_deferred to reload scene safely
	call_deferred("reload_scene_safely")

func reload_scene_safely():
	get_tree().reload_current_scene()
