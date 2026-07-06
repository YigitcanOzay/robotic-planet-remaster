# =============================================================================
# GameData.gd — Oyunun tüm sabit verileri
# Decompile edilmiş koddan çıkarılmıştır.
# =============================================================================

class_name GameData
extends Node

# --- KAYNAKLAR (12 TÜR) ---

const RESOURCES: Dictionary = {
	"water":          {"id":0,  "code":"W", "name":"Water"},
	"stone":          {"id":1,  "code":"S", "name":"Stone"},
	"crystal":        {"id":2,  "code":"C", "name":"Crystal"},
	"power":          {"id":3,  "code":"P", "name":"Power"},
	"iron":           {"id":4,  "code":"I", "name":"Iron"},
	"yellow_crystal": {"id":5,  "code":"Y", "name":"Yellow Crystal"},
	"energy":         {"id":6,  "code":"E", "name":"Energy"},
	"titanium":       {"id":7,  "code":"T", "name":"Titanium"},
	"fuel":           {"id":8,  "code":"F", "name":"Fuel"},
	"asphalt":        {"id":9,  "code":"A", "name":"Asphalt"},
	"uranium":        {"id":10, "code":"U", "name":"Uranium"},
	"metal":          {"id":11, "code":"M", "name":"Metal"},
}

# --- ROBOTLAR (4 TÜR) ---

const ROBOTS: Dictionary = {
	"worker": {
		"code":"G", "name":"Worker Robot",
		"speed":1.0, "capacity":0, "cycle_ticks":0,
		"build_time":25, "unlock_level":1,
		"sprite":"res://assets/sprites/units/worker.png"
	},
	"transporter": {
		"code":"B", "name":"Transporter",
		"speed":1.0, "capacity":1, "cycle_ticks":30,
		"build_time":30, "unlock_level":1,
		"sprite":"res://assets/sprites/units/transporter.png"
	},
	"heavy_transporter": {
		"code":"H", "name":"Heavy Transporter",
		"speed":2.0, "capacity":1, "cycle_ticks":10,
		"build_time":40, "unlock_level":3,
		"sprite":"res://assets/sprites/units/heavy_transporter.png"
	},
	"scout": {
		"code":"M", "name":"Scout",
		"speed":3.0, "capacity":0, "cycle_ticks":5,
		"build_time":20, "unlock_level":2,
		"sprite":"res://assets/sprites/units/scout.png"
	},
}

# --- MADENLER (5 TÜR) ---

const MINES: Dictionary = {
	"water_mine": {
		"code":"W", "name":"Water Mine", "hp":9,
		"produces":"water", "inputs":{},
		"output_slots":8, "input_slots":0,
		"production_cycle_ms":3000,
		"cost":{"stone":2,"metal":1},   # TODO: verify
		"build_time_s":12.0, "unlock_level":1,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/water_mine.png"
	},
	"stone_mine": {
		"code":"S", "name":"Stone Mine", "hp":8,
		"produces":"stone", "inputs":{},
		"output_slots":8, "input_slots":0,
		"production_cycle_ms":3000,
		"cost":{"metal":2},             # TODO: verify
		"build_time_s":10.0, "unlock_level":1,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/stone_mine.png"
	},
	"iron_mine": {
		"code":"I", "name":"Iron Mine", "hp":8,
		"produces":"iron", "inputs":{},
		"output_slots":8, "input_slots":0,
		"production_cycle_ms":3000,
		"cost":{"metal":3,"stone":2},   # TODO: verify
		"build_time_s":12.0, "unlock_level":1,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/iron_mine.png"
	},
	"yellow_crystal_mine": {
		"code":"Y", "name":"Yellow Crystal Mine", "hp":8,
		"produces":"yellow_crystal", "inputs":{},
		"output_slots":6, "input_slots":0,
		"production_cycle_ms":3000,
		"cost":{"metal":4,"stone":3},   # TODO: verify
		"build_time_s":15.0, "unlock_level":2,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/yellow_crystal_mine.png"
	},
	"power_mine": {
		"code":"F", "name":"Power Mine", "hp":6,
		"produces":"power", "inputs":{},
		"output_slots":6, "input_slots":0,
		"production_cycle_ms":3000,
		"cost":{"metal":3,"stone":2},   # TODO: verify
		"build_time_s":12.0, "unlock_level":1,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/power_mine.png"
	},
}

