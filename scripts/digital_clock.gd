class_name DigitalClock
extends Control
## 왼쪽 위 디지털 시계. assets/digital_clock.png를 칸 단위로 잘라 "11:00" 형식으로 보여 주고, 콜론이 깜빡인다.
## 위치와 크기는 scenes/ui/hud.tscn에서 정한다.

const CELL_SIZE: Vector2 = Vector2(128.0, 200.0)
const CELL_TOP: float = 28.0              # 칸 위아래의 빈 공간을 뺀다
const DIGIT_CELLS: String = '1234567890'  # 이미지의 칸 순서
const COLON_ON_CELL: int = 10
const COLON_OFF_CELL: int = 11
const COLON_BLINK_SEC: float = 0.5

@export var sheet: Texture2D

var _cells: Array[AtlasTexture] = []
var _shown_text: String = ''
var _blink_time: float = 0.0

@onready var _digits: Array[TextureRect] = [$Hour1, $Hour2, $Minute1, $Minute2]
@onready var _colon: TextureRect = $Colon


func _ready() -> void:
    for i: int in COLON_OFF_CELL + 1:
        var cell := AtlasTexture.new()
        cell.atlas = sheet
        cell.region = Rect2(Vector2(CELL_SIZE.x * float(i), CELL_TOP), CELL_SIZE)
        _cells.append(cell)
    _colon.texture = _cells[COLON_ON_CELL]


func _process(delta: float) -> void:
    _blink_time = fmod(_blink_time + delta, COLON_BLINK_SEC * 2.0)
    _colon.texture = _cells[COLON_ON_CELL if _blink_time < COLON_BLINK_SEC else COLON_OFF_CELL]
    var text: String = GameState.get_clock_text()
    if text != _shown_text:
        _shown_text = text
        _show_digits(text.replace('h ', ''))


## digits: "1137"처럼 숫자 4개
func _show_digits(digits: String) -> void:
    for i: int in _digits.size():
        _digits[i].texture = _cells[DIGIT_CELLS.find(digits[i])]
