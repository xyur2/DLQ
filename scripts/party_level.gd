class_name PartyLevel
extends Node2D
## 레벨 하나의 맵. scenes/top_view/levels/level_N.tscn의 루트에 붙는다.
## - rooms: 방 바닥(사람이 다닐 수 있는 곳). 벽 안쪽 좌표. 사람의 이동 계산에 쓰므로 타일을 바꾸면 함께 맞춘다.
## - 자식 Floor, Walls(TileMapLayer): 바닥과 벽 타일. 칸은 48px이고, 벽 충돌은 TileSet의 물리 레이어가 맡는다.
## - 자식 Props: 소품, Doors: 문(PartyDoor), PlayerStart: 플레이어 시작 위치.
## 사람(NPC)은 이 노드의 random_point / next_step으로 방 사이를 문을 거쳐 이동한다.
## 방은 열린 문으로 이어진 그래프이고, 여러 방을 거쳐 가는 길은 너비 우선 탐색으로 찾는다.
## 방마다 목표 인원(room_alloc)이 있고, 사람은 빈자리가 많은 방을 더 자주 목적지로 고른다(CrowdBalancer 참고).

const FREE_POINT_ATTEMPTS: int = 12

## 방 바닥 영역 (벽 안쪽)
@export var rooms: Array[Rect2] = []

## 방마다 목표 인원. TopView가 set_allocation()으로 정한다. 비어 있으면 넓이로만 목적지를 고른다.
var room_alloc: Array[int] = []
## 방마다 지금 머물거나 가는 중인 사람 수. CrowdBalancer가 주기적으로 갱신한다.
var room_load: Array[int] = []

var _doors: Array[PartyDoor] = []

@onready var _player_start: Marker2D = $PlayerStart


func _ready() -> void:
    _add_obstacle_shadows()
    var doors_node: Node = get_node_or_null('Doors')
    if doors_node != null:
        for node: Node in doors_node.get_children():
            if node is PartyDoor:
                _doors.append(node as PartyDoor)


## 장애물마다 외곽선 모양 그림자(DropShadow)를 깐다. 높이는 장애물 씬 루트의 metadata/shadow_height(없으면 low).
func _add_obstacle_shadows() -> void:
    var obstacles: Node = get_node_or_null('Obstacles')
    if obstacles == null:
        return
    for box: Node in obstacles.get_children():
        if box.has_node('Shadow'):
            continue
        var height: String = String(box.get_meta('shadow_height', 'low'))
        var image: Sprite2D = box.get_node_or_null('Image') as Sprite2D
        var fill: Polygon2D = box.get_node_or_null('Fill') as Polygon2D
        if image != null:
            DropShadow.add_for_sprite(image, height)
        elif fill != null:
            DropShadow.add_for_polygon(fill, height)


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


## 방 넓이로 정한 기본 인원. 큰 방(960×720)이 6명, 작은 방(480×528)이 2명이 되도록 AREA_PER_NPC로 나눈다.
func room_quota(index: int) -> int:
    return maxi(1, roundi(rooms[index].get_area() / GameConfig.AREA_PER_NPC))


func total_quota() -> int:
    var total: int = 0
    for i: int in rooms.size():
        total += room_quota(i)
    return total


## 전체 인원 total을 방마다 나눈다. 기본 인원을 먼저 주고, 남는 인원(레벨 추가 인원)은 기본 인원 비율로 나눈다.
## 나머지는 소수 부분이 큰 방부터, 같으면 넓은 방부터 한 명씩 준다.
func set_allocation(total: int) -> void:
    var quota_sum: int = total_quota()
    var extra: int = maxi(0, total - quota_sum)
    room_alloc.clear()
    room_load.clear()
    var fractions: Array[Vector2] = []   # (소수 부분, 방 번호)
    var given: int = 0
    for i: int in rooms.size():
        var share: float = float(extra) * float(room_quota(i)) / float(quota_sum)
        room_alloc.append(room_quota(i) + floori(share))
        room_load.append(0)
        given += floori(share)
        fractions.append(Vector2(share - floorf(share), i))
    fractions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
        if not is_equal_approx(a.x, b.x):
            return a.x > b.x
        return rooms[int(a.y)].get_area() > rooms[int(b.y)].get_area())
    for k: int in extra - given:
        room_alloc[int(fractions[k % fractions.size()].y)] += 1


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


## 방 전체를 모으는 소품이 모으는 범위: point가 있는 방(월드 좌표)
func gather_area(point: Vector2) -> Rect2:
    var room: Rect2 = rooms[room_or_nearest(point)]
    return Rect2(to_global(room.position), room.size)


## 점이 들어 있는 방, 문틀 안이면 가장 가까운 방
func room_or_nearest(point: Vector2) -> int:
    var index: int = room_at(point)
    return index if index >= 0 else _nearest_room(point)


