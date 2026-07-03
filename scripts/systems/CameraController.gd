extends Camera2D

const ZOOM_MIN   := Vector2(0.3, 0.3)
const ZOOM_MAX   := Vector2(2.0, 2.0)

var _drag_active  := false
var _pinch_active := false
var map_min := Vector2.ZERO
var map_max := Vector2.ZERO

func set_map_bounds(w: float, h: float) -> void:
map_min = Vector2.ZERO
map_max = Vector2(w, h)

func _input(event: InputEvent) -> void:
if event is InputEventScreenTouch:
if event.pressed:
if event.index == 0:
_drag_active = true
_pinch_active = false
elif event.index == 1:
_drag_active = false
_pinch_active = true
else:
if event.index == 0: _drag_active = false
if event.index == 1: _pinch_active = false
elif event is InputEventScreenDrag:
if _drag_active and not _pinch_active:
position -= event.relative / zoom
_clamp_position()
elif event is InputEventMagnifyGesture:
zoom = (zoom * event.factor).clamp(ZOOM_MIN, ZOOM_MAX)
_clamp_position()

func _clamp_position() -> void:
if map_max == Vector2.ZERO: return
var half = get_viewport().get_visible_rect().size * 0.5 / zoom
position.x = clamp(position.x, map_min.x + half.x, map_max.x - half.x)
position.y = clamp(position.y, map_min.y + half.y, map_max.y - half.y)
