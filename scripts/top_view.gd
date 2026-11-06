class_name TopView
extends Node2D
## 탑뷰 씬: 맵, 소품, 플레이어, NPC. 맵 배치(소품 위치)는 top_view.tscn에서 편집한다.

const NPC_SCENE: PackedScene = preload('res://scenes/top_view/npc.tscn')
const SPAWN_MAX_ATTEMPTS: int = 50

@onready var player: PartyPlayer = $Player
@onready var _npcs: Node2D = $NPCs


func _ready() -> void:
    player.position = GameConfig.MAP_SIZE * 0.5
    GameState.circle_ending_started.connect(_on_circle_ending_started)


## 플레이어에게서 NPC_SPAWN_MIN_DIST 이상 떨어진 곳에 NPC를 만든다.
func spawn_npcs(count: int) -> Array[PartyNpc]:
    var result: Array[PartyNpc] = []
    for i: int in count:
        var npc: PartyNpc = NPC_SCENE.instantiate()
        var point: Vector2 = GameConfig.random_map_point()
        for _attempt: int in SPAWN_MAX_ATTEMPTS:
            if point.distance_to(player.position) >= GameConfig.NPC_SPAWN_MIN_DIST:
                break
            point = GameConfig.random_map_point()
        npc.position = point
        npc.follow_target = player
        npc.follower_option = i < int(GameState.cfg['follower_count'])
        _npcs.add_child(npc)
        result.append(npc)
    return result


## 지나가는 사람을 클릭하면 반응을 보낸다. 왼쪽은 긍정, 오른쪽은 부정.
func _unhandled_input(event: InputEvent) -> void:
    var mb := event as InputEventMouseButton
    if mb == null or not mb.pressed:
        return
    if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
        return
    if not GameState.is_playing() or GameState.phone_on or GameState.is_stunned():
        return
    var npc: PartyNpc = _npc_at(get_canvas_transform().affine_inverse() * mb.position)
    if npc == null or player.global_position.distance_to(npc.global_position) > GameConfig.REACTION_RANGE:
        return
    get_viewport().set_input_as_handled()
    var positive: bool = mb.button_index == MOUSE_BUTTON_LEFT
    if npc.receive_reaction(positive):
        GameState.report_reaction(positive)


func _npc_at(point: Vector2) -> PartyNpc:
    var best: PartyNpc = null
    var best_distance: float = GameConfig.REACTION_CLICK_RADIUS
    for node: Node in _npcs.get_children():
        var npc := node as PartyNpc
        if npc != null and npc.global_position.distance_to(point) <= best_distance:
            best_distance = npc.global_position.distance_to(point)
            best = npc
    return best


## 히든 엔딩: 휴대폰을 끄고 보니 모든 사람이 플레이어를 둘러싸고 있다.
func _on_circle_ending_started() -> void:
    var everyone: Array[Node] = _npcs.get_children()
    var center: Vector2 = player.global_position
    for i: int in everyone.size():
        var angle: float = TAU * float(i) / float(everyone.size())
        var point: Vector2 = center + Vector2.RIGHT.rotated(angle) * GameConfig.CIRCLE_RADIUS
        (everyone[i] as PartyNpc).surround(point, center)


func nearest_npc_distance() -> float:
    var best: float = INF
    for node: Node in _npcs.get_children():
        var npc := node as Node2D
        if npc == null:
            continue
        best = minf(best, player.global_position.distance_to(npc.global_position))
    return best
