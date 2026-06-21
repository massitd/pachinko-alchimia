extends Node

var shot_score := 0
var round_score := 0
var shot_mult := 1

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
	
	
func _on_peg_hit(peg) -> void:
	shot_score += peg.peg_type.score_value
	Events.score_changed.emit(shot_score, round_score)
	
	shot_mult += peg.peg_type.mult
	Events.mult_changed.emit(shot_mult)

func _on_resolve_turn() -> void:
	if level_done:
		return
	round_score += shot_score * shot_mult
	shot_score = 0
	shot_mult = 1
	Events.score_changed.emit(shot_score, round_score)
	Events.mult_changed.emit(shot_mult)
	if round_score >= goal:
		level_done = true
		print("goal reached")
		Events.level_complete.emit(round_score)
