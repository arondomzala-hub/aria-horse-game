extends Control
class_name HorsePreview

## Miniatura konia rysowana w UI (menu wyboru).

var horse_id: GameState.HorseId = GameState.HorseId.WEX


func _draw() -> void:
	var p: Dictionary = GameState.get_coat_palette(horse_id)
	var o := Vector2(size.x * 0.45, size.y * 0.62)
	var s := 1.5
	_poly(p.coat, o, s, [
		Vector2(-28, -6), Vector2(22, -10), Vector2(26, 4),
		Vector2(14, 12), Vector2(-24, 12), Vector2(-30, 2),
	])
	_poly(p.coat, o, s, [
		Vector2(14, -8), Vector2(28, -22), Vector2(34, -16), Vector2(22, 0),
	])
	_poly(p.coat, o, s, [
		Vector2(26, -24), Vector2(44, -20), Vector2(48, -14), Vector2(38, -8), Vector2(24, -12),
	])
	_poly(p.mane, o, s, [
		Vector2(14, -12), Vector2(26, -26), Vector2(30, -22), Vector2(20, -6),
	])
	_poly(p.mane, o, s, [
		Vector2(-28, 0), Vector2(-36, -4), Vector2(-48, 8), Vector2(-34, 10),
	])
	for lx in [-22.0, -10.0, 4.0, 14.0]:
		_poly(p.dark, o, s, [
			Vector2(lx - 2, 10), Vector2(lx + 2, 10), Vector2(lx + 3, 28), Vector2(lx - 3, 28),
		])
	_poly(p.eye, o, s, [
		Vector2(40, -18), Vector2(44, -18), Vector2(44, -14), Vector2(40, -14),
	])


func _poly(color: Color, origin: Vector2, scale_f: float, points: Array) -> void:
	var pts := PackedVector2Array()
	for pt in points:
		pts.append(origin + pt * scale_f)
	draw_colored_polygon(pts, color)


func setup(id: GameState.HorseId) -> void:
	horse_id = id
	queue_redraw()
