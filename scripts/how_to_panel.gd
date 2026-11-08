class_name HowToPanel
extends ScrollContainer
## How to Play 설명. 위쪽 버튼으로 한국어와 영어를 바꾸고, 고른 언어는 GameSettings에 저장한다(기본 한국어).
## 메뉴 휴대폰 화면과 일시 정지 화면이 함께 쓴다. 배치는 scenes/ui/how_to_panel.tscn에서 편집한다.

const KOREAN_FONT: Font = preload('res://scenes/ui/korean_font.tres')
const SELECTED_COLOR: Color = Color(0.85, 0.08, 0.1)
const UNSELECTED_COLOR: Color = Color(0.5, 0.5, 0.56)

const TEXT_KO: String = """홈커밍 파티. 여기 있는 사람들은 모두 내 여자친구를 안다. 그리고 또 메시지가 온다.

조작
[이동] WASD
[소품 / 문] 가까이에서 E
[휴대폰 켜기] Q 또는 메시지 아이콘
[휴대폰 끄기] 옆면 전원 버튼
[반응 / 말 걸기] 사람을 왼쪽 또는 오른쪽 클릭
[일시 정지] ESC

답장
단어의 글자를 순서대로 누른다. 긴 답장은 단어별로 나온다. 틀린 글자를 누르면 잠시 휴대폰이 잠긴다. 휴대폰을 보는 동안에는 메시지가 쌓이지 않는다.

들키지 않기
휴대폰을 켠 채로 누가 가까이 오면 들킨다. 안 읽은 메시지가 10개가 되면 차단당한다. 시계가 한 시간 지날 때까지 버티면 레벨 클리어.

소품
스피커와 조명은 근처 사람을 끌어모은다. 플레이리스트는 그 방의 모두를 모은다. 문을 닫으면 사람이 못 들어오지만, 다시 열고 들어올 수 있다.

사람들
머리 위에 !가 뜬 사람은 나를 따라온다. 클릭해서 말을 걸면 돌아간다. 한 방에 30초 넘게 머무르면 다른 방 사람들이 하나둘 찾아온다. 남의 길을 너무 오래 막으면 밀려난다.

파티 타임
조명 아래에서 E를 누르면 근처 사람과 춤을 춘다. 슬로우 댄스 시간에는 모두 거의 움직이지 않는다.

점수
답장, 반응, 춤, 레벨 클리어로 점수를 얻는다. 레벨마다 최고 점수를 깨고 업적을 모아 보자."""

const TEXT_EN: String = """Homecoming party. Everyone here knows your girlfriend. And then another message arrives.

CONTROLS
[MOVE] WASD
[PROPS / DOORS] E up close
[PHONE ON] Q or the message icon
[PHONE OFF] Side power button
[REACT / TALK] Left or right click people
[PAUSE] ESC

REPLY
Tap the letters of the word in order. Longer replies come word by word. A wrong letter locks the phone for a moment. Messages stop piling up while you look at the phone.

DON'T GET CAUGHT
If someone gets close while your phone is on, you're caught. Ten unread messages and she blocks you. Hold out until the clock moves one hour to clear the level.

PROPS
The speaker and the light pull nearby people to them. The playlist gathers everyone in its room. Close doors to keep people out, but they can open them again.

PEOPLE
People with a ! above their head follow you. Click them to talk and send them away. Stay in one room for 30 seconds and people from other rooms start coming to you. Stand in someone's way too long and they push you back.

PARTY TIME
Step into a spotlight and press E to dance with someone nearby. During Slow Dance Time everyone barely moves.

SCORE
Replies, reactions, dancing and clearing levels score points. Beat your best on every level and collect achievements."""

@onready var _text: Label = $Body/Text
@onready var _korean: Button = $Body/Language/Korean
@onready var _english: Button = $Body/Language/English


func _ready() -> void:
    _korean.add_theme_font_override('font', KOREAN_FONT)
    _korean.pressed.connect(_set_language.bind('ko'))
    _english.pressed.connect(_set_language.bind('en'))
    _apply(GameSettings.how_to_language)


## 다른 화면에서 언어를 바꿨을 수 있으니 보일 때마다 저장된 언어로 맞춘다.
func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and is_visible_in_tree():
        _apply(GameSettings.how_to_language)


func _set_language(language: String) -> void:
    GameSettings.set_how_to_language(language)
    _apply(language)
    scroll_vertical = 0


func _apply(language: String) -> void:
    var korean: bool = language == 'ko'
    _text.text = TEXT_KO if korean else TEXT_EN
    if korean:
        _text.add_theme_font_override('font', KOREAN_FONT)
    else:
        _text.remove_theme_font_override('font')
    for pair: Array in [[_korean, korean], [_english, not korean]]:
        var button: Button = pair[0]
        var selected: bool = pair[1]
        var color: Color = SELECTED_COLOR if selected else UNSELECTED_COLOR
        for key: StringName in [&'font_color', &'font_hover_color', &'font_pressed_color']:
            button.add_theme_color_override(key, color)
