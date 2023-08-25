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

var n_game_state: BoardState

var animating: bool = false
var interactive: bool = true

func _ready() -> void:
	game_state = GameState.new()
	n_game_state = BoardState.new();
	n_game_state.tile_added.connect(_on_tile_spawn);
	n_game_state.tile_moved.connect(_on_tile_move);
	n_game_state.init(4, 3);
	n_game_state.spawn_starting_tiles()
	
	var win_size = ((TILE_MARGIN+Tile.TILE_SIZE)*n_game_state.get_grid_size())+TILE_MARGIN
	get_window().size = Vector2i(floori(win_size), floori(win_size)+24)
	score_label.position = Vector2(0, win_size)


func _on_tile_spawn(pos: Vector2i, value: int) -> void:
	var t: Tile = Tile.new(value);
	tiles[get_tile_key(pos)] = t
	t.position = get_tile_position(pos)
	add_child(t)

func _on_tile_move(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	var tile: Tile = tiles[get_tile_key(prev_pos)]
	tile.animate_to(get_tile_position(new_pos))

func get_tile_key(pos: Vector2i) -> int:
	return (n_game_state.get_grid_size() * pos.y) + pos.x;

func get_tile_position(pos: Vector2i) -> Vector2:
	return (pos*Vector2i(TILE_MARGIN+Tile.TILE_SIZE,TILE_MARGIN+Tile.TILE_SIZE)) + Vector2i(TILE_MARGIN,TILE_MARGIN)


func on_action(action: int) -> void:
	if (action in n_game_state.get_valid_actions()):
		animating = true
		n_game_state.apply_action(action)
		
		
func do_ai_action() -> void:
	#var action: int = ai_controller.pick_move(game_state.duplicate())
	on_action(0)

func on_animation_finish() -> void:
	for key in tiles.keys():
		var tile: Tile = tiles[key]
		remove_child(tile)
		tile.queue_free()
		tiles.erase(key)

	score_label.text = "Score: %s"%n_game_state.score
	
	for x in n_game_state.get_grid_size():
		for y in n_game_state.get_grid_size():
			if (n_game_state.get_grid().get_at(x,y) > 0):
				_on_tile_spawn(Vector2i(x,y), n_game_state.get_grid().get_at(x,y))
			
	if (!n_game_state.board_full()):
		n_game_state.spawn_tile()

func _draw() -> void:
	var i = 0
	var offset = Vector2((TILE_MARGIN as float)/4.0, (TILE_MARGIN as float)/4.0)
	for x in n_game_state.get_grid_size():
		for y in n_game_state.get_grid_size():
			
			draw_rect(
				Rect2(Vector2(get_tile_position(Vector2i(x,y)))-offset, Vector2(Tile.TILE_SIZE, Tile.TILE_SIZE)+(offset*2)),
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
				
