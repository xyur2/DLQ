class_name PartyNpc
extends CharacterBody2D
## 0레벨 NPC: 대기와 무작위 이동을 반복하고 플레이어를 추적하지 않는다.
## 어그로 신호를 받으면 지속 시간 동안 해당 지점에 모인다.

enum Mode { IDLE, WALK, AGGRO }

const LAYER_NPC: int = 4
const MASK_WALL_AND_PLAYER: int = 1 | 2   # NPC끼리는 통과
const STUCK_MOVE_RATIO: float = 0.25      # 기대 이동량의 이 비율보다 적게 움직이면 막힌 것으로 본다

var _mode: Mode = Mode.IDLE
var _target: Vector2 = Vector2.ZERO
var _idle_left: float = 0.0
var _stuck_time: float = 0.0
var _aggro_left: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    collision_layer = LAYER_NPC
    collision_mask = MASK_WALL_AND_PLAYER
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group('npcs')
    var circle := CircleShape2D.new()
    circle.radius = GameConfig.NPC_RADIUS
    _shape.shape = circle
    # 처음엔 무작위 시간 동안 대기 → NPC끼리 박자가 겹치지 않음
    _start_idle()
    GameState.aggro_emitted.connect(_on_aggro)
    GameState.debug_changed.connect(_on_debug_changed)


## 사운드(발소리)용
func is_walking() -> bool:
    return velocity.length_squared() > 1.0


func _physics_process(delta: float) -> void:
    if not GameState.is_playing():
        velocity = Vector2.ZERO
        return
    match _mode:
        Mode.IDLE:
            velocity = Vector2.ZERO
            _idle_left -= delta
            if _idle_left <= 0.0:
                _start_walk()
        Mode.WALK:
            _move_to_target(GameConfig.NPC_SPEED, delta)
            if global_position.distance_to(_target) <= GameConfig.NPC_ARRIVE_DISTANCE:
                _start_idle()
            elif _stuck_time >= GameConfig.NPC_STUCK_TIMEOUT:
                _start_walk()
        Mode.AGGRO:
            _aggro_left -= delta
            if _aggro_left <= 0.0:
                _start_idle()
            elif global_position.distance_to(_target) > GameConfig.NPC_ARRIVE_DISTANCE:
                _move_to_target(GameConfig.NPC_AGGRO_SPEED, delta)
            else:
                velocity = Vector2.ZERO
    if GameState.debug_enabled:
        queue_redraw()


func _move_to_target(speed: float, delta: float) -> void:
    var before: Vector2 = global_position
    var dist: float = global_position.distance_to(_target)
    # 목적지를 지나치지 않도록 속도 제한
    velocity = global_position.direction_to(_target) * minf(speed, dist / delta)
    move_and_slide()
    if global_position.distance_to(before) < velocity.length() * delta * STUCK_MOVE_RATIO:
        _stuck_time += delta
    else:
        _stuck_time = 0.0


func _start_idle() -> void:
    _mode = Mode.IDLE
    velocity = Vector2.ZERO
    _idle_left = randf_range(GameConfig.NPC_IDLE_TIME_RANGE.x, GameConfig.NPC_IDLE_TIME_RANGE.y)


func _start_walk() -> void:
    _mode = Mode.WALK
    _stuck_time = 0.0
    _target = GameConfig.random_map_point()


func _on_aggro(point: Vector2, radius: float, duration: float) -> void:
    if global_position.distance_to(point) > radius:
        return
    _mode = Mode.AGGRO
    _aggro_left = duration
    _stuck_time = 0.0
    var spread: float = GameConfig.NPC_AGGRO_SPREAD
    # 벽 너머 목적지가 나오지 않도록 맵 안쪽으로 제한
    _target = GameConfig.clamp_to_map(point + Vector2(randf_range(-spread, spread), randf_range(-spread, spread)))


func _on_debug_changed(_enabled: bool) -> void:
    queue_redraw()


func _draw() -> void:
    draw_circle(Vector2.ZERO, GameConfig.NPC_RADIUS, GameConfig.NPC_COLOR)
    if GameState.debug_enabled and _mode != Mode.IDLE:
        draw_line(Vector2.ZERO, to_local(_target), Color(0, 1, 1, 0.5), 2.0)
