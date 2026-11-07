class_name SpeechBubble
extends TextureRect
## 대화 말풍선. 글이 짧은 말풍선 안에 한 줄로 들어가면 짧은 그림을, 넘치면 긴 그림을 쓴다.
## 그림과 크기는 scenes/ui/speech_bubble.tscn에서 편집한다.

const SHORT_TEXT_LEFT: float = 0.3    # 짧은 말풍선에서 글이 시작하는 곳 (가로 비율, 왼쪽은 꼬리)
const LONG_TEXT_LEFT: float = 0.15
const TEXT_RIGHT: float = 0.9
const TEXT_TOP: float = 0.08
const TEXT_BOTTOM: float = 0.9

@export var short_texture: Texture2D
@export var long_texture: Texture2D
@export var short_size: Vector2 = Vector2(300.0, 82.0)
@export var long_size: Vector2 = Vector2(416.0, 82.0)

var is_long: bool = false

@onready var _text: Label = $Text
@onready var _sender: Label = $Sender


## sender가 있으면 글 위에 보낸 사람 이름을 작게 붙인다.
func show_text(message: String, font_size: int, sender: String = '') -> void:
    _text.text = message
    _text.add_theme_font_size_override('font_size', font_size)
    var font: Font = _text.get_theme_font('font')
    var width: float = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
    is_long = width > short_size.x * (TEXT_RIGHT - SHORT_TEXT_LEFT)
    texture = long_texture if is_long else short_texture
    custom_minimum_size = long_size if is_long else short_size
    size = custom_minimum_size
    var left: float = size.x * (LONG_TEXT_LEFT if is_long else SHORT_TEXT_LEFT)
    var top: float = size.y * TEXT_TOP
    var right: float = size.x * TEXT_RIGHT
    var bottom: float = size.y * TEXT_BOTTOM
    _sender.visible = sender != ''
    _sender.text = sender
    if _sender.visible:
        _sender.position = Vector2(left, top)
        _sender.size = Vector2(right - left, 0.0)
        top += _sender.get_minimum_size().y
    _text.position = Vector2(left, top)
    _text.size = Vector2(right - left, bottom - top)
