# =============================================================================
# GameManager.gd — Ana koordinatör
# Sahnenin root node'u bu scripti alır.
# =============================================================================

extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_speed_changed(multiplier: float)
signal player_won
signal player_lost

@export var map_width:  int = 56
@export var map_height: int = 56
@export var map_seed:   int = 0

var map_system:       MapSystem        = null
var building_manager: BuildingManager  = null
var unit_manager:     UnitManager      = null

enum GameState { LOADING, PLAYING, PAUSED, WON, LOST }
var state: GameState = GameState.LOADING

var speed_multiplier: float = 1.0
const SPEED_OPTIONS: Array[float] = [0.0, 1.0, 2.0, 4.0]
var speed_index: int = 1

var game_time: float = 0.0

# =============================================================================
func _ready() -> void:
	_find_systems()
	_init_map()
	_spawn_starters()
	state = GameState.PLAYING
	emit_signal("game_started")
	print("Robotic Planet Remaster — v0.1.2 başladı")

func _find_systems() -> void:
	map_system       = get_node_or_null("MapSystem")
	building_manager = get_node_or_null("BuildingManager")
	unit_manager     = get_node_or_null("UnitManager")

	if building_manager and map_system:
		building_manager.map_system = map_system
	if unit_manager and building_manager:
		unit_manager.building_manager = building_manager
	if unit_manager and map_system:
		unit_manager.map_system = map_system

func _init_map() -> void:
	if map_system == null: return
	map_system.initialize(map_width, map_height, map_seed)
	building_manager.place_building("hq", Vector2i(5, 5), 0)
	building_manager.place_building("hq", Vector2i(map_width-6, map_height-6), 1)

	# Başlangıç binaları (ekonomi testi):
	# Madenler girdisiz üretir → robot Storage'a taşır (en net görünür akış)
	_place_starter("iron_mine",  Vector2i(8, 5))
	_place_starter("stone_mine", Vector2i(8, 8))
	_place_starter("storage",    Vector2i(11, 6))

	# Kamera sinirlarini harita boyutuna gore ayarla
	var cam = get_node_or_null("Camera2D")
	if cam and cam.has_method("set_map_bounds"):
		cam.set_map_bounds(map_width * MapSystem.TILE_SIZE, map_height * MapSystem.TILE_SIZE)

	# Kamerayı başlangıç üssüne getir
	if cam:
		cam.position = map_system.grid_to_world(Vector2i(9, 7))

func _place_starter(key: String, pos: Vector2i) -> void:
	# Tile'ı garanti grass yap (rastgele forest/rock olmasın)
	map_system.set_tile(pos, MapSystem.TileType.GRASS)
	# Test binaları anında tamamlanmış olsun (inşaat beklemesin)
	var b = building_manager.place_building(key, pos, 0)
	if b != null:
		b.complete_construction()

func _spawn_starters() -> void:
	if unit_manager == null or map_system == null: return
	# Robotları madenlerle depo arasına koy
	var p = map_system.grid_to_world(Vector2i(9, 6))
	unit_manager.spawn_robot("transporter", p + Vector2(0,  0), 0)
	unit_manager.spawn_robot("transporter", p + Vector2(32, 0), 0)
	unit_manager.spawn_robot("transporter", p + Vector2(0, 32), 0)

# =============================================================================
func _process(delta: float) -> void:
	if state != GameState.PLAYING: return
	var scaled = delta * speed_multiplier
	game_time += scaled
	if building_manager: building_manager.update(scaled)
	if unit_manager:     unit_manager.update(scaled)
	_check_win()

func _check_win() -> void:
	if building_manager == null: return
	if building_manager.get_player_hq() == null: _end(false)
	elif building_manager.get_ai_hq()   == null: _end(true)

func _end(won: bool) -> void:
	if state in [GameState.WON, GameState.LOST]: return
	state = GameState.WON if won else GameState.LOST
	emit_signal("player_won" if won else "player_lost")

# =============================================================================
# HIZ KONTROLÜ
# =============================================================================

func toggle_pause() -> void:
	if state == GameState.PLAYING:
		state = GameState.PAUSED
		speed_multiplier = 0.0
		emit_signal("game_paused")
	elif state == GameState.PAUSED:
		state = GameState.PLAYING
		speed_multiplier = SPEED_OPTIONS[speed_index]
		emit_signal("game_resumed")

func cycle_speed() -> void:
	if state == GameState.PAUSED: return
	speed_index = (speed_index % (SPEED_OPTIONS.size() - 1)) + 1
	speed_multiplier = SPEED_OPTIONS[speed_index]
	emit_signal("game_speed_changed", speed_multiplier)

func set_speed(m: float) -> void:
	speed_multiplier = m
	emit_signal("game_speed_changed", m)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed): return
	match event.keycode:
		KEY_SPACE: toggle_pause()
		KEY_1:     set_speed(1.0)
		KEY_2:     set_speed(2.0)
		KEY_4:     set_speed(4.0)
