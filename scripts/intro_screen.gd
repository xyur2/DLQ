class_name IntroScreen
extends ColorRect
## 시작 화면. 첫 실행에만 나오고, R로 재시작할 때는 바로 사라진다.
## 문구와 모양은 scenes/ui/intro_screen.tscn에서 편집한다.


func _ready() -> void:
    if GameState.intro_seen:
        queue_free()


func _gui_input(event: InputEvent) -> void:
    var mb := event as InputEventMouseButton
    if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
        accept_event()
        GameState.begin_play()
        queue_free()
