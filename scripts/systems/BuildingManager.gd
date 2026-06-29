# =============================================================================
# BuildingManager.gd — Bina yerleştirme ve inşaat yönetimi
# =============================================================================

class_name BuildingManager
extends Node

signal building_placed(building: Building)
signal building_completed(building: Building)
signal building_destroyed(building: Building)

var map_system: MapSystem = null
var buildings: Array[Building] = []
var construction_queue: Array[Dictionary] = []
var player_hq: Building = null
var ai_hq: Building     = null

# =============================================================================
func can_place(building_key: String, grid_pos: Vector2i) -> bool:
	if map_system == null: return false
	if GameData.get_building(building_key).is_empty(): return false
	if not map_system.is_buildable(grid_pos): return false
	if map_system.get_building_at(grid_pos) != null: return false
	return true

func place_building(building_key: String, grid_pos: Vector2i, player: int) -> Building:
	if not can_place(building_key, grid_pos): return null

	var b              = Building.new()
	b.building_key     = building_key
	b.owner_player     = player
	b.grid_position    = grid_pos
	b.is_constructed   = false

	get_parent().add_child(b)
	b.global_position = map_system.grid_to_world(grid_pos)
	buildings.append(b)
	map_system.place_building_tiles(grid_pos, b)

	if building_key == "hq":
		if player == 0: player_hq = b
		else:           ai_hq     = b

	construction_queue.append({
		"building":   b,
		"build_time": GameData.get_building(building_key).get("build_time_s", 10.0),
		"elapsed":    0.0,
	})

	b.building_destroyed.connect(_on_building_destroyed)
	emit_signal("building_placed", b)
	return b

# =============================================================================
func update(delta: float) -> void:
	_update_construction(delta)
	_update_production(delta)

func _update_construction(delta: float) -> void:
	var done: Array = []
	for entry in construction_queue:
		entry["elapsed"] += delta
		var b: Building = entry["building"]
		var progress = entry["elapsed"] / entry["build_time"]
		b.update_build_progress(progress)
		if progress >= 1.0:
			b.complete_construction()
			done.append(entry)
			emit_signal("building_completed", b)
	for e in done: construction_queue.erase(e)

func _update_production(delta: float) -> void:
	var delta_ms = delta * 1000.0
	for b in buildings:
		if b.is_constructed: b.update(delta_ms)

# =============================================================================
func get_player_hq() -> Building:
	return player_hq if is_instance_valid(player_hq) else null

func get_ai_hq() -> Building:
	return ai_hq if is_instance_valid(ai_hq) else null

func get_buildings_producing(resource_type: String) -> Array[Building]:
	var result: Array[Building] = []
	for b in buildings:
		if b.is_constructed and b.produces == resource_type:
			result.append(b)
	return result

func get_buildings_needing_input(resource_type: String) -> Array[Building]:
	var result: Array[Building] = []
	for b in buildings:
		if b.is_constructed and resource_type in b.inputs_needed:
			if b.has_input_space(resource_type):
				result.append(b)
	return result

func get_nearest_with_output(pos: Vector2, player: int) -> Dictionary:
	var best_dist = INF
	var best_b: Building = null
	var best_bin: int    = -1
	for b in buildings:
		if b.owner_player != player or not b.is_constructed: continue
		var idx = b.get_available_output()
		if idx == -1: continue
		var d = b.global_position.distance_to(pos)
		if d < best_dist:
			best_dist = d; best_b = b; best_bin = idx
	return {"building": best_b, "bin": best_bin}

func _on_building_destroyed(building: Building) -> void:
	buildings.erase(building)
	if building == player_hq: player_hq = null
	if building == ai_hq:     ai_hq     = null
	map_system.remove_building_tiles(building.grid_position)
	emit_signal("building_destroyed", building)
