class_name PhoneView
extends Control
## 휴대폰 화면. 탑뷰를 완전히 가리고, 제시된 답장(단어 또는 문장)의 알파벳을 순서대로 눌러 답장한다.
## - 답장 문구는 GameConfig.REPLY_PHRASES에서 레벨의 reply_words(단어 수), long_chance(긴 단어 확률)에 맞게 고른다.
## - 오른쪽 위 빨간 배지에 쌓인 DM 수를 보여 준다. 답장하면 바로 0이 되어 사라진다.
## - 문장이면 단어 하나를 다 누를 때마다 글자 풍선을 지우고 다음 단어의 풍선을 새로 놓는다.
## - 틀린 알파벳을 누르면 점수가 깎이고 cfg['wrong_lock_time']초 동안 터치가 막힌다.
## - 제한 시간은 없다. 답장하지 않으면 DM이 cfg['dm_interval']초마다 계속 쌓인다. 휴대폰을 보는 동안은 쌓이지 않는다.
## - 끄기는 전원 버튼으로만 가능하다. 끄고 다시 켜면 문장의 몇 번째 단어인지, 누른 글자, 풍선 배치까지 그대로 이어서 한다.
## 숨은 입력: 글자 버튼이나 키보드로 GameConfig.LETTER_COMBOS의 글자를 연속으로 입력하면 음향 효과가 나온다.
## 손 떨림: 손 이미지와 실제 마우스 커서가 함께 흔들리고, 휴대폰은 다른 패턴으로 약하게 흔들린다.
## 같은 패턴이면 커서와 버튼의 거리가 변하지 않아 누르기 쉬워지므로 패턴을 나눈다.
## 전환: 켜고 끌 때 휴대폰과 손은 아래에서 올라오고 내려가며, 배경은 천천히 어두워지고 밝아진다.

const LETTER_SCENE: PackedScene = preload('res://scenes/phone/letter_button.tscn')
const LETTER_SCENE_SIZE: Vector2 = Vector2(84.0, 64.0)   # letter_button.tscn의 크기. 열 수 계산에 씀
const ALPHABET: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const LOCK_TINT: Color = Color(1.0, 0.82, 0.86)
const LOCK_SCREEN_COLOR: Color = Color(1.0, 0.8, 0.84)
const SCREEN_COLOR: Color = Color.WHITE
const BANNER_FONT_SIZE: int = 22
const BANNER_SENDER: String = 'GIRLFRIEND'
const LETTER_HISTORY_MAX: int = 8
const SENTENCE_BLANK: String = '•'   # 문장 진행 표시에서 아직 누르지 않은 글자
const BANNER_SLIDE_PX: float = 24.0
const BANNER_FADE_SEC: float = 0.22
const PHONE_NOISE_PHASE: float = 5000.0   # 휴대폰 흔들림을 손·커서와 다른 패턴으로

var _letters: Array[LetterButton] = []
var _puzzle_active: bool = false
var _words: PackedStringArray = []   # 답장 문구의 단어들. 단어 하나짜리 답장이면 원소 하나
var _word_index: int = 0             # 지금 누르는 단어의 번호
var _word: String = ''               # 지금 누르는 단어
var _next_index: int = 0             # 지금 단어에서 다음에 눌러야 할 글자 번호
var _progress_font_size: int = 0
var _word_font_size: int = 0
var _lock_left: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_time: float = 0.0
var _hands_base: Vector2 = Vector2.ZERO
var _mouse_offset: Vector2i = Vector2i.ZERO
var _typed: String = ''
var _girlfriend_wait: float = 0.0
var _girlfriend_show: float = 0.0
var _girlfriend_next: int = 0
var _banner_base_y: float = 0.0
var _slide: float = 0.0   # 0: 내려가 있음, 1: 올라와 있음

