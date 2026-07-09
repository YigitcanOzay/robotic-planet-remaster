# =============================================================================
# LevelData.gd — Level/Dünya tanımları (level select ekranı için)
# Oyun mekaniği verisi DEĞİL — UI katmanı verisi. GameData.gd'den ayrı tutulur.
# =============================================================================

class_name LevelData
extends Node

# Her level: id, isim, açıklama, unlocked (şimdilik hepsi statik açık/kilitli)
# İleride: save dosyasından "tamamlandı mı" bilgisi okunacak
const LEVELS: Array[Dictionary] = [
	{
		"id": "world_1",
		"name": "Dünya 1",
		"description": "Başlangıç — Temel madencilik",
		"scene": "res://scenes/game/main_game.tscn",
		"unlocked": true,
	},
	{
		"id": "world_2",
		"name": "Dünya 2",
		"description": "Kilitli — Dünya 1'i tamamla",
		"scene": "res://scenes/game/main_game.tscn",
		"unlocked": false,
	},
	{
		"id": "world_3",
		"name": "Dünya 3",
		"description": "Kilitli — Dünya 2'yi tamamla",
		"scene": "res://scenes/game/main_game.tscn",
		"unlocked": false,
	},
]

static func get_level(id: String) -> Dictionary:
	for lvl in LEVELS:
		if lvl["id"] == id:
			return lvl
	return {}
