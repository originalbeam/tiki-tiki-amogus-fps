class_name WeaponModDB
extends RefCounted

const WeaponModScript = preload("res://scripts/weapons/weapon_mod.gd")

static var _mods: Dictionary = {}
static var _initialized: bool = false

# Slot definitions per weapon_id across ALL 10 firearms (12 modification categories!)
static func get_slot_defs(weapon_id: String) -> Array[Dictionary]:
	match weapon_id:
		"ak47":
			return [
				{"slot_type": "dust_cover", "label": "КРЫШКА СК", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "side_rail", "label": "БОК. ПЛАНКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_any_mods": ["ak_cover_picatinny", "ak_rail_b13"]},
				{"slot_type": "handguard", "label": "ЦЕВЬЁ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "pistol_grip", "label": "РУКОЯТКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "ПОДСТВОЛ", "is_vital": false, "can_remove": true, "requires_any_mods": ["ak_hg_quad", "ak_hg_poly"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["ak_hg_quad"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["ak_hg_quad"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["ak_tube_ar"]},
				{"slot_type": "internal", "label": "МЕХАНИЗМ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"shotgun":
			return [
				{"slot_type": "rail", "label": "ПЛАНКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": ["sg_rail_pic"]},
				{"slot_type": "magazine", "label": "ТУБУС МАГ.", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "handguard", "label": "ЦЕВЬЁ", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ЧОК / СТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "РУКОЯТЬ ЦЕВЬЯ", "is_vital": false, "can_remove": true, "requires_mods": ["sg_hg_tac"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["sg_hg_tac"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["sg_hg_tac"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["sg_tube_ar"]},
				{"slot_type": "internal", "label": "МЕХАНИЗМ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 12G", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"pistol":
			return [
				{"slot_type": "rail", "label": "КРОНШТЕЙН", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": ["ps_rail_rmr"]},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "pistol_grip", "label": "НАКЛАДКИ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "internal", "label": "УСМ / АВТО", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 9×19", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"rpg":
			return [
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "rail", "label": "БОК. ПЛАНКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["rpg_rail_side"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["rpg_rail_side"]},
				{"slot_type": "ammo_type", "label": "БОЕВАЯ ЧАСТЬ", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"kar98k":
			return [
				{"slot_type": "rail", "label": "ПЛАНКА SCOUT", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_any_mods": ["k98_rail_scout", "k98_hg_tac"]},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "handguard", "label": "ЛОЖЕ / ЦЕВЬЁ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "ПОДСТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": ["k98_hg_tac"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["k98_hg_tac"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["k98_hg_tac"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["k98_tube_ar"]},
				{"slot_type": "internal", "label": "УСМ / ЗАТВОР", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 7.92", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"pkm":
			return [
				{"slot_type": "rail", "label": "ПЛАНКА КРЫШКИ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": ["pkm_rail_pic"]},
				{"slot_type": "handguard", "label": "ЦЕВЬЁ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "КОРОБ ЛЕНТЫ", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "pistol_grip", "label": "РУКОЯТКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "ПОДСТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": ["pkm_hg_quad"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["pkm_hg_quad"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["pkm_hg_quad"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["pkm_tube_ar"]},
				{"slot_type": "internal", "label": "МЕХАНИЗМ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 7.62R", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"l96a1":
			return [
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "handguard", "label": "ЦЕВЬЁ / ШАССИ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "ПОДСТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": ["l96_hg_tac"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["l96_hg_tac"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["l96_hg_tac"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["l96_tube_ar"]},
				{"slot_type": "internal", "label": "УСМ / УДАРНИК", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ .338", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"deagle":
			return [
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "СТВОЛ / ДТК", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "rail", "label": "НИЖН. ПЛАНКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["de_rail_under"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["de_rail_under"]},
				{"slot_type": "pistol_grip", "label": "НАКЛАДКИ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "internal", "label": "УСМ / ПРУЖИНА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ .50AE", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"aa12":
			return [
				{"slot_type": "rail", "label": "ПЛАНКА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": ["aa_rail_pic"]},
				{"slot_type": "magazine", "label": "МАГАЗИН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "handguard", "label": "ЦЕВЬЁ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ЧОК / СТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "ПОДСТВОЛ", "is_vital": false, "can_remove": true, "requires_mods": ["aa_hg_quad"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["aa_hg_quad"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["aa_hg_quad"]},
				{"slot_type": "internal", "label": "ЗАТВОР / БУФЕР", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 12G", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		"mg42":
			return [
				{"slot_type": "rail", "label": "ПЛАНКА КРЫШКИ", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "optic", "label": "ПРИЦЕЛ", "is_vital": false, "can_remove": true, "requires_mods": ["mg_rail_pic"]},
				{"slot_type": "handguard", "label": "ОБВЕС КОЖУХА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "muzzle", "label": "ДУЛЬНОЕ УСТР.", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "magazine", "label": "ЛЕНТА / БАРАБАН", "is_vital": false, "can_remove": false, "requires_mods": []},
				{"slot_type": "underbarrel", "label": "РУКОЯТЬ ЦЕВЬЯ", "is_vital": false, "can_remove": true, "requires_mods": ["mg_hg_quad"]},
				{"slot_type": "tactical_laser", "label": "ЛАЗЕР [T]", "is_vital": false, "can_remove": true, "requires_mods": ["mg_hg_quad"]},
				{"slot_type": "flashlight", "label": "ФОНАРЬ [L]", "is_vital": false, "can_remove": true, "requires_mods": ["mg_hg_quad"]},
				{"slot_type": "stock_adapter", "label": "ПРИКЛАД / ТРУБА", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "buttstock", "label": "ПРИКЛАД AR", "is_vital": false, "can_remove": true, "requires_mods": ["mg_tube_ar"]},
				{"slot_type": "internal", "label": "ЗАТВОР (RPM)", "is_vital": false, "can_remove": true, "requires_mods": []},
				{"slot_type": "ammo_type", "label": "ПАТРОНЫ 7.92", "is_vital": false, "can_remove": false, "requires_mods": []}
			]
		_:
			return []

static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_mods.clear()

	# =========================================================================
	# 1. RAILS, DUST COVERS & SCOPE MOUNTS (ПЛАНКИ ПИКАТИННИ И КРОНШТЕЙНЫ)
	# =========================================================================
	_register({"id": "ak_cover_std", "name": "Штатная крышка СК АК-47", "short_name": "ШТАТНАЯ СК", "description": "Стандартная штампованная крышка ствольной коробки АК-47 с ребрами жесткости.", "slot_type": "dust_cover", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "ak_cover_picatinny", "name": "Крышка СК «Бастион» Пикатинни", "short_name": "ПИКАТИННИ", "description": "Тактическая крышка с верхней планкой Пикатинни 20 мм. Открывает слот прицелов (конфликтует с боковой Б-13).", "slot_type": "dust_cover", "price": 75, "compatible_weapons": ["ak47"], "conflicts_with": ["ak_rail_b13"], "recoil_pitch_mult": 0.97, "recoil_yaw_mult": 0.97, "ergonomics_add": 2.0, "provides_slots": ["optic"]})
	_register({"id": "ak_rail_b13", "name": "Боковой кронштейн Зенит Б-13", "short_name": "ЛАСТ. ХВОСТ", "description": "Фрезерованный кронштейн «ласточкин хвост» на левую стенку СК. Альтернативная база для прицелов (конфликтует с крышкой Пикатинни).", "slot_type": "side_rail", "price": 65, "compatible_weapons": ["ak47"], "conflicts_with": ["ak_cover_picatinny"], "ergonomics_add": -1.5, "spread_mult": 0.96, "provides_slots": ["optic"]})

	_register({"id": "sg_rail_pic", "name": "Верхняя планка Пикатинни 12G", "short_name": "ПИКАТИННИ", "description": "Стальная база Пикатинни на коробку дробовика. Открывает установку коллиматоров и тепловизора.", "slot_type": "rail", "price": 55, "compatible_weapons": ["shotgun"], "ergonomics_add": -1.0, "provides_slots": ["optic"]})
	_register({"id": "ps_rail_rmr", "name": "Кронштейн затвора RMR / Пикатинни", "short_name": "БАЗА RMR", "description": "Низкопрофильная площадка на раму пистолета под мини-коллиматоры.", "slot_type": "rail", "price": 50, "compatible_weapons": ["pistol"], "ergonomics_add": 1.0, "provides_slots": ["optic"]})
	_register({"id": "rpg_rail_side", "name": "Боковая планка Пикатинни РПГ-7", "short_name": "БОК. ПЛАНКА", "description": "Хомут с боковой планкой на пусковую трубу РПГ-7. Открывает слоты ЛЦУ и фонаря.", "slot_type": "rail", "price": 60, "compatible_weapons": ["rpg"], "provides_slots": ["tactical_laser", "flashlight"]})
	_register({"id": "k98_rail_scout", "name": "Передняя планка Scout на ствол Kar98k", "short_name": "SCOUT RAIL", "description": "Передняя планка Пикатинни формата Scout, крепящаяся на ствол впереди затвора. Окно заряжания и обоймы остаются полностью свободными! (Конфликтует с тактическим ложем, у которого уже есть верхняя планка).", "slot_type": "rail", "price": 75, "compatible_weapons": ["kar98k"], "conflicts_with": ["k98_hg_tac"], "provides_slots": ["optic"]})
	_register({"id": "pkm_rail_pic", "name": "Планка Пикатинни на откидную крышку ПКМ", "short_name": "ПИКАТИННИ", "description": "Усиленная планка на откидную крышку лентоприёмника ПКМ (откидывается вверх вместе с прицелом при перезарядке).", "slot_type": "rail", "price": 85, "compatible_weapons": ["pkm"], "provides_slots": ["optic"]})
	_register({"id": "de_rail_under", "name": "Нижняя планка Пикатинни Deagle", "short_name": "НИЖН. ПЛАНКА", "description": "Фрезерованная нижняя рельса под тяжёлый ствол Desert Eagle. Открывает ЛЦУ и фонарь.", "slot_type": "rail", "price": 55, "compatible_weapons": ["deagle"], "recoil_pitch_mult": 0.96, "provides_slots": ["tactical_laser", "flashlight"]})
	_register({"id": "aa_rail_pic", "name": "Верхняя планка Пикатинни AA-12", "short_name": "ПИКАТИННИ", "description": "Полноразмерная рельса вдоль гребня AA-12. Открывает коллиматоры, ПНВ и тепловизор.", "slot_type": "rail", "price": 70, "compatible_weapons": ["aa12"], "provides_slots": ["optic"]})
	_register({"id": "mg_rail_pic", "name": "Тактическая планка на откидную крышку MG 42", "short_name": "ПИКАТИННИ", "description": "Усиленная планка Пикатинни поверх откидной крышки MG 42 (откидывается вверх вместе с прицелом при перезарядке).", "slot_type": "rail", "price": 90, "compatible_weapons": ["mg42"], "provides_slots": ["optic"]})

	# =========================================================================
	# 2. OPTICS & SIGHTS (МЕХАНИКА, КОЛЛИМАТОРЫ, ГОЛОГРАФИЯ, ОПТИКА, ПНВ, ТЕПЛОВИЗОР)
	# =========================================================================
	_register({
		"id": "optic_tritium_iron", "name": "Тритиевые мех. прицельные Ghost-Ring", "short_name": "ТРИТИЙ",
		"description": "Светящиеся зелёные тритиевые механические прицельные высокой чёткости. Повышают эргономику и скорость прицеливания.",
		"slot_type": "optic", "price": 55, "compatible_weapons": ["ak47", "shotgun", "pistol", "deagle", "aa12"],
		"spread_mult": 0.90, "ergonomics_add": 8.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 1.0, "ads_zoom_max": 1.0, "ads_reticle": "iron_sights"}
	})
	_register({
		"id": "optic_rmr", "name": "Мини-коллиматор Trijicon RMR", "short_name": "RMR 1x",
		"description": "Компактный открытый рефлекторный прицел с яркой красной точкой. Идеален для пистолетов и ближнего боя.",
		"slot_type": "optic", "price": 95, "compatible_weapons": ["pistol", "deagle", "shotgun", "ak47", "aa12"],
		"spread_mult": 0.80, "recoil_pitch_mult": 0.96, "ergonomics_add": 6.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 1.0, "ads_zoom_max": 1.0, "ads_reticle": "red_dot"}
	})
	_register({
		"id": "optic_pk06", "name": "Коллиматорный прицел ПК-06", "short_name": "ПК-06",
		"description": "Открытый российский коллиматор с тонкой рамкой и чёткой точкой 1x.",
		"slot_type": "optic", "price": 90, "compatible_weapons": ["ak47", "shotgun", "pistol", "pkm", "aa12", "mg42"],
		"spread_mult": 0.82, "recoil_pitch_mult": 0.95, "ergonomics_add": 5.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 1.0, "ads_zoom_max": 1.0, "ads_reticle": "red_dot"}
	})
	_register({
		"id": "optic_red_dot", "name": "Голографический прицел EOTech EXPS3", "short_name": "EOTECH 1x",
		"description": "Легендарный голографический прицел с маркой «круг-точка» 1x. Мгновенный захват цели и заметное снижение разброса.",
		"slot_type": "optic", "price": 115, "compatible_weapons": ["ak47", "shotgun", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42"],
		"spread_mult": 0.76, "recoil_pitch_mult": 0.93, "recoil_yaw_mult": 0.93, "ergonomics_add": 4.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 1.0, "ads_zoom_max": 1.0, "ads_reticle": "red_dot"}
	})
	_register({
		"id": "optic_acog", "name": "Призматический прицел ACOG TA31 (4x)", "short_name": "ACOG 4x",
		"description": "Армейская оптика постоянной кратности 4.0x с шевронной баллистической сеткой.",
		"slot_type": "optic", "price": 165, "compatible_weapons": ["ak47", "pkm", "aa12", "mg42", "kar98k"],
		"spread_mult": 0.66, "recoil_pitch_mult": 0.91, "ergonomics_add": -2.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 3.5, "ads_zoom_max": 4.0, "ads_default_zoom": 4.0, "ads_reticle": "lpvo_crosshair"}
	})
	_register({
		"id": "optic_zf39", "name": "Снайперский прицел ZF39 (4x ВМВ)", "short_name": "ZF39 4x",
		"description": "Аутентичный немецкий оптический прицел с классической трёхлучевой сеткой. Отлично подходит для Kar98k.",
		"slot_type": "optic", "price": 145, "compatible_weapons": ["kar98k"],
		"spread_mult": 0.58, "recoil_pitch_mult": 0.92, "ergonomics_add": -2.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 3.0, "ads_zoom_max": 5.0, "ads_default_zoom": 4.0, "ads_reticle": "sniper_crosshair"}
	})
	_register({
		"id": "optic_lpvo", "name": "Оптический прицел LPVO 1.5x–4x", "short_name": "LPVO 1.5-4x",
		"description": "Переменная тактическая оптика 1.5x–4.0x (колёсико мыши меняет кратность). Универсален на любых дистанциях.",
		"slot_type": "optic", "price": 175, "compatible_weapons": ["ak47", "pkm", "kar98k", "deagle", "mg42"],
		"spread_mult": 0.62, "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.90, "ergonomics_add": -3.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 1.5, "ads_zoom_max": 4.0, "ads_default_zoom": 2.5, "ads_reticle": "lpvo_crosshair"}
	})
	_register({
		"id": "l96_opt_pm2", "name": "Штатная оптика PM II 3x–8x", "short_name": "PM II 3-8x",
		"description": "Штатный снайперский прицел Schmidt & Bender 3.0x–8.0x с сеткой Mil-Dot.",
		"slot_type": "optic", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 3.0, "ads_zoom_max": 8.0, "ads_default_zoom": 4.5, "ads_reticle": "sniper_crosshair"}
	})
	_register({
		"id": "rpg_opt_pgo7", "name": "Штатный прицел ПГО-7В (2x–4x)", "short_name": "ПГО-7 2-4x",
		"description": "Штатный оптический прицел гранатомёта РПГ-7 с дальномерной шкалой.",
		"slot_type": "optic", "price": 0, "compatible_weapons": ["rpg"], "is_vanilla_default": true,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 2.0, "ads_zoom_max": 4.0, "ads_default_zoom": 2.7, "ads_reticle": "pgo7_crosshair"}
	})
	_register({
		"id": "optic_sniper_12x", "name": "Дальнобойная оптика Nightforce 6x–12x", "short_name": "NF 6-12x",
		"description": "Сверхдальнобойная переменная оптика 6.0x–12.0x с тончайшей баллистической сеткой для хирургических выстрелов.",
		"slot_type": "optic", "price": 230, "compatible_weapons": ["l96a1", "kar98k"],
		"spread_mult": 0.45, "recoil_pitch_mult": 0.90, "ergonomics_add": -5.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 6.0, "ads_zoom_max": 12.0, "ads_default_zoom": 8.0, "ads_reticle": "sniper_crosshair"}
	})
	_register({
		"id": "optic_nvg", "name": "Ночной прицел 1ПН93 ПНВ (2x–5x)", "short_name": "ПНВ 2-5x",
		"description": "Прицел ночного видения с зелёным ЭОП-усилителем, сеткой-дальномером и усилением видимости в тенях и дыму!",
		"slot_type": "optic", "price": 240, "compatible_weapons": ["ak47", "kar98k", "pkm", "l96a1", "aa12", "mg42", "rpg"],
		"spread_mult": 0.65, "recoil_pitch_mult": 0.92, "ergonomics_add": -4.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 2.0, "ads_zoom_max": 5.0, "ads_default_zoom": 3.0, "ads_reticle": "nvg", "vision_mode": "nvg"}
	})
	_register({
		"id": "optic_thermal", "name": "Тепловизионный прицел FLIR RS-32 (2x–8x)", "short_name": "ТЕПЛОВИЗОР",
		"description": "Полноценный тепловизор FLIR! Охлаждает фон в тёмно-синий спектр и ярко подсвечивает врагов, дроны и технику горячим бело-оранжевым свечением!",
		"slot_type": "optic", "price": 320, "compatible_weapons": ["ak47", "shotgun", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42", "rpg"],
		"spread_mult": 0.60, "recoil_pitch_mult": 0.90, "ergonomics_add": -5.0,
		"mechanics": {"ads_enabled": true, "ads_zoom_min": 2.0, "ads_zoom_max": 8.0, "ads_default_zoom": 3.5, "ads_reticle": "thermal", "vision_mode": "thermal"}
	})

	# =========================================================================
	# 3. MAGAZINES & AMMO STORAGE (УВЕЛИЧЕННЫЕ И УМЕНЬШЕННЫЕ МАГАЗИНЫ / ТУБУСЫ / КОРОБА)
	# =========================================================================
	# AK-47
	_register({"id": "ak_mag_10", "name": "Укороченный магазин АК (10 патр.)", "short_name": "МАГ 10", "description": "Лёгкий 10-патронный магазин. Резко ускоряет перезарядку и повышает эргономику.", "slot_type": "magazine", "price": 45, "compatible_weapons": ["ak47"], "mag_size_add": -20, "reload_time_mult": 0.78, "ergonomics_add": 10.0})
	_register({"id": "ak_mag_30", "name": "Штатный стальной магазин (30 патр.)", "short_name": "МАГ 30", "description": "Стандартный ребристый стальной магазин АК на 30 патронов.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "ak_mag_45", "name": "Бакелитовый магазин РПК (45 патр.)", "short_name": "РПК 45", "description": "Удлинённый оранжевый бакелитовый магазин от РПК на 45 патронов.", "slot_type": "magazine", "price": 115, "compatible_weapons": ["ak47"], "mag_size_add": 15, "reload_time_mult": 1.12, "ergonomics_add": -4.0})
	_register({"id": "ak_mag_75", "name": "Барабанный магазин РПК «Бубен» (75 патр.)", "short_name": "БУБЕН 75", "description": "Массивный стальной барабан на 75 патронов. Превращает АК-47 в ручной пулемёт!", "slot_type": "magazine", "price": 210, "compatible_weapons": ["ak47"], "mag_size_add": 45, "reload_time_mult": 1.32, "ergonomics_add": -11.0, "recoil_pitch_mult": 0.94})
	# Pump Shotgun tubes
	_register({"id": "sg_tube_4", "name": "Короткий тубус (4 патр.)", "short_name": "ТУБУС 4", "description": "Облегчённый короткий трубчатый магазин. Максимальная манёвренность.", "slot_type": "magazine", "price": 40, "compatible_weapons": ["shotgun"], "mag_size_add": -1, "ergonomics_add": 9.0, "reload_time_mult": 0.90})
	_register({"id": "sg_tube_5", "name": "Штатный тубус (5 патр.)", "short_name": "ТУБУС 5", "description": "Стандартный подствольный трубчатый магазин на 5 патронов 12G.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["shotgun"], "is_vanilla_default": true})
	_register({"id": "sg_tube_8", "name": "Расширенный тубус +3 (8 патр.)", "short_name": "ТУБУС 8", "description": "Удлинённый подствольный тубус на 8+1 патронов 12 калибра. Незаменим в плотном бою!", "slot_type": "magazine", "price": 135, "compatible_weapons": ["shotgun"], "mag_size_add": 3, "ergonomics_add": -6.0, "recoil_pitch_mult": 0.95})
	# Pistol
	_register({"id": "ps_mag_12", "name": "Компактный магазин (12 патр.)", "short_name": "МАГ 12", "description": "Короткий магазин скрытого ношения: сверхбыстрая перезарядка и +8 эргономики.", "slot_type": "magazine", "price": 35, "compatible_weapons": ["pistol"], "mag_size_add": -5, "reload_time_mult": 0.80, "ergonomics_add": 8.0})
	_register({"id": "ps_mag_17", "name": "Штатный магазин (17 патр.)", "short_name": "МАГ 17", "description": "Стандартный двухрядный магазин 9×19 на 17 патронов.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["pistol"], "is_vanilla_default": true})
	_register({"id": "ps_mag_33", "name": "Штурмовой магазин Stick (33 патр.)", "short_name": "МАГ 33", "description": "Длинный магазин Glock на 33 патрона! Идеален в паре с автоспуском G18C.", "slot_type": "magazine", "price": 120, "compatible_weapons": ["pistol"], "mag_size_add": 16, "reload_time_mult": 1.15, "ergonomics_add": -5.0})
	# Kar98k
	_register({"id": "k98_mag_5", "name": "Штатный внутренний магазин (5 патр.)", "short_name": "ВНУТР. 5", "description": "Стандартный внутренний магазин Mauser на 5 патронов под обойму.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["kar98k"], "is_vanilla_default": true})
	_register({"id": "k98_mag_10", "name": "Окопный расширенный магазин (10 патр.)", "short_name": "ОКОПН. 10", "description": "Исторический траншейный увеличенный короб Mauser Grabenmagazin на 10 патронов 7.92×57!", "slot_type": "magazine", "price": 145, "compatible_weapons": ["kar98k"], "mag_size_add": 5, "ergonomics_add": -5.0})
	# PKM
	_register({"id": "pkm_box_50", "name": "Компактный мягкий короб (50 патр.)", "short_name": "КОРОБ 50", "description": "Лёгкий штурмовой подсумок на 50 патронов — ускоряет перезарядку и облегчает ПКМ.", "slot_type": "magazine", "price": 75, "compatible_weapons": ["pkm"], "mag_size_add": -50, "reload_time_mult": 0.76, "ergonomics_add": 14.0})
	_register({"id": "pkm_box_100", "name": "Штатный короб ПКМ (100 патр.)", "short_name": "КОРОБ 100", "description": "Стандартный стальной оливковый короб на 100 патронов 7.62×54R.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["pkm"], "is_vanilla_default": true})
	_register({"id": "pkm_box_200", "name": "Тяжёлый короб ПКМ (200 патр.)", "short_name": "КОРОБ 200", "description": "Огромный пулемётный короб на 200 патронов для непрерывного подавления целой волны.", "slot_type": "magazine", "price": 220, "compatible_weapons": ["pkm"], "mag_size_add": 100, "reload_time_mult": 1.24, "ergonomics_add": -10.0})
	# L96A1
	_register({"id": "l96_mag_5", "name": "Штатный магазин .338 (5 патр.)", "short_name": "МАГ 5", "description": "Стандартный стальной магазин L96A1 на 5 патронов .338 Lapua Magnum.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true})
	_register({"id": "l96_mag_10", "name": "Увеличенный магазин .338 (10 патр.)", "short_name": "МАГ 10", "description": "Удлинённый двухрядный стальной магазин на 10 патронов .338 LM.", "slot_type": "magazine", "price": 170, "compatible_weapons": ["l96a1"], "mag_size_add": 5, "ergonomics_add": -4.0, "reload_time_mult": 1.08})
	# Desert Eagle
	_register({"id": "de_mag_7", "name": "Штатный магазин .50 AE (7 патр.)", "short_name": "МАГ 7", "description": "Стандартный магазин Desert Eagle на 7 патронов .50 AE.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["deagle"], "is_vanilla_default": true})
	_register({"id": "de_mag_10", "name": "Удлинённый магазин .50 AE (10 патр.)", "short_name": "МАГ 10", "description": "Увеличенный магазин с усиленной пяткой на 10+1 патронов .50 AE.", "slot_type": "magazine", "price": 110, "compatible_weapons": ["deagle"], "mag_size_add": 3, "ergonomics_add": -3.0})
	# AA-12
	_register({"id": "aa_mag_8", "name": "Коробчатый магазин AA-12 (8 патр.)", "short_name": "КОРОБ 8", "description": "Компактный прямой магазин на 8 патронов: молниеносная перезарядка и +12 эргономики.", "slot_type": "magazine", "price": 60, "compatible_weapons": ["aa12"], "mag_size_add": -12, "reload_time_mult": 0.72, "ergonomics_add": 12.0})
	_register({"id": "aa_mag_20", "name": "Штатный барабан AA-12 (20 патр.)", "short_name": "БАРАБАН 20", "description": "Фирменный 20-зарядный барабанный магазин AA-12.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["aa12"], "is_vanilla_default": true})
	_register({"id": "aa_mag_32", "name": "Мега-барабан AA-12 (32 патр.)", "short_name": "БАРАБАН 32", "description": "Экспериментальный гигантский барабан на 32 патрона 12 калибра!", "slot_type": "magazine", "price": 230, "compatible_weapons": ["aa12"], "mag_size_add": 12, "reload_time_mult": 1.25, "ergonomics_add": -9.0})
	# MG 42
	_register({"id": "mg_box_50", "name": "Штурмовой кекс Gurttrommel (50 патр.)", "short_name": "КЕКС 50", "description": "Компактный 50-патронный барабан — значительно легче и быстрее меняется.", "slot_type": "magazine", "price": 75, "compatible_weapons": ["mg42"], "mag_size_add": -50, "reload_time_mult": 0.75, "ergonomics_add": 13.0})
	_register({"id": "mg_box_100", "name": "Штатный барабан MG 42 (100 патр.)", "short_name": "КЕКС 100", "description": "Стандартный барабан на 100 патронов 7.92×57 мм.", "slot_type": "magazine", "price": 0, "compatible_weapons": ["mg42"], "is_vanilla_default": true})
	_register({"id": "mg_box_250", "name": "Станковый короб MG 42 (250 патр.)", "short_name": "КОРОБ 250", "description": "Массивный металлический короб Patronenkasten 41 на 250 патронов — пила без остановки!", "slot_type": "magazine", "price": 250, "compatible_weapons": ["mg42"], "mag_size_add": 150, "reload_time_mult": 1.28, "ergonomics_add": -11.0})

	# =========================================================================
	# 4. HANDGUARDS / FORENDS (РАЗЛИЧНЫЕ ЦЕВЬЯ)
	# =========================================================================
	_register({"id": "ak_hg_wood", "name": "Штатное деревянное цевьё АК", "short_name": "ДЕРЕВО", "description": "Классическое ламинированное берёзовое цевьё АК-47.", "slot_type": "handguard", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "ak_hg_poly", "name": "Полимерное цевьё АК-74М", "short_name": "ПОЛИМЕР", "description": "Лёгкое чёрное полимерное цевьё с нижней планкой под рукоятку или ГП-25.", "slot_type": "handguard", "price": 65, "compatible_weapons": ["ak47"], "ergonomics_add": 6.0, "recoil_pitch_mult": 0.96, "provides_slots": ["underbarrel"]})
	_register({"id": "ak_hg_quad", "name": "Цевьё Зенит Б-30 (Квадрейл Пикатинни)", "short_name": "ЗЕНИТ Б-30", "description": "Фрезерованное алюминиевое цевьё с 4 планками Пикатинни! Открывает ГП-25/рукоятки, лазеры [T] и фонари [L].", "slot_type": "handguard", "price": 125, "compatible_weapons": ["ak47"], "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.90, "ergonomics_add": 4.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})

	_register({"id": "sg_hg_wood", "name": "Штатное ореховое цевьё", "short_name": "ОРЕХ", "description": "Классическое ребристое ореховое цевьё помпового дробовика.", "slot_type": "handguard", "price": 0, "compatible_weapons": ["shotgun"], "is_vanilla_default": true})
	_register({"id": "sg_hg_magpul", "name": "Полимерное цевьё Magpul MOE", "short_name": "MAGPUL", "description": "Эргономичное полимерное цевьё с ускоренным ходом помпы и лучшим контролем.", "slot_type": "handguard", "price": 65, "compatible_weapons": ["shotgun"], "ergonomics_add": 7.0, "fire_rate_mult": 0.93, "recoil_pitch_mult": 0.95})
	_register({"id": "sg_hg_tac", "name": "Тактическое цевьё с планками Пикатинни", "short_name": "КВАДРЕЙЛ", "description": "Алюминиевое цевьё с планками Пикатинни — открывает рукоятку, лазер [T] и фонарь [L].", "slot_type": "handguard", "price": 105, "compatible_weapons": ["shotgun"], "recoil_pitch_mult": 0.91, "ergonomics_add": 4.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})

	_register({"id": "k98_hg_wood", "name": "Штатное ложе Schichtholz", "short_name": "КЛЕЕНОЕ", "description": "Аутентичное клееное буковое ложе Kar98k.", "slot_type": "handguard", "price": 0, "compatible_weapons": ["kar98k"], "is_vanilla_default": true})
	_register({"id": "k98_hg_tac", "name": "Тактическое ложе Scout с планками Пикатинни", "short_name": "ТАКТ. ЛОЖЕ", "description": "Современное полимерное ложе с передними планками Scout — открывает оптику (впереди затвора без помех обоймам!), сошки, лазер [T] и фонарь [L].", "slot_type": "handguard", "price": 120, "compatible_weapons": ["kar98k"], "conflicts_with": ["k98_rail_scout"], "recoil_pitch_mult": 0.90, "spread_mult": 0.88, "ergonomics_add": 6.0, "provides_slots": ["optic", "underbarrel", "tactical_laser", "flashlight"]})

	_register({"id": "pkm_hg_quad", "name": "Цевьё Зенит Б-50 для ПКМ (Квадрейл)", "short_name": "ЗЕНИТ Б-50", "description": "Алюминиевое тактическое цевьё на ПКМ с планками Пикатинни. Открывает M203, рукоятки, лазер [T] и фонарь [L]!", "slot_type": "handguard", "price": 135, "compatible_weapons": ["pkm"], "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.90, "ergonomics_add": 5.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})
	_register({"id": "l96_hg_std", "name": "Штатное цевьё AI (Олива)", "short_name": "ШАССИ AI", "description": "Штатное оливковое цевьё Accuracy International с вентиляционными прорезями.", "slot_type": "handguard", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true})
	_register({"id": "l96_hg_tac", "name": "Тактический квадрейл шасси AWM", "short_name": "ШАССИ RAIL", "description": "Боковые и нижние планки Пикатинни на цевьё L96A1. Открывает лазер [T], фонарь [L] и подствол M203!", "slot_type": "handguard", "price": 130, "compatible_weapons": ["l96a1"], "recoil_pitch_mult": 0.92, "recoil_yaw_mult": 0.92, "ergonomics_add": 3.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})
	_register({"id": "aa_hg_std", "name": "Штатное полимерное цевьё AA-12", "short_name": "ШТАТНОЕ", "description": "Стандартное ребристое цевьё AA-12.", "slot_type": "handguard", "price": 0, "compatible_weapons": ["aa12"], "is_vanilla_default": true})
	_register({"id": "aa_hg_quad", "name": "Тактическое цевьё AA-12 (3 планки)", "short_name": "КВАДРЕЙЛ", "description": "Усиленное цевьё с планками Пикатинни. Открывает подствольник M203, рукоятки, лазер [T] и фонарь [L]!", "slot_type": "handguard", "price": 115, "compatible_weapons": ["aa12"], "recoil_pitch_mult": 0.91, "ergonomics_add": 4.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})
	_register({"id": "mg_hg_quad", "name": "Тактический обвес кожуха MG 42", "short_name": "ОБВЕС RAIL", "description": "Планки Пикатинни на перфорированный кожух MG 42. Открывает переднюю рукоятку, лазер [T] и фонарь [L]!", "slot_type": "handguard", "price": 130, "compatible_weapons": ["mg42"], "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.92, "ergonomics_add": 5.0, "provides_slots": ["underbarrel", "tactical_laser", "flashlight"]})

	# =========================================================================
	# 5. UNDERBARREL: GRENADE LAUNCHERS (ГП-25 / M203) & FOREGRIPS / BIPODS
	# =========================================================================
	_register({
		"id": "ub_gp25", "name": "Подствольный гранатомёт ГП-25 «Костёр»", "short_name": "ГП-25 40мм",
		"description": "Полноценный 40-мм подствольник! [G] — переход в режим гранатомёта с баллистической сеткой, [ЛКМ] — выстрел (480 урона, 8.5м; взводится после 14м полёта), [R] — зарядка. В комплекте 1+5 гранат!",
		"slot_type": "underbarrel", "price": 260, "compatible_weapons": ["ak47"],
		"ergonomics_add": -8.0, "recoil_pitch_mult": 0.95,
		"mechanics": {"underbarrel_grenade_launcher": true, "ugl_type": "gp25", "ugl_damage": 480.0, "ugl_radius": 8.5}
	})
	_register({
		"id": "ub_m203", "name": "Подствольный гранатомёт M203 (40мм)", "short_name": "M203 40мм",
		"description": "Армейский 40-мм подствольный гранатомёт! [G] — режим гранатомёта с баллистической сеткой, [ЛКМ] — пуск (480 урона, 8.5м; взводится после 14м полёта), [R] — зарядка. В комплекте 1+5 гранат!",
		"slot_type": "underbarrel", "price": 270, "compatible_weapons": ["pkm", "l96a1", "aa12"],
		"ergonomics_add": -8.0, "recoil_pitch_mult": 0.96,
		"mechanics": {"underbarrel_grenade_launcher": true, "ugl_type": "m203", "ugl_damage": 480.0, "ugl_radius": 8.5}
	})
	_register({"id": "ub_grip_rk1", "name": "Вертикальная рукоятка Зенит РК-1", "short_name": "РК-1", "description": "Массивная алюминиевая передняя рукоятка. Мощно гасит вертикальную и горизонтальную отдачу.", "slot_type": "underbarrel", "price": 90, "compatible_weapons": ["ak47", "shotgun", "pkm", "aa12", "mg42", "l96a1"], "recoil_pitch_mult": 0.84, "recoil_yaw_mult": 0.86, "ergonomics_add": 5.0})
	_register({"id": "ub_grip_afg", "name": "Угловая рукоятка Magpul AFG-2", "short_name": "AFG-2", "description": "Эргономичная наклонная рукоять на цевьё: +10 эргономики и уверенный контроль разброса.", "slot_type": "underbarrel", "price": 80, "compatible_weapons": ["ak47", "shotgun", "kar98k", "pkm", "aa12", "mg42"], "recoil_pitch_mult": 0.90, "spread_mult": 0.90, "ergonomics_add": 10.0})
	_register({"id": "ub_bipod_harris", "name": "Тактические сошки Harris S-BRM", "short_name": "СОШКИ", "description": "Пружинные снайперские сошки. Радикально повышают кучность и гасят отдачу.", "slot_type": "underbarrel", "price": 95, "compatible_weapons": ["kar98k", "l96a1", "pkm", "mg42"], "spread_mult": 0.72, "recoil_pitch_mult": 0.82, "ergonomics_add": -3.0})

	# =========================================================================
	# 6. TACTICAL LASERS ([T]) & WEAPON FLASHLIGHTS ([L])
	# =========================================================================
	_register({
		"id": "tac_laser_red", "name": "Лазерный целеуказатель Перст-4 (Красный)", "short_name": "ЛЦУ КРАСН.",
		"description": "Видимый красный 3D-луч и точка на целях! Переключается клавишей [T]. Снижает разброс от бедра на 32%.",
		"slot_type": "tactical_laser", "price": 95, "compatible_weapons": ["ak47", "shotgun", "pistol", "rpg", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42"],
		"spread_mult": 0.85, "ergonomics_add": -1.0,
		"mechanics": {"laser_sight": true, "laser_color": Color(1.0, 0.08, 0.06), "hipfire_spread_mult": 0.68}
	})
	_register({
		"id": "tac_laser_green", "name": "Лазерный блок AN/PEQ-15 (Зелёный)", "short_name": "PEQ-15 ЗЕЛ.",
		"description": "Сверхъяркий зелёный тактический ЛЦУ (клавиша [T]). Виден на большой дистанции, режет разброс от бедра на 42%!",
		"slot_type": "tactical_laser", "price": 130, "compatible_weapons": ["ak47", "shotgun", "pistol", "rpg", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42"],
		"spread_mult": 0.80, "recoil_yaw_mult": 0.94, "ergonomics_add": -1.5,
		"mechanics": {"laser_sight": true, "laser_color": Color(0.12, 1.0, 0.28), "hipfire_spread_mult": 0.58}
	})
	_register({
		"id": "tac_light_klesh", "name": "Тактический фонарь «Клещ-2П»", "short_name": "КЛЕЩ-2П",
		"description": "Мощный светодиодный оружейный фонарь! Включается клавишей [L] и ярко освещает цели перед вами.",
		"slot_type": "flashlight", "price": 70, "compatible_weapons": ["ak47", "shotgun", "pistol", "rpg", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42"],
		"ergonomics_add": -1.0,
		"mechanics": {"flashlight": true, "flashlight_energy": 5.5, "flashlight_range": 38.0}
	})
	_register({
		"id": "tac_light_surefire", "name": "Фонарь SureFire M600 / X300 Ultra", "short_name": "SUREFIRE",
		"description": "Дальнобойный тактический прожектор на 1000 люмен (клавиша [L]). Освещает всю арену и улучшает обзор.",
		"slot_type": "flashlight", "price": 105, "compatible_weapons": ["ak47", "shotgun", "pistol", "rpg", "kar98k", "pkm", "l96a1", "deagle", "aa12", "mg42"],
		"ergonomics_add": -1.5,
		"mechanics": {"flashlight": true, "flashlight_energy": 7.5, "flashlight_range": 52.0}
	})

	# =========================================================================
	# 7. PISTOL GRIPS (ПИСТОЛЕТНЫЕ РУКОЯТКИ И НАКЛАДКИ)
	# =========================================================================
	_register({"id": "ak_grip_std", "name": "Штатная бакелитовая рукоять АК", "short_name": "БАКЕЛИТ", "description": "Стандартная бакелитовая пистолетная рукоятка.", "slot_type": "pistol_grip", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "pkm_grip_std", "name": "Штатная бакелитовая рукоять ПКМ", "short_name": "БАКЕЛИТ", "description": "Стандартная рукоять ПКМ.", "slot_type": "pistol_grip", "price": 0, "compatible_weapons": ["pkm"], "is_vanilla_default": true})
	_register({"id": "ps_grip_std", "name": "Штатные накладки пистолета", "short_name": "ШТАТНЫЕ", "description": "Заводские текстурированные накладки на рукоять пистолета.", "slot_type": "pistol_grip", "price": 0, "compatible_weapons": ["pistol"], "is_vanilla_default": true})
	_register({"id": "ps_grip_rubber", "name": "Прорезиненные накладки Hogue 9мм", "short_name": "HOGUE 9мм", "description": "Анатомические резиновые накладки на рукоять пистолета: -10% отдачи и +10 эргономики.", "slot_type": "pistol_grip", "price": 65, "compatible_weapons": ["pistol"], "ergonomics_add": 10.0, "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.88})
	_register({"id": "de_grip_rubber", "name": "Штатные накладки Hogue", "short_name": "HOGUE", "description": "Прорезиненная рукоять с подпальцевыми выемками.", "slot_type": "pistol_grip", "price": 0, "compatible_weapons": ["deagle"], "is_vanilla_default": true})
	_register({"id": "grip_rk3", "name": "Прорезиненная рукоять Зенит РК-3", "short_name": "РК-3", "description": "Анатомическая тактическая рукоять: +10 эргономики и заметно мягче верт./гориз. увод ствола.", "slot_type": "pistol_grip", "price": 70, "compatible_weapons": ["ak47", "pkm"], "ergonomics_add": 10.0, "recoil_pitch_mult": 0.92, "recoil_yaw_mult": 0.90})
	_register({"id": "grip_skeleton", "name": "Скелетная алюминиевая рукоять", "short_name": "СКЕЛЕТН.", "description": "Ультралёгкая фрезерованная спортивная рукоять (+14 эргономики, ускорение перезарядки).", "slot_type": "pistol_grip", "price": 95, "compatible_weapons": ["ak47", "pkm"], "ergonomics_add": 14.0, "reload_time_mult": 0.93, "recoil_yaw_mult": 0.95})
	_register({"id": "de_grip_walnut", "name": "Гравированный орех Desert Eagle", "short_name": "ОРЕХ", "description": "Элитные деревянные накладки на рукоять Desert Eagle — стиль и уверенный хват.", "slot_type": "pistol_grip", "price": 75, "compatible_weapons": ["deagle"], "ergonomics_add": 8.0, "recoil_pitch_mult": 0.94, "recoil_yaw_mult": 0.86})

	# =========================================================================
	# 8. STOCKS & BUFFER TUBES (ПРИКЛАДЫ + ТРУБЫ ПРИКЛАДОВ AR-15)
	# =========================================================================
	_register({"id": "ak_stock_wood", "name": "Штатный деревянный приклад АК", "short_name": "ДЕРЕВО", "description": "Стандартный деревянный приклад.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "ak_stock_fold", "name": "Складной рамочный приклад АКС-74", "short_name": "РАМОЧНЫЙ", "description": "Лёгкий стальной рамочный приклад: +9 эргономики при умеренном гашении отдачи.", "slot_type": "stock_adapter", "price": 65, "compatible_weapons": ["ak47"], "ergonomics_add": 9.0, "recoil_pitch_mult": 1.03})
	_register({"id": "ak_tube_ar", "name": "Труба приклада AR-15 (Buffer Tube)", "short_name": "ТРУБА AR", "description": "Переходник с телескопической трубой приклада AR-15! Открывает слот тактических прикладов CTR / GL-SHOCK / PRS.", "slot_type": "stock_adapter", "price": 80, "compatible_weapons": ["ak47"], "recoil_pitch_mult": 0.94, "ergonomics_add": 3.0, "provides_slots": ["buttstock"]})

	_register({"id": "sg_stock_wood", "name": "Штатный ореховый приклад", "short_name": "ОРЕХ", "description": "Классический ореховый приклад дробовика.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["shotgun"], "is_vanilla_default": true})
	_register({"id": "sg_stock_pistol", "name": "Рукоять «Обрез» (без приклада)", "short_name": "ОБРЕЗ", "description": "Компактная пистолетная рукоять вместо приклада: +18 эргономики, но отдача выше.", "slot_type": "stock_adapter", "price": 55, "compatible_weapons": ["shotgun"], "ergonomics_add": 18.0, "recoil_pitch_mult": 1.18})
	_register({"id": "sg_tube_ar", "name": "Труба приклада M4 для дробовика", "short_name": "ТРУБА M4", "description": "Адаптер с трубой приклада — открывает установку телескопических прикладов!", "slot_type": "stock_adapter", "price": 75, "compatible_weapons": ["shotgun"], "recoil_pitch_mult": 0.94, "provides_slots": ["buttstock"]})

	_register({"id": "k98_stock_wood", "name": "Штатный приклад Kar98k", "short_name": "ШТАТНЫЙ", "description": "Стандартный приклад Mauser.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["kar98k"], "is_vanilla_default": true})
	_register({"id": "k98_tube_ar", "name": "Адаптер трубы приклада Kar98k", "short_name": "ТРУБА AR", "description": "Современный переходник под трубу приклада — открывает снайперские приклады!", "slot_type": "stock_adapter", "price": 80, "compatible_weapons": ["kar98k"], "recoil_pitch_mult": 0.94, "provides_slots": ["buttstock"]})

	_register({"id": "pkm_stock_wood", "name": "Штатный скелетный приклад ПКМ", "short_name": "БЕРЁЗА", "description": "Стандартный приклад ПКМ.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["pkm"], "is_vanilla_default": true})
	_register({"id": "pkm_tube_ar", "name": "Труба приклада ПТ-1 / AR для ПКМ", "short_name": "ТРУБА AR", "description": "Усиленная труба приклада на ствольную коробку ПКМ — открывает телескопические приклады.", "slot_type": "stock_adapter", "price": 85, "compatible_weapons": ["pkm"], "recoil_pitch_mult": 0.93, "provides_slots": ["buttstock"]})

	_register({"id": "l96_stock_std", "name": "Штатное шасси AI Thumbhole", "short_name": "ШАССИ AI", "description": "Штатный оливковый приклад L96A1.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true})
	_register({"id": "l96_tube_ar", "name": "Складная труба приклада AWM", "short_name": "ТРУБА AWM", "description": "Адаптер под регулируемые тактические приклады.", "slot_type": "stock_adapter", "price": 90, "compatible_weapons": ["l96a1"], "ergonomics_add": 4.0, "provides_slots": ["buttstock"]})

	_register({"id": "mg_stock_bakelite", "name": "Штатный бакелитовый приклад MG 42", "short_name": "БАКЕЛИТ", "description": "Стандартный бакелитовый приклад MG 42.", "slot_type": "stock_adapter", "price": 0, "compatible_weapons": ["mg42"], "is_vanilla_default": true})
	_register({"id": "mg_tube_ar", "name": "Адаптер трубы приклада MG 42", "short_name": "ТРУБА AR", "description": "Переходник под современную телескопическую трубу — открывает слот прикладов.", "slot_type": "stock_adapter", "price": 85, "compatible_weapons": ["mg42"], "recoil_pitch_mult": 0.93, "provides_slots": ["buttstock"]})

	# Child Tactical Buttstocks (installed onto Buffer Tubes!)
	_register({"id": "stock_ctr", "name": "Телескопический приклад Magpul CTR", "short_name": "MAGPUL CTR", "description": "Лёгкий и прочный тактический приклад на трубу: +10 эргономики и -14% отдачи.", "slot_type": "buttstock", "price": 90, "compatible_weapons": ["ak47", "shotgun", "kar98k", "pkm", "l96a1", "mg42"], "recoil_pitch_mult": 0.86, "recoil_yaw_mult": 0.88, "ergonomics_add": 10.0})
	_register({"id": "stock_glshock", "name": "Амортизирующий приклад FAB GL-SHOCK", "short_name": "GL-SHOCK", "description": "Приклад со встроенным пружинным демпфером отдачи: -22% вертикальной отдачи!", "slot_type": "buttstock", "price": 135, "compatible_weapons": ["ak47", "shotgun", "kar98k", "pkm", "l96a1", "mg42"], "recoil_pitch_mult": 0.78, "recoil_yaw_mult": 0.82, "ergonomics_add": 4.0})
	_register({"id": "stock_prs", "name": "Снайперский приклад Magpul PRS Gen3", "short_name": "PRS GEN3", "description": "Тяжёлый высокоточный приклад с микрорегулировками: -24% отдачи и -16% разброса.", "slot_type": "buttstock", "price": 155, "compatible_weapons": ["ak47", "kar98k", "pkm", "l96a1", "mg42"], "recoil_pitch_mult": 0.76, "recoil_yaw_mult": 0.80, "spread_mult": 0.84, "ergonomics_add": -2.0})

	# =========================================================================
	# 9. MUZZLE DEVICES (ДТК, ПЛАМЕГАСИТЕЛИ, ЧОКИ, ГЛУШИТЕЛИ!)
	# =========================================================================
	_register({"id": "ak_muz_slant", "name": "Штатный скошенный компенсатор АКМ", "short_name": "ШТАТНЫЙ", "description": "Классический скошенный компенсатор АКМ.", "slot_type": "muzzle", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true})
	_register({"id": "pkm_muz_std", "name": "Штатный щелевой пламегаситель ПКМ", "short_name": "ШТАТНЫЙ", "description": "Стандартный пламегаситель ПКМ.", "slot_type": "muzzle", "price": 0, "compatible_weapons": ["pkm"], "is_vanilla_default": true})
	_register({"id": "l96_muz_std", "name": "Штатный ДТК Accuracy International", "short_name": "ДТК AI", "description": "Двухкамерный дульный тормоз L96A1.", "slot_type": "muzzle", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true})
	_register({"id": "aa_muz_std", "name": "Штатная дульная гайка AA-12", "short_name": "ШТАТНАЯ", "description": "Заводская защитная дульная гайка ствола AA-12.", "slot_type": "muzzle", "price": 0, "compatible_weapons": ["aa12"], "is_vanilla_default": true})
	_register({"id": "mg_muz_std", "name": "Штатный конический усилитель MG 42", "short_name": "УСИЛИТЕЛЬ", "description": "Стандартный конический усилитель отдачи MG 42.", "slot_type": "muzzle", "price": 0, "compatible_weapons": ["mg42"], "is_vanilla_default": true})

	_register({"id": "muz_dtk2", "name": "Реактивный ДТК Зенит ДТК-2", "short_name": "ДТК-2", "description": "Агрессивный двухкамерный дульный тормоз-компенсатор: режет вертикальную отдачу на 20%!", "slot_type": "muzzle", "price": 95, "compatible_weapons": ["ak47", "kar98k", "pkm", "l96a1", "mg42", "pistol", "aa12"], "recoil_pitch_mult": 0.80, "recoil_yaw_mult": 0.86, "spread_mult": 0.92})
	_register({"id": "muz_deagle_10", "name": "Удлинённый 10\" ствол с ДТК (Deagle)", "short_name": "СТВОЛ 10\"", "description": "Легендарный 10-дюймовый матчевый ствол с портами компенсатора! +14% урона, резко снижает разброс и отдачу.", "slot_type": "muzzle", "price": 150, "compatible_weapons": ["deagle"], "damage_mult": 1.14, "spread_mult": 0.68, "recoil_pitch_mult": 0.78, "ergonomics_add": -5.0})
	_register({"id": "muz_choke_full", "name": "Усиленный дульный чок (Сужение)", "short_name": "ЧОК", "description": "Стягивает осыпь дроби на 35% и увеличивает эффективную дальность боя!", "slot_type": "muzzle", "price": 85, "compatible_weapons": ["shotgun", "aa12"], "spread_mult": 0.65, "damage_mult": 1.06})
	_register({"id": "muz_duckbill", "name": "Насадка-раструб «Утконос»", "short_name": "РАСТРУБ", "description": "Широкая веерная осыпь для зачистки толпы и сбивания дронов Shahed в полёте!", "slot_type": "muzzle", "price": 75, "compatible_weapons": ["shotgun", "aa12"], "spread_mult": 1.32, "recoil_pitch_mult": 0.88})
	_register({
		"id": "muz_suppressor", "name": "Тактический глушитель (ПБС-1 / AWM / Osprey)", "short_name": "ГЛУШИТЕЛЬ",
		"description": "Полноценный глушитель! Приглушает звук выстрела, почти полностью убирает вспышку, снижает отдачу и повышает кучность.",
		"slot_type": "muzzle", "price": 165, "compatible_weapons": ["ak47", "pistol", "kar98k", "pkm", "l96a1", "deagle", "mg42"],
		"recoil_pitch_mult": 0.85, "recoil_yaw_mult": 0.85, "spread_mult": 0.86, "ergonomics_add": -4.0,
		"mechanics": {"suppressed": true}
	})
	_register({
		"id": "muz_salvo12", "name": "Глушитель дробовика SilencerCo Salvo 12", "short_name": "SALVO 12",
		"description": "Массивный секционный глушитель 12 калибра! Тихий, глухой выстрел, гасит вспышку и отдачу.",
		"slot_type": "muzzle", "price": 175, "compatible_weapons": ["shotgun", "aa12"],
		"recoil_pitch_mult": 0.84, "spread_mult": 0.85, "ergonomics_add": -5.0,
		"mechanics": {"suppressed": true}
	})

	# =========================================================================
	# 10. INTERNAL MECHANISMS (УСМ, ЗАТВОРЫ, БУФЕРЫ ОТДАЧИ, АВТОСПУСК)
	# =========================================================================
	_register({"id": "int_match_trigger", "name": "Матчевый спортивный УСМ", "short_name": "МАТЧ УСМ", "description": "Доведённый короткий спуск: ускоряет темп стрельбы на 14% и улучшает кучность на 15%.", "slot_type": "internal", "price": 120, "compatible_weapons": ["ak47", "pistol", "kar98k", "l96a1", "deagle", "pkm"], "fire_rate_mult": 0.86, "spread_mult": 0.85, "ergonomics_add": 4.0})
	_register({"id": "int_recoil_buffer", "name": "Полиуретановый буфер и титановый поршень", "short_name": "БУФЕР ОТД.", "description": "Сглаживает удар затворной рамы в крайнем заднем положении: -18% отдачи.", "slot_type": "internal", "price": 135, "compatible_weapons": ["ak47", "pkm", "deagle", "aa12"], "recoil_pitch_mult": 0.82, "recoil_yaw_mult": 0.84})
	_register({"id": "int_fast_bolt", "name": "Облегчённый полированный затвор", "short_name": "БЫСТР. ЗАТВОР", "description": "Снижает массу подвижных частей: заметно ускоряет скорострельность (+22% RPM) и цикл затвора!", "slot_type": "internal", "price": 150, "compatible_weapons": ["kar98k", "l96a1", "shotgun", "aa12", "mg42"], "fire_rate_mult": 0.80, "recoil_pitch_mult": 1.08})
	_register({"id": "int_mg42_heavy_bolt", "name": "Утяжелённый затвор MG3 (850 выстр/мин)", "short_name": "ЗАТВОР MG3", "description": "Утяжеляет затвор MG 42, снижая темп с 1200 до контролируемых 850 выстр/мин — экономит патроны и гасит отдачу на 28%!", "slot_type": "internal", "price": 140, "compatible_weapons": ["mg42"], "fire_rate_mult": 1.40, "recoil_pitch_mult": 0.72, "recoil_yaw_mult": 0.74, "spread_mult": 0.82})
	_register({
		"id": "int_pistol_autosear", "name": "Автоспуск Glock 18C (Очередь / Авто)", "short_name": "АВТОСПУСК",
		"description": "Открывает переключение режимов огня [X] на пистолете: ОДИН. / ОЧЕРЕДЬ x3 / АВТО (1000 выстр/мин)!",
		"slot_type": "internal", "price": 185, "compatible_weapons": ["pistol"],
		"fire_rate_mult": 0.82, "recoil_pitch_mult": 1.15,
		"mechanics": {"unlock_fire_modes": ["semi", "burst", "auto"]}
	})

	# =========================================================================
	# 11. AMMO TYPE SELECTION (ВЫБОР ПАТРОНОВ С РЕАЛЬНЫМИ МЕХАНИКАМИ И ЭКОНОМИКОЙ!)
	# =========================================================================
	# 7.62x39 (AK-47)
	_register({"id": "ammo_762x39_fmj", "name": "7.62×39 ПС (Штатные FMJ)", "short_name": "7.62 ПС", "description": "Стандартные армейские патроны со стальным сердечником.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["ak47"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 42}})
	_register({"id": "ammo_762x39_ap", "name": "7.62×39 БП (Бронебойные AP)", "short_name": "7.62 БП", "description": "Термоупрочнённый сердечник! +15% урона и x1.65 пробитие по Бусику и Tiger I, но выше верт./гориз. отдача (+15%).", "slot_type": "ammo_type", "price": 110, "compatible_weapons": ["ak47"], "damage_mult": 1.15, "recoil_pitch_mult": 1.15, "recoil_yaw_mult": 1.14, "spread_mult": 0.94, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.65, "shop_price": 62}})
	_register({"id": "ammo_762x39_hp", "name": "7.62×39 HP (Экспансивные)", "short_name": "7.62 HP", "description": "Экспансивная пуля (+24% урона по пехоте, мягче отдача -6%, но разброс чуть шире +10%).", "slot_type": "ammo_type", "price": 95, "compatible_weapons": ["ak47"], "damage_mult": 1.24, "recoil_pitch_mult": 0.94, "recoil_yaw_mult": 0.94, "spread_mult": 1.10, "mechanics": {"ammo_mode": "hp", "armor_pen_mult": 0.65, "shop_price": 54}})
	_register({"id": "ammo_762x39_us", "name": "7.62×39 УС (Дозвуковые)", "short_name": "7.62 УС", "description": "Тяжёлые дозвуковые патроны: -28% верт. отдачи, -25% гориз. отдачи, -20% разброса и сверхтихий выстрел!", "slot_type": "ammo_type", "price": 90, "compatible_weapons": ["ak47"], "damage_mult": 0.92, "recoil_pitch_mult": 0.72, "recoil_yaw_mult": 0.75, "spread_mult": 0.80, "mechanics": {"ammo_mode": "subsonic", "shop_price": 56}})

	# 12 Gauge (Pump Shotgun + AA-12)
	_register({"id": "ammo_12ga_buck", "name": "12G Картечь 00 (Штатная)", "short_name": "КАРТЕЧЬ", "description": "Классическая 8-дробиновая картечь 12 калибра. Сбивает Shahed с 1 выстрела.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["shotgun", "aa12"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "buck", "shop_price": 7}})
	_register({
		"id": "ammo_12ga_slug", "name": "12G Пулевой патрон AP-20 Slug", "short_name": "ПУЛЯ SLUG",
		"description": "Заменяет дробь на ОДНУ тяжёлую бронебойную пулю без падения урона с дистанцией! Резко меньше разброс, выше отдача.",
		"slot_type": "ammo_type", "price": 125, "compatible_weapons": ["shotgun", "aa12"],
		"damage_mult": 9.8, "spread_mult": 0.14, "recoil_pitch_mult": 1.22, "recoil_yaw_mult": 1.15,
		"mechanics": {"ammo_mode": "slug", "pellets_override": 1, "has_falloff_override": false, "armor_pen_mult": 1.55, "shop_price": 12}
	})
	_register({
		"id": "ammo_12ga_dragon", "name": "12G «Дыхание Дракона» (Зажигательные)", "short_name": "ДРАКОН 🔥",
		"description": "Магниевый зажигательный заряд! Огненный сноп искр, +28% урона вблизи, шире разброс и сильнее отдача.",
		"slot_type": "ammo_type", "price": 135, "compatible_weapons": ["shotgun", "aa12"],
		"damage_mult": 1.28, "spread_mult": 1.18, "recoil_pitch_mult": 1.14, "recoil_yaw_mult": 1.16,
		"mechanics": {"ammo_mode": "dragons_breath", "incendiary": true, "shop_price": 14}
	})
	_register({
		"id": "ammo_12ga_flechette", "name": "12G Флешетта (Бронебойные иглы)", "short_name": "ФЛЕШЕТТА",
		"description": "Стальные оперенные стрелки: кучная осыпь (-22% разброса), -8% отдачи и x1.70 по бронетехнике!",
		"slot_type": "ammo_type", "price": 120, "compatible_weapons": ["shotgun", "aa12"],
		"damage_mult": 1.08, "spread_mult": 0.78, "recoil_pitch_mult": 0.92, "recoil_yaw_mult": 0.90,
		"mechanics": {"ammo_mode": "flechette", "armor_pen_mult": 1.70, "shop_price": 11}
	})

	# 9x19 (Pistol)
	_register({"id": "ammo_9x19_fmj", "name": "9×19 Parabellum FMJ", "short_name": "9мм FMJ", "description": "Стандартные пистолетные патроны 9×19 мм.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["pistol"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 22}})
	_register({"id": "ammo_9x19_ap", "name": "9×19 7Н31 (Бронебойные AP)", "short_name": "9мм AP", "description": "Высокоимпульсные бронебойные (+18% урона, x1.65 по броне, +14% отдачи, -8% разброса).", "slot_type": "ammo_type", "price": 90, "compatible_weapons": ["pistol"], "damage_mult": 1.18, "recoil_pitch_mult": 1.14, "recoil_yaw_mult": 1.12, "spread_mult": 0.92, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.65, "shop_price": 34}})
	_register({"id": "ammo_9x19_rip", "name": "9×19 RIP (Экспансивные)", "short_name": "9мм RIP", "description": "Фрагментирующаяся пуля: +30% урона по пехоте, мягче отдача (-10%), но разброс +12%.", "slot_type": "ammo_type", "price": 95, "compatible_weapons": ["pistol"], "damage_mult": 1.30, "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.92, "spread_mult": 1.12, "mechanics": {"ammo_mode": "hp", "armor_pen_mult": 0.60, "shop_price": 36}})

	# 7.92x57 (Kar98k + MG 42)
	_register({"id": "ammo_792_ss", "name": "7.92×57 sS (Штатные)", "short_name": "7.92 sS", "description": "Стандартные винтовочные патроны Mauser.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["kar98k", "mg42"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 45}})
	_register({"id": "ammo_792_smk", "name": "7.92×57 SmK (Бронебойные AP)", "short_name": "7.92 SmK", "description": "Немецкие бронебойные с закалённым сердечником (+18% урона, x1.70 по технике, +14% верт./гориз. отдачи, -10% разброса).", "slot_type": "ammo_type", "price": 125, "compatible_weapons": ["kar98k", "mg42"], "damage_mult": 1.18, "recoil_pitch_mult": 1.14, "recoil_yaw_mult": 1.14, "spread_mult": 0.90, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.70, "shop_price": 68}})
	_register({"id": "ammo_792_hp", "name": "7.92×57 Экспансивные HP", "short_name": "7.92 HP", "description": "Тяжёлая экспансивная пуля (+26% урона по пехоте, -8% отдачи, +10% разброса).", "slot_type": "ammo_type", "price": 115, "compatible_weapons": ["kar98k", "mg42"], "damage_mult": 1.26, "recoil_pitch_mult": 0.92, "recoil_yaw_mult": 0.92, "spread_mult": 1.10, "mechanics": {"ammo_mode": "hp", "armor_pen_mult": 0.65, "shop_price": 60}})

	# 7.62x54R (PKM)
	_register({"id": "ammo_762x54r_lps", "name": "7.62×54R ЛПС (Штатные)", "short_name": "54R ЛПС", "description": "Штатная пулемётная лента 7.62×54R.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["pkm"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 68}})
	_register({"id": "ammo_762x54r_bs", "name": "7.62×54R БС (Вольфрамовые AP)", "short_name": "54R БС", "description": "Бронебойно-зажигательные с вольфрамовым сердечником! +20% урона, x1.75 по технике, +15% верт./гориз. отдачи.", "slot_type": "ammo_type", "price": 145, "compatible_weapons": ["pkm"], "damage_mult": 1.20, "recoil_pitch_mult": 1.15, "recoil_yaw_mult": 1.16, "spread_mult": 0.95, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.75, "incendiary": true, "shop_price": 98}})
	_register({"id": "ammo_762x54r_hp", "name": "7.62×54R Экспансивные HP", "short_name": "54R HP", "description": "+25% урона по пехоте, сниженная отдача (-10%), разброс +8%.", "slot_type": "ammo_type", "price": 120, "compatible_weapons": ["pkm"], "damage_mult": 1.25, "recoil_pitch_mult": 0.90, "recoil_yaw_mult": 0.90, "spread_mult": 1.08, "mechanics": {"ammo_mode": "hp", "armor_pen_mult": 0.65, "shop_price": 84}})

	# .338 Lapua Magnum (L96A1)
	_register({"id": "ammo_338_match", "name": ".338 Lapua Magnum Match", "short_name": ".338 MATCH", "description": "Высокоточные снайперские патроны .338 LM.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["l96a1"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 55}})
	_register({"id": "ammo_338_ap", "name": ".338 LM AP (Бронебойные)", "short_name": ".338 AP", "description": "Противоматериальный бронебойный патрон! +25% урона, x1.85 по броне, -15% разброса, но отдача +16%.", "slot_type": "ammo_type", "price": 165, "compatible_weapons": ["l96a1"], "damage_mult": 1.25, "recoil_pitch_mult": 1.16, "recoil_yaw_mult": 1.14, "spread_mult": 0.85, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.85, "shop_price": 82}})
	_register({"id": "ammo_338_hp", "name": ".338 LM Hollow-Point", "short_name": ".338 HP", "description": "Колоссальный останавливающий эффект (+32% урона по пехоте, -8% отдачи, +15% разброса).", "slot_type": "ammo_type", "price": 140, "compatible_weapons": ["l96a1"], "damage_mult": 1.32, "recoil_pitch_mult": 0.92, "recoil_yaw_mult": 0.92, "spread_mult": 1.15, "mechanics": {"ammo_mode": "hp", "armor_pen_mult": 0.70, "shop_price": 72}})

	# .50 AE (Desert Eagle)
	_register({"id": "ammo_50ae_jhp", "name": ".50 AE JHP (Штатные)", "short_name": ".50 JHP", "description": "Стандартные тяжёлые патроны .50 Action Express.", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["deagle"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "fmj", "shop_price": 36}})
	_register({"id": "ammo_50ae_ap", "name": ".50 AE Бронебойные (Твёрдый сплав)", "short_name": ".50 AP", "description": "+20% урона, x1.70 по броне, -10% разброса, но отдача +16%.", "slot_type": "ammo_type", "price": 115, "compatible_weapons": ["deagle"], "damage_mult": 1.20, "recoil_pitch_mult": 1.16, "recoil_yaw_mult": 1.14, "spread_mult": 0.90, "mechanics": {"ammo_mode": "ap", "armor_pen_mult": 1.70, "shop_price": 54}})
	_register({"id": "ammo_50ae_inc", "name": ".50 AE Зажигательные 🔥", "short_name": ".50 ЗАЖИГ.", "description": "Яркий сноп огня, +26% урона, отдача +10%, разброс +14%!", "slot_type": "ammo_type", "price": 125, "compatible_weapons": ["deagle"], "damage_mult": 1.26, "recoil_pitch_mult": 1.10, "recoil_yaw_mult": 1.12, "spread_mult": 1.14, "mechanics": {"ammo_mode": "incendiary", "incendiary": true, "shop_price": 58}})

	# RPG-7 Warheads
	_register({"id": "ammo_rpg_pg7v", "name": "ПГ-7В (Штатная кумулятивная)", "short_name": "ПГ-7В", "description": "Штатная 85-мм граната (900 урона, радиус 16.5 м).", "slot_type": "ammo_type", "price": 0, "compatible_weapons": ["rpg"], "is_vanilla_default": true, "mechanics": {"ammo_mode": "standard", "shop_price": 150}})
	_register({"id": "ammo_rpg_tandem", "name": "ПГ-7ВР «Резюме» (Тандемная)", "short_name": "ПГ-7ВР", "description": "Двухступенчатая тандемная БЧ! Пробивает ДАЖЕ ЛОБОВУЮ БРОНЮ Tiger I, поджигает БК в борт за 2 попадания вместо 3 и даёт кумулятивный сноп искр.", "slot_type": "ammo_type", "price": 195, "compatible_weapons": ["rpg"], "damage_mult": 1.61, "recoil_pitch_mult": 1.15, "mechanics": {"ammo_mode": "tandem", "blast_radius": 12.5, "armor_pen_mult": 1.85, "shop_price": 225}})
	_register({"id": "ammo_rpg_thermo", "name": "ТБГ-7В (Термобарическая)", "short_name": "ТБГ-7В 🔥", "description": "Цилиндрическая объёмно-детонирующая БЧ! Колоссальный двухступенчатый огненный гриб (радиус 25 м), сносит пехоту, модули и командира Tiger I.", "slot_type": "ammo_type", "price": 185, "compatible_weapons": ["rpg"], "damage_mult": 0.95, "mechanics": {"ammo_mode": "thermobaric", "blast_radius": 25.0, "incendiary": true, "shop_price": 215}})

static func _register(cfg: Dictionary) -> void:
	var m = WeaponModScript.make(cfg)
	_mods[m.id] = m

static func get_mod(mod_id: String) -> RefCounted:
	_ensure_init()
	if mod_id == "":
		return null
	return _mods.get(mod_id, null)

static func get_mods_for_slot(weapon_id: String, slot_type: String) -> Array:
	_ensure_init()
	var result: Array = []
	for m in _mods.values():
		if m.slot_type == slot_type and weapon_id in m.compatible_weapons:
			result.append(m)
	result.sort_custom(func(a, b):
		if a.is_vanilla_default != b.is_vanilla_default:
			return a.is_vanilla_default
		return a.price < b.price
	)
	return result

static func is_mod_installed(installed_mods: Dictionary, mod_id: String) -> bool:
	for v in installed_mods.values():
		if str(v) == mod_id:
			return true
	return false

static func get_missing_requirements(installed_mods: Dictionary, req_list: Array, req_any_list: Array = []) -> Array[String]:
	_ensure_init()
	var missing: Array[String] = []
	for req_id in req_list:
		var r_str := str(req_id)
		if not is_mod_installed(installed_mods, r_str):
			var rm := get_mod(r_str)
			missing.append(rm.name if rm else r_str)
	if not req_any_list.is_empty():
		var any_ok := false
		for req_id in req_any_list:
			if is_mod_installed(installed_mods, str(req_id)):
				any_ok = true
				break
		if not any_ok:
			var names: Array[String] = []
			for req_id in req_any_list:
				var rm := get_mod(str(req_id))
				names.append(rm.short_name if rm else str(req_id))
			missing.append(" / ".join(names))
	return missing

static func is_slot_unlocked(installed_mods: Dictionary, slot_def: Dictionary) -> bool:
	var reqs: Array = slot_def.get("requires_mods", [])
	var req_any: Array = slot_def.get("requires_any_mods", [])
	return get_missing_requirements(installed_mods, reqs, req_any).is_empty()

static func can_install_mod(installed_mods: Dictionary, mod_id: String) -> Dictionary:
	_ensure_init()
	if mod_id == "":
		return {"ok": true, "reason": ""}
	var m := get_mod(mod_id)
	if not m:
		return {"ok": false, "reason": "Модификация не найдена"}
	var missing := get_missing_requirements(installed_mods, m.requires_mods, m.requires_any_mods)
	if missing.size() > 0:
		return {"ok": false, "reason": "Требуется: " + ", ".join(missing)}
	for conf_id in m.conflicts_with:
		if is_mod_installed(installed_mods, conf_id):
			var cm := get_mod(conf_id)
			return {"ok": false, "reason": "Конфликт с: " + (cm.name if cm else conf_id)}
	return {"ok": true, "reason": ""}

# Removes any installed mods whose slot or mod requirements are no longer satisfied
static func cleanup_invalid_mods(installed_mods: Dictionary, weapon_id: String = "") -> Array[String]:
	_ensure_init()
	var removed: Array[String] = []
	var slot_map: Dictionary = {}
	if weapon_id != "":
		for sd in get_slot_defs(weapon_id):
			slot_map[sd["slot_type"]] = sd
	var changed := true
	while changed:
		changed = false
		for slot_key in installed_mods.keys():
			var mid := str(installed_mods[slot_key])
			if mid == "":
				continue
			var invalid := false
			if slot_map.has(slot_key):
				if not is_slot_unlocked(installed_mods, slot_map[slot_key]):
					invalid = true
			var m := get_mod(mid)
			if m and not get_missing_requirements(installed_mods, m.requires_mods, m.requires_any_mods).is_empty():
				invalid = true
			if invalid:
				installed_mods[slot_key] = ""
				removed.append(mid)
				changed = true
	return removed
