# AudioManager autoload
extends Node

@onready var peg_hit_sound = $PegHitSound
@onready var peg_rehit_sound = $PegRehitSound
@onready var launch_sound = $LaunchSound

func _ready() -> void:
	Events.peg_hit.connect(_on_peg_hit)
	Events.ball_fired.connect(_on_ball_fired)
	Events.peg_rehit.connect(_on_peg_rehit)

func _on_peg_hit(peg) -> void:
	peg_hit_sound.pitch_scale = randf_range(0.9, 1.1)
	peg_hit_sound.volume_db = randf_range(-2.0, 0.0)
	peg_hit_sound.play()
	
func _on_peg_rehit(peg) -> void:
	peg_rehit_sound.pitch_scale = randf_range(0.8, 1.2)
	peg_rehit_sound.volume_db = randf_range(-3.0, -1.0)
	peg_rehit_sound.play()

func _on_ball_fired(ball) -> void:
	launch_sound.play()
