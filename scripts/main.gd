extends Node2D
## 메인 씬. 월드와 UI 노드를 모두 코드로 만들고, 매 프레임 GameState.tick을 호출한다.
## A1 단계: 뼈대만 둔다. 월드(A2~A5)와 B의 UI는 이후 단계에서 이 파일에 붙인다.


func _ready() -> void:
    RenderingServer.set_default_clear_color(GameConfig.BACKGROUND_COLOR)
    GameState.start_game()
    GameState.game_ended.connect(_on_game_ended)
    # TODO(확인필요): B의 IntroScreen이 준비되기 전까지는 인트로 없이 바로 시작한다.
    if not GameState.intro_seen:
        GameState.begin_play()


func _process(delta: float) -> void:
    # A3에서 NPC가 생기기 전까지 최근접 거리는 INF
    GameState.tick(delta, INF)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed('open_phone'):
        GameState.open_phone()
    elif event.is_action_pressed('debug_toggle'):
        GameState.set_debug(not GameState.debug_enabled)
    elif GameState.debug_enabled and event.is_action_pressed('debug_add_stage'):
        GameState.debug_add_stage()
    elif GameState.debug_enabled and event.is_action_pressed('debug_clear_stage'):
        GameState.debug_clear_stage()


func _on_game_ended(_reason: int) -> void:
    get_tree().paused = true
