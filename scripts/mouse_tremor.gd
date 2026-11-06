class_name MouseTremor
extends Node
## 손 떨림: 휴대폰이 켜져 있는 동안 실제 마우스 커서를 노이즈로 흔든다.
## 커서가 흔들린 위치에서 클릭되므로 떨림이 그대로 클릭 난이도가 된다.
## 폭은 GameState.get_tremor_px() (긴장도에 비례).

const MIN_STEP_SQ: float = 0.25   # 0.5px보다 작은 움직임은 무시

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _applied: Vector2 = Vector2.ZERO   # 지금 커서에 더해져 있는 떨림 오프셋


func _ready() -> void:
    _noise.seed = randi()
    _noise.frequency = GameConfig.TREMOR_NOISE_FREQUENCY


func _process(delta: float) -> void:
    var target := Vector2.ZERO
    if GameState.phone_on and GameState.is_playing():
        _time += delta * GameConfig.TREMOR_NOISE_SPEED
        var amount: float = GameState.get_tremor_px() * GameConfig.TREMOR_NOISE_GAIN
        target = Vector2(_noise.get_noise_1d(_time), _noise.get_noise_1d(_time + 1000.0)) * amount
    # 플레이어가 움직인 양은 그대로 두고, 떨림 오프셋의 변화량만 커서에 더한다.
    var step: Vector2 = target - _applied
    if step.length_squared() < MIN_STEP_SQ:
        return
    var viewport: Viewport = get_viewport()
    viewport.warp_mouse(viewport.get_mouse_position() + step)
    _applied = target
