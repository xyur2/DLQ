class_name PartyBackground
extends Control
## 메뉴 배경. 어두운 파티장 뒷벽의 네온 기둥, 전구 줄, 디스코볼 빛줄기, 바닥의 금빛 조명 무늬를 코드로 그린다.

const HORIZON_Y: float = 650.0
const VANISH_POINT: Vector2 = Vector2(960.0, 470.0)
const SKY_TOP: Color = Color(0.02, 0.015, 0.09)
const SKY_BOTTOM: Color = Color(0.1, 0.05, 0.3)
const FLOOR_FAR: Color = Color(0.16, 0.06, 0.4)
const FLOOR_NEAR: Color = Color(0.3, 0.07, 0.42)
const NEON_CYAN: Color = Color(0.25, 0.8, 1.0)
const GOBO_GOLD: Color = Color(1.0, 0.76, 0.35)
const BEAM_COLORS: Array[Color] = [
    Color(1.0, 0.25, 0.65), Color(0.3, 0.8, 1.0), Color(0.65, 0.4, 1.0), Color(1.0, 0.8, 0.45),
]
const COLUMN_COUNT: int = 11
const WALL_DOT_COUNT: int = 90
const GOBO_COUNT: int = 34
const BEAM_COUNT: int = 6
const PLANK_COUNT: int = 22
const BALL_GLOW_RADIUS: float = 300.0

## 빛줄기가 시작되는 디스코볼 위치
@export var ball_center: Vector2 = Vector2(1620.0, 118.0)

var _wall_dots: Array[Dictionary] = []
var _gobos: Array[Dictionary] = []
var _time: float = 0.0
var _soft_circle: GradientTexture2D = null


func _ready() -> void:
    _soft_circle = _make_soft_circle()
    for _i: int in WALL_DOT_COUNT:
        _wall_dots.append({
            'position': Vector2(randf() * size.x, randf_range(40.0, HORIZON_Y - 40.0)),
            'radius': randf_range(1.5, 3.5),
            'speed': randf_range(0.8, 2.6),
            'phase': randf() * TAU,
            'color': GOBO_GOLD if randf() < 0.6 else NEON_CYAN,
        })
    for i: int in GOBO_COUNT:
        _gobos.append({
            'position': Vector2(randf() * size.x, randf_range(HORIZON_Y + 20.0, size.y)),
            'phase': randf() * TAU,
            'speed': randf_range(0.12, 0.35),
            'star': i % 5 == 0,
            'color': GOBO_GOLD if i % 3 != 0 else Color(1.0, 0.45, 0.8),
        })


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    _draw_vertical_gradient(0.0, HORIZON_Y, SKY_TOP, SKY_BOTTOM)
    _draw_wall_dots()
    _draw_columns()
    _draw_vertical_gradient(HORIZON_Y, size.y, FLOOR_FAR, FLOOR_NEAR)
    _draw_planks()
    _draw_gobos()
    _draw_string_lights(250.0, 90.0, 0.0)
    _draw_string_lights(360.0, 60.0, 1.7)
    _draw_beams()
    _draw_ball_glow()


func _draw_vertical_gradient(top: float, bottom: float, top_color: Color, bottom_color: Color) -> void:
    draw_polygon(
        PackedVector2Array([Vector2(0.0, top), Vector2(size.x, top), Vector2(size.x, bottom), Vector2(0.0, bottom)]),
        PackedColorArray([top_color, top_color, bottom_color, bottom_color])
    )


func _draw_wall_dots() -> void:
    for dot: Dictionary in _wall_dots:
        var color: Color = dot['color']
        color.a = 0.15 + 0.5 * pow(0.5 + 0.5 * sin(_time * float(dot['speed']) + float(dot['phase'])), 2.0)
        draw_circle(dot['position'], float(dot['radius']), color)


## 뒷벽의 빛나는 기둥. 바깥쪽 투명한 띠로 번짐을 흉내 낸다.
func _draw_columns() -> void:
    var gap: float = size.x / float(COLUMN_COUNT)
    for i: int in COLUMN_COUNT:
        var x: float = gap * (float(i) + 0.5)
        var glow: float = 0.55 + 0.25 * sin(_time * 0.9 + float(i))
        var height: float = 170.0 + 40.0 * sin(float(i) * 1.7)
        for layer: Array in [[26.0, 0.07], [14.0, 0.14], [5.0, 0.8]]:
            var color: Color = NEON_CYAN
            color.a = float(layer[1]) * glow
            var half: float = float(layer[0]) * 0.5
            draw_rect(Rect2(x - half, HORIZON_Y - height, half * 2.0, height), color)


