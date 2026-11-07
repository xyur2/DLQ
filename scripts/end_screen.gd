class_name EndScreen
extends ColorRect
## 클리어, 게임 오버, 히든 엔딩 화면. 스토리 컷이 만화처럼 하나씩 나온 뒤 도장이 찍히고 버튼이 나타난다.
## process_mode = ALWAYS (씬에서 설정)라서 일시정지 중에도 재생된다. 배치는 scenes/ui/end_screen.tscn에서 편집한다.
## 씬의 Pages/<이름>이 있으면 만화 한 장을 칸(Polygon2D)별로 잘라 순서대로 보여 준다(칸 수는 자유).
## 없으면 Panels의 4칸에 assets/story/<이름>_1~4.png를 넣고, 그것도 없으면 번호만 있는 빈 컷으로 표시한다.

const STORY_NAMES: Dictionary = {
    GameState.EndReason.CAUGHT: 'caught',
    GameState.EndReason.TOO_MANY_DMS: 'girlfriend',
    GameState.EndReason.SURVIVED: 'clear',
    GameState.EndReason.HIDDEN: 'hidden',
}
const LINES: Dictionary = {
    GameState.EndReason.CAUGHT: '누군가 화면을 봤다.',
    GameState.EndReason.TOO_MANY_DMS: '메시지가 너무 많이 쌓였다. 그녀가 찾아왔다.',
    GameState.EndReason.SURVIVED: '끝까지 들키지 않았다.',
    GameState.EndReason.HIDDEN: '모두가 나를 보고 있었다. (히든 엔딩: 둥글게 둥글게)',
}
const FADE_SEC: float = 0.4
const PANEL_FADE_SEC: float = 0.3
const PANEL_SLIDE_PX: float = 24.0
const STAMP_START_SCALE: float = 3.0
const STAMP_ANGLE_GAME_OVER: float = -4.0
const STAMP_ANGLE_CLEAR: float = -14.0
const STAMP_CLEAR_COLOR: Color = Color(0.3, 1.0, 0.75)

## 다 나왔는지. 버튼과 키 입력은 이때부터 받는다.
var finished: bool = false

var _panels: Array[Polygon2D] = []

@onready var _info: Label = $Info
@onready var _left: Button = $Buttons/LevelSelect
@onready var _right: Button = $Buttons/Right
@onready var _buttons: Control = $Buttons
@onready var _stamp: Control = $Stamp
@onready var _stamp_image: TextureRect = $Stamp/Image
@onready var _stamp_box: Panel = $Stamp/Box
@onready var _stamp_label: Label = $Stamp/Box/Label
@onready var _stamp_sound: AudioStreamPlayer = $StampSound


func _ready() -> void:
    visible = false
    color.a = 0.0
    _buttons.visible = false
    _stamp.visible = false
    UiFx.add_hover(_buttons)
    _left.pressed.connect(SceneFlow.go_level_select)
    GameState.game_ended.connect(_on_game_ended)


func _on_game_ended(reason: int) -> void:
    visible = true
    _setup_panels(String(STORY_NAMES[reason]))
    _setup_buttons(reason)
    _setup_stamp(reason)
    _info.text = '%s   %s · 점수 %d' % [LINES[reason], GameState.get_level_label(), GameState.score]
    _info.visible = false
    var tween: Tween = create_tween()
    tween.tween_property(self, 'color:a', 1.0, FADE_SEC)
    for panel: Polygon2D in _panels:
        tween.tween_callback(_show_panel.bind(panel))
        tween.tween_interval(GameConfig.END_PANEL_SEC)
    tween.tween_callback(_show_stamp)
    tween.tween_interval(GameConfig.END_STAMP_SEC + 0.3)
    tween.tween_callback(_finish)


