# res://scripts/game_state.gd  (오토로드. class_name을 붙이지 않는다)
extends Node
## 게임 규칙의 유일한 판정자이자 A와 B의 계약.
## 시그널과 공개 메서드의 이름·시그니처를 바꾸려면 상대 파트와 먼저 상의한다.

enum State { INTRO, PLAYING, GAME_OVER, WON }
enum EndReason { NONE, CAUGHT, TOO_MANY_DMS, SURVIVED }

signal game_started()
signal phone_toggled(is_on: bool)
signal dm_arrived(stage: int)
signal dm_stage_changed(stage: int)
signal reply_resolved(success: bool)
signal tension_changed(value: float)
signal aggro_emitted(point: Vector2, radius: float, duration: float)
signal interact_hint_changed(text: String)
signal debug_changed(enabled: bool)
signal game_ended(reason: int)

var state: State = State.INTRO
var end_reason: EndReason = EndReason.NONE
var cfg: Dictionary = GameConfig.LEVELS[0]
var phone_on: bool = false
var dm_stage: int = 0
var elapsed_time: float = 0.0
var nearest_npc_px: float = INF
var tension: float = 0.0
var debug_enabled: bool = false
var intro_seen: bool = false
var _dm_timer: float = 0.0


func _ready() -> void:
    InputSetup.ensure_actions()


## 모든 값을 초기화한다. Main._enter_tree()에서 호출한다(자식 씬의 _ready보다 먼저).
## 인트로를 이미 봤으면(R 재시작) 바로 PLAYING으로 시작한다.
func start_game() -> void:
    cfg = GameConfig.LEVELS[0]
    end_reason = EndReason.NONE
    phone_on = false
    dm_stage = 0
    elapsed_time = 0.0
    nearest_npc_px = INF
    tension = 0.0
    _dm_timer = float(cfg['dm_interval'])
    state = State.PLAYING if intro_seen else State.INTRO


## 인트로 화면을 클릭했을 때 호출.
func begin_play() -> void:
    intro_seen = true
    state = State.PLAYING
    game_started.emit()


func is_playing() -> bool:
    return state == State.PLAYING


## Main이 매 프레임 호출. 순서: 시간 → DM 도착 → 긴장도 → 종료 판정
func tick(delta: float, nearest_px: float) -> void:
    if not is_playing():
        return
    elapsed_time += delta
    nearest_npc_px = nearest_px
    _dm_timer -= delta
    if _dm_timer <= 0.0:
        _dm_timer += float(cfg['dm_interval'])
        _set_dm_stage(dm_stage + 1)
        dm_arrived.emit(dm_stage)
    _update_tension(delta)
    _check_end()


## Q 또는 아이콘 클릭. 켜기 전용.
func open_phone() -> void:
    if is_playing() and not phone_on:
        phone_on = true
        phone_toggled.emit(true)


## 휴대폰 전원 버튼에서만 호출.
func close_phone() -> void:
    if is_playing() and phone_on:
        phone_on = false
        phone_toggled.emit(false)


func report_reply_success() -> void:
    if is_playing():
        _set_dm_stage(0)
        reply_resolved.emit(true)


## 제한 시간이 없어져 현재는 쓰지 않는다. 계약 유지를 위해 남겨 둠.
func report_reply_failed() -> void:
    if is_playing():
        _set_dm_stage(dm_stage + 1)
        reply_resolved.emit(false)


func emit_aggro(point: Vector2, radius: float, duration: float) -> void:
    aggro_emitted.emit(point, radius, duration)


## 마우스 떨림 폭(px). 휴대폰이 켜져 있을 때 PhoneView의 MouseTremor가 사용한다.
func get_tremor_px() -> float:
    return lerpf(GameConfig.TREMOR_MIN_PX, GameConfig.TREMOR_MAX_PX, tension)


func get_dm_badge_text() -> String:
    return String(GameConfig.DM_BADGE_TEXT[mini(dm_stage, GameConfig.MAX_DM_STAGE)])


## 왼쪽 위 시각. 180초 동안 11h 00 → 12h 00.
func get_clock_text() -> String:
    var ratio: float = clampf(elapsed_time / GameConfig.SURVIVE_TIME, 0.0, 1.0)
    var minutes: int = int(ratio * 60.0)
    if minutes >= 60:
        return '12h 00'
    return '11h %02d' % minutes


func set_debug(enabled: bool) -> void:
    debug_enabled = enabled
    debug_changed.emit(enabled)


func debug_add_stage() -> void:
    _set_dm_stage(dm_stage + 1)


func debug_clear_stage() -> void:
    _set_dm_stage(0)


func _set_dm_stage(value: int) -> void:
    var next: int = clampi(value, 0, GameConfig.MAX_DM_STAGE)
    if next != dm_stage:
        dm_stage = next
        dm_stage_changed.emit(dm_stage)


## 긴장도 = 근접도(경계 반경 260px → 발각 반경에서 0 → 1) × 0.7 + DM 단계 비율 × 0.3
## 목표값을 향해 오를 때는 빠르게, 내릴 때는 천천히 따라간다.
func _update_tension(delta: float) -> void:
    var caught: float = float(cfg['caught_radius'])
    var proximity: float = 0.0
    if not is_inf(nearest_npc_px):
        proximity = clampf(inverse_lerp(GameConfig.ALERT_RADIUS, caught, nearest_npc_px), 0.0, 1.0)
    var dm_ratio: float = float(dm_stage) / float(GameConfig.MAX_DM_STAGE)
    var target: float = clampf(
        GameConfig.TENSION_WEIGHT_PROXIMITY * proximity + GameConfig.TENSION_WEIGHT_DM * dm_ratio,
        0.0, 1.0
    )
    var rate: float = GameConfig.TENSION_RISE_PER_SEC if target > tension else GameConfig.TENSION_FALL_PER_SEC
    var next: float = move_toward(tension, target, rate * delta)
    if not is_equal_approx(next, tension):
        tension = next
        tension_changed.emit(tension)


## 같은 프레임에 겹치면 발각 → DM 10단계 → 승리 순.
func _check_end() -> void:
    if phone_on and nearest_npc_px < float(cfg['caught_radius']):
        _end_game(EndReason.CAUGHT)
    elif dm_stage >= GameConfig.MAX_DM_STAGE:
        _end_game(EndReason.TOO_MANY_DMS)
    elif elapsed_time >= GameConfig.SURVIVE_TIME:
        _end_game(EndReason.SURVIVED)


func _end_game(reason: EndReason) -> void:
    if not is_playing():
        return
    end_reason = reason
    state = State.WON if reason == EndReason.SURVIVED else State.GAME_OVER
    game_ended.emit(reason)
