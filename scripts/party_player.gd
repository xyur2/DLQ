class_name PartyPlayer
extends CharacterBody2D
## 플레이어. WASD 이동, 근처 소품에 E. 휴대폰이 켜져 있으면 이동·상호작용 불가.

const LAYER_PLAYER: int = 2
const MASK_WALL_AND_NPC: int = 1 | 4
const LAYER_PROP: int = 8

var _facing: Vector2 = Vector2.DOWN
var _last_hint: String = ''

@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _area: Area2D = $InteractionArea
@onready var _area_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var _camera: Camera2D = $Camera2D
@onready var _listener: AudioListener2D = $AudioListener2D


func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask = MASK_WALL_AND_NPC
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

    # 크기는 GameConfig 기준으로 맞춘다.
    var circle := CircleShape2D.new()
    circle.radius = GameConfig.PLAYER_RADIUS
    _body_shape.shape = circle

    _area.collision_layer = 0
    _area.collision_mask = LAYER_PROP
    var area_circle := CircleShape2D.new()
    area_circle.radius = GameConfig.INTERACT_RANGE
    _area_shape.shape = area_circle

    # 중앙 고정 카메라: 스무딩과 리밋 없음
    _camera.position_smoothing_enabled = false
    _camera.make_current()
    _listener.make_current()

    GameState.debug_changed.connect(_on_debug_changed)


func _physics_process(_delta: float) -> void:
    var can_move: bool = GameState.is_playing() and not GameState.phone_on
    var direction: Vector2 = Vector2.ZERO
    if can_move:
        direction = Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
    velocity = direction * GameConfig.PLAYER_SPEED
    move_and_slide()
    if direction != Vector2.ZERO:
        _facing = direction.normalized()
        queue_redraw()
    _update_hint(can_move)


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed('interact'):
        return
    if not GameState.is_playing() or GameState.phone_on:
        return
    var prop: PartyProp = _nearest_prop()
    if prop != null:
        prop.interact(self)
    elif GameState.debug_enabled:
        print('상호작용 대상 없음')


func _nearest_prop() -> PartyProp:
    var best: PartyProp = null
    var best_distance: float = INF
    for area: Area2D in _area.get_overlapping_areas():
        if not area.is_in_group('interactable') or not (area is PartyProp):
            continue
        var distance: float = global_position.distance_to(area.global_position)
        if distance < best_distance:
            best_distance = distance
            best = area as PartyProp
    return best


## 안내 문구가 바뀔 때만 interact_hint_changed를 보낸다.
func _update_hint(can_move: bool) -> void:
    var hint: String = ''
    if can_move:
        var prop: PartyProp = _nearest_prop()
        if prop != null:
            hint = prop.get_hint()
    if hint != _last_hint:
        _last_hint = hint
        GameState.interact_hint_changed.emit(hint)


func _on_debug_changed(_enabled: bool) -> void:
    queue_redraw()


func _draw() -> void:
    draw_circle(Vector2.ZERO, GameConfig.PLAYER_RADIUS, GameConfig.PLAYER_COLOR)
    draw_circle(_facing * GameConfig.PLAYER_RADIUS * 0.7, 4.0, Color.BLACK)
    if GameState.debug_enabled:
        draw_arc(Vector2.ZERO, GameConfig.ALERT_RADIUS, 0.0, TAU, 64, Color(1, 1, 0, 0.35), 2.0)
        draw_arc(Vector2.ZERO, float(GameState.cfg['caught_radius']), 0.0, TAU, 64, Color(1, 0, 0, 0.5), 2.0)
