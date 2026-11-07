class_name CharacterSprite
extends AnimatedSprite2D
## 플레이어와 NPC가 함께 쓰는 스프라이트. 위에서 본 아래쪽 방향 그림 한 벌을 이동 방향으로 회전시켜 쓴다.
## 애니메이션은 idle과 walk 두 개이고, 씬의 SpriteFrames에서 편집한다.
## 씬에 SpriteFrames가 없으면(에셋 미완성) 임시 그림으로 대체한다.

const MOVING_SPEED_SQUARED: float = 1.0
const ART_FACING_ANGLE: float = PI * 0.5   # 그림이 바라보는 방향: 아래


func setup(fallback_color: Color, fallback_radius: float) -> void:
    if sprite_frames == null:
        sprite_frames = GameAssets.placeholder_frames(fallback_color, fallback_radius)
    play('idle')


## 지정한 방향을 바로 바라본다.
func face(direction: Vector2) -> void:
    rotation = direction.angle() - ART_FACING_ANGLE


func set_motion(motion: Vector2) -> void:
    var moving: bool = motion.length_squared() > MOVING_SPEED_SQUARED
    if moving:
        var turn: float = GameConfig.CHARACTER_TURN_SPEED * get_physics_process_delta_time()
        rotation = rotate_toward(rotation, motion.angle() - ART_FACING_ANGLE, turn)
        # 걷는 속도에 맞춰 다리를 움직인다.
        speed_scale = motion.length() / GameConfig.CHARACTER_ANIM_BASE_SPEED
    var next: StringName = &'walk' if moving else &'idle'
    if animation != next:
        play(next)
