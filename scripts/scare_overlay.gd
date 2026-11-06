class_name ScareOverlay
extends ColorRect
## 히든 엔딩의 공포 효과. 화면이 붉게 번쩍이고, 이미지가 있으면 함께 보여 준다.
## 모양은 scenes/ui/scare_overlay.tscn에서 편집한다.

const FLASH_ALPHA: float = 0.9
const FLASH_SEC: float = 0.12
const FLASH_COUNT: int = 4

@onready var _image: TextureRect = $Image


func _ready() -> void:
    visible = false
    color.a = 0.0
    _image.texture = GameAssets.load_texture(GameAssets.SCARE_IMAGE)
    GameState.circle_scare_started.connect(_on_scare_started)


func _on_scare_started() -> void:
    visible = true
    var tween: Tween = create_tween()
    for _i: int in FLASH_COUNT:
        tween.tween_property(self, 'color:a', FLASH_ALPHA, FLASH_SEC)
        tween.tween_property(self, 'color:a', FLASH_ALPHA * 0.3, FLASH_SEC)
    tween.tween_property(self, 'color:a', FLASH_ALPHA, FLASH_SEC)
