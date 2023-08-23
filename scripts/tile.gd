extends Node2D
class_name Tile


const TILE_SIZE: float = 40.0
const CORNER_RADIUS: float = TILE_SIZE/8.0
const CORNER_BEGIN: float = CORNER_RADIUS
const CORNER_END: float = TILE_SIZE-CORNER_BEGIN

const FONT_SIZE: int = floori(TILE_SIZE/2.5)

const CORNERS: Array[Vector2] = [
	Vector2(CORNER_BEGIN,CORNER_BEGIN),
	Vector2(CORNER_BEGIN,CORNER_END),
	Vector2(CORNER_END,CORNER_BEGIN),
	Vector2(CORNER_END,CORNER_END)
]

const CORNER_A: Vector2 = Vector2(0, CORNER_BEGIN)
const SIZE_A: Vector2 = Vector2(TILE_SIZE,TILE_SIZE-(CORNER_RADIUS*2))
const CORNER_B: Vector2 = Vector2(CORNER_BEGIN, 0)
const SIZE_B: Vector2 = Vector2(TILE_SIZE-(CORNER_RADIUS*2), TILE_SIZE)
const RECT_A: Rect2 = Rect2(CORNER_A, SIZE_A)
const RECT_B: Rect2 = Rect2(CORNER_B, SIZE_B)


const COLORS: Array[Color] = [
	Color.ORANGE,
	Color.ORANGE_RED,
	Color.FIREBRICK,
	Color.CORAL,
	Color.INDIAN_RED,
	Color.CHOCOLATE,
	Color.HOT_PINK,
	Color.RED
]

const COLOR_MAP: Dictionary = {
	2: 0,
	4: 1,
	8: 2,
	16: 3,
	32: 4,
	64: 8,
	128: 9,
	256: 10,
	512: 11,
	1024: 12,
	2048: 13,
	4096: 14,
	8192: 15
}

var animating: bool = false
var target_position: Vector2

var index: int
var value: int

var font: SystemFont
var font_offset: Vector2

var color: Color


func _init(p_index: int, p_value: int):
	index = p_index
	value = p_value
	font = SystemFont.new()
	font.font_names = ["Calibri"]
	font_offset = font.get_string_size(
		"%s" % value,
		HORIZONTAL_ALIGNMENT_CENTER,
		TILE_SIZE,
		FONT_SIZE
	)
	font_offset.y /= 4
	font_offset.y += TILE_SIZE/2
	font_offset.x = 0
	color = COLORS[COLOR_MAP[p_value] % COLORS.size()]
	
func _ready():
	target_position = position 

func animate_to(pos: Vector2) -> void:
	target_position = pos

func do_animation_tick(delta: float) -> bool:
	position = position.move_toward(target_position, delta)
	return position.is_equal_approx(target_position)

func _draw() -> void:
	for corner in CORNERS:
		_draw_corner(corner)
	_draw_body()
	_draw_value()

func _draw_corner(dir: Vector2) -> void:
	draw_circle(dir, CORNER_RADIUS, color)

func _draw_body() -> void:
	draw_rect(RECT_A, color)
	draw_rect(RECT_B, color)

func _draw_value() -> void:
	draw_string(
		font, 
		font_offset, 
		"%s" % [value],
		HORIZONTAL_ALIGNMENT_CENTER, 
		TILE_SIZE, 
		FONT_SIZE, 
		_get_font_color(),
	)

func _get_font_color() -> Color:
	return Color.WHITE
