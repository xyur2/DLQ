class_name PhoneView
extends Control
## 휴대폰 화면. 탑뷰를 완전히 가리고, 제시된 단어의 알파벳을 순서대로 눌러 답장한다.
## - 틀린 알파벳을 누르면 cfg['wrong_lock_time']초 동안 터치가 막힌다.
## - 제한 시간은 없다. 답장하지 않으면 DM이 15초마다 계속 쌓일 뿐이다.
## - 끄기는 전원 버튼으로만 가능하다. 끄고 다시 켜면 같은 단어를 이어서 한다.
## 손 떨림은 자식 노드 MouseTremor가 마우스 커서를 흔드는 방식으로 처리한다.

const LETTER_SCENE: PackedScene = preload('res://scenes/phone/letter_button.tscn')
const ALPHABET: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const LOCK_TINT: Color = Color(1.0, 0.7, 0.7)

var _letters: Array[LetterButton] = []
var _puzzle_active: bool = false
var _word: String = ''
var _next_index: int = 0
var _lock_left: float = 0.0

@onready var _screen: Panel = $PhoneRoot/Screen
@onready var _status: Label = $PhoneRoot/Screen/Status
@onready var _word_label: Label = $PhoneRoot/Screen/Word
@onready var _progress: Label = $PhoneRoot/Screen/Progress
@onready var _lock_notice: Label = $PhoneRoot/Screen/LockNotice
@onready var _letter_area: Control = $PhoneRoot/Screen/LetterArea
@onready var _power_button: Button = $PhoneRoot/PowerButton


func _ready() -> void:
    visible = false
    _power_button.pressed.connect(_on_power_pressed)
    GameState.phone_toggled.connect(_on_phone_toggled)
    GameState.dm_stage_changed.connect(_on_stage_changed)
    _refresh_labels()


func _process(delta: float) -> void:
    if _lock_left > 0.0 and GameState.is_playing():
        _lock_left -= delta
        if _lock_left <= 0.0:
            _set_locked(false)
    _update_status()


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
    _screen.modulate = LOCK_TINT if locked else Color.WHITE


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
