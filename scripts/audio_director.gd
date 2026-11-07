class_name AudioDirector
extends Node

const SILENT_DB: float = -80.0
# 같은 이름의 파일이 여럿이면 앞쪽 형식을 쓴다. 효과음은 짧은 mp3를 wav보다 먼저 고른다.
const AUDIO_EXTENSIONS: Array[String] = ['ogg', 'mp3', 'wav']

var _music: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _music_slow: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _alert_stream: AudioStream
var _vibrate_stream: AudioStream
var _game_over_stream: AudioStream
var _send_stream: AudioStream
var _sfx_players: Dictionary = {}   # 소리마다 플레이어를 따로 둬서 서로 끊지 않는다. {AudioStream: AudioStreamPlayer}
var _horror_stream: AudioStream
var _knockback_stream: AudioStream
var _reaction_streams: Dictionary = {}
var _easter_streams: Dictionary = {}
var _npc_entries: Array[Dictionary] = []
var _was_in_alert: bool = false
var _easter_music: bool = false   # LLL·BAJI로 배경 음악이 바뀌었는지

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _music = _make_loop('music')
    _crowd = _make_loop('crowd')
    _heart = _make_loop('heartbeat')
    _music_slow = AudioStreamPlayer.new()
    _music_slow.stream = _load_stream('music_slow', true)
    add_child(_music_slow)
    _voice = AudioStreamPlayer.new()
    add_child(_voice)
    _music.bus = GameSettings.BUS_BGM
    _music_slow.bus = GameSettings.BUS_BGM
    for player: AudioStreamPlayer in [_crowd, _heart, _voice]:
        player.bus = GameSettings.BUS_SFX
    _alert_stream = _load_stream('alert', false)
    _vibrate_stream = _load_stream('vibrate', false)
    _game_over_stream = _load_stream('game_over', false)
    _send_stream = _load_stream('send', false)
    _horror_stream = _load_stream('horror', false)
    _knockback_stream = _load_stream('knockback', false)
    _reaction_streams = {
        true: _load_stream('reaction_positive', false),
        false: _load_stream('reaction_negative', false),
    }
    _easter_streams = {
        'take_l': _load_stream('take_l', false),
        'baji': _load_stream('baji', false),
    }
    GameState.dm_arrived.connect(func(_stage: int) -> void: _play_sfx(_vibrate_stream, GameConfig.VIBRATE_CLIP_SEC))
    GameState.reply_resolved.connect(_on_reply_resolved)
    GameState.game_ended.connect(_on_game_ended)
    GameState.slow_dance_changed.connect(_on_slow_dance_changed)
    GameState.reaction_sent.connect(func(positive: bool) -> void: _play_sfx(_reaction_streams[positive]))
    GameState.player_knocked_back.connect(func(_from: Vector2) -> void: _play_sfx(_knockback_stream))
    GameState.easter_egg.connect(_on_easter_egg)
    GameState.circle_scare_started.connect(func() -> void: _play_voice(_horror_stream))

func attach_npc(npc: PartyNpc) -> void:
    var chatter: AudioStreamPlayer2D = _make_npc_player(npc, 'chatter')
    var footstep: AudioStreamPlayer2D = _make_npc_player(npc, 'footstep')
    footstep.volume_db = GameConfig.FOOTSTEP_VOLUME_DB
    footstep.attenuation = GameConfig.FOOTSTEP_ATTENUATION
    _npc_entries.append({'npc': npc, 'footstep': footstep})
    if chatter.stream != null:
        chatter.play()

func _process(_delta: float) -> void:
    var duck: float = GameConfig.MUSIC_PHONE_DUCK_DB if GameState.phone_on else 0.0
    var music_db: float = GameConfig.MUSIC_VOLUME_DB + duck
    _music_slow.volume_db = music_db + GameConfig.SLOW_MUSIC_BOOST_DB
    _crowd.volume_db = GameConfig.CROWD_VOLUME_DB + (GameConfig.SLOW_CROWD_DUCK_DB if _music_slow.playing else 0.0)
    # 슬로우 댄스 음악이 재생 중이면 기본 음악을 잠시 끈다. 파일이 없으면 기본 음악을 유지한다.
    var main_db: float = GameConfig.EASTER_MUSIC_VOLUME_DB + duck if _easter_music else music_db
    _music.volume_db = SILENT_DB if _music_slow.playing else main_db
    # 휴대폰 화면에서만 들린다. 사람이 가까울수록(근접도) 또는 긴장이 높을수록 크고 빠르게 뛴다.
    var heart: float = maxf(GameState.tremor_closeness, GameState.tension) if GameState.phone_on else 0.0
    _heart.volume_db = SILENT_DB if heart <= 0.01 else lerpf(GameConfig.HEART_VOLUME_DB_RANGE.x, GameConfig.HEART_VOLUME_DB_RANGE.y, heart)
    _heart.pitch_scale = lerpf(GameConfig.HEART_PITCH_RANGE.x, GameConfig.HEART_PITCH_RANGE.y, heart)
    var in_alert: bool = GameState.nearest_npc_px < GameConfig.ALERT_RADIUS
    if in_alert and not _was_in_alert:
        _play_sfx(_alert_stream)
    elif _was_in_alert and not in_alert:
        _stop_sfx(_alert_stream)
    _was_in_alert = in_alert
    for i: int in range(_npc_entries.size() - 1, -1, -1):
        var entry: Dictionary = _npc_entries[i]
        # 무한 모드에서는 사람이 사라지므로 지워진 사람은 목록에서 뺀다.
        if not is_instance_valid(entry['npc']):
            _npc_entries.remove_at(i)
            continue
        var npc: PartyNpc = entry['npc']
        var footstep: AudioStreamPlayer2D = entry['footstep']
        var walking: bool = npc.is_walking() and GameState.is_playing()
        if footstep.stream != null and walking != footstep.playing:
            if walking:
                footstep.play()
            else:
                footstep.stop()

