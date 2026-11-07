# res://scripts/game_state.gd  (오토로드. class_name을 붙이지 않는다)
extends Node
## 게임 규칙의 유일한 판정자이자 A와 B의 계약.
## 시그널과 공개 메서드의 이름·시그니처를 바꾸려면 상대 파트와 먼저 상의한다.

enum State { INTRO, PLAYING, ENDING, GAME_OVER, WON }
enum EndReason { NONE, CAUGHT, TOO_MANY_DMS, SURVIVED, HIDDEN }

signal phone_toggled(is_on: bool)
signal dm_arrived(stage: int)
signal dm_stage_changed(stage: int)
signal reply_resolved(success: bool)
signal tension_changed(value: float)
## area가 비어 있지 않으면 그 안(월드 좌표)에 있는 사람만 모인다 (방 전체를 모으는 소품).
signal aggro_emitted(point: Vector2, radius: float, duration: float, area: Rect2)
signal interact_hint_changed(text: String)
signal debug_changed(enabled: bool)
signal game_ended(reason: int)
signal score_changed(value: int)
signal reaction_sent(positive: bool)
signal easter_egg(id: String)
signal player_knocked_back(from_point: Vector2)
signal slow_dance_changed(active: bool)
signal circle_ending_started()
signal circle_scare_started()
signal endless_level_changed(level: int)
signal dance_started(duration: float)

var state: State = State.INTRO
var end_reason: EndReason = EndReason.NONE
var level_index: int = 0           # 현재 레벨(GameConfig.LEVELS 번호). R 재시작해도 유지되고, 승리 후 N으로 다음 레벨
var test_level: bool = false       # 테스트 맵(레벨 0, GameConfig.TEST_LEVEL)인지. 디버그로만 연다
var cfg: Dictionary = GameConfig.LEVELS[0]
var npc_total: int = 0             # 이 판의 사람 수. Main이 사람을 만든 뒤 넣는다 (히든 엔딩 판정)
var phone_on: bool = false
var dm_stage: int = 0
var elapsed_time: float = 0.0
var nearest_npc_px: float = INF
var tension: float = 0.0
var tremor_closeness: float = 0.0   # 손 떨림용 근접도 0~1 (TREMOR_FAR_RADIUS → 발각 반경)
var debug_enabled: bool = false
var endless_mode: bool = false     # 무한 모드: 시간이 다 돼도 승리하지 않고 끝날 때까지 점수를 쌓는다
var endless_level: int = 1         # 무한 모드 레벨. 게임 시간 1시간마다 오른다
var level_title_left: float = 0.0  # 위쪽 알림에 레벨 이름을 보여 줄 남은 시간 (시작할 때, 무한 레벨이 오를 때)
var score: int = 0
var stun_left: float = 0.0
var dance_left: float = 0.0        # 춤추는 남은 시간. 이 동안 행동 불가
var slow_dance_active: bool = false
var _dm_timer: float = 0.0
var _slow_dance_start: float = 0.0
var _blocked_npcs: Dictionary = {}
var _circle_armed: bool = false
var _ending_left: float = 0.0
var _scare_started: bool = false


func _ready() -> void:
    InputSetup.ensure_actions()
    GameSettings.load_and_apply()


## 모든 값을 초기화한다. Main._enter_tree()에서 호출한다(자식 씬의 _ready보다 먼저).
func start_game() -> void:
    level_index = clampi(level_index, 0, GameConfig.LEVELS.size() - 1)
    endless_level = 1
    if endless_mode:
        cfg = endless_config(1)
    else:
        cfg = GameConfig.TEST_LEVEL if test_level else GameConfig.LEVELS[level_index]
    level_title_left = GameConfig.LEVEL_TITLE_SEC
    end_reason = EndReason.NONE
    phone_on = false
    dm_stage = 0
    elapsed_time = 0.0
    nearest_npc_px = INF
    tension = 0.0
    tremor_closeness = 0.0
    _dm_timer = float(cfg['dm_interval'])
    score = 0
    stun_left = 0.0
    dance_left = 0.0
    slow_dance_active = false
    _slow_dance_start = randf_range(GameConfig.SLOW_DANCE_START_RANGE.x, GameConfig.SLOW_DANCE_START_RANGE.y)
    _blocked_npcs.clear()
    _circle_armed = false
    _ending_left = 0.0
    _scare_started = false
    state = State.PLAYING


