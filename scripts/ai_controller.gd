extends RefCounted
class_name AIController

const MAX_DEPTH: int = 2

const H_SCORE: int = 0
const H_FREE_SPACE: int = 1
const H_MONOTINICITY: int = 2
const H_SNAKE_CHAIN: int = 3
const H_CUSTOM: int = 4

const NEIGHBOURS: Array[Vector2] = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]

var heuristic: int

var no_up: bool = true

func _init(p_heuristic: int):
	heuristic = p_heuristic

func get_player_successor_states(game_state: GameState) -> Array[GameState]:
	var out: Array[GameState] = []
	var actions = game_state.get_valid_actions()
	if (no_up):
		if (actions.size() > 1):
			var up_index = actions.find(GameState.ACTION_UP)
			if (up_index != -1):
					actions.remove_at(up_index)
	for action in actions:
		var state: GameState = game_state.duplicate()
		state.apply_action(action)
		out.append(state)
	return out


func evaluation_function(game_state: GameState) -> float:
	match (heuristic):
		H_SCORE:
			return game_state.score
		H_FREE_SPACE:
			return game_state.get_free_count()
		H_MONOTINICITY:
			return monotinicity(game_state)
		H_SNAKE_CHAIN:
			return snake_chain(game_state)
		H_CUSTOM:
			return custom(game_state)
		_:
			return 0


func snake_chain(game_state: GameState) -> float:
	var best: int = -1
	var grid: Grid2D = game_state.get_grid().duplicate()
	
	for i in 4:
		var current: int = 0
		var prev_tile: int = -1
		for _y in game_state.get_grid_size():
			var y: int = game_state.get_grid_size()-_y-1
			for x in game_state.get_grid_size():
				var tile_value = grid.get_at(x,y)
				if (prev_tile == -1):
					prev_tile = tile_value
				elif(prev_tile != 0):
					if (tile_value == (prev_tile as float)/2.0):
						current += 2
					elif (tile_value < prev_tile):
						current += 1
					
		if (current > best):
			best = current
		grid = grid.rotate()
	
	return best

func monotinicity(game_state: GameState) -> float:
	var best: float = -1
	var grid: Grid2D = game_state.get_grid().duplicate()
	if (game_state.get_free_count() < float(grid.size.x * grid.size.y)*0.35):
		return game_state.get_free_count()
	for i in 4:
		var current: float = 0
		
		for y in game_state.get_grid_size():
			for x in game_state.get_grid_size()-1:
				if (grid.get_at(x,y) >= grid.get_at(x+1,y)):
					current += 1
		for x in game_state.get_grid_size():
			for y in game_state.get_grid_size()-1:
				if (grid.get_at(x,y) >= grid.get_at(x,y+1)):
					current += 1
		if (current > best):
			best = current
		grid = grid.rotate()
	return best



func custom(game_state: GameState) -> float:
	var grid: Grid2D = game_state.get_grid().duplicate()
	var score: float = 0.0
	for y in game_state.get_grid_size():
		for x in game_state.get_grid_size():
			score +=  grid.get_at(x,y)*x*y
	return score*game_state.get_free_count()
	
func pick_move(game_state: GameState) -> int:
	var action : int = GameState.INVALID_ACTION as int
	var value:float = -INF
	
	var actions = game_state.get_valid_actions()
	if (no_up):
		if (actions.size() > 1):
			var up_index = actions.find(GameState.ACTION_UP)
			if (up_index != -1):
					actions.remove_at(up_index)
	
	for a in actions:
		var state: GameState = game_state.duplicate()
		state.apply_action(a)
		var new_value: float = expectimax(state, 0, false)
		if (new_value > value):
			value = new_value
			action = a as int
	
	return action
	

func expectimax(game_state: GameState, depth: int, is_max: bool) -> float:
	
	if (game_state.get_valid_actions().size() == 0|| depth >= MAX_DEPTH):
		return evaluation_function(game_state)
	var value: float = -INF
	var next_depth: int = depth
	if (!is_max):
		next_depth += 1
		value = INF
	
	if (is_max):
		for state in get_player_successor_states(game_state):
			value = max(value, expectimax(state, next_depth, false))
	else:
		var spawn_states: Dictionary = game_state.get_spawn_states()
		var avg2: float = 0.0
		var avg4: float = 0.0
		for tile in spawn_states.keys():
			for state in spawn_states[tile]:
				if (tile == 2):
					avg2 += expectimax(state, next_depth, true)
				else:
					avg4 += expectimax(state, next_depth, true)
					
		avg2 /= spawn_states[2].size()
		avg4 /= spawn_states[4].size()
		value = (avg2*(2.0/3.0)) + (avg4*(1.0/3.0))
	return value

