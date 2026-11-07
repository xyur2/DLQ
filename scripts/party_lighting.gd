class_name PartyLighting
extends Node2D
## 탑뷰의 파티 조명. 맵 위로 금빛 고보 무늬와 색 조명이 천천히 움직이고, 주인공 주변을 살짝 밝힌다.
## 슬로우 댄스 동안은 푸른 조명으로 바뀐다. 레이어 순서: 맵 위, 사람 아래.

const SPOTS_PER_AREA: float = 1.0 / 26000.0
const WASH_COLORS: Array[Color] = [Color(0.85, 0.15, 0.6), Color(0.2, 0.5, 1.0), Color(0.5, 0.2, 1.0)]
const GOBO_COLOR: Color = Color(1.0, 0.72, 0.3)
const SLOW_COLOR: Color = Color(0.3, 0.55, 1.0)
const NORMAL_AMBIENT: Color = Color(0.5, 0.4, 0.78)
const SLOW_AMBIENT: Color = Color(0.26, 0.36, 0.82)
const AMBIENT_FADE_SEC: float = 1.5
const WASH_COUNT_PER_ROOM: int = 3
const PLAYER_GLOW: Color = Color(0.75, 0.65, 1.0, 0.4)
const PLAYER_GLOW_RADIUS: float = 110.0
const WASH_ALPHA: float = 0.32

var _spots: Array[Dictionary] = []
var _washes: Array[Dictionary] = []
var _player: Node2D = null
var _time: float = 0.0
var _speed: float = 1.0
var _slow: float = 0.0   # 0: 평소 조명, 1: 슬로우 댄스 조명
var _soft_circle: GradientTexture2D = null
var _wrap: Vector2 = Vector2.ZERO   # 무한 모드: 이 크기마다 조명 무늬를 반복한다

@onready var _ambient: CanvasModulate = $Ambient


func setup(rooms: Array[Rect2], player: Node2D) -> void:
    _player = player
    for room: Rect2 in rooms:
        var count: int = roundi(room.get_area() * SPOTS_PER_AREA)
        for i: int in count:
            _spots.append({
                'room': room,
                'position': room.position + Vector2(randf(), randf()) * room.size,
                'radius': randf_range(9.0, 22.0),
                'phase': randf() * TAU,
                'speed': randf_range(0.15, 0.4),
                'star': i % 4 == 0,
            })
        for _i: int in WASH_COUNT_PER_ROOM:
            _washes.append({
                'room': room,
                'phase': randf() * TAU,
                'speed': randf_range(0.1, 0.22),
                'color': WASH_COLORS.pick_random(),
            })


## 무한 모드: window 크기의 조명 무늬를 만들어 플레이어 둘레에 끝없이 이어 붙인다.
func setup_wrapped(window: Vector2, player: Node2D) -> void:
    var area: Array[Rect2] = [Rect2(-window * 0.5, window)]
    setup(area, player)
    _wrap = window


## 무늬 안의 위치를 플레이어에게 가장 가까운 반복 위치로 옮긴다. 무한 모드가 아니면 그대로.
func _wrapped(point: Vector2) -> Vector2:
    if _wrap == Vector2.ZERO or _player == null:
        return point
    var center: Vector2 = to_local(_player.global_position)
    var rel: Vector2 = point - center
    return center + Vector2(wrapf(rel.x, -_wrap.x * 0.5, _wrap.x * 0.5), wrapf(rel.y, -_wrap.y * 0.5, _wrap.y * 0.5))


func _ready() -> void:
    _soft_circle = _make_soft_circle()
    _ambient.color = NORMAL_AMBIENT
    GameState.slow_dance_changed.connect(_on_slow_dance_changed)


func _process(delta: float) -> void:
    _time += delta * _speed
    queue_redraw()


func _on_slow_dance_changed(active: bool) -> void:
    _speed = 0.4 if active else 1.0
    var tween: Tween = create_tween().set_parallel()
    tween.tween_property(_ambient, 'color', SLOW_AMBIENT if active else NORMAL_AMBIENT, AMBIENT_FADE_SEC)
    tween.tween_property(self, '_slow', 1.0 if active else 0.0, AMBIENT_FADE_SEC)


func _draw() -> void:
    for wash: Dictionary in _washes:
        _draw_wash(wash)
    for spot: Dictionary in _spots:
        _draw_spot(spot)
    if _player != null:
        _draw_soft(to_local(_player.global_position), PLAYER_GLOW_RADIUS, PLAYER_GLOW)


## 방 안을 천천히 도는 넓은 색 조명
func _draw_wash(wash: Dictionary) -> void:
    var room: Rect2 = wash['room']
    var phase: float = float(wash['phase']) + _time * float(wash['speed'])
    var radius: float = minf(room.size.x, room.size.y) * 0.3
    var inner: Rect2 = room.grow(-radius)
    var point: Vector2 = inner.get_center() + Vector2(sin(phase) * inner.size.x, cos(phase * 1.3) * inner.size.y) * 0.5
    var color: Color = (wash['color'] as Color).lerp(SLOW_COLOR, _slow)
    color.a = WASH_ALPHA
    _draw_soft(_wrapped(point), radius * 1.4, color)


func _draw_soft(center: Vector2, radius: float, color: Color) -> void:
    draw_texture_rect(_soft_circle, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)


func _make_soft_circle() -> GradientTexture2D:
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
    var texture := GradientTexture2D.new()
    texture.gradient = gradient
    texture.fill = GradientTexture2D.FILL_RADIAL
    texture.fill_from = Vector2(0.5, 0.5)
    texture.fill_to = Vector2(1.0, 0.5)
    return texture


func _draw_spot(spot: Dictionary) -> void:
    var room: Rect2 = spot['room']
    var phase: float = float(spot['phase']) + _time * float(spot['speed'])
    var radius: float = float(spot['radius'])
    var point: Vector2 = (spot['position'] as Vector2) + Vector2(sin(phase), cos(phase * 0.8)) * 40.0
    if not room.grow(-radius * 1.2).has_point(point):
        return
    point = _wrapped(point)
    var color: Color = GOBO_COLOR.lerp(SLOW_COLOR, _slow)
    color.a = 0.42 + 0.14 * sin(phase * 3.0)
    if bool(spot['star']):
        var points := PackedVector2Array()
        for i: int in 10:
            var length: float = radius * 1.2 if i % 2 == 0 else radius * 0.5
            points.append(point + Vector2.UP.rotated(TAU * float(i) / 10.0 + phase * 0.3) * length)
        draw_colored_polygon(points, color)
    else:
        draw_arc(point, radius, 0.0, TAU, 24, color, radius * 0.32, true)
