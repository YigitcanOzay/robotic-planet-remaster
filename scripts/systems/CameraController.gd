# =============================================================================
# CameraController.gd — Dokunmatik kamera
# Tek parmak sürükle → pan | İki parmak → pinch zoom
# Camera2D node'una bağlanır.
# =============================================================================

extends Camera2D

const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.0

# Aktif dokunuşlar: index → son ekran pozisyonu
var _touches: Dictionary = {}
var _last_pinch_dist: float = -1.0
var _mouse_dragging: bool = false  # YEDEK: mouse pan için

var map_min := Vector2.ZERO
var map_max := Vector2.ZERO

func set_map_bounds(w: float, h: float) -> void:
	map_min = Vector2.ZERO
	map_max = Vector2(w, h)

func zoom_by(factor: float) -> void:
	"""HUD butonlarından çağrılır — pinch zoom mouse ile mümkün olmadığında yedek kontrol."""
	var new_zoom = clamp(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_position()

# =============================================================================
func _input(event: InputEvent) -> void:
	# --- GERÇEK TOUCH (bazı ortamlarda çalışır) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			_last_pinch_dist = -1.0

	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position

		if _touches.size() == 1:
			# Tek parmak → pan
			position -= event.relative / zoom
			_clamp_position()
		elif _touches.size() == 2:
			# İki parmak → pinch zoom
			_handle_pinch()

	# --- YEDEK: MOUSE (legacy Android export'ta touch, mouse'a çevriliyor) ---
	# Not: Mouse tek imleç olduğu için pinch-zoom mouse ile yapılamaz,
	# bu yüzden sadece pan (sürükleme) buradan destekleniyor.
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_dragging = event.pressed

	elif event is InputEventMouseMotion:
		if _mouse_dragging:
			position -= event.relative / zoom
			_clamp_position()

func _handle_pinch() -> void:
	var keys = _touches.keys()
	var p0: Vector2 = _touches[keys[0]]
	var p1: Vector2 = _touches[keys[1]]
	var dist = p0.distance_to(p1)

	if _last_pinch_dist > 0.0:
		var ratio = dist / _last_pinch_dist
		var new_zoom = clamp(zoom.x * ratio, ZOOM_MIN, ZOOM_MAX)
		zoom = Vector2(new_zoom, new_zoom)
		_clamp_position()

	_last_pinch_dist = dist

# =============================================================================
func _clamp_position() -> void:
	if map_max == Vector2.ZERO:
		return
	var half = get_viewport().get_visible_rect().size * 0.5 / zoom
	if half.x * 2 < map_max.x:
		position.x = clamp(position.x, map_min.x + half.x, map_max.x - half.x)
	else:
		position.x = (map_min.x + map_max.x) * 0.5
	if half.y * 2 < map_max.y:
		position.y = clamp(position.y, map_min.y + half.y, map_max.y - half.y)
	else:
		position.y = (map_min.y + map_max.y) * 0.5
