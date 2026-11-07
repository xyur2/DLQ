class_name GameHud
extends Control
## 탑뷰 HUD: 왼쪽 위 디지털 시계(digital_clock.gd)와 점수, 위쪽 상태 알림, 아래쪽 상호작용 안내, 오른쪽 아래 DM 아이콘(자식 씬 노드).
## 배치와 글자 크기는 scenes/ui/hud.tscn에서 편집한다.

@onready var _hint: Label = $Hint
@onready var _score: Label = $Score
@onready var _notice: Label = $Notice


func _ready() -> void:
    _hint.visible = false
    GameState.interact_hint_changed.connect(_on_hint_changed)


func _process(_delta: float) -> void:
    _score.text = '%s - Score %d' % [GameState.get_level_label(), GameState.score]
    if GameState.is_stunned():
        _notice.text = 'Pushed away... %ds' % ceili(GameState.stun_left)
    elif GameState.slow_dance_active:
        _notice.text = 'Slow Dance Time'
    elif GameState.is_playing() and GameState.elapsed_time < GameConfig.LEVEL_TITLE_SEC:
        _notice.text = GameState.get_level_title()
    else:
        _notice.text = ''
    _notice.visible = _notice.text != ''


func _on_hint_changed(text_value: String) -> void:
    _hint.text = text_value
    _hint.visible = text_value != ''
