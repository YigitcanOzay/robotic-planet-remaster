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
	z_index = 10  # bina ve zeminin üstünde
	queue_redraw()

# =============================================================================
# ÇİZİM (kod-sprite: üçgen gövde + taşınan kaynak)
# =============================================================================

func _draw() -> void:
	# Robot türüne göre renk
	var body_col := Color(0.85, 0.85, 0.90)  # transporter varsayılan
	match robot_type:
		"worker":            body_col = Color(0.95, 0.75, 0.20)
		"heavy_transporter": body_col = Color(0.60, 0.65, 0.95)
		"scout":             body_col = Color(0.40, 0.90, 0.50)

	# Üçgen gövde (yön göstermez, sadece ayırt için)
	var pts := PackedVector2Array([
		Vector2(0, -8), Vector2(7, 6), Vector2(-7, 6)
	])
	draw_colored_polygon(pts, body_col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]),
		Color.BLACK, 1.5)

	# Taşınan kaynak (üstünde renkli kutu)
	if cargo != null:
		var col = GameData.resource_color(cargo.resource_type)
		draw_rect(Rect2(-5, -14, 10, 10), col)
		draw_rect(Rect2(-5, -14, 10, 10), Color.BLACK, false, 1.0)

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
	res.visible = false  # robot kendi _draw'unda gösterir, çift görüntü olmasın
	queue_redraw()
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
	queue_redraw()
	emit_signal("task_completed", self)

# =============================================================================
func is_idle() -> bool:     return state == State.IDLE
func has_cargo() -> bool:   return cargo != null
func get_cargo_type() -> String: return "" if cargo == null else cargo.resource_type
