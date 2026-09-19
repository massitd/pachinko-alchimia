@tool
class_name BallType
extends Resource

@export var scene: PackedScene

# Reactant element (Fire/Water/Air/Earth, per the design doc's reaction model,
# §5) belongs here once that system exists. Nothing reads it yet — this
# exists now purely so balls fit the same list/queue shape as potions.
