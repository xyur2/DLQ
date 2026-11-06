class_name GameAssets
extends RefCounted
## 아직 완성되지 않은 에셋의 경로와 불러오기. 파일 목록은 docs/에셋 목록.md 참고.
## 파일이 없으면 임시 그림으로 대체하므로 에셋이 없어도 게임이 실행된다.
## 완성된 에셋(휴대폰, 손, 버블, 로딩 바, DM 아이콘)은 각 씬이 직접 불러온다.

const PARTY_MAP: String = 'res://assets/party_map.png'
const PLAYER_SHEET: String = 'res://assets/player.png'
const NPC_SHEET: String = 'res://assets/npc.png'
const PROP_ICONS: Dictionary = {
    'speaker': 'res://assets/prop_speaker.png',
    'light': 'res://assets/prop_light.png',
    'playlist': 'res://assets/prop_playlist.png',
}
# TODO(확인필요): 효과를 어떤 형식으로 가져올지 정해지면 맞춘다. 지금은 효과 하나를 씬 파일 하나로 받는다.
const PROP_EFFECTS: Dictionary = {
    'light': 'res://assets/light_effect.tscn',
    'playlist': 'res://assets/playlist_effect.tscn',
}

## 캐릭터 시트: 가로는 프레임, 세로는 아래 순서의 애니메이션 (위에서부터)
const CHARACTER_ANIMATIONS: Array[String] = [
    'idle_down', 'idle_up', 'idle_left', 'idle_right',
    'walk_down', 'walk_up', 'walk_left', 'walk_right',
]
const CHARACTER_COLUMNS: int = 4
const CHARACTER_FPS: float = 8.0

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
    return _texture_or(path, _solid.bind(Vector2i(48, 48), fallback_color))


## 소품 효과 씬. 없으면 null.
static func prop_effect(prop_id: String) -> PackedScene:
    var path: String = String(PROP_EFFECTS.get(prop_id, ''))
    if path != '' and ResourceLoader.exists(path):
        return load(path) as PackedScene
    return null


## 캐릭터 시트로 SpriteFrames를 만든다. 시트가 없으면 방향 점이 있는 원으로 대체한다.
static func character_frames(sheet_path: String, fallback_color: Color, fallback_radius: float) -> SpriteFrames:
    if _frames.has(sheet_path):
        return _frames[sheet_path]
    var sheet: Texture2D = load_texture(sheet_path)
    var columns: int = CHARACTER_COLUMNS
    if sheet == null:
        sheet = _placeholder_character(fallback_color, fallback_radius)
        columns = 1
    var frame_size := Vector2(
        float(sheet.get_width()) / float(columns),
        float(sheet.get_height()) / float(CHARACTER_ANIMATIONS.size())
    )
    var frames := SpriteFrames.new()
    frames.remove_animation('default')
    for row: int in CHARACTER_ANIMATIONS.size():
        var animation: String = CHARACTER_ANIMATIONS[row]
        frames.add_animation(animation)
        frames.set_animation_speed(animation, CHARACTER_FPS)
        frames.set_animation_loop(animation, true)
        for column: int in columns:
            var atlas := AtlasTexture.new()
            atlas.atlas = sheet
            atlas.region = Rect2(Vector2(column, row) * frame_size, frame_size)
            frames.add_frame(animation, atlas)
    _frames[sheet_path] = frames
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


## 애니메이션 한 줄에 프레임 하나. 방향은 점 위치로 표시한다.
static func _placeholder_character(color: Color, radius: float) -> Texture2D:
    var directions: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
    var frame: int = PLACEHOLDER_FRAME
    var image := Image.create_empty(frame, frame * CHARACTER_ANIMATIONS.size(), false, Image.FORMAT_RGBA8)
    var center := Vector2(frame, frame) * 0.5
    for row: int in CHARACTER_ANIMATIONS.size():
        var dot: Vector2 = center + directions[row % directions.size()] * radius * 0.7
        for y: int in frame:
            for x: int in frame:
                var point := Vector2(x + 0.5, y + 0.5)
                if point.distance_to(dot) <= PLACEHOLDER_DOT_RADIUS:
                    image.set_pixel(x, y + row * frame, Color.BLACK)
                elif point.distance_to(center) <= radius:
                    image.set_pixel(x, y + row * frame, color)
    return ImageTexture.create_from_image(image)
