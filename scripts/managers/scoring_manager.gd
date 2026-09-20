extends Node

var shot_score := 0
var round_score := 0
var shot_mult := 1

# Global chain multiplier (design doc §5): each consecutive SAME-element hit
# adds CHAIN_STEP; any other relationship breaks it back to CHAIN_BASE. It
# stacks on top of shot_mult (the flat mult authored on peg types), so a break
# never wipes out mult-peg gains. Resets every shot.
const CHAIN_BASE := 0
const CHAIN_STEP := 1
var chain_mult := CHAIN_BASE

# Direct-hit value multiplier per relationship, applied to the peg's base value.
const VALUE_FACTOR := {
	Alchemy.Relationship.NEUTRAL: 1.0,
	Alchemy.Relationship.SAME: 1.0,
	Alchemy.Relationship.ADJACENT: 1.0,
	Alchemy.Relationship.OPPOSITE: 1.5,
}

var current_world = GameFlow.current_world
var current_screen = GameFlow.current_screen

var goal := 0

var level_done = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.peg_hit.connect(_on_peg_hit)
	Events.resolve_turn.connect(_on_resolve_turn)
	
	var screen_data = GameFlow.worlds[GameFlow.current_world]["screens"][GameFlow.current_screen]
	goal = screen_data.get("target", 0)
	Events.goal_set.emit.call_deferred(goal)
	
	
func _on_peg_hit(peg, ball) -> void:
	var ball_element := Alchemy.Element.NEUTRAL
	if ball is Ball and ball.ball_type:
		ball_element = ball.ball_type.element
	var relationship := Alchemy.relationship(ball_element, peg.get_element())

	var points := roundi(peg.peg_type.score_value * VALUE_FACTOR[relationship])
	shot_score += points
	Events.score_changed.emit(shot_score, round_score)

	var mult_gain: int = peg.peg_type.mult
	if relationship == Alchemy.Relationship.SAME:
		chain_mult += CHAIN_STEP
		mult_gain += CHAIN_STEP
	else:
		chain_mult = CHAIN_BASE

	shot_mult += peg.peg_type.mult
	Events.mult_changed.emit(_total_mult())
	Events.hit_scored.emit(peg, points, mult_gain, relationship, chain_mult)


func _total_mult() -> int:
	return shot_mult + chain_mult


func _on_resolve_turn() -> void:
	if level_done:
		return
	round_score += shot_score * _total_mult()
	shot_score = 0
	shot_mult = 1
	chain_mult = CHAIN_BASE
	Events.score_changed.emit(shot_score, round_score)
	Events.mult_changed.emit(_total_mult())
	if round_score >= goal:
		level_done = true
		print("goal reached")
		Events.level_complete.emit(round_score)
