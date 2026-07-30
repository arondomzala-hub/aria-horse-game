extends Control

const CHOOSE_SCENE := "res://scenes/choose_horse.tscn"
const LEADERBOARD_SCENE := "res://scenes/leaderboard.tscn"


func _ready() -> void:
	var bg := $Background as TextureRect
	bg.texture = GameState.get_menu_background()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	$StartButton.pressed.connect(_on_start_pressed)
	$LeaderboardButton.pressed.connect(_on_leaderboard_pressed)
	$StartButton.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(CHOOSE_SCENE)


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file(LEADERBOARD_SCENE)
