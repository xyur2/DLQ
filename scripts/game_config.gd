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
# 한 방에 오래 머물기: 플레이어가 같은 방에 CAMP_START_SEC 이상 있으면 다른 방의 사람을 하나씩 그 방으로 부른다.
# 부르는 간격은 PULL_INTERVAL_START에서 CAMP_RAMP_SEC 동안 PULL_INTERVAL_MIN까지 줄어 점점 빨리 모인다.
# 불려 오는 사람은 닫힌 문도 열고 들어온다. 다른 방으로 나가면(문틀은 제외) 처음부터 다시 센다. 무한 모드에는 없다.
const CAMP_START_SEC: float = 30.0
const CAMP_PULL_INTERVAL_START: float = 6.0
const CAMP_PULL_INTERVAL_MIN: float = 2.0
const CAMP_RAMP_SEC: float = 60.0
# 사람끼리는 몸이 부딪혀 겹치지 않는다. 걷는 사람은 가까운 사람을 미리 피해 옆으로 비켜 간다.
const NPC_AVOID_RADIUS: float = 64.0         # 이 거리 안의 사람을 피한다 (중심 거리)
const NPC_AVOID_STRENGTH: float = 1.2        # 피하는 힘. 클수록 일찍, 크게 비켜 간다
# 방마다 사람 수. 방의 기본 인원 = 넓이 / AREA_PER_NPC (반올림, 최소 1). 큰 방 960×720 = 6명, 작은 방 480×528 = 2명.
# 판의 사람 수 = 방 기본 인원의 합 + 레벨의 npc_bonus. 추가 인원은 기본 인원 비율로 방마다 나눠 목표 인원(할당량)이 된다.
const AREA_PER_NPC: float = 115200.0
const CROWD_MARGIN: int = 2                  # 방 인원이 목표 인원보다 이만큼 이상 많으면 다른 방으로 보낸다
const BALANCE_INTERVAL: float = 1.0          # 방 인원을 세고 나누는 간격(초)
const CROWD_PICK_BASE: float = 0.5           # 걸을 목적지를 고를 때 꽉 찬 방에도 주는 최소 가중치 (가중치 = 빈자리 + 이 값)
const CROWD_HOP_FALLOFF: float = 0.12        # 문을 하나 더 지날 때마다 목적지 가중치에 곱함. 평소에는 가까운 방 위주로 다니고, 먼 방은 CrowdBalancer가 보낸다
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
# 닫힌 문 열기. 사람이 걸어갈 곳을 고를 때 닫힌 문 너머의 방을 고르면, 그 문까지 가서 열고 들어간다.
const DOOR_OPEN_EMPTY_CHANCE: float = 0.25    # 닫힌 문 너머에 사람이 0명인 방(플레이어 제외)이 있으면 그 방을 고를 확률
const DOOR_OPEN_CHANCE: float = 0.04          # 그 밖에 닫힌 문 너머의 방(사람이 있어도)을 고를 확률
const DOOR_OPEN_REACH: float = 72.0           # 문 가운데에서 이 거리 안에 오면 문을 연다
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

# 춤추기: 조명(light 소품)이 비추는 바닥(어그로 지점) 안에서 E를 누르면 가까운 사람 한 명과 춤춘다. 조명 하나에 한 번.
const DANCE_SEC: float = 5.0                  # 춤추는 동안 아무것도 할 수 없는 시간(초)
const DANCE_TURNS: float = 1.0                # 춤추는 동안 플레이어와 짝이 둘 사이 가운데를 도는 바퀴 수 (정수면 제자리로 돌아옴). 5초에 한 바퀴
const DANCE_CAMERA_RETURN_SEC: float = 0.35   # 춤이 끝난 뒤 카메라가 가운데에서 플레이어에게 돌아오는 시간
const DANCE_SCORE: int = 300                  # 춤 한 번 점수 (답장 최고 200, 반응 처음 50)
const DANCE_SPOT_RADIUS: float = 110.0        # 조명이 비추는 바닥 반경. 플레이어 중심이 이 안이어야 춤출 수 있음
const DANCE_PARTNER_RANGE: float = 160.0      # 플레이어에게서 이 거리 안의 가장 가까운 사람과 춤춘다
const DANCE_SPOT_COLOR: Color = Color(1.0, 0.85, 0.55, 0.3)