@onready var _backdrop: ColorRect = $Backdrop
@onready var _phone_root: Control = $PhoneRoot
@onready var _banner: SpeechBubble = $PhoneRoot/Screen/GirlfriendBanner
@onready var _banner_text: Label = $PhoneRoot/Screen/GirlfriendBanner/Text
@onready var _hands: TextureRect = $Hands
@onready var _screen_background: Panel = $PhoneRoot/ScreenBackground
@onready var _screen: Control = $PhoneRoot/Screen
@onready var _timer_bar: TextureProgressBar = $PhoneRoot/Screen/TimerBar
@onready var _status: Label = $PhoneRoot/Screen/Status
@onready var _word_label: Label = $PhoneRoot/Screen/Word
@onready var _progress: Label = $PhoneRoot/Screen/Progress
@onready var _lock_notice: Label = $PhoneRoot/Screen/LockNotice
@onready var _letter_area: Control = $PhoneRoot/Screen/LetterArea
@onready var _power_hitbox: Button = $PhoneRoot/PowerHitbox
@onready var _door_alert: TextureRect = $PhoneRoot/Screen/DoorAlert
var _reply_started_at: float = -1.0
var _reply_wrong: int = 0
var _door_alert_left: float = 0.0
@onready var _dm_badge: Panel = $PhoneRoot/Screen/DmBadge
@onready var _dm_badge_label: Label = $PhoneRoot/Screen/DmBadge/Count


func _ready() -> void:
    # 화면 스타일은 씬 리소스라 재시작해도 남는다. 잠금 색이 다음 판으로 넘어가지 않게 이 판 전용으로 복사하고 원래 색으로 되돌린다.
    _screen_background.add_theme_stylebox_override('panel', _screen_background.get_theme_stylebox('panel').duplicate())
    _set_locked(false)
    visible = false
    _noise.seed = randi()
    _noise.frequency = GameConfig.TREMOR_NOISE_FREQUENCY
    _hands_base = _hands.position
    _banner_base_y = _banner.position.y
    _progress_font_size = _progress.get_theme_font_size('font_size')
    _word_font_size = _word_label.get_theme_font_size('font_size')
    _girlfriend_next = randi() % GameConfig.GIRLFRIEND_MESSAGES.size()
    _banner.gui_input.connect(_on_banner_input)
    _power_hitbox.pressed.connect(_on_power_pressed)
    GameState.phone_toggled.connect(_on_phone_toggled)
    GameState.dm_stage_changed.connect(_on_stage_changed)
    GameState.dm_arrived.connect(_on_dm_arrived)
    GameState.door_opened_by_npc.connect(_on_door_opened)
    _door_alert.visible = false
    _door_alert.pivot_offset = _door_alert.size * 0.5
    _dm_badge.pivot_offset = _dm_badge.size * 0.5
    # 게임이 끝나면(발각 등) 일시 정지되기 전에 커서 흔들림을 멈추고 커서를 제자리로 돌린다.
    GameState.game_ended.connect(func(_reason: int) -> void: _release_mouse())
    _refresh_labels()


func _process(delta: float) -> void:
    _update_slide(delta)
    _update_tremor(delta)
    _update_girlfriend(delta)
    if _lock_left > 0.0 and GameState.is_playing():
        _lock_left -= delta
        _timer_bar.value = maxf(0.0, _lock_left) / float(GameState.cfg['wrong_lock_time'])
        if _lock_left <= 0.0:
            _set_locked(false)
    _update_status()
    if _door_alert_left > 0.0:
        _door_alert_left -= delta
        _door_alert.visible = _door_alert_left > 0.0 and GameState.phone_on


## 휴대폰을 켜고 끌 때의 전환. 끄는 중에도 게임은 진행되므로 입력은 막지 않는다.
func _update_slide(delta: float) -> void:
    var goal: float = 1.0 if GameState.phone_on else 0.0
    _slide = move_toward(_slide, goal, delta / GameConfig.PHONE_SLIDE_SEC)
    _backdrop.modulate.a = _slide
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if GameState.phone_on else Control.MOUSE_FILTER_IGNORE
    if _slide <= 0.0 and not GameState.phone_on:
        visible = false


## 전환에 따른 아래쪽 거리. 빠르게 움직이다가 자리에 가까울수록 느려진다.
func _slide_offset() -> Vector2:
    return Vector2.DOWN * GameConfig.PHONE_SLIDE_DISTANCE * pow(1.0 - _slide, 3.0)


