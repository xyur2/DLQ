class_name PhoneHands
extends Control

const SKIN: Color = Color(0.85, 0.65, 0.55)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var w: float = GameConfig.PHONE_SIZE.x
    var h: float = GameConfig.PHONE_SIZE.y
    draw_rect(Rect2(-180.0, h - 460.0, 210.0, 500.0), SKIN)
    draw_rect(Rect2(w - 30.0, h - 460.0, 210.0, 500.0), SKIN)
    for i: int in 4:
        var y: float = h - 660.0 + float(i) * 12.0
        draw_rect(Rect2(-170.0 + float(i) * 48.0, y, 38.0, 210.0), SKIN)
        draw_rect(Rect2(w + 132.0 - float(i) * 48.0, y, 38.0, 210.0), SKIN)
