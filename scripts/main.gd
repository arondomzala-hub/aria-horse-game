extends Node2D

## Generowana trasa Valley: panorama tła + przeszkody + gwiazdy.
## Kolejne poziomy generowane proceduralnie; 3 życia, serca na parzystych poziomach.

const GROUND_Y := 520.0
const TRACK_END := 5200.0
const MENU_SCENE := "res://scenes/main_menu.tscn"
const STAR_SCENE := preload("res://scenes/star.tscn")
const STAR_PATH := "res://assets/star.png"
const HEART_PATH := "res://assets/heart.png"
const PATH_VALLEY_BG := "res://assets/env/valley_bg.png"
const MAX_LIVES := 3
const BTN_RUN_PATH := "res://assets/ui/btn_run.png"
const BTN_JUMP_PATH := "res://assets/ui/btn_jump.png"
const TOUCH_BTN_SIZE := 260.0
const TOUCH_BTN_MARGIN := 28.0

@onready var horse: HorseRunner = $Horse
@onready var camera: Camera2D = $Horse/Camera2D
@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD
@onready var hint_label: Label = $HUD/Hint
@onready var level_label: Label = $HUD/LevelLabel
@onready var status_label: Label = $HUD/Status
@onready var quit_dialog: Control = $HUD/QuitDialog
@onready var star_count_label: Label = $HUD/StarCounter/Count
@onready var star_icon: TextureRect = $HUD/StarCounter/Icon
@onready var lives_box: HBoxContainer = $HUD/Lives
@onready var game_over_dialog: Control = $HUD/GameOverDialog
@onready var game_over_info: Label = $HUD/GameOverDialog/Panel/VBox/Info
@onready var name_edit: LineEdit = $HUD/GameOverDialog/Panel/VBox/NameEdit
@onready var level_complete_dialog: Control = $HUD/LevelCompleteDialog
@onready var level_complete_title: Label = $HUD/LevelCompleteDialog/Panel/VBox/Title

var _finish_x := TRACK_END - 120.0
var _finished := false
var _respawn_timer := 0.0
var _quit_open := false
var _game_over := false
var _level := 1
var _lives := MAX_LIVES
var _stars_collected := 0
var _track: Node2D
var _touch_run: TouchScreenButton
var _touch_jump: TouchScreenButton

var _tex_cache: Dictionary = {}


func _ready() -> void:
	_build_background()
	_build_ground()
	_build_finish()
	_build_level()
	horse.died.connect(_on_horse_died)
	hint_label.text = "Space — jump   |   A — boost   |   Esc — quit"
	status_label.text = ""
	star_icon.texture = _load_texture(STAR_PATH)
	_update_star_hud()
	_setup_lives_hud()
	_update_level_hud()
	quit_dialog.visible = false
	quit_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$HUD/QuitDialog/Panel/VBox/Buttons/Yes.pressed.connect(_on_quit_yes)
	$HUD/QuitDialog/Panel/VBox/Buttons/No.pressed.connect(_on_quit_no)
	game_over_dialog.visible = false
	$HUD/GameOverDialog/Panel/VBox/Save.pressed.connect(_on_game_over_save)
	name_edit.text_submitted.connect(func(_text: String) -> void: _on_game_over_save())
	level_complete_dialog.visible = false
	$HUD/LevelCompleteDialog/Panel/VBox/Next.pressed.connect(_on_next_level_pressed)
	_setup_touch_controls()


func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if event.is_action_pressed("ui_cancel"):
		if _quit_open:
			_close_quit_dialog()
		else:
			_open_quit_dialog()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _quit_open or _game_over:
		return

	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			status_label.text = ""
			horse.respawn()
			_finished = false
		return

	if _finished:
		return

	if horse.global_position.x >= _finish_x:
		_finished = true
		horse.velocity = Vector2.ZERO
		horse.set_physics_process(false)
		_show_level_complete()


func _show_level_complete() -> void:
	level_complete_title.text = "Level %d complete!" % _level
	level_complete_dialog.visible = true
	$HUD/LevelCompleteDialog/Panel/VBox/Next.grab_focus()


func _on_next_level_pressed() -> void:
	level_complete_dialog.visible = false
	_start_next_level()


func _start_next_level() -> void:
	_level += 1
	_build_level()
	_update_level_hud()
	status_label.text = ""
	horse.respawn()
	_finished = false


func _open_quit_dialog() -> void:
	_quit_open = true
	quit_dialog.visible = true
	get_tree().paused = true
	$HUD/QuitDialog/Panel/VBox/Buttons/No.grab_focus()


func _close_quit_dialog() -> void:
	_quit_open = false
	quit_dialog.visible = false
	get_tree().paused = false


