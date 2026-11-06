class_name TopView
extends Node2D
## 탑뷰 씬: 맵, 소품, 플레이어, NPC. 맵 배치(소품 위치)는 top_view.tscn에서 편집한다.

const NPC_SCENE: PackedScene = preload('res://scenes/top_view/npc.tscn')
const SPAWN_MAX_ATTEMPTS: int = 50

@onready var player: PartyPlayer = $Player
@onready var _npcs: Node2D = $NPCs


func _ready() -> void:
    player.position = GameConfig.MAP_SIZE * 0.5


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
        _npcs.add_child(npc)
        result.append(npc)
    return result


func nearest_npc_distance() -> float:
    var best: float = INF
    for node: Node in _npcs.get_children():
        var npc := node as Node2D
        if npc == null:
            continue
        best = minf(best, player.global_position.distance_to(npc.global_position))
    return best
