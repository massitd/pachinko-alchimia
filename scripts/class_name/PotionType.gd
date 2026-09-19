@tool
class_name PotionType
extends Resource

@export var scene: PackedScene

@export var quality: Alchemy.Quality = Alchemy.Quality.HOT

## How much this potion pushes a peg's meter per second, per fluid particle
## the peg is currently near. Tune low — a peg sitting in a dense splash
## should ramp up over real time, not slam to max in one frame.
@export var push_rate: float = 0.5

## Radius (world units) of the fluid burst at shatter.
@export var splash_radius: float = 40.0
