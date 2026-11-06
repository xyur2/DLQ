class_name ScoreEffects
extends Control
## 점수가 바뀔 때마다 +N, -N이 떠오르는 효과. 휴대폰 화면 위에서도 보이도록 전용 레이어에 있다.
## 위치는 scenes/ui/ui.tscn에서 정한다.

const POSITIVE_COLOR: Color = Color(0.45, 1.0, 0.5)
const NEGATIVE_COLOR: Color = Color(1.0, 0.35, 0.35)
const FONT_SIZE: int = 40
const RISE_PX: float = 60.0
const DURATION: float = 0.9

## 탑뷰에서 효과가 나타나는 위치. 왼쪽 위 점수 옆.
@export var top_view_position: Vector2 = Vector2(180.0, 64.0)
## 휴대폰 화면에서 효과가 나타나는 위치. 휴대폰 오른쪽 위.
@export var phone_position: Vector2 = Vector2(1240.0, 120.0)

var _last_score: int = 0


func _ready() -> void:
    _last_score = GameState.score
    GameState.score_changed.connect(_on_score_changed)


func _on_score_changed(value: int) -> void:
    var points: int = value - _last_score
    _last_score = value
    if points != 0:
        _spawn(points)


func _spawn(points: int) -> void:
    var label := Label.new()
    label.text = '%+d' % points
    label.position = phone_position if GameState.phone_on else top_view_position
    label.add_theme_font_size_override('font_size', FONT_SIZE)
    label.add_theme_color_override('font_color', POSITIVE_COLOR if points > 0 else NEGATIVE_COLOR)
    label.add_theme_color_override('font_outline_color', Color.BLACK)
    label.add_theme_constant_override('outline_size', 6)
    add_child(label)
    var tween: Tween = label.create_tween()
    tween.set_parallel()
    tween.tween_property(label, 'position:y', label.position.y - RISE_PX, DURATION)
    tween.tween_property(label, 'modulate:a', 0.0, DURATION).set_ease(Tween.EASE_IN)
    tween.chain().tween_callback(label.queue_free)