## 손 이미지와 마우스 커서는 같은 양만큼, 휴대폰은 다른 패턴으로 흔든다.
func _update_tremor(delta: float) -> void:
    var center: Vector2 = (size - _phone_root.size) * 0.5
    if not GameState.phone_on or not GameState.is_playing():
        _hands.position = _hands_base + _slide_offset()
        _phone_root.position = center + _slide_offset()
        _release_mouse()
        return
    # 가까울수록 더 빠르게 떨린다.
    var speed: float = lerpf(GameConfig.TREMOR_NOISE_SPEED_MIN, GameConfig.TREMOR_NOISE_SPEED_MAX, GameState.get_tremor_ratio())
    _noise_time += delta * speed
    var amount: float = GameState.get_tremor_px() * GameConfig.TREMOR_NOISE_GAIN
    var offset := Vector2(
        _noise.get_noise_1d(_noise_time),
        _noise.get_noise_1d(_noise_time + 1000.0)
    ) * amount
    var phone_offset := Vector2(
        _noise.get_noise_1d(_noise_time + PHONE_NOISE_PHASE),
        _noise.get_noise_1d(_noise_time + PHONE_NOISE_PHASE + 1000.0)
    ) * amount * GameConfig.TREMOR_PHONE_RATIO
    _hands.position = _hands_base + _slide_offset() + offset
    _phone_root.position = center + _slide_offset() + phone_offset
    _shake_mouse(offset)


## 일시 정지되거나 장면을 떠날 때도 커서를 제자리로 돌린다.
func _notification(what: int) -> void:
    if what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
        _release_mouse()


## 커서 흔들림을 멈추고, 흔들어 둔 만큼 커서를 되돌린다.
func _release_mouse() -> void:
    if _mouse_offset != Vector2i.ZERO:
        _shake_mouse(Vector2.ZERO)
    _mouse_offset = Vector2i.ZERO


## 지난 프레임의 흔들림을 뺀 차이만큼만 커서를 옮겨, 플레이어의 마우스 조작은 그대로 살린다.
## 커서는 정수 픽셀로만 움직이므로 픽셀 단위로 추적해야 오차가 쌓여 밀려나지 않는다.
## 에디터 Game 탭 안에서 실행하면(내장 창) 창 좌표가 달라 커서가 엉뚱하게 움직일 수 있어 실제 커서는 흔들지 않는다(손은 흔들림).
func _shake_mouse(offset: Vector2) -> void:
    if not DisplayServer.window_is_focused() or Engine.is_embedded_in_editor():
        return
    var pixels := Vector2i((offset * get_viewport().get_screen_transform().get_scale()).round())
    if pixels == _mouse_offset:
        return
    var cursor: Vector2i = DisplayServer.mouse_get_position() - get_window().position
    Input.warp_mouse(Vector2(cursor + pixels - _mouse_offset))
    _mouse_offset = pixels


func _update_status() -> void:
    var has_dm: bool = GameState.dm_stage > 0
    _status.text = 'New messages: %s' % GameState.get_dm_badge_text() if has_dm else 'No new messages'
    _dm_badge.visible = has_dm
    _dm_badge_label.text = GameState.get_dm_badge_text()


## DM이 오면 배지가 튀어 오른다.
func _on_dm_arrived(_stage: int) -> void:
    _dm_badge.scale = Vector2.ONE * 1.3
    _dm_badge.create_tween().tween_property(_dm_badge, 'scale', Vector2.ONE, 0.18) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 휴대폰을 켠 동안 여자친구 메시지가 위에 떴다 사라진다. 누르면 바로 사라진다.
func _update_girlfriend(delta: float) -> void:
    if not GameState.phone_on or not GameState.is_playing():
        _banner.visible = false
        return
    if _banner.visible:
        _girlfriend_show -= delta
        if _girlfriend_show <= 0.0:
            _hide_banner()
        return
    _girlfriend_wait -= delta
    if _girlfriend_wait <= 0.0:
        _show_banner()


func _show_banner() -> void:
    Achievements.event('gf_received')
    _banner.show_text(String(GameConfig.GIRLFRIEND_MESSAGES[_girlfriend_next]), BANNER_FONT_SIZE, BANNER_SENDER)
    _girlfriend_next = (_girlfriend_next + 1) % GameConfig.GIRLFRIEND_MESSAGES.size()
    _girlfriend_show = GameConfig.GIRLFRIEND_SHOW_SEC
    _banner.visible = true
    _banner.modulate.a = 0.0
    _banner.position.y = _banner_base_y - BANNER_SLIDE_PX
    var tween: Tween = _banner.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(_banner, 'position:y', _banner_base_y, BANNER_FADE_SEC)
    tween.tween_property(_banner, 'modulate:a', 1.0, BANNER_FADE_SEC)


