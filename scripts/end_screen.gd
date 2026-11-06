class_name EndScreen
extends ColorRect

var _message: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    color = Color(0.0, 0.0, 0.0, 0.0)
    visible = false
    _message = Label.new()
    _message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _message.add_theme_font_size_override('font_size', 40)
    add_child(_message)
    GameState.game_ended.connect(_on_game_ended)

func _on_game_ended(reason: int) -> void:
    var line: String = ''
    if reason == GameState.EndReason.CAUGHT:
        line = '누군가 화면을 봤다.'
    elif reason == GameState.EndReason.TOO_MANY_DMS:
        line = '메시지가 너무 많이 쌓였다. 그녀가 찾아왔다.'
    elif reason == GameState.EndReason.SURVIVED:
        line = '끝까지 들키지 않았다.'
    _message.text = line + '\n\nR 키를 눌러 다시 시작'
    visible = true
    var tween: Tween = create_tween()
    tween.tween_property(self, 'color:a', 0.85, 1.0)

func _input(event: InputEvent) -> void:
    if visible and event.is_action_pressed('restart'):
        get_tree().paused = false
        get_tree().reload_current_scene()
