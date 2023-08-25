#ifndef _GRID_2D_H
#define _GRID_2D_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>

namespace godot
{

    class Grid2D : public RefCounted
    {
        GDCLASS(Grid2D, RefCounted)

    private:
        std::vector<int> *data;
        Vector2i size;

        int get_index(Vector2i vector);
        Vector2i get_vector(int index);

    protected:
        static void _bind_methods();

    public:
        Grid2D();
        ~Grid2D();
        Vector2i get_size();
        void set_size(Vector2i vector);
        int get_at_v(Vector2i vector);
        int get_at(int x, int y);
        void set_at_v(int value, Vector2i vector);
        void set_at(int value, int x, int y);
        bool no_zeros();
        TypedArray<int> get_data();
        Ref<Grid2D> duplicate();
        TypedArray<Vector2i> get_positions_of(int value);
    };

}

#endif