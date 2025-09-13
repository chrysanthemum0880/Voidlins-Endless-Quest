extends CharacterBody2D

@onready var animated_sprite = $acidsplashsprite
@onready var collision_shape = $CollisionShape2D
@onready var damage_area = $damagearea
@onready var damage_collision = $damagearea/dmgcollision
var lifetime = 1.5
var direction: Vector2
var speed = 300
var damage = 20

#play fireball animation
func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("acid splash")

	if damage_area:
		damage_area.area_entered.connect(_on_damagearea_entered)

	#start lifetime timer
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_expired)
	add_child(timer)
	timer.start()

func initialize(start_pos: Vector2, fire_direction: Vector2):
	global_position = start_pos
	direction = fire_direction.normalized()

	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()

	# Check for collisions
	if get_slide_collision_count() > 0:
		_on_collision()

func _on_damagearea_entered(area: Area2D) -> void:
	# Check if the area belongs to an enemy
	var enemy = area.get_parent()
	if enemy.has_method("take_dmg"):
		print("acid splash hit enemy for ", damage, " damage!")
		enemy.take_dmg(damage)
		_on_collision() 

#handle collision
func _on_collision():
	print("acid splash hit something!")
	queue_free()

#destroy acid splash
func _on_lifetime_expired():
	queue_free()
