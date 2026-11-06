class_name InputSetup
extends RefCounted
## 입력 액션을 코드로 등록한다. 한글 자판에서도 동작하도록 physical_keycode를 쓴다.

static func ensure_actions() -> void:
    var table: Dictionary = {
        'move_up': KEY_W,
        'move_down': KEY_S,
        'move_left': KEY_A,
        'move_right': KEY_D,
        'interact': KEY_E,
        'open_phone': KEY_Q,
        'restart': KEY_R,
        'debug_toggle': KEY_F1,
        'debug_add_stage': KEY_F2,
        'debug_clear_stage': KEY_F3,
    }
    for action: String in table.keys():
        if InputMap.has_action(action):
            continue
        InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = table[action]
        InputMap.action_add_event(action, event)
