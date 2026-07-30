extends Node

## Wspólny stan gry między scenami.

enum HorseId { WEX, HAROLD, ARPACO, FIRO, PTYS, PINKI }

var selected_horse: HorseId = HorseId.WEX

const HORSE_NAMES := {
	HorseId.WEX: "Wex",
	HorseId.HAROLD: "Harold",
	HorseId.ARPACO: "Arpaco",
	HorseId.FIRO: "Firo",
	HorseId.PTYS: "Ptyś",
	HorseId.PINKI: "Pinki",
}

const MENU_BG_PATH := "res://assets/menu_bg.png"
const SHEET_PATH := "res://assets/horses_sheet.png"
const SHEET_COLS := 3
const SHEET_ROWS := 2
const SHEET_SIZE := Vector2i(1024, 1024)

const HORSE_SHEET_INDEX := {
	HorseId.WEX: 0,
	HorseId.HAROLD: 1,
	HorseId.ARPACO: 2,
	HorseId.FIRO: 3,
	HorseId.PTYS: 4,
	HorseId.PINKI: 5,
}

const ALL_HORSES: Array[HorseId] = [
	HorseId.WEX,
	HorseId.HAROLD,
	HorseId.ARPACO,
	HorseId.FIRO,
	HorseId.PTYS,
	HorseId.PINKI,
]

const LEADERBOARD_PATH := "user://leaderboard.json"
const LEADERBOARD_MAX := 10

var scores: Array = []  # [{name: String, level: int, stars: int}]

var _menu_bg: Texture2D
var _sheet: Texture2D


func _ready() -> void:
	load_scores()


func load_scores() -> void:
	scores = []
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		scores = data


func save_scores() -> void:
	var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Nie udało się zapisać leaderboardu: %s" % LEADERBOARD_PATH)
		return
	f.store_string(JSON.stringify(scores))


func add_score(player_name: String, level: int, stars: int) -> void:
	scores.append({"name": player_name, "level": level, "stars": stars})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
		return int(a.stars) > int(b.stars))
	if scores.size() > LEADERBOARD_MAX:
		scores.resize(LEADERBOARD_MAX)
	save_scores()


func get_menu_background() -> Texture2D:
	if _menu_bg == null:
		_menu_bg = _load_texture(MENU_BG_PATH)
	return _menu_bg


func get_horse_atlas(id: HorseId = selected_horse) -> AtlasTexture:
	if _sheet == null:
		_sheet = _load_texture(SHEET_PATH)
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = get_sheet_region(id)
	atlas.filter_clip = true
	return atlas


func get_sheet_region(id: HorseId) -> Rect2:
	var index: int = HORSE_SHEET_INDEX[id]
	var col := index % SHEET_COLS
	var row := int(index / float(SHEET_COLS))
	var cell_w := int(SHEET_SIZE.x / float(SHEET_COLS))
	var cell_h := int(SHEET_SIZE.y / float(SHEET_ROWS))
	var x := col * cell_w
	var w := cell_w if col < SHEET_COLS - 1 else SHEET_SIZE.x - x
	var y := row * cell_h
	var h := cell_h if row < SHEET_ROWS - 1 else SHEET_SIZE.y - y
	return Rect2(x, y, w, h)


## Ładuje PNG bezpośrednio (import Godota dla tych plików bywa invalid / bez .ctex).
func _load_texture(path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var err := img.load(abs_path)
	if err != OK:
		# Fallback: spróbuj ResourceLoader
		var res := ResourceLoader.load(path)
		if res is Texture2D and (res as Texture2D).get_width() > 0:
			return res
		push_error("Nie udało się wczytać obrazu: %s (err=%s)" % [path, err])
		var fallback := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		fallback.fill(Color(0.9, 0.4, 0.6))
		return ImageTexture.create_from_image(fallback)

	return ImageTexture.create_from_image(img)


func get_coat_palette(id: HorseId = selected_horse) -> Dictionary:
	match id:
		HorseId.WEX:
			return {
				"coat": Color(0.52, 0.30, 0.14),
				"dark": Color(0.12, 0.08, 0.06),
				"mane": Color(0.08, 0.05, 0.04),
				"hoof": Color(0.08, 0.05, 0.04),
				"eye": Color(0.08, 0.06, 0.04),
			}
		HorseId.HAROLD:
			return {
				"coat": Color(0.93, 0.92, 0.9),
				"dark": Color(0.55, 0.52, 0.5),
				"mane": Color(0.88, 0.86, 0.84),
				"hoof": Color(0.25, 0.22, 0.2),
				"eye": Color(0.25, 0.35, 0.55),
			}
		HorseId.ARPACO:
			return {
				"coat": Color(0.92, 0.9, 0.88),
				"dark": Color(0.1, 0.08, 0.08),
				"mane": Color(0.08, 0.05, 0.05),
				"hoof": Color(0.08, 0.05, 0.05),
				"eye": Color(0.15, 0.12, 0.1),
				"spotted": true,
			}
		HorseId.FIRO:
			return {
				"coat": Color(0.45, 0.45, 0.48),
				"dark": Color(0.12, 0.1, 0.1),
				"mane": Color(0.08, 0.07, 0.08),
				"hoof": Color(0.08, 0.06, 0.06),
				"eye": Color(0.15, 0.15, 0.18),
			}
		HorseId.PTYS:
			return {
				"coat": Color(0.08, 0.07, 0.08),
				"dark": Color(0.08, 0.07, 0.08),
				"mane": Color(0.05, 0.04, 0.05),
				"hoof": Color(0.95, 0.94, 0.92),
				"eye": Color(0.7, 0.65, 0.3),
			}
		HorseId.PINKI:
			return {
				"coat": Color(0.62, 0.28, 0.16),
				"dark": Color(0.92, 0.88, 0.78),
				"mane": Color(0.9, 0.82, 0.55),
				"hoof": Color(0.92, 0.88, 0.78),
				"eye": Color(0.2, 0.12, 0.08),
			}
	return get_coat_palette(HorseId.WEX)
