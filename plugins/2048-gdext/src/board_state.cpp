#include "board_state.h"

#include <time.h>

using namespace godot;

void BoardState::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("init", "grid_size", "starting_tiles"), &BoardState::init);
    ClassDB::bind_method(D_METHOD("get_grid_size"), &BoardState::get_grid_size);
    ClassDB::bind_method(D_METHOD("get_starting_tiles"), &BoardState::get_starting_tiles);
    ClassDB::bind_method(D_METHOD("get_grid"), &BoardState::get_grid);

    ClassDB::bind_method(D_METHOD("get_score"), &BoardState::get_score);
    ClassDB::bind_method(D_METHOD("set_score", "score"), &BoardState::set_score);
    ClassDB::add_property("BoardState", PropertyInfo(Variant::INT, "score"), "set_score", "get_score");

    ClassDB::bind_method(D_METHOD("board_full"), &BoardState::board_full);
    ClassDB::bind_method(D_METHOD("spawn_tile"), &BoardState::spawn_tile);
    ClassDB::bind_method(D_METHOD("spawn_starting_tiles"), &BoardState::spawn_starting_tiles);

    ClassDB::bind_method(D_METHOD("get_valid_actions"), &BoardState::get_valid_actions);
    ClassDB::bind_method(D_METHOD("apply_action"), &BoardState::apply_action);

    ClassDB::bind_integer_constant("BoardState", "Actions", INVALID_ACTION_LABEL, INVALID_ACTION);
    ClassDB::bind_integer_constant("BoardState", "Actions", ACTION_UP_LABEL, ACTION_UP);
    ClassDB::bind_integer_constant("BoardState", "Actions", ACTION_DOWN_LABEL, ACTION_DOWN);
    ClassDB::bind_integer_constant("BoardState", "Actions", ACTION_LEFT_LABEL, ACTION_LEFT);
    ClassDB::bind_integer_constant("BoardState", "Actions", ACTION_RIGHT_LABEL, ACTION_RIGHT);

    ADD_SIGNAL(MethodInfo(SIGNAL_TILE_MOVED, PropertyInfo(Variant::VECTOR2I, "prev_pos"), PropertyInfo(Variant::VECTOR2I, "next_pos")));
    ADD_SIGNAL(MethodInfo(SIGNAL_TILE_ADDED, PropertyInfo(Variant::VECTOR2I, "pos"), PropertyInfo(Variant::INT, "value")));
}

BoardState::BoardState()
{
    this->grid.instantiate();
    this->grid_size = 0;
    this->starting_tiles = 0;
    this->score = 0;
}

BoardState::~BoardState() {}

Vector2i BoardState::get_action_vector(int action)
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

void BoardState::init(int grid_size, int starting_tiles)
{
    this->grid_size = grid_size;
    this->starting_tiles = starting_tiles;
    this->grid->set_size(Vector2i(grid_size, grid_size));
    this->score = 0;
}

int BoardState::get_grid_size()
{
    return this->grid_size;
}

int BoardState::get_starting_tiles()
{
    return this->starting_tiles;
}

Ref<Grid2D> BoardState::get_grid()
{
    return this->grid->duplicate();
}

int BoardState::get_score()
{
    return score;
}

void BoardState::set_score(int score)
{
    this->score = score;
}

bool BoardState::board_full()
{
    return this->grid->no_zeros();
}

void BoardState::spawn_tile()
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

        TypedArray<Vector2i> free_slots = this->grid->get_positions_of(0);
        Vector2i pos = free_slots.pick_random();
        this->grid->set_at_v(value, pos);
        emit_signal(SIGNAL_TILE_ADDED, pos, value);
    }
}

void BoardState::spawn_starting_tiles()
{
    for (int i = 0; i < starting_tiles; i++)
    {
        spawn_tile();
    }
}

TypedArray<int> BoardState::get_valid_actions()
{
    TypedArray<int> out = TypedArray<int>();
    for (int action = ACTION_UP; action <= ACTION_RIGHT; action++)
    {
        for (int x = 0; x < this->grid_size; x++)
        {
            bool valid = false;
            for (int y = 0; y < this->grid_size; y++)
            {
                
                Vector2i tile = Vector2i(x,y);
                if (this->grid->get_at_v(tile) != 0) {
                    Vector2i action_vector = get_action_vector(action);
                    Vector2i check_vector = action_vector+tile;
                    if (check_vector.x >= 0 && check_vector.y >= 0 && check_vector.x < this->grid_size && check_vector.y < this->grid_size) {
                        int check_value = this->grid->get_at_v(check_vector);
                        if (check_value == 0 || check_value == this->grid->get_at_v(tile)) {
                            valid = true;
                            out.append(action);
                            break;
                        }
                    }

                }
            }
            if (valid) {
                break;
            }
        }
    }

    return out;
}

void BoardState::apply_action(int action)
{
    Vector2i action_vector = get_action_vector(action);
    TypedArray<Vector2i> added_tiles = TypedArray<Vector2i>();

    TypedArray<Vector2i> pos2 = this->grid->get_positions_of(2);

    bool in_reverse = action == ACTION_DOWN || action == ACTION_RIGHT;

    for (int x = 0; x < this->grid_size; x++)
    {
        for (int y = 0; y < this->grid_size; y++)
        {

            int t_x = x;
            int t_y = y;

            
            if (in_reverse)
            {
                t_x = this->grid_size - x - 1;
                t_y = this->grid_size - y - 1;
            }

            Vector2i tile = Vector2i(t_x, t_y);

            int tile_value = grid->get_at_v(tile);

            if (tile_value != 0)
            {
                Vector2i check_pos = Vector2i(tile) + action_vector;
                bool added = false;
                while (check_pos.x >= 0 && check_pos.y >= 0 && check_pos.x < this->grid_size && check_pos.y < this->grid_size)
                {

                    int check_value = grid->get_at_v(check_pos);

                    if (check_value == tile_value && added_tiles.find(check_pos) == -1)
                    {
                        added = true;
                        added_tiles.append(check_pos);
                        break;
                    }
                    if ((check_value != tile_value && check_value != 0) || added_tiles.find(check_pos) >= 0)
                    {
                        check_pos -= action_vector;
                        break;
                    }
                    check_pos += action_vector;
                }
                if (check_pos.x < 0)
                {
                    check_pos.x = 0;
                }
                if (check_pos.y < 0)
                {
                    check_pos.y = 0;
                }
                if (check_pos.x >= this->grid_size)
                {
                    check_pos.x = this->grid_size - 1;
                }
                if (check_pos.y >= this->grid_size)
                {
                    check_pos.y = this->grid_size - 1;
                }

                this->grid->set_at_v(tile_value, check_pos);
                if (added)
                {
                    this->grid->set_at_v(tile_value * 2, check_pos);
                    this->score += tile_value * 2;
                }
                if (check_pos != tile)
                {
                    this->grid->set_at_v(0, tile);
                    emit_signal(SIGNAL_TILE_MOVED, tile, check_pos);
                }
            }
        }
    }
}
