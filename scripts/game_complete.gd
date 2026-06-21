extends Node

func _on_menu_return_pressed() -> void:
	GameFlow.return_to_menu()
	print("back to menu pressed")
	queue_free()
