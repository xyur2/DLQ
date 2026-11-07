class_name EndlessSpawner
extends Node
## 무한 모드: 플레이어 둘레 구역(ENDLESS_ZONE_HALF)의 사람과 소품 수를 맞춘다. TopView가 만들어 붙인다.
## ENDLESS_SPAWN_INTERVAL마다
## - 구역에서 ENDLESS_DESPAWN_MARGIN보다 멀고 화면 밖인 사람과 (안 쓴) 소품을 지운다. 따라오는 중인 사람은 남긴다.
## - 사람이 목표 인원(cfg['npc_target'])보다 적으면 구역 안, 화면 밖 무작위 자리에 새로 만든다.
##   따라오는 옵션은 지금 있는 사람 중 cfg['follower_count']명이 되도록 새 사람에게 준다.
## - 안 쓴 소품이 ENDLESS_PROP_COUNT보다 적으면 같은 식으로 새로 만든다. 종류는 무작위, 한 번 쓰면 사라진다.

const PROP_SCENE: PackedScene = preload('res://scenes/top_view/prop.tscn')
const PROP_IDS: Array[String] = ['speaker', 'light', 'playlist']
const SPOT_ATTEMPTS: int = 30

## 누적 수 (테스트와 디버그용)
var npcs_spawned: int = 0
var npcs_removed: int = 0
var props_spawned: int = 0
var props_removed: int = 0

var _top_view: TopView = null
var _level: EndlessLevel = null
var _player: Node2D = null
var _npcs_root: Node = null
var _left: float = 0.0


func setup(top_view: TopView, level: EndlessLevel, player: Node2D, npcs_root: Node) -> void:
    _top_view = top_view
    _level = level
    _player = player
    _npcs_root = npcs_root
    _left = 0.0


func _physics_process(delta: float) -> void:
    if _level == null or not GameState.is_playing():
        return
    _left -= delta
    if _left > 0.0:
        return
    _left = GameConfig.ENDLESS_SPAWN_INTERVAL
    refresh()


func refresh() -> void:
    var view: Rect2 = _view_rect().grow(GameConfig.ENDLESS_VIEW_MARGIN)
    var half: Vector2 = GameConfig.ENDLESS_ZONE_HALF
    var zone := Rect2(_player.global_position - half, half * 2.0)
    var keep: Rect2 = zone.grow(GameConfig.ENDLESS_DESPAWN_MARGIN)

    var alive: Array[PartyNpc] = []
    var followers: int = 0
    for node: Node in _npcs_root.get_children():
        var npc := node as PartyNpc
        if npc == null or npc.is_queued_for_deletion():
            continue
        var far: bool = not keep.has_point(npc.global_position) and not view.has_point(npc.global_position)
        if far and not npc.is_following():
            npc.queue_free()
            npcs_removed += 1
            continue
        alive.append(npc)
        if npc.follower_option:
            followers += 1
    for _k: int in maxi(0, int(GameState.cfg['npc_target']) - alive.size()):
        var point: Vector2 = _free_point(zone, view, alive)
        if point == Vector2.INF:
            break
        var follower: bool = followers < int(GameState.cfg['follower_count'])
        if follower:
            followers += 1
        alive.append(_top_view.create_npc(point, 'normal', follower))
        npcs_spawned += 1

    var unused_props: int = 0
    for prop: PartyProp in _level.get_props():
        if prop.is_queued_for_deletion() or prop.used_up:
            continue
        if not keep.has_point(prop.global_position) and not view.has_point(prop.global_position):
            prop.queue_free()
            props_removed += 1
            continue
        unused_props += 1
    for _k: int in maxi(0, GameConfig.ENDLESS_PROP_COUNT - unused_props):
        var point: Vector2 = _free_point(zone, view, alive)
        if point == Vector2.INF:
            break
        _spawn_prop(point)


## 구역 안, 화면 밖이고 소품 위가 아니며 다른 사람과 떨어진 무작위 지점. 못 찾으면 Vector2.INF.
func _free_point(zone: Rect2, view: Rect2, others: Array[PartyNpc]) -> Vector2:
    for _attempt: int in SPOT_ATTEMPTS:
        var point: Vector2 = zone.position + Vector2(randf(), randf()) * zone.size
        if view.has_point(point) or _level.is_on_prop(point):
            continue
        var crowded: bool = false
        for other: PartyNpc in others:
            if other.global_position.distance_to(point) < GameConfig.NPC_SPAWN_SPACING:
                crowded = true
                break
        if not crowded:
            return point
    return Vector2.INF


func _spawn_prop(point: Vector2) -> void:
    var prop: PartyProp = PROP_SCENE.instantiate()
    var prop_id: String = PROP_IDS.pick_random()
    prop.prop_id = prop_id
    prop.single_use = true
    prop.aggro_offset = Vector2.from_angle(randf() * TAU) * float(GameConfig.ENDLESS_AGGRO_OFFSETS[prop_id])
    prop.position = _level.to_local(point)
    _level.get_node('Props').add_child(prop)
    props_spawned += 1


## 지금 화면에 보이는 월드 영역
func _view_rect() -> Rect2:
    var camera: Camera2D = get_viewport().get_camera_2d()
    var size: Vector2 = get_viewport().get_visible_rect().size
    if camera == null:
        return Rect2(_player.global_position - size * 0.5, size)
    size /= camera.zoom
    return Rect2(camera.get_screen_center_position() - size * 0.5, size)
