class_name GameAssets
extends RefCounted
## 코드에서 불러오는 에셋(맵, 소품, 효과, 공포 이미지)의 경로. 파일 목록은 docs/에셋 목록.md 참고.
## 파일이 없으면 임시 그림으로 대체하므로 에셋이 없어도 게임이 실행된다.
## 휴대폰, 손, 버블, 로딩 바, DM 아이콘, 시계, 주인공은 각 씬이 직접 불러온다.

const PARTY_MAP: String = 'res://assets/party_map.webp'
const SCARE_IMAGE: String = 'res://assets/scare.png'
const PROP_ICONS: Dictionary = {
    'speaker': 'res://assets/prop_speaker.png',
    'light': 'res://assets/prop_light.webp',
    'playlist': 'res://assets/prop_playlist.webp',
}
## 캔버스의 빈 공간을 뺀 그림 영역. 없으면 이미지 전체를 쓴다.
const PROP_ICON_REGIONS: Dictionary = {
    'light': Rect2(436, 263, 1203, 1374),
    'playlist': Rect2(111, 520, 1784, 847),
}
# TODO(확인필요): 효과를 어떤 형식으로 가져올지 정해지면 맞춘다. 지금은 효과 하나를 씬 파일 하나로 받는다.
const PROP_EFFECTS: Dictionary = {
    'light': 'res://assets/light_effect.tscn',
    'playlist': 'res://assets/playlist_effect.tscn',
}

const PLACEHOLDER_FRAME: int = 64
const PLACEHOLDER_DOT_RADIUS: float = 4.0

static var _textures: Dictionary = {}
static var _frames: Dictionary = {}


## 파일이 있으면 텍스처를, 없으면 null을 돌려준다.
static func load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        return load(path) as Texture2D
    return null


static func prop_icon(prop_id: String, fallback_color: Color) -> Texture2D:
    var path: String = String(PROP_ICONS[prop_id])
    var texture: Texture2D = _texture_or(path, _solid.bind(Vector2i(48, 48), fallback_color))
    if not PROP_ICON_REGIONS.has(prop_id) or not ResourceLoader.exists(path):
        return texture
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    atlas.region = PROP_ICON_REGIONS[prop_id]
    return atlas


## 소품 효과 씬. 없으면 null.
static func prop_effect(prop_id: String) -> PackedScene:
    var path: String = String(PROP_EFFECTS.get(prop_id, ''))
    if path != '' and ResourceLoader.exists(path):
        return load(path) as PackedScene
    return null


## 캐릭터 에셋이 없을 때 쓰는 임시 SpriteFrames. 아래쪽에 방향 점이 있는 원.
static func placeholder_frames(color: Color, radius: float) -> SpriteFrames:
    if _frames.has(color):
        return _frames[color]
    var texture: Texture2D = _placeholder_character(color, radius)
    var frames := SpriteFrames.new()
    frames.remove_animation('default')
    for animation: String in ['idle', 'walk']:
        frames.add_animation(animation)
        frames.add_frame(animation, texture)
    _frames[color] = frames
    return frames


static func _texture_or(path: String, make_placeholder: Callable) -> Texture2D:
    if _textures.has(path):
        return _textures[path]
    var texture: Texture2D = load_texture(path)
    if texture == null:
        texture = make_placeholder.call()
    _textures[path] = texture
    return texture


static func _rects(size: Vector2i, rects: Array) -> Texture2D:
    var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
    for entry: Array in rects:
        image.fill_rect(entry[0], entry[1])
    return ImageTexture.create_from_image(image)


static func _solid(size: Vector2i, color: Color) -> Texture2D:
    return _rects(size, [[Rect2i(Vector2i.ZERO, size), color]])


static func _placeholder_character(color: Color, radius: float) -> Texture2D:
    var frame: int = PLACEHOLDER_FRAME
    var image := Image.create_empty(frame, frame, false, Image.FORMAT_RGBA8)
    var center := Vector2(frame, frame) * 0.5
    var dot: Vector2 = center + Vector2.DOWN * radius * 0.7
    for y: int in frame:
        for x: int in frame:
            var point := Vector2(x + 0.5, y + 0.5)
            if point.distance_to(dot) <= PLACEHOLDER_DOT_RADIUS:
                image.set_pixel(x, y, Color.BLACK)
            elif point.distance_to(center) <= radius:
                image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
