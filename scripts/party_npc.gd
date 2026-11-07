class_name PartyNpc
extends CharacterBody2D
## 사람. 대기와 무작위 이동을 반복하고, 상황에 따라 다음과 같이 행동한다.
## - 소품 어그로: 지속 시간 동안 해당 지점에 모인다.
## - 따라오는 사람: follower_option이 켜져 있거나 반응을 충분히 받으면 일정 시간 플레이어를 따라온다.
## - 길막: 걷다가 플레이어에게 막히면 멈춰 서고, 오래 막히면 플레이어를 밀쳐 낸다.
## - 슬로우 댄스: 제자리 근처만 조금씩 움직인다.
## 다른 방으로 갈 때는 PartyLevel.next_step을 따라 열린 문을 지난다. 문이 닫혀 있으면 그 방으로 가지 않는다.
##
## 종류(kind). 값은 GameConfig의 각 종류 구역에서 조정한다.
## - normal: 위 기본 행동만 한다.
## - active(활발형): 1.5배 빠르고, 짧게 쉬고, 걷는 중에도 자주 방향을 바꾼다.
## - tracker(추적형): 10~30초마다 정해진 시간 동안 플레이어 쪽으로 온다.
## - attention(주의 집중형): 30~45초마다 주변 사람들을 자기 주위로 부르고, 그동안 제자리에 선다.
## - interactive(상호작용형): 1분 안팎마다 사용할 수 있는 소품으로 걸어가 작동시킨다.
## 특수 행동은 대기·걷기 중일 때만 시작하고, 다른 행동(어그로, 따라오기) 중이면 끝날 때까지 미룬다.
## 슬로우 댄스 중에는 특수 행동을 하지 않는다.

enum Mode { IDLE, WALK, AGGRO, FOLLOW }

const LAYER_NPC: int = 4
const MASK_WALL_AND_PLAYER: int = 1 | 2   # NPC끼리는 통과
const STUCK_MOVE_RATIO: float = 0.25      # 기대 이동량의 이 비율보다 적게 움직이면 막힌 것으로 본다
const BLOCK_HEADING_MIN_DOT: float = 0.3  # 목적지가 플레이어 쪽이어야 길막으로 본다
const EMOTE_RISE_PX: float = 40.0
const EMOTE_SEC: float = 0.8
const KIND_LABELS: Dictionary = {'normal': '', 'active': '활', 'tracker': '추', 'attention': '주', 'interactive': '상'}

## 생김새 번호(1부터). TopView가 정한다. 0이면 임시 그림.
var look: int = 0

## 사람 종류. TopView가 레벨의 npc_kinds에 따라 정한다.
@export_enum('normal', 'active', 'tracker', 'attention', 'interactive') var kind: String = 'normal'
## 켜 두면 주기적으로 플레이어를 따라온다.
@export var follower_option: bool = false

var follow_target: Node2D = null
var level: PartyLevel = null   # TopView가 생성할 때 넣어 준다
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
var _special_left: float = 0.0          # 다음 특수 행동까지 남은 시간
var _turn_left: float = 0.0             # 활발형: 다음 방향 전환까지
var _errand_prop: PartyProp = null      # 상호작용형: 작동시키러 가는 소품
var _errand_left: float = 0.0

@onready var _sprite: CharacterSprite = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    collision_layer = LAYER_NPC
    collision_mask = MASK_WALL_AND_PLAYER
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group('npcs')
    _sprite.sprite_frames = GameAssets.npc_frames(look)
    _sprite.setup(GameConfig.NPC_KIND_COLORS.get(kind, GameConfig.NPC_COLOR), GameConfig.NPC_RADIUS)
    var circle := CircleShape2D.new()
    circle.radius = GameConfig.NPC_RADIUS
    _shape.shape = circle
    _new_reaction_goal()
    _follow_cooldown = randf_range(0.0, GameConfig.FOLLOW_COOLDOWN)
    _special_left = _roll_special_interval()
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
    _cancel_errand()
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
    _errand_prop = null
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
    _update_special(delta)
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
            if _errand_prop != null:
                _update_errand(delta)
            else:
                _update_walk(delta)
        Mode.AGGRO:
            _aggro_left -= delta
            if _aggro_left <= 0.0 or not level.can_reach(global_position, _target):
                _dance_anchor = global_position
                _start_idle()
            elif global_position.distance_to(_target) > GameConfig.NPC_ARRIVE_DISTANCE:
                _move_to_target(GameConfig.NPC_AGGRO_SPEED * _speed_multiplier(), delta)
            else:
                velocity = Vector2.ZERO
        Mode.FOLLOW:
            _follow_left -= delta
            _target = follow_target.global_position
            if _follow_left <= 0.0:
                _dance_anchor = global_position
                _start_idle()
            elif not level.can_reach(global_position, _target):
                velocity = Vector2.ZERO   # 문이 닫혀 있으면 문 너머로 따라가지 못한다
            elif global_position.distance_to(_target) > GameConfig.FOLLOW_STOP_DISTANCE:
                _move_to_target(GameConfig.FOLLOW_SPEED * _speed_multiplier(), delta)
            else:
                velocity = Vector2.ZERO
    _sprite.set_motion(velocity)
    if GameState.debug_enabled:
        queue_redraw()


