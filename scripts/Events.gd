extends Node

# signals written at the level of their sender, not recipient 
# --- Run


# --- Game Flow
signal screen_complete(next_screen)
signal goal_set(goal)
signal screen_loaded()
signal game_won()

# --- Level
signal score_changed(shot_score, round_score)
signal mult_changed(shot_mult)
signal state_changed(new_state)
signal level_complete(result)
signal balls_changed(balls_reminaing: int)

# --- Turn
signal peg_hit(peg: Node2D, ball: Node2D)
signal peg_rehit(peg: Node2D, ball: Node2D)
## Emitted by ScoringManager once a direct hit has been scored. `relationship`
## is an Alchemy.Relationship; `mult_gain` is the mult this hit added (0 if none);
## `chain` is the chain multiplier after this hit (0 once it's broken).
signal hit_scored(peg: Node2D, points: int, mult_gain: int, relationship: int, chain: int)
signal ball_lost(ball: Node2D)
signal ball_fired(ball: Node2D)
signal potion_fired(potion: Node2D)
signal potion_shattered(potion: Node2D)
signal resolve_turn()
signal game_over()
