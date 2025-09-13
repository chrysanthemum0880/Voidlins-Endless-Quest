extends CharacterBody2D
class_name player

#variables-------------------------------------------
@export var speed = 200
@export var jump_speed = -400
@export var gravity = 300 *  9.8
@export_range(0.0, 1.0) var friction = 0.32
@export_range(0.0 , 1.0) var acceleration = 0.32
@onready var animated_sprite = $AnimatedSprite2D
@onready var playerhitbox = $playerhitbox
const jump_power = -350
const FIREBALL_SCENE = preload("res://Scenes/spells/FIREBALL_SCENE.tscn")
const BURNINGCLAWS_SCENE = preload("res://Scenes/spells/BURNINGCLAWS_SCENE.tscn")
const CROWNOFMADNESS_SCENE = preload("res://Scenes/spells/CROWNOFMADNESS_SCENE.tscn")
const TOLLTHEDEAD_SCENE = preload("res://Scenes/spells/TOLLTHEDEAD_SCENE.tscn")
const ACIDSPLASH_SCENE = preload("res://Scenes/spells/ACIDSPLASH_SCENE.tscn")
const BONECHILL_SCENE = preload("res://Scenes/spells/BONECHILL_SCENE.tscn")
var is_jumping: bool = false
var is_attacking: bool = false
var attack_type: String
var current_attack: bool
var weapon_equip: bool
var health = 100
var health_max = 100
var health_min = 0
var dead: bool = false
var taking_damage: bool = false
var can_take_damage: bool = true
var attack_cooldown_timer: float = 0.0
var attack_cooldown_duration: float = 0.5

#end variables----------------------------------------

func _ready():
	Global.playerBody = self
	current_attack = false
	dead = false
	
	# Connect the area_entered signal for AREAS, not bodies
	playerhitbox.area_entered.connect(_on_playerhitbox_area_entered)

