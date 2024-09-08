extends Node2D

@export var gravity := Vector2(0, 1000)
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1
@export var jump_speed := 300.0
@export var stop_accel := 11.2
@export var move_accel := 25
@export var skid_accel := 15
@export var momentum_accel := 4
@export var start_speed := 100
@export var max_speed := 300
@export var air_multiplier := 0.65

@onready var body : AnimatableBody2D = %Body
@onready var anim : AnimatedSprite2D = %Anim

var velocity := Vector2()
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var grounded := false
var skidding := false

func _ready():
	anim.play("idle")

func landed():
	velocity.y = 0
	grounded = true

func _process(delta):
	if grounded:
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false

		if skidding:
			anim.play("skid")
		else:
			if velocity.x != 0:
				anim.play("run")
			else:
				anim.play("idle")
	else:
		if velocity.y > 0:
			anim.play("falling")
	

func _physics_process(delta):
	grounded = !!body.move_and_collide(Vector2.DOWN, true)
	velocity += gravity * delta

	coyote_timer -= delta
	jump_buffer_timer -= delta

	if grounded:
		coyote_timer = coyote_time
	
	if Input.is_action_just_pressed("Jump"):
		anim.play("jump")
		jump_buffer_timer = jump_buffer_time
		print("jump_buffer_timer: {0}, coyote_timer: {1}".format([jump_buffer_timer, coyote_timer]))
	
	if Input.is_action_just_released("Jump") && velocity.y < 0:
		velocity.y *= 0.5
		coyote_timer = 0
		jump_buffer_timer = 0
	
	if coyote_timer > 0 && jump_buffer_timer > 0:
		velocity.y = -jump_speed
		grounded = false


	var speed = velocity.x
	var horizontal = Input.get_axis("Left", "Right")
	var accel = stop_accel
	var target_speed = 0.0
	skidding = false
	if abs(horizontal) > 0:
		accel = move_accel
		if sign(velocity.x) == -sign(horizontal):
			accel = skid_accel
			skidding = true
		elif abs(speed) > start_speed: accel = momentum_accel
		target_speed = max_speed * sign(horizontal);

	if !grounded: accel *= air_multiplier

	print("accel: %s" % accel)
	speed = move_toward(speed, target_speed, accel)

	velocity.x = speed

	move(velocity * delta, func(): velocity.x = 0, landed)

func move(amount: Vector2, hit_x: Callable, hit_y: Callable):
	if abs(amount.x) > 0:
		var collision = body.move_and_collide(Vector2(amount.x, 0))
		if collision:
			hit_x.call()
	
	if abs(amount.y) > 0:
		var collision = body.move_and_collide(Vector2(0, amount.y))
		if collision:
			hit_y.call()
