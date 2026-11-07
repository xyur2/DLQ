extends CanvasLayer
## 업적 오토로드(Achievements). 달성 기록과 누적 횟수는 user://achievements.cfg에 저장해 게임을 꺼도 남는다.
## 판정은 GameState 신호와 다른 스크립트가 부르는 event()로 한다. 목록은 AchievementList.
## 달성하면 왼쪽 아래에 이름과 설명이 효과음과 함께 떴다 사라진다(여럿이면 차례로).
## 테스트 맵(레벨 0)에서는 게임 안 업적을 세지 않는다.

signal unlocked(id: String)

const SAVE_PATH: String = 'user://achievements.cfg'
const TOAST_SHOW_SEC: float = 3.5
const TOAST_SLIDE_SEC: float = 0.3
const TOAST_HIDDEN_X: float = -700.0
# 테스트 맵에서도 세는 메뉴·설정 업적
const MENU_EVENTS: Array[String] = ['menu_power', 'menu_99', 'how_to', 'volume']
const CLEAR_ACHIEVEMENTS: Dictionary = {1: 'perfect_alibi', 2: 'party_survivor', 5: 'halfway_home', 7: 'hallway_hero', 9: 'last_call'}
const LEVEL_GROUPS: Array = [[[1, 2, 3], 'room_by_room'], [[4, 5, 6], 'every_room_counts'], [[7, 8, 9], 'the_long_night'], [[1, 2, 3, 4, 5, 6, 7, 8, 9], 'full_party']]
const ENDLESS_LEVELS: Dictionary = {3: 'night_owl', 5: 'endless_party', 10: 'sunrise'}
const PROP_FIRST_USE: Dictionary = {'speaker': 'turn_it_up', 'light': 'lights_camera', 'playlist': 'dj_booth'}

var _file := ConfigFile.new()
var _run: Dictionary = {}           # 이번 판 기록
var _queue: Array[String] = []
var _showing: bool = false

@onready var _toast: Control = $Toast
@onready var _toast_name: Label = $Toast/Name
@onready var _toast_desc: Label = $Toast/Desc
@onready var _sound: AudioStreamPlayer = $Sound


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _file.load(SAVE_PATH)   # 파일이 없으면 빈 채로 둔다
    _toast.visible = false
    _sound.stream = AudioDirector.load_sound('achievement')
    if _sound.stream == null:
        _sound.stream = AudioDirector.load_sound('send')
    GameState.game_started.connect(_on_game_started)
    GameState.game_ended.connect(_on_game_ended)
    GameState.score_changed.connect(_on_score_changed)
    GameState.reply_resolved.connect(_on_reply_resolved)
    GameState.wrong_letter_pressed.connect(_on_wrong_letter)
    GameState.dm_stage_changed.connect(_on_dm_stage_changed)
    GameState.phone_toggled.connect(_on_phone_toggled)
    GameState.slow_dance_changed.connect(_on_slow_dance_changed)
    GameState.dance_started.connect(_on_dance_started)
    GameState.player_knocked_back.connect(_on_knocked_back)
    GameState.easter_egg.connect(_on_easter_egg)
    GameState.endless_level_changed.connect(_on_endless_level_changed)
    GameState.door_opened_by_npc.connect(func(_point: Vector2) -> void: event('npc_opened_door'))


func _process(_delta: float) -> void:
    if not GameState.is_playing() or GameState.test_level:
        return
    var since: float = float(_run.get('phone_since', -1.0))
    if GameState.phone_on and since >= 0.0 and GameState.elapsed_time - since >= 30.0:
        unlock('screen_time')
    if GameState.endless_mode and GameState.elapsed_time >= 300.0:
        unlock('still_texting')


# ── 공개 API ──

func is_unlocked(id: String) -> bool:
    return _file.has_section_key('unlocked', id)


func unlocked_count() -> int:
    var count: int = 0
    for item: Dictionary in AchievementList.ITEMS:
        if is_unlocked(String(item['id'])):
            count += 1
    return count


func unlock(id: String) -> void:
    if is_unlocked(id) or AchievementList.find(id).is_empty():
        return
    _file.set_value('unlocked', id, int(Time.get_unix_time_from_system()))
    _file.save(SAVE_PATH)
    unlocked.emit(id)
    _queue.append(id)
    _show_next()
    _check_completion()


## 게임을 꺼도 남는 누적 횟수
func add_total(key: String, amount: int = 1) -> int:
    var value: int = int(_file.get_value('stats', key, 0)) + amount
    _file.set_value('stats', key, value)
    _file.save(SAVE_PATH)
    return value


func get_total(key: String) -> int:
    return int(_file.get_value('stats', key, 0))


