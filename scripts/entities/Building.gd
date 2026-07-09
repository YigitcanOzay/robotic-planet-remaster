# =============================================================================
# Building.gd — Bina temel sınıfı
# Bin sistemi + 3000ms üretim döngüsü + efficiency formülü
# =============================================================================

class_name Building
extends Node2D

signal production_completed(building, resource_type: String)
signal building_destroyed(building)
signal efficiency_changed(building, value: float)

# --- Temel ---
var building_key: String      = ""
var building_data: Dictionary = {}
var owner_player: int         = 0
var grid_position: Vector2i   = Vector2i.ZERO
var is_constructed: bool      = false
var build_progress: float     = 0.0

var hp: float     = 0.0
var max_hp: float = 0.0

# --- Bin sistemi ---
var input_bins: Array  = []
var output_bins: Array = []
var max_input_slots: int  = 0
var max_output_slots: int = 0

# --- Üretim ---
var produces: String          = ""
var inputs_needed: Dictionary = {}
var production_cycle_ms: float = 3000.0
var time_in_cycle_ms: float    = 0.0

# --- Efficiency ---
var efficiency: float           = 1.0
var _eff_success: int           = 0
var _eff_wait: int              = 0
var efficiency_history: Array[float] = []

# =============================================================================
func _ready() -> void:
	building_data    = GameData.get_building(building_key)
	max_hp           = building_data.get("hp", 5) * 10.0
	hp               = max_hp
	max_input_slots  = building_data.get("input_slots", 0)
	max_output_slots = building_data.get("output_slots", 0)
	produces         = building_data.get("produces", "")
	inputs_needed    = building_data.get("inputs", {})
	production_cycle_ms = float(building_data.get("production_cycle_ms", 3000))

	input_bins  = _empty_bins(max_input_slots)
	output_bins = _empty_bins(max_output_slots)

	z_index = 5  # zeminin üstünde
	queue_redraw()

func _empty_bins(size: int) -> Array:
	var a: Array = []
	for i in range(size): a.append(null)
	return a

# =============================================================================
# ÇİZİM (kod-sprite: kare + kod harfi + durum)
# =============================================================================

func _draw() -> void:
	var half := 14.0
	var body_color: Color = GameData.building_color(building_key)

	# İnşaat aşamasındaysa soluk göster
	if not is_constructed:
		body_color = body_color.darkened(0.5)

	# Bina gövdesi
	draw_rect(Rect2(-half, -half, half*2, half*2), body_color)
	draw_rect(Rect2(-half, -half, half*2, half*2), Color.BLACK, false, 2.0)

	# Kod harfi
	var code: String = building_data.get("code", "?")
	var font := ThemeDB.fallback_font
	var font_size := 16
	var text_size := font.get_string_size(code, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-text_size.x*0.5, text_size.y*0.35), code,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

	# İnşaat ilerleme çubuğu
	if not is_constructed:
		var bar_w := half * 2
		draw_rect(Rect2(-half, half+2, bar_w, 4), Color(0.2,0.2,0.2))
		draw_rect(Rect2(-half, half+2, bar_w*build_progress, 4), Color(0.3,0.9,0.3))
	else:
		# Output bin dolu sayısı (küçük yeşil noktalar)
		var filled := _count_output_filled()
		for i in range(min(filled, 8)):
			draw_circle(Vector2(-half + 3 + i*4, -half - 4), 1.5,
				GameData.resource_color(produces))

func _count_output_filled() -> int:
	var n := 0
	for s in output_bins:
		if s != null: n += 1
	return n

func count_output_filled() -> int:
	"""Public erişim — HUD bilgi panelinde kullanılır."""
	return _count_output_filled()

func count_input_filled() -> int:
	"""Public erişim — HUD bilgi panelinde kullanılır."""
	var n := 0
	for s in input_bins:
		if s != null: n += 1
	return n

# =============================================================================
# GÜNCELLEME (GameManager çağırır)
# =============================================================================

func update(delta_ms: float) -> void:
	if not is_constructed or produces == "":
		return
	time_in_cycle_ms += delta_ms
	if time_in_cycle_ms >= production_cycle_ms:
		time_in_cycle_ms = 0.0
		_attempt_production()

# =============================================================================
# ÜRETİM
# =============================================================================

func _attempt_production() -> void:
	if _output_full():
		_eff_wait += 1
		_update_efficiency()
		return
	if not inputs_needed.is_empty():
		if not _has_inputs():
			_eff_wait += 1
			_update_efficiency()
			return
		_consume_inputs()

	var res       = GameResource.new()
	res.resource_type = produces
	add_child(res)
	var idx = _add_to_output(res)
	res.place_in_bin(self, idx)

	_eff_success += 1
	_update_efficiency()
	queue_redraw()
	emit_signal("production_completed", self, produces)

func _output_full() -> bool:
	for s in output_bins:
		if s == null: return false
	return true

func _has_inputs() -> bool:
	for rtype in inputs_needed:
		var need = inputs_needed[rtype]
		var found = 0
		for s in input_bins:
			if s != null and s.resource_type == rtype:
				found += 1
		if found < need: return false
	return true

func _consume_inputs() -> void:
	for rtype in inputs_needed:
		var remaining = inputs_needed[rtype]
		for i in range(input_bins.size()):
			if remaining <= 0: break
			if input_bins[i] != null and input_bins[i].resource_type == rtype:
				input_bins[i].queue_free()
				input_bins[i] = null
				remaining -= 1

func _add_to_output(res: GameResource) -> int:
	for i in range(output_bins.size()):
		if output_bins[i] == null:
			output_bins[i] = res
			return i
	return -1

# =============================================================================
# BİN YÖNETİMİ (Robot'lar çağırır)
# =============================================================================

func add_to_input_bin(res: GameResource) -> int:
	for i in range(input_bins.size()):
		if input_bins[i] == null:
			input_bins[i] = res
			res.delivered_to_bin(self, i)
			_eff_success += 1
			_update_efficiency()
			return i
	return -1

func remove_from_output_bin(index: int) -> GameResource:
	if index < 0 or index >= output_bins.size(): return null
	var res = output_bins[index]
	if res != null:
		output_bins[index] = null
		res.pick_up_by_robot()
		queue_redraw()
	return res

func get_available_output() -> int:
	for i in range(output_bins.size()):
		if output_bins[i] != null: return i
	return -1

func has_input_space(_res_type: String) -> bool:
	for s in input_bins:
		if s == null: return true
	return false

# =============================================================================
# VERİMLİLİK
# =============================================================================

func _update_efficiency() -> void:
	var total = _eff_success + _eff_wait
	efficiency = 1.0 if total == 0 else float(_eff_success) / float(total)
	efficiency_history.push_front(efficiency)
	if efficiency_history.size() > 50: efficiency_history.pop_back()
	_eff_success = 0
	_eff_wait    = 0
	emit_signal("efficiency_changed", self, efficiency)

# =============================================================================
# HASAR / TAMİR / İNŞAAT
# =============================================================================

func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	if hp <= 0.0:
		emit_signal("building_destroyed", self)
		queue_free()

func repair(amount: float) -> void:
	hp = min(max_hp, hp + amount)

func complete_construction() -> void:
	is_constructed = true
	build_progress = 1.0
	queue_redraw()

func update_build_progress(p: float) -> void:
	build_progress = clamp(p, 0.0, 1.0)
	queue_redraw()
