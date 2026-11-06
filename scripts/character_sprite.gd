class_name CharacterSprite
extends AnimatedSprite2D
## 플레이어와 NPC가 함께 쓰는 스프라이트. 이동 방향에 맞춰 대기·걷기 애니메이션을 고른다.
## 애니메이션 이름은 GameAssets.CHARACTER_ANIMATIONS와 같다.

const MOVING_SPEED_SQUARED: float = 1.0

var _direction: String = 'down'


func setup(sheet_path: String, fallback_color: Color, fallback_radius: float) -> void:
    sprite_frames = GameAssets.character_frames(sheet_path, fallback_color, fallback_radius)
    play('idle_down')


func set_motion(motion: Vector2) -> void:
    var moving: bool = motion.length_squared() > MOVING_SPEED_SQUARED
    if moving:
        if absf(motion.x) > absf(motion.y):
            _direction = 'right' if motion.x > 0.0 else 'left'
        else:
            _direction = 'down' if motion.y > 0.0 else 'up'
    var next: String = ('walk_' if moving else 'idle_') + _direction
    if animation != next:
        play(next)
