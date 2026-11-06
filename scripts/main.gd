extends Node2D
## 메인 씬. 월드와 UI 노드를 모두 코드로 만들고, 매 프레임 GameState.tick을 호출한다.

const HUD_LAYER: int = 10
const PHONE_LAYER: int = 20
const SCREEN_LAYER: int = 30
const DEBUG_LAYER: int = 40
const SPAWN_MAX_ATTEMPTS: int = 50

var _world: Node2D
var _player: PartyPlayer
var _audio: AudioDirector


func _ready() -> void:
    RenderingServer.set_default_clear_color(GameConfig.BACKGROUND_COLOR)
    GameState.start_game()
    GameState.game_ended.connect(_on_game_ended)
    _build_world()
    _build_ui()
    _spawn_npcs()


func _process(delta: float) -> void:
    GameState.tick(delta, _nearest_npc_distance())


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed('open_phone'):
        GameState.open_phone()
    elif event.is_action_pressed('debug_toggle'):
        GameState.set_debug(not GameState.debug_enabled)
    elif GameState.debug_enabled and event.is_action_pressed('debug_add_stage'):
        GameState.debug_add_stage()
    elif GameState.debug_enabled and event.is_action_pressed('debug_clear_stage'):
        GameState.debug_clear_stage()


func _build_world() -> void:
    _world = Node2D.new()
    _world.name = 'World'
    add_child(_world)
    _world.add_child(PartyMap.new())
    # 소품: 이름, 위치, 어그로 지점, 효과 반경, 재사용 대기, 색
    _add_prop('스피커', Vector2(320, 320), Vector2(320, 320),
        GameConfig.SPEAKER_RADIUS, GameConfig.SPEAKER_COOLDOWN, Color(0.75, 0.45, 0.25))
    _add_prop('조명', Vector2(1600, 320), Vector2(1600, 1120),
        GameConfig.LIGHT_RADIUS, GameConfig.LIGHT_COOLDOWN, Color(0.85, 0.8, 0.35))
    _add_prop('플레이리스트', Vector2(960, 1320), Vector2(960, 160),
        GameConfig.PLAYLIST_RADIUS, GameConfig.PLAYLIST_COOLDOWN, Color(0.45, 0.6, 0.85))
    _player = PartyPlayer.new()
    _player.name = 'PartyPlayer'
    _player.position = GameConfig.MAP_SIZE * 0.5
    _world.add_child(_player)


func _add_prop(prop_name: String, at: Vector2, point: Vector2, radius: float, cooldown: float, color: Color) -> void:
    var prop := PartyProp.new()
    prop.setup(prop_name, point, radius, cooldown, color)
    prop.position = at
    _world.add_child(prop)


func _build_ui() -> void:
    _audio = AudioDirector.new()
    _audio.name = 'AudioDirector'
    add_child(_audio)

    var hud_layer := _add_layer('HudLayer', HUD_LAYER)
    hud_layer.add_child(GameHud.new())

    var phone_layer := _add_layer('PhoneLayer', PHONE_LAYER)
    phone_layer.add_child(PhoneView.new())

    var screen_layer := _add_layer('ScreenLayer', SCREEN_LAYER)
    if not GameState.intro_seen:
        screen_layer.add_child(IntroScreen.new())
    screen_layer.add_child(EndScreen.new())

    var debug_layer := _add_layer('DebugLayer', DEBUG_LAYER)
    debug_layer.add_child(DebugOverlay.new())


func _add_layer(layer_name: String, layer_index: int) -> CanvasLayer:
    var layer := CanvasLayer.new()
    layer.name = layer_name
    layer.layer = layer_index
    add_child(layer)
    return layer


func _spawn_npcs() -> void:
    for i: int in int(GameState.cfg['npc_count']):
        var npc := PartyNpc.new()
        var point: Vector2 = GameConfig.random_map_point()
        for _attempt: int in SPAWN_MAX_ATTEMPTS:
            if point.distance_to(_player.position) >= GameConfig.NPC_SPAWN_MIN_DIST:
                break
            point = GameConfig.random_map_point()
        npc.position = point
        _world.add_child(npc)
        _audio.attach_npc(npc)


func _nearest_npc_distance() -> float:
    var best: float = INF
    for node: Node in get_tree().get_nodes_in_group('npcs'):
        var npc := node as Node2D
        if npc == null:
            continue
        best = minf(best, _player.global_position.distance_to(npc.global_position))
    return best


func _on_game_ended(_reason: int) -> void:
    get_tree().paused = true
