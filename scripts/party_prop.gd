class_name PartyProp
extends Area2D
## 상호작용 소품(스피커·조명·플레이리스트). E를 누르면 어그로 지점으로 사람을 모은다.
## 종류별 이름·반경·재사용 대기·색은 GameConfig.PROPS, 위치와 어그로 지점은 레벨 씬에서 정한다.
## whole_room 소품(플레이리스트)은 반경 대신 소품이 있는 방 전체의 사람을 모은다(PartyLevel.gather_area).
## 조명(light)은 어그로 지점에 춤추는 자리(DanceSpot)를 만든다.
## 모양은 소품 이미지, 작동 효과는 효과 씬(GameAssets.PROP_EFFECTS). 효과 씬이 없으면 원으로 대신 표시한다.
## 재사용 대기 중에는 소품이 어두워지고, 그림 아래에 줄어드는 막대와 남은 초가 나온다.
## 막대와 남은 초는 prop.tscn에서 z_index 10이라 소품으로 모인 사람에게 가려지지 않는다.

const LAYER_PROP: int = 8
const BODY_RATIO: float = 0.85            # 충돌 크기 = 그림 크기 × 이 비율
const BAR_SIZE: Vector2 = Vector2(72.0, 7.0)
const BAR_GAP: float = 6.0
const BAR_BACK_COLOR: Color = Color(0.05, 0.03, 0.14, 0.85)
const BAR_FILL_COLOR: Color = Color(0.4, 0.9, 1.0)
const ACTIVE_CIRCLE_RADIUS: float = 160.0
const ACTIVE_CIRCLE_MAX_ALPHA: float = 0.25
const COOLDOWN_TINT: Color = Color(0.25, 0.25, 0.3)   # 재사용 대기 중 소품 색

## 소품 종류 (GameConfig.PROPS의 키)
@export_enum('speaker', 'light', 'playlist') var prop_id: String = 'speaker'
## 사람을 모을 지점. 소품 위치 기준 상대 좌표.
@export var aggro_offset: Vector2 = Vector2.ZERO
## 이 소품만 효과 반경을 바꿀 때 쓴다. 0이면 GameConfig.PROPS의 값.
@export var radius_override: float = 0.0
## 무한 모드: 한 번 쓰면 재사용 대기 대신 사라진다. 어그로 효과가 끝나면 노드도 지운다.
@export var single_use: bool = false

## 한 번 쓰고 사라졌는지 (single_use일 때)
var used_up: bool = false

var display_name: String = ''
var whole_room: bool = false
var aggro_radius: float = 0.0
var cooldown_total: float = 0.0
var base_color: Color = Color.WHITE
var _cooldown_left: float = 0.0
var _active_left: float = 0.0
var _effect: Node = null
var _icon_size: Vector2 = Vector2.ZERO

@onready var _icon: Sprite2D = $Icon
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _body_shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _bar: Node2D = $CooldownBar
@onready var _cooldown_label: Label = $CooldownLabel


func _ready() -> void:
    var spec: Dictionary = GameConfig.PROPS[prop_id]
    display_name = String(spec['name'])
    aggro_radius = radius_override if radius_override > 0.0 else float(spec['radius'])
    whole_room = bool(spec.get('whole_room', false))
    if prop_id == 'light':
        var spot := DanceSpot.new()
        spot.name = 'DanceSpot'
        spot.position = aggro_offset
        add_child(spot)
    cooldown_total = float(spec['cooldown'])
    base_color = spec['color']
    _icon.texture = GameAssets.prop_icon(prop_id, base_color)
    # 이미지 해상도와 상관없이 같은 크기로 보여 준다.
    _icon.scale = Vector2.ONE * float(spec['icon_size']) / maxf(_icon.texture.get_width(), _icon.texture.get_height())

    collision_layer = LAYER_PROP
    collision_mask = 0
    add_to_group('interactable')
    # 그림 크기에 맞춘 판정: 상호작용 범위와 몸체 충돌
    _icon_size = Vector2(_icon.texture.get_size()) * _icon.scale
    var area_box := RectangleShape2D.new()
    area_box.size = _icon_size
    _shape.shape = area_box
    var body_box := RectangleShape2D.new()
    body_box.size = _icon_size * BODY_RATIO
    _body_shape.shape = body_box
    # 재사용 대기 표시는 그림 바로 아래
    _bar.position = Vector2(0.0, _icon_size.y * 0.5 + BAR_GAP)
    _bar.draw.connect(_draw_bar)
    _cooldown_label.position = Vector2(-_cooldown_label.size.x * 0.5, _bar.position.y + BAR_SIZE.y + 1.0)