# --- FABRİKALAR / İSTASYONLAR (7 TÜR) ---

const FACTORIES: Dictionary = {
	"metal_factory": {
		"code":"M", "name":"Metal Factory", "hp":6,
		"produces":"metal", "inputs":{"iron":1,"fuel":1},
		"output_slots":4, "input_slots":8,
		"production_cycle_ms":3000,
		"cost":{"stone":5,"iron":3},    # TODO: verify
		"build_time_s":20.0, "unlock_level":5,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/metal_factory.png"
	},
	"energy_station": {
		"code":"E", "name":"Energy Station", "hp":6,
		"produces":"energy", "inputs":{"crystal":1,"iron":1},
		"output_slots":4, "input_slots":8,
		"production_cycle_ms":3000,
		"cost":{"metal":4,"stone":3},   # TODO: verify
		"build_time_s":18.0, "unlock_level":2,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/energy_station.png"
	},
	"fuel_station": {
		"code":"R", "name":"Fuel Station", "hp":6,
		"produces":"fuel", "inputs":{"power":1},
		"output_slots":4, "input_slots":6,
		"production_cycle_ms":3000,
		"cost":{"metal":3,"stone":2},   # TODO: verify
		"build_time_s":15.0, "unlock_level":2,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/fuel_station.png"
	},
	"uranium_station": {
		"code":"U", "name":"Uranium Station", "hp":6,
		"produces":"uranium", "inputs":{"crystal":1,"titanium":1},
		"output_slots":2, "input_slots":6,
		"production_cycle_ms":3000,
		"cost":{"metal":8,"stone":5},   # TODO: verify
		"build_time_s":25.0, "unlock_level":5,
		"destruction_return":0.20,
		"sprite":"res://assets/sprites/buildings/uranium_station.png"
	},
	"crystal_station": {
		"code":"C", "name":"Crystal Station", "hp":6,
		"produces":"crystal", "inputs":{"stone":1},
		"output_slots":4, "input_slots":6,
		"production_cycle_ms":3000,
		"cost":{"metal":4,"stone":4},   # TODO: verify
		"build_time_s":16.0, "unlock_level":2,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/crystal_station.png"
	},
	"titanium_station": {
		"code":"T", "name":"Titanium Station", "hp":6,
		"produces":"titanium", "inputs":{"iron":1,"fuel":1},
		"output_slots":4, "input_slots":8,
		"production_cycle_ms":3000,
		"cost":{"metal":6,"stone":4},   # TODO: verify
		"build_time_s":20.0, "unlock_level":3,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/titanium_station.png"
	},
	"asphalt_station": {
		"code":"A", "name":"Asphalt Station", "hp":6,
		"produces":"asphalt", "inputs":{"stone":1,"fuel":1},
		"output_slots":4, "input_slots":6,
		"production_cycle_ms":3000,
		"cost":{"metal":3,"stone":3},   # TODO: verify
		"build_time_s":15.0, "unlock_level":6,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/asphalt_station.png"
	},
}

# --- ÖZEL YAPILAR ---

const SPECIAL_BUILDINGS: Dictionary = {
	"storage": {
		"code":"L", "name":"Storage", "hp":10,
		"produces":"", "inputs":{},
		"output_slots":0, "input_slots":16,
		"cost":{"metal":5,"stone":5},   # TODO: verify
		"build_time_s":18.0, "unlock_level":1,
		"destruction_return":0.33,
		"sprite":"res://assets/sprites/buildings/storage.png"
	},
	"research_lab": {
		"code":"D", "name":"Research Lab", "hp":7,
		"produces":"tech", "inputs":{},
		"output_slots":0, "input_slots":4,
		"cost":{"metal":8,"crystal":2}, # TODO: verify
		"build_time_s":24.0, "unlock_level":6,
		"destruction_return":0.20,
		"sprite":"res://assets/sprites/buildings/research_lab.png"
	},
	"hq": {
		"code":"HQ", "name":"Headquarters", "hp":20,
		"produces":"", "inputs":{},
		"output_slots":0, "input_slots":0,
		"cost":{}, "build_time_s":0.0,
		"unlock_level":0, "destruction_return":0.0,
		"sprite":"res://assets/sprites/buildings/hq.png"
	},
}

