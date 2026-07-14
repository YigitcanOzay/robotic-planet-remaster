# =============================================================================
# HUD.gd — Üst kaynak sayaçları + alt hız/bina butonları + yerleştirme
# CanvasLayer node'una bağlanır.
# =============================================================================

extends CanvasLayer

var game_manager: Node = null
var building_manager: BuildingManager = null
var unit_manager: UnitManager = null
var map_system: MapSystem = null
var camera: Camera2D = null

# Seçim durumu
var selected_building: Building = null
var selected_robot: Robot = null
var info_panel: PanelContainer = null
var info_label: Label = null
const ROBOT_SELECT_RADIUS: float = 24.0  # px, dünya koordinatında

# UI referansları
var resource_label: Label
var speed_label: Label
var status_label: Label
var debug_label: Label   # GEÇİCİ: input teşhisi için, sorun çözülünce kaldırılacak
var debug_label2: Label  # GEÇİCİ: DisplayServer/Input singleton teşhisi
var _frame_count: int = 0
var _input_event_seen: bool = false

# Yerleştirme durumu
var placing_key: String = ""   # "" ise yerleştirme kapalı

# Yol döşeme modu
var road_mode: bool = false
var road_first_point: Vector2i = Vector2i(-1, -1)  # -1,-1 = henüz ilk nokta seçilmedi

# Alt menüde gösterilecek binalar (test için 4 tane)
const PLACEABLE := ["stone_mine", "iron_mine", "fuel_station", "metal_factory"]

# =============================================================================
func _ready() -> void:
	game_manager = get_parent()
	building_manager = game_manager.get_node_or_null("BuildingManager")
	unit_manager = game_manager.get_node_or_null("UnitManager")
	map_system = game_manager.get_node_or_null("MapSystem")
	camera = game_manager.get_node_or_null("Camera2D")
	_build_ui()

func _process(_delta: float) -> void:
	_update_resource_label()
	_update_info_panel()
	_frame_count += 1
	if not _input_event_seen:
		debug_label.text = "input: henüz event yok | frame=%d" % _frame_count

	# GEÇİCİ: Input singleton'ının gerçek zamanlı durumu (event log'dan bağımsız)
	if debug_label2:
		var mp = get_viewport().get_mouse_position()
		var mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		debug_label2.text = "mouse_pos=%s | mouse_down=%s" % [mp, mouse_down]

# =============================================================================
# UI OLUŞTUR
# =============================================================================

