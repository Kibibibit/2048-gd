#include "grid_2d.h"

#include <vector>

using namespace godot;

void Grid2D::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_size"), &Grid2D::get_size);
    ClassDB::bind_method(D_METHOD("set_size", "new_size"), &Grid2D::set_size);
    ClassDB::add_property("Grid2D", PropertyInfo(Variant::VECTOR2I, "size"), "set_size", "get_size");

    ClassDB::bind_method(D_METHOD("get_at_v", "vector"), &Grid2D::get_at_v);
    ClassDB::bind_method(D_METHOD("get_at", "x", "y"), &Grid2D::get_at);

    ClassDB::bind_method(D_METHOD("set_at_v", "value", "vector"), &Grid2D::set_at_v);
    ClassDB::bind_method(D_METHOD("set_at", "value", "x", "y"), &Grid2D::set_at);

    ClassDB::bind_method(D_METHOD("get_data"), &Grid2D::get_data);

    ClassDB::bind_method(D_METHOD("duplicate"), &Grid2D::duplicate);
}

Grid2D::Grid2D()
{
    this->data = new std::vector<int>();
    this->size = Vector2i(0, 0);
}

Grid2D::~Grid2D()
{
    delete this->data;
}

int Grid2D::get_index(Vector2i vector)
{
    return (this->size.x * vector.y) + vector.x;
}

Vector2i Grid2D::get_vector(int index)
{
    return Vector2i(
        index % size.x,
        (int)floor(index / size.y));
}

Vector2i Grid2D::get_size()
{
    return Vector2i(this->size);
}

void Grid2D::set_size(Vector2i new_size)
{
    this->size = Vector2i(new_size);
    int new_data_size = new_size.x * new_size.y;
    while (this->data->size() < new_data_size)
    {
        this->data->push_back(0);
    }
    while (this->data->size() > new_data_size)
    {
        this->data->pop_back();
    }
}

int Grid2D::get_at_v(Vector2i vector)
{
    CRASH_BAD_INDEX_MSG(vector.x, this->size.x, "Bad Grid2D access on x");
    CRASH_BAD_INDEX_MSG(vector.y, this->size.y, "Bad Grid2D access on y");
    return this->data->at(get_index(vector));
}

int Grid2D::get_at(int x, int y)
{
    return get_at_v(Vector2i(x, y));
}

void Grid2D::set_at_v(int value, Vector2i vector)
{
    CRASH_BAD_INDEX_MSG(vector.x, this->size.x, "Bad Grid2D access on x");
    CRASH_BAD_INDEX_MSG(vector.y, this->size.y, "Bad Grid2D access on y");
    this->data->at(get_index(vector)) = value;
}

void Grid2D::set_at(int value, int x, int y)
{
    set_at_v(value, Vector2i(x, y));
}

TypedArray<int> Grid2D::get_data()
{
    TypedArray<int> out = TypedArray<int>();
    for (int i = 0; i < this->data->size(); i++)
    {
        out.push_back(this->data->at(i));
    }
    return out;
}

Ref<Grid2D> Grid2D::duplicate()
{
    Ref<Grid2D> out;
    out.instantiate();
    out->set_size(this->get_size());
    for (int x = 0; x < this->size.x; x++)
    {
        for (int y = 0; y < this->size.y; y++)
        {
            out->set_at(this->get_at(x, y), x, y);
        }
    }
    return out;
}

bool Grid2D::no_zeros()
{
    for (int i = 0; i < this->data->size(); i++)
    {
        if (this->data->at(i) == 0)
        {
            return false;
        }
    }
    return true;
}

TypedArray<Vector2i> Grid2D::get_positions_of(int value)
{
    TypedArray<Vector2i> out = TypedArray<Vector2i>();
    for (int i = 0; i < this->data->size(); i++)
    {
        if (this->data->at(i) == value)
        {
            out.append(get_vector(i));
        }
    }
    return out;
}