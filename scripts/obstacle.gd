extends Area2D
class_name Obstacle

## Przeszkoda-hazard: kontakt zabija konia (chyba że skacze nad nią).

enum Kind { HURDLE, PUDDLE, LOG, HALE }

const HAY_PATH := "res://assets/env/hay_bale.png"
const CROSS_PATH := "res://assets/obstacles/cross.png"
const PUDDLE_PATH := "res://assets/obstacles/puddle.png"
const TREE_PATH := "res://assets/obstacles/fallen_tree.png"

@export var kind: Kind = Kind.HURDLE


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("kill"):
		body.kill()


func _build() -> void:
	match kind:
		Kind.HURDLE:
			# Krzyżak — najwyższa przeszkoda; hitbox węższy niż grafika,
			# bo słupki po bokach są wyższe niż środek X.
			_build_sprite_obstacle(CROSS_PATH, 46.5, 0.5, 0.6, 6.0)
		Kind.PUDDLE:
			# Kałuża — płaska, ale szeroka; hitbox od ziemi w górę.
			_build_sprite_obstacle(PUDDLE_PATH, 14.0, 0.62, 0.85, 3.0)
		Kind.LOG:
			_build_sprite_obstacle(TREE_PATH, 39.0, 0.58, 0.66, 6.0)
		Kind.HALE:
			_build_sprite_obstacle(HAY_PATH, 40.0, 0.58, 0.7, 6.0)


func _build_sprite_obstacle(path: String, target_h: float, col_w_frac: float, col_h_frac: float, sink: float) -> void:
	var tex := _load_texture(path)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var s := target_h / float(tex.get_height())
	sprite.scale = Vector2(s, s)
	# `sink` wkopuje grafikę lekko w trawę; hitbox zostaje na poziomie gruntu.
	sprite.position = Vector2(0, -target_h * 0.5 + sink)
	add_child(sprite)

	var shape := RectangleShape2D.new()
	var col_h := target_h * col_h_frac
	shape.size = Vector2(tex.get_width() * s * col_w_frac, col_h)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -col_h * 0.5)
	add_child(cs)


func _load_texture(path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	var res := ResourceLoader.load(path)
	if res is Texture2D and (res as Texture2D).get_width() > 0:
		return res
	var fallback := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0.9, 0.75, 0.2))
	return ImageTexture.create_from_image(fallback)
