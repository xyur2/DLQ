class_name GameSettings
extends RefCounted
## BGM과 효과음 크기, How to Play 언어. 소리는 오디오 버스로 적용하고 모두 user://settings.cfg에 저장한다.

const BUS_BGM: StringName = &'BGM'
const BUS_SFX: StringName = &'SFX'
const SAVE_PATH: String = 'user://settings.cfg'
const SECTION: String = 'audio'

static var bgm_volume: float = 1.0
static var sfx_volume: float = 1.0
## How to Play 설명 언어. 'ko' 또는 'en'
static var how_to_language: String = 'ko'


## 게임을 시작할 때 한 번 호출한다.
static func load_and_apply() -> void:
    _ensure_bus(BUS_BGM)
    _ensure_bus(BUS_SFX)
    var file := ConfigFile.new()
    if file.load(SAVE_PATH) == OK:
        bgm_volume = clampf(float(file.get_value(SECTION, 'bgm', 1.0)), 0.0, 1.0)
        sfx_volume = clampf(float(file.get_value(SECTION, 'sfx', 1.0)), 0.0, 1.0)
        how_to_language = 'en' if String(file.get_value('ui', 'how_to_language', 'ko')) == 'en' else 'ko'
    _apply(BUS_BGM, bgm_volume)
    _apply(BUS_SFX, sfx_volume)


static func set_bgm(value: float) -> void:
    bgm_volume = clampf(value, 0.0, 1.0)
    _apply(BUS_BGM, bgm_volume)
    _save()


static func set_sfx(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    _apply(BUS_SFX, sfx_volume)
    _save()


static func set_how_to_language(language: String) -> void:
    how_to_language = language
    _save()


static func _ensure_bus(bus: StringName) -> void:
    if AudioServer.get_bus_index(bus) >= 0:
        return
    AudioServer.add_bus()
    AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)


static func _apply(bus: StringName, value: float) -> void:
    var index: int = AudioServer.get_bus_index(bus)
    AudioServer.set_bus_mute(index, value <= 0.0)
    AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


static func _save() -> void:
    var file := ConfigFile.new()
    file.set_value(SECTION, 'bgm', bgm_volume)
    file.set_value(SECTION, 'sfx', sfx_volume)
    file.set_value('ui', 'how_to_language', how_to_language)
    file.save(SAVE_PATH)
