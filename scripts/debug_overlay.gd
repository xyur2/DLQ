class_name DebugOverlay
extends Label
## F1 디버그 오버레이 (오른쪽 위). F2 단계 +1, F3 단계 0.

var _hint: String = ''


func _ready() -> void:
    visible = GameState.debug_enabled
    GameState.debug_changed.connect(_on_debug_changed)
    GameState.interact_hint_changed.connect(_on_hint_changed)


func _on_debug_changed(enabled: bool) -> void:
    visible = enabled


## 상호작용 안내는 원래 B의 GameHud가 표시한다. 디버그 확인용으로 여기에도 보여준다.
func _on_hint_changed(text_value: String) -> void:
    _hint = text_value


func _process(_delta: float) -> void:
    if visible:
        text = 'Tension %.2f\nTremor %.1fpx\nNearest %.0fpx\nDM stage %d\nPhone %s\nElapsed %.1fs\nHint %s\nF2 stage+1 / F3 stage 0' % [
            GameState.tension, GameState.get_tremor_px(), GameState.nearest_npc_px,
            GameState.dm_stage, 'on' if GameState.phone_on else 'off', GameState.elapsed_time,
            _hint if _hint != '' else '-'
        ]
