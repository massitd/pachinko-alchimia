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
signal peg_hit(peg: Node2D)
signal peg_rehit(peg: Node2D)
signal ball_lost(ball: Node2D)
signal ball_fired(ball: Node2D)
signal resolve_turn()
signal game_over()
