extends Node2D

@export var state_manager: Node

const BALL = preload("res://Scenes/objects/balls/ball.tscn")

var last_valid_angle: float = 0.0
var angle_min = -PI / 2
var angle_max = PI / 2
var aim_weight = 10
var impulse = 700

# variables for the trajectory
var ball_radius := 8
var ball_bounce := 0.8
var max_bounces:= 1
var trajectory_steps := 150
var stub_steps := 12

var _cast_shape := CircleShape2D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_cast_shape.radius = ball_radius
	
	Events.state_changed.connect(_on_state_changed)
	_aim_visibility()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var aim_pos = get_global_mouse_position()
	## where the cannon needs to point, by mouse position
	var target_angle = $cannon.global_position.angle_to_point(aim_pos) - PI / 2
	var wrapped_angle = wrapf(target_angle, -PI, PI)

	if wrapped_angle >= angle_min and wrapped_angle <= angle_max:
		last_valid_angle = wrapped_angle
	
	$cannon.rotation = lerp_angle($cannon.rotation, last_valid_angle, aim_weight*delta)
	
	if state_manager.can_shoot():
		update_trajectory()
	
func _on_state_changed(new_state) -> void:
	_aim_visibility()

# enables and disables aiming ui based on state 
func _aim_visibility() -> void:
	if state_manager and state_manager.can_shoot():
		$marker.visible = true
		$AimLine.visible = true
	else:
		$marker.visible = false
		$AimLine.visible = false
	
func get_launch_direction() -> Vector2:
	return Vector2(cos($cannon.rotation + PI / 2), sin($cannon.rotation + PI / 2))

## creates trajectory for aiming line
func update_trajectory() -> void:
	var points = []
	var pos = $cannon/ball_spawn.global_position
	var velocity = get_launch_direction() * impulse
	var gravity_vec = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var dt = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	var space = get_world_2d().direct_space_state

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = _cast_shape
	params.collision_mask = 1

	$marker.visible = false
	points.append(to_local(pos))

	# phase 1: flight until first contact (or out of steps)
	for i in range(trajectory_steps):
		velocity += gravity_vec * dt
		var motion = velocity * dt

		params.transform = Transform2D(0, pos)
		params.motion = motion
		var cast = space.cast_motion(params)

		if cast[0] < 1.0:
			var contact_pos = pos + motion * cast[0]
			points.append(to_local(contact_pos))
			$marker.global_position = contact_pos
			$marker.visible = true

			# phase 2: short reflected stub to hint the bounce direction
			params.transform = Transform2D(0, pos + motion * cast[1])
			var rest = space.get_rest_info(params)
			if not rest.is_empty():
				var normal: Vector2 = rest["normal"]
				var out_velocity = velocity - (1.0 + ball_bounce) * velocity.dot(normal) * normal
				var stub_pos = contact_pos + normal * 0.5
				for j in range(stub_steps):
					out_velocity += gravity_vec * dt
					stub_pos += out_velocity * dt
					points.append(to_local(stub_pos))
			break

		pos += motion
		points.append(to_local(pos))

	$AimLine.points = points
	
func _input(event):
	if event is InputEventMouseButton:
		if state_manager and state_manager.can_shoot():
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				spawn_ball()

## Fires balls from launcher
func spawn_ball() -> void:
	
	# create new instance of ball scene
	var ball = BALL.instantiate()
	
	# set where ball appears
	ball.position = $cannon/ball_spawn.global_position
	get_parent().add_child(ball)
	
	# calculate direction as vector
	var direction = Vector2(cos($cannon.rotation + PI / 2), sin($cannon.rotation + PI / 2))
	
	# push ball
	ball.apply_impulse(direction * impulse)
	
	Events.ball_fired.emit(ball)

## Kills balls that enter the bottom of the screen
func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		body.queue_free()
		Events.ball_lost.emit(body)
