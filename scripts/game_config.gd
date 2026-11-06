# res://scripts/game_config.gd
class_name GameConfig
extends RefCounted
## 모든 조정값. 전부 플레이테스트 전 임시값이다.
## A와 B는 각자 표시된 구역의 값만 수정한다.

# ===== A 구역 =====
const MAP_SIZE: Vector2 = Vector2(1920.0, 1440.0)
const WALL_THICKNESS: float = 48.0
const GRID_STEP: float = 48.0
const BACKGROUND_COLOR: Color = Color(0.03, 0.03, 0.04)
const FLOOR_COLOR: Color = Color(0.13, 0.13, 0.15)
const GRID_COLOR: Color = Color(1.0, 1.0, 1.0, 0.04)
const WALL_COLOR: Color = Color(0.07, 0.07, 0.08)

const PLAYER_RADIUS: float = 19.2
const PLAYER_SPEED: float = 144.0
const PLAYER_COLOR: Color = Color(0.85, 0.85, 0.8)
const INTERACT_RANGE: float = 57.6

const NPC_RADIUS: float = 19.2
const NPC_SPEED: float = 86.4          # 플레이 피드백: 조금 더 빠르게 (57.6 → 86.4)
const NPC_AGGRO_SPEED: float = 172.8   # 115.2 → 172.8
const NPC_IDLE_TIME_RANGE: Vector2 = Vector2(1.0, 3.0)
const NPC_MAP_MARGIN: float = 72.0
const NPC_ARRIVE_DISTANCE: float = 9.6
const NPC_STUCK_TIMEOUT: float = 1.5
const NPC_SPAWN_MIN_DIST: float = 480.0
const NPC_AGGRO_SPREAD: float = 140.0
const NPC_COLOR: Color = Color(0.55, 0.5, 0.5)

const AGGRO_DURATION: float = 12.0
const SPEAKER_COOLDOWN: float = 30.0
const LIGHT_COOLDOWN: float = 30.0
const PLAYLIST_COOLDOWN: float = 60.0
const SPEAKER_RADIUS: float = 640.0
const LIGHT_RADIUS: float = 720.0
const PLAYLIST_RADIUS: float = 99999.0

# 소품 종류별 값. 위치와 어그로 지점은 top_view.tscn에서 배치한다.
const PROPS: Dictionary = {
    'speaker': {'name': '스피커', 'radius': SPEAKER_RADIUS, 'cooldown': SPEAKER_COOLDOWN, 'color': Color(0.75, 0.45, 0.25)},
    'light': {'name': '조명', 'radius': LIGHT_RADIUS, 'cooldown': LIGHT_COOLDOWN, 'color': Color(0.85, 0.8, 0.35)},
    'playlist': {'name': '플레이리스트', 'radius': PLAYLIST_RADIUS, 'cooldown': PLAYLIST_COOLDOWN, 'color': Color(0.45, 0.6, 0.85)},
}

const SURVIVE_TIME: float = 180.0
const MAX_DM_STAGE: int = 10
const ALERT_RADIUS: float = 260.0
const TENSION_WEIGHT_PROXIMITY: float = 0.7
const TENSION_WEIGHT_DM: float = 0.3
const TENSION_RISE_PER_SEC: float = 3.0
const TENSION_FALL_PER_SEC: float = 0.5

const LEVELS: Array = [
    {
        'npc_count': 5,
        'dm_interval': 15.0,
        'caught_radius': 80.0,
        'decoy_count': 6,          # 단어 글자 외에 섞이는 알파벳 수
        'wrong_lock_time': 1.0,    # 틀린 알파벳을 눌렀을 때 터치가 막히는 시간(초)
    },
]

# ===== B 구역 =====
const VIEW_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const DM_BADGE_TEXT: Array = ['', '1', '4', '21', '34', '56', '73', '85', '99+', '99+', '99+']
const DM_ICON_SHAKE_PX: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 5.0, 7.0]
# 손 떨림 = 휴대폰 화면(본체·버튼·손 전체) 흔들림.
# 떨림 폭 = TREMOR_MIN_PX + (TREMOR_MAX_PX - TREMOR_MIN_PX) * 긴장도
# 플레이 피드백으로 원래(24 × 긴장도²)보다 세게, 낮은 긴장도에서도 흔들리게 함.
const TREMOR_MIN_PX: float = 4.0
const TREMOR_MAX_PX: float = 32.0
const TREMOR_NOISE_SPEED: float = 120.0
const TREMOR_NOISE_FREQUENCY: float = 0.03
const TREMOR_NOISE_GAIN: float = 1.6          # 노이즈 값(대략 ±0.6)을 ±1 근처로 키움
const PHONE_SIZE: Vector2 = Vector2(640.0, 1000.0)
# 답장 단어. 대문자 알파벳만.
const REPLY_WORDS: Array = ['LOVE', 'MISS', 'SOON', 'WAIT', 'CALL', 'LATER', 'HUSH', 'KISS', 'BABY', 'SORRY']
const LETTER_GRID: Vector2i = Vector2i(5, 6)  # 알파벳 버튼을 놓는 칸 (열, 행)
const LETTER_JITTER: float = 8.0              # 칸 안에서 무작위로 어긋나는 정도(px)
const MUSIC_VOLUME_DB: float = -8.0
const MUSIC_PHONE_DUCK_DB: float = -8.0
const NPC_SOUND_MAX_DISTANCE: float = 700.0

static func random_map_point() -> Vector2:
    return Vector2(
        randf_range(NPC_MAP_MARGIN, MAP_SIZE.x - NPC_MAP_MARGIN),
        randf_range(NPC_MAP_MARGIN, MAP_SIZE.y - NPC_MAP_MARGIN)
    )

## 맵 안쪽(벽에서 NPC_MAP_MARGIN 떨어진 곳)으로 좌표를 제한한다.
static func clamp_to_map(point: Vector2) -> Vector2:
    return Vector2(
        clampf(point.x, NPC_MAP_MARGIN, MAP_SIZE.x - NPC_MAP_MARGIN),
        clampf(point.y, NPC_MAP_MARGIN, MAP_SIZE.y - NPC_MAP_MARGIN)
    )
