extends Node

enum State { UNHIT, HIT, CLEARED }
var state:= State.UNHIT

@export var peg_type: PegType


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.resolve_turn.connect(_resolve)
	if peg_type:
		$Peg.modulate = peg_type.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
