class_name PauseMenu
extends Control
## ESC 일시 정지 화면. process_mode = ALWAYS (씬에서 설정). 배치는 scenes/ui/pause_menu.tscn에서 편집한다.

@onready var _list: Control = $List
@onready var _title: Control = $Title
@onready var _sub_panel: Control = $SubPanel
@onready var _settings: Control = $SubPanel/Settings
@onready var _how_to: Control = $SubPanel/HowTo
@onready var _sub_title: Label = $SubPanel/Title


func _ready() -> void:
    visible = false
    _sub_panel.visible = false
    UiFx.add_hover(self)
    $List/Resume.pressed.connect(_resume)
    $List/Retry.pressed.connect(SceneFlow.restart)
    $List/Home.pressed.connect(func() -> void:
        Achievements.event('rage_quit')
        SceneFlow.go_home()
    )
    $List/Settings.pressed.connect(_open_sub.bind('Settings', true))
    $List/HowTo.pressed.connect(func() -> void:
        Achievements.event('how_to')
        _open_sub('How to Play', false)
    )
    $SubPanel/Back.pressed.connect(_close_sub)


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed('pause'):
        return
    if visible:
        if _sub_panel.visible:
            _close_sub()
        else:
            _resume()
    elif GameState.is_playing():
        visible = true
        get_tree().paused = true
    else:
        return
    get_viewport().set_input_as_handled()


func _resume() -> void:
    visible = false
    get_tree().paused = false


func _open_sub(title: String, show_settings: bool) -> void:
    _list.visible = false
    _title.visible = false
    _sub_panel.visible = true
    _sub_title.text = title
    _settings.visible = show_settings
    _how_to.visible = not show_settings


func _close_sub() -> void:
    _sub_panel.visible = false
    _list.visible = true
    _title.visible = true