# 슬로우 댄스 타임
const SLOW_DANCE_START_RANGE: Vector2 = Vector2(60.0, 100.0)  # 시작 시각(초). 판마다 무작위
const SLOW_DANCE_DURATION: float = 25.0
const SLOW_DANCE_SPEED: float = 28.8
const SLOW_DANCE_WANDER: float = 48.0         # 제자리에서 움직이는 범위(px)

# 점수
const SCORE_CLEAR_PER_LEVEL: int = 1000       # 레벨 클리어 보너스 = 이 값 × 레벨 번호 (레벨 1은 1000, 레벨 9는 9000). 무한 모드·테스트 맵은 없음
const SCORE_REPLY_BASE: int = 200             # 1단계에서 답장할 때
const SCORE_REPLY_STAGE_PENALTY: int = 20     # 밀린 단계마다 깎임
const SCORE_REPLY_MIN: int = 20
const SCORE_REACTION_FIRST: int = 50          # 같은 사람에게 처음 반응할 때
const SCORE_REACTION_DECAY: float = 0.5       # 같은 사람에게 다시 반응할 때마다 곱함 (내림): 50, 25, 12, 6, 3, 1, 0...
const SCORE_REACTION_RESET_SEC: float = 20.0  # 같은 사람에게 마지막으로 반응한 뒤 이만큼 지나면 다시 처음 점수(50점)부터
const SCORE_WRONG_LETTER: int = 10            # 틀린 글자를 누르면 깎임. 0 아래로는 내려가지 않음
# 길막은 점수가 없다 (히든 엔딩 판정에만 쓴다).

# 소품 종류별 값. 위치와 어그로 지점은 레벨 씬에서 배치한다.
# whole_room: 반경 대신 소품이 있는 방 전체의 사람을 모은다(무한 모드는 소품 가운데의 ENDLESS_GATHER_SIZE 범위).
const PROPS: Dictionary = {
    'speaker': {'name': 'Speaker', 'radius': SPEAKER_RADIUS, 'cooldown': SPEAKER_COOLDOWN, 'color': Color(0.75, 0.45, 0.25), 'icon_size': 110.0},
    'light': {'name': 'Light', 'radius': LIGHT_RADIUS, 'cooldown': LIGHT_COOLDOWN, 'color': Color(0.85, 0.8, 0.35), 'icon_size': 96.0},
    'playlist': {'name': 'Playlist', 'radius': PLAYLIST_RADIUS, 'cooldown': PLAYLIST_COOLDOWN, 'color': Color(0.45, 0.6, 0.85), 'icon_size': 150.0, 'whole_room': true},
}

const SURVIVE_TIME: float = 180.0             # 게임 시간 1시간. 레벨 n은 시계로 (CLOCK_START_HOUR + n − 1)시부터 1시간
const CLOCK_START_HOUR: int = 10              # 레벨 1(과 무한 모드)이 시작하는 시각. 시계는 12시간제 (12시 다음은 1시)
const MAX_DM_STAGE: int = 10
const ALERT_RADIUS: float = 260.0
const TENSION_WEIGHT_PROXIMITY: float = 0.7
const TENSION_WEIGHT_DM: float = 0.3
const TENSION_RISE_PER_SEC: float = 3.0
const TENSION_FALL_PER_SEC: float = 0.5

