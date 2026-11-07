# res://scripts/game_config.gd
class_name GameConfig
extends RefCounted
## 모든 조정값. 전부 플레이테스트 전 임시값이다.
## A와 B는 각자 표시된 구역의 값만 수정한다.

# ===== A 구역 =====
# 맵(방·벽·문·소품 배치)은 레벨마다 scenes/top_view/levels/level_N.tscn에서 편집한다.
const CAMERA_ZOOM: float = 2.0                # 2 = 카메라 뷰 가로·세로 절반 (1920×1080 화면에 960×540이 보임)
const WALL_THICKNESS: float = 48.0
const BACKGROUND_COLOR: Color = Color(0.0, 0.0, 0.0)   # 맵 바깥. 벽 타일의 검정과 같게 한다

const PLAYER_RADIUS: float = 19.2
const PLAYER_SPEED: float = 144.0
const PLAYER_COLOR: Color = Color(0.85, 0.85, 0.8)
const CHARACTER_TURN_SPEED: float = 14.0      # 캐릭터가 이동 방향으로 도는 속도(라디안/초)
const CHARACTER_ANIM_BASE_SPEED: float = 60.0 # 걷기 애니메이션을 기본 속도(초당 12.5프레임)로 재생할 이동 속도. 빠를수록 비례해 빨라짐
const INTERACT_RANGE: float = 57.6

const NPC_RADIUS: float = 19.2
const NPC_SPEED: float = 86.4          # 플레이 피드백: 조금 더 빠르게 (57.6 → 86.4)
const NPC_AGGRO_SPEED: float = 172.8   # 115.2 → 172.8
const NPC_IDLE_TIME_RANGE: Vector2 = Vector2(1.0, 3.0)
const NPC_MAP_MARGIN: float = 72.0
const NPC_ARRIVE_DISTANCE: float = 9.6
const NPC_STUCK_TIMEOUT: float = 1.5
const NPC_SPAWN_MIN_DIST: float = 240.0      # 맵 절반에 맞춰 480 → 240
const NPC_SPAWN_SPACING: float = 64.0        # 처음 놓을 때 사람끼리 떨어뜨리는 거리 (지름 38.4 + 여유)
# 사람끼리는 몸이 부딪혀 겹치지 않는다. 걷는 사람은 가까운 사람을 미리 피해 옆으로 비켜 간다.
const NPC_AVOID_RADIUS: float = 64.0         # 이 거리 안의 사람을 피한다 (중심 거리)
const NPC_AVOID_STRENGTH: float = 1.2        # 피하는 힘. 클수록 일찍, 크게 비켜 간다
const NPC_AGGRO_SPREAD: float = 70.0         # 140 → 70
const NPC_COLOR: Color = Color(0.55, 0.5, 0.5)

const AGGRO_DURATION: float = 12.0
const SPEAKER_COOLDOWN: float = 30.0
const LIGHT_COOLDOWN: float = 30.0
const PLAYLIST_COOLDOWN: float = 60.0
const SPEAKER_RADIUS: float = 320.0          # 맵 절반에 맞춰 640 → 320
const LIGHT_RADIUS: float = 360.0            # 720 → 360
const PLAYLIST_RADIUS: float = 99999.0

