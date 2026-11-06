class_name DmIcon
extends Control

const ICON_SIZE: Vector2 = Vector2(96.0, 96.0)
const BASE_POSITION: Vector2 = Vector2(1792.0, 952.0)

var _badge: Label
var _time: float = 0.0

func _ready() -> void:
    size = ICON_SIZE
    position = BASE_POSITION
    pivot_offset = ICON_SIZE * 0.5
    mouse_filter = Control.MOUSE_FILTER_STOP
    _badge = Label.new()
    _badge.position = Vector2(50.0, -14.0)
    _badge.size = Vector2(56.0, 32.0)
    _badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    add_child(_badge)
    GameState.dm_stage_changed.connect(_on_stage_changed)
    GameState.dm_arrived.connect(_on_dm_arrived)
    _on_stage_changed(GameState.dm_stage)

func _process(delta: float) -> void:
    _time += delta
    var amount: float = float(GameConfig.DM_ICON_SHAKE_PX[GameState.dm_stage])
    position = BASE_POSITION + Vector2(sin(_time * 70.0), cos(_time * 83.0)) * amount

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
