@tool
class_name PotionType
extends Resource

# NOTE: Quality is duplicated here for now rather than pulled from the planned
# Alchemy class (which doesn't exist yet). Once alchemy.gd exists with shared
# Quality/Element enums, this should reference that instead of redeclaring it.
enum Quality { HOT, COLD, WET, DRY }

@export var quality: Quality = Quality.HOT
@export var color: Color = Color.RED

## How much this potion pushes a peg's meter per second, per fluid particle
## a peg detects within its wetting radius. Tune low — a peg sitting in a
## dense splash should ramp up over real time, not slam to max in one frame.
@export var push_rate: float = 0.5

## Radius (world units) of the initial fluid burst at shatter.
@export var splash_radius: float = 40.0
