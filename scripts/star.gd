extends Area2D
class_name StarPickup

## Gwiazdka do zebrania na trasie.

signal collected(star: StarPickup)

const STAR_PATH := "res://assets/star.png"

var _taken := false
var _bob_t := 0.0
var _base_y := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	collision_layer = 0
	collision_mask = 2  # horse
	monitoring = true
	monitorable = false


func _process(delta: float) -> void:
	if _taken:
		return
	_bob_t += delta * 3.0
	position.y = _base_y + sin(_bob_t) * 6.0
	sprite.rotation = sin(_bob_t * 0.7) * 0.12


func _setup_sprite() -> void:
	sprite.texture = _load_texture(STAR_PATH)
	sprite.scale = Vector2(0.1, 0.1)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _on_body_entered(body: Node2D) -> void:
	if _taken:
		return
	if body is HorseRunner or body.has_method("kill"):
		_take()


func _take() -> void:
	_taken = true
	set_deferred("monitoring", false)
	collected.emit(self)
	# Krótki efekt zebrania
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
	# Awaryjna gwiazda proceduralna
	var fallback := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 64:
			var dx := (x - 32) / 32.0
			var dy := (y - 32) / 32.0
			var ang := atan2(dy, dx)
			var r := sqrt(dx * dx + dy * dy)
			var spike := absf(cos(ang * 2.5))
			if r < 0.35 + spike * 0.45:
				fallback.set_pixel(x, y, Color(1.0, 0.82, 0.15, 1.0))
	return ImageTexture.create_from_image(fallback)
