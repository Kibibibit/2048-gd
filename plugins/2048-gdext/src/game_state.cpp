
#include "game_state.h"
#include <vector>
#include <random>
#include <time.h>

using namespace godot;

void GameState::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("init", "grid_size", "starting_tiles"), &GameState::init);
    ClassDB::bind_method(D_METHOD("board_full"), &GameState::board_full);

    ClassDB::bind_method(D_METHOD("get_grid_size"), &GameState::get_grid_size);
    ClassDB::bind_method(D_METHOD("set_grid_size", "grid_size"), &GameState::set_grid_size);
    ClassDB::add_property("GameState", PropertyInfo(Variant::INT, "grid_size"), "set_grid_size", "get_grid_size");

    ClassDB::bind_method(D_METHOD("get_starting_tiles"), &GameState::get_starting_tiles);
    ClassDB::bind_method(D_METHOD("set_starting_tiles", "starting_tiles"), &GameState::set_starting_tiles);
    ClassDB::add_property("GameState", PropertyInfo(Variant::INT, "starting_tiles"), "set_starting_tiles", "get_starting_tiles");

    ClassDB::bind_method(D_METHOD("get_score"), &GameState::get_score);
    ClassDB::bind_method(D_METHOD("set_score", "score"), &GameState::set_score);
    ClassDB::add_property("GameState", PropertyInfo(Variant::INT, "score"), "set_score", "get_score");

    ClassDB::bind_method(D_METHOD("vector_from_action", "action"), &GameState::vector_from_action);
    ClassDB::bind_method(D_METHOD("get_index_vector", "index"), &GameState::get_index_vector);
    ClassDB::bind_method(D_METHOD("get_vector_index", "vector"), &GameState::get_vector_index);
    ClassDB::bind_method(D_METHOD("get_at_vector", "vector"), &GameState::get_at_vector);
    ClassDB::bind_method(D_METHOD("get_at_index", "index"), &GameState::get_at_index);

    ClassDB::bind_method(D_METHOD("spawn_starting_tiles"), &GameState::spawn_starting_tiles);
    ClassDB::bind_method(D_METHOD("spawn_tile"), &GameState::spawn_tile);

    ClassDB::bind_method(D_METHOD("get_valid_actions"), &GameState::get_valid_actions);
    ClassDB::bind_method(D_METHOD("get_successor_state", "action"), &GameState::get_successor_state);
    ClassDB::bind_method(D_METHOD("duplicate"), &GameState::duplicate);

    ClassDB::bind_integer_constant("GameState", "Actions", "INVALID_ACTION", GameState::INVALID_ACTION);
    ClassDB::bind_integer_constant("GameState", "Actions", "ACTION_UP", GameState::ACTION_UP);
    ClassDB::bind_integer_constant("GameState", "Actions", "ACTION_DOWN", GameState::ACTION_DOWN);
    ClassDB::bind_integer_constant("GameState", "Actions", "ACTION_LEFT", GameState::ACTION_LEFT);
    ClassDB::bind_integer_constant("GameState", "Actions", "ACTION_RIGHT", GameState::ACTION_RIGHT);

    ADD_SIGNAL(MethodInfo("tile_added", PropertyInfo(Variant::INT, "index"), PropertyInfo(Variant::INT, "value")));
    ADD_SIGNAL(MethodInfo("tile_moved", PropertyInfo(Variant::INT, "current_index"), PropertyInfo(Variant::INT, "new_index")));
}

GameState::GameState()
{
    this->grid = TypedArray<int>();
    this->free_slots = TypedArray<int>();
    this->score = 0;
    this->grid_size = 0;
    this->starting_tiles = 0;
}

GameState::~GameState()
{
}

void GameState::init(int grid_size, int starting_tiles)
{
    this->grid_size = grid_size;
    this->starting_tiles = starting_tiles;
    this->score = 0;

    for (int i = 0; i < grid_size * grid_size; i++)
    {
        this->grid.push_back(0);
        this->free_slots.push_back(i);
    }
}

bool GameState::board_full()
{
    return this->free_slots.is_empty();
}

bool GameState::spawn_tile()
{
    if (!board_full())
    {
        srand(time(NULL));
        float roll = ((float)rand()) / RAND_MAX;
        int value = 2;
        if (roll < 1.0 / 3.0)
        {
            value = 4;
        }
        srand(time(NULL));
        int free_index = rand() % this->free_slots.size();
        int index = this->free_slots[free_index];
        this->free_slots.remove_at(free_index);
        this->grid[index] = value;
        emit_signal("tile_added", index, value);
        return true;
    }
    return false;
}

void GameState::spawn_starting_tiles()
{
    for (int i = 0; i < this->starting_tiles; i++)
    {
        spawn_tile();
    }
}

int GameState::get_score()
{
    return this->score;
}
void GameState::set_score(int score)
{
    this->score = score;
}

int GameState::get_starting_tiles()
{
    return this->starting_tiles;
}
void GameState::set_starting_tiles(int starting_tiles)
{
    this->starting_tiles = starting_tiles;
}

int GameState::get_grid_size()
{
    return this->grid_size;
}
void GameState::set_grid_size(int grid_size)
{
    this->grid_size = grid_size;
}

Vector2i GameState::vector_from_action(int action)
{
    switch (action)
    {
    case ACTION_UP:
        return Vector2i(0, -1);
    case ACTION_DOWN:
        return Vector2i(0, 1);
    case ACTION_LEFT:
        return Vector2i(-1, 0);
    case ACTION_RIGHT:
        return Vector2i(1, 0);
    default:
        return Vector2i(0, 0);
    }
}
Vector2i GameState::get_index_vector(int index)
{
    return Vector2i(
        index % this->grid_size, (int)floor((double)index / this->grid_size));
}
int GameState::get_vector_index(Vector2i vector)
{
    return (vector.y * this->grid_size) + vector.x;
}
int GameState::get_at_vector(Vector2i vector)
{
    return this->grid[get_vector_index(vector)];
}
int GameState::get_at_index(int index)
{
    return this->grid[index];
}

