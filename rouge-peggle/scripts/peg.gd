extends Node

enum State { UNHIT, HIT, CLEARED }
var state:= State.UNHIT

@export var state_manager: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.resolve_turn.connect(_resolve)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# flashes the peg
func peg_flash():
		var tween = get_tree().create_tween()
		tween.tween_property($Peg, "modulate", Color.GOLD, 0.01)	
		tween.tween_property($Peg, "modulate", Color.LIGHT_SALMON, 0.2).set_delay(0.1)
		if state == State.HIT:
			tween.tween_property($Peg, "modulate", Color.DARK_SLATE_GRAY, 0.3).set_delay(0.2)

# happens when a ball hits a the peg
func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	if state == State.UNHIT:
		state = State.HIT
		Events.peg_hit.emit(self)
		peg_flash()
	elif state == State.HIT:
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