## 방 안에서 소품 위가 아닌 무작위 지점
func random_free_point_in_room(index: int) -> Vector2:
    var point: Vector2 = random_point_in_room(index)
    for _attempt: int in FREE_POINT_ATTEMPTS:
        if not is_on_prop(point):
            break
        point = random_point_in_room(index)
    return point


## 어느 방이든 무작위 지점. from_point를 주면 그곳에서 갈 수 있는 방만 고른다.
## 목표 인원이 정해져 있으면 빈자리(목표 − 지금 인원)가 많은 방일수록, 지나는 문이 적은 방일수록 자주 뽑힌다.
## 목표 인원이 없으면 넓은 방일수록 자주 뽑힌다.
func random_point(from_point: Vector2 = Vector2.INF) -> Vector2:
    var point: Vector2 = _any_room_point(from_point)
    for _attempt: int in FREE_POINT_ATTEMPTS:
        if not is_on_prop(point):
            break
        point = _any_room_point(from_point)
    return point


## 소품 위거나 소품에 너무 가까운 지점인지
func is_on_prop(point: Vector2) -> bool:
    for prop: PartyProp in get_props():
        if prop.get_body_rect().grow(GameConfig.NPC_RADIUS).has_point(point):
            return true
    for rect: Rect2 in _obstacle_rects():
        if rect.grow(GameConfig.NPC_RADIUS).has_point(point):
            return true
    return false


## 자식 Obstacles 아래의 장애물(StaticBody2D + 사각형 충돌) 영역. 사람이 그 위로 목적지를 잡거나 생성되지 않게 한다.
func _obstacle_rects() -> Array[Rect2]:
    var result: Array[Rect2] = []
    var obstacles: Node = get_node_or_null('Obstacles')
    if obstacles == null:
        return result
    for body: Node in obstacles.get_children():
        var shape_node: CollisionShape2D = body.get_node_or_null('CollisionShape2D')
        if shape_node != null and shape_node.shape is RectangleShape2D:
            var size_value: Vector2 = (shape_node.shape as RectangleShape2D).size
            result.append(Rect2(shape_node.global_position - size_value * 0.5, size_value))
    return result


func _any_room_point(from_point: Vector2) -> Vector2:
    var candidates: Array[int] = []
    var weights: Array[float] = []
    var total: float = 0.0
    var from_room: int = -1 if from_point == Vector2.INF else room_at(from_point)
    for i: int in rooms.size():
        if from_point == Vector2.INF or _rooms_connected(from_room, i):
            var weight: float = _pick_weight(i)
            if from_room >= 0 and i != from_room and not room_alloc.is_empty():
                weight *= pow(GameConfig.CROWD_HOP_FALLOFF, room_path(from_room, i).size() - 1)
            candidates.append(i)
            weights.append(weight)
            total += weight
    if candidates.is_empty():
        return from_point
    var pick: float = randf() * total
    for k: int in candidates.size():
        pick -= weights[k]
        if pick <= 0.0:
            return random_point_in_room(candidates[k])
    return random_point_in_room(candidates[-1])


func _pick_weight(index: int) -> float:
    if room_alloc.size() != rooms.size() or room_load.size() != rooms.size():
        return rooms[index].get_area()
    return maxf(float(room_alloc[index] - room_load[index]), 0.0) + GameConfig.CROWD_PICK_BASE


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
    return _next_step(from_point, to_point, false)


# ── 닫힌 문을 열고 가는 사람용 (PartyNpc의 문 열기) ──

## 닫힌 문도 지날 수 있다고 칠 때 from에서 to로 갈 수 있는지
func can_reach_through_doors(from_point: Vector2, to_point: Vector2) -> bool:
    return _rooms_connected(room_at(from_point), room_at(to_point), true)


## 닫힌 문도 지날 수 있다고 칠 때의 next_step. 닫힌 문 앞에 오면 closed_door_ahead()로 문을 연다.
func next_step_through_doors(from_point: Vector2, to_point: Vector2) -> Vector2:
    return _next_step(from_point, to_point, true)


## from에서 to로 갈 때 바로 다음에 지날 문이 닫혀 있으면 그 문, 아니면 null
func closed_door_ahead(from_point: Vector2, to_point: Vector2) -> PartyDoor:
    var from_room: int = room_at(from_point)
    var path: Array[int] = room_path_any(from_room, room_at(to_point), true)
    if path.size() < 2:
        return null
    var door: PartyDoor = _door_between(path[0], path[1], true)
    return door if door != null and not door.is_open else null


