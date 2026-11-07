class_name PartyLevel
extends Node2D
## 레벨 하나의 맵. scenes/top_view/levels/level_N.tscn의 루트에 붙는다.
## - rooms: 방 바닥(사람이 다닐 수 있는 곳). 벽 안쪽 좌표.
## - walls: 충돌 벽. 문이 들어갈 자리는 비워 둔다.
## - 자식 Props: 소품, Doors: 문(PartyDoor), PlayerStart: 플레이어 시작 위치.
## 사람(NPC)은 이 노드의 random_point / next_step으로 방 사이를 문을 거쳐 이동한다.

const WALL_LAYER: int = 1

## 방 바닥 영역 (벽 안쪽)
@export var rooms: Array[Rect2] = []
## 충돌 벽 영역. 문 자리는 비워 둔다.
@export var walls: Array[Rect2] = []
## 배경 이미지. rooms[0]에 맞춰 늘이거나 줄인다. 비우면 바닥과 격자를 그린다.
@export_file('*.png', '*.webp') var background_path: String = ''

var _doors: Array[PartyDoor] = []
var _background: Texture2D = null

@onready var _player_start: Marker2D = $PlayerStart


func _ready() -> void:
    for rect: Rect2 in walls:
        _add_wall(rect)
    var doors_node: Node = get_node_or_null('Doors')
    if doors_node != null:
        for node: Node in doors_node.get_children():
            if node is PartyDoor:
                _doors.append(node as PartyDoor)
    if background_path != '':
        _background = GameAssets.load_texture(background_path)
    queue_redraw()


func get_player_start() -> Vector2:
    return _player_start.global_position


## 이 레벨의 소품 (자식 Props 아래)
func get_props() -> Array[PartyProp]:
    var result: Array[PartyProp] = []
    var props_node: Node = get_node_or_null('Props')
    if props_node != null:
        for node: Node in props_node.get_children():
            if node is PartyProp:
                result.append(node as PartyProp)
    return result


## 점이 들어 있는 방 번호. 문틀 안처럼 어느 방에도 없으면 -1.
func room_at(point: Vector2) -> int:
    var local: Vector2 = to_local(point)
    for i: int in rooms.size():
        if rooms[i].has_point(local):
            return i
    return -1


## 방 하나 안의 무작위 지점 (벽에서 NPC_MAP_MARGIN 떨어진 곳)
func random_point_in_room(index: int) -> Vector2:
    var inner: Rect2 = rooms[index].grow(-GameConfig.NPC_MAP_MARGIN)
    return to_global(Vector2(
        randf_range(inner.position.x, inner.end.x),
        randf_range(inner.position.y, inner.end.y)
    ))


## 어느 방이든 무작위 지점. 넓은 방이 더 자주 뽑힌다. from_point를 주면 그곳에서 갈 수 있는 방만 고른다.
func random_point(from_point: Vector2 = Vector2.INF) -> Vector2:
    var candidates: Array[int] = []
    var total: float = 0.0
    for i: int in rooms.size():
        if from_point == Vector2.INF or _rooms_connected(room_at(from_point), i):
            candidates.append(i)
            total += rooms[i].get_area()
    if candidates.is_empty():
        return from_point
    var pick: float = randf() * total
    for i: int in candidates:
        pick -= rooms[i].get_area()
        if pick <= 0.0:
            return random_point_in_room(i)
    return random_point_in_room(candidates[-1])


## 점을 그 점이 속한 방(없으면 가장 가까운 방) 안쪽으로 제한한다.
func clamp_point(point: Vector2, room_hint: int = -1) -> Vector2:
    var index: int = room_hint if room_hint >= 0 else room_at(point)
    if index < 0:
        index = _nearest_room(point)
    var inner: Rect2 = rooms[index].grow(-GameConfig.NPC_MAP_MARGIN)
    var local: Vector2 = to_local(point)
    return to_global(Vector2(
        clampf(local.x, inner.position.x, inner.end.x),
        clampf(local.y, inner.position.y, inner.end.y)
    ))


