extends Area2D
class_name Potion

## Assigned per-instance in the inspector, same convention as peg.gd's peg_type.
@export var potion_type: PotionType

@onready var _fluid: Fluid2D = $Fluid2D
@onready var _sprite: Node2D = $Sprite2D  # swap for whatever the actual visual node is

var _shattered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Fluid starts with zero points — corked until shatter.
	_fluid.points = PackedVector2Array()

func _on_body_entered(body: Node) -> void:
	if _shattered:
		return
	if not body.is_in_group("ball"):
		return
	_shatter()

func _shatter() -> void:
	_shattered = true

	if potion_type == null:
		push_warning("Potion shattered with no potion_type assigned — skipping fluid burst.")
	else:
		_fluid.density = 1000.0  # water-ish; revisit per-quality if that matters later
		_fluid.create_circle_points(potion_type.splash_radius)
		# NOTE: verify Fluid2D exposes set_velocities() (symmetric to set_points()) —
		# confirmed in the docs: get_velocities() exists, get_points()/set_points() exist.
		# If set_velocities() isn't available, the burst will just start at rest and
		# let gravity/collisions do the work, which may be fine to start with.

		_fluid.add_to_group("active_fluids")
		_fluid.set_meta("quality", potion_type.quality)
		_fluid.set_meta("push_rate", potion_type.push_rate)

	# Reparent the fluid up to the level so it survives this node's queue_free().
	# Assumes the potion lives directly under the level tier — adjust the path
	# if potions end up nested deeper (e.g. under a PotionContainer).
	var level := get_parent()
	_fluid.reparent(level)

	Events.potion_shattered.emit(potion_type, global_position)

	_sprite.hide()
	set_deferred("monitoring", false)
	queue_free()