func _hide_banner() -> void:
    _banner.visible = false
    _girlfriend_wait = randf_range(GameConfig.GIRLFRIEND_INTERVAL_RANGE.x, GameConfig.GIRLFRIEND_INTERVAL_RANGE.y)


func _on_banner_input(event: InputEvent) -> void:
    var mb := event as InputEventMouseButton
    if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
        accept_event()
        _hide_banner()
        Achievements.event('gf_dismissed')


## 사람이 닫힌 문을 열고 들어오면, 휴대폰을 보는 중일 때 왼쪽 위에 느낌표가 튀어 오른다.
func _on_door_opened(_point: Vector2) -> void:
    if not GameState.phone_on:
        return
    _door_alert_left = GameConfig.DOOR_ALERT_SEC
    _door_alert.visible = true
    _door_alert.scale = Vector2.ONE * 1.4
    _door_alert.create_tween().tween_property(_door_alert, 'scale', Vector2.ONE, 0.2) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_power_pressed() -> void:
    GameState.close_phone()


func _on_phone_toggled(is_on: bool) -> void:
    _typed = ''
    if is_on:
        visible = true
        _girlfriend_wait = GameConfig.GIRLFRIEND_FIRST_DELAY
        _try_start_puzzle()


func _on_stage_changed(_stage: int) -> void:
    _try_start_puzzle()


func _try_start_puzzle() -> void:
    if _puzzle_active or not GameState.phone_on or GameState.dm_stage <= 0:
        return
    _puzzle_active = true
    _reply_started_at = -1.0
    _reply_wrong = 0
    _words = _pick_phrase().split(' ', false)
    _word_index = 0
    _start_word()


## 레벨의 reply_words(단어 수 범위)에서 단어 수를 고르고, long_chance 확률로 긴 단어가 든 문구를 고른다.
## 맞는 문구가 없으면 단어 수만 맞춘 문구, 그것도 없으면 아무 문구.
static func _pick_phrase() -> String:
    var words: Vector2i = GameState.cfg.get('reply_words', Vector2i(1, 1))
    var count: int = randi_range(words.x, words.y)
    var want_long: bool = randf() < float(GameState.cfg.get('long_chance', 0.0))
    var exact: Array = []
    var same_count: Array = []
    for phrase: String in GameConfig.REPLY_PHRASES:
        var parts: PackedStringArray = phrase.split(' ', false)
        if parts.size() != count:
            continue
        same_count.append(phrase)
        if _has_long_word(parts) == want_long:
            exact.append(phrase)
    if not exact.is_empty():
        return String(exact.pick_random())
    if not same_count.is_empty():
        return String(same_count.pick_random())
    return String(GameConfig.REPLY_PHRASES.pick_random())


static func _has_long_word(parts: PackedStringArray) -> bool:
    for part: String in parts:
        if part.length() >= GameConfig.LONG_WORD_LEN:
            return true
    return false


## 문장의 _word_index번째 단어를 시작한다. 글자 풍선을 지우고 새로 놓는다.
func _start_word() -> void:
    _word = _words[_word_index]
    _next_index = 0
    _clear_letters()
    _spawn_letters()
    _refresh_labels()


func _clear_letters() -> void:
    for button: LetterButton in _letters:
        button.queue_free()
    _letters.clear()


