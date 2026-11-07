class_name MenuScreen
extends Control
## 게임 시작 화면과 레벨 선택, How to Play, 설정 화면.
## 홈에서는 휴대폰 알림이 쌓이고, 전원 버튼을 누르면 개발진 정보가 나온다.
## 다른 화면으로 갈 때는 홈의 휴대폰이 가운데로 와서 커진 다음 내용이 나타난다.
## 배치는 scenes/menu/menu.tscn에서 편집한다.

enum View { HOME, LEVELS, HOW_TO, SETTINGS }

const PHONE_HOME_POSITION: Vector2 = Vector2(93.0, 852.0)
const PHONE_HOME_ROTATION: float = 0.5236      # 홈에서는 휴대폰이 30도 기울어 있다
const PHONE_ZOOM_POSITION: Vector2 = Vector2(780.0, 604.0)
const PHONE_SCALE: float = 3.4
const ALERT_POP_SCALE: float = 1.3
const ALERT_POP_SEC: float = 0.18
const BURST_BASE_SCALE: float = 0.7
const BURST_STAGE_SCALE: float = 0.03
const FADE_SEC: float = 0.2
const MESSAGE_POP_SCALE: float = 0.8
const MESSAGE_POP_SEC: float = 0.28
const NUDGE_PX: float = 5.0
const MESSAGE_TEXT_MARGIN: Vector2 = Vector2(30.0, 16.0)
const MESSAGE_TEXT_HEIGHT: float = 120.0
const NUDGE_SEC: float = 0.04
const VIEW_TITLES: Dictionary = {View.HOW_TO: 'How to Play', View.SETTINGS: 'Settings'}

## 레벨 선택 화면의 메시지 그림
@export var message_texture: Texture2D

var _view: View = View.HOME
var _busy: bool = false
var _level: int = 0
var _stage: int = 0
var _idle_time: float = 0.0
var _credits_left: float = 0.0
var _shake_time: float = 0.0
var _icon_base: Vector2 = Vector2.ZERO
var _alert_base: Vector2 = Vector2.ZERO
var _message_wait: float = 0.0
var _content_tween: Tween = null

@onready var _background: Control = $Background
@onready var _phone: Control = $Phone
@onready var _home: Control = $Home
@onready var _title: Label = $Zoomed/Title
@onready var _zoomed: Control = $Zoomed
@onready var _levels: Control = $Zoomed/Levels
@onready var _how_to: Control = $Zoomed/HowTo
@onready var _settings: Control = $Zoomed/Settings
@onready var _messages: VBoxContainer = $Zoomed/Levels/Messages
@onready var _level_name: Label = $Zoomed/Levels/LevelName
@onready var _hint: Label = $Zoomed/Levels/Hint
@onready var _start: Button = $Zoomed/Levels/Start
@onready var _previous: Button = $Zoomed/Previous
@onready var _next: Button = $Zoomed/Next
@onready var _back: Button = $Zoomed/Back
@onready var _screen_content: Control = $Phone/ScreenContent
@onready var _icon: Control = $Phone/ScreenContent/NotifyIcon
@onready var _alert: Control = $Home/Alert
@onready var _burst: Control = $Home/Burst
@onready var _power: Button = $Phone/PowerHitbox
@onready var _credits: Label = $Phone/ScreenContent/Credits
@onready var _music: AudioStreamPlayer = $Music


func _ready() -> void:
    _icon_base = _icon.position
    _alert_base = _alert.position
    UiFx.fade_in($FadeCover)
    UiFx.add_hover(self)
    $Home/Buttons/MainMode.pressed.connect(_open.bind(View.LEVELS))
    $Home/Buttons/Endless.pressed.connect(_on_endless_pressed)
    $Home/Buttons/HowTo.pressed.connect(_open.bind(View.HOW_TO))
    $Home/Buttons/Settings.pressed.connect(_open.bind(View.SETTINGS))
    $Home/Buttons/Quit.pressed.connect(_on_quit_pressed)
    _power.pressed.connect(_on_power_pressed)
    _previous.pressed.connect(_change_level.bind(-1))
    _next.pressed.connect(_change_level.bind(1))
    _back.pressed.connect(_close)
    _start.pressed.connect(_on_start_pressed)
    _zoomed.visible = false
    _credits.visible = false
    _update_badge()
    _play_music()
    _show_screen_content()
    if SceneFlow.menu_start_view == 'levels':
        SceneFlow.menu_start_view = ''
        _level = GameState.level_index
        _snap_to_zoomed()
        _show_view(View.LEVELS)
        _zoomed.modulate.a = 1.0


