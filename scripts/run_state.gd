extends Node

## Run tier: persists across level swaps, same category as GameFlow. Holds what
## the player owns for the whole run; levels read it (StateManager copies it
## into the level-tier queues at level start) and never mutate it.
##
## Using a ball/potion in a level does NOT remove it from these arrays — the
## inventory is a permanent collection, like a deck in a card game. Only the
## level's queue contents get consumed. If that ever changes to a depleting
## inventory, the level should report it up through the bus (e.g.
## Events.potion_consumed) and RunState should listen — RunState must never
## reach down into level-tier nodes.

const HOT_POTION := preload("res://types/potion_types/fire_potion.tres")
const COLD_POTION := preload("res://types/potion_types/cold_potion.tres")
const BASIC_BALL := preload("res://types/ball_types/basic_ball.tres")

var owned_potions: Array[PotionType] = []
var owned_balls: Array[BallType] = []


func _ready() -> void:
	_seed_starting_inventory()


## Placeholder loadout until real acquisition (shop / drafts / rewards) exists.
func _seed_starting_inventory() -> void:
	owned_potions = [HOT_POTION, COLD_POTION]
	owned_balls = [BASIC_BALL, BASIC_BALL, BASIC_BALL]