## 다른 스크립트가 알리는 일. data는 일마다 다르다.
func event(name: String, data: Dictionary = {}) -> void:
    if GameState.test_level and not MENU_EVENTS.has(name):
        return
    match name:
        'prop_used':
            _on_prop_used(String(data.get('id', '')), int(data.get('gathered', 0)))
        'door_toggled':
            if _add_run('doors') >= 10:
                unlock('doorman')
            if bool(data.get('closed', false)) and int(data.get('other_count', 0)) >= 5:
                unlock('locked_in')
        'npc_opened_door':
            unlock('uninvited')
        'reaction':
            _on_reaction(int(data.get('npc', 0)), bool(data.get('positive', true)))
        'talked':
            unlock('small_talk')
            if add_total('talks') >= 10:
                unlock('peacekeeper')
        'blocked':
            var blocked: Dictionary = _run_dict('blocked')
            blocked[int(data.get('npc', 0))] = true
            if blocked.size() >= 3:
                unlock('bouncer')
        'camping':
            unlock('camper')
        'gf_received':
            if add_total('gf_received') >= 50:
                unlock('she_keeps_texting')
        'gf_dismissed':
            unlock('left_her_on_seen')
            if _add_run('gf_dismissed') >= 10:
                unlock('do_not_disturb')
        'menu_power':
            unlock('meet_the_team')
        'menu_99':
            unlock('ninety_nine_plus')
        'how_to':
            unlock('read_the_manual')
        'volume':
            unlock('volume_check')
        'rage_quit':
            unlock('rage_quit')
        'retry':
            if add_total('retries') >= 10:
                unlock('try_again')


# ── 판정 ──

func _on_game_started() -> void:
    _run = {'phone_since': -1.0, 'max_dm': 0}


func _on_game_ended(reason: int) -> void:
    if GameState.test_level:
        return
    add_total('ending_%d' % reason)
    match reason:
        GameState.EndReason.SURVIVED:
            _on_cleared()
        GameState.EndReason.CAUGHT:
            unlock('busted')
            if get_total('ending_%d' % reason) >= 10:
                unlock('serial_offender')
        GameState.EndReason.TOO_MANY_DMS:
            unlock('left_on_read')
            if get_total('ending_%d' % reason) >= 10:
                unlock('ghosted_again')
        GameState.EndReason.HIDDEN:
            unlock('all_eyes_on_you')
    var seen_all: bool = true
    for ending: int in [GameState.EndReason.CAUGHT, GameState.EndReason.TOO_MANY_DMS, GameState.EndReason.SURVIVED, GameState.EndReason.HIDDEN]:
        seen_all = seen_all and get_total('ending_%d' % ending) > 0
    if seen_all:
        unlock('seen_it_all')
    if GameState.new_record:
        unlock('endless_best' if GameState.endless_mode else 'new_best')
    var all_records: bool = true
    for index: int in GameConfig.LEVELS.size():
        all_records = all_records and ScoreRecords.get_best(ScoreRecords.level_key(index)) > 0
    if all_records:
        unlock('record_collector')


func _on_cleared() -> void:
    if GameState.endless_mode:
        return
    var level: int = GameState.level_index + 1
    _file.set_value('cleared', str(level), true)
    if CLEAR_ACHIEVEMENTS.has(level):
        unlock(String(CLEAR_ACHIEVEMENTS[level]))
    for group: Array in LEVEL_GROUPS:
        var all_clear: bool = true
        for need: int in group[0]:
            all_clear = all_clear and _file.has_section_key('cleared', str(need))
        if all_clear:
            unlock(String(group[1]))
    if GameState.dm_stage >= 9:
        unlock('down_to_the_wire')
    if int(_run.get('wrong', 0)) == 0:
        unlock('steady_hands')
    if int(_run.get('max_dm', 0)) <= 3:
        unlock('inbox_zero')
    if int(_run.get('phone_opens', 0)) == 0:
        unlock('unbothered')
    if int(_run.get('replies', 0)) == 0:
        unlock('bare_minimum')
    _file.save(SAVE_PATH)


func _on_score_changed(value: int) -> void:
    if GameState.test_level:
        return
    if value >= 5000:
        unlock('high_scorer')
    if value >= 12000:
        unlock('score_hunter')


## PhoneView가 답장 직전에 GameState.last_reply를 채운다.
func _on_reply_resolved(success: bool) -> void:
    if not success or GameState.test_level:
        return
    var info: Dictionary = GameState.last_reply
    var stage: int = int(info.get('stage', 0))
    var words: int = int(info.get('words', 1))
    unlock('first_reply')
    var total: int = add_total('replies')
    if total >= 100:
        unlock('serial_texter')
    if total >= 500:
        unlock('chatterbox')
    if _add_run('replies') >= 10:
        unlock('speed_reader')
    if stage == 1:
        unlock('quick_reply')
    if stage >= 9:
        unlock('last_second')
    if words >= 2:
        unlock('full_sentence')
    if words >= 4:
        unlock('novelist')
    if bool(info.get('long', false)) and add_total('long_replies') >= 10:
        unlock('big_words')
    if float(info.get('sec', 99.0)) <= 2.0:
        unlock('fast_thumbs')
    if int(info.get('wrong', 1)) == 0 and not GameState.endless_mode and GameState.level_index == GameConfig.LEVELS.size() - 1:
        unlock('crowded_keyboard')
    if GameState.tremor_closeness >= 0.8:
        unlock('shaky_hands')
    if GameState.slow_dance_active:
        unlock('slow_dancer')