# 사람 종류. 레벨의 npc_kinds로 종류별 인원을 정하고, 나머지는 일반(normal)이다.
# 색은 임시 그림용. 정식 아트가 들어오면 종류별 그림으로 바꾼다.
const NPC_KIND_COLORS: Dictionary = {
    'normal': Color(0.55, 0.5, 0.5),
    'active': Color(0.9, 0.6, 0.25),       # 활발형
    'tracker': Color(0.8, 0.25, 0.25),     # 추적형
    'attention': Color(0.65, 0.4, 0.9),    # 주의 집중형
    'interactive': Color(0.3, 0.7, 0.6),   # 상호작용형
}
# 활발형: 일반보다 1.5배 빠르고, 걷는 중에도 자주 방향을 바꾼다.
const ACTIVE_SPEED_MULTIPLIER: float = 1.5
const ACTIVE_IDLE_TIME_RANGE: Vector2 = Vector2(0.3, 1.0)   # 일반은 NPC_IDLE_TIME_RANGE (1~3초)
const ACTIVE_TURN_TIME_RANGE: Vector2 = Vector2(0.8, 2.0)   # 걷는 중 이 간격마다 새 목적지로 방향 전환
# 추적형: 일정 간격마다 정해진 시간 동안 플레이어 쪽으로 온다.
const TRACKER_INTERVAL_RANGE: Vector2 = Vector2(15.0, 45.0)   # 플레이 피드백: 빈도 2/3 (10~30 → 15~45)
const TRACKER_DURATION: float = 6.0
# 주의 집중형: 일정 간격마다 주변 사람들을 자기 주위로 부른다. 부르는 동안 자신은 제자리에 선다.
const ATTENTION_INTERVAL_RANGE: Vector2 = Vector2(30.0, 45.0)
const ATTENTION_RADIUS: float = 480.0          # 이 거리 안의 사람만 온다 (문이 닫힌 방은 제외)
const ATTENTION_DURATION: float = 8.0
# 상호작용형: 일정 간격마다 사용할 수 있는 소품으로 걸어가 작동시킨다.
const INTERACTIVE_INTERVAL_RANGE: Vector2 = Vector2(50.0, 70.0)
const INTERACTIVE_REACH: float = 48.0          # 소품 중심에서 이 거리 안에 오면 작동
const INTERACTIVE_GIVE_UP_SEC: float = 15.0    # 이 시간 안에 못 가면 포기
const INTERACTIVE_RETRY_SEC: float = 5.0       # 쓸 수 있는 소품이 없거나 포기했을 때 다시 시도하기까지

# 문 (레벨 1부터). E로 열고 닫는다. 닫혀 있으면 사람도 플레이어도 지나갈 수 없다.
const DOOR_WIDTH: float = 96.0
const DOOR_COLOR: Color = Color(0.45, 0.3, 0.2)
const DOOR_OPEN_COLOR: Color = Color(0.45, 0.3, 0.2, 0.35)
const DOOR_APPROACH_GAP: float = 12.0         # 사람이 문을 지날 때 문 양쪽에서 멈추는 지점의 여유
const LEVEL_TITLE_SEC: float = 3.0            # 레벨 시작 때 위쪽에 레벨 이름을 보여 주는 시간

# 따라오는 사람
const FOLLOW_SPEED: float = 108.0             # 플레이어(144)보다 느려서 따돌릴 수 있음
const FOLLOW_STOP_DISTANCE: float = 80.0      # 이 거리 안으로 들어오면 멈춰 서서 따라오기를 끝낸다 (발각 반경과 같음)
const FOLLOW_DURATION: float = 8.0            # follower_option이 켜진 사람이 한 번 따라오는 최대 시간
const FOLLOW_COOLDOWN: float = 37.5           # 다시 따라오기까지의 시간. 플레이 피드백: 빈도 2/3 (25 → 37.5)

# 사람에게 보내는 반응 (왼쪽 클릭 긍정, 오른쪽 클릭 부정)
const REACTION_RANGE: float = 300.0           # 플레이어에서 이 거리 안의 사람에게만
const REACTION_CLICK_RADIUS: float = 36.0     # 사람 중심에서 이 거리 안을 클릭하면 인정
const REACTION_COOLDOWN: float = 0.5          # 같은 사람에게 다시 보낼 수 있는 시간
const REACTION_GOAL_RANGE: Vector2i = Vector2i(3, 7)  # 따라오기까지 필요한 반응 수. 사람마다 무작위
const REACTION_FOLLOW_DURATION: float = 8.0

