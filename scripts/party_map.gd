class_name PartyMap
extends Node2D
## 벽으로 둘러싸인 사각형 맵. 내부 장애물은 0레벨에서 쓰지 않는다.

const WALL_LAYER: int = 1

@onready var _background: Sprite2D = $Background


func _ready() -> void:
    _background.texture = GameAssets.load_texture(GameAssets.PARTY_MAP)
    var w: float = GameConfig.MAP_SIZE.x
    var h: float = GameConfig.MAP_SIZE.y
    var t: float = GameConfig.WALL_THICKNESS
    _add_wall(Rect2(-t, -t, w + t * 2.0, t))   # 위
    _add_wall(Rect2(-t, h, w + t * 2.0, t))    # 아래
    _add_wall(Rect2(-t, 0.0, t, h))            # 왼쪽
    _add_wall(Rect2(w, 0.0, t, h))             # 오른쪽


func _add_wall(rect: Rect2) -> void:
    var body := StaticBody2D.new()
    body.collision_layer = WALL_LAYER
    body.collision_mask = 0
    body.position = rect.get_center()
    var shape := CollisionShape2D.new()
    var box := RectangleShape2D.new()
    box.size = rect.size
    shape.shape = box
    body.add_child(shape)
    add_child(body)


## 배경 이미지가 없을 때만 그리는 임시 바닥과 벽.
func _draw() -> void:
    if _background.texture != null:
        return
    var size: Vector2 = GameConfig.MAP_SIZE
    var t: float = GameConfig.WALL_THICKNESS
    draw_rect(Rect2(Vector2(-t, -t), size + Vector2(t, t) * 2.0), GameConfig.WALL_COLOR)
    draw_rect(Rect2(Vector2.ZERO, size), GameConfig.FLOOR_COLOR)
    # 격자: 카메라가 플레이어를 따라가므로 이동감을 준다.
    var x: float = 0.0
    while x <= size.x:
        draw_line(Vector2(x, 0.0), Vector2(x, size.y), GameConfig.GRID_COLOR)
        x += GameConfig.GRID_STEP
    var y: float = 0.0
    while y <= size.y:
        draw_line(Vector2(0.0, y), Vector2(size.x, y), GameConfig.GRID_COLOR)
        y += GameConfig.GRID_STEP
