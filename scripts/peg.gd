extends StaticBody2D
class_name Peg

enum State { UNHIT, HIT, CLEARED }

# temperature: hot = positive, cold = negative
# moisture:    dry = positive, wet  = negative
var state := State.UNHIT
var temperature := 0.0
var moisture := 0.0

const CAP := 1.0

@export var peg_type: PegType

# --- fluid sampling ----------------------------------------------------------

## How far a peg reaches out to sample fluid particles.
@export var wetting_radius: float = 24.0

## How often to sample (seconds).
@export var sample_interval: float = 0.1

var _sample_accum := 0.0


func _ready() -> void:
	Events.resolve_turn.connect(_resolve)
	_refresh_visual()


func _process(delta: float) -> void:
	_sample_accum += delta
	if _sample_accum < sample_interval:
		return
	var dt := _sample_accum
	_sample_accum = 0.0
	_sample_fluids(dt)


func _sample_fluids(dt: float) -> void:
	var pool = get_tree().get_first_node_in_group("potion_fluid_pool")
	if pool == null:
		return
	var result: Dictionary = pool.sample_push(global_position, wetting_radius)
	if result.is_empty():
		return
	apply_quality(result["quality"], result["count"] * result["push_rate"] * dt)


# --- quality model -----------------------------------------------------------

# Derived from the two meters; single source of truth, never stored.
# NEUTRAL until BOTH axes are off-center (a hot-but-not-dry peg isn't Fire yet).
func get_element() -> Alchemy.Element:
	if is_zero_approx(temperature) or is_zero_approx(moisture):
		return Alchemy.Element.NEUTRAL
	if temperature > 0.0:
		return Alchemy.Element.FIRE if moisture > 0.0 else Alchemy.Element.AIR
	else:
		return Alchemy.Element.EARTH if moisture > 0.0 else Alchemy.Element.WATER


func get_magnitude() -> float:
	return sqrt(temperature * temperature + moisture * moisture)


# The single entry point for every meter change.
func apply_quality(quality: Alchemy.Quality, amount: float) -> void:
	match quality:
		Alchemy.Quality.HOT:  temperature += amount
		Alchemy.Quality.COLD: temperature -= amount
		Alchemy.Quality.DRY:  moisture += amount
		Alchemy.Quality.WET:  moisture -= amount
	temperature = clampf(temperature, -CAP, CAP)
	moisture = clampf(moisture, -CAP, CAP)
	_refresh_visual()


# --- visuals -----------------------------------------------------------------

# Peg-specific: element colors plus the peg_type fallback for NEUTRAL, so this
# stays here rather than moving wholesale into Alchemy (which only knows
# about qualities/elements in the abstract, not a particular peg's resting
# color). Worth revisiting if Alchemy grows an Element color helper later.
func _color_for_element(e: Alchemy.Element) -> Color:
	match e:
		Alchemy.Element.FIRE:  return Color("e8462a")  # warm red
		Alchemy.Element.WATER: return Color("2a7de8")  # blue
		Alchemy.Element.EARTH: return Color("5aa657")  # green
		Alchemy.Element.AIR:   return Color("dfe9f0")  # pale steam
		_:                     return peg_type.color if peg_type else Color.WHITE  # NEUTRAL → resting color


func _refresh_visual() -> void:
	if not peg_type:
		return
	var target := _color_for_element(get_element())
	var t := clampf(get_magnitude(), 0.0, 1.0)
	$Peg.modulate = peg_type.color.lerp(target, t)


func peg_flash() -> void:
	var tween := create_tween()
	tween.tween_property($Peg, "modulate", Color.GOLD, 0.01)
	if state == State.HIT:
		tween.tween_property($Peg, "modulate", peg_type.color.darkened(0.5), 0.3).set_delay(0.1)
	else:
		tween.tween_property($Peg, "modulate", peg_type.color, 0.2).set_delay(0.1)


# --- hit / lifecycle ---------------------------------------------------------

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	if state == State.UNHIT:
		state = State.HIT
		Events.peg_hit.emit(self)
		peg_flash()
	elif state == State.HIT:
		Events.peg_rehit.emit(self)
		peg_flash()


func clear() -> void:
	if state != State.HIT:
		return
	state = State.CLEARED
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := get_tree().create_tween()
	tween.tween_property($Peg, "modulate", Color.TRANSPARENT, 0.5)


func _resolve() -> void:
	clear()
