extends Node

enum State { POTION_AIMING, POTION_ACTIVE, RESOLVING_POTIONS, BALL_AIMING, BALL_ACTIVE, RESOLVING_SCORE, ROUND_OVER }
var state = State.POTION_AIMING

@onready var potion_queue = $"../PotionQueue"
@onready var ball_queue = $"../BallQueue"

## Manual-testing override. Assign actual .tres resources in the inspector —
## e.g. eight copies of basic_ball.tres, a couple of hot potions. If an array
## is non-empty it is used for this level instead of RunState's inventory; if
## empty, the level is seeded from RunState.owned_balls / owned_potions.
@export var starting_balls: Array[BallType] = []
@export var starting_potions: Array[PotionType] = []

var won = false


func _ready() -> void:
	Events.ball_lost.connect(_on_ball_lost)
	Events.ball_fired.connect(_on_ball_fired)
	Events.level_complete.connect(_on_level_won)
	Events.potion_fired.connect(_on_potion_fired)
	Events.potion_shattered.connect(_on_potion_shattered)

	# Level reads up from run tier: copy the permanent inventory into this
	# level's queues. The queues get consumed as things fire; RunState's arrays
	# are never touched, so nothing needs to write back (see RunState for what
	# to do if that ever becomes a depleting inventory).
	var balls := starting_balls if not starting_balls.is_empty() else RunState.owned_balls
	var potions := starting_potions if not starting_potions.is_empty() else RunState.owned_potions
	for ball_type in balls:
		ball_queue.queue_item(ball_type)
	for potion_type in potions:
		potion_queue.queue_item(potion_type)

	Events.balls_changed.emit.call_deferred(ball_queue.remaining())

	# Skip straight to the reactant phase if there's nothing queued to throw —
	# also skips the (not yet modeled) placement phase, since contraptions
	# don't exist yet either.
	if not potion_queue.has_next():
		_change_state(State.BALL_AIMING)


func _on_ball_fired(ball) -> void:
	if state == State.BALL_AIMING:
		_change_state(State.BALL_ACTIVE)

func _on_ball_lost(ball) -> void:
	if state == State.BALL_ACTIVE:
		_change_state(State.RESOLVING_SCORE)

func _on_potion_fired(_potion) -> void:
	if state == State.POTION_AIMING:
		_change_state(State.POTION_ACTIVE)

func _on_potion_shattered(_potion_type, _position) -> void:
	if state == State.POTION_ACTIVE:
		_change_state(State.RESOLVING_POTIONS)

# called to change the state
func _change_state(new_state) -> void:
	state = new_state
	Events.state_changed.emit(new_state)
	match new_state:
		State.RESOLVING_SCORE:
			_resolve_round()
		State.RESOLVING_POTIONS:
			_resolve_potions()
		State.BALL_AIMING, State.POTION_AIMING:
			pass

func _on_level_won(_score) -> void:
	won = true

# called when it is time to score shot
func _resolve_round() -> void:
	# trigger the even to resolve the turn, in another script
	Events.resolve_turn.emit()
	
	Events.balls_changed.emit(ball_queue.remaining())
	
	if won:
		return
	
	if not ball_queue.has_next():
		Events.game_over.emit()
	
	else:
		_change_state(State.BALL_AIMING)

# Nothing to score here yet — potions don't hit pegs the way balls do. This
# just decides whether there's another potion to aim, or whether the potion
# phase is over and it's time for the reactant phase. Add a placement-phase
# state here once contraptions exist.
func _resolve_potions() -> void:
	if potion_queue.has_next():
		_change_state(State.POTION_AIMING)
	else:
		_change_state(State.BALL_AIMING)
	
	
func can_shoot() -> bool:
	return state == State.BALL_AIMING and ball_queue.has_next()

func can_fire_potion() -> bool:
	return state == State.POTION_AIMING
