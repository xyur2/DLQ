class_name PartyNpc
extends CharacterBody2D
## 사람. 대기와 무작위 이동을 반복하고, 상황에 따라 다음과 같이 행동한다.
## - 소품 어그로: 지속 시간 동안 해당 지점에 모인다.
## - 따라오는 사람: follower_option이 켜져 있거나 반응을 충분히 받으면 일정 시간 플레이어를 따라온다.
## - 길막: 걷다가 플레이어에게 막히면 멈춰 서고, 오래 막히면 플레이어를 밀쳐 낸다.
## - 슬로우 댄스: 제자리 근처만 조금씩 움직인다.

enum Mode { IDLE, WALK, AGGRO, FOLLOW }

const LAYER_NPC: int = 4
const MASK_WALL_AND_PLAYER: int = 1 | 2   # NPC끼리는 통과
const STUCK_MOVE_RATIO: float = 0.25      # 기대 이동량의 이 비율보다 적게 움직이면 막힌 것으로 본다
const BLOCK_HEADING_MIN_DOT: float = 0.3  # 목적지가 플레이어 쪽이어야 길막으로 본다
const EMOTE_RISE_PX: float = 40.0
const EMOTE_SEC: float = 0.8

## 켜 두면 주기적으로 플레이어를 따라온다.
@export var follower_option: bool = false

var follow_target: Node2D = null
var _mode: Mode = Mode.IDLE
var _target: Vector2 = Vector2.ZERO
var _idle_left: float = 0.0
var _stuck_time: float = 0.0
var _aggro_left: float = 0.0
var _follow_left: float = 0.0
var _follow_cooldown: float = 0.0
var _block_time: float = 0.0
var _block_reported: bool = false
var _reaction_count: int = 0
var _reaction_goal: int = 0
var _reaction_cooldown: float = 0.0
var _dance_anchor: Vector2 = Vector2.ZERO

@onready var _sprite: CharacterSprite = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    collision_layer = LAYER_NPC
    collision_mask = MASK_WALL_AND_PLAYER
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group('npcs')
    _sprite.setup(GameConfig.NPC_COLOR, GameConfig.NPC_RADIUS)
    var circle := CircleShape2D.new()
    circle.radius = GameConfig.NPC_RADIUS
    _shape.shape = circle
    _new_reaction_goal()
    _follow_cooldown = randf_range(0.0, GameConfig.FOLLOW_COOLDOWN)
    # 처음엔 무작위 시간 동안 대기 → NPC끼리 박자가 겹치지 않음
    _start_idle()
    GameState.aggro_emitted.connect(_on_aggro)
    GameState.debug_changed.connect(_on_debug_changed)
    GameState.slow_dance_changed.connect(_on_slow_dance_changed)


## 사운드(발소리)용
func is_walking() -> bool:
    return velocity.length_squared() > 1.0


func is_following() -> bool:
    return _mode == Mode.FOLLOW


## 일정 시간 플레이어를 따라온다.
func start_follow(duration: float) -> void:
    if follow_target == null:
        return
    _mode = Mode.FOLLOW
    _follow_left = duration
    _stuck_time = 0.0


## 왼쪽 클릭(긍정)·오른쪽 클릭(부정). 연타 방지 시간 안이면 무시하고 false를 돌려준다.
func receive_reaction(positive: bool) -> bool:
    if _reaction_cooldown > 0.0:
        return false
    _reaction_cooldown = GameConfig.REACTION_COOLDOWN
    _show_emote(positive)
    _reaction_count += 1
    if _reaction_count >= _reaction_goal:
        _new_reaction_goal()
        start_follow(GameConfig.REACTION_FOLLOW_DURATION)
    return true


## 히든 엔딩: 지정된 자리로 옮겨 플레이어를 바라본다.
func surround(point: Vector2, look_at_point: Vector2) -> void:
    _mode = Mode.IDLE
    velocity = Vector2.ZERO
    global_position = point
    _sprite.face(look_at_point - point)


