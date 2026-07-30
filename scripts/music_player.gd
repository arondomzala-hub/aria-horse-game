extends Node

## Globalny odtwarzacz muzyki. Jako autoload przeżywa zmiany scen,
## więc muzyka gra od wyboru konia aż do zamknięcia gry.

const MUSIC_PATH := "res://assets/audio/gallop_beat_loop.wav"

var _player: AudioStreamPlayer


func _ready() -> void:
	# Muzyka ma grać także przy ewentualnej pauzie gry.
	process_mode = Node.PROCESS_MODE_ALWAYS


func start() -> void:
	if _player != null and _player.playing:
		return
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.stream = _load_stream()
		_player.volume_db = -6.0
		add_child(_player)
	_player.play()


func _load_stream() -> AudioStream:
	var res := ResourceLoader.load(MUSIC_PATH)
	if res is AudioStream:
		return _ensure_loop(res)

	# Fallback: wczytaj WAV bezpośrednio z dysku (jak tekstury w GameState).
	var abs_path := ProjectSettings.globalize_path(MUSIC_PATH)
	var stream := AudioStreamWAV.load_from_file(abs_path)
	if stream == null:
		push_error("Nie udało się wczytać muzyki: %s" % MUSIC_PATH)
		return AudioStreamWAV.new()
	return _ensure_loop(stream)


## Plik ma wpisaną pętlę (chunk smpl), ale na wszelki wypadek wymuś Loop Forward.
func _ensure_loop(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			# 16-bit mono: 2 bajty na próbkę.
			wav.loop_end = wav.data.size() / 2
	return stream
