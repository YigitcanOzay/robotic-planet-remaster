# =============================================================================
# Robot.gd — Robot temel sınıfı
# Worker / Transporter / HeavyTransporter / Scout ortak kodu
# =============================================================================

class_name Robot
extends CharacterBody2D

signal task_completed(robot)
signal resource_picked_up(robot, resource)
signal resource_delivered(robot, resource, building)

# --- Veri ---
var robot_type: String    = "transporter"
var robot_data: Dictionary = {}
var owner_player: int     = 0

var speed: float     = 64.0   # px/sn (tile_size × speed_factor)
var capacity: int    = 1
var cargo: GameResource = null

# --- Görev state machine ---
enum State { IDLE, MOVING_TO_PICKUP, PICKING_UP, MOVING_TO_DROPOFF, DROPPING_OFF }
var state: State = State.IDLE

var target_building: Building = null
var target_bin_index: int     = -1
var path: PackedVector2Array  = []
var path_index: int           = 0

const TILE_SIZE: float = 32.0

# =============================================================================
func _ready() -> void:
	robot_data = GameData.ROBOTS.get(robot_type, {})
	speed      = robot_data.get("speed", 1.0) * TILE_SIZE * 2.0

# =============================================================================
# HAREKET
# =============================================================================

func _physics_process(delta: float) -> void:
	match state:
		State.MOVING_TO_PICKUP, State.MOVING_TO_DROPOFF:
			_move_along_path(delta)
		State.PICKING_UP:
			_do_pickup()
		State.DROPPING_OFF:
			_do_dropoff()

func _move_along_path(delta: float) -> void:
	if path.is_empty() or path_index >= path.size():
		_on_arrived()
		return
	var target    = path[path_index]
	var direction = (target - global_position).normalized()
	if global_position.distance_to(target) < 4.0:
		global_position = target
		path_index += 1
		if path_index >= path.size(): _on_arrived()
	else:
		velocity = direction * speed
		move_and_slide()

func _on_arrived() -> void:
	velocity = Vector2.ZERO
	if   state == State.MOVING_TO_PICKUP:  state = State.PICKING_UP
	elif state == State.MOVING_TO_DROPOFF: state = State.DROPPING_OFF

func move_to(world_pos: Vector2) -> void:
	path       = PackedVector2Array([global_position, world_pos])
	path_index = 0

# =============================================================================
# ALMA / BIRAKMA
# =============================================================================

func assign_pickup_task(from_building: Building, bin_index: int) -> void:
	target_building  = from_building
	target_bin_index = bin_index
	state            = State.MOVING_TO_PICKUP
	move_to(from_building.global_position)

func assign_delivery_task(to_building: Building) -> void:
	target_building = to_building
	state           = State.MOVING_TO_DROPOFF
	move_to(to_building.global_position)

func _do_pickup() -> void:
	if target_building == null:
		state = State.IDLE
		return
	var res = target_building.remove_from_output_bin(target_bin_index)
	if res == null:
		state = State.IDLE
		emit_signal("task_completed", self)
		return
	cargo = res
	emit_signal("resource_picked_up", self, res)
	state = State.IDLE  # UnitManager yeni görev atar

func _do_dropoff() -> void:
	if target_building == null or cargo == null:
		state = State.IDLE
		return
	var result = target_building.add_to_input_bin(cargo)
	if result == -1:
		state = State.IDLE
		emit_signal("task_completed", self)
		return
	emit_signal("resource_delivered", self, cargo, target_building)
	cargo           = null
	target_building = null
	target_bin_index = -1
	state           = State.IDLE
	emit_signal("task_completed", self)

# =============================================================================
func is_idle() -> bool:     return state == State.IDLE
func has_cargo() -> bool:   return cargo != null
func get_cargo_type() -> String: return "" if cargo == null else cargo.resource_type
