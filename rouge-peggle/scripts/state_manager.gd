extends Node

enum State { AIMING, BALL_ACTIVE, RESOLVING, ROUND_OVER }

var state = State.AIMING


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.ball_lost.connect(_on_ball_lost)
	Events.ball_fired.connect(_on_ball_fired)

func _on_ball_fired(ball) -> void:
	if state == State.AIMING:
		_change_state(State.BALL_ACTIVE)

# called when ball is killed
func _on_ball_lost(ball) -> void:
	if state == State.BALL_ACTIVE:
		_change_state(State.RESOLVING)

# called to change the state
func _change_state(new_state) -> void:
	state = new_state
	Events.state_changed.emit(new_state)
	match new_state:
		State.RESOLVING:
			_resolve_round()
		State.AIMING:
			pass

# called when it is time to score shot
func _resolve_round() -> void:
	# trigger the even to resolve the turn, in another script
	Events.resolve_turn.emit()
	
	# todo: add a check if there are balls remaining
	_change_state(State.AIMING)
	
func can_shoot() -> bool:
	return state == State.AIMING