## 몸체 충돌 영역 (월드 좌표)
func get_body_rect() -> Rect2:
    var size_value: Vector2 = _icon_size * BODY_RATIO
    return Rect2(global_position - size_value * 0.5, size_value)


## 중심에서 몸체 가장자리까지의 가장 먼 거리
func get_body_radius() -> float:
    return maxf(_icon_size.x, _icon_size.y) * BODY_RATIO * 0.5


## 어그로 지점 (월드 좌표)
func get_aggro_point() -> Vector2:
    return global_position + aggro_offset


func _process(delta: float) -> void:
    if used_up:
        _active_left = maxf(0.0, _active_left - delta)
        queue_redraw()
        if _active_left <= 0.0:
            _remove_effect()
            queue_free()
        return
    if _cooldown_left <= 0.0 and _active_left <= 0.0:
        return
    _cooldown_left = maxf(0.0, _cooldown_left - delta)
    _active_left = maxf(0.0, _active_left - delta)
    _icon.modulate = COOLDOWN_TINT if _cooldown_left > 0.0 else Color.WHITE
    _update_cooldown_display()
    if _active_left <= 0.0:
        _remove_effect()
    queue_redraw()


## 재사용 대기 중이 아니면 true (상호작용형 사람이 쓸 소품을 고를 때)
func is_ready() -> bool:
    return _cooldown_left <= 0.0 and not used_up


func get_hint() -> String:
    if _cooldown_left > 0.0:
        return '%s: wait %ds' % [display_name, ceili(_cooldown_left)]
    return '[E] %s' % display_name


func interact(_player: Node) -> void:
    if _cooldown_left > 0.0 or used_up:
        return
    _active_left = GameConfig.AGGRO_DURATION
    if single_use:
        _use_up()
    else:
        _cooldown_left = cooldown_total
        _icon.modulate = COOLDOWN_TINT
        _update_cooldown_display()
    _spawn_effect()
    GameState.emit_aggro(get_aggro_point(), aggro_radius, GameConfig.AGGRO_DURATION, _gather_area())
    if _player is PartyPlayer:
        var gathered: int = 0
        for npc: Node in get_tree().get_nodes_in_group('npcs'):
            if (npc as PartyNpc)._mode == PartyNpc.Mode.AGGRO:
                gathered += 1
        Achievements.event('prop_used', {'id': prop_id, 'gathered': gathered})


## whole_room이면 소품이 있는 방(무한 모드는 소품 둘레 큰 방 크기), 아니면 빈 영역(반경만 씀)
func _gather_area() -> Rect2:
    if not whole_room:
        return Rect2()
    var node: Node = get_parent()
    while node != null and not node is PartyLevel:
        node = node.get_parent()
    return (node as PartyLevel).gather_area(global_position) if node != null else Rect2()


## 한 번 쓴 소품: 그림과 판정을 없애고, 어그로 효과만 끝날 때까지 남긴다.
func _use_up() -> void:
    used_up = true
    remove_from_group('interactable')
    _icon.visible = false
    _shape.set_deferred('disabled', true)
    _body_shape.set_deferred('disabled', true)


func _update_cooldown_display() -> void:
    var waiting: bool = _cooldown_left > 0.0
    _bar.visible = waiting
    _cooldown_label.visible = waiting
    if waiting:
        _cooldown_label.text = '%ds' % ceili(_cooldown_left)
        _bar.queue_redraw()


func _draw_bar() -> void:
    var box := Rect2(-BAR_SIZE.x * 0.5, 0.0, BAR_SIZE.x, BAR_SIZE.y)
    _bar.draw_rect(box, BAR_BACK_COLOR)
    var filled: Rect2 = box
    filled.size.x *= _cooldown_left / cooldown_total
    _bar.draw_rect(filled, BAR_FILL_COLOR)


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
