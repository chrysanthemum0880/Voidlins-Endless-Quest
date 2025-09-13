extends CharacterBody2D

class_name voidenemy

#variables-------------------------------------------------
const speed = 80
@onready var voiddealdmg = $voiddealdmg
@onready var edge_detector = $EdgeDetector  # Add this raycast node
var is_void_chase: bool = true
var health = 80
var health_max = 80
var health_min = 0
var dead: bool = false
var taking_dmg: bool = false
var dmg_deal = 20
var is_dealing_dmg: bool = false
var dir: Vector2
const gravity = 900
var knockback_force = -20
var is_roaming: bool = true
var player: CharacterBody2D
var player_in_area = false
var voidattack: bool
#endvariables-----------------------------------------------

func _ready():
	# Connect the area_entered signal for the damage area
	voiddealdmg.area_entered.connect(_on_voiddealdmg_area_entered)
	
	# Setup edge detector raycast
	setup_edge_detector()

func setup_edge_detector():
	# Create raycast if it doesn't exist
	if not has_node("EdgeDetector"):
		edge_detector = RayCast2D.new()
		edge_detector.name = "EdgeDetector"
		add_child(edge_detector)
	
	# Configure the raycast to point downward from front of enemy
	edge_detector.target_position = Vector2(0, 50)  # Cast 50 pixels down
	edge_detector.enabled = true
	edge_detector.collision_mask = 1  # Adjust based on your ground layer

#functions--------------------------------------------------

#creates movement for enemy
func _process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0

	player = Global.playerBody
	
	# Update edge detector position based on movement direction
	update_edge_detector()

	move(delta)
	handle_animation()
	move_and_slide()

func update_edge_detector():
	if edge_detector and !dead:
		# Position the raycast at the front edge of the enemy based on direction
		var offset_distance = 20  # Distance from center to edge
		if dir.x > 0:  # Moving right
			edge_detector.position.x = offset_distance
		elif dir.x < 0:  # Moving left
			edge_detector.position.x = -offset_distance

func check_for_edge() -> bool:
	# Returns true if there's an edge (no ground) ahead
	if edge_detector and !dead and is_on_floor():
		return !edge_detector.is_colliding()
	return false

#determines movement if dead
func move(delta):
	if !dead:
		if !is_void_chase:
			# Check for edge before moving
			if check_for_edge():
				# Turn around at edge
				dir.x *= -1
				velocity.x = 0  # Stop current movement
			else:
				velocity += dir * speed * delta
				
		elif is_void_chase and !taking_dmg:
			var dir_to_player = position.direction_to(player.position) * speed
			
			# Only move toward player if not at an edge, or if player is behind us
			if !check_for_edge() or (dir_to_player.x * dir.x < 0):
				velocity.x = dir_to_player.x
				dir.x = abs(velocity.x) / velocity.x if velocity.x != 0 else dir.x
			else:
				# At edge and player is ahead - stop moving
				velocity.x = 0
				
		elif taking_dmg:
			var knockback_dir = position.direction_to(player.position) * knockback_force
			velocity.x = knockback_dir.x
		is_roaming = true
	elif dead:
		velocity.x = 0

# Rest of your existing functions remain the same...
func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_dmg and !is_dealing_dmg:
		anim_sprite.play("enemy1walk")
		if dir.x == -1:
			anim_sprite.flip_h = false
		elif dir.x == 1:
			anim_sprite.flip_h = true
	elif !dead and taking_dmg and !is_dealing_dmg:
		anim_sprite.play("enemy1dmg")
		await get_tree().create_timer(0.375).timeout
		taking_dmg = false
	elif dead and is_roaming:
		is_roaming = false
		anim_sprite.play("enemy1death")
		await get_tree().create_timer( 0.875).timeout
		handle_death()

func handle_death():
	self.queue_free()

func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = choose([1.5,2.0,2.5])
	if !is_void_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0

func choose(array):
	array.shuffle()
	return array.front()

func take_dmg(dmg):
	health -= dmg
	taking_dmg = true
	if health <= health_min:
		health = health_min
		dead = true

func _on_voiddealdmg_area_entered(area: Area2D) -> void:
	print("Something entered enemy damage area: ", area.name, " from parent: ", area.get_parent().name)
	
	var parent = area.get_parent()
	if parent == Global.playerBody and area.name == "playerhitbox":
		print("Player hitbox detected! Dealing damage...")
		parent.take_damage(dmg_deal)
	else:
		print("Not the player hitbox - ignoring")
