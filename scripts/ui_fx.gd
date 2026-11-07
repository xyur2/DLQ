class_name UiFx
extends RefCounted
## 메뉴 화면들이 함께 쓰는 작은 움직임.

const HOVER_SCALE: float = 1.035
const HOVER_SEC: float = 0.1
const HOVER_TINT: Color = Color(1.0, 0.82, 0.2)
const PRESS_TINT: Color = Color(1.0, 0.55, 0.15)
const FADE_IN_SEC: float = 0.35


## 글자가 있는 버튼에 마우스를 올리면 살짝 커지고 노란색이 되며, 누르면 주황색이 된다.
static func add_hover(root: Node) -> void:
    if root is Button and (root as Button).text != '':
        var button: Button = root
        button.mouse_entered.connect(_set_button_look.bind(button, HOVER_SCALE, HOVER_TINT))
        button.mouse_exited.connect(_set_button_look.bind(button, 1.0, Color.WHITE))
        button.button_down.connect(_set_button_look.bind(button, HOVER_SCALE, PRESS_TINT))
        button.button_up.connect(_set_button_look.bind(button, HOVER_SCALE, HOVER_TINT))
    for child: Node in root.get_children():
        add_hover(child)


static func _set_button_look(button: Button, goal: float, tint: Color) -> void:
    button.pivot_offset = button.size * 0.5
    var tween: Tween = button.create_tween().set_parallel()
    tween.tween_property(button, 'scale', Vector2.ONE * goal, HOVER_SEC)
    tween.tween_property(button, 'self_modulate', tint, HOVER_SEC)


## 장면이 시작될 때 검은 화면에서 밝아진다.
static func fade_in(cover: ColorRect) -> void:
    cover.visible = true
    cover.modulate.a = 1.0
    var tween: Tween = cover.create_tween()
    tween.tween_property(cover, 'modulate:a', 0.0, FADE_IN_SEC)
    tween.tween_callback(cover.hide)
