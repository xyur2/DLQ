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
const NPC_SPEED: float = 57.6
const NPC_AGGRO_SPEED: float = 115.2
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
        'bubble_count': 4,
        'reply_time': 10.0,
        'miss_penalty': 0.5,
    },
]

# ===== B 구역 =====
const VIEW_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const DM_BADGE_TEXT: Array = ['', '1', '4', '21', '34', '56', '73', '85', '99+', '99+', '99+']
const DM_ICON_SHAKE_PX: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 5.0, 7.0]
const TREMOR_MAX_PX: float = 24.0
const TREMOR_NOISE_SPEED: float = 120.0
const PHONE_SIZE: Vector2 = Vector2(640.0, 1000.0)
const PHONE_SCREEN_MARGIN: float = 30.0
const BUBBLE_SIZE: Vector2 = Vector2(268.0, 110.0)
const REPLY_MESSAGES: Array = [
    '지금은 곤란해',
    '조금만 기다려 줘',
    '나도 보고 싶어',
    '나중에 연락할게',
    '오늘은 어려울 것 같아',
    '아무한테도 말하지 마',
    '사람들이 옆에 있어',
    '금방 답장할게',
    '걱정하지 마',
    '내일 꼭 보자',
    '전화는 안 돼',
    '이따 다시 얘기해',
]
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
