class_name GameHud
extends Control
## 탑뷰 HUD: 왼쪽 위 시각과 점수, 위쪽 상태 알림, 아래쪽 상호작용 안내, 오른쪽 아래 DM 아이콘(자식 씬 노드).
## 배치와 글자 크기는 scenes/ui/hud.tscn에서 편집한다.

@onready var _clock: Label = $Clock
@onready var _hint: Label = $Hint
@onready var _score: Label = $Score
@onready var _notice: Label = $Notice


func _ready() -> void:
    GameState.interact_hint_changed.connect(_on_hint_changed)


func _process(_delta: float) -> void:
    _clock.text = GameState.get_clock_text()
    _score.text = '점수 %d' % GameState.score
    if GameState.is_stunned():
        _notice.text = '밀려났다... %d초' % ceili(GameState.stun_left)
    elif GameState.slow_dance_active:
        _notice.text = '슬로우 댄스 타임'
    else:
        _notice.text = ''


func _on_hint_changed(text_value: String) -> void:
    _hint.text = text_value
