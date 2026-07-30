extends Control

## Ekran najlepszych wyników: poziom malejąco, potem gwiazdki malejąco.

const MENU_SCENE := "res://scenes/main_menu.tscn"


func _ready() -> void:
	var bg := $Background as TextureRect
	bg.texture = GameState.get_menu_background()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	$Panel/VBox/BackButton.pressed.connect(_on_back_pressed)
	$Panel/VBox/BackButton.grab_focus()
	_fill_scores()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _fill_scores() -> void:
	var box: VBoxContainer = $Panel/VBox/Scores
	if GameState.scores.is_empty():
		box.add_child(_make_row("No scores yet — play a game!"))
		return
	for i in GameState.scores.size():
		var entry: Dictionary = GameState.scores[i]
		var text := "%d.  %s  —  Level %d,  %d stars" % [
			i + 1,
			str(entry.get("name", "?")),
			int(entry.get("level", 0)),
			int(entry.get("stars", 0)),
		]
		box.add_child(_make_row(text))


func _make_row(text: String) -> Label:
	var row := Label.new()
	row.text = text
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_theme_font_size_override("font_size", 24)
	row.add_theme_color_override("font_color", Color(0.35, 0.2, 0.4))
	return row


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
