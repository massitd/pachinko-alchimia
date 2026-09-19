extends RigidBody2D
class_name Potion

## Assigned per-instance in the inspector, same convention as peg.gd's peg_type.
@export var potion_type: PotionType

@onready var _sprite: Node2D = $potion
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _shattered: bool = false


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

	if potion_type and _sprite is CanvasItem:
		_sprite.modulate = Alchemy.color_for_quality(potion_type.quality)


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

	Events.potion_shattered.emit(potion_type, global_position)

	_sprite.hide()
	set_deferred("freeze", true)
	_collision.set_deferred("disabled", true)
	queue_free()
