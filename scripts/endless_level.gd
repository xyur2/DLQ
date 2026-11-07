class_name EndlessLevel
extends PartyLevel
## 무한 모드의 맵: 방과 벽 없이 상하좌우로 끝없이 이어진 바닥 하나. scenes/top_view/levels/endless.tscn의 루트에 붙는다.
## 바닥 타일(Floor)은 카메라 둘레만 칠하고 멀어진 칸은 지운다. 무늬는 일반 맵과 같다(칸 좌표를 3으로 나눈 나머지).
## 방이 하나뿐이라 사람은 문을 찾지 않고 곧장 걷는다.
## 걸어갈 곳은 지금 자리에서 ENDLESS_WANDER_RADIUS 안, 처음 놓을 곳은 플레이어 둘레 구역(ENDLESS_ZONE_HALF) 안이다.

const FLOOR_SOURCE: int = 1
const CELL: float = 48.0
const FILL_MARGIN_CELLS: int = 8     # 화면 밖으로 미리 칠해 두는 칸 수
const REFILL_STEP_CELLS: int = 4     # 카메라가 이만큼 움직이면 다시 칠한다

## 구역의 중심 (플레이어). TopView가 넣어 준다.
var follow_node: Node2D = null

var _filled_center: Vector2i = Vector2i(1 << 30, 1 << 30)

@onready var _floor: TileMapLayer = $Floor


func _process(_delta: float) -> void:
    var center: Vector2 = _view_center()
    var cell := Vector2i(floori(center.x / CELL), floori(center.y / CELL))
    if absi(cell.x - _filled_center.x) >= REFILL_STEP_CELLS or absi(cell.y - _filled_center.y) >= REFILL_STEP_CELLS:
        _fill_floor(cell)


## 구역의 중심 (플레이어 위치, 없으면 원점)
func zone_center() -> Vector2:
    return follow_node.global_position if follow_node != null else Vector2.ZERO


func _view_center() -> Vector2:
    var camera: Camera2D = get_viewport().get_camera_2d()
    return camera.get_screen_center_position() if camera != null else zone_center()


func _fill_floor(cell: Vector2i) -> void:
    _filled_center = cell
    var camera: Camera2D = get_viewport().get_camera_2d()
    var zoom: Vector2 = camera.zoom if camera != null else Vector2.ONE
    var half_view: Vector2 = get_viewport().get_visible_rect().size / zoom * 0.5
    var half := Vector2i(ceili(half_view.x / CELL), ceili(half_view.y / CELL)) + Vector2i.ONE * FILL_MARGIN_CELLS
    var keep: Vector2i = half + Vector2i.ONE * REFILL_STEP_CELLS * 2
    for used: Vector2i in _floor.get_used_cells():
        if absi(used.x - cell.x) > keep.x or absi(used.y - cell.y) > keep.y:
            _floor.erase_cell(used)
    for x: int in range(cell.x - half.x, cell.x + half.x + 1):
        for y: int in range(cell.y - half.y, cell.y + half.y + 1):
            var c := Vector2i(x, y)
            if _floor.get_cell_source_id(c) == -1:
                _floor.set_cell(c, FLOOR_SOURCE, Vector2i(posmod(x, 3), posmod(y, 3)))


# ── PartyLevel을 방 하나짜리 끝없는 바닥으로 바꾼다 ──

func room_quota(_index: int) -> int:
    return 0


func total_quota() -> int:
    return 0


func set_allocation(total: int) -> void:
    room_alloc.clear()
    room_alloc.append(total)
    room_load.clear()
    room_load.append(0)


## 방이 없으므로 소품 가운데의 큰 방 크기(ENDLESS_GATHER_SIZE)
func gather_area(point: Vector2) -> Rect2:
    var size: Vector2 = GameConfig.ENDLESS_GATHER_SIZE
    return Rect2(point - size * 0.5, size)


func room_at(_point: Vector2) -> int:
    return 0


func room_or_nearest(_point: Vector2) -> int:
    return 0


## 플레이어 둘레 구역 안의 무작위 지점
func random_point_in_room(_index: int) -> Vector2:
    var half: Vector2 = GameConfig.ENDLESS_ZONE_HALF
    return zone_center() + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))


## 걸어갈 곳: from_point에서 ENDLESS_WANDER_RADIUS 안(소품 위는 피함). from_point가 없으면 구역 안.
func random_point(from_point: Vector2 = Vector2.INF) -> Vector2:
    if from_point == Vector2.INF:
        return random_free_point_in_room(0)
    var radius: float = GameConfig.ENDLESS_WANDER_RADIUS
    var point: Vector2 = from_point + Vector2.from_angle(randf() * TAU) * randf_range(radius * 0.25, radius)
    for _attempt: int in FREE_POINT_ATTEMPTS:
        if not is_on_prop(point):
            break
        point = from_point + Vector2.from_angle(randf() * TAU) * randf_range(radius * 0.25, radius)
    return point


func clamp_point(point: Vector2, _room_hint: int = -1) -> Vector2:
    return point


func can_reach(_from_point: Vector2, _to_point: Vector2) -> bool:
    return true


func next_step(_from_point: Vector2, to_point: Vector2) -> Vector2:
    return to_point


func room_path(_a: int, _b: int) -> Array[int]:
    var path: Array[int] = [0]
    return path


func reachable_rooms(_from_room: int) -> Array[int]:
    var result: Array[int] = [0]
    return result