## from에서 to로 갈 수 있는지 (같은 방이거나 열린 문으로 이어져 있음)
func can_reach(from_point: Vector2, to_point: Vector2) -> bool:
    return _rooms_connected(room_at(from_point), room_at(to_point))


## from에서 to로 갈 때 지금 향해야 할 지점. 다른 방이면 문 앞 → 문 건너편 → 목적지 순서.
## 갈 수 없으면 from을 그대로 돌려준다.
func next_step(from_point: Vector2, to_point: Vector2) -> Vector2:
    var from_room: int = room_at(from_point)
    var to_room: int = room_at(to_point)
    if from_room == to_room or to_room < 0:
        return to_point
    if from_room < 0:
        # 문틀 안: 목적지 방 쪽 문 앞으로 나간다.
        var near_door: PartyDoor = _nearest_door(from_point)
        return near_door.approach_point(to_room) if near_door != null else to_point
    var door: PartyDoor = _open_door_between(from_room, to_room)
    if door == null:
        return from_point
    # 문틀과 나란히 서 있고 문 앞 지점보다 문에 가까우면 건너편으로, 아니면 먼저 문 앞으로 간다.
    var near_side: Vector2 = door.approach_point(from_room)
    var normal: Vector2 = door.get_normal()
    var rel: Vector2 = from_point - door.global_position
    var lateral: float = absf(rel.dot(normal.orthogonal()))
    var depth: float = absf(rel.dot(normal))
    var near_depth: float = absf((near_side - door.global_position).dot(normal))
    var aligned: bool = lateral <= GameConfig.DOOR_WIDTH * 0.5 - GameConfig.NPC_RADIUS
    if aligned and depth <= near_depth + GameConfig.NPC_ARRIVE_DISTANCE * 3.0:
        return door.approach_point(to_room)
    return near_side


func _rooms_connected(a: int, b: int) -> bool:
    if a < 0 or b < 0 or a == b:
        return true
    return _open_door_between(a, b) != null


# TODO(확인필요): 문 하나로 바로 이어진 방 사이만 이동한다. 방이 3개 이상 이어지면 경로 탐색이 필요하다.
func _open_door_between(a: int, b: int) -> PartyDoor:
    for door: PartyDoor in _doors:
        if door.is_open and door.connects(a, b):
            return door
    return null


func _nearest_door(point: Vector2) -> PartyDoor:
    var best: PartyDoor = null
    var best_distance: float = INF
    for door: PartyDoor in _doors:
        var distance: float = door.global_position.distance_to(point)
        if distance < best_distance:
            best_distance = distance
            best = door
    return best


func _nearest_room(point: Vector2) -> int:
    var local: Vector2 = to_local(point)
    var best: int = 0
    var best_distance: float = INF
    for i: int in rooms.size():
        var center: Vector2 = rooms[i].get_center()
        var clamped := Vector2(
            clampf(local.x, rooms[i].position.x, rooms[i].end.x),
            clampf(local.y, rooms[i].position.y, rooms[i].end.y)
        )
        var distance: float = clamped.distance_to(local) + center.distance_to(local) * 0.001
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _add_wall(rect: Rect2) -> void:
    var body := StaticBody2D.new()
    body.collision_layer = WALL_LAYER
    body.collision_mask = 0
    body.position = rect.get_center()
    var shape := CollisionShape2D.new()
    var box := RectangleShape2D.new()
    box.size = rect.size
    shape.shape = box
    body.add_child(shape)
    add_child(body)


func _draw() -> void:
    for rect: Rect2 in walls:
        draw_rect(rect, GameConfig.WALL_COLOR)
    for i: int in rooms.size():
        var room: Rect2 = rooms[i]
        if i == 0 and _background != null:
            draw_texture_rect(_background, room, false)
            continue
        draw_rect(room, GameConfig.FLOOR_COLOR)
        # 격자: 카메라가 플레이어를 따라가므로 이동감을 준다.
        var x: float = room.position.x
        while x <= room.end.x:
            draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), GameConfig.GRID_COLOR)
            x += GameConfig.GRID_STEP
        var y: float = room.position.y
        while y <= room.end.y:
            draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), GameConfig.GRID_COLOR)
            y += GameConfig.GRID_STEP
