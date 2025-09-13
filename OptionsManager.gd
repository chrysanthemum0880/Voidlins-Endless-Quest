# OptionsManager.gd - Save this as an autoload/singleton
extends Node

var options_overlay = null
var is_initialized = false

func _ready():
	# Set up input handling globally
	set_process_input(true)

func _input(event):
	# Global ESC key handling for options menu
	if event.is_action_pressed("esc"):
		toggle_options_menu()

func initialize_options_overlay():
	if is_initialized:
		return
		
	# Create CanvasLayer for global UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "GlobalOptionsLayer"
	canvas_layer.layer = 128  # Maximum layer value
	
	# Add to the scene tree root so it persists across scenes
	get_tree().root.add_child(canvas_layer)
	
	# Create the overlay container
	options_overlay = Control.new()
	options_overlay.name = "OptionsOverlay"
	options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # Works when paused
	canvas_layer.add_child(options_overlay)
	
	# Add semi-transparent background
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.7)  # Semi-transparent
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.add_child(background)
	
	# Create the menu content
	create_options_menu_content()
	
	# Hide initially
	options_overlay.visible = false
	is_initialized = true
	print("Global options overlay initialized")

func create_options_menu_content():
	# Create a centered panel for the menu
	var menu_panel = Panel.new()
	menu_panel.name = "MenuPanel"
	
	# Set size and position manually for better control
	var panel_size = Vector2(450, 600)
	menu_panel.custom_minimum_size = panel_size
	menu_panel.size = panel_size
	
	# Get the viewport size and center the panel
	var viewport_size = get_viewport().get_visible_rect().size
	var center_pos = (viewport_size - panel_size) * 0.5
	menu_panel.position = center_pos
	
	# Set anchors to center but don't use preset to maintain manual positioning
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -panel_size.x * 0.5
	menu_panel.offset_top = -panel_size.y * 0.5
	menu_panel.offset_right = panel_size.x * 0.5
	menu_panel.offset_bottom = panel_size.y * 0.5
	
	options_overlay.add_child(menu_panel)
	
	# Create VBox for organizing buttons
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	menu_panel.add_child(vbox)
	
	# Add margin container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(inner_vbox)
	
	# Title
	var title = Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	inner_vbox.add_child(title)
	
	# Back to Game button
	var back_btn = Button.new()
	back_btn.text = "Back to Game"
	back_btn.custom_minimum_size.y = 40
	back_btn.pressed.connect(hide_options_menu)
	inner_vbox.add_child(back_btn)
	
	# Return to Main Menu button
	var returnbutton = Button.new()
	returnbutton.text = "Return to Main Menu"
	returnbutton.custom_minimum_size.y = 40
	returnbutton.pressed.connect(_on_returnbutton_pressed)
	inner_vbox.add_child(returnbutton)
	
	# Add a separator
	var separator1 = HSeparator.new()
	inner_vbox.add_child(separator1)
	
	# Resolution section
	var res_label = Label.new()
	res_label.text = "Resolution:"
	res_label.add_theme_font_size_override("font_size", 16)
	inner_vbox.add_child(res_label)
	
	var resolution_menu = OptionButton.new()
	resolution_menu.name = "ResolutionMenu"
	resolution_menu.custom_minimum_size.y = 40
	resolution_menu.add_item("1920x1080")
	resolution_menu.add_item("1600x900") 
	resolution_menu.add_item("1280x720")
	resolution_menu.item_selected.connect(_on_resolution_item_selected)
	inner_vbox.add_child(resolution_menu)
	
	# Add a separator
	var separator2 = HSeparator.new()
	inner_vbox.add_child(separator2)
	
	# Volume section
	var volume_label = Label.new()
	volume_label.text = "Master Volume:"
	volume_label.add_theme_font_size_override("font_size", 16)
	inner_vbox.add_child(volume_label)
	
	# Volume value display
	var volume_value_label = Label.new()
	volume_value_label.name = "VolumeValueLabel"
	volume_value_label.text = "100%"
	volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(volume_value_label)
	
	var volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.custom_minimum_size.y = 30
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 100
	volume_slider.step = 1
	volume_slider.value_changed.connect(_on_volume_changed)
	inner_vbox.add_child(volume_slider)
	
	# Mute checkbox
	var mute_check = CheckBox.new()
	mute_check.name = "MuteCheckbox"
	mute_check.text = "Mute Audio"
	mute_check.toggled.connect(_on_mute_toggled)
	inner_vbox.add_child(mute_check)

