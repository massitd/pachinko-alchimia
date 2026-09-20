extends RigidBody2D
class_name Ball

## Set by the launcher via set_deploy_type(), or per-instance in the inspector.
@export var ball_type: BallType

## Sprite tint for balls with no type or a NEUTRAL one (matches ball.tscn).
const NEUTRAL_COLOR := Color(0.9764706, 0.47058824, 0)

@onready var _sprite: Sprite2D = $Ball

var stuck_time := 0.0
var stuck_threshold := 5.0
var speed_threshold := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ball")
	_apply_color()


# Generic hook the launcher's _deploy() calls, same convention as Potion.
func set_deploy_type(type: BallType) -> void:
	ball_type = type
	# The launcher calls this before add_child(), so _sprite isn't ready yet;
	# _ready() applies the color in that case.
	if is_node_ready():
		_apply_color()


func _apply_color() -> void:
	var element := ball_type.element if ball_type else Alchemy.Element.NEUTRAL
	_sprite.modulate = Alchemy.color_for_element(element, NEUTRAL_COLOR)


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
