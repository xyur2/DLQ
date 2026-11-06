class_name IntroScreen
extends ColorRect

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    color = Color.BLACK
    var label := Label.new()
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override('font_size', 32)
    label.text = '홈커밍 파티. 여기 있는 사람들은 전부 여자친구를 안다.\n\n그런데 또 메시지가 왔다.\n\nWASD 이동 / E 상호작용 / Q 휴대폰 켜기\n끌 때는 전원 버튼을 눌러야 한다.\n\n클릭해서 시작'
    add_child(label)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        accept_event()
        GameState.begin_play()
        queue_free()
