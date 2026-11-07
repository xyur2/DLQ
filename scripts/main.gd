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
	var npcs: Array[PartyNpc] = _top_view.spawn_npcs(_top_view.npc_count())
	GameState.npc_total = npcs.size()
	for npc: PartyNpc in npcs:
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
	elif GameState.debug_enabled and event.is_action_pressed('debug_next_level'):
		# 디버그: 다음 레벨로 바로 이동. 마지막 레벨 다음은 테스트 맵(레벨 0), 그다음은 레벨 1
		if GameState.test_level:
			GameState.set_level(0)
		elif GameState.level_index + 1 < GameConfig.LEVELS.size():
			GameState.set_level(GameState.level_index + 1)
		else:
			GameState.set_test_level()
		get_tree().reload_current_scene()


func _on_game_ended(_reason: int) -> void:
	get_tree().paused = true
