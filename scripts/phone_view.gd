class_name PhoneView
extends Control
## 휴대폰 화면. 탑뷰를 완전히 가리고, 제시된 단어의 알파벳을 순서대로 눌러 답장한다.
## - 틀린 알파벳을 누르면 점수가 깎이고 cfg['wrong_lock_time']초 동안 터치가 막힌다.
## - 제한 시간은 없다. 답장하지 않으면 DM이 cfg['dm_interval']초마다 계속 쌓일 뿐이다.
## - 끄기는 전원 버튼으로만 가능하다. 끄고 다시 켜면 같은 단어를 이어서 한다.
## 숨은 입력: 글자 버튼이나 키보드로 GameConfig.LETTER_COMBOS의 글자를 연속으로 입력하면 음향 효과가 나온다.
## 손 떨림: 손 이미지와 실제 마우스 커서가 함께 흔들리고, 휴대폰은 다른 패턴으로 약하게 흔들린다.
## 같은 패턴이면 커서와 버튼의 거리가 변하지 않아 누르기 쉬워지므로 패턴을 나눈다.
## 전환: 켜고 끌 때 휴대폰과 손은 아래에서 올라오고 내려가며, 배경은 천천히 어두워지고 밝아진다.

const LETTER_SCENE: PackedScene = preload('res://scenes/phone/letter_button.tscn')
const ALPHABET: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const LOCK_TINT: Color = Color(1.0, 0.7, 0.7)
const LETTER_HISTORY_MAX: int = 8
const PHONE_NOISE_PHASE: float = 5000.0   # 휴대폰 흔들림을 손·커서와 다른 패턴으로

var _letters: Array[LetterButton] = []
var _puzzle_active: bool = false
var _word: String = ''
var _next_index: int = 0
var _lock_left: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_time: float = 0.0
var _hands_base: Vector2 = Vector2.ZERO
var _mouse_offset: Vector2i = Vector2i.ZERO
var _typed: String = ''
var _slide: float = 0.0   # 0: 내려가 있음, 1: 올라와 있음

@onready var _backdrop: ColorRect = $Backdrop
@onready var _phone_root: Control = $PhoneRoot
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


func _ready() -> void:
    visible = false
    _noise.seed = randi()
    _noise.frequency = GameConfig.TREMOR_NOISE_FREQUENCY
    _hands_base = _hands.position
    _power_hitbox.pressed.connect(_on_power_pressed)
    GameState.phone_toggled.connect(_on_phone_toggled)
    GameState.dm_stage_changed.connect(_on_stage_changed)
    _refresh_labels()


func _process(delta: float) -> void:
    _update_slide(delta)
    _update_tremor(delta)
    if _lock_left > 0.0 and GameState.is_playing():
        _lock_left -= delta
        _timer_bar.value = maxf(0.0, _lock_left) / float(GameState.cfg['wrong_lock_time'])
        if _lock_left <= 0.0:
            _set_locked(false)
    _update_status()


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
    if not GameState.phone_on:
        _hands.position = _hands_base + _slide_offset()
        _phone_root.position = center + _slide_offset()
        _shake_mouse(Vector2.ZERO)
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


## 지난 프레임의 흔들림을 뺀 차이만큼만 커서를 옮겨, 플레이어의 마우스 조작은 그대로 살린다.
## 커서는 정수 픽셀로만 움직이므로 픽셀 단위로 추적해야 오차가 쌓여 밀려나지 않는다.
func _shake_mouse(offset: Vector2) -> void:
    if not DisplayServer.window_is_focused():
        return
    var pixels := Vector2i((offset * get_viewport().get_screen_transform().get_scale()).round())
    if pixels == _mouse_offset:
        return
    var cursor: Vector2i = DisplayServer.mouse_get_position() - get_window().position
    Input.warp_mouse(Vector2(cursor + pixels - _mouse_offset))
    _mouse_offset = pixels


func _update_status() -> void:
    if GameState.dm_stage > 0:
        _status.text = '새 메시지 %s개' % GameState.get_dm_badge_text()
    else:
        _status.text = '새 메시지 없음'


func _on_power_pressed() -> void:
    GameState.close_phone()


func _on_phone_toggled(is_on: bool) -> void:
    _typed = ''
    if is_on:
        visible = true
        _try_start_puzzle()


func _on_stage_changed(_stage: int) -> void:
    _try_start_puzzle()


func _try_start_puzzle() -> void:
    if _puzzle_active or not GameState.phone_on or GameState.dm_stage <= 0:
        return
    _puzzle_active = true
    _word = String(GameConfig.REPLY_WORDS.pick_random())
    _next_index = 0
    _spawn_letters()
    _refresh_labels()


## 단어 글자 + 단어에 없는 알파벳(decoy)을 격자 칸에 무작위로 놓는다.
func _spawn_letters() -> void:
    var chars: Array[String] = []
    for c: String in _word:
        chars.append(c)
    var pool: Array[String] = []
    for c: String in ALPHABET:
        if not _word.contains(c):
            pool.append(c)
    pool.shuffle()
    for i: int in mini(int(GameState.cfg['decoy_count']), pool.size()):
        chars.append(pool[i])

    var cells: Array[Vector2i] = []
    for row: int in GameConfig.LETTER_GRID.y:
        for col: int in GameConfig.LETTER_GRID.x:
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
    var grid := Vector2(GameConfig.LETTER_GRID)
    var gap: float = maxf(float(GameState.cfg['letter_gap']), GameConfig.LETTER_MIN_GAP)
    var cell := Vector2(
        minf(button_size.x + gap, (_letter_area.size.x - button_size.x) / maxf(grid.x - 1.0, 1.0)),
        minf(button_size.y + gap, (_letter_area.size.y - button_size.y) / maxf(grid.y - 1.0, 1.0))
    )
    var origin: Vector2 = (_letter_area.size - (cell * (grid - Vector2.ONE) + button_size)) * 0.5
    # 남는 간격에서 최소 간격을 뺀 만큼만 어긋나게 해서, 이웃 버튼과 붙지 않게 한다.
    var spare: Vector2 = (cell - button_size - Vector2.ONE * GameConfig.LETTER_MIN_GAP) * 0.5
    var jitter_max := Vector2(
        clampf(spare.x, 0.0, GameConfig.LETTER_JITTER),
        clampf(spare.y, 0.0, GameConfig.LETTER_JITTER)
    )
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
        button.mark_used()
        _next_index += 1
        _refresh_labels()
        if _next_index >= _word.length():
            _finish_puzzle()
            GameState.report_reply_success()
    else:
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
    _screen_background.modulate = tint
    _screen.modulate = tint


func _finish_puzzle() -> void:
    _puzzle_active = false
    _set_locked(false)
    for button: LetterButton in _letters:
        button.queue_free()
    _letters.clear()
    _word = ''
    _next_index = 0
    _refresh_labels()


## 단어와 진행 상황 표시. 예: "L O _ _"
func _refresh_labels() -> void:
    if not _puzzle_active:
        _word_label.text = ''
        _progress.text = ''
        return
    _word_label.text = _word
    var parts: PackedStringArray = []
    for i: int in _word.length():
        parts.append(_word[i] if i < _next_index else '_')
    _progress.text = ' '.join(parts)
