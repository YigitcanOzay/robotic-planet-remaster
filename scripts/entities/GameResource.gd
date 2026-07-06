# =============================================================================
# GameResource.gd — Fiziksel kaynak nesnesi
# NOT: "Resource" Godot native class ile çakışır → GameResource kullanıyoruz
# =============================================================================

class_name GameResource
extends Node2D

var resource_type: String = ""
var is_in_bin: bool = false
var current_bin_index: int = -1
var owner_building = null

func _ready() -> void:
	visible = false  # bin içindeyken görünmez

func _draw() -> void:
	# Robot taşırken görünür: küçük renkli kare
	if visible:
		var col = GameData.resource_color(resource_type)
		draw_rect(Rect2(-5, -5, 10, 10), col)
		draw_rect(Rect2(-5, -5, 10, 10), Color.BLACK, false, 1.0)

func place_in_bin(building, bin_index: int) -> void:
	owner_building    = building
	current_bin_index = bin_index
	is_in_bin         = true
	visible           = false
	queue_redraw()

func pick_up_by_robot() -> void:
	owner_building    = null
	current_bin_index = -1
	is_in_bin         = false
	visible           = true
	queue_redraw()

func delivered_to_bin(building, bin_index: int) -> void:
	place_in_bin(building, bin_index)