func _build_ui() -> void:
	# --- Üst kaynak paneli ---
	var top = PanelContainer.new()
	top.position = Vector2(10, 10)
	top.custom_minimum_size = Vector2(400, 40)
	add_child(top)
	resource_label = Label.new()
	resource_label.text = "Kaynaklar yükleniyor..."
	resource_label.add_theme_font_size_override("font_size", 20)
	top.add_child(resource_label)

	# --- Ana menüye dönüş butonu (sağ üst) ---
	var menu_btn = Button.new()
	menu_btn.text = "☰ Menü"
	menu_btn.position = Vector2(950, 10)
	menu_btn.custom_minimum_size = Vector2(140, 50)
	menu_btn.add_theme_font_size_override("font_size", 20)
	menu_btn.pressed.connect(_on_menu_pressed)
	add_child(menu_btn)

	# --- GEÇİCİ: input teşhis etiketi ---
	debug_label = Label.new()
	debug_label.text = "input: (henüz yok)"
	debug_label.position = Vector2(10, 100)
	debug_label.add_theme_font_size_override("font_size", 22)
	debug_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	add_child(debug_label)

	# --- GEÇİCİ: DisplayServer/Input singleton teşhis etiketi ---
	debug_label2 = Label.new()
	debug_label2.text = "DisplayServer: (henüz yok)"
	debug_label2.position = Vector2(10, 140)
	debug_label2.add_theme_font_size_override("font_size", 20)
	debug_label2.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	add_child(debug_label2)

	# --- Durum etiketi (yerleştirme modu) ---
	status_label = Label.new()
	status_label.position = Vector2(10, 60)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	add_child(status_label)

	# --- Alt panel: hız + bina butonları ---
	var bottom = HBoxContainer.new()
	bottom.position = Vector2(10, 1750)
	bottom.add_theme_constant_override("separation", 8)
	add_child(bottom)

	# Hız butonları
	_add_button(bottom, "⏸", func(): game_manager.toggle_pause())
	_add_button(bottom, "×1", func(): game_manager.set_speed(1.0))
	_add_button(bottom, "×2", func(): game_manager.set_speed(2.0))
	_add_button(bottom, "×4", func(): game_manager.set_speed(4.0))

	# Zoom butonları (pinch mouse ile çalışmadığı için yedek kontrol)
	_add_button(bottom, "🔍+", func(): _zoom_camera(1.2))
	_add_button(bottom, "🔍-", func(): _zoom_camera(1.0 / 1.2))

	speed_label = Label.new()
	speed_label.text = "  ×1  "
	speed_label.add_theme_font_size_override("font_size", 20)
	bottom.add_child(speed_label)

	# Hız değişince etiket güncelle
	if game_manager.has_signal("game_speed_changed"):
		game_manager.game_speed_changed.connect(_on_speed_changed)

	# --- Bina butonları (ikinci sıra) ---
	var build_row = HBoxContainer.new()
	build_row.position = Vector2(10, 1820)
	build_row.add_theme_constant_override("separation", 8)
	add_child(build_row)

	for key in PLACEABLE:
		var data = GameData.get_building(key)
		var label_text = data.get("code", "?")
		_add_build_button(build_row, label_text, key)

	# Yol döşeme butonu
	var road_btn = Button.new()
	road_btn.text = "YOL"
	road_btn.custom_minimum_size = Vector2(90, 70)
	road_btn.add_theme_font_size_override("font_size", 24)
	road_btn.pressed.connect(_toggle_road_mode)
	build_row.add_child(road_btn)

	# --- Bilgi paneli (sağda, seçim yokken gizli) ---
	info_panel = PanelContainer.new()
	info_panel.position = Vector2(680, 10)
	info_panel.custom_minimum_size = Vector2(380, 220)
	info_panel.visible = false
	add_child(info_panel)

	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 4)
	info_panel.add_child(panel_vbox)

	var close_btn = Button.new()
	close_btn.text = "✕ Kapat"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(func(): _clear_selection())
	panel_vbox.add_child(close_btn)

	info_label = Label.new()
	info_label.text = ""
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel_vbox.add_child(info_label)

# =============================================================================
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _zoom_camera(factor: float) -> void:
	if camera and camera.has_method("zoom_by"):
		camera.zoom_by(factor)

func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(70, 60)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(callback)
	parent.add_child(b)

func _add_build_button(parent: Node, text: String, key: String) -> void:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(70, 70)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(func(): _start_placing(key))
	parent.add_child(b)

# =============================================================================
# YERLEŞTİRME
# =============================================================================

func _start_placing(key: String) -> void:
	placing_key = key
	road_mode = false  # yol modundaysak kapat
	var data = GameData.get_building(key)
	status_label.text = "Yerleştir: %s — haritaya dokun (iptal: tekrar bas)" % data.get("name", key)

# =============================================================================
# YOL DÖŞEME
# =============================================================================

func _toggle_road_mode() -> void:
	road_mode = not road_mode
	placing_key = ""  # yerleştirme modunu kapat
	road_first_point = Vector2i(-1, -1)
	if road_mode:
		status_label.text = "[YOL] Yol modu: 1. noktaya dokun (kapat: tekrar YOL)"
	else:
		status_label.text = "Yol modu kapalı"

func _handle_road_tap(screen_pos: Vector2) -> void:
	if camera == null or map_system == null:
		return
	var world = camera.position + (screen_pos - get_viewport().get_visible_rect().size * 0.5) / camera.zoom
	var grid = map_system.world_to_grid(world)

	if not map_system._in_bounds(grid):
		status_label.text = "[YOL] Harita dışı, tekrar dokun"
		return

	if road_first_point == Vector2i(-1, -1):
		# İlk nokta seçildi
		road_first_point = grid
		status_label.text = "[YOL] 1. nokta seçildi %s — 2. noktaya dokun" % str(grid)
	else:
		# İkinci nokta → aradaki yolu döşe
		var road_tiles = map_system.find_road_path(road_first_point, grid)
		if road_tiles.is_empty():
			status_label.text = "[YOL] Yol bulunamadı (engellerle çevrili), tekrar dene"
			road_first_point = Vector2i(-1, -1)
			return
		var laid = 0
		for tile in road_tiles:
			if _lay_road_tile(tile):
				laid += 1
		# Yol tamamlandı → modu otomatik kapat (yeni yol için tekrar YOL'a basılır)
		road_mode = false
		road_first_point = Vector2i(-1, -1)
		status_label.text = "[YOL] %d tile döşendi, yol modu kapandı" % laid

