extends RefCounted
class_name AIController

const MAX_DEPTH: int = 2

const NEIGHBOURS: Array[Vector2] = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]

func get_player_successor_states(game_state: GameState) -> Array[GameState]:
	var out: Array[GameState] = []
	for action in game_state.get_valid_actions():
		var state: GameState = game_state.duplicate()
		state.apply_action(action)
		out.append(state)
	return out


func evaluation_function(game_state: GameState) -> float:
	
	var counts: Dictionary = {}
	var data: Array[int] = game_state.get_grid().get_data()
	var sum: float = 0
	
	for value in data:
		if (value not in counts):
			sum += pow(data.count(value),3)
			counts[value] = value
	
	return sum


func pick_move(game_state: GameState) -> int:
	var action : int = GameState.INVALID_ACTION as int
	var value:float = -INF
	
	for a in game_state.get_valid_actions():
		var state: GameState = game_state.duplicate()
		state.apply_action(a)
		var new_value: float = expectimax(state, 0, false)
		if (new_value > value):
			value = new_value
			action = a as int
	
	return action
	

func expectimax(game_state: GameState, depth: int, is_max: bool) -> float:
	
	if (game_state.board_full() || depth >= MAX_DEPTH):
		return evaluation_function(game_state)
	var value: float = -INF
	var next_depth: int = depth
	if (!is_max):
		next_depth += 1
		value = INF
	
	if (is_max):
		for state in  get_player_successor_states(game_state):
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

