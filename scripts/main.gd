extends Node2D


const TILE_MARGIN: float = 4.0
const ANIMATION_SPEED: float = 1000.0

@onready
var ui_box: VBoxContainer = $VBoxContainer

@onready
var h_label: Label = $VBoxContainer/HLabel

@onready
var score_label: Label = $VBoxContainer/ScoreLabel

@onready
var ai_controller: AIController = AIController.new(AIController.H_CUSTOM)

var tiles: Dictionary = {}

var anim_queue: Array[Callable]


var game_state: GameState

var animating: bool = false
var interactive: bool = true

func _ready() -> void:
	game_state = GameState.new(4, 3);
	game_state.tile_added.connect(_on_tile_spawn);
	game_state.tile_moved.connect(_on_tile_move);
	game_state.init(4, 3);
	game_state.spawn_starting_tiles()
	
	var win_size = ((TILE_MARGIN+Tile.TILE_SIZE)*game_state.get_grid_size())+TILE_MARGIN
	get_window().size = Vector2i(floori(win_size), floori(win_size)+52)
	ui_box.position = Vector2(0, win_size)
	ui_box.size.x = win_size

func _on_tile_spawn(pos: Vector2i, value: int) -> void:
	var t: Tile = Tile.new(value);
	tiles[get_tile_key(pos)] = t
	t.position = get_tile_position(pos)
	add_child(t)

func _on_tile_move(prev_pos: Vector2i, new_pos: Vector2i) -> void:
	var tile: Tile = tiles[get_tile_key(prev_pos)]
	tile.target_position = get_tile_position(new_pos)
	anim_queue.append(tile.animate_to)
	

func get_tile_key(pos: Vector2i) -> int:
	return (game_state.get_grid_size() * pos.y) + pos.x;

func get_tile_position(pos: Vector2i) -> Vector2:
	return (pos*Vector2i(TILE_MARGIN+Tile.TILE_SIZE,TILE_MARGIN+Tile.TILE_SIZE)) + Vector2i(TILE_MARGIN,TILE_MARGIN)


func on_action(action: int) -> void:
	if (action in game_state.get_valid_actions()):
		animating = true
		game_state.apply_action(action)
		
		while !anim_queue.is_empty():
			var c: Callable = anim_queue.pop_front()
			c.call()
		
		
func do_ai_action() -> void:
	var action: int = ai_controller.pick_move(game_state)
	on_action(action)

func on_animation_finish() -> void:
	for key in tiles.keys():
		var tile: Tile = tiles[key]
		remove_child(tile)
		tile.queue_free()
		tiles.erase(key)

	score_label.text = "Score: %s"%game_state.score
	h_label.text = "H: %s"%ai_controller.evaluation_function(game_state)
	
	for x in game_state.get_grid_size():
		for y in game_state.get_grid_size():
			if (game_state.get_grid().get_at(x,y) > 0):
				_on_tile_spawn(Vector2i(x,y), game_state.get_grid().get_at(x,y))
			
	if (!game_state.board_full()):
		game_state.spawn_tile()

func _draw() -> void:
	var offset = Vector2((TILE_MARGIN as float)/4.0, (TILE_MARGIN as float)/4.0)
	for x in game_state.get_grid_size():
		for y in game_state.get_grid_size():
			draw_rect(
				Rect2(Vector2(get_tile_position(Vector2i(x,y)))-offset, Vector2(Tile.TILE_SIZE, Tile.TILE_SIZE)+(offset*2)),
				Color.WEB_GRAY
			)

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
				
