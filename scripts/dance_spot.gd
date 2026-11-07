class_name DanceSpot
extends Area2D
## 조명이 비추는 바닥(조명 소품의 어그로 지점). 플레이어가 이 안에 서서 E를 누르면 가까운 사람 한 명과 춤춘다.
## 춤추는 DANCE_SEC초 동안 플레이어는 아무것도 할 수 없고(GameState.is_stunned), DANCE_SCORE점을 얻는다.
## 조명 하나에 한 번만 출 수 있고, 춘 뒤에는 빛이 꺼진다.
## PartyProp(조명)이 자식으로 만든다. 소품·문과 같은 상호작용 규약(그룹 interactable, interact, get_hint)을 따른다.

const LAYER_INTERACTABLE: int = 8
const FADE_SEC: float = 0.6
const PULSE_SPEED: float = 3.0

var used: bool = false
var _time: float = 0.0
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
    if _partner(_player_position()) == null:
        return '조명 아래: 가까이 춤출 사람이 없다'
    return '[E] 함께 춤추기 (+%d점, %d초 동안 멈춤)' % [GameConfig.DANCE_SCORE, roundi(GameConfig.DANCE_SEC)]


func interact(player: Node) -> void:
    if used:
        return
    var player_position: Vector2 = (player as Node2D).global_position
    var partner: PartyNpc = _partner(player_position)
    if partner == null or not GameState.start_dance():
        return
    used = true
    remove_from_group('interactable')
    _shape.set_deferred('disabled', true)
    partner.start_dance(GameConfig.DANCE_SEC, player_position)


## from에서 DANCE_PARTNER_RANGE 안의 가장 가까운 사람
func _partner(from: Vector2) -> PartyNpc:
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
