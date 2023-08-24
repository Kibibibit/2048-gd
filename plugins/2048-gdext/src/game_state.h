#ifndef _GAME_STATE_H
#define _GAME_STATE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>
#include <unordered_map>

namespace godot
{
    class GameState : public RefCounted
    {
        GDCLASS(GameState, RefCounted)

    protected:
        static void _bind_methods();

    private:
        int grid_size;
        int starting_tiles;
        int score;
        TypedArray<int> grid;
        TypedArray<int> free_slots;

        TypedArray<int> compress_tile_line(TypedArray<int> line);

    public:
        GameState();
        ~GameState();
        static const int INVALID_ACTION = 0;
        static const int ACTION_UP = 1;
        static const int ACTION_DOWN = 2;
        static const int ACTION_LEFT = 3;
        static const int ACTION_RIGHT = 4;

        void init(int grid_size, int starting_tiles);
        bool board_full();
        bool spawn_tile();

        void spawn_starting_tiles();

        int get_grid_size();
        void set_grid_size(int grid_size);
        int get_starting_tiles();
        void set_starting_tiles(int starting_tiles);
        int get_score();
        void set_score(int score);

        Vector2i vector_from_action(int action);
        Vector2i get_index_vector(int index);
        int get_vector_index(Vector2i vector);
        int get_at_vector(Vector2i vector);
        int get_at_index(int index);

        TypedArray<int> get_tile_line(Vector2i tile, Vector2i action_vector);
        TypedArray<int> get_valid_actions();

        Ref<GameState> get_successor_state(int action);
        Ref<GameState> duplicate();
        std::unordered_map<int, std::vector<GameState>> get_spawn_states();

    };

} // namespace godot

#endif