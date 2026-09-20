extends RigidBody2D
class_name Potion

## Assigned per-instance in the inspector, same convention as peg.gd's peg_type.
@export var potion_type: PotionType

@onready var _sprite: Node2D = $potion
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _shattered: bool = false

# Where the potion was launched from; its sprite's top always points back here.
var _launch_origin: Vector2
var _sprite_rest_pos: Vector2


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_launch_origin = global_position
	_sprite_rest_pos = _sprite.position

	if potion_type and _sprite is CanvasItem:
		_sprite.modulate = Alchemy.color_for_quality(potion_type.quality)


# The body tumbles under physics, but the sprite is re-aimed every frame so the
# top of the bottle points back at the launcher.
func _process(_delta: float) -> void:
	if _shattered:
		return
	var facing := (_launch_origin - global_position).angle() + PI / 2.0
	_sprite.global_rotation = facing
	# Keep the sprite's resting offset "above" it in that facing, not the body's.
	_sprite.position = _sprite_rest_pos.rotated(facing - global_rotation)


# Generic hook the launcher's deploy logic calls without needing to know this
# is specifically a PotionType — any scene that wants to be queue-deployable
# implements this the same way.
func set_deploy_type(type: PotionType) -> void:
	potion_type = type
	if _sprite is CanvasItem:
		_sprite.modulate = Alchemy.color_for_quality(type.quality)


func _on_body_entered(_body: Node) -> void:
	# Shatters on first contact with anything — peg or wall. If potions should
	# only break on pegs specifically, filter here (e.g. `if _body is Peg`).
	if _shattered:
		return
	_shatter()


func _shatter() -> void:
	_shattered = true

	if potion_type == null:
		push_warning("Potion shattered with no potion_type assigned — skipping fluid burst.")
	else:
		var pool = get_tree().get_first_node_in_group("potion_fluid_pool")
		if pool:
			pool.register_splash(
				global_position,
				potion_type.splash_radius,
				potion_type.quality,
				potion_type.push_per_particle
			)
		else:
			push_warning("No PotionFluidPool found in the 'potion_fluid_pool' group — splash skipped.")

	_finish()


## Called by the launcher's kill zone when a potion falls out of the board
## without touching anything. There's no splash, but the turn phase still has
## to end — otherwise StateManager waits forever in POTION_ACTIVE.
func fall_out() -> void:
	if _shattered:
		return
	_shattered = true
	_finish()


func _finish() -> void:
	Events.potion_shattered.emit(potion_type, global_position)

	_sprite.hide()
	set_deferred("freeze", true)
	_collision.set_deferred("disabled", true)
	queue_free()
