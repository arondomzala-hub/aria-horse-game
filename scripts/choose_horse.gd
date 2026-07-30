extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var horses_grid: GridContainer = $Center/Panel/VBox/Horses
@onready var title_label: Label = $Center/Panel/VBox/Title


func _ready() -> void:
	title_label.text = "Choose Horse"
	var bg := $Background as TextureRect
	bg.texture = GameState.get_menu_background()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	$BackButton.pressed.connect(_on_back_pressed)
	_build_horse_buttons()


func _build_horse_buttons() -> void:
	for child in horses_grid.get_children():
		child.queue_free()

	for id in GameState.ALL_HORSES:
		horses_grid.add_child(_make_horse_card(id))


func _make_horse_card(id: GameState.HorseId) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(190, 290)
	btn.focus_mode = Control.FOCUS_ALL
	btn.clip_contents = true

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.05, 0.05, 0.06, 0.92)
	style_normal.corner_radius_top_left = 16
	style_normal.corner_radius_top_right = 16
	style_normal.corner_radius_bottom_right = 16
	style_normal.corner_radius_bottom_left = 16
	style_normal.border_width_left = 3
	style_normal.border_width_top = 3
	style_normal.border_width_right = 3
	style_normal.border_width_bottom = 3
	style_normal.border_color = Color(0.95, 0.55, 0.7)
	style_normal.content_margin_left = 6
	style_normal.content_margin_right = 6
	style_normal.content_margin_top = 6
	style_normal.content_margin_bottom = 6

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.12, 0.08, 0.12, 0.95)
	style_hover.border_color = Color(1.0, 0.75, 0.85)
	style_hover.border_width_left = 4
	style_hover.border_width_top = 4
	style_hover.border_width_right = 4
	style_hover.border_width_bottom = 4

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)

	var tex := TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.offset_left = 8
	tex.offset_top = 8
	tex.offset_right = -8
	tex.offset_bottom = -8
	tex.texture = GameState.get_horse_atlas(id)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex)

	btn.pressed.connect(func() -> void: _select_horse(id))
	btn.tooltip_text = GameState.HORSE_NAMES[id]
	return btn


func _select_horse(id: GameState.HorseId) -> void:
	GameState.selected_horse = id
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
