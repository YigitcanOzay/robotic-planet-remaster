# =============================================================================
# LevelSelect.gd — Dünya/Level seçim ekranı
# 3 dünya ikonu, kilitli olanlar tıklanamaz ve gri gösterilir.
# =============================================================================

extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Üst bar: geri butonu + başlık ---
	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	top_bar.add_theme_constant_override("separation", 20)
	add_child(top_bar)

	var back_btn = Button.new()
	back_btn.text = "← Geri"
	back_btn.custom_minimum_size = Vector2(120, 60)
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	top_bar.add_child(back_btn)

	var title = Label.new()
	title.text = "DÜNYA SEÇ"
	title.add_theme_font_size_override("font_size", 32)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(title)

	# --- Level ikonları (dikey liste, mobil için) ---
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(140, 180)
	vbox.custom_minimum_size = Vector2(800, 0)
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	for level in LevelData.LEVELS:
		_add_level_card(vbox, level)

	# --- Alt: Mission Code butonu (placeholder, ileride eklenecek) ---
	var mission_code_btn = Button.new()
	mission_code_btn.text = "🔑 Mission Code Gir"
	mission_code_btn.custom_minimum_size = Vector2(800, 70)
	mission_code_btn.position = Vector2(140, 1780)
	mission_code_btn.add_theme_font_size_override("font_size", 22)
	mission_code_btn.disabled = true  # TODO: ileride eklenecek
	add_child(mission_code_btn)

func _add_level_card(parent: Node, level: Dictionary) -> void:
	var card = Button.new()
	card.custom_minimum_size = Vector2(800, 140)
	card.disabled = not level["unlocked"]
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if level["unlocked"]:
		card.pressed.connect(func(): _on_level_selected(level))
	parent.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # tıklamalar Button'a geçsin
	card.add_child(hbox)

	# İkon (basit renkli kare, sprite yok henüz)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(100, 100)
	icon.color = Color(0.3, 0.6, 0.3) if level["unlocked"] else Color(0.3, 0.3, 0.3)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = level["name"]
	name_label.add_theme_font_size_override("font_size", 26)
	if not level["unlocked"]:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = level["description"]
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(desc_label)

	if not level["unlocked"]:
		var lock_label = Label.new()
		lock_label.text = "🔒 Kilitli"
		lock_label.add_theme_font_size_override("font_size", 18)
		lock_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		info_vbox.add_child(lock_label)

func _on_level_selected(level: Dictionary) -> void:
	get_tree().change_scene_to_file(level["scene"])