# 테스트 맵(레벨 0). 플레이 목록(LEVELS)에는 없고, 디버그 모드(F1)에서 F4로 레벨을 넘기면 마지막 레벨 다음에 나온다.
const TEST_LEVEL: Dictionary = {
    'title': 'Level 0: Test Map',
    'scene': 'res://scenes/top_view/levels/level_0.tscn',
    'npc_bonus': 0,
    'npc_kinds': {},
    'follower_count': 1,
    'dm_interval': 3.0,
    'reply_cooldown': 5.0,
    'reply_words': Vector2i(1, 1),
    'long_chance': 0.0,
    'decoy_count': 0,
    'letter_gap': 40.0,
    'letter_spread': 2.0,
    'letter_jitter': 0.0,
    'caught_radius': 80.0,
    'wrong_lock_time': 2.0,
}

# 플레이할 수 있는 레벨 9개. 화면에는 Level 1~9로 나온다(level_index 0~8).
# 레벨마다 맵 파일이 따로 있다(level_N.tscn). 소품·문 배치는 레벨마다 따로 고칠 수 있다.
# 방 구조는 3레벨마다 바뀐다: 1~3 큰 방 + 작은 방, 4~6 큰 방 + 작은 방 4개, 7~9 큰 방 - 긴 복도 - 큰 방, 복도 옆 작은 방 3개.
# DM 주기와 답장 후 쉬는 시간은 레벨 5까지 짧아지고(3.0 → 2.4초, 5 → 4초) 그 뒤로는 그대로다.
# 휴대폰 답장 난이도 (기획 표):
#   레벨 | 메시지 길이 | 단어 길이 | 글자 풍선               | 풍선 간격
#   1    | 한 단어     | 짧게      | 필요한 글자만            | 서로 떨어져 (가지런히)
#   2    | 한 단어     | 길게      | 필요한 글자만            | 서로 떨어져 (가지런히)
#   3~4  | 1~2단어     | 짧게      | 필요한 글자만            | 불규칙하게 떨어져
#   5    | 1~2단어     | 짧게      | 가짜 글자 3개            | 불규칙하게 붙어
#   6    | 1~2단어     | 짧/길게   | 가짜 글자 3개            | 불규칙하게 붙어
#   7~8  | 1~3단어     | 짧/길게   | 가짜 글자 3개            | 빽빽하게
#   9    | 2~3단어     | 짧/길게   | 가짜 글자로 칸을 꽉 채움 | 빽빽하게
# 레벨이 오를수록 긴 단어(LONG_WORD_LEN 글자 이상)가 든 문구가 나올 확률(long_chance)이 오른다.
# 사람 수 = 맵의 방 기본 인원 합(8, 14, 20) + npc_bonus(맵 안에서 1번째 레벨 2, 2번째 4, 3번째 6).
# 같은 키를 모든 레벨에 둔다. 레벨을 늘리려면 항목과 씬을 추가한다.
const LEVELS: Array = [
    {
        'title': 'Level 1: The Side Room',
        'scene': 'res://scenes/top_view/levels/level_1.tscn',
        'npc_bonus': 2,            # 방 기본 인원 합에 더하는 사람 수
        'npc_kinds': {},           # 종류별 인원. 예: {'active': 1, 'tracker': 1, 'attention': 1, 'interactive': 1}. 나머지는 일반
        'follower_count': 1,       # follower_option을 켜고 시작하는 사람 수 (일반 사람 중에서)
        'dm_interval': 3.0,        # DM 도착 주기(초). 휴대폰을 보는 동안은 멈춘다
        'reply_cooldown': 5.0,     # 답장한 뒤 다음 DM까지 쉬는 시간(초)
        'reply_words': Vector2i(1, 1),  # 답장 문구의 단어 수 (최소, 최대). REPLY_PHRASES에서 고른다
        'long_chance': 0.0,        # 긴 단어가 든 문구를 고를 확률 (0: 짧은 단어만, 1: 긴 단어만)
        'decoy_count': 0,          # 단어 글자 외에 섞이는 가짜 알파벳 수. -1이면 칸(LETTER_GRID)을 꽉 채운다
        'letter_gap': 40.0,        # 휴대폰 글자 풍선 사이 간격(px). LETTER_MIN_GAP보다 작아지지 않음
        'letter_spread': 2.0,      # 풍선을 흩어 놓는 정도. 줄 수 = 풍선 수 × 이 값 ÷ 열 수 (1이면 빈칸 없이 모임, 최대 6줄)
        'letter_jitter': 0.0,      # 풍선이 칸에서 무작위로 어긋나는 최대 정도(px). 0이면 가지런함. 간격이 좁으면 자동으로 줄어듦
        'caught_radius': 80.0,
        'wrong_lock_time': 2.0,    # 틀린 알파벳을 눌렀을 때 터치가 막히는 시간(초)
    },
    {'title': 'Level 2: More Guests', 'scene': 'res://scenes/top_view/levels/level_2.tscn', 'npc_bonus': 4, 'npc_kinds': {},
        'follower_count': 1, 'dm_interval': 2.85, 'reply_cooldown': 4.75,
        'reply_words': Vector2i(1, 1), 'long_chance': 1.0, 'decoy_count': 0,
        'letter_gap': 40.0, 'letter_spread': 2.0, 'letter_jitter': 0.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 3: Crowded Side Room', 'scene': 'res://scenes/top_view/levels/level_3.tscn', 'npc_bonus': 6, 'npc_kinds': {},
        'follower_count': 1, 'dm_interval': 2.7, 'reply_cooldown': 4.5,
        'reply_words': Vector2i(1, 2), 'long_chance': 0.0, 'decoy_count': 0,
        'letter_gap': 36.0, 'letter_spread': 1.8, 'letter_jitter': 14.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 4: Little Rooms', 'scene': 'res://scenes/top_view/levels/level_4.tscn', 'npc_bonus': 2, 'npc_kinds': {},
        'follower_count': 2, 'dm_interval': 2.55, 'reply_cooldown': 4.25,
        'reply_words': Vector2i(1, 2), 'long_chance': 0.0, 'decoy_count': 0,
        'letter_gap': 36.0, 'letter_spread': 1.8, 'letter_jitter': 14.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 5: Guests Everywhere', 'scene': 'res://scenes/top_view/levels/level_5.tscn', 'npc_bonus': 4, 'npc_kinds': {},
        'follower_count': 2, 'dm_interval': 2.4, 'reply_cooldown': 4.0,
        'reply_words': Vector2i(1, 2), 'long_chance': 0.0, 'decoy_count': 3,
        'letter_gap': 16.0, 'letter_spread': 1.3, 'letter_jitter': 5.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 6: No Empty Rooms', 'scene': 'res://scenes/top_view/levels/level_6.tscn', 'npc_bonus': 6, 'npc_kinds': {},
        'follower_count': 2, 'dm_interval': 2.4, 'reply_cooldown': 4.0,
        'reply_words': Vector2i(1, 2), 'long_chance': 0.3, 'decoy_count': 3,
        'letter_gap': 16.0, 'letter_spread': 1.3, 'letter_jitter': 5.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 7: The Long Hallway', 'scene': 'res://scenes/top_view/levels/level_7.tscn', 'npc_bonus': 2, 'npc_kinds': {},
        'follower_count': 3, 'dm_interval': 2.4, 'reply_cooldown': 4.0,
        'reply_words': Vector2i(1, 3), 'long_chance': 0.4, 'decoy_count': 3,
        'letter_gap': 6.0, 'letter_spread': 1.0, 'letter_jitter': 0.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 8: Hallway Crowd', 'scene': 'res://scenes/top_view/levels/level_8.tscn', 'npc_bonus': 4, 'npc_kinds': {},
        'follower_count': 3, 'dm_interval': 2.4, 'reply_cooldown': 4.0,
        'reply_words': Vector2i(1, 3), 'long_chance': 0.55, 'decoy_count': 3,
        'letter_gap': 6.0, 'letter_spread': 1.0, 'letter_jitter': 0.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
    {'title': 'Level 9: Last Call', 'scene': 'res://scenes/top_view/levels/level_9.tscn', 'npc_bonus': 6, 'npc_kinds': {},
        'follower_count': 3, 'dm_interval': 2.4, 'reply_cooldown': 4.0,
        'reply_words': Vector2i(2, 3), 'long_chance': 0.7, 'decoy_count': -1,
        'letter_gap': 6.0, 'letter_spread': 1.0, 'letter_jitter': 0.0, 'caught_radius': 80.0, 'wrong_lock_time': 2.0},
]

# 무한 모드. 방과 벽 없이 상하좌우로 끝없이 이어진 바닥(ENDLESS_SCENE).
# 사람과 소품은 플레이어 둘레 구역(ENDLESS_ZONE_HALF) 안, 화면 밖에서 생기고, 구역에서 멀어지고 화면 밖이면 사라진다.
# 소품은 한 번 쓰면 사라진다. 게임 시간 1시간(ENDLESS_LEVEL_SEC, 시계 1시간)마다 무한 레벨이 오른다.
# 무한 레벨 n의 사람 수 = START + STEP × (n − 1), 레벨 9에서 상한(40명).
# DM 주기·쉬는 시간, 답장 문구, 글자 풍선 간격, 섞이는 글자는 일반 레벨 n(9 이상이면 레벨 9)과 같다. DM 주기는 레벨 5에서 상한.
const ENDLESS_SCENE: String = 'res://scenes/top_view/levels/endless.tscn'
const ENDLESS_LEVEL_SEC: float = 180.0          # 게임 시간 1시간 (SURVIVE_TIME과 같음)
const ENDLESS_NPC_START: int = 18               # 구역 안 사람 수 (무한 레벨 1)
const ENDLESS_NPC_STEP: int = 3
const ENDLESS_NPC_MAX: int = 40
const ENDLESS_FOLLOWER_MAX: int = 3             # 따라오는 사람. 1명에서 3레벨마다 +1
const ENDLESS_ZONE_HALF: Vector2 = Vector2(960.0, 720.0)   # 플레이어 둘레 1920×1440 구역. 40명이면 큰 방(960×720)에 10명꼴
const ENDLESS_GATHER_SIZE: Vector2 = Vector2(960.0, 720.0)  # 방 전체를 모으는 소품(플레이리스트)이 모으는 범위: 소품 가운데의 큰 방 크기
const ENDLESS_DESPAWN_MARGIN: float = 240.0     # 구역에서 이만큼 더 멀어지고 화면 밖이면 사라진다
const ENDLESS_VIEW_MARGIN: float = 96.0         # 화면 가장자리에서 이만큼 바깥이어야 생기거나 사라진다
const ENDLESS_SPAWN_INTERVAL: float = 0.5       # 사람·소품 수를 맞추는 간격(초)
const ENDLESS_WANDER_RADIUS: float = 360.0      # 사람이 한 번에 걸어가는 최대 거리
const ENDLESS_PROP_COUNT: int = 3               # 구역 안에 늘 있는 (아직 안 쓴) 소품 수
const ENDLESS_AGGRO_OFFSETS: Dictionary = {'speaker': 0.0, 'light': 400.0, 'playlist': 500.0}  # 소품에서 어그로 지점까지 거리(방향 무작위)
const ENDLESS_LIGHT_WINDOW: Vector2 = Vector2(3200.0, 2400.0)  # 바닥 조명 무늬가 반복되는 크기

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
# 답장 문구. 대문자 알파벳과 띄어쓰기만. 문장은 단어마다 글자 풍선이 새로 나온다.
# 레벨의 reply_words(단어 수)와 long_chance(긴 단어가 든 문구를 고를 확률)로 고른다.
# LONG_WORD_LEN 글자 이상인 단어가 하나라도 있으면 "긴" 문구다. 맞는 문구가 없으면 단어 수만 맞춰 고른다.
# 진행 표시가 휴대폰 화면보다 길면 글자 크기를 줄여 맞춘다.
const LONG_WORD_LEN: int = 5
const REPLY_PHRASES: Array = [
    # 한 단어, 짧게
    'LOVE', 'MISS', 'SOON', 'WAIT', 'CALL', 'HUSH', 'KISS', 'BABY', 'HOME', 'LATE', 'HOLD', 'TEXT', 'OKAY', 'STOP',
    # 한 단어, 길게
    'LATER', 'SORRY', 'HONEY', 'SWEET', 'DREAM', 'QUIET', 'HURRY', 'ALONE', 'NIGHT', 'SMILE',
    'SECRET', 'ALWAYS', 'MOMENT', 'LONELY', 'TONIGHT', 'FOREVER', 'DARLING', 'PROMISE',
    # 두 단어, 짧게
    'CALL ME', 'NOT NOW', 'HOLD ON', 'SEE YOU', 'MISS YOU', 'LOVE YOU', 'WAIT HERE', 'BE COOL', 'TOO LATE', 'GO HOME', 'NO WAY', 'SAY HI',
    # 두 단어, 길게
    'CALL LATER', 'MISSING YOU', 'SWEET DREAMS', 'COME OUTSIDE', 'TOO RISKY', 'ALWAYS YOURS', 'BE QUIET', 'TALK LATER',
    # 세 단어, 짧게
    'I MISS YOU', 'SEE YOU SOON', 'WAIT FOR ME', 'LOVE YOU TOO', 'NOT NOW BABY', 'CALL ME SOON', 'CANT TALK NOW', 'SHE IS HERE',
    # 세 단어, 길게
    'CALL ME LATER', 'NOT RIGHT NOW', 'MEET ME OUTSIDE', 'KEEP IT SECRET', 'DELETE THIS CHAT', 'MISS YOU ALREADY', 'I PROMISE YOU',
]
const LETTER_GRID: Vector2i = Vector2i(4, 6)  # 알파벳 버튼을 놓는 칸 (열, 행). 칸 간격은 레벨의 letter_gap
const LETTER_MIN_GAP: float = 6.0             # 어긋나도 버튼 사이에 남기는 최소 간격(px). 서로 붙지 않게
# 휴대폰을 켠 동안 위에 뜨는 여자친구 메시지. 누르면 사라진다.
const GIRLFRIEND_MESSAGES: Array = [
    'Babe, where are you?', "Why can't I find you?", 'Who are you texting?', "I'm coming to find you",
    'Get off your phone', 'My friend just saw you', 'Hello??', 'Answer me.', 'Where are you?', "Why aren't you answering?", 'Where are you right now?',
]
const GIRLFRIEND_FIRST_DELAY: float = 1.5     # 휴대폰을 켠 뒤 첫 메시지까지
const GIRLFRIEND_INTERVAL_RANGE: Vector2 = Vector2(5.0, 10.0)
const GIRLFRIEND_SHOW_SEC: float = 3.0
# 휴대폰에서 연속으로 입력하면 음향 효과가 나오는 글자
const LETTER_COMBOS: Dictionary = {'LLL': 'take_l', 'BAJI': 'baji'}
# 메뉴와 종료 화면
const MENU_NOTIFY_INTERVAL: float = 1.5       # 메인 메뉴에서 알림이 오르는 간격(초). 조작과 상관없음
const MENU_CREDITS_SEC: float = 4.0           # 전원 버튼을 누른 뒤 개발진 정보를 보여 주는 시간
const MENU_PHONE_ZOOM_SEC: float = 0.6        # 휴대폰이 가운데로 와서 커지는 시간
const MENU_MESSAGE_FIRST_DELAY: float = 0.5   # 레벨 선택 화면에서 첫 메시지가 오기 전 비어 있는 시간
const MENU_MESSAGES: Array = ['Where are you?', 'Should I come over?', 'Why no reply?']
const MENU_MESSAGE_MAX: int = 4               # 레벨 선택 화면 메시지 최대 개수. 말풍선 4개까지 들어감
const MENU_MESSAGE_INTERVAL: float = 0.45     # 레벨 선택 화면에 메시지가 하나씩 도착하는 간격
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
