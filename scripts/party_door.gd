class_name PartyDoor
extends Area2D
## 두 방 사이의 문. 기본은 열림. 근처에서 E를 누르면 열고 닫는다.
## 닫혀 있으면 벽처럼 사람과 플레이어를 막는다. 누가 문틀에 서 있으면 닫히지 않는다.
## 위치는 레벨 씬에서 벽의 빈자리 가운데에 놓는다.

const LAYER_INTERACTABLE: int = 8
const WALL_LAYER: int = 1
const BODY_MASK: int = 2 | 4   # 플레이어, 사람

## 이 문이 잇는 두 방 번호 (PartyLevel.rooms의 순서)
@export var room_a: int = 0
@export var room_b: int = 1
## true: 세로 벽에 난 문(좌우로 지나감), false: 가로 벽에 난 문(위아래로 지나감)
@export var vertical_wall: bool = true
@export var start_open: bool = true

var is_open: bool = true
var _blocked_hint_left: float = 0.0

@onready var _area_shape: CollisionShape2D = $CollisionShape2D
@onready var _blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D


func _ready() -> void:
    collision_layer = LAYER_INTERACTABLE
    collision_mask = 0
    add_to_group('interactable')
    var area_box := RectangleShape2D.new()
    area_box.size = _size()
    _area_shape.shape = area_box
    var blocker_box := RectangleShape2D.new()
    blocker_box.size = _size()
    _blocker_shape.shape = blocker_box
    ($Blocker as StaticBody2D).collision_layer = WALL_LAYER
    ($Blocker as StaticBody2D).collision_mask = 0
    _set_open(start_open)


func _process(delta: float) -> void:
    if _blocked_hint_left > 0.0:
        _blocked_hint_left -= delta


func connects(a: int, b: int) -> bool:
    return (a == room_a and b == room_b) or (a == room_b and b == room_a)


## 문을 지나가는 방향 (세로 벽이면 좌우, 가로 벽이면 위아래)
func get_normal() -> Vector2:
    return Vector2.RIGHT if vertical_wall else Vector2.DOWN


## 문 앞 지점. room 쪽으로 문에서 조금 떨어진 곳.
func approach_point(room: int) -> Vector2:
    var level: PartyLevel = _level()
    var normal: Vector2 = get_normal()
    var side: float = 1.0
    if level != null and room >= 0 and room < level.rooms.size():
        var room_center: Vector2 = level.to_global(level.rooms[room].get_center())
        side = signf((room_center - global_position).dot(normal))
        if side == 0.0:
            side = 1.0
    var offset: float = GameConfig.WALL_THICKNESS * 0.5 + GameConfig.NPC_RADIUS + GameConfig.DOOR_APPROACH_GAP
    return global_position + normal * side * offset


func get_hint() -> String:
    if _blocked_hint_left > 0.0:
        return 'Someone is in the doorway'
    return '[E] Close door' if is_open else '[E] Open door'


func interact(_player: Node) -> void:
    if is_open and _is_doorway_occupied():
        _blocked_hint_left = 1.0
        return
    var closing: bool = is_open
    _set_open(not is_open)
    if _player is Node2D:
        Achievements.event('door_toggled', {'closed': closing, 'other_count': _count_other_side(_player as Node2D)})


## 사람이 닫힌 문을 열고 들어올 때 (PartyNpc). 이미 열려 있으면 아무 일도 없다.
func open_by_npc() -> void:
    if not is_open:
        _set_open(true)
        GameState.report_door_opened_by_npc(global_position)


## 플레이어 반대편 방에 있는 사람 수
func _count_other_side(player: Node2D) -> int:
    var level: PartyLevel = _level()
    if level == null:
        return 0
    var other: int = room_b if level.room_at(player.global_position) == room_a else room_a
    var count: int = 0
    for npc: Node in get_tree().get_nodes_in_group('npcs'):
        if level.room_at((npc as Node2D).global_position) == other:
            count += 1
    return count


func _set_open(open: bool) -> void:
    is_open = open
    _blocker_shape.set_deferred('disabled', open)
    queue_redraw()


## 문틀 안에 플레이어나 사람이 있으면 true
func _is_doorway_occupied() -> bool:
    var query := PhysicsShapeQueryParameters2D.new()
    var box := RectangleShape2D.new()
    box.size = _size()
    query.shape = box
    query.transform = global_transform
    query.collision_mask = BODY_MASK
    query.collide_with_bodies = true
    return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _size() -> Vector2:
    if vertical_wall:
        return Vector2(GameConfig.WALL_THICKNESS, GameConfig.DOOR_WIDTH)
    return Vector2(GameConfig.DOOR_WIDTH, GameConfig.WALL_THICKNESS)


func _level() -> PartyLevel:
    var node: Node = get_parent()
    while node != null and not (node is PartyLevel):
        node = node.get_parent()
    return node as PartyLevel


func _draw() -> void:
    var size: Vector2 = _size()
    var rect := Rect2(-size * 0.5, size)
    if is_open:
        # 열린 문: 문짝이 벽 쪽으로 젖혀진 모습
        var panel_rect: Rect2
        if vertical_wall:
            panel_rect = Rect2(Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x, 6.0))
        else:
            panel_rect = Rect2(Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(6.0, size.y))
        draw_rect(panel_rect, GameConfig.DOOR_COLOR)
        draw_rect(rect, GameConfig.DOOR_OPEN_COLOR, false, 2.0)
    else:
        draw_rect(rect.grow(-2.0), GameConfig.DOOR_COLOR)
        draw_rect(rect.grow(-2.0), GameConfig.DOOR_COLOR.darkened(0.4), false, 2.0)
