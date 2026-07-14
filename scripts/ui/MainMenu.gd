# =============================================================================
# MainMenu.gd — Ana ekran: Start Game / Continue / Settings
# =============================================================================

extends Control

const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"

var has_save: bool = false  # TODO: Aşama 2'de gerçek save kontrolü eklenecek

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Arkaplan
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(340, 700)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Başlık
	var title = Label.new()
	title.text = "ROBOTIC PLANET\nREMASTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# Start Game
	var start_btn = Button.new()
	start_btn.text = "OYNA"
	start_btn.custom_minimum_size = Vector2(0, 80)
	start_btn.add_theme_font_size_override("font_size", 28)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	# Continue (Aşama 2'ye kadar pasif)
	var continue_btn = Button.new()
	continue_btn.text = "DEVAM ET"
	continue_btn.custom_minimum_size = Vector2(0, 70)
	continue_btn.add_theme_font_size_override("font_size", 24)
	continue_btn.disabled = not has_save
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)

	# Settings (placeholder)
	var settings_btn = Button.new()
	settings_btn.text = "AYARLAR"
	settings_btn.custom_minimum_size = Vector2(0, 70)
	settings_btn.add_theme_font_size_override("font_size", 24)
	settings_btn.disabled = true  # TODO: Aşama 3+
	vbox.add_child(settings_btn)

	# Versiyon bilgisi (sağ alt köşe)
	var version_label = Label.new()
	version_label.text = "v0.6.4"
	version_label.position = Vector2(950, 1850)
	version_label.add_theme_font_size_override("font_size", 16)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(version_label)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

func _on_continue_pressed() -> void:
	# TODO: Aşama 2 — son kayıttan devam et
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
