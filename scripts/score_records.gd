class_name ScoreRecords
extends RefCounted
## 스테이지마다 최고 점수. user://records.cfg에 저장한다.
## 키: 일반 레벨은 'level_1' ~ 'level_9'(화면 번호), 무한 모드는 'endless'. 테스트 맵은 저장하지 않는다.

const SAVE_PATH: String = 'user://records.cfg'
const SECTION: String = 'best_score'
const ENDLESS_KEY: String = 'endless'

static var _file: ConfigFile = null


static func level_key(level_index: int) -> String:
	return 'level_%d' % (level_index + 1)


static func get_best(key: String) -> int:
	return int(_load().get_value(SECTION, key, 0))


## 최고 점수보다 높으면 저장하고 true를 돌려준다. 0점은 기록하지 않는다.
static func submit(key: String, score: int) -> bool:
	if key == '' or score <= 0 or score <= get_best(key):
		return false
	var file: ConfigFile = _load()
	file.set_value(SECTION, key, score)
	file.save(SAVE_PATH)
	return true


static func _load() -> ConfigFile:
	if _file == null:
		_file = ConfigFile.new()
		_file.load(SAVE_PATH)   # 파일이 없으면 빈 채로 둔다
	return _file
