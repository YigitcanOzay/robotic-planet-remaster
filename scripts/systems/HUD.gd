# =============================================================================
# HUD.gd — Üst kaynak sayaçları + alt hız/bina butonları + yerleştirme
# CanvasLayer node'una bağlanır.
# =============================================================================

extends CanvasLayer

var game_manager: Node = null
var building_manager: BuildingManager = null
var map_system: MapSystem = null
var camera: Camera2D = null

# UI referansları
var resource_label: Label
var speed_label: Label
var status_label: Label

# Yerleştirme durumu
var placing_key: String = ""   # "" ise yerleştirme kapalı

# Alt menüde gösterilecek binalar (test için 4 tane)
const PLACEABLE := ["stone_mine", "iron_mine", "fuel_station", "metal_factory"]

# =============================================================================
func _ready() -> void:
	game_manager = get_parent()
	building_manager = game_manager.get_node_or_null("BuildingManager")
	map_system = game_manager.get_node_or_null("MapSystem")
	camera = game_manager.get_node_or_null("Camera2D")
	_build_ui()

func _process(_delta: float) -> void:
	_update_resource_label()

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

# =============================================================================
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
	var data = GameData.get_building(key)
	status_label.text = "Yerleştir: %s — haritaya dokun (iptal: tekrar bas)" % data.get("name", key)

func _input(event: InputEvent) -> void:
	if placing_key == "":
		return
	# Ekrana dokunma → grid pozisyonuna bina koy
	if event is InputEventScreenTouch and event.pressed:
		_try_place_at_screen(event.position)
		get_viewport().set_input_as_handled()  # kamera bu dokunuşu görmesin

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
