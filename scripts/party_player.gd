class_name PartyPlayer
extends CharacterBody2D
## 플레이어. WASD 이동, 근처 소품·문·춤추는 자리에 E. 휴대폰이 켜져 있거나 밀려났거나 춤추는 중이면 이동·상호작용 불가.

const LAYER_PLAYER: int = 2
const MASK_WALL_AND_NPC: int = 1 | 4
const LAYER_PROP: int = 8

var _last_hint: String = ''
var _camera_tween: Tween = null
var _knockback_left: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: CharacterSprite = $Sprite
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _area: Area2D = $InteractionArea
@onready var _area_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var _camera: Camera2D = $Camera2D
@onready var _listener: AudioListener2D = $AudioListener2D


func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask = MASK_WALL_AND_NPC
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group('player')
    _sprite.setup(GameConfig.PLAYER_COLOR, GameConfig.PLAYER_RADIUS)

    # 크기는 GameConfig 기준으로 맞춘다.
    var circle := CircleShape2D.new()
    circle.radius = GameConfig.PLAYER_RADIUS
    _body_shape.shape = circle

    _area.collision_layer = 0
    _area.collision_mask = LAYER_PROP
    var area_circle := CircleShape2D.new()
    area_circle.radius = GameConfig.INTERACT_RANGE
    _area_shape.shape = area_circle

    # 중앙 고정 카메라: 스무딩과 리밋 없음. 확대해서 보이는 범위를 줄인다.
    _camera.position_smoothing_enabled = false
    _camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM
    _camera.make_current()
    _listener.make_current()

    GameState.debug_changed.connect(_on_debug_changed)
    GameState.player_knocked_back.connect(_on_knocked_back)


func _physics_process(delta: float) -> void:
    var can_move: bool = GameState.is_playing() and not GameState.phone_on and not GameState.is_stunned()
    var direction: Vector2 = Vector2.ZERO
    if can_move:
        direction = Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
    velocity = direction * GameConfig.PLAYER_SPEED
    if _knockback_left > 0.0:
        _knockback_left -= delta
        velocity = _knockback_velocity
    move_and_slide()
    _sprite.set_motion(Vector2.ZERO if _knockback_left > 0.0 else velocity)
    _update_hint(can_move)


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed('interact'):
        return
    if not GameState.is_playing() or GameState.phone_on or GameState.is_stunned():
        return
    var target: Area2D = _nearest_interactable()
    if target != null:
        target.call('interact', self)
    elif GameState.debug_enabled:
        print('Nothing to interact with')


## 상호작용 대상 규약: Area2D, 그룹 'interactable', 메서드 interact(player)와 get_hint(). (소품, 문)
func _nearest_interactable() -> Area2D:
    var best: Area2D = null
    var best_distance: float = INF
    for area: Area2D in _area.get_overlapping_areas():
        if not area.is_in_group('interactable') or not area.has_method('interact') or not area.has_method('get_hint'):
            continue
        var distance: float = global_position.distance_to(area.global_position)
        if distance < best_distance:
            best_distance = distance
            best = area
    return best


## 안내 문구가 바뀔 때만 interact_hint_changed를 보낸다.
func _update_hint(can_move: bool) -> void:
    var hint: String = ''
    if can_move:
        var target: Area2D = _nearest_interactable()
        if target != null:
            hint = String(target.call('get_hint'))
    if hint != _last_hint:
        _last_hint = hint
        GameState.interact_hint_changed.emit(hint)


func _on_knocked_back(from_point: Vector2) -> void:
    _knockback_left = GameConfig.KNOCKBACK_DURATION
    _knockback_velocity = from_point.direction_to(global_position) * GameConfig.KNOCKBACK_SPEED


## 춤추는 동안 짝을 바라본다 (DanceSpot이 부름).
func face_toward(point: Vector2) -> void:
    _sprite.face(point - global_position)


## 춤추는 동안 카메라를 point(둘 사이 가운데)에 고정한다.
func hold_camera(point: Vector2) -> void:
    if _camera_tween != null:
        _camera_tween.kill()
    _camera.top_level = true
    _camera.global_position = point


## 고정한 카메라를 DANCE_CAMERA_RETURN_SEC 동안 플레이어에게 옮긴 뒤 다시 플레이어를 따라가게 한다.
func release_camera() -> void:
    if not _camera.top_level:
        return
    var from: Vector2 = _camera.global_position
    _camera_tween = create_tween()
    _camera_tween.tween_method(func(weight: float) -> void:
        _camera.global_position = from.lerp(global_position, weight),
        0.0, 1.0, GameConfig.DANCE_CAMERA_RETURN_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _camera_tween.tween_callback(func() -> void:
        _camera.top_level = false
        _camera.position = Vector2.ZERO)


func _on_debug_changed(_enabled: bool) -> void:
    queue_redraw()


func _draw() -> void:
    if GameState.debug_enabled:
        draw_arc(Vector2.ZERO, GameConfig.ALERT_RADIUS, 0.0, TAU, 64, Color(1, 1, 0, 0.35), 2.0)
        draw_arc(Vector2.ZERO, float(GameState.cfg['caught_radius']), 0.0, TAU, 64, Color(1, 0, 0, 0.5), 2.0)