# 길막
const BLOCK_CONTACT_DISTANCE: float = 44.0    # 몸이 닿았다고 보는 거리 (반지름 합 38.4 + 여유)
const BLOCK_MARK_TIME: float = 0.6            # 이만큼 막으면 길막으로 기록 (히든 엔딩·점수)
const BLOCK_KNOCKBACK_TIME: float = 3.0       # 이만큼 막으면 밀려남
const KNOCKBACK_SPEED: float = 600.0
const KNOCKBACK_DURATION: float = 0.25        # 약 150px 밀려남
const STUN_DURATION: float = 3.0              # 이동·상호작용·휴대폰 불가 시간

# 둥글게 둥글게 (히든 엔딩)
const CIRCLE_RADIUS: float = 96.0
const CIRCLE_STARE_SEC: float = 3.0           # 둘러싸고 째려보는 시간
const CIRCLE_SCARE_SEC: float = 1.5           # 이후 공포 효과 시간, 끝나면 게임 종료

# 슬로우 댄스 타임
const SLOW_DANCE_START_RANGE: Vector2 = Vector2(60.0, 100.0)  # 시작 시각(초). 판마다 무작위
const SLOW_DANCE_DURATION: float = 25.0
const SLOW_DANCE_SPEED: float = 28.8
const SLOW_DANCE_WANDER: float = 48.0         # 제자리에서 움직이는 범위(px)

# 점수
const SCORE_REPLY_BASE: int = 100             # 1단계에서 답장할 때
const SCORE_REPLY_STAGE_PENALTY: int = 15     # 밀린 단계마다 깎임
const SCORE_REPLY_MIN: int = 10
const SCORE_REACTION: int = 5
const SCORE_BLOCK: int = 10
const SCORE_WRONG_LETTER: int = 10          # 틀린 글자를 누르면 깎임. 0 아래로는 내려가지 않음

# 소품 종류별 값. 위치와 어그로 지점은 top_view.tscn에서 배치한다.
const PROPS: Dictionary = {
    'speaker': {'name': '스피커', 'radius': SPEAKER_RADIUS, 'cooldown': SPEAKER_COOLDOWN, 'color': Color(0.75, 0.45, 0.25), 'icon_size': 110.0},
    'light': {'name': '조명', 'radius': LIGHT_RADIUS, 'cooldown': LIGHT_COOLDOWN, 'color': Color(0.85, 0.8, 0.35), 'icon_size': 96.0},
    'playlist': {'name': '플레이리스트', 'radius': PLAYLIST_RADIUS, 'cooldown': PLAYLIST_COOLDOWN, 'color': Color(0.45, 0.6, 0.85), 'icon_size': 150.0},
}

const SURVIVE_TIME: float = 180.0
const MAX_DM_STAGE: int = 10
const ALERT_RADIUS: float = 260.0
const TENSION_WEIGHT_PROXIMITY: float = 0.7
const TENSION_WEIGHT_DM: float = 0.3
const TENSION_RISE_PER_SEC: float = 3.0
const TENSION_FALL_PER_SEC: float = 0.5

# 테스트 맵(레벨 0). 플레이 목록(LEVELS)에는 없고, 디버그 모드(F1)에서 F4로 레벨을 넘기면 마지막 레벨 다음에 나온다.
const TEST_LEVEL: Dictionary = {
    'title': '레벨 0: 테스트 맵',
    'scene': 'res://scenes/top_view/levels/level_0.tscn',
    'npc_count': 5,
    'npc_kinds': {},
    'follower_count': 1,
    'dm_interval': 3.0,
    'reply_cooldown': 5.0,
    'letter_gap': 40.0,
    'caught_radius': 80.0,
    'decoy_count': 6,
    'wrong_lock_time': 2.0,
}

