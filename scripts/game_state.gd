extends RefCounted
class_name GameState

signal added_tile(index: int, value:int)

const GRID_SIZE: int = 4
const STARTING_TILES: int = 3

const INVALID_ACTION: int = 0
const ACTION_UP: int = 1
const ACTION_DOWN: int = 2
const ACTION_LEFT: int = 3
const ACTION_RIGHT: int = 4

const ACTIONS: Array[int] = [ACTION_UP, ACTION_DOWN, ACTION_LEFT, ACTION_RIGHT]

var grid: Array[int] = []
var free_slots: Array[int] = []

var score: int

func _init() -> void:
	for i in range(GRID_SIZE*GRID_SIZE):
		grid.append(0)
		free_slots.append(i)
	score = 0

func init() -> void:
	for i in STARTING_TILES:
		spawn_tile()

func board_full() -> bool:
	return free_slots.is_empty()

func spawn_tile() -> bool:
	if (!board_full()):
		var roll: float = randf()
		var value: int = 2
		if (roll < 0.333):
			value = 4
		var index = free_slots.pop_at(randi_range(0,free_slots.size()-1))
		grid[index] = value
		added_tile.emit(index, value)
		
		return true
		
	return false

func vector_from_action(action: int) -> Vector2:
	match action:
		ACTION_LEFT:
			return Vector2(-1,0)
		ACTION_RIGHT:
			return Vector2(1,0)
		ACTION_UP:
			return Vector2(0,-1)
		ACTION_DOWN:
			return Vector2(0,1)
		_:
			return Vector2(0,0)

func get_index_vector(index: int) -> Vector2:
	return Vector2(index % GRID_SIZE, floori((index as float)/GRID_SIZE))

func get_vector_index(vector: Vector2) -> int:
	return (roundi(vector.y)*GRID_SIZE) + roundi(vector.x)

func get_at_vector(vector: Vector2) -> int:
	return grid[get_vector_index(vector)]

func get_tile_line(tile: Vector2, action_vector: Vector2) -> Array[int]:
	var out: Array[int] = []
	if (action_vector.x != 0):
		for x in GRID_SIZE:
			out.append(get_at_vector(Vector2(x, tile.y)))
	elif (action_vector.y != 0):
		for y in GRID_SIZE:
			out.append(get_at_vector(Vector2(tile.x, y)))
	return out

func get_new_tile_index(index: int, action: int) -> int:
	var tile_vector: Vector2 = get_index_vector(index)
	var action_vector = vector_from_action(action)
	var tile_line: Array[int] = get_tile_line(tile_vector, action_vector)
	var current_dim = tile_vector.x
	if (action_vector.y != 0):
		current_dim = tile_vector.y
	if (action_vector.x > 0 || action_vector.y > 0):
		tile_line.reverse()
		current_dim = tile_line.size() - current_dim - 1
	
	
	var out_index = index
	for i in tile_line.size():
		var added_tiles: Array[int] = []
		if (tile_line[i] != 0):
			var new_index: int = 0
			var added: bool = false
			for j in i:
				var check_index = i-j-1
				if (tile_line[check_index] == tile_line[i] && (!check_index in added_tiles)):
					new_index = check_index
					added = true
					added_tiles.append(check_index)
					break
				elif ((tile_line[check_index] != tile_line[i] && tile_line[check_index] != 0) || check_index in added_tiles):
					new_index = check_index+1
					break
			tile_line[new_index] = tile_line[i]
			if (added):
				tile_line[new_index] *= 2
			if (i != new_index):
				tile_line[i] = 0
			if (i == current_dim):
				out_index = new_index
				break
	
	if (action_vector.x > 0 || action_vector.y > 0):
		out_index = tile_line.size()-1-out_index
	
	if (action_vector.x != 0):
		return get_vector_index(Vector2(out_index, tile_vector.y))
	elif (action_vector.y != 0):
		return get_vector_index(Vector2(tile_vector.x, out_index))
	return 0

func get_valid_actions() -> Array[int]:
	var out: Array[int] = []
	
	for action in ACTIONS:
		var action_vector: Vector2 = vector_from_action(action)
		var valid: bool = false
		for x in GRID_SIZE:
			for y in GRID_SIZE:
				var tile_vector = Vector2(x,y)
				var value = get_at_vector(tile_vector)
				if (value != 0):
					var adj_vector = tile_vector+action_vector
					if (adj_vector.x >= 0 && adj_vector.y >= 0 && adj_vector.x < GRID_SIZE && adj_vector.y < GRID_SIZE):
						var adj_value = get_at_vector(adj_vector)
						if (adj_value == 0 || value==adj_value):
							out.append(action)
							valid = true
							break
			if (valid):
				break
		
	
	return out

func _compress_tile_line(line: Array[int]) -> Array[int]:
	var added_tiles: Array[int] = []
	var tile_line: Array[int] = line.duplicate()
	for i in tile_line.size():
		if (tile_line[i] != 0):
			var new_index: int = 0
			var added: bool = false
			for j in i:
				var check_index = i-j-1
				if (tile_line[check_index] == tile_line[i] && !(check_index in added_tiles)):
					new_index = check_index
					added = true
					added_tiles.append(new_index)
					break
				elif((tile_line[check_index] != tile_line[i] && tile_line[check_index] != 0) || check_index in added_tiles):
					new_index = check_index+1
					break
			tile_line[new_index] = tile_line[i]
			if (added):
				tile_line[new_index] *= 2
				score += tile_line[new_index]
			if (i != new_index):
				tile_line[i] = 0
	return tile_line

func get_successor_state(action: int) -> GameState:
	var out: GameState = GameState.new()
	var action_vector: Vector2 = vector_from_action(action)
	
	out.grid = grid.duplicate()
	out.free_slots = []
	
	
	var horizontal_mult = 0
	var vertical_mult = 1
	if (action_vector.y != 0):
		horizontal_mult = 1
		vertical_mult = 0
		
	var flipped = action_vector.x > 0 || action_vector.y > 0
	
	var out_lines = []
	
	for line in GRID_SIZE:
		var line_vector = Vector2(horizontal_mult, vertical_mult)*line
		var tile_line = get_tile_line(line_vector, action_vector)
		if (flipped):
			tile_line.reverse()
		var out_line = _compress_tile_line(tile_line)
		if (flipped):
			out_line.reverse()
		out_lines.append(out_line)
	
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if (horizontal_mult > 0):
				out.grid[get_vector_index(Vector2(x,y))] = out_lines[x][y]
			else:
				out.grid[get_vector_index(Vector2(x,y))] = out_lines[y][x]
	out.score = score

	for i in out.grid.size():
		if (out.grid[i] == 0):
			out.free_slots.append(i)
	return out

func duplicate()->GameState:
	var state: GameState = GameState.new()
	state.grid = grid.duplicate()
	state.free_slots = free_slots.duplicate()
	state.score = score
	return state

func get_spawn_states()->Dictionary:
	var out: Dictionary = {
		2: [],
		4: []
	}
	for free_index in free_slots:
		var state2: GameState = duplicate()
		state2.free_slots.remove_at(state2.free_slots.find(free_index))
		state2.grid[free_index] = 2
		out[2].append(state2)
		var state4: GameState = duplicate()
		state4.free_slots.remove_at(state4.free_slots.find(free_index))
		state4.grid[free_index] = 2
		out[4].append(state4)
	return out
