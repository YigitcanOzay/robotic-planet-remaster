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

func place_in_bin(building, bin_index: int) -> void:
	owner_building    = building
	current_bin_index = bin_index
	is_in_bin         = true
	visible           = false

func pick_up_by_robot() -> void:
	owner_building    = null
	current_bin_index = -1
	is_in_bin         = false
	visible           = true

func delivered_to_bin(building, bin_index: int) -> void:
	place_in_bin(building, bin_index)
