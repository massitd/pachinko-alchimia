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

# Count-delta crediting: each fluid particle pushes this peg once per splash.
var _credited_splash_id := -1
var _credited_count := 0
var _flash_tween: Tween

# --- element particles -------------------------------------------------------
## Seconds for an element's particles to fade fully in or out.
const PARTICLE_FADE_TIME := 0.6

# Current fade weight (0..1) per element; only the peg's current element is
# ever emitting, the rest just finish fading out.
var _particle_weights := {}
var _particles := {}


func _ready() -> void:
	Events.resolve_turn.connect(_resolve)
	_particles = {
		Alchemy.Element.FIRE:  get_node_or_null("FireParticles"),
		Alchemy.Element.WATER: get_node_or_null("WaterParticles"),
		Alchemy.Element.EARTH: get_node_or_null("EarthParticles"),
		Alchemy.Element.AIR:   get_node_or_null("AirParticles"),
	}
	for e in _particles:
		_particle_weights[e] = 0.0
	_refresh_visual()


func _process(delta: float) -> void:
	_update_particles(delta)
	if state == State.CLEARED:
		return
	_sample_accum += delta
	if _sample_accum < sample_interval:
		return
	_sample_accum = 0.0
	_sample_fluids()


func _sample_fluids() -> void:
	var pool = get_tree().get_first_node_in_group("potion_fluid_pool")
	if pool == null:
		return
	var result: Dictionary = pool.sample_push(global_position, wetting_radius)
	if result.is_empty():
		return
	if result["splash_id"] != _credited_splash_id:
		_credited_splash_id = result["splash_id"]
		_credited_count = 0
	var new_particles: int = result["count"] - _credited_count
	if new_particles <= 0:
		return
	apply_quality(result["quality"], new_particles * result["push_per_particle"])
	_credited_count = result["count"]


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

# Fades each element's particle system toward its target: the current element
# (scaled by magnitude) is 1, every other one is 0. Only the current element
# emits, so at most one system is ever active; a previous one just fades out.
func _update_particles(delta: float) -> void:
	var active := get_element() if state != State.CLEARED else Alchemy.Element.NEUTRAL
	var step := delta / PARTICLE_FADE_TIME
	for e in _particles:
		var node: GPUParticles2D = _particles[e]
		if node == null:
			continue
		var target := clampf(get_magnitude(), 0.0, 1.0) if e == active else 0.0
		var w := move_toward(_particle_weights[e], target, step)
		_particle_weights[e] = w
		node.emitting = e == active
		node.modulate.a = w
		node.visible = w > 0.0

# Peg-specific: element colors plus the peg_type fallback for NEUTRAL, so this
# stays here rather than moving wholesale into Alchemy (which only knows
# about qualities/elements in the abstract, not a particular peg's resting
# color). Worth revisiting if Alchemy grows an Element color helper later.
func _color_for_element(e: Alchemy.Element) -> Color:
	match e:
		Alchemy.Element.FIRE:  return Color("e8462a")  # warm red
		Alchemy.Element.WATER: return Color("2a7de8")  # blue
		Alchemy.Element.EARTH: return Color("5aa657")  # green
		Alchemy.Element.AIR:   return Color("b1c9d9ff")  # pale steam
		_:                     return peg_type.color if peg_type else Color.WHITE  # NEUTRAL → resting color


# Single-axis pegs (only heated, only wetted, ...) have no Element yet, but they
# should still visibly react — tint toward the color of whichever quality is
# strongest. Once both axes are off-center, get_element() takes over.
func _tint_color() -> Color:
	var element := get_element()
	if element != Alchemy.Element.NEUTRAL:
		return _color_for_element(element)
	if abs(temperature) >= abs(moisture):
		return Alchemy.color_for_quality(Alchemy.Quality.HOT if temperature > 0.0 else Alchemy.Quality.COLD)
	return Alchemy.color_for_quality(Alchemy.Quality.DRY if moisture > 0.0 else Alchemy.Quality.WET)


# What the sprite should show right now, meters and hit state included. Both
# _refresh_visual() and the hit flash settle to this, so neither undoes the other.
func _display_color() -> Color:
	var color := peg_type.color.lerp(_tint_color(), clampf(get_magnitude(), 0.0, 1.0))
	return color.darkened(0.5) if state == State.HIT else color


func _refresh_visual() -> void:
	# A cleared peg is fading out; a flashing one settles to _display_color()
	# itself when done, so don't fight either tween.
	if not peg_type or state == State.CLEARED or (_flash_tween and _flash_tween.is_running()):
		return
	$Peg.modulate = _display_color()


func peg_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property($Peg, "modulate", Color.GOLD, 0.01)
	# Evaluated live, so meter changes during the fade are picked up.
	var settle_time := 0.3 if state == State.HIT else 0.2
	_flash_tween.tween_method(func(w: float): $Peg.modulate = Color.GOLD.lerp(_display_color(), w), 0.0, 1.0, settle_time).set_delay(0.1)


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
	if _flash_tween:
		_flash_tween.kill()
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := get_tree().create_tween()
	tween.tween_property($Peg, "modulate", Color.TRANSPARENT, 0.5)


func _resolve() -> void:
	clear()
