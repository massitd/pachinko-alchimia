@tool
class_name BallType
extends Resource

@export var scene: PackedScene

## Reactant element (design doc §5). Scoring compares this to the element of
## each peg the ball hits via Alchemy.relationship().
@export var element: Alchemy.Element = Alchemy.Element.NEUTRAL

@export var color: Color = Color.WHITE