func _physics_process(delta: float) -> void:
	weapon_equip = Global.playerWeaponEquip

	# REMOVED: The old openmenu input - now handled globally by OptionsManager
	# The ESC key will now open the global options menu from anywhere
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			current_attack = false
			print("Attack cooldown finished")
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if !dead:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_speed

		# Movement
		var direction := Input.get_axis("walk left", "walk right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

		# Attacks
		if weapon_equip and !current_attack and attack_cooldown_timer <= 0:
			if Input.is_action_just_pressed("fireball") or Input.is_action_just_pressed("burning claws") or Input.is_action_just_pressed("crown of madness") or Input.is_action_just_pressed("toll the dead") or Input.is_action_just_pressed("acid splash") or Input.is_action_just_pressed("bone chill"):
				current_attack = true
				attack_cooldown_timer = attack_cooldown_duration
				print("Starting attack, cooldown: ", attack_cooldown_duration)
				if Input.is_action_just_pressed("fireball") and is_on_floor():
					attack_type = "fireball"
				elif Input.is_action_just_pressed("burning claws") and is_on_floor():
					attack_type = "burning claws"
				elif Input.is_action_just_pressed("crown of madness") and is_on_floor():
					attack_type = "crown of madness"
				elif Input.is_action_just_pressed("toll the dead") and is_on_floor():
					attack_type = "toll the dead"
				elif Input.is_action_just_pressed("acid splash") and is_on_floor():
					attack_type = "acid splash"
				elif Input.is_action_just_pressed("bone chill") and is_on_floor():
					attack_type = "bone chill"
				handle_attack_animation(attack_type)
		
		handle_movement_animation(direction)
	
	move_and_slide()

# FIXED: Use area_entered instead of body_entered and add proper filtering
func _on_playerhitbox_area_entered(area: Area2D) -> void:
	print("Area entered player hitbox: ", area.name, " from parent: ", area.get_parent().name)
	
	# Check if it's an enemy damage area
	var parent = area.get_parent()
	if parent is voidenemy and area.name == "voiddealdmg":
		print("Enemy damage area detected!")
		take_damage(parent.dmg_deal)
	else:
		print("Not an enemy damage area - ignoring")

#damage function
func take_damage(damage_amount: int):
	if !can_take_damage or dead or taking_damage:
		print("Cannot take damage right now")
		return
	
	health -= damage_amount
	taking_damage = true
	can_take_damage = false
	
	print("Player took ", damage_amount, " damage. Health now: ", health)
	
	# Play hit animation once and wait for it to finish
	animated_sprite.play("hit")
	await animated_sprite.animation_finished
	
	if health <= health_min:
		health = health_min
		dead = true
		print("Player died!")
		dying()
	else:
		# Reset taking_damage first so animations can resume normally
		taking_damage = false
		# Brief invincibility period after hit animation
		await get_tree().create_timer(0.5).timeout
		can_take_damage = true
		print("Player can take damage again")

#death handling
func dying():
	if dead:
		animated_sprite.play("death")  # Use existing animation
		velocity.x = 0
		print("Player is dying...")
		await get_tree().create_timer(2.0).timeout
		handle_death()

func handle_death():
	Global.startgame = false
	print("Reloading scene...")
	get_tree().change_scene_to_file("res://Scenes/gamestart.tscn")

func handle_movement_animation(dir):
	if dead or taking_damage:  # Don't play movement animations while taking damage
		return
		
	if !weapon_equip:
		if is_on_floor():
			if velocity.x == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
				toggle_flip_sprite(dir)
		elif !is_on_floor():
			animated_sprite.play("jump")
	if weapon_equip:
		if is_on_floor() and !current_attack:
			if velocity.x == 0:
				animated_sprite.play("wpnidle")
			else:  
				animated_sprite.play("wpnrun")
				toggle_flip_sprite(dir)
		elif !is_on_floor() and !current_attack:
			animated_sprite.play("wpnjump")

func toggle_flip_sprite(direction):
	if direction == 1:
		animated_sprite.flip_h = false
	if direction == -1:
		animated_sprite.flip_h = true

func handle_attack_animation(attack_type):
	if weapon_equip:
		if current_attack:
			match attack_type:
				"fireball":
					spawn_fireball()
				"burning claws":
					spawn_burningclaws()
				"crown of madness":
					spawn_crownofmadness()
				"toll the dead":
					spawn_tollthedead()
				"acid splash":
					spawn_acidsplash()
				"bone chill":
					spawn_bonechill()

# Your spell casting functions remain the same...
func spawn_fireball():
	var fireball = FIREBALL_SCENE.instantiate()
	get_tree().current_scene.add_child(fireball)
	
	var spawn_offset = Vector2(50, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	fireball.initialize(spawn_position, fire_direction)
	print("Fireball spawned!")

func spawn_burningclaws():
	var burningclaws = BURNINGCLAWS_SCENE.instantiate()
	get_tree().current_scene.add_child(burningclaws)
	
	var spawn_offset = Vector2(30, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	burningclaws.initialize(spawn_position, fire_direction)
	print("burning claws spawned!")

func spawn_crownofmadness():
	var crownofmadness = CROWNOFMADNESS_SCENE.instantiate()
	get_tree().current_scene.add_child(crownofmadness)
	
	var spawn_offset = Vector2(40, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	crownofmadness.initialize(spawn_position, fire_direction)
	print("crown of madness spawned!")

func spawn_tollthedead():
	var tollthedead = TOLLTHEDEAD_SCENE.instantiate()
	get_tree().current_scene.add_child(tollthedead)
	
	var spawn_offset = Vector2(40, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	tollthedead.initialize(spawn_position, fire_direction)
	print("toll the dead spawned!")

func spawn_acidsplash():
	var acidsplash = ACIDSPLASH_SCENE.instantiate()
	get_tree().current_scene.add_child(acidsplash)
	
	var spawn_offset = Vector2(40, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	acidsplash.initialize(spawn_position, fire_direction)
	print("acid splash spawned!")

func spawn_bonechill():
	var bonechill = BONECHILL_SCENE.instantiate()
	get_tree().current_scene.add_child(bonechill)
	
	var spawn_offset = Vector2(40, -10)
	if animated_sprite.flip_h:
		spawn_offset.x *= -1
	
	var spawn_position = global_position + spawn_offset
	
	var fire_direction = Vector2.RIGHT
	if animated_sprite.flip_h:
		fire_direction = Vector2.LEFT
	
	bonechill.initialize(spawn_position, fire_direction)
	print("bonechill spawned!")
