extends RigidBody2D
class_name Ball

## Set by the launcher via set_deploy_type(), or per-instance in the inspector.
@export var ball_type: BallType

var stuck_time := 0.0
var stuck_threshold := 5.0
var speed_threshold := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ball")


# Generic hook the launcher's _deploy() calls, same convention as Potion.
func set_deploy_type(type: BallType) -> void:
	ball_type = type


func _physics_process(delta: float) -> void:
	if linear_velocity.length() < speed_threshold:
		stuck_time += delta
		if stuck_time >= stuck_threshold:
			_die()
	else:
		stuck_time = 0.0

func _die() -> void:
	Events.ball_lost.emit(self)
	queue_free()
