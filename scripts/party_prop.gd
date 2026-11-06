class_name PartyProp
extends Area2D
## 상호작용 소품(스피커·조명·플레이리스트). E를 누르면 어그로 지점으로 사람을 모은다.
## 종류별 이름·반경·재사용 대기·색은 GameConfig.PROPS, 위치와 어그로 지점은 top_view.tscn에서 정한다.
## 모양은 소품 이미지, 작동 효과는 효과 씬(GameAssets.PROP_EFFECTS). 효과 씬이 없으면 원으로 대신 표시한다.

const LAYER_PROP: int = 8
const PROP_HALF_SIZE: float = 24.0
const ACTIVE_CIRCLE_RADIUS: float = 160.0
const ACTIVE_CIRCLE_MAX_ALPHA: float = 0.25
const COOLDOWN_TINT: Color = Color(0.4, 0.4, 0.4)

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
var _effect: Node = null

@onready var _icon: Sprite2D = $Icon
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    var spec: Dictionary = GameConfig.PROPS[prop_id]
    display_name = String(spec['name'])
    aggro_radius = float(spec['radius'])
    cooldown_total = float(spec['cooldown'])
    base_color = spec['color']
    _icon.texture = GameAssets.prop_icon(prop_id, base_color)
    # 이미지 해상도와 상관없이 판정 크기에 맞춰 보여 준다.
    _icon.scale = Vector2.ONE * PROP_HALF_SIZE * 2.0 / maxf(_icon.texture.get_width(), _icon.texture.get_height())

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
    _icon.modulate = COOLDOWN_TINT if _cooldown_left > 0.0 else Color.WHITE
    if _active_left <= 0.0:
        _remove_effect()
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
    _icon.modulate = COOLDOWN_TINT
    _spawn_effect()
    GameState.emit_aggro(get_aggro_point(), aggro_radius, GameConfig.AGGRO_DURATION)


## 효과 씬은 어그로 지점에 놓이고, 재생은 씬이 스스로 한다(자동 재생 또는 emitting 켜기).
func _spawn_effect() -> void:
    var scene: PackedScene = GameAssets.prop_effect(prop_id)
    if scene == null:
        return
    _effect = scene.instantiate()
    add_child(_effect)
    if _effect is Node2D:
        (_effect as Node2D).position = aggro_offset


func _remove_effect() -> void:
    if _effect != null:
        _effect.queue_free()
        _effect = null


func _draw() -> void:
    if _active_left > 0.0 and _effect == null:
        var alpha: float = ACTIVE_CIRCLE_MAX_ALPHA * _active_left / GameConfig.AGGRO_DURATION
        draw_circle(aggro_offset, ACTIVE_CIRCLE_RADIUS, Color(base_color, alpha))