func _on_wrong_letter() -> void:
    if _add_run('wrong') >= 10 and not GameState.test_level:
        unlock('butterfingers')


func _on_dm_stage_changed(stage: int) -> void:
    _run['max_dm'] = maxi(int(_run.get('max_dm', 0)), stage)


func _on_phone_toggled(is_on: bool) -> void:
    if not is_on:
        _run['phone_since'] = -1.0
        return
    _run['phone_since'] = GameState.elapsed_time
    if GameState.slow_dance_active:
        _run['phone_in_slow_dance'] = true
    if _add_run('phone_opens') >= 30 and not GameState.test_level:
        unlock('phone_addict')


func _on_slow_dance_changed(active: bool) -> void:
    if active:
        _run['phone_in_slow_dance'] = GameState.phone_on
    elif GameState.is_playing() and not GameState.test_level and not bool(_run.get('phone_in_slow_dance', true)):
        unlock('wallflower')


func _on_dance_started(_duration: float) -> void:
    if GameState.test_level:
        return
    unlock('first_dance')
    if _add_run('dances') >= 3:
        unlock('dance_machine')
    if add_total('dances') >= 20:
        unlock('party_animal')


func _on_knocked_back(_from: Vector2) -> void:
    if GameState.test_level:
        return
    unlock('in_the_way')
    if _add_run('knockbacks') >= 5:
        unlock('shake_it_off')


func _on_easter_egg(id: String) -> void:
    if GameState.test_level:
        return
    unlock('take_the_l' if id == 'take_l' else 'baji')
    var eggs: Dictionary = _run_dict('eggs')
    eggs[id] = true
    if eggs.has('take_l') and eggs.has('baji'):
        unlock('remix')


func _on_endless_level_changed(level: int) -> void:
    for need: int in ENDLESS_LEVELS:
        if level >= need:
            unlock(String(ENDLESS_LEVELS[need]))


func _on_prop_used(id: String, gathered: int) -> void:
    if PROP_FIRST_USE.has(id):
        unlock(String(PROP_FIRST_USE[id]))
    var used: Dictionary = _run_dict('props')
    used[id] = true
    if used.has('speaker') and used.has('light') and used.has('playlist'):
        unlock('party_planner')
    if id == 'playlist' and gathered >= 8:
        unlock('crowd_control')
    if add_total('props') >= 100:
        unlock('prop_master')
    if GameState.endless_mode and _add_run('endless_props') >= 10:
        unlock('one_time_deal')


func _on_reaction(npc_id: int, positive: bool) -> void:
    if add_total('reactions') >= 50:
        unlock('social_butterfly')
    if add_total('reactions_positive' if positive else 'reactions_negative') >= 100:
        unlock('good_vibes' if positive else 'hater')
    var seen: Dictionary = _run_dict('reacted')
    var kinds: Dictionary = seen.get(npc_id, {})
    kinds[positive] = true
    seen[npc_id] = kinds
    if kinds.size() >= 2:
        unlock('mixed_signals')
    if seen.size() >= 10:
        unlock('first_impression')


func _check_completion() -> void:
    var normal_done: bool = true
    var all_done: bool = true
    for item: Dictionary in AchievementList.ITEMS:
        var id: String = item['id']
        if id == 'completionist' or id == 'true_completionist':
            continue
        var done: bool = is_unlocked(id)
        all_done = all_done and done
        if not AchievementList.is_hidden(item):
            normal_done = normal_done and done
    if normal_done:
        unlock('completionist')
    if all_done and is_unlocked('completionist'):
        unlock('true_completionist')


func _add_run(key: String, amount: int = 1) -> int:
    var value: int = int(_run.get(key, 0)) + amount
    _run[key] = value
    return value


func _run_dict(key: String) -> Dictionary:
    if not _run.has(key):
        _run[key] = {}
    return _run[key]


# ── 알림 ──

func _show_next() -> void:
    if _showing or _queue.is_empty():
        return
    _showing = true
    var item: Dictionary = AchievementList.find(_queue.pop_front())
    _toast_name.text = String(item['name'])
    _toast_desc.text = String(item['desc'])
    _toast.visible = true
    _toast.position.x = TOAST_HIDDEN_X
    if _sound.stream != null:
        _sound.play()
    var tween: Tween = create_tween()
    tween.tween_property(_toast, 'position:x', 24.0, TOAST_SLIDE_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_interval(TOAST_SHOW_SEC)
    tween.tween_property(_toast, 'position:x', TOAST_HIDDEN_X, TOAST_SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    tween.tween_callback(func() -> void:
        _toast.visible = false
        _showing = false
        _show_next()
    )