func _process(delta: float) -> void:
    _hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.004)
    if _view == View.LEVELS:
        _update_messages(delta)
    if _view != View.HOME:
        return
    _shake_time += delta
    if _credits_left > 0.0:
        _credits_left -= delta
        if _credits_left <= 0.0:
            _credits.visible = false
            _icon.visible = true
        return
    _idle_time += delta
    if _idle_time >= GameConfig.MENU_NOTIFY_INTERVAL:
        _idle_time = 0.0
        _stage = mini(_stage + 1, GameConfig.MAX_DM_STAGE)
        _update_badge()
        _pop_alert()
    var shake: float = float(GameConfig.DM_ICON_SHAKE_PX[_stage])
    var wobble := Vector2(sin(_shake_time * 70.0), cos(_shake_time * 83.0)) * shake
    _icon.position = _icon_base + wobble
    _alert.position = _alert_base + wobble


## 조작하는 동안에는 알림이 쌓이지 않는다.
func _input(event: InputEvent) -> void:
    if event is InputEventMouse or event is InputEventKey:
        _idle_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed('pause') and _view != View.HOME:
        _close()


## 알림이 쌓이면 느낌표와 빛살이 나타나고, 빛살은 단계만큼 커진다.
func _update_badge() -> void:
    _alert.visible = _stage > 0
    _burst.visible = _stage > 0
    _burst.scale = Vector2.ONE * (BURST_BASE_SCALE + BURST_STAGE_SCALE * float(_stage))


func _pop_alert() -> void:
    _alert.scale = Vector2.ONE * ALERT_POP_SCALE
    var tween: Tween = _alert.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(_alert, 'scale', Vector2.ONE, ALERT_POP_SEC)


func _on_power_pressed() -> void:
    if _busy:
        return
    _credits_left = GameConfig.MENU_CREDITS_SEC
    _credits.visible = true
    _icon.visible = false


func _open(view: View) -> void:
    if _busy:
        return
    _busy = true
    _level = clampi(GameState.level_index, 0, GameConfig.LEVELS.size() - 1)
    await _move_phone(true)
    _show_view(view)
    var tween: Tween = create_tween()
    tween.tween_property(_zoomed, 'modulate:a', 1.0, FADE_SEC)
    await tween.finished
    _busy = false


func _close() -> void:
    if _busy or _view == View.HOME:
        return
    _busy = true
    var tween: Tween = create_tween()
    tween.tween_property(_zoomed, 'modulate:a', 0.0, FADE_SEC)
    await tween.finished
    _zoomed.visible = false
    _view = View.HOME
    _screen_content.modulate.a = 0.0
    await _move_phone(false)
    _show_screen_content()
    _busy = false


## 휴대폰이 자리 잡은 뒤 아이콘을 천천히 보여 준다.
func _show_screen_content() -> void:
    _stop_content_fade()
    _screen_content.visible = true
    _screen_content.modulate.a = 0.0
    _content_tween = create_tween()
    _content_tween.tween_interval(GameConfig.MENU_ICON_DELAY)
    _content_tween.tween_property(_screen_content, 'modulate:a', 1.0, GameConfig.MENU_ICON_FADE_SEC)


func _stop_content_fade() -> void:
    if _content_tween != null:
        _content_tween.kill()
        _content_tween = null


func _on_quit_pressed() -> void:
    get_tree().quit()


func _on_endless_pressed() -> void:
    if _busy:
        return
    _busy = true
    await _move_phone(true)
    SceneFlow.start_endless()


func _on_start_pressed() -> void:
    if not _busy:
        _busy = true
        SceneFlow.start_level(_level)


## 휴대폰을 가운데로 불러와 확대하거나 제자리로 돌려보낸다. 홈 화면 요소는 함께 사라지고 나타난다.
func _move_phone(zoom_in: bool) -> void:
    _power.visible = not zoom_in
    if zoom_in:
        _stop_content_fade()
        _home.mouse_filter = Control.MOUSE_FILTER_IGNORE
    else:
        _home.visible = true
    var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    var seconds: float = GameConfig.MENU_PHONE_ZOOM_SEC
    tween.tween_property(_phone, 'position', PHONE_ZOOM_POSITION if zoom_in else PHONE_HOME_POSITION, seconds)
    tween.tween_property(_phone, 'rotation', 0.0 if zoom_in else PHONE_HOME_ROTATION, seconds)
    if zoom_in:
        tween.tween_property(_screen_content, 'modulate:a', 0.0, seconds * 0.5)
    tween.tween_property(_home, 'modulate:a', 0.0 if zoom_in else 1.0, seconds * (0.5 if zoom_in else 1.0))
    tween.tween_property(_background, 'modulate', Color.WHITE * (0.6 if zoom_in else 1.0) + Color(0, 0, 0, 1) * (0.4 if zoom_in else 0.0), seconds)
    await tween.finished
    if zoom_in:
        _home.visible = false
        _screen_content.visible = false


