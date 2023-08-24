
#include "game_state.h"
#include <vector>
#include <random>

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
    this->grid = std::vector<int>();
    this->free_slots = std::vector<int>();
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
    return this->free_slots.empty();
}

bool GameState::spawn_tile()
{
    if (!board_full())
    {
        float roll = ((float)rand()) / RAND_MAX;
        int value = 2;
        if (roll < 1.0 / 3.0)
        {
            value = 4;
        }
        int free_index = rand() % this->free_slots.size();
        int index = this->free_slots[free_index];
        this->free_slots.erase(this->free_slots.begin() + index);
        this->grid.insert(this->grid.begin() + index, value);
        emit_signal("tile_added", index, value);
        return true;
    }
    return false;
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
    return (vector.y*this->grid_size) + vector.x;
}
int GameState::get_at_vector(Vector2i vector)
{
    return this->grid.at(get_vector_index(vector));
}
int GameState::get_at_index(int index)
{
    return this->grid.at(index);
}

std::vector<int> GameState::get_tile_line(Vector2i tile, Vector2i action_vector)
{
    return std::vector<int>();
}
std::vector<int> GameState::get_valid_actions()
{
    return std::vector<int>();
}

GameState GameState::get_successor_state(int action)
{
    return GameState();
}
GameState GameState::duplicate()
{
    return GameState(*this);
}
std::unordered_map<int, std::vector<GameState>> GameState::get_spawn_states()
{
    return std::unordered_map<int, std::vector<GameState>>();
}