func has_next_level() -> bool:
    return not endless_mode and not test_level and level_index + 1 < GameConfig.LEVELS.size()


## 다음 start_game()부터 적용된다. 씬을 다시 불러야 맵이 바뀐다.
func set_level(index: int) -> void:
    test_level = false
    level_index = clampi(index, 0, GameConfig.LEVELS.size() - 1)


## 디버그: 다음 start_game()부터 테스트 맵(레벨 0)으로 시작한다. set_level을 부르면 풀린다.
func set_test_level() -> void:
    test_level = true


func set_endless(enabled: bool) -> void:
    endless_mode = enabled


func get_level_title() -> String:
    return String(cfg['title'])


## 화면에 보이는 레벨 번호는 1부터 시작한다.
func get_level_label() -> String:
    if endless_mode:
        return 'Endless Mode %d' % endless_level
    return 'Level 0' if test_level else 'Level %d' % (level_index + 1)


## 무한 모드 레벨 level의 설정. 레벨이 오를수록 사람이 많아지고(상한 ENDLESS_NPC_MAX), DM 주기·쉬는 시간,
## 답장 문구, 글자 풍선은 일반 레벨 level(9 이상이면 레벨 9)과 같다. DM 주기는 레벨 5에서 상한.
static func endless_config(level: int) -> Dictionary:
    var step: int = maxi(level - 1, 0)
    var every_three: int = floori(step / 3.0)
    var text: Dictionary = GameConfig.LEVELS[mini(step, GameConfig.LEVELS.size() - 1)]
    return {
        'title': 'Endless Mode Level %d' % level,
        'scene': GameConfig.ENDLESS_SCENE,
        'npc_target': mini(GameConfig.ENDLESS_NPC_START + GameConfig.ENDLESS_NPC_STEP * step, GameConfig.ENDLESS_NPC_MAX),
        'npc_bonus': 0,
        'npc_kinds': {},
        'follower_count': mini(1 + every_three, GameConfig.ENDLESS_FOLLOWER_MAX),
        'dm_interval': text['dm_interval'],
        'reply_cooldown': text['reply_cooldown'],
        'reply_pool': text['reply_pool'],
        'letter_gap': text['letter_gap'],
        'letter_spread': text['letter_spread'],
        'caught_radius': 80.0,
        'decoy_count': text['decoy_count'],
        'wrong_lock_time': 2.0,
    }


func is_playing() -> bool:
    return state == State.PLAYING


## Main이 매 프레임 호출. 순서: 시간 → DM 도착 → 긴장도 → 종료 판정
func tick(delta: float, nearest_px: float) -> void:
    if state == State.ENDING:
        _update_ending(delta)
        return
    if not is_playing():
        return
    elapsed_time += delta
    level_title_left = maxf(0.0, level_title_left - delta)
    if endless_mode:
        _update_endless_level()
    stun_left = maxf(0.0, stun_left - delta)
    dance_left = maxf(0.0, dance_left - delta)
    _update_slow_dance()
    nearest_npc_px = nearest_px
    _dm_timer -= delta
    if _dm_timer <= 0.0:
        _dm_timer += float(cfg['dm_interval'])
        _set_dm_stage(dm_stage + 1)
        dm_arrived.emit(dm_stage)
    _update_tension(delta)
    _update_tremor(delta)
    _check_end()


## 무한 모드: 게임 시간 1시간마다 레벨을 올리고 설정(cfg)을 바꾼다. 다음 DM, 다음 단어부터 적용된다.
func _update_endless_level() -> void:
    var level: int = 1 + floori(elapsed_time / GameConfig.ENDLESS_LEVEL_SEC)
    if level <= endless_level:
        return
    endless_level = level
    cfg = endless_config(level)
    level_title_left = GameConfig.LEVEL_TITLE_SEC
    endless_level_changed.emit(level)


