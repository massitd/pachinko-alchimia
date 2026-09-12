extends StaticBody2D

enum State { UNHIT, HIT, CLEARED }
enum Quality { HOT, COLD, DRY, WET }
enum Element { NEUTRAL, FIRE, EARTH, WATER, AIR }

# temperature: hot = positive, cold = negative
# moisture:    dry = positive, wet  = negative
var state := State.UNHIT
var temperature := 0.0
var moisture := 0.0

const CAP := 1.0

@export var peg_type: PegType


func _ready() -> void:
	Events.resolve_turn.connect(_resolve)
	_refresh_visual()


# --- quality model -----------------------------------------------------------

# Derived from the two meters; single source of truth, never stored.
# NEUTRAL until BOTH axes are off-center (a hot-but-not-dry peg isn't Fire yet).
func get_element() -> Element:
	if is_zero_approx(temperature) or is_zero_approx(moisture):
		return Element.NEUTRAL
	if temperature > 0.0:
		return Element.FIRE if moisture > 0.0 else Element.AIR
	else:
		return Element.EARTH if moisture > 0.0 else Element.WATER


func get_magnitude() -> float:
	return sqrt(temperature * temperature + moisture * moisture)


# The single entry point for every meter change.
func apply_quality(quality: Quality, amount: float) -> void:
	match quality:
		Quality.HOT:  temperature += amount
		Quality.COLD: temperature -= amount
		Quality.DRY:  moisture += amount
		Quality.WET:  moisture -= amount
	temperature = clampf(temperature, -CAP, CAP)
	moisture = clampf(moisture, -CAP, CAP)
	_refresh_visual()


# --- visuals -----------------------------------------------------------------

func _color_for_element(e: Element) -> Color:
	match e:
		Element.FIRE:  return Color("e8462a")  # warm red
		Element.WATER: return Color("2a7de8")  # blue
		Element.EARTH: return Color("5aa657")  # green
		Element.AIR:   return Color("dfe9f0")  # pale steam
		_:             return peg_type.color if peg_type else Color.WHITE


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