# 플레이할 수 있는 레벨. 위로 갈수록 DM이 자주 오고, 답장 후 쉬는 시간이 짧고, 휴대폰 글자 사이 간격이 좁다.
# 화면에는 Level 1, 2로 나온다(level_index 0, 1). 같은 키를 모든 레벨에 둔다. 레벨을 늘리려면 항목과 씬을 추가한다.
const LEVELS: Array = [
    {
        'title': '레벨 1: 옆방',
        'scene': 'res://scenes/top_view/levels/level_1.tscn',
        'npc_count': 10,           # 플레이 피드백: 북적이는 파티처럼 2배 (5 → 10)
        'npc_kinds': {},           # 종류별 인원. 예: {'active': 1, 'tracker': 1, 'attention': 1, 'interactive': 1}. 나머지는 일반
        'follower_count': 1,       # follower_option을 켜고 시작하는 사람 수 (일반 사람 중에서)
        'dm_interval': 2.6,        # DM 도착 주기(초)
        'reply_cooldown': 4.0,     # 답장한 뒤 다음 DM까지 쉬는 시간(초)
        'letter_gap': 20.0,        # 휴대폰 글자 버튼 사이 간격(px). LETTER_MIN_GAP보다 작아지지 않음
        'caught_radius': 80.0,
        'decoy_count': 6,          # 단어 글자 외에 섞이는 알파벳 수
        'wrong_lock_time': 2.0,    # 틀린 알파벳을 눌렀을 때 터치가 막히는 시간(초)
    },
    {
        'title': '레벨 2: 북적이는 파티',
        'scene': 'res://scenes/top_view/levels/level_2.tscn',
        'npc_count': 12,           # 6 → 12
        'npc_kinds': {},
        'follower_count': 2,
        'dm_interval': 2.2,
        'reply_cooldown': 3.0,
        'letter_gap': 8.0,
        'caught_radius': 80.0,
        'decoy_count': 8,
        'wrong_lock_time': 2.0,
    },
]

