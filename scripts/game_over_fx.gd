class_name GameOverFx
extends CanvasLayer
## 게임 오버 직전, 플레이 화면에서 보여 주는 연출. EndScreen이 종료 화면을 띄우기 전에 play()를 기다린다.
## 게임은 이미 일시 정지된 상태라 이 노드는 항상 돌고(process_mode = ALWAYS), 다른 노드는 일시 정지와 상관없는 트윈으로 움직인다.
## - 들킴: 휴대폰이 내려가 탑뷰가 보이고, 들킨 사람 머리 위에 느낌표가 뜬 뒤 화면이 하얗게 깜빡인다.
## - 차단: 휴대폰이 올라오고 애인 메시지(GameConfig.BLOCKED_MESSAGES)가 차례로 온다.
## 배치는 scenes/ui/ui.tscn의 GameOverFx(layer 28: 휴대폰 20 위, 종료 화면 30 아래)에서 편집한다.

const FLASH_ON_SEC: float = 0.07
const FLASH_OFF_SEC: float = 0.07
const FLASH_FADE_SEC: float = 0.3

@onready var _flash: ColorRect = $Flash


func _ready() -> void:
    add_to_group('game_over_fx')
    _flash.visible = false


## 종료 이유에 맞는 연출을 끝까지 재생한다. 연출이 없는 이유는 바로 돌아온다.
func play(reason: int) -> void:
    if reason == GameState.EndReason.CAUGHT:
        await _play_caught()
    elif reason == GameState.EndReason.TOO_MANY_DMS:
        await _play_blocked()


## 종료 화면이 덮은 뒤 남은 흰 화면을 치운다.
func clear() -> void:
    if not _flash.visible:
        return
    var tween: Tween = create_tween()
    tween.tween_property(_flash, 'modulate:a', 0.0, FLASH_FADE_SEC)
    tween.tween_callback(_flash.hide)


func _play_caught() -> void:
    var phone: PhoneView = _phone()
    if phone != null:
        phone.force_hide(GameConfig.CAUGHT_PHONE_DROP_SEC)
    await _wait(GameConfig.CAUGHT_PHONE_DROP_SEC)
    var top: TopView = _top_view()
    var npc: PartyNpc = top.nearest_npc() if top != null else null
    if npc != null:
        npc.show_caught_alert()
    UiFx.play_sound('alert')
    await _wait(GameConfig.CAUGHT_ALERT_SEC)
    _flash.visible = true
    _flash.modulate.a = 1.0
    for i: int in GameConfig.CAUGHT_FLASH_COUNT:
        _flash.color = Color.WHITE
        await _wait(FLASH_ON_SEC)
        _flash.color = Color(1, 1, 1, 0)
        await _wait(FLASH_OFF_SEC)
    _flash.color = Color.WHITE


func _play_blocked() -> void:
    var phone: PhoneView = _phone()
    if phone == null:
        return
    phone.force_show(GameConfig.BLOCKED_PHONE_RISE_SEC)
    await _wait(GameConfig.BLOCKED_PHONE_RISE_SEC + GameConfig.BLOCKED_FIRST_DELAY)
    for message: String in GameConfig.BLOCKED_MESSAGES:
        phone.add_breakup_message(message)
        await _wait(GameConfig.BLOCKED_MESSAGE_SEC)
    await _wait(GameConfig.BLOCKED_HOLD_SEC)


func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds, true, false, true).timeout


func _phone() -> PhoneView:
    var scene: Node = get_tree().current_scene
    return scene.get_node_or_null('PhoneLayer/Phone') as PhoneView if scene != null else null


func _top_view() -> TopView:
    var scene: Node = get_tree().current_scene
    return scene.get_node_or_null('TopView') as TopView if scene != null else null
