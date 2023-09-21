#ifndef _GAME_STATE_H
#define _GAME_STATE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include "grid_2d.h"

#define SIGNAL_TILE_MOVED "tile_moved"
#define SIGNAL_TILE_ADDED "tile_added"

#define INVALID_ACTION 0
#define INVALID_ACTION_LABEL "INVALID_ACTION"
#define ACTION_UP 1
#define ACTION_UP_LABEL "ACTION_UP"
#define ACTION_DOWN 2
#define ACTION_DOWN_LABEL "ACTION_DOWN"
#define ACTION_LEFT 3
#define ACTION_LEFT_LABEL "ACTION_LEFT"
#define ACTION_RIGHT 4
#define ACTION_RIGHT_LABEL "ACTION_RIGHT"

namespace godot {
    
    class GameState : public RefCounted {

        GDCLASS(GameState, RefCounted)

        private:
            Ref<Grid2D> grid;
            int grid_size;
            int starting_tiles;
            int score;
            Vector2i get_action_vector(int action);

        protected:
            static void _bind_methods();
            

        public:
            GameState();
            ~GameState();
            virtual void _init(int grid_size, int starting_tiles);
            void init(int grid_size, int starting_tiles);

            Ref<Grid2D> get_grid();

            int get_grid_size();
            int get_starting_tiles();
            
            int get_score();
            void set_score(int score);

            void spawn_starting_tiles();
            void spawn_tile();

            bool board_full();

            TypedArray<int> get_valid_actions();
            void apply_action(int action);

            Ref<GameState> duplicate();

            int get_free_count();

            Dictionary get_spawn_states();

    };

}



#endif