func _lay_road_tile(grid: Vector2i) -> bool:
	"""Tek bir tile'ı ROAD yapar. Bina/HQ üzerine yazmaz. Döşendiyse true."""
	var t = map_system.get_tile(grid)
	if t == MapSystem.TileType.BUILDING or t == MapSystem.TileType.HQ:
		return false
	map_system.set_tile(grid, MapSystem.TileType.ROAD)
	return true

func _input(event: InputEvent) -> void:
	# GEÇİCİ: hangi event tiplerinin geldiğini teşhis et
	if event is InputEventScreenTouch:
		_input_event_seen = true
		debug_label.text = "input: SCREEN_TOUCH pressed=%s pos=%s" % [event.pressed, event.position]
	elif event is InputEventScreenDrag:
		_input_event_seen = true
		debug_label.text = "input: SCREEN_DRAG pos=%s rel=%s" % [event.position, event.relative]
	elif event is InputEventMouseButton:
		_input_event_seen = true
		debug_label.text = "input: MOUSE_BUTTON pressed=%s pos=%s" % [event.pressed, event.position]
	elif event is InputEventMouseMotion:
		_input_event_seen = true
		debug_label.text = "input: MOUSE_MOTION pos=%s" % [event.position]

	# Yol döşeme modu (yerleştirme ve seçimden ÖNCE ele alınır)
	if road_mode:
		var touch_pos = Vector2.ZERO
		var is_tap = false
		if event is InputEventScreenTouch and event.pressed:
			touch_pos = event.position; is_tap = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			touch_pos = event.position; is_tap = true
		if is_tap:
			# Alt buton bölgesine (hız/bina/yol butonları) denk geliyorsa yol işleme,
			# butonların çalışmasına izin ver (yol modundan çıkabilmek için şart)
			if touch_pos.y < 1740:
				_handle_road_tap(touch_pos)
				get_viewport().set_input_as_handled()
		return

	if placing_key == "":
		# Yerleştirme modu kapalı → tıklama SEÇİM için kullanılır
		if event is InputEventScreenTouch and event.pressed:
			_try_select_at_screen(event.position)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_try_select_at_screen(event.position)
		return
	# Ekrana dokunma → grid pozisyonuna bina koy (gerçek touch ortamı)
	if event is InputEventScreenTouch and event.pressed:
		_try_place_at_screen(event.position)
		get_viewport().set_input_as_handled()  # kamera bu dokunuşu görmesin
	# YEDEK: mouse click (legacy Android export'ta touch, mouse'a çevriliyor)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_at_screen(event.position)
		get_viewport().set_input_as_handled()

func _try_place_at_screen(screen_pos: Vector2) -> void:
	if camera == null or map_system == null:
		return
	# Ekran → dünya koordinatı
	var world = camera.position + (screen_pos - get_viewport().get_visible_rect().size * 0.5) / camera.zoom
	var grid = map_system.world_to_grid(world)

	if building_manager.can_place(placing_key, grid):
		building_manager.place_building(placing_key, grid, 0)
		status_label.text = "Kuruldu: %s" % placing_key
		placing_key = ""
	else:
		status_label.text = "Buraya kurulamaz, başka yere dokun"

# =============================================================================
# SEÇİM (bina / robot bilgi paneli)
# =============================================================================

func _try_select_at_screen(screen_pos: Vector2) -> void:
	if camera == null or map_system == null:
		return
	var world = camera.position + (screen_pos - get_viewport().get_visible_rect().size * 0.5) / camera.zoom

	# Önce bina var mı diye bak (grid-hizalı)
	var grid = map_system.world_to_grid(world)
	var b = map_system.get_building_at(grid)
	if b != null:
		_select_building(b)
		return

	# Bina yoksa en yakın robotu ara (serbest pozisyon)
	var nearest = _find_nearest_robot(world)
	if nearest != null:
		_select_robot(nearest)
		return

	# Hiçbiri değilse seçimi temizle
	_clear_selection()