## from_point에서 닫힌 문을 하나 이상 열어야 갈 수 있는 방 중 하나의 지점. 고르지 않으면 Vector2.INF.
## 그런 방 중 사람이 0명인 방(room_load 기준, 플레이어 제외)이 있으면 DOOR_OPEN_EMPTY_CHANCE 확률로 그 방,
## 아니면 DOOR_OPEN_CHANCE 확률로 아무 방이나 고른다. 고른 방의 인원은 바로 1 늘려 여러 명이 한꺼번에 몰리지 않게 한다.
func closed_room_point(from_point: Vector2) -> Vector2:
    var from_room: int = room_at(from_point)
    if from_room < 0 or _doors.is_empty():
        return Vector2.INF
    var empty: Array[int] = []
    var closed: Array[int] = []
    for i: int in rooms.size():
        if _rooms_connected(from_room, i) or not _rooms_connected(from_room, i, true):
            continue   # 열린 문으로 이미 갈 수 있거나, 아예 이어져 있지 않음
        closed.append(i)
        if i < room_load.size() and room_load[i] == 0:
            empty.append(i)
    var pick: int = -1
    if not empty.is_empty() and randf() < GameConfig.DOOR_OPEN_EMPTY_CHANCE:
        pick = empty.pick_random()
    elif not closed.is_empty() and randf() < GameConfig.DOOR_OPEN_CHANCE:
        pick = closed.pick_random()
    if pick < 0:
        return Vector2.INF
    if pick < room_load.size():
        room_load[pick] += 1
    return random_free_point_in_room(pick)


func _next_step(from_point: Vector2, to_point: Vector2, any_door: bool) -> Vector2:
    var from_room: int = room_at(from_point)
    var to_room: int = room_at(to_point)
    if from_room == to_room or to_room < 0:
        return to_point
    if from_room < 0:
        # 문틀 안: 목적지까지 더 가까운 쪽 방의 문 앞으로 나간다.
        var near_door: PartyDoor = _nearest_door(from_point)
        return near_door.approach_point(_exit_side(near_door, to_room, any_door)) if near_door != null else to_point
    var path: Array[int] = room_path_any(from_room, to_room, any_door)
    if path.size() < 2:
        return from_point
    # 여러 방을 거쳐야 하면 바로 다음 방으로 가는 문부터 지난다.
    to_room = path[1]
    var door: PartyDoor = _door_between(from_room, to_room, any_door)
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


func _rooms_connected(a: int, b: int, any_door: bool = false) -> bool:
    if a < 0 or b < 0 or a == b:
        return true
    return not room_path_any(a, b, any_door).is_empty()


## a에서 b까지 열린 문으로 지나는 방 순서 [a, ..., b]. 갈 수 없으면 빈 배열. 문 수가 가장 적은 길.
func room_path(a: int, b: int) -> Array[int]:
    return room_path_any(a, b, false)


## room_path와 같고, any_door가 true면 닫힌 문도 지날 수 있다고 친다.
func room_path_any(a: int, b: int, any_door: bool) -> Array[int]:
    var result: Array[int] = []
    if a < 0 or b < 0:
        return result
    var came_from: Dictionary = {a: -1}
    var queue: Array[int] = [a]
    while not queue.is_empty():
        var current: int = queue.pop_front()
        if current == b:
            break
        for door: PartyDoor in _doors:
            if not door.is_open and not any_door:
                continue
            var next: int = -1
            if door.room_a == current:
                next = door.room_b
            elif door.room_b == current:
                next = door.room_a
            if next >= 0 and not came_from.has(next):
                came_from[next] = current
                queue.append(next)
    if not came_from.has(b):
        return result
    var step: int = b
    while step != -1:
        result.push_front(step)
        step = came_from[step]
    return result


## 방 from_room에서 갈 수 있는 방들 (자기 자신 포함)
func reachable_rooms(from_room: int) -> Array[int]:
    var result: Array[int] = []
    for i: int in rooms.size():
        if _rooms_connected(from_room, i):
            result.append(i)
    return result


## 문틀 안에서 목적지로 갈 때 나갈 쪽 방: 문이 잇는 두 방 중 목적지까지 문을 덜 지나는 쪽
func _exit_side(door: PartyDoor, to_room: int, any_door: bool = false) -> int:
    var via_a: Array[int] = room_path_any(door.room_a, to_room, any_door)
    var via_b: Array[int] = room_path_any(door.room_b, to_room, any_door)
    if via_a.is_empty():
        return door.room_b
    if via_b.is_empty():
        return door.room_a
    return door.room_a if via_a.size() <= via_b.size() else door.room_b


## a와 b를 잇는 문. any_door가 false면 열린 문만, true면 열린 문을 먼저 찾고 없으면 닫힌 문.
func _door_between(a: int, b: int, any_door: bool) -> PartyDoor:
    var closed: PartyDoor = null
    for door: PartyDoor in _doors:
        if not door.connects(a, b):
            continue
        if door.is_open:
            return door
        if any_door and closed == null:
            closed = door
    return closed


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
