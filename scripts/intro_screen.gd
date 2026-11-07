class_name IntroScreen
extends Control
## 게임을 켜면 가장 먼저 나오는 시작 만화. 칸(Polygon2D)이 하나씩 나온 뒤 잠시 멈췄다가 메뉴로 넘어간다.
## 칸은 만화 한 장(assets/story/intro_page.webp)을 잘라 쓰고, 배치는 scenes/ui/intro_screen.tscn의 Page에서 편집한다.
## 클릭이나 키를 누르면 남은 칸을 한꺼번에 보여 주고, 다 나온 뒤 한 번 더 누르면 바로 메뉴로 간다.

const FADE_SEC: float = 0.4
const PANEL_FADE_SEC: float = 0.35
const PANEL_SLIDE_PX: float = 24.0
const HINT_SKIP: String = 'Click to skip'
const HINT_START: String = 'Click to start'

## 모든 칸이 나왔는지.
var finished: bool = false

var _panels: Array[Polygon2D] = []
var _tween: Tween
var _leaving: bool = false

@onready var _page: Node2D = $Page
@onready var _hint: Label = $Hint


func _ready() -> void:
    for child: Node in _page.get_children():
        var cut: Polygon2D = child as Polygon2D
        cut.visible = false
        _panels.append(cut)
    _hint.text = HINT_SKIP
    modulate.a = 0.0
    _tween = create_tween()
    _tween.tween_property(self, 'modulate:a', 1.0, FADE_SEC)
    for panel: Polygon2D in _panels:
        _tween.tween_callback(_show_panel.bind(panel))
        _tween.tween_interval(GameConfig.INTRO_PANEL_SEC)
    _tween.tween_callback(_finish)
    _tween.tween_interval(GameConfig.INTRO_HOLD_SEC)
    _tween.tween_callback(_leave)


func _input(event: InputEvent) -> void:
    var pressed: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo)
    if not pressed or _leaving:
        return
    get_viewport().set_input_as_handled()
    if finished:
        _leave()
        return
    # 건너뛰기: 남은 칸을 바로 보여 주고 잠시 뒤 메뉴로.
    _tween.kill()
    modulate.a = 1.0
    for panel: Polygon2D in _panels:
        panel.visible = true
        panel.modulate.a = 1.0
        panel.position = Vector2.ZERO
    _finish()
    _tween = create_tween()
    _tween.tween_interval(GameConfig.INTRO_HOLD_SEC)
    _tween.tween_callback(_leave)


func _show_panel(panel: Polygon2D) -> void:
    panel.visible = true
    panel.modulate.a = 0.0
    panel.position = Vector2(0.0, PANEL_SLIDE_PX)
    var tween: Tween = create_tween().set_parallel()
    tween.tween_property(panel, 'modulate:a', 1.0, PANEL_FADE_SEC)
    tween.tween_property(panel, 'position', Vector2.ZERO, PANEL_FADE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _finish() -> void:
    finished = true
    _hint.text = HINT_START


func _leave() -> void:
    if _leaving:
        return
    _leaving = true
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, 'modulate:a', 0.0, FADE_SEC)
    _tween.tween_callback(SceneFlow.go_home)
