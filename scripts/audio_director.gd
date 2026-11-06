class_name AudioDirector
extends Node

var _music: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _alert_stream: AudioStream
var _vibrate_stream: AudioStream
var _game_over_stream: AudioStream
var _npc_entries: Array[Dictionary] = []
var _was_in_alert: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _music = _make_loop('res://audio/music.ogg')
    _crowd = _make_loop('res://audio/crowd.ogg')
    _heart = _make_loop('res://audio/heartbeat.ogg')
    _sfx = AudioStreamPlayer.new()
    add_child(_sfx)
    _alert_stream = _load_stream('res://audio/alert.ogg', false)
    _vibrate_stream = _load_stream('res://audio/vibrate.ogg', false)
    _game_over_stream = _load_stream('res://audio/game_over.ogg', false)
    GameState.dm_arrived.connect(func(_stage: int) -> void: _play_sfx(_vibrate_stream))
    GameState.game_ended.connect(_on_game_ended)

func attach_npc(npc: PartyNpc) -> void:
    var chatter: AudioStreamPlayer2D = _make_npc_player(npc, 'res://audio/chatter.ogg')
    var footstep: AudioStreamPlayer2D = _make_npc_player(npc, 'res://audio/footstep.ogg')
    _npc_entries.append({'npc': npc, 'footstep': footstep})
    if chatter.stream != null:
        chatter.play()

func _process(_delta: float) -> void:
    var duck: float = GameConfig.MUSIC_PHONE_DUCK_DB if GameState.phone_on else 0.0
    _music.volume_db = GameConfig.MUSIC_VOLUME_DB + duck
    _heart.volume_db = linear_to_db(maxf(GameState.tension, 0.001))
    _heart.pitch_scale = lerpf(1.0, 1.5, GameState.tension)
    var in_alert: bool = GameState.nearest_npc_px < GameConfig.ALERT_RADIUS
    if in_alert and not _was_in_alert:
        _play_sfx(_alert_stream)
    _was_in_alert = in_alert
    for entry: Dictionary in _npc_entries:
        var npc: PartyNpc = entry['npc']
        var footstep: AudioStreamPlayer2D = entry['footstep']
        var walking: bool = npc.is_walking() and GameState.is_playing()
        if footstep.stream != null and walking != footstep.playing:
            if walking:
                footstep.play()
            else:
                footstep.stop()

func _make_loop(path: String) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = _load_stream(path, true)
    add_child(player)
    if player.stream != null:
        player.play()
    return player

func _make_npc_player(npc: PartyNpc, path: String) -> AudioStreamPlayer2D:
    var player := AudioStreamPlayer2D.new()
    player.stream = _load_stream(path, true)
    player.max_distance = GameConfig.NPC_SOUND_MAX_DISTANCE
    npc.add_child(player)
    return player

func _load_stream(path: String, looped: bool) -> AudioStream:
    if not ResourceLoader.exists(path):
        return null
    var stream: AudioStream = load(path)
    if looped and stream is AudioStreamOggVorbis:
        (stream as AudioStreamOggVorbis).loop = true
    return stream

func _play_sfx(stream: AudioStream) -> void:
    if stream != null:
        _sfx.stream = stream
        _sfx.play()

func _on_game_ended(reason: int) -> void:
    _heart.stop()
    if reason != GameState.EndReason.SURVIVED:
        _play_sfx(_game_over_stream)
