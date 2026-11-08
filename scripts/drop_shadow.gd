class_name DropShadow
extends RefCounted
## 탑뷰 오브젝트와 사람 밑에 까는 부드러운 그림자. 위에서 조명이 내려올 때처럼 물체 바로 밑이 가장 진하고 바깥으로 갈수록 옅어진다.
## - 오브젝트(장애물, 소품): 그림의 외곽선(불투명한 부분) 모양을 흐리게 번지게 만든다. 높이(low, mid, high)에 따라
##   퍼지는 범위·진하기·아래로 밀리는 정도가 달라진다(GameConfig.SHADOW_HEIGHTS). 높을수록 넓고 진하고 많이 밀린다.
## - 사람: 발밑의 둥근 그림자(GameConfig.CHARACTER_SHADOW_*).
## 같은 그림·크기·높이의 그림자는 한 번만 만들어 다시 쓴다.

## 그림자 그림은 흰색(진하기만 담음)으로 만들고 색은 self_modulate로 입힌다. 상호작용 강조 때 이 그림자를 노란 빛으로 바꿔 쓴다.
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.03)
const WORK_SCALE: float = 0.5        # 그림자는 화면 크기의 절반 해상도로 만들고 2배로 늘려 그린다(어차피 흐림)
const BLUR_PASSES: int = 3           # 상자 흐림을 세 번 겹치면 가우시안에 가깝다
const MASK_GAIN: float = 1.5         # 흐리면 물체 밑도 옅어지므로 다시 진하게 끌어올린다

static var _textures: Dictionary = {}


## 그림(Sprite2D) 밑에 그림의 외곽선 모양 그림자를 깐다. height는 GameConfig.SHADOW_HEIGHTS의 키.
static func add_for_sprite(sprite: Sprite2D, height: String) -> Sprite2D:
    var preset: Dictionary = _preset(height)
    var display: Vector2 = Vector2(sprite.texture.get_size()) * sprite.scale.abs()
    var texture: Texture2D = _outline_texture(sprite.texture, display, preset, height)
    if texture == null:
        return add_for_rect(sprite, sprite.position, display * 0.85, height)
    var shadow: Sprite2D = _make(sprite, texture, sprite.position + preset['offset'])
    shadow.scale = Vector2.ONE / WORK_SCALE
    return shadow


## 도형(Polygon2D) 밑에 도형을 감싸는 사각형 그림자를 깐다(그림이 없는 임시 도형용).
static func add_for_polygon(shape: Polygon2D, height: String) -> Sprite2D:
    var box := Rect2(shape.polygon[0], Vector2.ZERO)
    for point: Vector2 in shape.polygon:
        box = box.expand(point)
    return add_for_rect(shape, shape.position + box.get_center(), box.size, height)


## 가운데 size 사각형(모서리는 둥글게) 그림자.
static func add_for_rect(target: Node2D, center: Vector2, size: Vector2, height: String) -> Sprite2D:
    var preset: Dictionary = _preset(height)
    var texture: Texture2D = _rect_texture(Vector2i(roundi(size.x), roundi(size.y)), float(preset['spread']), float(preset['alpha']))
    return _make(target, texture, center + preset['offset'])


## 사람(플레이어, NPC) 발밑에 둥근 그림자를 깐다. 사람 그림(sprite)이 돌아가도 그림자는 그대로다.
static func add_for_character(sprite: Node2D, radius: float) -> Sprite2D:
    var diameter: int = roundi(radius * 2.0 * GameConfig.CHARACTER_SHADOW_SCALE)
    var texture: Texture2D = _rect_texture(Vector2i(diameter, diameter), GameConfig.CHARACTER_SHADOW_SPREAD, GameConfig.CHARACTER_SHADOW_ALPHA)
    return _make(sprite, texture, sprite.position + GameConfig.CHARACTER_SHADOW_OFFSET)


static func _preset(height: String) -> Dictionary:
    return GameConfig.SHADOW_HEIGHTS.get(height, GameConfig.SHADOW_HEIGHTS['low'])


## 그림자를 target 바로 앞 형제로 넣어 target 밑에 그려지게 한다.
static func _make(target: Node, texture: Texture2D, position: Vector2) -> Sprite2D:
    var shadow := Sprite2D.new()
    shadow.name = 'Shadow'
    shadow.texture = texture
    shadow.self_modulate = SHADOW_COLOR
    shadow.position = position
    var parent: Node = target.get_parent()
    parent.add_child(shadow)
    parent.move_child(shadow, target.get_index())
    return shadow