TypedArray<int> GameState::get_tile_line(Vector2i tile, Vector2i action_vector)
{
    TypedArray<int> out = TypedArray<int>();
    if (action_vector.x != 0)
    {
        for (int x = 0; x < this->grid_size; x++)
        {
            out.push_back(this->get_at_vector(Vector2i(x, tile.y)));
        }
    }
    else if (action_vector.y != 0)
    {
        for (int y = 0; y < this->grid_size; y++)
        {
            out.push_back(this->get_at_vector(Vector2i(tile.x, y)));
        }
    }
    return out;
}

TypedArray<int> GameState::compress_tile_line(TypedArray<int> line)
{
    TypedArray<int> tile_line = TypedArray<int>();
    for (int i = 0; i < line.size(); i++)
    {
        tile_line.push_back(line[i]);
    }

    TypedArray<int> added_tiles = TypedArray<int>();

    for (int i = 0; i < tile_line.size(); i++)
    {

        if ((int32_t) tile_line[i] != 0)
        {

            int new_index = 0;
            bool added = false;

            for (int j = 0; j < i; j++)
            {
                int check_index = i - j - 1;

                if (tile_line[check_index] == tile_line[i] && added_tiles.find(check_index) == -1)
                {
                    new_index = check_index;
                    added = true;
                    added_tiles.push_back(new_index);
                    break;
                }
                else if ((tile_line[check_index] != tile_line[i] && (int32_t)tile_line[check_index] != 0) || added_tiles.find(check_index) != -1)
                {
                    new_index = check_index + 1;
                    break;
                }
            }
            tile_line[new_index] = tile_line[i];
            if (added)
            {
                int multiplied_value = (int32_t)tile_line[new_index];
                multiplied_value *= 2;
                tile_line[new_index] = multiplied_value;
                this->score += multiplied_value;
            }
            if (i != new_index)
            {
                tile_line[i] = 0;
            }
        }
    }
    return tile_line;
}

TypedArray<int> GameState::get_valid_actions()
{
    TypedArray<int> valid_moves = TypedArray<int>();
    for (int action = ACTION_UP; action <= ACTION_RIGHT; action++)
    {
        Vector2i action_vector = vector_from_action(action);
        bool valid = false;

        for (int x = 0; x < this->grid_size; x++)
        {
            for (int y = 0; y < this->grid_size; y++)
            {
                Vector2i tile_vector = Vector2i(x, y);
                int value = get_at_vector(tile_vector);
                if (value != 0)
                {
                    Vector2i adj_vector = tile_vector + action_vector;
                    if (adj_vector.x >= 0 && adj_vector.y >= 0 && adj_vector.x < this->grid_size && adj_vector.y < this->grid_size)
                    {
                        int adj_value = get_at_vector(adj_vector);
                        if (adj_value == 0 || value == adj_value)
                        {
                            valid_moves.push_back(action);
                            valid = true;
                            break;
                        }
                    }
                }
            }
            if (valid)
            {
                break;
            }
        }
    }
    return valid_moves;
}

Ref<GameState> GameState::get_successor_state(int action)
{
    Ref<GameState> out = this->duplicate();
    out->free_slots.clear();
    Vector2i action_vector = vector_from_action(action);
    int hori_mult = 0;
    int vert_mult = 1;
    if (action_vector.y != 0)
    {
        hori_mult = 1;
        vert_mult = 0;
    }

    bool flipped = action_vector.x > 0 || action_vector.y > 0;

    std::vector<TypedArray<int>> out_lines = std::vector<TypedArray<int>>();

    for (int i = 0; i < out->grid_size; i++)
    {
        Vector2i line_vector = Vector2i(hori_mult, vert_mult) * i;
        TypedArray<int> tile_line = get_tile_line(line_vector, action_vector);
        if (flipped)
        {
            tile_line.reverse();
        }
        TypedArray<int> out_line = compress_tile_line(tile_line);
        if (flipped)
        {
            out_line.reverse();
        }
        out_lines.push_back(out_line);
    }

    for (int y = 0; y < out->grid_size; y++)
    {
        for (int x = 0; x < out->grid_size; x++)
        {
            if (hori_mult > 0)
            {
                out->grid[get_vector_index(Vector2i(x, y))] = ((TypedArray<int>)out_lines[x])[y];
            }
            else
            {
                out->grid[get_vector_index(Vector2i(x, y))] = ((TypedArray<int>)out_lines[y])[x];
            }
        }
    }
    out->score = score;

    for (int i = 0; i < out->grid.size(); i++)
    {
        if ((int32_t)out->grid[i] == 0)
        {
            out->free_slots.append(i);
        }
    }
    return out;
}
Ref<GameState> GameState::duplicate()
{
    Ref<GameState> out;
    out.instantiate();
    out->score = this->score;
    out->grid_size = this->grid_size;
    out->starting_tiles = this->starting_tiles;
    out->free_slots = TypedArray<int>();
    out->grid = TypedArray<int>();
    for (int i = 0; i < grid.size(); i++)
    {
        out->grid.push_back(this->grid[i]);
    }
    for (int i = 0; i < free_slots.size(); i++)
    {
        out->free_slots.push_back(this->free_slots[i]);
    }
    return out;
}
std::unordered_map<int, std::vector<GameState>> GameState::get_spawn_states()
{
    return std::unordered_map<int, std::vector<GameState>>();
}