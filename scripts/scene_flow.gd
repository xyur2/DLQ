class_name SceneFlow
extends RefCounted
## 메뉴와 게임 사이의 화면 이동을 모아 둔 곳.

const MENU_SCENE: String = 'res://scenes/menu/menu.tscn'
const GAME_SCENE: String = 'res://scenes/main.tscn'

## 메뉴를 열 때 바로 보여 줄 화면. 'levels'이면 레벨 선택에서 시작한다.
static var menu_start_view: String = ''


static func start_level(index: int) -> void:
    GameState.set_endless(false)
    GameState.set_level(index)
    _change_to(GAME_SCENE)


## 무한 모드는 마지막 레벨의 설정으로 진행한다.
static func start_endless() -> void:
    GameState.set_endless(true)
    GameState.set_level(GameConfig.LEVELS.size() - 1)
    _change_to(GAME_SCENE)


static func restart() -> void:
    _tree().paused = false
    _tree().reload_current_scene()


static func next_level() -> void:
    start_level(GameState.level_index + 1)


static func go_home() -> void:
    menu_start_view = ''
    _change_to(MENU_SCENE)


static func go_level_select() -> void:
    menu_start_view = 'levels'
    _change_to(MENU_SCENE)


static func _change_to(path: String) -> void:
    _tree().paused = false
    _tree().change_scene_to_file(path)


static func _tree() -> SceneTree:
    return Engine.get_main_loop() as SceneTree