## Q 또는 아이콘 클릭. 켜기 전용.
func open_phone() -> void:
    if is_playing() and not phone_on and not is_stunned():
        phone_on = true
        _circle_armed = _is_everyone_blocked()
        phone_toggled.emit(true)


## 휴대폰 전원 버튼에서만 호출.
func close_phone() -> void:
    if is_playing() and phone_on:
        phone_on = false
        phone_toggled.emit(false)
        if _circle_armed:
            _start_circle_ending()


func report_reply_success() -> void:
    if is_playing():
        # 밀린 단계가 적을수록 점수가 높다.
        _add_score(maxi(GameConfig.SCORE_REPLY_MIN,
            GameConfig.SCORE_REPLY_BASE - (dm_stage - 1) * GameConfig.SCORE_REPLY_STAGE_PENALTY))
        _set_dm_stage(0)
        # 답장 후 reply_cooldown초 동안은 DM이 오지 않는다. 그 뒤 다시 dm_interval마다.
        _dm_timer = float(cfg['reply_cooldown'])
        reply_resolved.emit(true)


## 제한 시간이 없어져 현재는 쓰지 않는다. 계약 유지를 위해 남겨 둠.
func report_reply_failed() -> void:
    if is_playing():
        _set_dm_stage(dm_stage + 1)
        reply_resolved.emit(false)


## 틀린 글자를 눌렀을 때 PhoneView가 호출.
func report_wrong_letter() -> void:
    if is_playing():
        _add_score(-GameConfig.SCORE_WRONG_LETTER)


## 사람에게 반응을 보냈을 때 TopView가 호출.
## times_before: 이 사람이 전에 반응을 받은 횟수. 같은 사람을 여러 번 누를수록 점수가 줄어든다.
func report_reaction(positive: bool, times_before: int = 0) -> void:
    if is_playing():
        _add_score(reaction_score(times_before))
        reaction_sent.emit(positive)


## 같은 사람에게 times_before번 반응한 뒤 다시 반응할 때 얻는 점수. 처음 10점, 그다음부터 절반씩(내림), 0점까지.
static func reaction_score(times_before: int) -> int:
    return floori(GameConfig.SCORE_REACTION_FIRST * pow(GameConfig.SCORE_REACTION_DECAY, maxi(times_before, 0)))


## 사람이 길막으로 멈췄을 때 호출. 모든 사람을 막으면 히든 엔딩 조건이 된다.
func report_npc_blocked(npc_id: int) -> void:
    if is_playing():
        _blocked_npcs[npc_id] = true
        _add_score(GameConfig.SCORE_BLOCK)


## 길막이 길어졌을 때 호출. 플레이어는 밀려나고 잠시 아무것도 할 수 없다.
func report_long_block(from_point: Vector2) -> void:
    if is_playing() and not is_stunned():
        stun_left = GameConfig.STUN_DURATION
        player_knocked_back.emit(from_point)


## 밀려났거나 춤추는 중이면 이동, E, 반응, 휴대폰 켜기를 할 수 없다.
func is_stunned() -> bool:
    return stun_left > 0.0 or dance_left > 0.0


func is_dancing() -> bool:
    return dance_left > 0.0


## 조명 아래에서 사람과 춤춘다(DanceSpot). DANCE_SEC초 동안 행동 불가, DANCE_SCORE점. 시작했으면 true.
func start_dance() -> bool:
    if not is_playing() or phone_on or is_stunned():
        return false
    dance_left = GameConfig.DANCE_SEC
    _add_score(GameConfig.DANCE_SCORE)
    dance_started.emit(GameConfig.DANCE_SEC)
    return true


## 휴대폰에서 정해진 글자를 연속으로 입력했을 때 호출.
func trigger_easter_egg(id: String) -> void:
    if is_playing():
        easter_egg.emit(id)


func emit_aggro(point: Vector2, radius: float, duration: float, area: Rect2 = Rect2()) -> void:
    aggro_emitted.emit(point, radius, duration, area)


