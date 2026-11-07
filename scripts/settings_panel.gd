class_name SettingsPanel
extends Control
## 설정 화면 내용. 메뉴의 휴대폰 화면과 일시 정지 화면에서 함께 쓴다.

@onready var _bgm: HSlider = $Rows/BgmSlider
@onready var _sfx: HSlider = $Rows/SfxSlider
@onready var _bgm_label: Label = $Rows/BgmLabel
@onready var _sfx_label: Label = $Rows/SfxLabel


func _ready() -> void:
    _bgm.value = GameSettings.bgm_volume
    _sfx.value = GameSettings.sfx_volume
    _refresh()
    _bgm.value_changed.connect(_on_bgm_changed)
    _sfx.value_changed.connect(_on_sfx_changed)


func _on_bgm_changed(value: float) -> void:
    GameSettings.set_bgm(value)
    _refresh()


func _on_sfx_changed(value: float) -> void:
    GameSettings.set_sfx(value)
    _refresh()


func _refresh() -> void:
    _bgm_label.text = 'BGM  %d%%' % roundi(GameSettings.bgm_volume * 100.0)
    _sfx_label.text = '효과음  %d%%' % roundi(GameSettings.sfx_volume * 100.0)
