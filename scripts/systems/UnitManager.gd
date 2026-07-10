# =============================================================================
# UnitManager.gd — Robot üretimi ve görev atama
# =============================================================================

class_name UnitManager
extends Node

signal robot_spawned(robot: Robot)

var map_system: MapSystem           = null
var building_manager: BuildingManager = null

var robots: Array[Robot] = []
var _task_timer: float   = 0.0
const TASK_INTERVAL: float = 0.5

const WORKER_TYPES: Array[String] = ["worker"]  # bu tipler inşaat yapar, kaynak taşımaz

func connect_building_signals() -> void:
	"""GameManager tarafından, building_manager referansı atandıktan SONRA çağrılır.
	_ready() içinde çağrılmaz çünkü child _ready, parent _find_systems'ten önce çalışır
	ve building_manager o an henüz null olur."""
	if building_manager and not building_manager.building_placed.is_connected(_on_building_placed):
		building_manager.building_placed.connect(_on_building_placed)

# =============================================================================
func update(delta: float) -> void:
	_task_timer += delta
	if _task_timer >= TASK_INTERVAL:
		_task_timer = 0.0
		_assign_tasks()

func spawn_robot(robot_type: String, world_pos: Vector2, player: int) -> Robot:
	var r             = Robot.new()
	r.robot_type      = robot_type
	r.owner_player    = player
	r.global_position = world_pos
	get_parent().add_child(r)
	robots.append(r)
	emit_signal("robot_spawned", r)
	return r

# =============================================================================
func _assign_tasks() -> void:
	if building_manager == null: return
	for r in robots:
		if not r.is_idle(): continue
		if r.robot_type in WORKER_TYPES:
			_assign_construct_if_needed(r)
			continue
		if r.has_cargo(): _assign_delivery(r)
		else:             _assign_pickup(r)

func _assign_construct_if_needed(worker: Robot) -> void:
	"""Boşta worker varsa, bekleyen (worker'sız) bir inşaat alanı bul."""
	var waiting = building_manager.get_buildings_awaiting_worker(worker.owner_player)
	if waiting.is_empty():
		return
	var nearest: Building = null
	var best_dist = INF
	for b in waiting:
		var d = b.global_position.distance_to(worker.global_position)
		if d < best_dist:
			best_dist = d; nearest = b
	if nearest != null:
		worker.assign_construct_task(nearest)

func _assign_pickup(r: Robot) -> void:
	var result = building_manager.get_nearest_with_output(r.global_position, r.owner_player)
	var b: Building = result.get("building", null)
	var bin: int    = result.get("bin", -1)
	if b == null or bin == -1: return
	r.assign_pickup_task(b, bin)

func _assign_delivery(r: Robot) -> void:
	var ctype = r.get_cargo_type()
	if ctype == "": return
	var candidates = building_manager.get_buildings_needing_input(ctype)
	var nearest: Building = null
	var best_dist = INF
	for b in candidates:
		if b.owner_player != r.owner_player: continue
		var d = b.global_position.distance_to(r.global_position)
		if d < best_dist:
			best_dist = d; nearest = b
	if nearest == null: return
	r.assign_delivery_task(nearest)

# =============================================================================
# İNŞAAT GÖREV ATAMA (Worker'lar)
# =============================================================================

func _on_building_placed(building: Building) -> void:
	if building.is_constructed:
		return  # HQ gibi anında tamamlanan binalar worker beklemez
	_try_assign_worker(building)

func _try_assign_worker(building: Building) -> void:
	var worker = _find_idle_worker(building.owner_player)
	if worker == null:
		return  # Şu an boşta worker yok, bina "beklemede" kalır
	worker.assign_construct_task(building)

func _find_idle_worker(player: int) -> Robot:
	# NOT: Şu an ilk bulunan boşta worker'ı döner (mesafe karşılaştırması yapmaz).
	# Birden fazla worker olduğunda "en yakın" mantığı gerekirse burası genişletilir.
	for r in robots:
		if r.owner_player != player: continue
		if r.robot_type not in WORKER_TYPES: continue
		if not r.is_idle(): continue
		return r
	return null

# =============================================================================
func get_robots_by_player(player: int) -> Array[Robot]:
	var result: Array[Robot] = []
	for r in robots:
		if r.owner_player == player: result.append(r)
	return result