func _on_quit_yes() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_quit_no() -> void:
	_close_quit_dialog()


func _on_horse_died() -> void:
	_lives -= 1
	_update_lives_hud()
	if _lives <= 0:
		_show_game_over()
	else:
		status_label.text = "Ouch!"
		_respawn_timer = 0.85


func _show_game_over() -> void:
	_game_over = true
	status_label.text = ""
	game_over_info.text = "Level: %d\nStars: %d" % [_level, _stars_collected]
	name_edit.text = ""
	game_over_dialog.visible = true
	name_edit.grab_focus()


func _on_game_over_save() -> void:
	var player_name := name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	GameState.add_score(player_name, _level, _stars_collected)
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_star_collected(_star: StarPickup) -> void:
	_stars_collected += 1
	_update_star_hud()


func _on_heart_collected(_heart: HeartPickup) -> void:
	if _lives < MAX_LIVES:
		_lives += 1
		_update_lives_hud()


func _update_star_hud() -> void:
	star_count_label.text = str(_stars_collected)


func _update_level_hud() -> void:
	level_label.text = "Level %d" % _level


func _setup_lives_hud() -> void:
	var tex := _load_texture(HEART_PATH)
	for child in lives_box.get_children():
		if child is TextureRect:
			child.texture = tex
	_update_lives_hud()


func _update_lives_hud() -> void:
	var i := 0
	for child in lives_box.get_children():
		if child is TextureRect:
			child.modulate.a = 1.0 if i < _lives else 0.22
			i += 1


## Ekranowe przyciski dotykowe (tylko urządzenia z ekranem dotykowym):
## bieg w lewym dolnym rogu, skok w prawym dolnym.
func _setup_touch_controls() -> void:
	_touch_run = _make_touch_button(BTN_RUN_PATH, "accelerate")
	_touch_jump = _make_touch_button(BTN_JUMP_PATH, "jump")
	hud.add_child(_touch_run)
	hud.add_child(_touch_jump)
	get_viewport().size_changed.connect(_position_touch_controls)
	_position_touch_controls()


func _make_touch_button(path: String, action: String) -> TouchScreenButton:
	var btn := TouchScreenButton.new()
	var tex := _load_texture(path)
	btn.texture_normal = tex
	btn.action = action
	btn.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	var s := TOUCH_BTN_SIZE / float(tex.get_width())
	btn.scale = Vector2(s, s)
	var shape := CircleShape2D.new()
	shape.radius = maxf(tex.get_width(), tex.get_height()) * 0.5
	btn.shape = shape
	btn.shape_centered = true
	return btn


func _position_touch_controls() -> void:
	var vs := get_viewport().get_visible_rect().size
	var y := vs.y - TOUCH_BTN_SIZE - TOUCH_BTN_MARGIN
	_touch_run.position = Vector2(TOUCH_BTN_MARGIN, y)
	_touch_jump.position = Vector2(vs.x - TOUCH_BTN_SIZE - TOUCH_BTN_MARGIN, y)


