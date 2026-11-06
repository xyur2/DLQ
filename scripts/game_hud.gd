class_name GameHud
extends Control

var _clock: Label
var _hint: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _clock = Label.new()
    _clock.position = Vector2(32.0, 24.0)
    _clock.add_theme_font_size_override('font_size', 32)
    add_child(_clock)
    _hint = Label.new()
    _hint.position = Vector2(760.0, 960.0)
    _hint.size = Vector2(400.0, 40.0)
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.add_theme_font_size_override('font_size', 26)
    add_child(_hint)
    add_child(DmIcon.new())
    GameState.interact_hint_changed.connect(func(text: String) -> void: _hint.text = text)

func _process(_delta: float) -> void:
    _clock.text = GameState.get_clock_text()