## 단어 글자 + 단어에 없는 알파벳(decoy)을 격자 칸에 무작위로 놓는다.
## decoy_count가 -1이면 가짜 글자로 칸(LETTER_GRID)을 꽉 채운다(모자라면 같은 가짜 글자가 또 나옴).
## 레벨이 오를수록 칸 사이 간격(letter_gap)이 좁고, 풍선이 쓰는 줄 수(letter_spread)가 줄어 빈칸 없이 모인다.
func _spawn_letters() -> void:
    var chars: Array[String] = []
    for c: String in _word:
        chars.append(c)
    var pool: Array[String] = []
    for c: String in ALPHABET:
        if not _word.contains(c):
            pool.append(c)
    pool.shuffle()
    var decoys: int = int(GameState.cfg.get('decoy_count', 0))
    if decoys < 0:
        decoys = GameConfig.LETTER_GRID.x * GameConfig.LETTER_GRID.y - chars.size()
    for i: int in maxi(decoys, 0):
        chars.append(pool[i % pool.size()])

    # 열 수: 레벨의 간격(letter_gap)을 지키며 화면 너비에 들어가는 만큼(3~LETTER_GRID.x열). 간격이 넓은 낮은 레벨은 3열.
    # 쓰는 줄 수 = 풍선 수 × letter_spread ÷ 열 수 (모두 들어가는 최소 줄 수 ~ LETTER_GRID.y)
    var gap: float = maxf(float(GameState.cfg['letter_gap']), GameConfig.LETTER_MIN_GAP)
    var button_width: float = LETTER_SCENE_SIZE.x
    var columns: int = clampi(floori((_letter_area.size.x + gap) / (button_width + gap)), 3, GameConfig.LETTER_GRID.x)
    var spread: float = float(GameState.cfg.get('letter_spread', 2.0))
    var needed_rows: int = ceili(float(chars.size()) / float(columns))
    if needed_rows > GameConfig.LETTER_GRID.y:
        columns = GameConfig.LETTER_GRID.x
        needed_rows = ceili(float(chars.size()) / float(columns))
    var rows: int = clampi(ceili(float(chars.size()) * spread / float(columns)), needed_rows, GameConfig.LETTER_GRID.y)
    var cells: Array[Vector2i] = []
    for row: int in rows:
        for col: int in columns:
            cells.append(Vector2i(col, row))
    cells.shuffle()

    for i: int in mini(chars.size(), cells.size()):
        var button: LetterButton = LETTER_SCENE.instantiate()
        _letter_area.add_child(button)
        button.setup(chars[i])
        button.picked.connect(_on_letter_picked)
        _letters.append(button)
    if _letters.is_empty():
        return

    # 칸 = 버튼 + 레벨의 글자 간격(letter_gap). 레벨이 오를수록 간격이 좁아져 버튼이 모인다.
    # 영역보다 커지면 영역에 맞춘다. 격자는 영역 가운데에 놓는다.
    var button_size: Vector2 = _letters[0].size
    var grid := Vector2(columns, rows)
    var cell := Vector2(
        minf(button_size.x + gap, (_letter_area.size.x - button_size.x) / maxf(grid.x - 1.0, 1.0)),
        minf(button_size.y + gap, (_letter_area.size.y - button_size.y) / maxf(grid.y - 1.0, 1.0))
    )
    var origin: Vector2 = (_letter_area.size - (cell * (grid - Vector2.ONE) + button_size)) * 0.5
    # 레벨의 letter_jitter만큼 불규칙하게 어긋나게 한다. 남는 간격에서 최소 간격을 뺀 만큼까지만 어긋나서 이웃 버튼과 붙지 않는다.
    var jitter_limit: float = float(GameState.cfg.get('letter_jitter', 0.0))
    var spare: Vector2 = (cell - button_size - Vector2.ONE * GameConfig.LETTER_MIN_GAP) * 0.5
    var jitter_max := Vector2(clampf(spare.x, 0.0, jitter_limit), clampf(spare.y, 0.0, jitter_limit))
    var max_pos: Vector2 = _letter_area.size - button_size
    for i: int in _letters.size():
        var jitter := Vector2(
            randf_range(-jitter_max.x, jitter_max.x),
            randf_range(-jitter_max.y, jitter_max.y)
        )
        var pos: Vector2 = origin + Vector2(cells[i]) * cell + jitter
        # 영역 밖으로 나가지 않게
        _letters[i].position = Vector2(clampf(pos.x, 0.0, max_pos.x), clampf(pos.y, 0.0, max_pos.y))


## 키보드 글자는 답장에 쓰지 않고 숨은 입력으로만 받는다. 한글 자판에서도 동작하도록 물리 키를 쓴다.
func _unhandled_key_input(event: InputEvent) -> void:
    var key := event as InputEventKey
    if key == null or not key.pressed or key.echo or not GameState.phone_on:
        return
    if key.physical_keycode >= KEY_A and key.physical_keycode <= KEY_Z:
        _record_letter(String.chr(key.physical_keycode))


