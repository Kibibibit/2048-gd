extends Node2D


const TILE_MARGIN: float = 4.0
const ANIMATION_SPEED: float = 1000.0

@onready
var score_label: Label = $Label

@onready
var ai_controller: AIController = AIController.new()

var tiles: Dictionary = {}

var current_game_state: GameState

var animating: bool = false
var current_action: int = GameState.INVALID_ACTION
var interactive: bool = true

func _ready() -> void:
	current_game_state = GameState.new()
	current_game_state.added_tile.connect(_on_tile_spawn)
	current_game_state.init()
	var win_size = ((TILE_MARGIN+Tile.TILE_SIZE)*GameState.GRID_SIZE)+TILE_MARGIN
	get_window().size = Vector2i(floori(win_size), floori(win_size)+24)
	score_label.position = Vector2(0, win_size)


func _on_tile_spawn(index: int, value: int) -> void:
	var t: Tile = Tile.new(index, value)
	tiles[t.get_instance_id()] = t
	t.position = get_tile_position(index)
	add_child(t)


func get_tile_position(index: int) -> Vector2:
	var grid_pos: Vector2 = Vector2(index % GameState.GRID_SIZE, floori((index as float)/GameState.GRID_SIZE))
	return (grid_pos*Vector2(TILE_MARGIN+Tile.TILE_SIZE,TILE_MARGIN+Tile.TILE_SIZE)) + Vector2(TILE_MARGIN,TILE_MARGIN)


func on_action(action: int) -> void:
	if (action in current_game_state.get_valid_actions()):
		current_action = action
		for _t in tiles.values():
			var tile: Tile = _t
			tile.animate_to(get_tile_position(current_game_state.get_new_tile_index(tile.index, action)))
		
		animating = true
		
func do_ai_action() -> void:
	var action: int = ai_controller.pick_move(current_game_state.duplicate())
	on_action(action)

func on_animation_finish(action: int) -> void:
	for key in tiles.keys():
		var tile: Tile = tiles[key]
		remove_child(tile)
		tiles.erase(key)
	current_game_state.added_tile.disconnect(_on_tile_spawn)
	current_game_state = current_game_state.get_successor_state(action)
	
	current_game_state.added_tile.connect(_on_tile_spawn)
	for index in current_game_state.grid.size():
		if (current_game_state.grid[index] > 0):
			_on_tile_spawn(index, current_game_state.grid[index])
	if (!current_game_state.board_full()):
		current_game_state.spawn_tile()

func _draw() -> void:
	var i = 0
	var offset = Vector2((TILE_MARGIN as float)/4.0, (TILE_MARGIN as float)/4.0)
	for x in GameState.GRID_SIZE:
		for y in GameState.GRID_SIZE:
			draw_rect(
				Rect2(get_tile_position(i)-offset, Vector2(Tile.TILE_SIZE, Tile.TILE_SIZE)+(offset*2)),
				Color.WEB_GRAY
			)
			i+=1

func _process(delta: float) -> void:
	score_label.text = "Score: %s"%current_game_state.score
	if (animating):
		var all_tiles_done: bool = true
		for _tile in tiles.values():
			var tile: Tile = _tile as Tile
			var done = tile.do_animation_tick(delta*ANIMATION_SPEED)
			if (!done):
				all_tiles_done = false
		if (all_tiles_done):
			animating = false
			on_animation_finish(current_action)
			current_action = GameState.INVALID_ACTION
	elif(!interactive):
		do_ai_action()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey && !animating && interactive):
		if (event.pressed):
			var action: int = GameState.INVALID_ACTION
			match (event.keycode):
				KEY_UP,KEY_W,KEY_K:
					action = GameState.ACTION_UP
				KEY_DOWN,KEY_S,KEY_J:
					action = GameState.ACTION_DOWN
				KEY_LEFT,KEY_A,KEY_H:
					action = GameState.ACTION_LEFT
				KEY_RIGHT,KEY_D,KEY_L:
					action = GameState.ACTION_RIGHT
				KEY_SPACE:
					interactive = false
			if (action != GameState.INVALID_ACTION):
				on_action(action)
				