func _find_nearest_robot(world_pos: Vector2) -> Robot:
	if unit_manager == null:
		return null
	var best: Robot = null
	var best_dist = ROBOT_SELECT_RADIUS
	for r in unit_manager.robots:
		if not is_instance_valid(r):
			continue
		var d = r.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = r
	return best

func _select_building(b: Building) -> void:
	selected_building = b
	selected_robot = null
	info_panel.visible = true

func _select_robot(r: Robot) -> void:
	selected_robot = r
	selected_building = null
	info_panel.visible = true

func _clear_selection() -> void:
	selected_building = null
	selected_robot = null
	info_panel.visible = false

func _update_info_panel() -> void:
	if selected_building != null:
		if not is_instance_valid(selected_building):
			_clear_selection()
			return
		info_label.text = _format_building_info(selected_building)
	elif selected_robot != null:
		if not is_instance_valid(selected_robot):
			_clear_selection()
			return
		info_label.text = _format_robot_info(selected_robot)

func _format_building_info(b: Building) -> String:
	var lines: Array = []
	lines.append("🏭 %s" % b.building_data.get("name", b.building_key))
	lines.append("HP: %.0f / %.0f" % [b.hp, b.max_hp])
	lines.append("Durum: %s" % _building_status_text(b))
	if b.produces != "":
		lines.append("Üretim: %s" % b.produces)
		lines.append("Verimlilik: %d%%" % int(b.efficiency * 100))
		lines.append("Çıkış bin: %d / %d dolu" % [b.count_output_filled(), b.max_output_slots])
	if not b.inputs_needed.is_empty():
		lines.append("Girdi bin: %d / %d dolu" % [b.count_input_filled(), b.max_input_slots])
		var needs: Array = []
		for k in b.inputs_needed:
			needs.append(k)
		lines.append("Gereken: %s" % ", ".join(needs))
	return "\n".join(lines)

func _format_robot_info(r: Robot) -> String:
	var lines: Array = []
	var type_name = r.robot_data.get("name", r.robot_type)
	lines.append("🤖 %s" % type_name)
	if r.is_blocked:
		lines.append("Durum: 🚧 Yol yok, bekliyor")
	else:
		lines.append("Durum: %s" % _robot_state_text(r.state))
	if r.robot_type != "build":
		if r.has_cargo():
			lines.append("Taşıyor: %s" % r.get_cargo_type())
		else:
			lines.append("Taşıyor: (boş)")
	return "\n".join(lines)

func _building_status_text(b: Building) -> String:
	if b.is_constructed:
		return "Aktif"
	if b.construction_started:
		return "İnşa ediliyor (%d%%)" % int(b.build_progress * 100)
	return "⏳ İşçi bekleniyor"

func _robot_state_text(state: int) -> String:
	match state:
		Robot.State.IDLE: return "Boşta"
		Robot.State.MOVING_TO_PICKUP: return "Kaynağa gidiyor"
		Robot.State.PICKING_UP: return "Kaynak alıyor"
		Robot.State.MOVING_TO_DROPOFF: return "Teslimata gidiyor"
		Robot.State.DROPPING_OFF: return "Teslim ediyor"
		Robot.State.MOVING_TO_CONSTRUCT: return "İnşaat alanına gidiyor"
		Robot.State.CONSTRUCTING: return "İnşa ediyor"
		_: return "?"

# =============================================================================
# GÜNCELLEME
# =============================================================================

func _update_resource_label() -> void:
	if building_manager == null:
		return
	var totals = building_manager.count_resources(0)
	if totals.is_empty():
		resource_label.text = "Kaynak yok (robotlar taşıyınca artar)"
		return
	var parts: Array = []
	for res_type in totals:
		var code = GameData.RESOURCES.get(res_type, {}).get("code", "?")
		parts.append("%s:%d" % [code, totals[res_type]])
	resource_label.text = "  ".join(parts)

func _on_speed_changed(mult: float) -> void:
	speed_label.text = "  ×%s  " % str(mult)