func _update_walk(delta: float) -> void:
    if not level.can_reach(global_position, _target):
        _start_walk()   # 가는 중에 문이 닫힘
    if kind == 'active' and not GameState.slow_dance_active:
        _turn_left -= delta
        if _turn_left <= 0.0:
            _start_walk()   # 활발형: 도착하기 전에 방향을 바꾼다
    _move_to_target(_walk_speed(), delta)
    if global_position.distance_to(_target) <= GameConfig.NPC_ARRIVE_DISTANCE:
        _start_idle()
    elif _stuck_time >= GameConfig.NPC_STUCK_TIMEOUT:
        _start_walk()


# ── 종류별 특수 행동 ──

func _roll_special_interval() -> float:
    var range_sec: Vector2 = Vector2.ZERO
    match kind:
        'tracker':
            range_sec = GameConfig.TRACKER_INTERVAL_RANGE
        'attention':
            range_sec = GameConfig.ATTENTION_INTERVAL_RANGE
        'interactive':
            range_sec = GameConfig.INTERACTIVE_INTERVAL_RANGE
        _:
            return INF
    return randf_range(range_sec.x, range_sec.y)


func _update_special(delta: float) -> void:
    if is_inf(_special_left) or GameState.slow_dance_active:
        return
    _special_left -= delta
    if _special_left > 0.0:
        return
    # 다른 행동 중이면 끝날 때까지 미룬다.
    var free: bool = _mode == Mode.IDLE or (_mode == Mode.WALK and _errand_prop == null)
    if not free:
        return
    _special_left = _roll_special_interval()
    match kind:
        'tracker':
            start_follow(GameConfig.TRACKER_DURATION)
            _show_text('?', Color(1.0, 0.45, 0.4))
        'attention':
            _call_attention()
        'interactive':
            _start_errand()


## 주의 집중형: 주변 사람들을 자기 주위로 부르고 제자리에 선다.
func _call_attention() -> void:
    GameState.emit_aggro(global_position, GameConfig.ATTENTION_RADIUS, GameConfig.ATTENTION_DURATION)
    # 자기 자신도 어그로를 받으므로, 부른 다음 대기로 덮어쓴다.
    _mode = Mode.IDLE
    velocity = Vector2.ZERO
    _idle_left = GameConfig.ATTENTION_DURATION
    _show_text('!', Color(0.8, 0.6, 1.0))


## 상호작용형: 지금 쓸 수 있고 갈 수 있는 소품 하나를 골라 걸어간다. 없으면 잠시 뒤 다시 시도.
func _start_errand() -> void:
    var choices: Array[PartyProp] = []
    for prop: PartyProp in level.get_props():
        if prop.is_ready() and level.can_reach(global_position, prop.global_position):
            choices.append(prop)
    if choices.is_empty():
        _special_left = GameConfig.INTERACTIVE_RETRY_SEC
        return
    _errand_prop = choices.pick_random()
    _errand_left = GameConfig.INTERACTIVE_GIVE_UP_SEC
    _mode = Mode.WALK
    _stuck_time = 0.0
    var prop_point: Vector2 = _errand_prop.global_position
    _target = level.clamp_point(prop_point, level.room_at(prop_point))
    _show_text('♪', Color(0.5, 0.95, 0.8))


## 소품으로 가던 중 다른 일(어그로, 따라오기)로 끊기면 잠시 뒤 다시 시도한다.
func _cancel_errand() -> void:
    if _errand_prop == null:
        return
    _errand_prop = null
    _special_left = minf(_special_left, GameConfig.INTERACTIVE_RETRY_SEC)


func _update_errand(delta: float) -> void:
    _errand_left -= delta
    var gave_up: bool = _errand_left <= 0.0 or not _errand_prop.is_ready() \
        or not level.can_reach(global_position, _target)
    if gave_up:
        # 시간이 너무 걸렸거나, 그새 누가 썼거나, 문이 닫힘
        _errand_prop = null
        _special_left = GameConfig.INTERACTIVE_RETRY_SEC
        _start_walk()
        return
    _move_to_target(_walk_speed(), delta)
    var near_prop: bool = global_position.distance_to(_errand_prop.global_position) <= GameConfig.INTERACTIVE_REACH
    if near_prop or global_position.distance_to(_target) <= GameConfig.NPC_ARRIVE_DISTANCE:
        var prop: PartyProp = _errand_prop
        _errand_prop = null
        prop.interact(self)
        # 소품 어그로 범위 안이면 그대로 따라 모이고, 아니면 쉰다.
        if _mode == Mode.WALK:
            _start_idle()


