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
	btn.custom_minimum_size = Vector2(190, 320)
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

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var tex := TextureRect.new()
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex.custom_minimum_size = Vector2(0, 180)
	tex.texture = GameState.get_horse_atlas(id)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tex)

	var name_label := Label.new()
	name_label.text = GameState.HORSE_NAMES[id]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.95))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = GameState.get_stats_label(id)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.78))
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)

	btn.pressed.connect(func() -> void: _select_horse(id))
	btn.tooltip_text = "%s\n%s" % [GameState.HORSE_NAMES[id], GameState.get_stats_label(id)]
	return btn


func _select_horse(id: GameState.HorseId) -> void:
	GameState.selected_horse = id
	MusicPlayer.start()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
