extends Node2D
## 메인 씬. 하위 씬 세 개를 묶고 매 프레임 GameState.tick을 호출한다.
## - TopView (scenes/top_view/top_view.tscn): 맵, 소품, 플레이어, NPC
## - Phone (scenes/phone/phone.tscn): 휴대폰 화면, 단어 입력, 전원 버튼, 마우스 떨림
## - UI (scenes/ui/ui.tscn): HUD, 시작 화면, 종료 화면, 디버그 오버레이

@onready var _top_view: TopView = $TopView
@onready var _audio: AudioDirector = $AudioDirector


## 자식 씬의 _ready보다 먼저 호출되므로, UI가 초기화된 상태를 읽는다.
func _enter_tree() -> void:
	GameState.start_game()


func _ready() -> void:
	RenderingServer.set_default_clear_color(GameConfig.BACKGROUND_COLOR)
	GameState.game_ended.connect(_on_game_ended)
	for npc: PartyNpc in _top_view.spawn_npcs(int(GameState.cfg['npc_count'])):
		_audio.attach_npc(npc)


func _process(delta: float) -> void:
	GameState.tick(delta, _top_view.nearest_npc_distance())


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
