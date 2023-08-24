extends Node2D


const TILE_MARGIN: float = 4.0
const ANIMATION_SPEED: float = 1000.0

@onready
var score_label: Label = $Label

@onready
var ai_controller: AIController = AIController.new()

var tiles: Dictionary = {}

var game_state: GameState
var next_game_state: GameState

var animating: bool = false
var interactive: bool = true

func _ready() -> void:
	game_state = GameState.new()
	game_state.tile_added.connect(_on_tile_spawn);
	game_state.tile_moved.connect(_on_tile_move);
	game_state.init(4, 3);
	game_state.spawn_starting_tiles()
	
	var win_size = ((TILE_MARGIN+Tile.TILE_SIZE)*game_state.grid_size)+TILE_MARGIN
	get_window().size = Vector2i(floori(win_size), floori(win_size)+24)
	score_label.position = Vector2(0, win_size)


func _on_tile_spawn(index: int, value: int) -> void:
	var t: Tile = Tile.new(index, value)
	tiles[t.index] = t
	t.position = get_tile_position(index)
	add_child(t)

func _on_tile_move(current_index: int, new_index: int) -> void:
	var tile: Tile = tiles[current_index]
	tile.animate_to(get_tile_position(new_index))

func get_tile_position(index: int) -> Vector2:
	var grid_pos: Vector2 = Vector2(index % GameStateGD.GRID_SIZE, floori((index as float)/GameStateGD.GRID_SIZE))
	return (grid_pos*Vector2(TILE_MARGIN+Tile.TILE_SIZE,TILE_MARGIN+Tile.TILE_SIZE)) + Vector2(TILE_MARGIN,TILE_MARGIN)


func on_action(action: int) -> void:
	if (action in game_state.get_valid_actions()):
		animating = true
		next_game_state = game_state.get_successor_state(action)
		
		
func do_ai_action() -> void:
	#var action: int = ai_controller.pick_move(game_state.duplicate())
	on_action(0)

func on_animation_finish() -> void:
	for key in tiles.keys():
		var tile: Tile = tiles[key]
		remove_child(tile)
		tile.queue_free()
		tiles.erase(key)
	game_state.tile_added.disconnect(_on_tile_spawn)
	game_state.tile_moved.disconnect(_on_tile_move)
	game_state = next_game_state
	game_state.tile_added.connect(_on_tile_spawn)
	game_state.tile_moved.connect(_on_tile_move)
	score_label.text = "Score: %s"%game_state.score
	
	for index in game_state.grid_size*game_state.grid_size:
		if (game_state.get_at_index(index) > 0):
			_on_tile_spawn(index, game_state.get_at_index(index))
	if (!game_state.board_full()):
		game_state.spawn_tile()

func _draw() -> void:
	var i = 0
	var offset = Vector2((TILE_MARGIN as float)/4.0, (TILE_MARGIN as float)/4.0)
	for x in game_state.grid_size:
		for y in game_state.grid_size:
			draw_rect(
				Rect2(get_tile_position(i)-offset, Vector2(Tile.TILE_SIZE, Tile.TILE_SIZE)+(offset*2)),
				Color.WEB_GRAY
			)
			i+=1

func _process(delta: float) -> void:
	
	if (animating):
		var all_tiles_done: bool = true
		for _tile in tiles.values():
			var tile: Tile = _tile as Tile
			var done = tile.do_animation_tick(delta*ANIMATION_SPEED)
			if (!done):
				all_tiles_done = false
		if (all_tiles_done):
			animating = false
			on_animation_finish()
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
				
