extends Area2D
class_name LightningPickup

## Piorun do zebrania — daje tymczasowy boost prędkości.

signal collected(lightning: LightningPickup)

const LIGHTNING_PATH := "res://assets/lightning.png"
const TARGET_H := 110.0
const HITBOX_RADIUS := 48.0

var _taken := false
var _bob_t := 0.0
var _base_y := 0.0

var sprite: Sprite2D


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	var shape := CircleShape2D.new()
	shape.radius = HITBOX_RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	collision_layer = 0
	collision_mask = 2  # horse
	monitoring = true
	monitorable = false


func _process(delta: float) -> void:
	if _taken:
		return
	_bob_t += delta * 3.5
	position.y = _base_y + sin(_bob_t) * 6.0
	sprite.rotation = sin(_bob_t * 0.7) * 0.12


func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	var tex := _load_texture(LIGHTNING_PATH)
	sprite.texture = tex
	var s := TARGET_H / float(tex.get_height())
	sprite.scale = Vector2(s, s)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	z_index = 3


func _on_body_entered(body: Node2D) -> void:
	if _taken:
		return
	if body is HorseRunner or body.has_method("kill"):
		_take()


func _take() -> void:
	_taken = true
	set_deferred("monitoring", false)
	collected.emit(self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", sprite.scale * 1.35, 0.12)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)


func _load_texture(path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	var res := ResourceLoader.load(path)
	if res is Texture2D and (res as Texture2D).get_width() > 0:
		return res
	# Awaryjny piorun proceduralny
	var fallback := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0, 0, 0, 0))
	var pts := PackedVector2Array([
		Vector2(28, 4), Vector2(18, 28), Vector2(30, 28),
		Vector2(22, 60), Vector2(42, 24), Vector2(30, 24), Vector2(40, 4),
	])
	for y in 64:
		for x in 64:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), pts):
				fallback.set_pixel(x, y, Color(1.0, 0.92, 0.25, 1.0))
	return ImageTexture.create_from_image(fallback)
