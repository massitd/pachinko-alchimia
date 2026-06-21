extends CanvasLayer

var target_shot := 0
var target_total := 0
var target_mult := 1
var displayed_shot_score := 0.0
var displayed_mult := 1.0
var displayed_round_score := 0.0
var tick_speed := 10.0

var balls_remaining := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.goal_set.connect(_on_goal_set)
	Events.balls_changed.connect(_on_balls_changed)
	Events.mult_changed.connect(_on_mult_changed)
	
func _on_goal_set(goal_value):
	$GoalScore.text = str(goal_value)
	
func _on_mult_changed(mult) -> void:
	target_mult = mult

func _on_score_changed(shot, round_total) -> void:
	target_shot = shot
	target_total = round_total
	
func _on_balls_changed(balls_remaining) -> void:
	$BallsRemaining.text = str(balls_remaining)
	
func _process(delta: float) -> void:
	displayed_shot_score = lerp(displayed_shot_score, float(target_shot), tick_speed * delta)
	displayed_round_score = lerp(displayed_round_score, float(target_total), tick_speed * delta)
	displayed_mult = lerp(displayed_mult, float(target_mult), tick_speed * delta)
	
	$ShotScore.text = str(int(round(displayed_shot_score)))
	$RoundScore.text = str(int(round(displayed_round_score)))
	$ShotMult.text = str(int(round(displayed_mult)))
