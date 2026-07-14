# =============================================================================
# MapSystem.gd — Grid ve A* pathfinding
# =============================================================================

class_name MapSystem
extends Node2D

const TILE_SIZE: int = 32

enum TileType { GRASS, FOREST, WATER, HILL, ROCK, ROAD, BUILDING, HQ }

const WALKABLE: Array = [TileType.ROAD]  # yol şartı: sadece Asphalt üzerinde yürünebilir

var map_width:  int = 56
var map_height: int = 56
var rng_seed:   int = 0

var grid:          Array = []
var building_grid: Array = []

signal tile_changed(pos: Vector2i, new_type: int)

# =============================================================================
func initialize(w: int, h: int, seed: int = 0) -> void:
	map_width  = w
	map_height = h
	rng_seed   = seed
	_generate()
	queue_redraw()

func _generate() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed if rng_seed != 0 else randi()
	grid          = []
	building_grid = []
	for x in range(map_width):
		grid.append([])
		building_grid.append([])
		for y in range(map_height):
			var t = TileType.GRASS
			var r = rng.randf()
			if   r < 0.10: t = TileType.FOREST
			elif r < 0.15: t = TileType.HILL
			elif r < 0.17: t = TileType.ROCK
			if x == 0 or y == 0 or x == map_width-1 or y == map_height-1:
				t = TileType.WATER
			grid[x].append(t)
			building_grid[x].append(null)

func _draw() -> void:
	var colors := {
		TileType.GRASS:    Color(0.30, 0.60, 0.20),
		TileType.FOREST:   Color(0.10, 0.40, 0.10),
		TileType.WATER:    Color(0.10, 0.30, 0.70),
		TileType.HILL:     Color(0.60, 0.50, 0.30),
		TileType.ROCK:     Color(0.50, 0.50, 0.50),
		TileType.ROAD:     Color(0.30, 0.30, 0.30),
		TileType.BUILDING: Color(0.70, 0.70, 0.20),
		TileType.HQ:       Color(0.90, 0.20, 0.20),
	}
	for x in range(map_width):
		for y in range(map_height):
			draw_rect(
				Rect2(Vector2(x,y) * TILE_SIZE, Vector2(TILE_SIZE-1, TILE_SIZE-1)),
				colors.get(grid[x][y], Color.MAGENTA)
			)

# --- Koordinat ---
func world_to_grid(w: Vector2) -> Vector2i:
	return Vector2i(int(w.x / TILE_SIZE), int(w.y / TILE_SIZE))

func grid_to_world(g: Vector2i) -> Vector2:
	return Vector2(g.x * TILE_SIZE + TILE_SIZE * 0.5,
	               g.y * TILE_SIZE + TILE_SIZE * 0.5)

# --- Tile sorgu ---
func get_tile(pos: Vector2i) -> TileType:
	if not _in_bounds(pos): return TileType.WATER
	return grid[pos.x][pos.y] as TileType

func is_walkable(pos: Vector2i) -> bool:
	return get_tile(pos) in WALKABLE

func get_speed_multiplier(pos: Vector2i) -> float:
	"""Tile üzerindeki hareket hız çarpanı. Şu an sadece ROAD yürünebilir
	olduğu için pratikte hep 1.0 döner; kural ileride gevşetilirse kullanılır."""
	match get_tile(pos):
		TileType.ROAD: return 1.0
		_: return 0.5

func is_buildable(pos: Vector2i) -> bool:
	if not _in_bounds(pos): return false
	return get_tile(pos) in [TileType.GRASS, TileType.HILL]

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height

# --- Tile değiştir ---
func set_tile(pos: Vector2i, t: TileType) -> void:
	if not _in_bounds(pos): return
	grid[pos.x][pos.y] = t
	emit_signal("tile_changed", pos, t)
	queue_redraw()

func place_building_tiles(pos: Vector2i, building: Building) -> void:
	set_tile(pos, TileType.BUILDING)
	building_grid[pos.x][pos.y] = building

