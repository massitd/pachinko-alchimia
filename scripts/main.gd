extends Node

const GAME_OVER = preload("res://Scenes/menus/game_over.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameFlow.current_screen_holder = $CurrentScreen
	print("Main set holder: ", GameFlow.current_screen_holder, " id: ", GameFlow.current_screen_holder.get_instance_id())

	GameFlow.begin()
	
	Events.game_over.connect(_on_game_over)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_game_over() -> void:
	var popup = GAME_OVER.instantiate()
	add_child(popup)