## 바닥 나무 판자 줄. 소실점으로 모인다.
func _draw_planks() -> void:
    var line_color := Color(0.05, 0.01, 0.15, 0.4)
    for i: int in PLANK_COUNT + 1:
        var bottom_x: float = lerpf(-900.0, size.x + 900.0, float(i) / float(PLANK_COUNT))
        var bottom := Vector2(bottom_x, size.y)
        var ratio: float = (HORIZON_Y - VANISH_POINT.y) / (size.y - VANISH_POINT.y)
        draw_line(VANISH_POINT.lerp(bottom, ratio), bottom, line_color, 1.5)


## 바닥에 떨어지는 조명 무늬. 앞쪽일수록 크고, 원근에 맞춰 납작하다.
func _draw_gobos() -> void:
    for gobo: Dictionary in _gobos:
        var base: Vector2 = gobo['position']
        var phase: float = float(gobo['phase']) + _time * float(gobo['speed'])
        var depth: float = inverse_lerp(HORIZON_Y, size.y, base.y)
        var point: Vector2 = base + Vector2(sin(phase) * 60.0, cos(phase * 0.7) * 12.0)
        if point.y < HORIZON_Y + 8.0:
            continue
        var radius: float = lerpf(6.0, 40.0, depth)
        var color: Color = gobo['color']
        color.a = lerpf(0.25, 0.6, depth) * (0.65 + 0.35 * sin(phase * 3.0))
        if bool(gobo['star']):
            _draw_star(point, radius * 1.3, color)
        else:
            _draw_flat_ring(point, radius, color)


func _draw_flat_ring(center: Vector2, radius: float, color: Color) -> void:
    draw_set_transform(center, 0.0, Vector2(1.0, 0.42))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, color, maxf(radius * 0.28, 1.5), true)
    draw_set_transform(Vector2.ZERO)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
    var points := PackedVector2Array()
    for i: int in 10:
        var length: float = radius if i % 2 == 0 else radius * 0.42
        var offset: Vector2 = Vector2.UP.rotated(TAU * float(i) / 10.0) * length
        points.append(center + Vector2(offset.x, offset.y * 0.45))
    draw_colored_polygon(points, color)


func _draw_string_lights(y: float, sag: float, phase: float) -> void:
    var previous: Vector2 = Vector2.ZERO
    var count: int = 60
    for i: int in count + 1:
        var ratio: float = float(i) / float(count)
        var wave: float = fmod(ratio * 3.0, 1.0)
        var point := Vector2(ratio * size.x, y + sag * 4.0 * wave * (1.0 - wave))
        if i > 0:
            draw_line(previous, point, Color(0.5, 0.42, 0.65, 0.3), 1.0)
        previous = point
        var twinkle: float = 0.5 + 0.5 * sin(_time * 2.0 + float(i) * 1.3 + phase)
        draw_circle(point, 5.0, Color(1.0, 0.85, 0.55, 0.1 + 0.14 * twinkle))
        draw_circle(point, 2.0, Color(1.0, 0.9, 0.7, 0.5 + 0.5 * twinkle))


## 디스코볼에서 뻗는 빛줄기. 끝으로 갈수록 투명하다.
func _draw_beams() -> void:
    for i: int in BEAM_COUNT:
        var angle: float = PI * 0.5 + 0.75 * sin(_time * (0.2 + 0.05 * float(i)) + float(i) * 1.9) + 0.35
        var direction: Vector2 = Vector2.RIGHT.rotated(angle)
        var far_point: Vector2 = ball_center + direction * 1300.0
        var side: Vector2 = direction.orthogonal() * 70.0
        var color: Color = BEAM_COLORS[i % BEAM_COLORS.size()]
        var near_color: Color = color
        near_color.a = 0.26
        color.a = 0.0
        draw_polygon(
            PackedVector2Array([ball_center, far_point + side, far_point - side]),
            PackedColorArray([near_color, color, color])
        )


func _draw_ball_glow() -> void:
    var pulse: float = 0.8 + 0.2 * sin(_time * 3.0)
    var box := Rect2(ball_center - Vector2.ONE * BALL_GLOW_RADIUS, Vector2.ONE * BALL_GLOW_RADIUS * 2.0)
    draw_texture_rect(_soft_circle, box, false, Color(0.55, 0.7, 1.0, 0.5 * pulse))


func _make_soft_circle() -> GradientTexture2D:
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
    var texture := GradientTexture2D.new()
    texture.gradient = gradient
    texture.fill = GradientTexture2D.FILL_RADIAL
    texture.fill_from = Vector2(0.5, 0.5)
    texture.fill_to = Vector2(1.0, 0.5)
    return texture