func remove_building_tiles(pos: Vector2i) -> void:
	set_tile(pos, TileType.GRASS)
	building_grid[pos.x][pos.y] = null

func get_building_at(pos: Vector2i) -> Building:
	if not _in_bounds(pos): return null
	return building_grid[pos.x][pos.y]

# --- A* ---
func find_path(start: Vector2i, goal: Vector2i) -> PackedVector2Array:
	if start == goal:
		return PackedVector2Array([grid_to_world(start)])

	var open_set := [start]
	var came_from := {}
	var g := {start: 0}
	var f := {start: _h(start, goal)}

	while not open_set.is_empty():
		var cur: Vector2i = _lowest_f(open_set, f)
		if cur == goal:
			return _reconstruct(came_from, cur)
		open_set.erase(cur)
		for nb in _neighbors(cur):
			# Hedefin kendisi yürünemez olsa bile (örn. bina tile'ı) oraya varmaya izin ver.
			# Sadece ARA duraklar yürünebilir olmak zorunda.
			if nb != goal and not is_walkable(nb): continue
			var tg: int = g.get(cur, 9999) + 1
			if tg < g.get(nb, 9999):
				came_from[nb] = cur
				g[nb] = tg
				f[nb] = tg + _h(nb, goal)
				if nb not in open_set: open_set.append(nb)

	return PackedVector2Array()

func _h(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x-b.x) + abs(a.y-b.y)

func _lowest_f(open_set: Array, f: Dictionary) -> Vector2i:
	var best: Vector2i = open_set[0]
	for n in open_set:
		if f.get(n, 9999) < f.get(best, 9999): best = n
	return best

func _neighbors(p: Vector2i) -> Array:
	return [Vector2i(p.x+1,p.y), Vector2i(p.x-1,p.y),
	        Vector2i(p.x,p.y+1), Vector2i(p.x,p.y-1)]

func _reconstruct(came_from: Dictionary, cur: Vector2i) -> PackedVector2Array:
	var path: Array[Vector2i] = [cur]
	while cur in came_from:
		cur = came_from[cur]
		path.push_front(cur)
	var result := PackedVector2Array()
	for p in path: result.append(grid_to_world(p))
	return result

# =============================================================================
# YOL DÖŞEME PATHFINDING (robot hareketinden AYRI)
# Doğal engelleri (orman/su/kaya) atlar, düz zemin üzerinden geçer.
# Grid koordinat listesi döner (hangi tile'lar yol yapılacak).
# =============================================================================

const ROAD_BLOCKERS: Array = [TileType.FOREST, TileType.WATER, TileType.ROCK]

func find_road_path(start: Vector2i, goal: Vector2i) -> Array:
	"""İki nokta arası, engelleri atlayan tile listesi döndürür (grid koordinatı).
	Boş dönerse yol bulunamadı (engellerle tamamen çevrili)."""
	if start == goal:
		return [start]
	if not _in_bounds(start) or not _in_bounds(goal):
		return []

	var open_set := [start]
	var came_from := {}
	var g := {start: 0}
	var f := {start: _h(start, goal)}

	while not open_set.is_empty():
		var cur: Vector2i = _lowest_f(open_set, f)
		if cur == goal:
			return _reconstruct_grid(came_from, cur)
		open_set.erase(cur)
		for nb in _neighbors(cur):
			if not _in_bounds(nb): continue
			# Hedef hariç, engel tile'larından geçme
			if nb != goal and get_tile(nb) in ROAD_BLOCKERS: continue
			var tg: int = g.get(cur, 9999) + 1
			if tg < g.get(nb, 9999):
				came_from[nb] = cur
				g[nb] = tg
				f[nb] = tg + _h(nb, goal)
				if nb not in open_set: open_set.append(nb)

	return []

func _reconstruct_grid(came_from: Dictionary, cur: Vector2i) -> Array:
	var path: Array[Vector2i] = [cur]
	while cur in came_from:
		cur = came_from[cur]
		path.push_front(cur)
	return path
