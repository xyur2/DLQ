class_name UiFx
extends RefCounted
## 메뉴 화면들이 함께 쓰는 작은 움직임.

const HOVER_SCALE: float = 1.035
const HOVER_SEC: float = 0.1
const HOVER_TINT: Color = Color(1.0, 0.82, 0.2)
const PRESS_TINT: Color = Color(1.0, 0.55, 0.15)
const FADE_IN_SEC: float = 0.35
const HOVER_SOUND: String = 'option'    # 버튼에 마우스를 올릴 때 (audio/option.mp3)
const CLICK_SOUND: String = 'select'    # 버튼을 누를 때 (audio/select.mp3)

## 효과음 플레이어. 장면이 바뀌어도 끊기지 않도록 루트에 하나씩 붙여 두고 다시 쓴다.
static var _sound_players: Dictionary = {}


## 글자가 있는 버튼에 마우스를 올리면 살짝 커지고 노란색이 되며, 누르면 주황색이 된다.
## 올릴 때 HOVER_SOUND, 누를 때 CLICK_SOUND가 난다.
static func add_hover(root: Node) -> void:
    if root is Button and (root as Button).text != '':
        var button: Button = root
        button.mouse_entered.connect(_set_button_look.bind(button, HOVER_SCALE, HOVER_TINT))
        button.mouse_exited.connect(_set_button_look.bind(button, 1.0, Color.WHITE))
        button.button_down.connect(_set_button_look.bind(button, HOVER_SCALE, PRESS_TINT))
        button.button_up.connect(_set_button_look.bind(button, HOVER_SCALE, HOVER_TINT))
        button.mouse_entered.connect(func() -> void:
            if not button.disabled:
                play_sound(HOVER_SOUND)
        )
        button.pressed.connect(play_sound.bind(CLICK_SOUND))
    for child: Node in root.get_children():
        add_hover(child)


static func _set_button_look(button: Button, goal: float, tint: Color) -> void:
    button.pivot_offset = button.size * 0.5
    var tween: Tween = button.create_tween().set_parallel()
    tween.tween_property(button, 'scale', Vector2.ONE * goal, HOVER_SEC)
    tween.tween_property(button, 'self_modulate', tint, HOVER_SEC)


## audio 폴더의 효과음을 SFX 버스로 한 번 재생한다. 일시 정지 중에도 난다. 파일이 없으면 조용히 넘어간다.
## clip_sec가 0보다 크면 그 시간만 재생한다.
static func play_sound(sound: String, clip_sec: float = 0.0) -> void:
    var player: AudioStreamPlayer = _sound_players.get(sound)
    if player == null or not is_instance_valid(player):
        player = AudioStreamPlayer.new()
        player.stream = AudioDirector.load_sound(sound)
        player.bus = &'SFX'
        player.process_mode = Node.PROCESS_MODE_ALWAYS
        (Engine.get_main_loop() as SceneTree).root.add_child(player)
        _sound_players[sound] = player
    AudioDirector.play_clip(player, clip_sec)


## 장면이 시작될 때 검은 화면에서 밝아진다.
static func fade_in(cover: ColorRect) -> void:
    cover.visible = true
    cover.modulate.a = 1.0
    var tween: Tween = cover.create_tween()
    tween.tween_property(cover, 'modulate:a', 0.0, FADE_IN_SEC)
    tween.tween_callback(cover.hide)