func _snap_to_zoomed() -> void:
    _phone.position = PHONE_ZOOM_POSITION
    _phone.rotation = 0.0
    _stop_content_fade()
    _screen_content.visible = false
    _power.visible = false
    _home.visible = false
    _home.modulate.a = 0.0
    _background.modulate = Color(0.6, 0.6, 0.6, 1.0)


func _show_view(view: View) -> void:
    _view = view
    _zoomed.visible = true
    _zoomed.modulate.a = 0.0
    _levels.visible = view == View.LEVELS
    _how_to.visible = view == View.HOW_TO
    _settings.visible = view == View.SETTINGS
    if view == View.LEVELS:
        _refresh_level()
    else:
        _title.text = String(VIEW_TITLES[view])
        _previous.visible = false
        _next.visible = false


func _change_level(step: int) -> void:
    _level = clampi(_level + step, 0, GameConfig.LEVELS.size() - 1)
    _refresh_level()


## 레벨이 오를수록 휴대폰 화면의 메시지가 늘어난다.
func _refresh_level() -> void:
    _title.text = 'Level %d' % (_level + 1)
    _level_name.text = String(GameConfig.LEVELS[_level]['title']).get_slice(': ', 1)
    _previous.visible = _level > 0
    _next.visible = _level < GameConfig.LEVELS.size() - 1
    _clear_messages()
    _message_wait = GameConfig.MENU_MESSAGE_FIRST_DELAY


## 메시지가 실시간으로 하나씩 도착한다. 레벨 수만큼 도착하면 잠시 뒤 비우고 다시 시작한다.
func _update_messages(delta: float) -> void:
    _message_wait -= delta
    if _message_wait > 0.0:
        return
    if _messages.get_child_count() > _level:
        _clear_messages()
        _message_wait = GameConfig.MENU_MESSAGE_FIRST_DELAY
        return
    _add_message()
    var full: bool = _messages.get_child_count() > _level
    _message_wait = GameConfig.MENU_MESSAGE_HOLD if full else GameConfig.MENU_MESSAGE_INTERVAL


func _add_message() -> void:
    var message := TextureRect.new()
    message.texture = message_texture
    message.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    message.custom_minimum_size = GameConfig.MENU_MESSAGE_SIZE
    message.mouse_filter = Control.MOUSE_FILTER_IGNORE
    message.modulate.a = 0.0
    message.pivot_offset = Vector2(0.0, GameConfig.MENU_MESSAGE_SIZE.y)
    message.scale = Vector2.ONE * MESSAGE_POP_SCALE
    var text_label := Label.new()
    text_label.text = String(GameConfig.MENU_MESSAGES[_messages.get_child_count() % GameConfig.MENU_MESSAGES.size()])
    text_label.position = MESSAGE_TEXT_MARGIN
    text_label.size = Vector2(GameConfig.MENU_MESSAGE_SIZE.x - MESSAGE_TEXT_MARGIN.x * 2.0, MESSAGE_TEXT_HEIGHT)
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    text_label.add_theme_font_size_override('font_size', 30)
    message.add_child(text_label)
    _messages.add_child(message)
    var tween: Tween = message.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(message, 'scale', Vector2.ONE, MESSAGE_POP_SEC)
    tween.tween_property(message, 'modulate:a', 1.0, MESSAGE_POP_SEC * 0.6)
    if not _busy:
        _nudge_phone()


## 메시지가 오면 휴대폰이 살짝 진동한다.
func _nudge_phone() -> void:
    var tween: Tween = _phone.create_tween()
    for offset: float in [NUDGE_PX, -NUDGE_PX, NUDGE_PX * 0.5, 0.0]:
        tween.tween_property(_phone, 'position:x', PHONE_ZOOM_POSITION.x + offset, NUDGE_SEC)


func _clear_messages() -> void:
    for child: Node in _messages.get_children():
        _messages.remove_child(child)
        child.queue_free()


func _play_music() -> void:
    if ResourceLoader.exists(GameConfig.MENU_MUSIC_PATH):
        var stream: AudioStream = load(GameConfig.MENU_MUSIC_PATH)
        if stream is AudioStreamOggVorbis:
            (stream as AudioStreamOggVorbis).loop = true
        _music.stream = stream
        _music.play()
