class_name EndScreen
extends ColorRect
## 종료 화면. process_mode = ALWAYS (씬에서 설정)라서 일시정지 중에도 페이드와 R 입력이 동작한다.
## 모양은 scenes/ui/end_screen.tscn에서 편집한다.

const FADE_ALPHA: float = 0.85
const FADE_SEC: float = 1.0

@onready var _message: Label = $Message


func _ready() -> void:
    visible = false
    color.a = 0.0
    GameState.game_ended.connect(_on_game_ended)


func _on_game_ended(reason: int) -> void:
    var line: String = ''
    if reason == GameState.EndReason.CAUGHT:
        line = '누군가 화면을 봤다.'
    elif reason == GameState.EndReason.TOO_MANY_DMS:
        line = '메시지가 너무 많이 쌓였다. 그녀가 찾아왔다.'
    elif reason == GameState.EndReason.SURVIVED:
        line = '끝까지 들키지 않았다.'
    _message.text = line + '\n\nR 키를 눌러 다시 시작'
    visible = true
    var tween: Tween = create_tween()
    tween.tween_property(self, 'color:a', FADE_ALPHA, FADE_SEC)


func _input(event: InputEvent) -> void:
    if visible and event.is_action_pressed('restart'):
        get_tree().paused = false
        get_tree().reload_current_scene()
