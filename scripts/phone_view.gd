class_name PhoneView
extends Control

var _root: Control
var _screen: Panel
var _timer_bar: ProgressBar
var _status: Label
var _noise: FastNoiseLite
var _noise_time: float = 0.0
var _bubbles: Array[MessageBubble] = []
var _set_active: bool = false
var _time_left: float = 0.0
var _next_order: int = 1

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible = false
    _noise = FastNoiseLite.new()
    _noise.seed = randi()
    _noise.frequency = 0.03
    _build()
    GameState.phone_toggled.connect(_on_phone_toggled)
    GameState.dm_stage_changed.connect(_on_stage_changed)

func _build() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.04, 0.04, 0.05)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.gui_input.connect(_on_miss_input)
    add_child(backdrop)

    _root = Control.new()
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.size = GameConfig.PHONE_SIZE
    _root.position = _base_position()
    add_child(_root)

    var body := Panel.new()
    body.size = GameConfig.PHONE_SIZE
    body.add_theme_stylebox_override('panel', _box(Color(0.1, 0.1, 0.11), 48))
    body.gui_input.connect(_on_miss_input)
    _root.add_child(body)

    var margin: float = GameConfig.PHONE_SCREEN_MARGIN
    _screen = Panel.new()
    _screen.position = Vector2(margin, margin)
    _screen.size = GameConfig.PHONE_SIZE - Vector2(margin, margin) * 2.0
    _screen.add_theme_stylebox_override('panel', _box(Color(0.96, 0.96, 0.97), 28))
    _screen.gui_input.connect(_on_miss_input)
    _root.add_child(_screen)

    var header := Label.new()
    header.text = 'J'
    header.position = Vector2(20.0, 16.0)
    header.add_theme_color_override('font_color', Color.BLACK)
    header.add_theme_font_size_override('font_size', 28)
    _screen.add_child(header)

    _status = Label.new()
    _status.position = Vector2(20.0, 54.0)
    _status.add_theme_color_override('font_color', Color(0.35, 0.35, 0.4))
    _screen.add_child(_status)

    _timer_bar = ProgressBar.new()
    _timer_bar.position = Vector2(20.0, 90.0)
    _timer_bar.size = Vector2(_screen.size.x - 40.0, 12.0)
    _timer_bar.show_percentage = false
    _timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _timer_bar.max_value = 1.0
    _timer_bar.step = 0.001
    _screen.add_child(_timer_bar)

    var power := Button.new()
    power.position = Vector2(GameConfig.PHONE_SIZE.x, 140.0)
    power.size = Vector2(28.0, 120.0)
    power.tooltip_text = '전원'
    power.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    power.focus_mode = Control.FOCUS_NONE
    power.pressed.connect(GameState.close_phone)
    _root.add_child(power)

    var hands := PhoneHands.new()
    hands.size = GameConfig.PHONE_SIZE
    _root.add_child(hands)

func _box(color: Color, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.set_corner_radius_all(radius)
    return box

func _base_position() -> Vector2:
    return (GameConfig.VIEW_SIZE - GameConfig.PHONE_SIZE) * 0.5

func _process(delta: float) -> void:
    _update_tremor(delta)
    _update_set(delta)
    _update_status()

func _update_tremor(delta: float) -> void:
    _noise_time += delta * GameConfig.TREMOR_NOISE_SPEED
    var amount: float = GameState.get_tremor_px()
    var offset := Vector2(
        _noise.get_noise_1d(_noise_time),
        _noise.get_noise_1d(_noise_time + 1000.0)
    ) * amount * 1.6
    _root.position = _base_position() + offset

func _update_set(delta: float) -> void:
    if not _set_active or not GameState.is_playing():
        return
    _time_left -= delta
    _timer_bar.value = maxf(0.0, _time_left) / float(GameState.cfg['reply_time'])
    if _time_left <= 0.0:
        _finish_set()
        GameState.report_reply_failed()
        _try_start_set()

func _update_status() -> void:
    if GameState.dm_stage > 0:
        _status.text = '새 메시지 %s개' % GameState.get_dm_badge_text()
    else:
        _status.text = '새 메시지 없음'

func _on_phone_toggled(is_on: bool) -> void:
    visible = is_on
    if is_on:
        _try_start_set()

func _on_stage_changed(_stage: int) -> void:
    _try_start_set()

func _try_start_set() -> void:
    if _set_active or not GameState.phone_on or GameState.dm_stage <= 0:
        return
    _set_active = true
    _next_order = 1
    _time_left = float(GameState.cfg['reply_time'])
    _timer_bar.value = 1.0
    var slots: Array[Vector2] = _make_slots()
    slots.shuffle()
    var messages: Array = GameConfig.REPLY_MESSAGES.duplicate()
    messages.shuffle()
    for i: int in int(GameState.cfg['bubble_count']):
        var bubble := MessageBubble.new()
        bubble.position = slots[i]
        bubble.size = GameConfig.BUBBLE_SIZE
        bubble.setup(i + 1, String(messages[i]))
        bubble.set_active(i == 0)
        bubble.clicked.connect(_on_bubble_clicked)
        _screen.add_child(bubble)
        _bubbles.append(bubble)

func _make_slots() -> Array[Vector2]:
    var result: Array[Vector2] = []
    for row: int in 5:
        for column: int in 2:
            result.append(Vector2(14.0 + 284.0 * column, 120.0 + 130.0 * row))
    return result

func _on_bubble_clicked(bubble: MessageBubble) -> void:
    if bubble.order != _next_order:
        _apply_miss()
        return
    _bubbles.erase(bubble)
    bubble.queue_free()
    _next_order += 1
    if _bubbles.is_empty():
        _finish_set()
        GameState.report_reply_success()
        return
    for other: MessageBubble in _bubbles:
        other.set_active(other.order == _next_order)

func _on_miss_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _apply_miss()

func _apply_miss() -> void:
    if not _set_active:
        return
    _time_left -= float(GameState.cfg['miss_penalty'])
    _screen.modulate = Color(1.0, 0.65, 0.65)
    var tween: Tween = create_tween()
    tween.tween_property(_screen, 'modulate', Color.WHITE, 0.2)

func _finish_set() -> void:
    _set_active = false
    for bubble: MessageBubble in _bubbles:
        bubble.queue_free()
    _bubbles.clear()
    _timer_bar.value = 0.0