# --- YARDIMCI FONKSİYONLAR ---

static func get_building(key: String) -> Dictionary:
	if key in MINES:    return MINES[key]
	if key in FACTORIES: return FACTORIES[key]
	if key in SPECIAL_BUILDINGS: return SPECIAL_BUILDINGS[key]
	return {}

static func get_all_buildings() -> Dictionary:
	var all := {}
	all.merge(MINES)
	all.merge(FACTORIES)
	all.merge(SPECIAL_BUILDINGS)
	return all

# --- MEKANİKLER ---

const MECHANICS: Dictionary = {
	"production_cycle_ms": 3000,
	"efficiency_history_buffer": 50,
	"build_return_standard": 0.33,
	"build_return_special": 0.20,
	"map_min_size": 32,
	"map_max_size": 76,
	"map_default_size": 56,
	"speed_options": [0.0, 1.0, 2.0, 4.0],
}

# --- KİLİT AÇMA ---

const UNLOCKS: Dictionary = {
	1: ["stone_mine","iron_mine","water_mine","power_mine","storage","worker","transporter"],
	2: ["yellow_crystal_mine","energy_station","fuel_station","crystal_station","scout"],
	3: ["titanium_station","heavy_transporter"],
	5: ["metal_factory","uranium_station"],
	6: ["asphalt_station","research_lab"],
}

static func get_unlocked_at_level(level: int) -> Array:
	var result: Array = []
	for lvl in UNLOCKS:
		if lvl <= level:
			result.append_array(UNLOCKS[lvl])
	return result

# --- KAYNAK RENKLERİ (kod-çizim sprite'lar için) ---

const RESOURCE_COLORS: Dictionary = {
	"water":          Color(0.30, 0.60, 0.95),
	"stone":          Color(0.55, 0.55, 0.55),
	"crystal":        Color(0.60, 0.30, 0.85),
	"power":          Color(0.95, 0.85, 0.20),
	"iron":           Color(0.75, 0.45, 0.30),
	"yellow_crystal": Color(0.90, 0.90, 0.20),
	"energy":         Color(0.20, 0.90, 0.90),
	"titanium":       Color(0.80, 0.80, 0.85),
	"fuel":           Color(0.90, 0.50, 0.15),
	"asphalt":        Color(0.25, 0.25, 0.25),
	"uranium":        Color(0.40, 0.90, 0.30),
	"metal":          Color(0.65, 0.70, 0.80),
	"tech":           Color(0.90, 0.40, 0.60),
}

static func resource_color(res_type: String) -> Color:
	return RESOURCE_COLORS.get(res_type, Color.WHITE)

# --- BİNA KATEGORİ RENKLERİ ---

const BUILDING_CATEGORY_COLORS: Dictionary = {
	"mine":    Color(0.45, 0.35, 0.25),  # kahve - madenler
	"factory": Color(0.30, 0.35, 0.50),  # mavi-gri - fabrikalar
	"special": Color(0.50, 0.45, 0.20),  # hardal - özel
	"hq":      Color(0.70, 0.15, 0.15),  # kırmızı - HQ
}

static func building_category(building_key: String) -> String:
	if building_key in MINES:            return "mine"
	if building_key in FACTORIES:        return "factory"
	if building_key == "hq":             return "hq"
	return "special"

static func building_color(building_key: String) -> Color:
	return BUILDING_CATEGORY_COLORS.get(building_category(building_key), Color.GRAY)
