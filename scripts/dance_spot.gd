class_name DanceSpot
extends Area2D
## 조명이 비추는 바닥(조명 소품의 어그로 지점). 플레이어가 이 안에 서서 E를 누르면 가까운 사람 한 명과 춤춘다.
## 춤추는 DANCE_SEC초 동안 플레이어와 짝은 서로 마주 보며 둘 사이 가운데를 DANCE_TURNS바퀴 돈다(처음과 끝은 천천히).
## 그동안 플레이어는 아무것도 할 수 없고(GameState.is_stunned), DANCE_SCORE점을 얻는다.
## 조명 하나에 한 번만 출 수 있고, 춘 뒤에는 빛이 꺼진다.
## PartyProp(조명)이 자식으로 만든다. 소품·문과 같은 상호작용 규약(그룹 interactable, interact, get_hint)을 따른다.

const LAYER_INTERACTABLE: int = 8
const FADE_SEC: float = 0.6
const PULSE_SPEED: float = 3.0

var used: bool = false
var _time: float = 0.0
var _player: Node2D = null
var _partner: PartyNpc = null
var _center: Vector2 = Vector2.ZERO      # 둘 사이 가운데 (도는 기준점)
var _offset: Vector2 = Vector2.ZERO      # 가운데에서 플레이어까지
var _dance_time: float = -1.0            # 춤이 시작된 뒤 지난 시간. 음수면 춤추지 않음
var _fade: float = 1.0
var _shape: CollisionShape2D = null
var _soft: GradientTexture2D = null


func _ready() -> void:
    collision_layer = LAYER_INTERACTABLE
    collision_mask = 0
    monitoring = false
    add_to_group('interactable')
    # 플레이어의 상호작용 범위(INTERACT_RANGE)와 겹치면 잡히므로, 플레이어 중심이 빛 반경 안일 때만 겹치도록 줄인다.
    var circle := CircleShape2D.new()
    circle.radius = maxf(GameConfig.DANCE_SPOT_RADIUS - GameConfig.INTERACT_RANGE, 4.0)
    _shape = CollisionShape2D.new()
    _shape.shape = circle
    add_child(_shape)
    var glow := CanvasItemMaterial.new()
    glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = glow
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
    _soft = GradientTexture2D.new()
    _soft.gradient = gradient
    _soft.fill = GradientTexture2D.FILL_RADIAL
    _soft.fill_from = Vector2(0.5, 0.5)
    _soft.fill_to = Vector2(1.0, 0.5)


func _process(delta: float) -> void:
    _time += delta
    if used:
        _fade = move_toward(_fade, 0.0, delta / FADE_SEC)
        if _fade <= 0.0:
            visible = false
            set_process(false)
    queue_redraw()


func _draw() -> void:
    var color: Color = GameConfig.DANCE_SPOT_COLOR
    color.a *= (0.8 + 0.2 * sin(_time * PULSE_SPEED)) * _fade
    var radius: float = GameConfig.DANCE_SPOT_RADIUS
    draw_texture_rect(_soft, Rect2(-Vector2.ONE * radius * 1.3, Vector2.ONE * radius * 2.6), false, color)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, color.a * 1.6), 3.0, true)


func get_hint() -> String:
    if _find_partner(_player_position()) == null:
        return 'Under the light: nobody close enough to dance'
    return '[E] Dance together (+%d, frozen %ds)' % [GameConfig.DANCE_SCORE, roundi(GameConfig.DANCE_SEC)]


func interact(player: Node) -> void:
    if used:
        return
    var player_position: Vector2 = (player as Node2D).global_position
    var partner: PartyNpc = _find_partner(player_position)
    if partner == null or not GameState.start_dance():
        return
    used = true
    remove_from_group('interactable')
    _shape.set_deferred('disabled', true)
    partner.start_dance(GameConfig.DANCE_SEC)
    _player = player as Node2D
    _partner = partner
    _center = (player_position + partner.global_position) * 0.5
    _offset = player_position - _center
    _dance_time = 0.0


## 춤: 플레이어와 짝을 둘 사이 가운데를 기준으로 마주 보게 돌린다.
func _physics_process(delta: float) -> void:
    if _dance_time < 0.0:
        return
    _dance_time += delta
    var progress: float = clampf(_dance_time / GameConfig.DANCE_SEC, 0.0, 1.0)
    var rel: Vector2 = _offset.rotated(TAU * GameConfig.DANCE_TURNS * smoothstep(0.0, 1.0, progress))
    var player_alive: bool = is_instance_valid(_player)
    var partner_alive: bool = is_instance_valid(_partner)
    if player_alive:
        _player.global_position = _center + rel
    if partner_alive:
        _partner.global_position = _center - rel
    if player_alive and partner_alive:
        _player.call('face_toward', _partner.global_position)
        _partner.face_toward(_player.global_position)
    if progress >= 1.0:
        _dance_time = -1.0


## from에서 DANCE_PARTNER_RANGE 안의 가장 가까운 사람
func _find_partner(from: Vector2) -> PartyNpc:
    var best: PartyNpc = null
    var best_distance: float = GameConfig.DANCE_PARTNER_RANGE
    for node: Node in get_tree().get_nodes_in_group('npcs'):
        var npc := node as PartyNpc
        if npc == null or npc.is_queued_for_deletion():
            continue
        var distance: float = npc.global_position.distance_to(from)
        if distance <= best_distance:
            best_distance = distance
            best = npc
    return best


func _player_position() -> Vector2:
    var players: Array[Node] = get_tree().get_nodes_in_group('player')
    return (players[0] as Node2D).global_position if not players.is_empty() else global_position