func _load_texture(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var tex: Texture2D
	if img.load(abs_path) == OK:
		tex = ImageTexture.create_from_image(img)
	else:
		var res := ResourceLoader.load(path)
		if res is Texture2D and (res as Texture2D).get_width() > 0:
			tex = res
		else:
			var fallback := Image.create(8, 8, false, Image.FORMAT_RGBA8)
			fallback.fill(Color(0.5, 0.6, 0.4))
			tex = ImageTexture.create_from_image(fallback)
	_tex_cache[path] = tex
	return tex


## Buduje przeszkody, gwiazdki i (na parzystych poziomach) serce dla `_level`.
func _build_level() -> void:
	if is_instance_valid(_track):
		_track.queue_free()
	_track = Node2D.new()
	world.add_child(_track)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + _level

	var kinds: Array = [
		Obstacle.Kind.HALE,
		Obstacle.Kind.PUDDLE,
		Obstacle.Kind.LOG,
		Obstacle.Kind.HURDLE,
	]
	# Odstępy maleją z poziomem (więcej przeszkód), ale z bezpiecznym minimum.
	var spacing_min := maxf(600.0 - (_level - 1) * 15.0, 480.0)
	var spacing_max := maxf(800.0 - (_level - 1) * 15.0, 640.0)

	var obstacle_xs: Array[float] = []
	var x := 900.0
	while x <= TRACK_END - 400.0:
		_spawn_obstacle(x, kinds[rng.randi_range(0, kinds.size() - 1)])
		obstacle_xs.append(x)
		x += rng.randf_range(spacing_min, spacing_max)

	# Gwiazdki: przed pierwszą przeszkodą i w połowie każdego odstępu —
	# zawsze z dala od przeszkód.
	var pickup_xs: Array[float] = [350.0, 600.0]
	for i in obstacle_xs.size() - 1:
		pickup_xs.append((obstacle_xs[i] + obstacle_xs[i + 1]) * 0.5)
	pickup_xs.append(minf(obstacle_xs[-1] + 300.0, _finish_x - 120.0))

	# Na parzystych poziomach jeden środkowy slot zajmuje serce.
	var heart_index := -1
	if _level % 2 == 0 and pickup_xs.size() > 2:
		heart_index = 2 + int((pickup_xs.size() - 2) / 2.0)

	for i in pickup_xs.size():
		var pos := Vector2(pickup_xs[i], GROUND_Y - rng.randf_range(70.0, 100.0))
		if i == heart_index:
			var heart := HeartPickup.new()
			heart.position = pos
			heart.collected.connect(_on_heart_collected)
			_track.add_child(heart)
		else:
			var star: StarPickup = STAR_SCENE.instantiate()
			star.position = pos
			star.collected.connect(_on_star_collected)
			_track.add_child(star)


func _build_background() -> void:
	var tex := _load_texture(PATH_VALLEY_BG)
	# Trawa to dolne ~30% obrazu — linia biegu (GROUND_Y) leży głęboko na trawie.
	var target_h := 640.0
	var sc := target_h / float(tex.get_height())
	var tile_w := float(tex.get_width()) * sc
	var top_y := GROUND_Y - target_h * 0.88
	# Poniżej panoramy dokładamy lustrzane przedłużenie samej trawy (dolne 25%
	# obrazu, flip_v — szew niewidoczny), aż pod dolną krawędź widoku kamery.
	var grass_src_h := float(tex.get_height()) * 0.25
	var x := -200.0
	while x < TRACK_END + 500.0:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(sc, sc)
		s.position = Vector2(x, top_y)
		s.z_index = -20
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world.add_child(s)

		var g := Sprite2D.new()
		g.texture = tex
		g.centered = false
		g.scale = Vector2(sc, sc)
		g.position = Vector2(x, top_y + target_h)
		g.z_index = -20
		g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		g.region_enabled = true
		g.region_rect = Rect2(0, tex.get_height() - grass_src_h, tex.get_width(), grass_src_h)
		g.flip_v = true
		world.add_child(g)

		x += tile_w - 1.0


func _build_ground() -> void:
	# Tylko kolizja — wizualna trawa jest częścią panoramy.
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TRACK_END + 600, 80)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(TRACK_END * 0.5, GROUND_Y + 40)
	body.add_child(cs)
	world.add_child(body)

	var wall := StaticBody2D.new()
	var wshape := RectangleShape2D.new()
	wshape.size = Vector2(40, 400)
	var wcs := CollisionShape2D.new()
	wcs.shape = wshape
	wcs.position = Vector2(-40, GROUND_Y - 160)
	wall.add_child(wcs)
	world.add_child(wall)


func _spawn_obstacle(x: float, kind: Obstacle.Kind) -> void:
	var ob := Obstacle.new()
	ob.kind = kind
	ob.position = Vector2(x, GROUND_Y)
	ob.collision_layer = 4
	ob.collision_mask = 2
	ob.monitoring = true
	ob.monitorable = false
	ob.z_index = 1
	_track.add_child(ob)


func _build_finish() -> void:
	var post := Polygon2D.new()
	post.z_index = 2
	post.color = Color(0.9, 0.9, 0.9)
	post.polygon = PackedVector2Array([
		Vector2(_finish_x - 4, GROUND_Y), Vector2(_finish_x + 4, GROUND_Y),
		Vector2(_finish_x + 4, GROUND_Y - 120), Vector2(_finish_x - 4, GROUND_Y - 120),
	])
	world.add_child(post)

	var flag := Polygon2D.new()
	flag.z_index = 2
	flag.color = Color(0.85, 0.2, 0.2)
	flag.polygon = PackedVector2Array([
		Vector2(_finish_x + 4, GROUND_Y - 120),
		Vector2(_finish_x + 70, GROUND_Y - 100),
		Vector2(_finish_x + 4, GROUND_Y - 80),
	])
	world.add_child(flag)

	var line := Polygon2D.new()
	line.z_index = 2
	line.color = Color(1, 1, 1, 0.7)
	line.polygon = PackedVector2Array([
		Vector2(_finish_x - 2, GROUND_Y - 8), Vector2(_finish_x + 2, GROUND_Y - 8),
		Vector2(_finish_x + 2, GROUND_Y + 16), Vector2(_finish_x - 2, GROUND_Y + 16),
	])
	world.add_child(line)