func toggle_options_menu():
	if not is_initialized:
		initialize_options_overlay()
	
	if options_overlay:
		var was_visible = options_overlay.visible
		options_overlay.visible = not was_visible
		
		# Re-center the menu when showing (in case window was resized)
		if options_overlay.visible:
			recenter_menu()
		
		# Better pause handling - always pause when menu is visible
		# The overlay is set to PROCESS_MODE_WHEN_PAUSED so it needs the game to be paused
		if options_overlay.visible:
			get_tree().paused = true
		else:
			get_tree().paused = false
		
		var current_scene = get_tree().current_scene
		var scene_name = current_scene.name.to_lower() if current_scene else ""
		
		print("Global options menu toggled. Visible: ", options_overlay.visible)
		print("Scene: ", scene_name, " - Paused: ", get_tree().paused)

func show_options_menu():
	if not is_initialized:
		initialize_options_overlay()
	
	if options_overlay:
		options_overlay.visible = true
		recenter_menu()  # Re-center when showing
		
		# Handle pausing
		var current_scene = get_tree().current_scene
		var scene_name = current_scene.name.to_lower() if current_scene else ""
		if not (scene_name.contains("menu") or scene_name.contains("gamestart")):
			get_tree().paused = true

func hide_options_menu():
	if options_overlay:
		options_overlay.visible = false
		get_tree().paused = false
		print("Options menu hidden and game unpaused")

# Function to recenter the menu (useful if window is resized)
func recenter_menu():
	if options_overlay:
		var menu_panel = options_overlay.find_child("MenuPanel", true, false)
		if menu_panel:
			var panel_size = Vector2(450, 600)
			# Update position based on current viewport size
			menu_panel.offset_left = -panel_size.x * 0.5
			menu_panel.offset_top = -panel_size.y * 0.5
			menu_panel.offset_right = panel_size.x * 0.5
			menu_panel.offset_bottom = panel_size.y * 0.5

# Button callbacks
func _on_volume_changed(value: float):
	# Convert 0-100 range to 0.0-1.0 for the audio system
	var volume_linear = value / 100.0
	Bgm.set_master_volume(volume_linear)
	
	# Update the volume display label
	if options_overlay:
		var volume_label = options_overlay.find_child("VolumeValueLabel", true, false)
		if volume_label:
			volume_label.text = str(int(value)) + "%"
	
	print("Volume set to: ", value, "% (", volume_linear, ")")

func _on_mute_toggled(toggled_on: bool):
	if toggled_on:
		Bgm.set_master_volume(0.0)
	else:
		# Get current slider value and apply it
		if options_overlay:
			var volume_slider = options_overlay.find_child("VolumeSlider", true, false)
			if volume_slider:
				var volume_linear = volume_slider.value / 100.0
				Bgm.set_master_volume(volume_linear)
			else:
				Bgm.set_master_volume(1.0)  # Fallback
	
	print("Audio muted: ", toggled_on)

func _on_resolution_item_selected(index: int) -> void:
	print("Resolution button clicked! Index: ", index)
	
	# Get current window mode
	var current_mode = DisplayServer.window_get_mode()
	print("Current window mode: ", current_mode)
	
	# First, force the window to windowed mode to enable resizing
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await get_tree().process_frame  # Wait for mode change
	
	# Enable resizing flags
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	await get_tree().process_frame  # Wait for flag changes
	
	var new_size: Vector2i
	match index:
		0:
			new_size = Vector2i(1920, 1080)
			print("Setting resolution to 1920x1080")
		1:
			new_size = Vector2i(1600, 900)
			print("Setting resolution to 1600x900")
		2:
			new_size = Vector2i(1280, 720)
			print("Setting resolution to 1280x720")
	
	# Try multiple methods to set the size
	print("Attempting to resize window...")
	
	# Method 1: Direct window resize
	DisplayServer.window_set_size(new_size)
	await get_tree().process_frame
	
	# Method 2: If that doesn't work, try get_window()
	if DisplayServer.window_get_size() != new_size:
		print("Method 1 failed, trying get_window().set_size()")
		get_window().set_size(new_size)
		await get_tree().process_frame
	
	# Method 3: Set viewport size as fallback
	if DisplayServer.window_get_size() != new_size:
		print("Method 2 failed, trying viewport resize")
		get_viewport().set_size(new_size)
		await get_tree().process_frame
	
	var final_size = DisplayServer.window_get_size()
	print("Final window size: ", final_size)
	
	if final_size == new_size:
		print("Resolution change successful!")
		
		# Center the window after successful resize
		var screen_size = DisplayServer.screen_get_size()
		var pos = (screen_size - final_size) / 2
		DisplayServer.window_set_position(pos)
		print("Window positioned at: ", DisplayServer.window_get_position())
		
		# Re-center the menu
		await get_tree().process_frame
		recenter_menu()
	else:
		print("Resolution change failed. Window may be in embedded mode.")

func _on_returnbutton_pressed() -> void:
	hide_options_menu()
	get_tree().change_scene_to_file("res://Scenes/interface/mainmenu.tscn")
