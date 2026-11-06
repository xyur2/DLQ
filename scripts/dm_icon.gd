class_name DmIcon
extends Control
## DM 아이콘. 클릭하면 휴대폰을 켠다. 8단계부터는 숫자가 같으므로 흔들림 폭으로 위험을 구분한다.
## 위치는 scenes/ui/hud.tscn에서 정한다.

var _base_position: Vector2 = Vector2.ZERO
var _time: float = 0.0

@onready var _badge: Label = $Badge


func _ready() -> void:
    _base_position = position
    pivot_offset = size * 0.5
    GameState.dm_stage_changed.connect(_on_stage_changed)
    GameState.dm_arrived.connect(_on_dm_arrived)
    _on_stage_changed(GameState.dm_stage)


func _process(delta: float) -> void:
    _time += delta
    var amount: float = float(GameConfig.DM_ICON_SHAKE_PX[GameState.dm_stage])
    position = _base_position + Vector2(sin(_time * 70.0), cos(_time * 83.0)) * amount


func _gui_input(event: InputEvent) -> void:
    var mb := event as InputEventMouseButton
    if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
        accept_event()
        GameState.open_phone()


func _on_stage_changed(_stage: int) -> void:
    _badge.text = GameState.get_dm_badge_text()
    _badge.visible = GameState.dm_stage > 0
    queue_redraw()


func _on_dm_arrived(_stage: int) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, 'scale', Vector2(1.15, 1.15), 0.1)
    tween.tween_property(self, 'scale', Vector2.ONE, 0.1)


func _draw() -> void:
    var body := Rect2(8.0, 22.0, 80.0, 56.0)
    draw_rect(body, Color(0.98, 0.68, 0.18))
    draw_polyline(PackedVector2Array([
        body.position,
        body.position + Vector2(40.0, 30.0),
        body.position + Vector2(80.0, 0.0),
    ]), Color(0.75, 0.45, 0.08), 3.0)
    if GameState.dm_stage > 0:
        draw_circle(Vector2(78.0, 2.0), 22.0, Color(0.85, 0.15, 0.15))
