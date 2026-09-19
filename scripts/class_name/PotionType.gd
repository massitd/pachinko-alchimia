@tool
class_name PotionType
extends Resource

@export var scene: PackedScene

@export var quality: Alchemy.Quality = Alchemy.Quality.HOT

## Flat, one-time amount this potion pushes a peg's meter per fluid particle
## the peg is near. Each particle pays out once per splash, so a splash's total
## effect on a peg caps at (particles it was ever near) * push_per_particle.
@export var push_per_particle: float = 0.01

## Radius (world units) of the fluid burst at shatter.
@export var splash_radius: float = 40.0