## 그림의 불투명한 부분을 SHADOW_HEIGHTS의 spread만큼 흐리게 번지게 한 그림. 그림을 읽을 수 없으면 null.
static func _outline_texture(source: Texture2D, display: Vector2, preset: Dictionary, height: String) -> Texture2D:
    var key: String = 'outline|%s|%s|%s' % [_source_key(source), Vector2i(display), height]
    if _textures.has(key):
        return _textures[key]
    var image: Image = source.get_image()
    if image == null or image.is_empty():
        return null
    if image.is_compressed():
        image.decompress()
    image.convert(Image.FORMAT_RGBA8)
    var inner := Vector2i(maxi(1, ceili(display.x * WORK_SCALE)), maxi(1, ceili(display.y * WORK_SCALE)))
    image.resize(inner.x, inner.y, Image.INTERPOLATE_BILINEAR)
    var radius: int = maxi(1, roundi(float(preset['spread']) * WORK_SCALE * 0.5))
    var pad: int = radius * BLUR_PASSES + 2
    var width: int = inner.x + pad * 2
    var height_px: int = inner.y + pad * 2
    var mask := PackedFloat32Array()
    mask.resize(width * height_px)
    for y: int in inner.y:
        for x: int in inner.x:
            mask[(y + pad) * width + x + pad] = image.get_pixel(x, y).a
    for i: int in BLUR_PASSES:
        mask = _blur(mask, width, height_px, radius)
    var alpha: float = float(preset['alpha'])
    var out := Image.create(width, height_px, false, Image.FORMAT_RGBA8)
    for y: int in height_px:
        for x: int in width:
            out.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * minf(1.0, mask[y * width + x] * MASK_GAIN)))
    var texture := ImageTexture.create_from_image(out)
    _textures[key] = texture
    return texture


static func _source_key(source: Texture2D) -> String:
    var atlas := source as AtlasTexture
    if atlas != null and atlas.atlas != null:
        return '%s%s' % [atlas.atlas.resource_path, atlas.region]
    return source.resource_path if source.resource_path != '' else str(source.get_instance_id())


## 가로, 세로로 한 번씩 상자 흐림(반경 radius). 바깥은 0으로 본다.
static func _blur(source: PackedFloat32Array, width: int, height: int, radius: int) -> PackedFloat32Array:
    var span: float = float(radius * 2 + 1)
    var row := PackedFloat32Array()
    row.resize(width * height)
    for y: int in height:
        var base: int = y * width
        var sum: float = 0.0
        for x: int in range(0, mini(radius, width - 1) + 1):
            sum += source[base + x]
        for x: int in width:
            row[base + x] = sum / span
            if x + radius + 1 < width:
                sum += source[base + x + radius + 1]
            if x - radius >= 0:
                sum -= source[base + x - radius]
    var result := PackedFloat32Array()
    result.resize(width * height)
    for x: int in width:
        var sum: float = 0.0
        for y: int in range(0, mini(radius, height - 1) + 1):
            sum += row[y * width + x]
        for y: int in height:
            result[y * width + x] = sum / span
            if y + radius + 1 < height:
                sum += row[(y + radius + 1) * width + x]
            if y - radius >= 0:
                sum -= row[(y - radius) * width + x]
    return result


## 가운데 size만큼은 가장 진하고, 바깥 spread px 동안 부드럽게(제곱으로) 옅어지는 사각형 그림.
static func _rect_texture(size: Vector2i, spread_px: float, alpha: float) -> Texture2D:
    var key: String = 'rect|%s|%s|%s' % [size, spread_px, alpha]
    if _textures.has(key):
        return _textures[key]
    var spread: int = maxi(1, roundi(spread_px))
    var width: int = size.x + spread * 2
    var height: int = size.y + spread * 2
    var half: Vector2 = Vector2(size) * 0.5
    # 모서리가 너무 각지지 않도록 안쪽 사각형도 살짝 둥글게 본다.
    var corner: float = minf(minf(half.x, half.y), spread * 0.5)
    var inner: Vector2 = half - Vector2(corner, corner)
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    var center := Vector2(width, height) * 0.5
    for y: int in height:
        for x: int in width:
            var p: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5) - center).abs() - inner
            var outside: float = Vector2(maxf(p.x, 0.0), maxf(p.y, 0.0)).length() - corner
            var t: float = clampf(1.0 - outside / float(spread), 0.0, 1.0) if outside > 0.0 else 1.0
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * t * t))
    var texture := ImageTexture.create_from_image(image)
    _textures[key] = texture
    return texture
