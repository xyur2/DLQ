class_name PhoneView
extends Control
## 휴대폰 화면. 탑뷰를 완전히 가리고, 제시된 단어의 알파벳을 순서대로 눌러 답장한다.
## - 틀린 알파벳을 누르면 cfg['wrong_lock_time']초 동안 터치가 막힌다.
## - 제한 시간은 없다. 답장하지 않으면 DM이 15초마다 계속 쌓일 뿐이다.
## - 끄기는 전원 버튼으로만 가능하다. 끄고 다시 켜면 같은 단어를 이어서 한다.
## 손 떨림: 휴대폰은 고정이고, 손 이미지와 실제 마우스 커서가 함께 흔들린다. 커서가 흔들려 누르기 어려운 것이 핵심이다.

const LETTER_SCENE: PackedScene = preload('res://scenes/phone/letter_button.tscn')
const ALPHABET: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const LOCK_TINT: Color = Color(1.0, 0.7, 0.7)

var _letters: Array[LetterButton] = []
var _puzzle_active: bool = false
var _word: String = ''
var _next_index: int = 0
var _lock_left: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_time: float = 0.0
var _hands_base: Vector2 = Vector2.ZERO
var _mouse_offset: Vector2i = Vector2i.ZERO

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
    _update_tremor(delta)
    if _lock_left > 0.0 and GameState.is_playing():
        _lock_left -= delta
        _timer_bar.value = maxf(0.0, _lock_left) / float(GameState.cfg['wrong_lock_time'])
        if _lock_left <= 0.0:
            _set_locked(false)
    _update_status()


## 손 이미지와 마우스 커서를 같은 양만큼 흔든다.
func _update_tremor(delta: float) -> void:
    if not visible:
        _hands.position = _hands_base
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
    _hands.position = _hands_base + offset
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
    visible = is_on
    if is_on:
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

    var cell_size := Vector2(
        _letter_area.size.x / float(GameConfig.LETTER_GRID.x),
        _letter_area.size.y / float(GameConfig.LETTER_GRID.y)
    )
    for i: int in mini(chars.size(), cells.size()):
        var button: LetterButton = LETTER_SCENE.instantiate()
        _letter_area.add_child(button)
        button.setup(chars[i])
        var jitter := Vector2(
            randf_range(-GameConfig.LETTER_JITTER, GameConfig.LETTER_JITTER),
            randf_range(-GameConfig.LETTER_JITTER, GameConfig.LETTER_JITTER)
        )
        button.position = (Vector2(cells[i]) + Vector2(0.5, 0.5)) * cell_size - button.size * 0.5 + jitter
        button.picked.connect(_on_letter_picked)
        _letters.append(button)


func _on_letter_picked(button: LetterButton) -> void:
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
