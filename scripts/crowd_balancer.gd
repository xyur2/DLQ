class_name CrowdBalancer
extends Node
## 방마다 사람이 너무 몰리지 않게 한다. TopView가 만들어 붙인다.
## BALANCE_INTERVAL마다 방별 인원(머무는 사람 + 그 방으로 가는 사람)을 세어 PartyLevel.room_load에 넣는다.
## 어떤 방의 인원이 목표 인원(room_alloc)보다 CROWD_MARGIN 이상 많으면, 목표 인원 + 1이 될 때까지(최소 한 명)
## 그 방 안에서 쉬거나 그 방 안을 걷는 사람을 빈자리가 있는 가장 가까운 방(문을 덜 지나는 방, 같으면 빈자리가 많은 방)으로 보낸다.
## 다른 방으로 가는 중인 사람은 건드리지 않는다(양쪽 방을 오가며 복도에 몰리는 것을 막음).
## 소품으로 모이는 사람, 따라오는 사람, 소품 심부름 중인 사람은 건드리지 않는다. 슬로우 댄스 중에는 세기만 한다.
##
## 한 방에 오래 머물기: 플레이어가 같은 방에 CAMP_START_SEC 이상 있으면 다른 방의 가장 가까운 사람을 하나씩
## 그 방으로 부른다(닫힌 문도 열고 들어옴). 간격은 점점 짧아진다. 그동안 그 방은 붐벼도 사람을 내보내지 않는다.

var level: PartyLevel = null
var npcs_root: Node = null
var player: Node2D = null
## 다른 방으로 보낸 누적 인원 (테스트와 디버그용)
var moved_count: int = 0
## 플레이어가 머무는 방과 머문 시간. 문틀 안(-1)에서는 이전 방을 유지한다.
var camp_room: int = -1
var camp_time: float = 0.0

var _left: float = 0.0
var _pull_left: float = 0.0


func setup(level_node: PartyLevel, npcs: Node, player_node: Node2D = null) -> void:
    level = level_node
    npcs_root = npcs
    player = player_node
    _left = GameConfig.BALANCE_INTERVAL


## 플레이어가 한 방에 오래 머물러 사람을 부르는 중인지
func is_camping() -> bool:
    return camp_room >= 0 and camp_time >= GameConfig.CAMP_START_SEC


func _physics_process(delta: float) -> void:
    if level == null or not GameState.is_playing():
        return
    _update_camp(delta)
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
        if i == camp_room and is_camping():
            continue   # 플레이어에게 모이는 중인 방은 붐벼도 내보내지 않는다
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


func _update_camp(delta: float) -> void:
    if player == null:
        return
    var room: int = level.room_at(player.global_position)
    if room >= 0 and room != camp_room:
        camp_room = room
        camp_time = 0.0
        return
    camp_time += delta
    if not is_camping():
        _pull_left = 0.0   # 30초가 되는 순간 첫 사람을 부른다
        return
    _pull_left -= delta
    if _pull_left > 0.0:
        return
    var ramp: float = clampf((camp_time - GameConfig.CAMP_START_SEC) / GameConfig.CAMP_RAMP_SEC, 0.0, 1.0)
    _pull_left = lerpf(GameConfig.CAMP_PULL_INTERVAL_START, GameConfig.CAMP_PULL_INTERVAL_MIN, ramp)
    _pull_one()


## 플레이어의 방 밖에 있고 보낼 수 있는 사람 중 플레이어에게 가장 가까운 사람을 그 방으로 부른다.
func _pull_one() -> void:
    var best: PartyNpc = null
    var best_distance: float = INF
    for node: Node in npcs_root.get_children():
        var npc := node as PartyNpc
        if npc == null or not npc.can_relocate() or npc.get_room_claim() == camp_room:
            continue
        var distance: float = npc.global_position.distance_to(player.global_position)
        if distance < best_distance:
            best_distance = distance
            best = npc
    if best == null:
        return
    best.relocate(level.random_free_point_in_room(camp_room), true)
    if camp_room < level.room_load.size():
        level.room_load[camp_room] += 1
    moved_count += 1


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
