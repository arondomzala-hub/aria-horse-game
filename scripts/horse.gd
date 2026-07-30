extends CharacterBody2D
class_name HorseRunner

## Biegnący koń: sam pędzi w prawo. R = skok, E = przyspieszenie.
## Jedna animacja biegu; przy E przyspiesza tylko tempo klatek.

const BASE_SPEED := 320.0
const BOOST_SPEED := 520.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1600.0
const COYOTE_TIME := 0.08
const LIGHTNING_SPEED_MULT := 1.5
const LIGHTNING_DURATION := 4.0

const HORSE_SHEET := "res://assets/horses/horse.png"
const FRAME_COUNT := 6
const RUN_FPS := 12.0
const BOOST_ANIM_SCALE := 1.35
const LIGHTNING_ANIM_SCALE := 1.5
## Klatka ma 221 px wysokości; skala 0.45 daje konia ~100 px na ekranie.
const SPRITE_SCALE := 0.45
## Dolna krawędź kolizji ≈ y=14 — stopy sprite'a trafiają w ten poziom.
const FEET_Y := 14.0

signal died
signal finished

var _coyote := 0.0
var _alive := true
var _spawn_pos := Vector2.ZERO
var _speed_mult := 1.0
var _jump_mult := 1.0
var _lightning_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_spawn_pos = global_position
	_speed_mult = GameState.get_speed_mult()
	_jump_mult = GameState.get_jump_mult()
	_setup_animations()
	anim.play("run")


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	if _lightning_timer > 0.0:
		_lightning_timer = maxf(_lightning_timer - delta, 0.0)

	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		velocity.y += GRAVITY * delta

	var boosting := Input.is_action_pressed("accelerate")
	var lightning_mult := LIGHTNING_SPEED_MULT if _lightning_timer > 0.0 else 1.0
	var target_speed := (BOOST_SPEED if boosting else BASE_SPEED) * _speed_mult * lightning_mult
	velocity.x = target_speed

	if Input.is_action_just_pressed("jump") and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY * _jump_mult
		_coyote = 0.0

	move_and_slide()

	# Boost / lightning przyspieszają tylko tempo klatek — animacja pozostaje jedna.
	if _lightning_timer > 0.0:
		anim.speed_scale = LIGHTNING_ANIM_SCALE
	elif boosting:
		anim.speed_scale = BOOST_ANIM_SCALE
	else:
		anim.speed_scale = 1.0


func apply_lightning_boost() -> void:
	_lightning_timer = LIGHTNING_DURATION


func kill() -> void:
	if not _alive:
		return
	_alive = false
	_lightning_timer = 0.0
	velocity = Vector2.ZERO
	anim.pause()
	died.emit()


func respawn() -> void:
	global_position = _spawn_pos
	velocity = Vector2.ZERO
	_alive = true
	_coyote = 0.0
	_lightning_timer = 0.0
	set_physics_process(true)
	anim.speed_scale = 1.0
	anim.play("run")


func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	_add_sheet_animation(frames, "run", HORSE_SHEET, RUN_FPS)
	anim.sprite_frames = frames
	anim.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	anim.centered = true
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex: Texture2D = frames.get_frame_texture("run", 0)
	if tex:
		_align_feet(tex.get_height())


func _add_sheet_animation(frames: SpriteFrames, anim_name: String, sheet_path: String, fps: float) -> void:
	var sheet := _load_texture(sheet_path)
	var frame_w := int(sheet.get_width() / float(FRAME_COUNT))
	var frame_h := sheet.get_height()
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, true)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		atlas.filter_clip = true
		frames.add_frame(anim_name, atlas)


func _align_feet(frame_h: int) -> void:
	anim.position = Vector2(0.0, FEET_Y - (frame_h * SPRITE_SCALE * 0.5))


func _load_texture(path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var err := img.load(abs_path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	var res := ResourceLoader.load(path)
	if res is Texture2D and (res as Texture2D).get_width() > 0:
		return res
	push_error("Missing horse sheet: %s" % path)
	var fallback := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0.6, 0.3, 0.15))
	return ImageTexture.create_from_image(fallback)