func _physics_process(delta: float) -> void:
    if not GameState.is_playing():
        velocity = Vector2.ZERO
        _sprite.set_motion(velocity)
        return
    _follow_cooldown = maxf(0.0, _follow_cooldown - delta)
    _reaction_cooldown = maxf(0.0, _reaction_cooldown - delta)
    if _update_block(delta):
        velocity = Vector2.ZERO
        _sprite.set_motion(velocity)
        return
    match _mode:
        Mode.IDLE:
            velocity = Vector2.ZERO
            _idle_left -= delta
            if _idle_left <= 0.0:
                if _should_start_follow():
                    _follow_cooldown = GameConfig.FOLLOW_COOLDOWN
                    start_follow(GameConfig.FOLLOW_DURATION)
                else:
                    _start_walk()
        Mode.WALK:
            _move_to_target(_walk_speed(), delta)
            if global_position.distance_to(_target) <= GameConfig.NPC_ARRIVE_DISTANCE:
                _start_idle()
            elif _stuck_time >= GameConfig.NPC_STUCK_TIMEOUT:
                _start_walk()
        Mode.AGGRO:
            _aggro_left -= delta
            if _aggro_left <= 0.0:
                _dance_anchor = global_position
                _start_idle()
            elif global_position.distance_to(_target) > GameConfig.NPC_ARRIVE_DISTANCE:
                _move_to_target(GameConfig.NPC_AGGRO_SPEED, delta)
            else:
                velocity = Vector2.ZERO
        Mode.FOLLOW:
            _follow_left -= delta
            _target = follow_target.global_position
            if _follow_left <= 0.0:
                _dance_anchor = global_position
                _start_idle()
            elif global_position.distance_to(_target) > GameConfig.FOLLOW_STOP_DISTANCE:
                _move_to_target(GameConfig.FOLLOW_SPEED, delta)
            else:
                velocity = Vector2.ZERO
    _sprite.set_motion(velocity)
    if GameState.debug_enabled:
        queue_redraw()


## 플레이어에게 막혀 있으면 true. 잠깐 막히면 길막으로 기록하고, 오래 막히면 플레이어를 밀쳐 낸다.
func _update_block(delta: float) -> bool:
    if not _is_blocked_by_player():
        _block_time = 0.0
        _block_reported = false
        return false
    _block_time += delta
    if not _block_reported and _block_time >= GameConfig.BLOCK_MARK_TIME:
        _block_reported = true
        GameState.report_npc_blocked(get_instance_id())
    if _block_time >= GameConfig.BLOCK_KNOCKBACK_TIME:
        _block_time = 0.0
        _block_reported = false
        GameState.report_long_block(global_position)
    return true


func _is_blocked_by_player() -> bool:
    if follow_target == null or GameState.phone_on or GameState.is_stunned():
        return false
    if _mode != Mode.WALK and _mode != Mode.AGGRO:
        return false
    var to_player: Vector2 = follow_target.global_position - global_position
    if to_player.length() > GameConfig.BLOCK_CONTACT_DISTANCE:
        return false
    var heading: Vector2 = global_position.direction_to(_target)
    return heading.dot(to_player.normalized()) >= BLOCK_HEADING_MIN_DOT


func _should_start_follow() -> bool:
    return follower_option and _follow_cooldown <= 0.0 and not GameState.slow_dance_active


func _walk_speed() -> float:
    return GameConfig.SLOW_DANCE_SPEED if GameState.slow_dance_active else GameConfig.NPC_SPEED


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
    if GameState.slow_dance_active:
        var wander: float = GameConfig.SLOW_DANCE_WANDER
        _target = GameConfig.clamp_to_map(_dance_anchor + Vector2(randf_range(-wander, wander), randf_range(-wander, wander)))
    else:
        _target = GameConfig.random_map_point()


func _new_reaction_goal() -> void:
    _reaction_count = 0
    _reaction_goal = randi_range(GameConfig.REACTION_GOAL_RANGE.x, GameConfig.REACTION_GOAL_RANGE.y)


func _show_emote(positive: bool) -> void:
    var emote := Label.new()
    emote.text = '♥' if positive else '✖'
    emote.add_theme_font_size_override('font_size', 32)
    emote.add_theme_color_override('font_color', Color(1.0, 0.4, 0.55) if positive else Color(0.55, 0.75, 1.0))
    emote.position = Vector2(-14.0, -GameConfig.NPC_RADIUS - 44.0)
    add_child(emote)
    var tween: Tween = emote.create_tween()
    tween.set_parallel()
    tween.tween_property(emote, 'position:y', emote.position.y - EMOTE_RISE_PX, EMOTE_SEC)
    tween.tween_property(emote, 'modulate:a', 0.0, EMOTE_SEC)
    tween.chain().tween_callback(emote.queue_free)


func _on_aggro(point: Vector2, radius: float, duration: float) -> void:
    if global_position.distance_to(point) > radius:
        return
    _mode = Mode.AGGRO
    _aggro_left = duration
    _stuck_time = 0.0
    var spread: float = GameConfig.NPC_AGGRO_SPREAD
    # 벽 너머 목적지가 나오지 않도록 맵 안쪽으로 제한
    _target = GameConfig.clamp_to_map(point + Vector2(randf_range(-spread, spread), randf_range(-spread, spread)))


func _on_slow_dance_changed(active: bool) -> void:
    if not active:
        return
    _dance_anchor = global_position
    if _mode == Mode.WALK:
        _start_idle()


func _on_debug_changed(_enabled: bool) -> void:
    queue_redraw()


func _draw() -> void:
    if GameState.debug_enabled and _mode != Mode.IDLE:
        draw_line(Vector2.ZERO, to_local(_target), Color(0, 1, 1, 0.5), 2.0)