func _record_letter(letter: String) -> void:
    _typed += letter
    for combo: String in GameConfig.LETTER_COMBOS.keys():
        if _typed.ends_with(combo):
            _typed = ''
            GameState.trigger_easter_egg(String(GameConfig.LETTER_COMBOS[combo]))
            return
    _typed = _typed.right(LETTER_HISTORY_MAX)


func _on_letter_picked(button: LetterButton) -> void:
    if not GameState.phone_on:
        return
    _record_letter(button.letter)
    if not _puzzle_active or _lock_left > 0.0 or not GameState.is_playing():
        return
    if button.letter == _word[_next_index]:
        if _reply_started_at < 0.0:
            _reply_started_at = GameState.elapsed_time
        button.mark_used()
        _next_index += 1
        _refresh_labels()
        if _next_index >= _word.length():
            if _word_index + 1 < _words.size():
                # 문장: 다음 단어로. 글자 풍선을 새로 놓는다.
                _word_index += 1
                _start_word()
            else:
                GameState.last_reply = {
                    'words': _words.size(),
                    'long': _has_long_word(_words),
                    'sec': GameState.elapsed_time - _reply_started_at,
                    'wrong': _reply_wrong,
                    'stage': GameState.dm_stage,
                }
                _finish_puzzle()
                GameState.report_reply_success()
    else:
        _reply_wrong += 1
        _lock_left = float(GameState.cfg['wrong_lock_time'])
        _set_locked(true)
        GameState.report_wrong_letter()


## 틀렸을 때 잠시 터치를 막는다.
func _set_locked(locked: bool) -> void:
    if not locked:
        _lock_left = 0.0
    for button: LetterButton in _letters:
        button.set_locked(locked)
    _lock_notice.visible = locked
    # TODO(확인필요): v2에 제한 시간이 없어, 타이머 바는 오답 터치 잠금의 남은 시간을 보여 준다.
    _timer_bar.visible = locked
    _timer_bar.value = 1.0 if locked else 0.0
    var tint: Color = LOCK_TINT if locked else Color.WHITE
    (_screen_background.get_theme_stylebox('panel') as StyleBoxFlat).bg_color = LOCK_SCREEN_COLOR if locked else SCREEN_COLOR
    _screen.modulate = tint


func _finish_puzzle() -> void:
    _puzzle_active = false
    _set_locked(false)
    _clear_letters()
    _words = PackedStringArray()
    _word_index = 0
    _word = ''
    _next_index = 0
    _refresh_labels()


## 위: 지금 누를 단어. 아래: 진행 상황.
## 단어 하나면 "L O _ _", 문장이면 끝낸 단어는 그대로, 지금 단어는 누른 데까지, 남은 글자는 •로 "SEE YOU VE•• ••••".
## (문장에서 _를 쓰면 붙어서 한 줄로 보여 글자 수를 셀 수 없다.)
func _refresh_labels() -> void:
    if not _puzzle_active:
        _word_label.text = ''
        _progress.text = ''
        return
    _word_label.text = _word
    if _words.size() <= 1:
        var letters: PackedStringArray = []
        for i: int in _word.length():
            letters.append(_word[i] if i < _next_index else '_')
        _progress.text = ' '.join(letters)
    else:
        var parts: PackedStringArray = []
        for w: int in _words.size():
            var word: String = _words[w]
            if w < _word_index:
                parts.append(word)
            elif w == _word_index:
                parts.append(word.left(_next_index) + SENTENCE_BLANK.repeat(word.length() - _next_index))
            else:
                parts.append(SENTENCE_BLANK.repeat(word.length()))
        _progress.text = ' '.join(parts)
    _fit_font(_word_label, _word_font_size)
    _fit_font(_progress, _progress_font_size)


## 글이 칸보다 넓으면 들어갈 때까지 글자 크기를 줄인다.
func _fit_font(label: Label, base_size: int) -> void:
    var font: Font = label.get_theme_font('font')
    var font_size: int = base_size
    while font_size > 18 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
        font_size -= 2
    label.add_theme_font_size_override('font_size', font_size)
