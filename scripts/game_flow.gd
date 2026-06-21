extends Node

const SHOP_SCENE = 		preload("res://Scenes/menus/shop_menu.tscn")
const MENU_SCENE = 		preload("res://Scenes/menus/main_menu.tscn")
const DRAFT = 			preload("res://Scenes/menus/draft_menu.tscn")
const END_SCREEN = 		preload("res://Scenes/menus/game_complete.tscn")
const FIRST_SCREEN = 	preload("res://Scenes/menus/main_menu.tscn")

var current_screen_holder: Node



var worlds := [
	{ "name": "World 1", "screens": [
		{ "type": "level", "target": 100 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 110 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 130 },
		{ "type": "draft" },
		{ "type": "shop" },
	],
	"level_pool": [
			load("res://Scenes/Levels/w1_l1.tscn"),
			load("res://Scenes/Levels/w1_l2.tscn"),
			load("res://Scenes/Levels/w1_l3.tscn"),
	]},
	{ "name": "World 2", "screens": [
		{ "type": "level", "target": 200 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 210 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 230 },
		{ "type": "draft" },
		{ "type": "shop" },
	],
	"level_pool": [
			load("res://Scenes/Levels/w1_l1.tscn"),
			load("res://Scenes/Levels/w1_l2.tscn"),
			load("res://Scenes/Levels/w1_l3.tscn"),
	]},
	{ "name": "World 3", "screens": [
		{ "type": "level", "target": 300 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 310 },
		{ "type": "draft" },
		{ "type": "shop" },
		{ "type": "level", "target": 330 },
		{ "type": "draft" },
		{ "type": "shop" },
	],
	"level_pool": [
		load("res://Scenes/Levels/w1_l1.tscn"),
		load("res://Scenes/Levels/w1_l2.tscn"),
		load("res://Scenes/Levels/w1_l3.tscn"),
	]},
]

var current_world := 0
var current_screen := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.level_complete.connect(_on_level_complete)
	Events.screen_complete.connect(_on_screen_complete)

func _on_level_complete(_score) -> void:
	# wait a moment after beating a level before proceeding to next screen
	await get_tree().create_timer(1.5).timeout
	_advance.call_deferred()
	
func _on_screen_complete() -> void:
	_advance.call_deferred()

func _advance() -> void:
	print("advance running, screen: ", current_screen)
	current_screen += 1
	if current_screen >= worlds[current_world]["screens"].size():
		current_screen = 0
		current_world += 1
		if current_world >= worlds.size():
			_run_complete()
			return
	_load_screen()

func _load_screen() -> void:
	var screen_data = worlds[current_world]["screens"][current_screen]
	_swap_to(_scene_lookup(screen_data["type"]))
	
## this is where picking from the level pools will happen
func _scene_lookup(screen_type: String) -> PackedScene:
	match screen_type:
		"level":
			return _pick_level()
		"shop":
			return SHOP_SCENE
		"menu":
			return MENU_SCENE
		"draft":
			return DRAFT
		_:
			return null
			
func begin() -> void:
	_swap_to(FIRST_SCREEN)

func start_run() -> void:
	current_world = 0
	current_screen = 0
	_load_screen()
	
func _pick_level() -> PackedScene:
	var pool = worlds[current_world]["level_pool"]
	return pool[randi() % pool.size()]

## everything ultimately calls this
func _swap_to(scene: PackedScene) -> void:
	if current_screen_holder:
		print("  holder id: ", current_screen_holder.get_instance_id())
	if not scene:
		push_error("_swap_to got a null scene")
		return
	for child in current_screen_holder.get_children():
		child.queue_free()
	var new_screen = scene.instantiate()
	current_screen_holder.add_child(new_screen)

func _run_complete() -> void:
	_swap_to(END_SCREEN)
	
func _return_to_menu() -> void:
	_swap_to(MENU_SCENE)
	
func return_to_menu() -> void:
	print("return_to_menu called")
	current_world = 0
	current_screen = 0
	_swap_to(MENU_SCENE)
