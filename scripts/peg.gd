extends StaticBody2D

enum State { UNHIT, HIT, CLEARED }
var state:= State.UNHIT

# hot pos/cold neg, dry pos/wet neg
var temperature := 0.0
var moisture := 0.0
enum Quality { HOT, COLD, DRY, WET }
enum Element { NEUTRAL, FIRE, EARTH, WATER, AIR }
var element := Element.NEUTRAL
var magnitude := 0.0

const CAP := 1.0

@export var peg_type: PegType


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.resolve_turn.connect(_resolve)
	if peg_type:
		$Peg.modulate = peg_type.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# function to determine which element the peg currently is
func get_element() -> Element:
	if is_zero_approx(temperature) or is_zero_approx(moisture):
		return Element.NEUTRAL
	if temperature > 0:
		return Element.FIRE if moisture > 0 else Element.AIR
	else:
		return Element.EARTH if moisture > 0 else Element.WATER

# function to determine the magnitudes of each element
func get_magnitude():
	return sqrt((temperature*temperature) + (moisture*moisture))
	
func apply_quality(quality: Quality, amount: float) -> void:
	match quality:
		Quality.HOT:  temperature += amount
		Quality.COLD: temperature -= amount
		Quality.DRY:  moisture += amount
		Quality.WET:  moisture -= amount
	temperature = clampf(temperature, -CAP, CAP)
	moisture = clampf(moisture, -CAP, CAP)
	_refresh_visual()

func _color_for_element(e: Element) -> Color:
	match e:
		Element.FIRE:  return Color("e8462a")  # warm red
		Element.WATER: return Color("2a7de8")  # blue
		Element.EARTH: return Color("5aa657")  # green
		Element.AIR:   return Color("dfe9f0")  # pale steam
		_:             return peg_type.color    # NEUTRAL → resting color

func _refresh_visual() -> void:
	var target := _color_for_element(get_element())
	var t := clampf(get_magnitude(), 0.0, 1.0)
	$Peg.modulate = peg_type.color.lerp(target, t)

# flashes the peg
func peg_flash():
	var tween = create_tween()
	tween.tween_property($Peg, "modulate", Color.GOLD, 0.01)
	if state == State.HIT:
		tween.tween_property($Peg, "modulate", peg_type.color.darkened(0.5), 0.3).set_delay(0.1)
	else:
		tween.tween_property($Peg, "modulate", peg_type.color, 0.2).set_delay(0.1)

# happens when a ball hits a the peg
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


# clears peg
func clear() -> void:
	if state != State.HIT:
		return
	state = State.CLEARED
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = get_tree().create_tween()
	tween.tween_property($Peg, 'modulate', Color.TRANSPARENT, 0.5)
	
func _resolve() -> void:
	clear()
