extends Node2D

## Floating "+N" score and "+N mult" numbers that rise from a peg when a ball
## scores on it. Pure presentation: it only listens to Events.hit_scored.

const RISE := 48.0
const LIFETIME := 0.8
const JITTER := 8.0

const SCORE_COLOR := Color("ffffff")
const OPPOSITE_COLOR := Color("ffb340")  # boosted hit
const MULT_COLOR := Color("5ad7ff")


func _ready() -> void:
	Events.hit_scored.connect(_on_hit_scored)


func _on_hit_scored(peg: Node2D, points: int, mult_gain: int, relationship: int, chain: int) -> void:
	if not is_instance_valid(peg):
		return
	var origin := peg.global_position + Vector2(randf_range(-JITTER, JITTER), -14.0)

	var score_color := OPPOSITE_COLOR if relationship == Alchemy.Relationship.OPPOSITE else SCORE_COLOR
	_spawn("+%d" % points, origin, score_color, 22)
	if mult_gain > 0:
		var text := "+%d mult" % mult_gain
		if chain > 0:
			text += "  chain ×%d" % chain
		_spawn(text, origin + Vector2(0, -22), MULT_COLOR, 18)


func _spawn(text: String, at: Vector2, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	# Size is only known after the text is set; center the label on `at`.
	label.reset_size()
	label.global_position = at - label.size / 2.0

	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - RISE, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)
	tween.chain().tween_callback(label.queue_free)
