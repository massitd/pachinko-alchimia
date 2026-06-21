extends Node

enum State { AIMING, BALL_ACTIVE, RESOLVING, ROUND_OVER }
var state = State.AIMING

var ball_count := 8

var won = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.ball_lost.connect(_on_ball_lost)
	Events.ball_fired.connect(_on_ball_fired)
	Events.balls_changed.emit.call_deferred(ball_count)
	Events.level_complete.connect(_on_level_won)


func _on_ball_fired(ball) -> void:
	ball_count -= 1
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
			
func _on_level_won(_score) -> void:
	won = true

# called when it is time to score shot
func _resolve_round() -> void:
	# trigger the even to resolve the turn, in another script
	Events.resolve_turn.emit()
	
	Events.balls_changed.emit(ball_count)
	
	if won:
		return
	
	if ball_count <= 0:
		Events.game_over.emit()
	
	else:
		_change_state(State.AIMING)
	
	
func can_shoot() -> bool:
	return state == State.AIMING and ball_count > 0
