class_name MessageBubble
extends Panel

signal clicked(bubble: MessageBubble)

var order: int = 0
var _box: StyleBoxFlat

func setup(order_value: int, message: String) -> void:
    order = order_value
    _box = StyleBoxFlat.new()
    _box.set_corner_radius_all(20)
    add_theme_stylebox_override('panel', _box)

    var number := Label.new()
    number.text = str(order_value)
    number.position = Vector2(14.0, 8.0)
    number.add_theme_font_size_override('font_size', 26)
    number.add_theme_color_override('font_color', Color.WHITE)
    add_child(number)

    var label := Label.new()
    label.text = message
    label.position = Vector2(50.0, 12.0)
    label.size = Vector2(GameConfig.BUBBLE_SIZE.x - 62.0, GameConfig.BUBBLE_SIZE.y - 24.0)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_color_override('font_color', Color.WHITE)
    add_child(label)

func set_active(active: bool) -> void:
    _box.bg_color = Color(0.2, 0.75, 0.4) if active else Color(0.55, 0.57, 0.6)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        accept_event()
        clicked.emit(self)