func _make_loop(sound: String) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = _load_stream(sound, true)
    add_child(player)
    if player.stream != null:
        player.play()
    return player

func _make_npc_player(npc: PartyNpc, sound: String) -> AudioStreamPlayer2D:
    var player := AudioStreamPlayer2D.new()
    player.stream = _load_stream(sound, true)
    player.max_distance = GameConfig.NPC_SOUND_MAX_DISTANCE
    player.bus = GameSettings.BUS_SFX
    npc.add_child(player)
    return player

func _load_stream(sound: String, looped: bool) -> AudioStream:
    return load_sound(sound, looped)


## audio 폴더에서 이름이 sound인 파일을 형식과 상관없이 찾는다. 없으면 null. 메뉴에서도 쓴다.
static func load_sound(sound: String, looped: bool = false) -> AudioStream:
    for extension: String in AUDIO_EXTENSIONS:
        var path: String = 'res://audio/%s.%s' % [sound, extension]
        if ResourceLoader.exists(path):
            var stream: AudioStream = load(path)
            if looped:
                _set_looping(stream)
            return stream
    return null


## clip_sec가 0보다 크면 그 시간만 재생하고 멈춘다. 그사이 다시 재생하면 새 재생 기준으로 센다.
static func play_clip(player: AudioStreamPlayer, clip_sec: float) -> void:
    if player.stream == null:
        return
    player.play()
    if clip_sec <= 0.0:
        return
    var serial: int = int(player.get_meta('clip_serial', 0)) + 1
    player.set_meta('clip_serial', serial)
    player.get_tree().create_timer(clip_sec, true, false, true).timeout.connect(func() -> void:
        if is_instance_valid(player) and int(player.get_meta('clip_serial', 0)) == serial:
            player.stop()
    )


static func _set_looping(stream: AudioStream) -> void:
    if stream is AudioStreamOggVorbis:
        (stream as AudioStreamOggVorbis).loop = true
    elif stream is AudioStreamMP3:
        (stream as AudioStreamMP3).loop = true
    elif stream is AudioStreamWAV:
        var wav: AudioStreamWAV = stream
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
        wav.loop_begin = 0
        wav.loop_end = roundi(wav.get_length() * float(wav.mix_rate))

func _play_sfx(stream: AudioStream, clip_sec: float = 0.0) -> void:
    if stream == null:
        return
    if not _sfx_players.has(stream):
        var player := AudioStreamPlayer.new()
        player.stream = stream
        player.bus = GameSettings.BUS_SFX
        add_child(player)
        _sfx_players[stream] = player
    play_clip(_sfx_players[stream], clip_sec)


func _stop_sfx(stream: AudioStream) -> void:
    if _sfx_players.has(stream):
        (_sfx_players[stream] as AudioStreamPlayer).stop()


## LLL, BAJI를 입력하면 이 판(레벨)이 끝날 때까지 배경 음악이 그 소리로 바뀐다. 다음 판은 원래 음악.
func _on_easter_egg(id: String) -> void:
    var stream: AudioStream = _easter_streams.get(id)
    if stream == null:
        return
    # 다시 입력하면 처음부터 다시 나온다.
    _set_looping(stream)
    _music.stream = stream
    _music.play()
    _easter_music = true


func _on_reply_resolved(success: bool) -> void:
    if success:
        _play_sfx(_send_stream, GameConfig.SEND_CLIP_SEC)

func _play_voice(stream: AudioStream) -> void:
    if stream != null:
        _voice.stream = stream
        _voice.play()

func _on_slow_dance_changed(active: bool) -> void:
    if active and _music_slow.stream != null:
        _music_slow.play()
    elif not active:
        _music_slow.stop()

func _on_game_ended(reason: int) -> void:
    _heart.stop()
    _stop_sfx(_alert_stream)
    _stop_sfx(_vibrate_stream)
    if reason != GameState.EndReason.SURVIVED and reason != GameState.EndReason.HIDDEN:
        _play_sfx(_game_over_stream)
