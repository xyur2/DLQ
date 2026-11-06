class_name PartyProp
extends Area2D
## 상호작용 소품(스피커·조명·플레이리스트). E를 누르면 어그로 지점으로 사람을 모은다.
## 종류별 이름·반경·재사용 대기·색은 GameConfig.PROPS, 위치와 어그로 지점은 top_view.tscn에서 정한다.

const LAYER_PROP: int = 8
const PROP_HALF_SIZE: float = 24.0
const ACTIVE_CIRCLE_RADIUS: float = 160.0
const ACTIVE_CIRCLE_MAX_ALPHA: float = 0.25

## 소품 종류 (GameConfig.PROPS의 키)
@export_enum('speaker', 'light', 'playlist') var prop_id: String = 'speaker'
## 사람을 모을 지점. 소품 위치 기준 상대 좌표.
@export var aggro_offset: Vector2 = Vector2.ZERO

var display_name: String = ''
var aggro_radius: float = 0.0
var cooldown_total: float = 0.0
var base_color: Color = Color.WHITE
var _cooldown_left: float = 0.0
var _active_left: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    var spec: Dictionary = GameConfig.PROPS[prop_id]
    display_name = String(spec['name'])
    aggro_radius = float(spec['radius'])
    cooldown_total = float(spec['cooldown'])
    base_color = spec['color']

    collision_layer = LAYER_PROP
    collision_mask = 0
    add_to_group('interactable')
    var circle := CircleShape2D.new()
    circle.radius = PROP_HALF_SIZE
    _shape.shape = circle


## 어그로 지점 (월드 좌표)
func get_aggro_point() -> Vector2:
    return global_position + aggro_offset


func _process(delta: float) -> void:
    if _cooldown_left <= 0.0 and _active_left <= 0.0:
        return
    _cooldown_left = maxf(0.0, _cooldown_left - delta)
    _active_left = maxf(0.0, _active_left - delta)
    queue_redraw()


func get_hint() -> String:
    if _cooldown_left > 0.0:
        return '%s 대기 중 %d초' % [display_name, ceili(_cooldown_left)]
    return '[E] %s' % display_name


func interact(_player: Node) -> void:
    if _cooldown_left > 0.0:
        return
    _cooldown_left = cooldown_total
    _active_left = GameConfig.AGGRO_DURATION
    GameState.emit_aggro(get_aggro_point(), aggro_radius, GameConfig.AGGRO_DURATION)


func _draw() -> void:
    var color: Color = base_color if _cooldown_left <= 0.0 else base_color.darkened(0.6)
    draw_rect(Rect2(-PROP_HALF_SIZE, -PROP_HALF_SIZE, PROP_HALF_SIZE * 2.0, PROP_HALF_SIZE * 2.0), color)
    if _active_left > 0.0:
        var alpha: float = ACTIVE_CIRCLE_MAX_ALPHA * _active_left / GameConfig.AGGRO_DURATION
        draw_circle(aggro_offset, ACTIVE_CIRCLE_RADIUS, Color(base_color, alpha))