# ===== B 구역 =====
const VIEW_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const DM_BADGE_TEXT: Array = ['', '1', '4', '21', '34', '56', '73', '85', '99+', '99+', '99+']
const DM_ICON_SHAKE_PX: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 5.0, 7.0]
# 손 떨림 = 손 이미지와 마우스 커서의 흔들림. 휴대폰은 고정. 가까운 사람과의 거리를 떨림으로 구분하게 한다.
# 근접도 = 최근접 거리가 TREMOR_FAR_RADIUS일 때 0 → 발각 반경일 때 1 (빠르게 따라감)
# 떨림 폭(px) = BASE + DM × (DM 단계 / 10) + NEAR × 근접도^CURVE
# 떨림 속도   = 근접도^CURVE에 따라 NOISE_SPEED_MIN → MAX
const TREMOR_BASE_PX: float = 3.0             # 휴대폰을 켜면 항상
const TREMOR_DM_PX: float = 6.0               # DM 10단계일 때 더해지는 양
const TREMOR_NEAR_PX: float = 50.0            # 사람이 발각 반경까지 왔을 때 더해지는 양
const TREMOR_FAR_RADIUS: float = 520.0        # 이 거리 안으로 들어오면 흔들리기 시작
const TREMOR_CURVE: float = 2.0               # 클수록 가까워질수록 급격히 커짐
const TREMOR_RISE_PER_SEC: float = 4.0        # 근접도가 오를 때 따라가는 속도
const TREMOR_FALL_PER_SEC: float = 2.0        # 근접도가 내릴 때 따라가는 속도
const TREMOR_NOISE_SPEED_MIN: float = 60.0
const TREMOR_NOISE_SPEED_MAX: float = 220.0
const TREMOR_NOISE_FREQUENCY: float = 0.03
const TREMOR_NOISE_GAIN: float = 1.6          # 노이즈 값(대략 ±0.6)을 ±1 근처로 키움
const TREMOR_PHONE_RATIO: float = 0.5         # 휴대폰은 손·커서의 이 비율만큼, 다른 패턴으로 흔들림
const PHONE_SLIDE_SEC: float = 0.45           # 휴대폰이 올라오고 내려가는 시간, 배경이 어두워지고 밝아지는 시간
const PHONE_SLIDE_DISTANCE: float = 1100.0    # 내려가 있을 때의 거리(px). 화면 밖으로 완전히 나가는 값
# 답장 단어. 대문자 알파벳만.
const REPLY_WORDS: Array = ['LOVE', 'MISS', 'SOON', 'WAIT', 'CALL', 'LATER', 'HUSH', 'KISS', 'BABY', 'SORRY']
const LETTER_GRID: Vector2i = Vector2i(4, 6)  # 알파벳 버튼을 놓는 칸 (열, 행). 칸 간격은 레벨의 letter_gap
const LETTER_JITTER: float = 8.0              # 칸 안에서 무작위로 어긋나는 최대 정도(px). 간격이 좁으면 자동으로 줄어듦
const LETTER_MIN_GAP: float = 6.0             # 어긋나도 버튼 사이에 남기는 최소 간격(px). 서로 붙지 않게
# 휴대폰을 켠 동안 위에 뜨는 여자친구 메시지. 누르면 사라진다.
const GIRLFRIEND_MESSAGES: Array = [
    '자기야 어디야?', '왜 이렇게 안 보여', '누구랑 연락해?', '나 지금 찾으러 갈게',
    '휴대폰 그만 보고 나와', '내 친구가 너 봤대', '왜 답장 안 해?', '지금 어디 있어?',
]
const GIRLFRIEND_FIRST_DELAY: float = 1.5     # 휴대폰을 켠 뒤 첫 메시지까지
const GIRLFRIEND_INTERVAL_RANGE: Vector2 = Vector2(5.0, 10.0)
const GIRLFRIEND_SHOW_SEC: float = 3.0
# 휴대폰에서 연속으로 입력하면 음향 효과가 나오는 글자
const LETTER_COMBOS: Dictionary = {'LLL': 'take_l', 'BAJI': 'baji'}
# 메뉴와 종료 화면
const MENU_NOTIFY_INTERVAL: float = 1.5       # 메인 메뉴를 가만히 두면 알림이 오르는 간격(초)
const MENU_CREDITS_SEC: float = 4.0           # 전원 버튼을 누른 뒤 개발진 정보를 보여 주는 시간
const MENU_PHONE_ZOOM_SEC: float = 0.6        # 휴대폰이 가운데로 와서 커지는 시간
const MENU_MESSAGE_SIZE: Vector2 = Vector2(360.0, 120.0)  # 레벨 선택 화면의 메시지 크기
const MENU_MESSAGE_FIRST_DELAY: float = 1.2   # 레벨 선택 화면에서 첫 메시지가 오기 전 비어 있는 시간
const MENU_MESSAGES: Array = ['어디야?', '왜 답이 없어', '지금 보러 갈까?']
const MENU_MESSAGE_INTERVAL: float = 0.9      # 레벨 선택 화면에 메시지가 하나씩 도착하는 간격
const MENU_MESSAGE_HOLD: float = 2.2          # 다 도착한 뒤 비우고 다시 시작하기까지
const MENU_ICON_DELAY: float = 0.25           # 홈으로 돌아와 휴대폰이 멈춘 뒤 아이콘이 나타나기 시작할 때까지
const MENU_ICON_FADE_SEC: float = 0.7         # 아이콘이 나타나는 시간
const MENU_MUSIC_PATH: String = 'res://audio/menu_music.ogg'
const STAMP_SOUND_PATH: String = 'res://audio/stamp.ogg'
const END_PANEL_SEC: float = 1.0              # 스토리 컷이 하나씩 나오는 간격
const END_STAMP_SEC: float = 0.18             # 도장이 내려찍히는 시간
const MUSIC_VOLUME_DB: float = -8.0
const MUSIC_PHONE_DUCK_DB: float = -8.0
const NPC_SOUND_MAX_DISTANCE: float = 700.0