func _setup_panels(story: String) -> void:
    var page: Node = get_node_or_null('Pages/' + story)
    if page == null:
        page = $Panels
    page.visible = true
    _panels.clear()
    for child: Node in page.get_children():
        var cut: Polygon2D = child as Polygon2D
        cut.visible = false
        _panels.append(cut)
    if page != $Panels:
        return
    for i: int in _panels.size():
        var panel: Polygon2D = _panels[i]
        panel.visible = false
        var path: String = 'res://assets/story/%s_%d.png' % [story, i + 1]
        var number: Label = panel.get_node('Number')
        if not ResourceLoader.exists(path):
            number.text = '컷 %d' % (i + 1)
            number.position = _bounds(panel.polygon).get_center() - number.size * 0.5
            continue
        number.visible = false
        var texture: Texture2D = load(path)
        var box: Rect2 = _bounds(panel.polygon)
        var uvs := PackedVector2Array()
        for point: Vector2 in panel.polygon:
            uvs.append((point - box.position) / box.size * texture.get_size())
        panel.texture = texture
        panel.uv = uvs
        panel.color = Color.WHITE


func _setup_buttons(reason: int) -> void:
    var cleared: bool = reason == GameState.EndReason.SURVIVED
    if cleared and GameState.has_next_level():
        _right.text = 'Next Level'
        _right.pressed.connect(SceneFlow.next_level)
    elif cleared:
        _right.text = '홈으로'
        _right.pressed.connect(SceneFlow.go_home)
    else:
        _right.text = 'Retry'
        _right.pressed.connect(SceneFlow.restart)


func _setup_stamp(reason: int) -> void:
    var cleared: bool = reason == GameState.EndReason.SURVIVED
    _stamp_label.text = 'CLEAR' if cleared else 'GAME OVER'
    _stamp.rotation_degrees = STAMP_ANGLE_CLEAR if cleared else STAMP_ANGLE_GAME_OVER
    if cleared:
        var style: StyleBoxFlat = _stamp_box.get_theme_stylebox('panel').duplicate()
        style.border_color = STAMP_CLEAR_COLOR
        style.shadow_color = Color(STAMP_CLEAR_COLOR, 0.45)
        _stamp_box.add_theme_stylebox_override('panel', style)
        _stamp_label.add_theme_color_override('font_color', STAMP_CLEAR_COLOR)
    var path: String = 'res://assets/stamp_clear.png' if cleared else 'res://assets/stamp_game_over.png'
    if ResourceLoader.exists(path):
        _stamp_image.texture = load(path)
        _stamp_box.visible = false
    if ResourceLoader.exists(GameConfig.STAMP_SOUND_PATH):
        _stamp_sound.stream = load(GameConfig.STAMP_SOUND_PATH)


func _show_panel(panel: Polygon2D) -> void:
    panel.visible = true
    panel.modulate.a = 0.0
    panel.position = Vector2(0.0, PANEL_SLIDE_PX)
    var tween: Tween = create_tween().set_parallel()
    tween.tween_property(panel, 'modulate:a', 1.0, PANEL_FADE_SEC)
    tween.tween_property(panel, 'position', Vector2.ZERO, PANEL_FADE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 도장: 크게 떠 있다가 빠르게 내려와 찍힌다.
func _show_stamp() -> void:
    _stamp.visible = true
    _stamp.modulate.a = 0.0
    _stamp.scale = Vector2.ONE * STAMP_START_SCALE
    var tween: Tween = create_tween().set_parallel()
    tween.tween_property(_stamp, 'scale', Vector2.ONE, GameConfig.END_STAMP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(_stamp, 'modulate:a', 1.0, GameConfig.END_STAMP_SEC * 0.5)
    tween.chain().tween_callback(_on_stamp_landed)


func _on_stamp_landed() -> void:
    if _stamp_sound.stream != null:
        _stamp_sound.play()
    var tween: Tween = create_tween()
    tween.tween_property(_stamp, 'scale', Vector2.ONE * 1.06, 0.05)
    tween.tween_property(_stamp, 'scale', Vector2.ONE, 0.08)


func _finish() -> void:
    finished = true
    _buttons.visible = true
    _info.visible = true


func _bounds(points: PackedVector2Array) -> Rect2:
    var box := Rect2(points[0], Vector2.ZERO)
    for point: Vector2 in points:
        box = box.expand(point)
    return box


func _input(event: InputEvent) -> void:
    if not finished:
        return
    if event.is_action_pressed('next_level') \
            and GameState.end_reason == GameState.EndReason.SURVIVED and GameState.has_next_level():
        SceneFlow.next_level()
    elif event.is_action_pressed('restart'):
        SceneFlow.restart()
