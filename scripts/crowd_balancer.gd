class_name CrowdBalancer
extends Node
## 방마다 사람이 너무 몰리지 않게 한다. TopView가 만들어 붙인다.
## BALANCE_INTERVAL마다 방별 인원(머무는 사람 + 그 방으로 가는 사람)을 세어 PartyLevel.room_load에 넣는다.
## 어떤 방의 인원이 목표 인원(room_alloc)보다 CROWD_MARGIN 이상 많으면, 목표 인원 + 1이 될 때까지(최소 한 명)
## 그 방 안에서 쉬거나 그 방 안을 걷는 사람을 빈자리가 있는 가장 가까운 방(문을 덜 지나는 방, 같으면 빈자리가 많은 방)으로 보낸다.
## 다른 방으로 가는 중인 사람은 건드리지 않는다(양쪽 방을 오가며 복도에 몰리는 것을 막음).
## 소품으로 모이는 사람, 따라오는 사람, 소품 심부름 중인 사람은 건드리지 않는다. 슬로우 댄스 중에는 세기만 한다.

var level: PartyLevel = null
var npcs_root: Node = null
## 다른 방으로 보낸 누적 인원 (테스트와 디버그용)
var moved_count: int = 0

var _left: float = 0.0


func setup(level_node: PartyLevel, npcs: Node) -> void:
    level = level_node
    npcs_root = npcs
    _left = GameConfig.BALANCE_INTERVAL


func _physics_process(delta: float) -> void:
    if level == null or not GameState.is_playing():
        return
    _left -= delta
    if _left > 0.0:
        return
    _left = GameConfig.BALANCE_INTERVAL
    balance()


func balance() -> void:
    var room_count: int = level.rooms.size()
    var load: Array[int] = []
    var movable: Array = []   # 방마다 보낼 수 있는 사람
    for i: int in room_count:
        load.append(0)
        movable.append([])
    for node: Node in npcs_root.get_children():
        var npc := node as PartyNpc
        if npc == null:
            continue
        var claim: int = npc.get_room_claim()
        load[claim] += 1
        if npc.can_relocate() and level.room_at(npc.global_position) == claim:
            (movable[claim] as Array).append(npc)
    level.room_load = load
    if GameState.slow_dance_active or level.room_alloc.size() != room_count:
        return
    for i: int in room_count:
        var over: int = load[i] - level.room_alloc[i]
        if over < GameConfig.CROWD_MARGIN:
            continue
        var to_move: int = over - 1
        var candidates: Array = movable[i]
        candidates.shuffle()
        for npc: PartyNpc in candidates:
            if to_move <= 0:
                break
            var dest: int = _pick_room(i, load)
            if dest < 0:
                break
            npc.relocate(level.random_free_point_in_room(dest))
            load[i] -= 1
            load[dest] += 1
            to_move -= 1
            moved_count += 1
    level.room_load = load


## from_room에서 갈 수 있고 빈자리가 있는 방 중 문을 가장 덜 지나는 방, 같으면 빈자리가 많은 방. 없으면 -1.
func _pick_room(from_room: int, load: Array[int]) -> int:
    var best: int = -1
    var best_vacancy: int = 0
    var best_hops: int = 0
    for j: int in level.reachable_rooms(from_room):
        if j == from_room:
            continue
        var vacancy: int = level.room_alloc[j] - load[j]
        if vacancy <= 0:
            continue
        var hops: int = level.room_path(from_room, j).size()
        if best < 0 or hops < best_hops or (hops == best_hops and vacancy > best_vacancy):
            best = j
            best_vacancy = vacancy
            best_hops = hops
    return best