## 휴대폰 떨림 폭(px). PhoneView가 매 프레임 읽어 휴대폰을 흔든다.
## = BASE + DM × (단계/10) + NEAR × 근접도^CURVE
func get_tremor_px() -> float:
    var dm_ratio: float = float(dm_stage) / float(GameConfig.MAX_DM_STAGE)
    return GameConfig.TREMOR_BASE_PX + GameConfig.TREMOR_DM_PX * dm_ratio         + GameConfig.TREMOR_NEAR_PX * get_tremor_ratio()


## 근접도에 따른 떨림 비율 0~1. 떨림 속도(노이즈 속도)에 쓴다.
func get_tremor_ratio() -> float:
    return pow(tremor_closeness, GameConfig.TREMOR_CURVE)


func get_dm_badge_text() -> String:
    return String(GameConfig.DM_BADGE_TEXT[mini(dm_stage, GameConfig.MAX_DM_STAGE)])


## 왼쪽 위 시각. 180초 동안 11h 00 → 12h 00.
func get_clock_text() -> String:
    if endless_mode:
        # 무한 모드는 12시에서 멈추지 않고 계속 흐른다 (1시간 = ENDLESS_LEVEL_SEC).
        var total_minutes: int = floori(elapsed_time / GameConfig.ENDLESS_LEVEL_SEC * 60.0)
        return '%02dh %02d' % [(11 + floori(total_minutes / 60.0)) % 24, total_minutes % 60]
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


func _add_score(points: int) -> void:
    var next: int = maxi(0, score + points)
    if next != score:
        score = next
        score_changed.emit(score)


func _update_slow_dance() -> void:
    var active: bool = elapsed_time >= _slow_dance_start \
        and elapsed_time < _slow_dance_start + GameConfig.SLOW_DANCE_DURATION
    if active != slow_dance_active:
        slow_dance_active = active
        slow_dance_changed.emit(active)


func _is_everyone_blocked() -> bool:
    return npc_total > 0 and _blocked_npcs.size() >= npc_total


func _start_circle_ending() -> void:
    state = State.ENDING
    _ending_left = GameConfig.CIRCLE_STARE_SEC + GameConfig.CIRCLE_SCARE_SEC
    circle_ending_started.emit()


func _update_ending(delta: float) -> void:
    _ending_left -= delta
    if not _scare_started and _ending_left <= GameConfig.CIRCLE_SCARE_SEC:
        _scare_started = true
        circle_scare_started.emit()
    if _ending_left <= 0.0:
        _end_game(EndReason.HIDDEN)


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


## 손 떨림용 근접도. 긴장도보다 빨리 따라가서 사람이 멀어지면 바로 줄어든다.
func _update_tremor(delta: float) -> void:
    var closeness: float = 0.0
    if not is_inf(nearest_npc_px):
        closeness = clampf(
            inverse_lerp(GameConfig.TREMOR_FAR_RADIUS, float(cfg['caught_radius']), nearest_npc_px),
            0.0, 1.0
        )
    var rate: float = GameConfig.TREMOR_RISE_PER_SEC if closeness > tremor_closeness else GameConfig.TREMOR_FALL_PER_SEC
    tremor_closeness = move_toward(tremor_closeness, closeness, rate * delta)


## 같은 프레임에 겹치면 발각 → DM 10단계 → 승리 순.
func _check_end() -> void:
    if phone_on and nearest_npc_px < float(cfg['caught_radius']):
        _end_game(EndReason.CAUGHT)
    elif dm_stage >= GameConfig.MAX_DM_STAGE:
        _end_game(EndReason.TOO_MANY_DMS)
    elif elapsed_time >= GameConfig.SURVIVE_TIME and not endless_mode:
        _end_game(EndReason.SURVIVED)


func _end_game(reason: EndReason) -> void:
    if not is_playing() and state != State.ENDING:
        return
    end_reason = reason
    state = State.WON if reason == EndReason.SURVIVED else State.GAME_OVER
    game_ended.emit(reason)
