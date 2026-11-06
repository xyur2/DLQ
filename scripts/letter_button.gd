class_name LetterButton
extends Button
## 휴대폰 화면의 알파벳 버튼 하나. 모양은 scenes/phone/letter_button.tscn에서 편집한다.

signal picked(button: LetterButton)

const USED_TINT: Color = Color(0.45, 0.9, 0.55, 0.55)

var letter: String = ''
var used: bool = false


func _ready() -> void:
    pressed.connect(_on_pressed)


func setup(value: String) -> void:
    letter = value
    text = value


## 맞게 누른 글자: 초록으로 흐리게 남기고 다시 못 누르게 한다.
func mark_used() -> void:
    used = true
    disabled = true
    modulate = USED_TINT


func set_locked(locked: bool) -> void:
    disabled = locked or used


func _on_pressed() -> void:
    picked.emit(self)