# ── 길막 ──

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
    var heading: Vector2 = global_position.direction_to(_steer_point())
    return heading.dot(to_player.normalized()) >= BLOCK_HEADING_MIN_DOT


# ── 이동 ──

func _should_start_follow() -> bool:
    return follower_option and _follow_cooldown <= 0.0 and not GameState.slow_dance_active


func _speed_multiplier() -> float:
    return GameConfig.ACTIVE_SPEED_MULTIPLIER if kind == 'active' else 1.0


func _walk_speed() -> float:
    var base: float = GameConfig.SLOW_DANCE_SPEED if GameState.slow_dance_active else GameConfig.NPC_SPEED
    return base * _speed_multiplier()


## 지금 향할 지점. 목적지가 다른 방이면 문 앞, 문 건너편 순서로 거친다.
func _steer_point() -> Vector2:
    return level.next_step(global_position, _target)


func _move_to_target(speed: float, delta: float) -> void:
    var before: Vector2 = global_position
    var goal: Vector2 = _steer_point()
    var dist: float = global_position.distance_to(goal)
    # 목적지를 지나치지 않도록 속도 제한
    velocity = global_position.direction_to(goal) * minf(speed, dist / delta)
    move_and_slide()
    if global_position.distance_to(before) < velocity.length() * delta * STUCK_MOVE_RATIO:
        _stuck_time += delta
    else:
        _stuck_time = 0.0


func _start_idle() -> void:
    _mode = Mode.IDLE
    velocity = Vector2.ZERO
    var range_sec: Vector2 = GameConfig.ACTIVE_IDLE_TIME_RANGE if kind == 'active' else GameConfig.NPC_IDLE_TIME_RANGE
    _idle_left = randf_range(range_sec.x, range_sec.y)


func _start_walk() -> void:
    _mode = Mode.WALK
    _errand_prop = null
    _stuck_time = 0.0
    _turn_left = randf_range(GameConfig.ACTIVE_TURN_TIME_RANGE.x, GameConfig.ACTIVE_TURN_TIME_RANGE.y)
    if GameState.slow_dance_active:
        var wander: float = GameConfig.SLOW_DANCE_WANDER
        var offset := Vector2(randf_range(-wander, wander), randf_range(-wander, wander))
        _target = level.clamp_point(_dance_anchor + offset, level.room_at(_dance_anchor))
    else:
        _target = level.random_point(global_position)


func _new_reaction_goal() -> void:
    _reaction_count = 0
    _reaction_goal = randi_range(GameConfig.REACTION_GOAL_RANGE.x, GameConfig.REACTION_GOAL_RANGE.y)


func _show_emote(positive: bool) -> void:
    _show_text('♥' if positive else '✖', Color(1.0, 0.4, 0.55) if positive else Color(0.55, 0.75, 1.0))


## 머리 위로 떠오르다 사라지는 글자
func _show_text(text_value: String, color: Color) -> void:
    var emote := Label.new()
    emote.text = text_value
    emote.add_theme_font_size_override('font_size', 32)
    emote.add_theme_color_override('font_color', color)
    emote.position = Vector2(-14.0, -GameConfig.NPC_RADIUS - 44.0)
    add_child(emote)
    var tween: Tween = emote.create_tween()
    tween.set_parallel()
    tween.tween_property(emote, 'position:y', emote.position.y - EMOTE_RISE_PX, EMOTE_SEC)
    tween.tween_property(emote, 'modulate:a', 0.0, EMOTE_SEC)
    tween.chain().tween_callback(emote.queue_free)


func _on_aggro(point: Vector2, radius: float, duration: float) -> void:
    if global_position.distance_to(point) > radius or not level.can_reach(global_position, point):
        return
    _cancel_errand()
    _mode = Mode.AGGRO
    _aggro_left = duration
    _stuck_time = 0.0
    var spread: float = GameConfig.NPC_AGGRO_SPREAD
    # 벽 너머 목적지가 나오지 않도록 어그로 지점이 있는 방 안쪽으로 제한
    var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
    _target = level.clamp_point(point + offset, level.room_at(point))


func _on_slow_dance_changed(active: bool) -> void:
    if not active:
        return
    _dance_anchor = global_position
    if _mode == Mode.WALK:
        _start_idle()


func _on_debug_changed(_enabled: bool) -> void:
    queue_redraw()


func _draw() -> void:
    if not GameState.debug_enabled:
        return
    if _mode != Mode.IDLE:
        draw_line(Vector2.ZERO, to_local(_target), Color(0, 1, 1, 0.5), 2.0)
    var label: String = String(KIND_LABELS.get(kind, ''))
    if label != '':
        draw_string(ThemeDB.fallback_font, Vector2(-10.0, -GameConfig.NPC_RADIUS - 6.0), label,
            HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
