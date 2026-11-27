extends CanvasLayer

const InventoryUIScript = preload("res://scripts/ui/inventory_ui.gd")
const WorkbenchUIScript = preload("res://scripts/ui/workbench_ui.gd")
const CheatMenuUIScript = preload("res://scripts/ui/cheat_menu_ui.gd")
const MapTravelUIScript = preload("res://scripts/ui/map_travel_ui.gd")
const TigerBossHUDScript = preload("res://scripts/ui/tiger_boss_hud.gd")
const Mi24BossHUDScript = preload("res://scripts/ui/mi24_boss_hud.gd")
const WeaponModDBScript = preload("res://scripts/weapons/weapon_mod_db.gd")

var tiger_boss_hud: PanelContainer = null
var mi24_boss_hud: PanelContainer = null
var boss_warning_label: Label = null
var boss_warning_flash_t: float = 0.0

@onready var health_bar: ProgressBar = $BottomLeft/HealthBar
@onready var health_label: Label = $BottomLeft/HealthLabel
@onready var armor_bar: ProgressBar = $BottomLeft/ArmorBar
@onready var armor_label: Label = $BottomLeft/ArmorLabel

# Stamina UI
@onready var stamina_bar: ProgressBar = $BottomLeft/StaminaBarContainer/StaminaBar
@onready var stamina_label: Label = $BottomLeft/StaminaLabel

@onready var ammo_label: Label = $BottomRight/AmmoLabel
@onready var reload_label: Label = $BottomRight/ReloadLabel
@onready var weapon_label: Label = $BottomRight/WeaponLabel

@onready var weapon_1_card: PanelContainer = $TopRight/WeaponList/W1
@onready var weapon_1_label: Label = $TopRight/WeaponList/W1/Label
@onready var weapon_2_card: PanelContainer = $TopRight/WeaponList/W2
@onready var weapon_2_label: Label = $TopRight/WeaponList/W2/Label
@onready var weapon_3_card: PanelContainer = $TopRight/WeaponList/W3
@onready var weapon_3_label: Label = $TopRight/WeaponList/W3/Label
@onready var weapon_5_card: PanelContainer = $TopRight/WeaponList/W5
@onready var weapon_5_label: Label = $TopRight/WeaponList/W5/Label
@onready var knife_card: PanelContainer = $KnifeCard

@onready var score_label: Label = $TopLeft/ScoreLabel
@onready var wave_label: Label = $TopLeft/WaveLabel

@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var crosshair_node: Control = $Crosshair
@onready var hitmarker: Control = $Crosshair/Hitmarker

# Dynamic EFT UI Panels (Inventory [I], Workbench [N], Cheat Menu [}], Map Travel [M])
var inventory_ui: Panel = null
var workbench_ui: Panel = null
var cheat_menu_ui: Panel = null
var map_travel_ui: Panel = null
var arena_interact_prompt_label: Label = null
var arena_toast_label: Label = null
var arena_toast_tween: Tween = null
var inventory_hud_badge: PanelContainer = null
var workbench_zone_prompt_label: Label = null
var ads_reticle_overlay: Control = null
var ads_zoom_label: Label = null
var ads_blur_overlay: ColorRect = null
var ads_blur_mat: ShaderMaterial = null
var tactical_status_label: Label = null
var ugl_reticle_overlay: Control = null
var ugl_reticle_hint_label: Label = null
var is_ugl_hud_active: bool = false
var eft_quickbar_container: HBoxContainer = null
var eft_quickbar_cells: Array[Dictionary] = [] # [{panel, label, key_lbl, style}]
var eft_knife_cell: Dictionary = {} # {panel, label, key_lbl, style} — positioned left of Slot 1
var eft_knife_tween: Tween = null

# Death Screen
@onready var game_over_panel: Panel = $GameOverPanel
@onready var death_stats_label: Label = $GameOverPanel/VBox/StatsLabel

# Shop Defense Health Bar
var shop_hp_container: Control = null
var shop_hp_bar: ProgressBar = null
var shop_hp_label: Label = null
var shop_hp_title: Label = null
var style_shop_fill_normal: StyleBoxFlat = null
var style_shop_fill_warn: StyleBoxFlat = null
var style_shop_fill_danger: StyleBoxFlat = null
var shop_pulse_tween: Tween = null

# Player Respawn Countdown Overlay
var respawn_overlay: Panel = null
var respawn_title: Label = null
var respawn_timer_label: Label = null
var respawn_countdown: float = 0.0
var is_respawning: bool = false

# Top-Right Enemy Counter UI
var enemy_counter_container: PanelContainer = null
var enemy_counter_label: Label = null

# Pause Menu
@onready var pause_panel: Panel = $PausePanel

# Interactive 3D Handbook
@onready var handbook_panel: Panel = $HandbookPanel
@onready var handbook_preview: SubViewportContainer = $HandbookPanel/HBox/RightCol/TopPreview/PreviewContainer
@onready var handbook_title: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/ItemTitle
@onready var handbook_stats: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/Scroll/ItemStats

# Handbook Graphical Stats Bars
@onready var hb_stats_box: GridContainer = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox
@onready var hb_stat1_box: VBoxContainer = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat1_Box
@onready var hb_stat1_label: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat1_Box/HB_Stat1_Label
@onready var hb_stat1_bar: ProgressBar = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat1_Box/HB_Stat1_Bar

@onready var hb_stat2_box: VBoxContainer = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat2_Box
@onready var hb_stat2_label: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat2_Box/HB_Stat2_Label
@onready var hb_stat2_bar: ProgressBar = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat2_Box/HB_Stat2_Bar

@onready var hb_stat3_box: VBoxContainer = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat3_Box
@onready var hb_stat3_label: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat3_Box/HB_Stat3_Label
@onready var hb_stat3_bar: ProgressBar = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat3_Box/HB_Stat3_Bar

@onready var hb_stat4_box: VBoxContainer = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat4_Box
@onready var hb_stat4_label: Label = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat4_Box/HB_Stat4_Label
@onready var hb_stat4_bar: ProgressBar = $HandbookPanel/HBox/RightCol/BottomStats/Margin/VBox/HB_StatsBox/HB_Stat4_Box/HB_Stat4_Bar

# Wave Warmup Banner
@onready var wave_banner: PanelContainer = $WaveBanner
@onready var wave_banner_title: Label = $WaveBanner/VBox/Title
@onready var wave_banner_intel: Label = $WaveBanner/VBox/Intel
@onready var wave_banner_hint: Label = $WaveBanner/VBox/ShopHint

# Field Shop (Handbook-style layout with 3D Preview)
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_preview: SubViewportContainer = $ShopPanel/HBox/RightCol/TopPreview/PreviewContainer
@onready var shop_balance_label: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/TopHBox/BalanceLabel
@onready var shop_item_title: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/TopHBox/ItemTitle
@onready var shop_price_badge: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/PriceBadge
@onready var shop_item_desc: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/ItemDesc

@onready var shop_stat1_box: VBoxContainer = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat1_Box
@onready var shop_stat1_label: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat1_Box/Stat1_Label
@onready var shop_stat1_bar: ProgressBar = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat1_Box/Stat1_Bar

@onready var shop_stat2_box: VBoxContainer = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat2_Box
@onready var shop_stat2_label: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat2_Box/Stat2_Label
@onready var shop_stat2_bar: ProgressBar = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat2_Box/Stat2_Bar

@onready var shop_stat3_box: VBoxContainer = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat3_Box
@onready var shop_stat3_label: Label = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat3_Box/Stat3_Label
@onready var shop_stat3_bar: ProgressBar = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/Stat3_Box/Stat3_Bar

@onready var shop_buy_btn: Button = $ShopPanel/HBox/RightCol/BottomDetails/Margin/VBox/BuyItemBtn

var damage_tween: Tween
var hitmarker_tween: Tween
var knife_card_tween: Tween
var current_wave_num: int = 1
var final_score: int = 0
var is_game_over: bool = false
var current_slot: int = 1

# Stamina StyleBoxes
var style_stamina_blue: StyleBoxFlat
var style_stamina_red: StyleBoxFlat

# Shop catalog database (rebalanced hardcore economy)
var current_shop_item_id: String = "ak"
var shop_catalog = {
	"ak": {
		"title": "ПАТРОНЫ АК-47 (7.62x39)",
		"price": 42,
		"desc": "Коробчатый магазин на 30 патронов 7.62x39 мм для АК-47. Берегите боекомплект — стрельба короткими очередями в прицеле [ПКМ] окупается сторицей.",
		"stat1_label": "Боезапас в пачке: +30 патронов",
		"stat1_val": 30.0,
		"stat1_max": 60.0,
		"stat2_label": "Урон за пулю: 32 ед.",
		"stat2_val": 32.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 30 ПАТРОНОВ ($42)"
	},
	"shotgun": {
		"title": "КАРТЕЧЬ 12 GAUGE (ДРОБОВИК / AA-12)",
		"price": 7,
		"desc": "Тяжелый патрон 12 калибра. ОБЩИЙ боезапас для Помпового дробовика и AA-12! Смертоносен в упор и сбивает БПЛА Shahed с одного выстрела.",
		"stat1_label": "Боезапас в пачке: +1 патрон (Общий 12G)",
		"stat1_val": 1.0,
		"stat1_max": 10.0,
		"stat2_label": "Урон залпа: 144 / 128 ед. (8 дробин)",
		"stat2_val": 144.0,
		"stat2_max": 200.0,
		"btn_text": "КУПИТЬ 1 ПАТРОН ($7)"
	},
	"pistol": {
		"title": "ПАТРОНЫ ПИСТОЛЕТА (9x19)",
		"price": 22,
		"desc": "Магазин на 17 патронов 9x19 мм. Самый экономичный калибр для добивания и прицельной стрельбы по уязвимым точкам.",
		"stat1_label": "Боезапас в пачке: +17 патронов",
		"stat1_val": 17.0,
		"stat1_max": 34.0,
		"stat2_label": "Урон за пулю: 26 ед.",
		"stat2_val": 26.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 17 ПАТРОНОВ ($22)"
	},
	"rpg_launcher": {
		"title": "РПГ-7 (ГРАНАТОМЕТ)",
		"price": 460,
		"desc": "Противотанковый гранатомет с оптикой ПГО-7 (2x–4x). Поставляется с 1 гранатой ПГ-7В. Мгновенно взрывает Бусик и поджигает боекомплект Tiger I тремя попаданиями в борт. Экипировка: Инвентарь [I].",
		"stat1_label": "Урон взрыва: 900 ед. (Радиус 16.5 м)",
		"stat1_val": 900.0,
		"stat1_max": 900.0,
		"stat2_label": "Комплект: Гранатомет + 1 граната ПГ-7В",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ РПГ-7 ($460)"
	},
	"rpg": {
		"title": "ГРАНАТА ПГ-7В ДЛЯ РПГ-7 (85 мм)",
		"price": 150,
		"desc": "Реактивная граната ПГ-7В с удлинённым ускорителем. Дорогой, но сокрушительный аргумент против техники и плотных скоплений врагов.",
		"stat1_label": "Боезапас: +1 граната ПГ-7В",
		"stat1_val": 1.0,
		"stat1_max": 5.0,
		"stat2_label": "Урон взрыва: 900 ед. (Радиус 16.5 м)",
		"stat2_val": 900.0,
		"stat2_max": 900.0,
		"btn_text": "КУПИТЬ 1 ГРАНАТУ ($150)"
	},
	"kar98k_weapon": {
		"title": "KAR98K (ВИНТОВКА MAUSER)",
		"price": 320,
		"desc": "Классическая болтовая винтовка 7.92×57 мм Mauser с обойменным заряжанием. Высочайший урон за выстрел. ОБЩИЙ боезапас 7.92×57 с пулеметом MG 42! В комплекте 5+15 патронов. Экипировка: Инвентарь [I].",
		"stat1_label": "Урон: 135 ед. (Болтовка 5 патр.)",
		"stat1_val": 135.0,
		"stat1_max": 250.0,
		"stat2_label": "Калибр: 7.92×57 мм (Общий с MG 42)",
		"stat2_val": 90.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ KAR98K ($320)"
	},
	"deagle_weapon": {
		"title": "DESERT EAGLE (.50 AE)",
		"price": 340,
		"desc": "Тяжелый хромированный пистолет-пушка под калибр .50 Action Express. Пробивает любую цель на раз, громогласный выстрел и мощный ход затвора. В комплекте 7+21 патрон. Экипировка: Инвентарь [I].",
		"stat1_label": "Урон: 84 ед. (Магазин 7+1)",
		"stat1_val": 84.0,
		"stat1_max": 250.0,
		"stat2_label": "Калибр: .50 AE (Тритиевые прицельные)",
		"stat2_val": 85.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ DESERT EAGLE ($340)"
	},
	"aa12_weapon": {
		"title": "AA-12 (АВТОМАТИЧЕСКИЙ ДРОБОВИК)",
		"price": 520,
		"desc": "Штурмовой автоматический дробовик с барабаном на 20 патронов (300 выстр/мин). Сбивает БПЛА Shahed с одного выстрела и сметает толпы вблизи. ОБЩИЙ боезапас 12 Gauge с Помповым дробовиком! В комплекте 20+20 патронов.",
		"stat1_label": "Урон залпа: 128 ед. (8x16, 300 RPM)",
		"stat1_val": 128.0,
		"stat1_max": 200.0,
		"stat2_label": "Барабан: 20 патр. (Общий 12G)",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ AA-12 ($520)"
	},
	"pkm_weapon": {
		"title": "ПКМ (ПУЛЕМЕТ КАЛАШНИКОВА)",
		"price": 640,
		"desc": "Советский единый пулемет под винтовочный патрон 7.62×54 мм R. Короб на 100 патронов, темп 650 выстр/мин, надежный и тяжелый аргумент против волн врагов и мотора Бусика. В комплекте 100+100 патронов.",
		"stat1_label": "Урон: 40 ед. (650 RPM, лента 100)",
		"stat1_val": 40.0,
		"stat1_max": 100.0,
		"stat2_label": "Калибр: 7.62×54 мм R",
		"stat2_val": 95.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ ПКМ ($640)"
	},
	"l96a1_weapon": {
		"title": "L96A1 (СНАЙПЕРСКАЯ ВИНТОВКА)",
		"price": 680,
		"desc": "Британская армейская снайперская винтовка калибра .338 Lapua Magnum со встроенной переменной оптикой 3x–8x (колесико мыши). Колоссальный урон 240 ед. и хирургическая точность. В комплекте 5+10 патронов.",
		"stat1_label": "Урон: 240 ед. (Оптика 3.0x–8.0x)",
		"stat1_val": 240.0,
		"stat1_max": 250.0,
		"stat2_label": "Калибр: .338 Lapua Magnum (5+1)",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ L96A1 ($680)"
	},
	"mg42_weapon": {
		"title": "MG 42 (ЦИРКУЛЯРНАЯ ПИЛА)",
		"price": 720,
		"desc": "Безумная скорострельность 1200 выстр/мин и кекс-короб на 100 патронов. Распыляет пехоту за доли секунды. ОБЩИЙ боезапас 7.92×57 мм с Kar98k! В комплекте 100+100 патронов.",
		"stat1_label": "Урон: 30 ед. (1200 RPM, лента 100)",
		"stat1_val": 100.0,
		"stat1_max": 100.0,
		"stat2_label": "Калибр: 7.92×57 мм (Общий с Kar98k)",
		"stat2_val": 95.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ MG 42 ($720)"
	},
	"ammo_792x57": {
		"title": "ПАТРОНЫ 7.92×57 MAUSER (KAR98K / MG 42)",
		"price": 45,
		"desc": "Обоймы и лента винтовочных патронов 7.92×57 мм Mauser. ОБЩИЙ боезапас одновременно для Kar98k и MG 42!",
		"stat1_label": "Боезапас в пачке: +25 патронов",
		"stat1_val": 25.0,
		"stat1_max": 50.0,
		"stat2_label": "Совместимость: Kar98k + MG 42",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 25 ПАТРОНОВ ($45)"
	},
	"ammo_762x54r": {
		"title": "ЛЕНТА 7.62×54R ДЛЯ ПКМ",
		"price": 68,
		"desc": "Металлическая пулеметная лента с фланцевыми винтовочными патронами 7.62×54 мм R для ПКМ.",
		"stat1_label": "Боезапас в пачке: +50 патронов",
		"stat1_val": 50.0,
		"stat1_max": 100.0,
		"stat2_label": "Урон за пулю (ПКМ): 40 ед.",
		"stat2_val": 40.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 50 ПАТРОНОВ ($68)"
	},
	"ammo_338lm": {
		"title": "ПАТРОНЫ .338 LAPUA MAGNUM (L96A1)",
		"price": 55,
		"desc": "Высокоточные дальнобойные патроны .338 Lapua Magnum Match для снайперской винтовки L96A1.",
		"stat1_label": "Боезапас в пачке: +5 патронов",
		"stat1_val": 5.0,
		"stat1_max": 10.0,
		"stat2_label": "Урон за пулю (L96A1): 240 ед.",
		"stat2_val": 240.0,
		"stat2_max": 250.0,
		"btn_text": "КУПИТЬ 5 ПАТРОНОВ ($55)"
	},
	"ammo_50ae": {
		"title": "ПАТРОНЫ .50 AE (DESERT EAGLE)",
		"price": 36,
		"desc": "Тяжелые крупнокалиберные патроны .50 Action Express с плоской полуоболочечной пулей для Desert Eagle.",
		"stat1_label": "Боезапас в пачке: +14 патронов",
		"stat1_val": 14.0,
		"stat1_max": 28.0,
		"stat2_label": "Урон за пулю (Deagle): 84 ед.",
		"stat2_val": 84.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 14 ПАТРОНОВ ($36)"
	},
	"ammo_ugl": {
		"title": "ГРАНАТЫ 40мм ВОГ-25 / M406 (ПОДСТВОЛЬНИК)",
		"price": 45,
		"desc": "Боекомплект из 3 осколочных гранат 40 мм для подствольных гранатомётов ГП-25 и M203. [G] — режим гранатомёта, [ЛКМ] — пуск (взведение после 14 м полёта), [R] — зарядка.",
		"stat1_label": "Боезапас в пачке: +3 гранаты 40 мм",
		"stat1_val": 3.0,
		"stat1_max": 6.0,
		"stat2_label": "Урон взрыва: 480 ед. (Радиус 8.5 м)",
		"stat2_val": 480.0,
		"stat2_max": 600.0,
		"btn_text": "КУПИТЬ 3 ГРАНАТЫ 40мм ($45)"
	},
	"workbench": {
		"title": "ВЕРСТАК МОДИФИКАЦИИ ОРУЖИЯ",
		"price": 280,
		"desc": "Устанавливается в центре карты. Нажмите [N] рядом с верстаком, чтобы глубоко модифицировать ВСЕ 10 стволов: прицелы (коллиматоры, LPVO, ПНВ 1ПН93, тепловизор FLIR), магазины/барабаны, подствольные гранатомёты ГП-25/M203, ЛЦУ, фонари, цевья, трубы и приклады, УСМ, глушители и типы патронов.",
		"stat1_label": "Функционал: Модификация ВСЕХ 10 стволов [N]",
		"stat1_val": 100.0,
		"stat1_max": 100.0,
		"stat2_label": "Установка: Центр арены (разовая покупка)",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ ВЕРСТАК ($280)"
	},
	"medkit": {
		"title": "БОЛЬШАЯ ПОЛЕВАЯ АПТЕЧКА",
		"price": 75,
		"desc": "Войсковой реанимационный комплект с гемостатиками. Мгновенно восстанавливает +50 HP.",
		"stat1_label": "Восстановление здоровья: +50 HP",
		"stat1_val": 50.0,
		"stat1_max": 100.0,
		"btn_text": "КУПИТЬ АПТЕЧКУ ($75)"
	},
	"weapon_slot_4": {
		"title": "ДОПОЛНИТЕЛЬНЫЙ СЛОТ ОРУЖИЯ [4]",
		"price": 600,
		"desc": "Открывает 4-й быстрый слот под огнестрельное оружие! Позволяет носить 4 ствола одновременно и мгновенно переключаться клавишей [4]. Назначение — в Инвентаре [I].",
		"stat1_label": "Открывает слот: [4] (Огнестрельное)",
		"stat1_val": 100.0,
		"stat1_max": 100.0,
		"stat2_label": "Покупка: Навсегда на текущую игру",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ СЛОТ [4] ($600)"
	},
	"weapon_slot_5": {
		"title": "ДОПОЛНИТЕЛЬНЫЙ СЛОТ ОРУЖИЯ [5]",
		"price": 600,
		"desc": "Открывает 5-й быстрый слот под огнестрельное оружие! Позволяет носить до 5 стволов на быстром доступе [1]–[5]. Назначение — в Инвентаре [I].",
		"stat1_label": "Открывает слот: [5] (Огнестрельное)",
		"stat1_val": 100.0,
		"stat1_max": 100.0,
		"stat2_label": "Покупка: Навсегда на текущую игру",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ СЛОТ [5] ($600)"
	},
	"vodka": {
		"title": "ВОДКА \"ЧЕКУНЕЦ 67\"",
		"price": 67,
		"desc": "Легендарная 40-градусная: +6–7 HP, двойная выносливость (300) и спринт x1.5 на 15 сек без усталости. Быстрый слот [6], до 3 шт.",
		"stat1_label": "Лечение: +6-7 HP",
		"stat1_val": 7.0,
		"stat1_max": 20.0,
		"stat2_label": "Выносливость: x2 (300) / 15 сек",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ ЧЕКУНЕЦ 67 ($67)"
	},
	"heavy_armor": {
		"title": "СВЕРХТЯЖЕЛЫЙ БРОНЕЖИЛЕТ (150 БР)",
		"price": 220,
		"desc": "Штурмовой комплекс 6А (150 брони). Входящий урон режется вдвое, затем делится 50/50 между HP и броней. Работает пока броня >= 76.",
		"stat1_label": "Запас брони: 150 ед.",
		"stat1_val": 150.0,
		"stat1_max": 250.0,
		"stat2_label": "Поглощение урона: -50% + Сплит",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ СВЕРХТЯЖЕЛЫЙ ($220)"
	},
	"armor_plate": {
		"title": "БРОНЕПЛИТА ДЛЯ СВЕРХТЯЖЕЛОГО (+30)",
		"price": 65,
		"desc": "Сменная титано-керамическая бронеплита (+30 брони, до 150). Доступна только при активном сверхтяжелом жилете (броня >= 76).",
		"stat1_label": "Восстановление брони: +30 ед.",
		"stat1_val": 30.0,
		"stat1_max": 50.0,
		"btn_text": "КУПИТЬ БРОНЕПЛИТУ ($65)"
	}
}

# Handbook item database (concise mechanics + updated innovations + all funny dossiers!)
var handbook_db = {
	"ak47": {
		"title": "АК-47 (АВТОМАТ КАЛАШНИКОВА)",
		"bars": [
			{"name": "Урон: 32 ед.", "val": 32.0, "max": 200.0},
			{"name": "Темп стрельбы: 545 выстр/мин", "val": 545.0, "max": 900.0},
			{"name": "Магазин: 30+1 (Пачка: $42)", "val": 75.0, "max": 100.0},
			{"name": "Модификации: Верстак [N]", "val": 100.0, "max": 100.0}
		],
		"stats": "• Прицеливание на [ПКМ] (мушка по умолчанию). На Верстаке [N] можно поставить планку Пикатинни ($75), коллиматор ($110) или прицел LPVO 1.5x–4x ($175, колесико мыши меняет кратность).\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Легендарная надежность газоотводной автоматики. Басовитый выстрел и лязг затвора внушают первобытный ужас в космических захватчиков, но патроны теперь на вес золота — зажимать в небо себе дороже.»"
	},
	"shotgun": {
		"title": "ПОМПОВЫЙ ДРОБОВИК",
		"bars": [
			{"name": "Урон залпа: 144 ед. (8x18)", "val": 144.0, "max": 200.0},
			{"name": "Магазин: 5+1 (1 патрон: $7)", "val": 60.0, "max": 100.0},
			{"name": "Дальность: до 18 м", "val": 35.0, "max": 100.0},
			{"name": "ПВО против Shahed: 1 выстрел", "val": 100.0, "max": 100.0}
		],
		"stats": "• Поддерживает прицеливание [ПКМ] для сужения разброса.\n• Главная фишка: любая одна картечина сбивает БПЛА Shahed мгновенно!\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Оглушительный грохот картечного залпа и смачный клац цевья. Идеальный аргумент в споре с летящим Шахедом или Желтым берсерком в узком проходе.»"
	},
	"pistol": {
		"title": "ТАКТИЧЕСКИЙ ПИСТОЛЕТ",
		"bars": [
			{"name": "Урон: 26 ед.", "val": 26.0, "max": 200.0},
			{"name": "Магазин: 17+1 (Пачка: $22)", "val": 80.0, "max": 100.0},
			{"name": "Точность: Высокая", "val": 88.0, "max": 100.0},
			{"name": "Экономичность: Максимальная", "val": 95.0, "max": 100.0}
		],
		"stats": "• Самый дешевый в обслуживании ствол — отлично подходит для экономии патронов АК-47 и точного выцеливания смотровых стекол Tiger I на [ПКМ].\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Верный полимерный Glock, который не просит много денег и всегда выручает, когда основной магазин щелкнул впустую прямо перед носом врага.»"
	},
	"rpg": {
		"title": "РПГ-7 (ГРАНАТОМЕТ)",
		"bars": [
			{"name": "Урон взрыва: 900 ед.", "val": 900.0, "max": 900.0},
			{"name": "Радиус взрыва: 16.5 м", "val": 100.0, "max": 100.0},
			{"name": "Оптика ПГО-7: 2.0x–4.0x", "val": 100.0, "max": 100.0},
			{"name": "Цена: $460 (Ракета: $150)", "val": 90.0, "max": 100.0}
		],
		"stats": "• После покупки экипируется в любой слот [1]–[3] через Инвентарь [I]. Прицеливание [ПКМ] через оптику ПГО-7 (кратность колесиком).\n• Мгновенно взрывает Бусик при попадании в любую часть.\n• Против Tiger I: 1 ракета в корму выбивает двигатель; 3 ракеты в один борт поджигают БК со струёй огня и отрывом башни! Осторожно: взрыв ближе 12.8 м бьет и по игроку.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Абсолютный дипломат калибра 85 мм. Решает любые споры с бронетехникой, но каждая ракета стоит как целая пачка бронеплит — стреляйте с умом и не себе под ноги.»"
	},
	"kar98k": {
		"title": "KAR98K (7.92×57 MAUSER)",
		"bars": [
			{"name": "Урон: 135 ед.", "val": 135.0, "max": 250.0},
			{"name": "Магазин: 5 патр. (Обойма)", "val": 50.0, "max": 100.0},
			{"name": "Точность: Снайперская", "val": 94.0, "max": 100.0},
			{"name": "Общий боезапас: с MG 42", "val": 100.0, "max": 100.0}
		],
		"stats": "• Болтовая винтовка Mauser 98: при пустом магазине заряжается сразу обоймой на 5 патронов с выбиванием пустой планки затвором, а при неполном — по одному патрону вручную (можно прервать выстрелом [ЛКМ]).\n• Делит общий запас патронов 7.92×57 мм с пулеметом MG 42.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Старый добрый дедушкин карабин. Никакой электроники, только клееный фанерный приклад Schichtholz, блестящий затвор и 135 единиц чистого аргумента прямо в визир импостора.»"
	},
	"pkm": {
		"title": "ПКМ (ПУЛЕМЕТ КАЛАШНИКОВА)",
		"bars": [
			{"name": "Урон: 40 ед.", "val": 40.0, "max": 100.0},
			{"name": "Темп стрельбы: 650 выстр/мин", "val": 650.0, "max": 1200.0},
			{"name": "Лента: 100 патр. (7.62×54R)", "val": 100.0, "max": 100.0},
			{"name": "Цена: $640 (Лента 50: $68)", "val": 85.0, "max": 100.0}
		],
		"stats": "• Откидная крышка ствольной коробки и смена зеленого металлического короба на 100 патронов.\n• Великолепно распиливает переднюю часть Бусика и сдерживает целые отряды.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Тяжелый, громкий и абсолютно равнодушный к возражениям противника. Единственный минус — пока меняешь короб, можно успеть допить чай.»"
	},
	"l96a1": {
		"title": "L96A1 (.338 LAPUA MAGNUM)",
		"bars": [
			{"name": "Урон: 240 ед.", "val": 240.0, "max": 250.0},
			{"name": "Оптика PiP: 3.0x–8.0x", "val": 100.0, "max": 100.0},
			{"name": "Магазин: 5+1 (.338 LM)", "val": 60.0, "max": 100.0},
			{"name": "Цена: $680 (5 патр.: $55)", "val": 90.0, "max": 100.0}
		],
		"stats": "• Встроенный оптический прицел 3.0x–8.0x с сеткой Mil-Dot (колесико мыши меняет кратность в [ПКМ]).\n• Самый высокий пулевой урон в игре — сносит любых пехотинцев с одного выстрела.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Зеленая британская аристократка, которая делает аккуратное отверстие диаметром с грецкий орех с другого конца арены.»"
	},
	"deagle": {
		"title": "DESERT EAGLE (.50 AE)",
		"bars": [
			{"name": "Урон: 84 ед.", "val": 84.0, "max": 250.0},
			{"name": "Магазин: 7+1 (.50 AE)", "val": 65.0, "max": 100.0},
			{"name": "Цена: $340 (14 патр.: $36)", "val": 75.0, "max": 100.0}
		],
		"stats": "• Карманная гаубица с затворной задержкой и яркой тритиевой мушкой на [ПКМ].\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Технически это пистолет. Практически — способ вывихнуть запястье себе и сломать планы всем красным крюмейтам в радиусе ста метров.»"
	},
	"aa12": {
		"title": "AA-12 (АВТОМАТИЧЕСКИЙ ДРОБОВИК)",
		"bars": [
			{"name": "Урон залпа: 128 ед. (8x16)", "val": 128.0, "max": 200.0},
			{"name": "Барабан: 20 патр. (300 RPM)", "val": 100.0, "max": 100.0},
			{"name": "ПВО против Shahed: 1 выстрел", "val": 100.0, "max": 100.0},
			{"name": "Общий боезапас: 12G с помпой", "val": 100.0, "max": 100.0}
		],
		"stats": "• Полностью автоматический дробовик с барабаном на 20 патронов. Сбивает Shahed с одного выстрела.\n• Делит общий запас картечи 12 Gauge с Помповым дробовиком.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Зачем целиться, если можно зажать курок и превратить коридор в облако свинца и красных гильз?»"
	},
	"mg42": {
		"title": "MG 42 (7.92×57 MAUSER)",
		"bars": [
			{"name": "Урон: 30 ед.", "val": 30.0, "max": 100.0},
			{"name": "Темп стрельбы: 1200 выстр/мин", "val": 1200.0, "max": 1200.0},
			{"name": "Кекс-лента: 100 патр.", "val": 100.0, "max": 100.0},
			{"name": "Общий боезапас: с Kar98k", "val": 100.0, "max": 100.0}
		],
		"stats": "• Невероятный темп 1200 выстр/мин (20 пуль в секунду!) и откидная крышка при перезарядке кекс-короба.\n• Делит общий запас патронов 7.92×57 мм с Kar98k.\n\n📜 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Звучит как рвущийся брезент, ест патроны быстрее, чем вы успеваете заработать на них, но зрелище стоит каждого доллара.»"
	},
	"knife": {
		"title": "АРМЕЙСКИЙ ШТЫКОВОЙ НОЖ",
		"bars": [
			{"name": "Урон удара: 70 ед.", "val": 70.0, "max": 200.0},
			{"name": "Дальность: 2.8 м", "val": 28.0, "max": 100.0},
			{"name": "Клавиша: [V] (Бесплатно)", "val": 100.0, "max": 100.0}
		],
		"stats": "• Быстрый удар [V] в любой момент — не тратит патроны и идеален для добивания подранков.\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Штатный штык-нож с гравировкой \"Не влезай — зарежет!\". Найден на складе запчастей, где им десять лет подряд открывали консервные банки со сгущенкой и зачищали оптоволоконные кабели. Заточен до состояния лазерной бритвы — рассекает скафандры предателей быстрее, чем они успеют нажать кнопку тревоги!»"
	},
	"enemy_red": {
		"title": "КРАСНЫЙ КРЮМЕЙТ (ИМПОСТОР)",
		"bars": [
			{"name": "Здоровье: 100 HP", "val": 100.0, "max": 300.0},
			{"name": "Скорость: 4.2 м/с", "val": 4.2, "max": 10.0},
			{"name": "АК-47: 10 ед. x 3", "val": 30.0, "max": 60.0},
			{"name": "Награда: $6", "val": 6.0, "max": 20.0}
		],
		"stats": "• Стреляет короткими очередями по 3 патрона из АК-47.\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Бывший корабельный кок с рейса \"Skeld-9\". Зашел в электрощитовую разогреть шаурму на главной энергомагистрали, случайно закоротил силовой кабель и устроил саботаж века. Когда экипаж собрал экстренное совещание, Красный так яростно доказывал, что \"просто чистил картошку разводным ключом\", что случайно выбросил капитана в шлюз. С тех пор бродит с АК-47, палит на каждый шорох и свято верит, что все вокруг — предатели, кроме него.»"
	},
	"enemy_blue": {
		"title": "СИНИЙ КРЮМЕЙТ (СКАУТ)",
		"bars": [
			{"name": "Здоровье: 80 HP", "val": 80.0, "max": 300.0},
			{"name": "Скорость: 6.2 м/с", "val": 6.2, "max": 10.0},
			{"name": "Пистолет: 8 ед.", "val": 18.0, "max": 60.0},
			{"name": "Награда: $10 (~12% бинт)", "val": 10.0, "max": 20.0}
		],
		"stats": "• Быстрый спринтер; при гибели может выронить Полевой бинт (+10 HP).\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Абсолютный чемпион корабля по скоростному залезанию в вентиляционные люки. Утром перед вылетом случайно насыпал в чашку концентрированный ракетный окислитель вместо кофе. Получил пульс 350 ударов в минуту, скорость 6.2 м/с и привычку бегать зигзагами. В карманах всегда таскает бинты, потому что на такой скорости регулярно не вписывается в дверные проемы и со звоном впечатывается шлемом в переборки.»"
	},
	"enemy_yellow": {
		"title": "ЖЕЛТЫЙ КРЮМЕЙТ (ТЯЖЕЛОВЕС)",
		"bars": [
			{"name": "Здоровье: 280 HP", "val": 280.0, "max": 300.0},
			{"name": "Скорость: 3.2 м/с", "val": 3.2, "max": 10.0},
			{"name": "Топор: 38 ед.", "val": 38.0, "max": 60.0},
			{"name": "Награда: $20 (100% жилет)", "val": 20.0, "max": 20.0}
		],
		"stats": "• Идет в ближний бой с топором; 100% роняет Бронежилет (+15 брони до 75).\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Старший системный администратор реакторного отсека. Когда на станции упал Wi-Fi сервер с любимым сериалом, воспринял инструкцию \"перерубить кабель аварийного питания\" слишком буквально. Натянул три кевларовых жилета, выломал двуручный топор из пожарного щита и пошел разбираться с пользователями. Огнестрел презирает: \"хороший рубящий удар сверху лечит любые синие экраны смерти!\".»"
	},
	"enemy_green": {
		"title": "ЗЕЛЕНЫЙ КРЮМЕЙТ (СНАЙПЕР)",
		"bars": [
			{"name": "Здоровье: 60 HP", "val": 60.0, "max": 300.0},
			{"name": "Скорость: 3.5 м/с", "val": 3.5, "max": 10.0},
			{"name": "AWP: 48 ед.", "val": 48.0, "max": 60.0},
			{"name": "Награда: $16 (~12% бинт)", "val": 16.0, "max": 20.0}
		],
		"stats": "• За 1.6 сек до выстрела AWP прицел выдает яркий блик (Lens Flare) — прячьтесь в укрытие!\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Тонкая натура и астроном-самоучка. Тайком прикрутил к AWP объектив от списанного телескопа \"Хаббл\". Теперь видит цель через три модуля, но линза перед выстрелом сияет ярче диско-шара на сельской дискотеке. Сам Зеленый уверен, что это \"божественное сияние его непревзойденной снайперской харизмы\".»"
	},
	"enemy_shahed": {
		"title": "БПЛА \"SHAHED\" (КАМИКАДЗЕ)",
		"bars": [
			{"name": "Здоровье: 30 HP", "val": 30.0, "max": 100.0},
			{"name": "Взрыв: 50 HP (5.5 м)", "val": 50.0, "max": 100.0},
			{"name": "Уязвимость: Дробовик (1 выстр.)", "val": 100.0, "max": 100.0},
			{"name": "Награда: $12", "val": 12.0, "max": 20.0}
		],
		"stats": "• Пикирует сверху с воем двигателя; сбивается с одного выстрела из дробовика даже одиночной картечиной.\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Собран из газонокосилки, крыла от дельтаплана и космического скотча. Обожает подкрадываться со спины с фирменным звуком мопеда под окном в три часа ночи. Категорически не переносит картечь 12 калибра.»"
	},
	"enemy_busik": {
		"title": "БУСИК (ШТУРМОВОЙ МИНИВЭН)",
		"bars": [
			{"name": "Появление: 3+ волна (1 / 2 / 3)", "val": 65.0, "max": 100.0},
			{"name": "Десант внутри: 4–6 врагов", "val": 85.0, "max": 100.0},
			{"name": "Взрыв: как РПГ-7 (16.5 м)", "val": 100.0, "max": 100.0},
			{"name": "Награда: $40 + весь десант", "val": 85.0, "max": 100.0}
		],
		"stats": "• Подъезжает, открывает сдвижную дверь и высаживает 4–6 обычных врагов (их видно в салоне), после чего кружит вокруг игрока и внезапно таранит по прямой после 2 гудков!\n• Уничтожение: 1 ракета РПГ-7 в любую часть ИЛИ расстрел передней части (капот дымится, Бусик несется строго прямо и взрывается о любой объект). Все, кто остался внутри, гибнут с выдачей награды!\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«За рулем сидит невозмутимый Зеленый в соломенной шляпе — бывший водитель маршрутки №67, которому забыли сказать, что конечная уже в другой галактике. Останавливается строго \"у столба\", высаживает всю толпу из салона без билетов, а если ему прострелить радиатор — жмет педаль в пол с криком \"ЗА ПРОЕЗД ПЕРЕДАЕМ!\" до ближайшей бетонной стены.»"
	},
	"enemy_tiger": {
		"title": "БОСС TIGER I (5 ВОЛНА)",
		"bars": [
			{"name": "Появление: 5 волна (Босс)", "val": 100.0, "max": 100.0},
			{"name": "88-мм пушка + 2 пулемета", "val": 100.0, "max": 100.0},
			{"name": "Модули и экипаж (5 чел.)", "val": 100.0, "max": 100.0},
			{"name": "Награда: $440", "val": 100.0, "max": 100.0}
		],
		"stats": "• Нет обычной полоски HP — у танка отдельные модули и экипаж (отображаются слева в HUD):\n  - Командир (в люке): убийство лишает танк обзора 360°.\n  - Водитель / Радист (стрелять точно в передние стекла): останавливают танк / отключают курсовой пулемет.\n  - Пулемет и оптика наводчика на башне: отключают спаренный пулемет / замедляют реакцию.\n• Уничтожение: 1) уничтожить 4 бортовых бака + 2 задние решетки двигателя → пожар → стук изнутри → 5 сек тишины → взрыв; 2) 3 попадания РПГ-7 в один борт → струя горящего БК из люка → мощный взрыв с отрывом башни! (1 РПГ в корму выбивает двигатель).\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Трофейный 57-тонный исполин, непонятно как заехавший на арену. Красный командир в офицерской фуражке торчит из люка с видом человека, который приехал на дачу жарить шашлыки, но свернул не туда. За непробиваемым стеклом башни сидит Желтый наводчик и ехидно улыбается — пока у танка не сгорят все четыре бака.»"
	},
	"enemy_engineer": {
		"title": "ОРАНЖЕВЫЙ ИНЖЕНЕР (3+ ВОЛНА)",
		"bars": [
			{"name": "Здоровье: 120 HP", "val": 120.0, "max": 300.0},
			{"name": "Турель: 115 HP (Лазер)", "val": 75.0, "max": 100.0},
			{"name": "Бонусы: Ставит бочку + дроп", "val": 80.0, "max": 100.0},
			{"name": "Награда: $24 (+$12 турель)", "val": 85.0, "max": 100.0}
		],
		"stats": "• Выходит на дистанцию, ставит автономную лазерную турель (115 HP) и выгружает свежую взрывную бочку на арену — её можно подорвать прямо под ним!\n• При гибели с шансом 55% роняет бронежилет или бинт.\n\n📜 СЕКРЕТНОЕ ДОСЬЕ:\n«Бывший электрик с космодрома. Притащил с собой сварочную каску, треногу от фотоаппарата и ящик просроченного топлива. Обожает ставить турель ровно в тот момент, когда вы перезаряжаетесь.»"
	},
	"enemy_shield": {
		"title": "ЧЁРНЫЙ ЩИТОВИК (4+ ВОЛНА)",
		"bars": [
			{"name": "Здоровье: 240 HP", "val": 240.0, "max": 300.0},
			{"name": "Баллистический щит: Рикошет", "val": 100.0, "max": 100.0},
			{"name": "Уязвимость: ББ / ДШКМ / Щель", "val": 90.0, "max": 100.0},
			{"name": "Награда: $32 (100% жилет)", "val": 95.0, "max": 100.0}
		],
		"stats": "• Обычные пули рикошетят от стальной плиты с искрами без урона!\n• Пробитие: бронебойные патроны (ББ / AP), пулемёт ДШКМ 12.7 мм, снайперский выстрел точно в узкую смотровую щель, обход с фланга, бочки, ГП-25 или РПГ-7.\n• 100% роняет бронежилет.\n\n📜 СЕКРЕТНОЕ ДОСЬЕ:\n«Снял бронированную дверь с реакторного шлюза и прикрутил к ней ручку. В тепловизоре холодный стальной щит остаётся тёмным, а вот сам щитовик за ним светится как печка.»"
	},
	"enemy_saboteur": {
		"title": "СЕРЫЙ ДИВЕРСАНТ-СТРЕЛОК (4+ ВОЛНА)",
		"bars": [
			{"name": "Здоровье: 95 HP", "val": 95.0, "max": 300.0},
			{"name": "Скорость: 5.4 м/с (Фланги)", "val": 5.4, "max": 10.0},
			{"name": "ПБС-карабин: Тихий огонь", "val": 70.0, "max": 100.0},
			{"name": "Награда: $26", "val": 85.0, "max": 100.0}
		],
		"stats": "• Носит тёмную стелс-броню и ПНВ, чаще появляется в ночных и туманных волнах. Широко обходит с фланга и бьёт тихими двойками из карабина с глушителем.\n• Идеально подсвечивается тепловизором FLIR и фонариком!\n\n📜 СЕКРЕТНОЕ ДОСЬЕ:\n«Считает себя невидимым ниндзя, пока не попадёт в прицел тепловизора — там он сияет белее прожектора.»"
	},
	"enemy_cloaker": {
		"title": "ДИВЕРСАНТ-КЛОКЕР (4+ ВОЛНА, РЕДКИЙ)",
		"bars": [
			{"name": "Здоровье: 110 HP", "val": 110.0, "max": 300.0},
			{"name": "Рывок: 9.8 м/с (WULULU!)", "val": 9.8, "max": 10.0},
			{"name": "Нокдаун-удар: 32 ед. (1.2 сек)", "val": 85.0, "max": 100.0},
			{"name": "Награда: $38 (65% бинт)", "val": 100.0, "max": 100.0}
		],
		"stats": "• Узнаётся по трём ярко-зелёным линзам ПНВ и нарастающей электронной сирене «WULULULU!» при рывке.\n• Вблизи сбивает с ног (нокдаун 1.2 сек с креном камеры и звоном в ушах), после чего отпрыгивает назад, давая честное окно для контратаки!\n\n📜 СЕКРЕТНОЕ ДОСЬЕ:\n«Фанат старых боевиков про спецназ. Предупреждает о нападении громкой сиреной исключительно ради драматического эффекта.»"
	},
	"enemy_mi24": {
		"title": "БОСС МИ-24 «КРОКОДИЛ» (10 ВОЛНА)",
		"bars": [
			{"name": "Появление: 10 волна (Воздушный босс)", "val": 100.0, "max": 100.0},
			{"name": "ЯкБ-12.7 + Блоки НАР + Десант", "val": 100.0, "max": 100.0},
			{"name": "Модули: Двиг-ли, Хвост, НАР, Кабина", "val": 100.0, "max": 100.0},
			{"name": "Награда: $520", "val": 100.0, "max": 100.0}
		],
		"stats": "• Воздушный штурмовой босс! Барражирует над ареной, бьёт носовой пушкой ЯкБ-12.7 по лазерной указке, накрывает залпами НАР (красные кольца на земле), отстреливает тепловые ловушки (ЛТЦ) и высаживает десант!\n• Модульное уничтожение (HUD слева):\n  - Хвостовой рулевой винт (ХВОСТ): разрушение мгновенно отправляет вертолёт в неуправляемый штопор!\n  - 2 двигателя ТВ3-117 (ДВ-Л / ДВ-П): белые-горячие в тепловизоре; уничтожение обоих роняет борт!\n  - Блоки НАР (НАР-Л / НАР-П): взрываются с детонацией и лишают вертолёт ракетных залпов.\n  - Бронестекло кабины (ПИЛ / ОПЕР): пробивается ББ-патронами, L96A1, Kar98k, ДШКМ 12.7 мм или РПГ-7 — убийство оператора отключает пушку, пилота — сбивает вертолёт сразу!\n\n📜 СЕКРЕТНОЕ ДОСЬЕ:\n«Легендарный советский «Крокодил», прилетевший выяснить, кто взорвал все бочки на полигоне. Отлично разбирается со стационарного ДШКМ 12.7 мм, снайперки или меткой ракеты РПГ-7.»"
	},
	"armor_vest": {
		"title": "ТАКТИЧЕСКИЙ БРОНЕЖИЛЕТ",
		"bars": [
			{"name": "Броня: +15 ед. (до 75)", "val": 15.0, "max": 75.0},
			{"name": "Поглощение: 50% урона", "val": 50.0, "max": 100.0}
		],
		"stats": "• Бесплатно выпадает с каждого Желтого тяжеловеса. Поглощает 50% входящего урона.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Снят прямо с туловища Желтого берсерка. В нагрудных карманах до сих пор лежат обертки от сухпайков и инструкция по сборке топора.»"
	},
	"bandage": {
		"title": "ПОЛЕВЫЕ БИНТЫ",
		"bars": [
			{"name": "Лечение: +10 HP", "val": 10.0, "max": 50.0},
			{"name": "Шанс дропа: ~12% (Синий/Зеленый)", "val": 100.0, "max": 100.0}
		],
		"stats": "• Бесплатное лечение в бою — берегите деньги, подбирая бинты с Синих и Зеленых врагов!\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Стерильная марля высшего сорта с тонким ароматом спирта и целебного космического подорожника.»"
	},
	"medkit": {
		"title": "БОЛЬШАЯ ПОЛЕВАЯ АПТЕЧКА",
		"bars": [
			{"name": "Лечение: +50 HP", "val": 50.0, "max": 100.0},
			{"name": "Цена в магазине: $75", "val": 75.0, "max": 100.0}
		],
		"stats": "• Мгновенно восстанавливает +50 HP при покупке в минивэне-магазине.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Белый чемоданчик со стимуляторами и рулоном космической синей изоленты. На крышке нацарапано: \"Если оторвало руку — примотай обратно и беги на волну\".»"
	},
	"vodka": {
		"title": "ВОДКА \"ЧЕКУНЕЦ 67\"",
		"bars": [
			{"name": "Лечение: +6–7 HP | Цена: $67", "val": 67.0, "max": 100.0},
			{"name": "Спринт: x1.5 | Стамина: 300", "val": 100.0, "max": 100.0},
			{"name": "Длительность: 15 сек (Слот [5])", "val": 75.0, "max": 100.0}
		],
		"stats": "• Клавиша [5] (до 3 шт., сохраняется после смерти): убирает усталость и дает дикий разгон на 15 сек — идеально для уворотов от Бусика и Tiger I.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Стеклянный чекунец легендарной 40-градусной с этикеткой №67. Официально числится в ведомости как \"антифриз для сервоприводов\", но на практике позволяет бегать быстрее собственного страха.»"
	},
	"heavy_armor": {
		"title": "СВЕРХТЯЖЕЛЫЙ БРОНЕЖИЛЕТ",
		"bars": [
			{"name": "Броня: 150 ед. | Цена: $220", "val": 150.0, "max": 150.0},
			{"name": "Снижение урона: -50% + Сплит", "val": 100.0, "max": 100.0},
			{"name": "Порог работы: >= 76 БР", "val": 76.0, "max": 150.0}
		],
		"stats": "• Режет весь входящий урон вдвое, затем делит остаток 50/50 между HP и броней.\n• Если броня упадет ниже 76 — сверхзащита ломается и жилет становится обычным (макс. 75). Чинится только Бронеплитами ($65).\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Весит как холодильник \"ЗиЛ\", стоит как крыло шаттла, но позволяет пережить прямое попадание из AWP и даже зацепить край взрыва. Главное — не давать броне просесть ниже 76!»"
	},
	"armor_plate": {
		"title": "БРОНЕПЛИТА (+30)",
		"bars": [
			{"name": "Броня: +30 ед. (до 150)", "val": 30.0, "max": 50.0},
			{"name": "Цена в магазине: $65", "val": 65.0, "max": 100.0}
		],
		"stats": "• Докупается только при активном сверхтяжелом жилете (броня >= 76), чтобы не дать ему разрушиться.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Сменная титано-керамическая пластина. Вставляется в жилет с таким уверенным хрустом, что вражеские снайперы впадают в легкую депрессию.»"
	},
	"workbench": {
		"title": "ВЕРСТАК МОДИФИКАЦИИ ОРУЖИЯ",
		"bars": [
			{"name": "Цена верстака: $280", "val": 70.0, "max": 100.0},
			{"name": "Клавиша: [N] рядом с верстаком", "val": 100.0, "max": 100.0}
		],
		"stats": "• Разовая покупка в магазине — верстак ставится в центре арены.\n• Открывает покупку и установку модулей для АК-47: планка Пикатинни ($75), коллиматор ($110), оптика LPVO 1.5x–4x ($175).\n• Смена слотов оружия [1]–[3] (в том числе РПГ-7) — через Инвентарь [I].\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Полевой стол с тисками, набором шестигранников и священной синей изолентой. Позволяет превратить обычный АК-47 в снайперский скальпель с переменной оптикой — лишь бы хватило бюджета.»"
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	damage_overlay.modulate.a = 0.0
	hitmarker.modulate.a = 0.0
	game_over_panel.visible = false
	pause_panel.visible = false
	handbook_panel.visible = false
	if shop_panel:
		shop_panel.visible = false
	reload_label.visible = false
	wave_banner.visible = false
	
	# Tarkov-style sharp military stamina styles (tactical sage green / exhausted dull crimson)
	style_stamina_blue = StyleBoxFlat.new()
	style_stamina_blue.bg_color = Color(0.36, 0.52, 0.30, 1.0) # Tactical olive drab / sage green
	style_stamina_blue.corner_radius_top_left = 0
	style_stamina_blue.corner_radius_top_right = 0
	style_stamina_blue.corner_radius_bottom_right = 0
	style_stamina_blue.corner_radius_bottom_left = 0
	
	style_stamina_red = StyleBoxFlat.new()
	style_stamina_red.bg_color = Color(0.65, 0.16, 0.16, 1.0) # Visceral danger crimson
	style_stamina_red.corner_radius_top_left = 0
	style_stamina_red.corner_radius_top_right = 0
	style_stamina_red.corner_radius_bottom_right = 0
	style_stamina_red.corner_radius_bottom_left = 0
	
	var player: Node = get_parent()
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("armor_changed"):
			player.armor_changed.connect(_on_armor_changed)
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("score_changed"):
			player.score_changed.connect(_on_score_changed)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		if player.has_signal("vodka_count_changed"):
			player.vodka_count_changed.connect(_on_vodka_count_changed)
		if player.has_signal("vodka_buff_updated"):
			player.vodka_buff_updated.connect(_on_vodka_buff_updated)
			
	select_shop_item("ak")
	highlight_weapon_card(1)
	if stamina_label:
		stamina_label.modulate = Color(0.65, 0.75, 0.55)
	build_respawn_overlay()
	setup_enemy_counter_ui()
	_setup_handbook_extra_buttons()
	_setup_shop_extra_buttons()
	_setup_inventory_hud_badge()
	_setup_eft_quickbar_hud()
	_setup_tactical_status_hud()
	_setup_ads_reticle_overlay()
	_setup_dynamic_panels()

func _setup_handbook_extra_buttons() -> void:
	var hb_list := get_node_or_null("HandbookPanel/HBox/LeftCol/VBox/Scroll/List")
	if not hb_list:
		return
	var ref_btn := hb_list.get_node_or_null("BtnAK47") as Button
	var btn_style: StyleBox = ref_btn.get_theme_stylebox("normal") if ref_btn else null

	var make_hb_btn := func(bname: String, btext: String, item_id: String) -> Button:
		var b := Button.new()
		b.name = bname
		b.text = btext
		b.custom_minimum_size = Vector2(0, 36)
		b.add_theme_font_size_override("font_size", 13)
		if btn_style:
			b.add_theme_stylebox_override("normal", btn_style)
		b.pressed.connect(func(): select_handbook_item(item_id))
		return b

	var btn_rpg := hb_list.get_node_or_null("BtnRPG")
	if btn_rpg:
		var w_idx: int = btn_rpg.get_index()
		var extra_weapons := [
			["BtnHB_Kar98k", "Kar98k (7.92×57)", "kar98k"],
			["BtnHB_Deagle", "Desert Eagle (.50 AE)", "deagle"],
			["BtnHB_AA12", "AA-12 (12 Gauge)", "aa12"],
			["BtnHB_PKM", "ПКМ (7.62×54R)", "pkm"],
			["BtnHB_L96A1", "L96A1 (.338 LM)", "l96a1"],
			["BtnHB_MG42", "MG 42 (7.92×57)", "mg42"]
		]
		for i in range(extra_weapons.size()):
			var ew: Array = extra_weapons[i]
			var b: Button = make_hb_btn.call(ew[0], ew[1], ew[2])
			hb_list.add_child(b)
			hb_list.move_child(b, w_idx + 1 + i)

	var btn_shahed := hb_list.get_node_or_null("BtnShahed")
	if btn_shahed:
		var idx: int = btn_shahed.get_index()
		var extra_enemies := [
			["BtnHB_Engineer", "Оранжевый Инженер (3+)", "enemy_engineer"],
			["BtnHB_Shield", "Чёрный Щитовик (4+)", "enemy_shield"],
			["BtnHB_Saboteur", "Серый Диверсант (4+)", "enemy_saboteur"],
			["BtnHB_Cloaker", "Диверсант-Клокер (4+)", "enemy_cloaker"],
			["BtnHB_Busik", "Бусик (3+ волна)", "enemy_busik"],
			["BtnHB_Tiger", "Босс Tiger I (5 волна)", "enemy_tiger"],
			["BtnHB_Mi24", "Босс Ми-24 (10 волна)", "enemy_mi24"],
		]
		for ei in range(extra_enemies.size()):
			var ee: Array = extra_enemies[ei]
			var eb: Button = make_hb_btn.call(ee[0], ee[1], ee[2])
			hb_list.add_child(eb)
			hb_list.move_child(eb, idx + 1 + ei)

	var btn_plate := hb_list.get_node_or_null("BtnHB_Plate")
	if btn_plate:
		var btn_wb: Button = make_hb_btn.call("BtnHB_Workbench", "Верстак модификации", "workbench")
		hb_list.add_child(btn_wb)
		hb_list.move_child(btn_wb, btn_plate.get_index() + 1)

func _setup_shop_extra_buttons() -> void:
	var shop_list := get_node_or_null("ShopPanel/HBox/LeftCol/VBox/Scroll/List")
	if not shop_list:
		return
	var ref_btn: Button = null
	var rpg_btn: Node = null
	for ch in shop_list.get_children():
		if ch is Button and ref_btn == null:
			ref_btn = ch
		if ch is Button and ("РПГ" in ch.text or "RPG" in ch.text.to_upper()):
			rpg_btn = ch
	var btn_style: StyleBox = ref_btn.get_theme_stylebox("normal") if ref_btn else null

	var make_shop_btn := func(bname: String, btext: String, item_id: String) -> Button:
		var b := Button.new()
		b.name = bname
		b.text = btext
		b.custom_minimum_size = Vector2(0, 36)
		b.add_theme_font_size_override("font_size", 13)
		if btn_style:
			b.add_theme_stylebox_override("normal", btn_style)
		b.pressed.connect(func(): select_shop_item(item_id))
		return b

	var insert_idx: int = (rpg_btn.get_index() + 1) if rpg_btn else shop_list.get_child_count()
	var new_items := [
		["BtnShop_Kar98k", "Kar98k ($320)", "kar98k_weapon"],
		["BtnShop_Deagle", "Desert Eagle ($340)", "deagle_weapon"],
		["BtnShop_AA12", "AA-12 ($520)", "aa12_weapon"],
		["BtnShop_PKM", "ПКМ ($640)", "pkm_weapon"],
		["BtnShop_L96A1", "L96A1 ($680)", "l96a1_weapon"],
		["BtnShop_MG42", "MG 42 ($720)", "mg42_weapon"],
		["BtnShop_Ammo792", "Патроны 7.92×57 ($45)", "ammo_792x57"],
		["BtnShop_Ammo762R", "Лента 7.62×54R ($68)", "ammo_762x54r"],
		["BtnShop_Ammo338", "Патроны .338 LM ($55)", "ammo_338lm"],
		["BtnShop_Ammo50AE", "Патроны .50 AE ($36)", "ammo_50ae"],
		["BtnShop_AmmoUGL", "Гранаты 40мм ГП ($45)", "ammo_ugl"],
		["BtnShop_Slot4", "Слот оружия [4] ($600)", "weapon_slot_4"],
		["BtnShop_Slot5", "Слот оружия [5] ($600)", "weapon_slot_5"]
	]
	for i in range(new_items.size()):
		var ni: Array = new_items[i]
		var b: Button = make_shop_btn.call(ni[0], ni[1], ni[2])
		shop_list.add_child(b)
		shop_list.move_child(b, insert_idx + i)

func _setup_dynamic_panels() -> void:
	inventory_ui = InventoryUIScript.new()
	add_child(inventory_ui)
	inventory_ui.setup(self)
	
	workbench_ui = WorkbenchUIScript.new()
	add_child(workbench_ui)
	workbench_ui.setup(self)
	
	cheat_menu_ui = CheatMenuUIScript.new()
	add_child(cheat_menu_ui)
	cheat_menu_ui.setup(self)

	map_travel_ui = MapTravelUIScript.new()
	add_child(map_travel_ui)
	map_travel_ui.setup(self)

func _setup_inventory_hud_badge() -> void:
	# EFT-style Inventory icon badge with [I] key indicator on the HUD
	inventory_hud_badge = PanelContainer.new()
	inventory_hud_badge.name = "InventoryHudBadge"
	inventory_hud_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_hud_badge.anchor_left = 1.0
	inventory_hud_badge.anchor_right = 1.0
	inventory_hud_badge.offset_left = -104.0
	inventory_hud_badge.offset_right = -24.0
	inventory_hud_badge.offset_top = 60.0
	inventory_hud_badge.offset_bottom = 96.0
	inventory_hud_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	inventory_hud_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.10, 0.12, 0.90)
	sb.border_width_left = 2
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.76, 0.64, 0.38, 0.85)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	inventory_hud_badge.add_theme_stylebox_override("panel", sb)
	
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 5)
	inventory_hud_badge.add_child(hb)
	
	var ico := Label.new()
	ico.text = "🎒"
	ico.add_theme_font_size_override("font_size", 15)
	hb.add_child(ico)
	
	var key_lbl := Label.new()
	key_lbl.text = "[I]"
	key_lbl.add_theme_font_size_override("font_size", 14)
	key_lbl.add_theme_color_override("font_color", Color(0.86, 0.74, 0.44))
	hb.add_child(key_lbl)
	
	add_child(inventory_hud_badge)

func _setup_eft_quickbar_hud() -> void:
	# Hide legacy vertical TopRight weapon list AND legacy top-right knife card in favor of bottom EFT Quickbar!
	var legacy_list := get_node_or_null("TopRight/WeaponList")
	if legacy_list:
		legacy_list.visible = false
	if knife_card:
		knife_card.visible = false

	eft_quickbar_container = HBoxContainer.new()
	eft_quickbar_container.name = "EFTQuickbarHUD"
	eft_quickbar_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	eft_quickbar_container.anchor_left = 0.5
	eft_quickbar_container.anchor_right = 0.5
	eft_quickbar_container.anchor_top = 1.0
	eft_quickbar_container.anchor_bottom = 1.0
	eft_quickbar_container.offset_left = -345.0
	eft_quickbar_container.offset_right = 345.0
	eft_quickbar_container.offset_top = -62.0
	eft_quickbar_container.offset_bottom = -12.0
	eft_quickbar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	eft_quickbar_container.add_theme_constant_override("separation", 4)
	eft_quickbar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(eft_quickbar_container)

	# Quick Knife Slot [V] positioned immediately LEFT of Slot [1]!
	var k_cell := PanelContainer.new()
	k_cell.name = "QuickCell_V"
	k_cell.custom_minimum_size = Vector2(58, 46)
	k_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var k_sb := StyleBoxFlat.new()
	k_sb.bg_color = Color(0.08, 0.08, 0.09, 0.84)
	k_sb.border_width_left = 1
	k_sb.border_width_top = 1
	k_sb.border_width_right = 1
	k_sb.border_width_bottom = 1
	k_sb.border_color = Color(0.56, 0.50, 0.36, 0.80)
	k_cell.add_theme_stylebox_override("panel", k_sb)

	var k_inner := Control.new()
	k_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	k_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k_cell.add_child(k_inner)

	var k_badge_bg := ColorRect.new()
	k_badge_bg.color = Color(0.14, 0.13, 0.12, 0.96)
	k_badge_bg.size = Vector2(15, 14)
	k_badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k_inner.add_child(k_badge_bg)

	var k_badge_lbl := Label.new()
	k_badge_lbl.text = "V"
	k_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k_badge_lbl.size = Vector2(15, 14)
	k_badge_lbl.add_theme_font_size_override("font_size", 9)
	k_badge_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	k_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k_badge_bg.add_child(k_badge_lbl)

	var k_txt := Label.new()
	k_txt.text = "НОЖ"
	k_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k_txt.set_anchors_preset(Control.PRESET_FULL_RECT)
	k_txt.offset_left = 2
	k_txt.offset_right = -2
	k_txt.offset_top = 12
	k_txt.clip_text = true
	k_txt.add_theme_font_size_override("font_size", 9)
	k_txt.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78))
	k_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k_inner.add_child(k_txt)

	eft_quickbar_container.add_child(k_cell)
	eft_knife_cell = {"panel": k_cell, "label": k_txt, "key_lbl": k_badge_lbl, "style": k_sb}

	eft_quickbar_cells.clear()
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	for i in range(10):
		var cell := PanelContainer.new()
		cell.name = "QuickCell_%s" % keys[i]
		cell.custom_minimum_size = Vector2(58, 46)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.07, 0.08, 0.80)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.32, 0.34, 0.38, 0.72)
		cell.add_theme_stylebox_override("panel", sb)

		var inner := Control.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(inner)

		var k_bg := ColorRect.new()
		k_bg.color = Color(0.12, 0.13, 0.15, 0.94)
		k_bg.size = Vector2(15, 14)
		k_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(k_bg)

		var k_lbl := Label.new()
		k_lbl.text = keys[i]
		k_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		k_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		k_lbl.size = Vector2(15, 14)
		k_lbl.add_theme_font_size_override("font_size", 9)
		k_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 0.48))
		k_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		k_bg.add_child(k_lbl)

		var txt := Label.new()
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.set_anchors_preset(Control.PRESET_FULL_RECT)
		txt.offset_left = 2
		txt.offset_right = -2
		txt.offset_top = 12
		txt.clip_text = true
		txt.add_theme_font_size_override("font_size", 9)
		txt.add_theme_color_override("font_color", Color(0.86, 0.86, 0.84))
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(txt)

		eft_quickbar_container.add_child(cell)
		eft_quickbar_cells.append({"panel": cell, "label": txt, "key_lbl": k_lbl, "style": sb})

func _refresh_eft_quickbar() -> void:
	if eft_quickbar_cells.size() < 10:
		return
	var player = get_parent()
	var wm = player.weapon_manager if (player and "weapon_manager" in player) else null
	var v_cnt: int = player.vodka_count if (player and "vodka_count" in player) else 0
	var v_act: bool = player.is_vodka_active if (player and "is_vodka_active" in player) else false
	var v_tm: float = player.vodka_timer if (player and "vodka_timer" in player) else 0.0

	for i in range(10):
		var c: Dictionary = eft_quickbar_cells[i]
		var sb: StyleBoxFlat = c["style"]
		var lbl: Label = c["label"]
		var klbl: Label = c["key_lbl"]
		if i < 5:
			var unl: bool = wm != null and wm.is_weapon_slot_unlocked(i)
			var w: Weapon = wm.weapon_slots[i] if (wm != null and i < wm.weapon_slots.size()) else null
			var is_cur: bool = unl and wm != null and (i == wm.current_weapon_idx) and w != null
			if not unl:
				sb.bg_color = Color(0.05, 0.05, 0.06, 0.58)
				sb.border_color = Color(0.36, 0.22, 0.20, 0.55)
				sb.border_width_left = 1; sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
				lbl.text = "🔒$600"
				lbl.add_theme_color_override("font_color", Color(0.58, 0.38, 0.36))
				klbl.add_theme_color_override("font_color", Color(0.52, 0.38, 0.36))
			elif is_cur:
				sb.bg_color = Color(0.18, 0.16, 0.11, 0.94)
				sb.border_color = Color(0.96, 0.80, 0.36, 1.0)
				sb.border_width_left = 2; sb.border_width_top = 2; sb.border_width_right = 2; sb.border_width_bottom = 2
				lbl.text = w.name.to_upper()
				lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
				klbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.40))
			else:
				sb.bg_color = Color(0.07, 0.08, 0.10, 0.82)
				sb.border_color = Color(0.42, 0.45, 0.48, 0.80) if w else Color(0.24, 0.26, 0.30, 0.65)
				sb.border_width_left = 1; sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
				lbl.text = w.name.to_upper() if w else "—"
				lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.80) if w else Color(0.40, 0.42, 0.46))
				klbl.add_theme_color_override("font_color", Color(0.86, 0.76, 0.48))
		elif i == 5:
			if v_act:
				sb.bg_color = Color(0.20, 0.18, 0.08, 0.94)
				sb.border_color = Color(0.96, 0.84, 0.28, 1.0)
				lbl.text = "%.1fc" % v_tm
				lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.40))
			else:
				sb.bg_color = Color(0.07, 0.10, 0.13, 0.84)
				sb.border_color = Color(0.44, 0.68, 0.88, 0.85) if v_cnt > 0 else Color(0.26, 0.32, 0.38, 0.65)
				lbl.text = "ВОДКА %d" % v_cnt if v_cnt > 0 else "ПРЕДМ."
				lbl.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0) if v_cnt > 0 else Color(0.45, 0.50, 0.56))
			klbl.add_theme_color_override("font_color", Color(0.56, 0.84, 1.0))
		else:
			sb.bg_color = Color(0.04, 0.045, 0.055, 0.50)
			sb.border_color = Color(0.20, 0.22, 0.25, 0.48)
			lbl.text = "СКОРО"
			lbl.add_theme_color_override("font_color", Color(0.32, 0.34, 0.38))
			klbl.add_theme_color_override("font_color", Color(0.38, 0.40, 0.44))

func _setup_tactical_status_hud() -> void:
	# Clean floating outlined text only (no box/window container!)
	tactical_status_label = Label.new()
	tactical_status_label.name = "TacticalStatusText"
	tactical_status_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tactical_status_label.anchor_left = 1.0
	tactical_status_label.anchor_right = 1.0
	tactical_status_label.anchor_top = 1.0
	tactical_status_label.anchor_bottom = 1.0
	tactical_status_label.offset_left = -440.0
	tactical_status_label.offset_right = -24.0
	tactical_status_label.offset_top = -138.0
	tactical_status_label.offset_bottom = -114.0
	tactical_status_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tactical_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tactical_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tactical_status_label.visible = false
	tactical_status_label.add_theme_font_size_override("font_size", 13)
	tactical_status_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.70))
	tactical_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	tactical_status_label.add_theme_constant_override("outline_size", 3)
	add_child(tactical_status_label)

	_setup_ugl_reticle_overlay()

func _add_ugl_bar(parent: Control, x: float, y: float, w: float, h: float, col: Color) -> void:
	# Subtle dark border backing + crisp tactical amber bar
	var sh := ColorRect.new()
	sh.color = Color(0.0, 0.0, 0.0, 0.72)
	sh.position = Vector2(x - 1.0, y - 1.0)
	sh.size = Vector2(w + 2.0, h + 2.0)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sh)

	var bar := ColorRect.new()
	bar.color = col
	bar.position = Vector2(x, y)
	bar.size = Vector2(w, h)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)

func _setup_ugl_reticle_overlay() -> void:
	ugl_reticle_overlay = Control.new()
	ugl_reticle_overlay.name = "UGLBallisticReticle"
	ugl_reticle_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ugl_reticle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ugl_reticle_overlay.visible = false
	add_child(ugl_reticle_overlay)

	var center_box := Control.new()
	center_box.name = "CenterAnchor"
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ugl_reticle_overlay.add_child(center_box)

	var amber := Color(0.98, 0.80, 0.30, 0.94)
	var bright := Color(1.0, 0.94, 0.72, 0.96)

	# Upper quadrant brackets framing the 40mm bore line
	_add_ugl_bar(center_box, -2.0, -2.0, 4.0, 4.0, bright) # Center pip
	_add_ugl_bar(center_box, -42.0, -1.0, 26.0, 2.0, amber) # Left stadia wing
	_add_ugl_bar(center_box, 16.0, -1.0, 26.0, 2.0, amber) # Right stadia wing
	_add_ugl_bar(center_box, -42.0, -14.0, 2.0, 28.0, amber) # Left bracket post
	_add_ugl_bar(center_box, 40.0, -14.0, 2.0, 28.0, amber) # Right bracket post
	_add_ugl_bar(center_box, -1.0, 10.0, 2.0, 128.0, Color(0.98, 0.80, 0.30, 0.72)) # Ballistic drop spine

	# Stepped GP-25 / M203 range-drop ladder rungs (25m, 50m, 75m, 100m)
	var rungs := [
		{"y": 24.0, "hw": 30.0, "txt": "25м"},
		{"y": 54.0, "hw": 22.0, "txt": "50м"},
		{"y": 90.0, "hw": 15.0, "txt": "75м"},
		{"y": 130.0, "hw": 10.0, "txt": "100м"}
	]
	for rg in rungs:
		var ry: float = rg["y"]
		var hw: float = rg["hw"]
		_add_ugl_bar(center_box, -hw, ry - 1.0, hw * 2.0, 2.0, amber)
		var rlbl := Label.new()
		rlbl.text = rg["txt"]
		rlbl.position = Vector2(hw + 6.0, ry - 8.0)
		rlbl.add_theme_font_size_override("font_size", 10)
		rlbl.add_theme_color_override("font_color", amber)
		rlbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		rlbl.add_theme_constant_override("outline_size", 2)
		rlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center_box.add_child(rlbl)

	ugl_reticle_hint_label = Label.new()
	ugl_reticle_hint_label.text = "ГП 40мм  |  ВЗВЕДЕНИЕ > 14м  |  [ЛКМ] ПУСК  [R] ЗАРЯДИТЬ  [G] ВЫХОД"
	ugl_reticle_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ugl_reticle_hint_label.position = Vector2(-260.0, 152.0)
	ugl_reticle_hint_label.size = Vector2(520.0, 24.0)
	ugl_reticle_hint_label.add_theme_font_size_override("font_size", 11)
	ugl_reticle_hint_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	ugl_reticle_hint_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	ugl_reticle_hint_label.add_theme_constant_override("outline_size", 3)
	ugl_reticle_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(ugl_reticle_hint_label)

func _on_tactical_state_changed(fire_mode_label: String, can_switch_mode: bool, has_laser: bool, laser_on: bool, has_light: bool, light_on: bool, has_ugl: bool, ugl_ammo: int, ugl_reserve: int, ugl_active: bool = false) -> void:
	is_ugl_hud_active = has_ugl and ugl_active
	var player = get_parent()
	var wm = player.weapon_manager if (player and "weapon_manager" in player) else null
	var inf: bool = wm != null and ("infinite_reserve_ammo" in wm) and wm.infinite_reserve_ammo

	if ugl_reticle_overlay:
		ugl_reticle_overlay.visible = is_ugl_hud_active
		if ugl_reticle_hint_label:
			if ugl_ammo <= 0:
				ugl_reticle_hint_label.text = "ГП 40мм ПУСТ — НАЖМИТЕ [R] ДЛЯ ЗАРЯДКИ  |  [G] ОСН. ОРУЖИЕ"
				ugl_reticle_hint_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.30))
			else:
				ugl_reticle_hint_label.text = "ГП 40мм ГОТОВ (%d/%s)  |  ВЗВЕДЕНИЕ > 14м  |  [ПКМ] ПРИЦЕЛ  [G] ВЫХОД" % [ugl_ammo, "∞" if inf else str(ugl_reserve)]
				ugl_reticle_hint_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	if crosshair_node:
		var aiming_now: bool = wm != null and wm.is_aiming
		crosshair_node.visible = (not is_ugl_hud_active) and (not aiming_now)

	if weapon_label and wm and wm.current_weapon:
		if is_ugl_hud_active:
			var utype: String = str(wm.current_weapon.active_mechanics.get("ugl_type", "gp25"))
			weapon_label.text = "ГП-25 «КОСТЁР» 40мм" if utype == "gp25" else "M203 40мм"
		else:
			weapon_label.text = wm.current_weapon.name.to_upper()

	if not tactical_status_label:
		return
	var parts: Array[String] = []
	if can_switch_mode and fire_mode_label != "":
		parts.append("[X] %s" % fire_mode_label)
	if has_laser:
		parts.append("[T] ЛЦУ: %s" % ("ВКЛ" if laser_on else "ВЫКЛ"))
	if has_light:
		parts.append("[L] ФОНАРЬ: %s" % ("ВКЛ" if light_on else "ВЫКЛ"))
	if has_ugl:
		var g_tag := "РЕЖИМ ГП" if ugl_active else "ГП"
		parts.append("[G] %s: %d/%s" % [g_tag, ugl_ammo, "∞" if inf else str(ugl_reserve)])
	tactical_status_label.visible = not parts.is_empty()
	tactical_status_label.text = "   |   ".join(parts)

func _setup_ads_reticle_overlay() -> void:
	# Full-screen peripheral blur outside the optic lens (blur strength scales with optic magnification!)
	ads_blur_overlay = ColorRect.new()
	ads_blur_overlay.name = "ADSPeripheralBlur"
	ads_blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ads_blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ads_blur_overlay.visible = false
	
	var blur_sh := Shader.new()
	blur_sh.code = """
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;
uniform float clear_radius : hint_range(0.04, 0.30) = 0.125;
uniform float feather : hint_range(0.01, 0.15) = 0.055;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	float aspect = px.y / max(px.x, 0.00001);
	vec2 d = uv - vec2(0.5);
	d.x *= aspect;
	float dist = length(d);
	
	float mask = smoothstep(clear_radius, clear_radius + feather, dist);
	float radius = blur_strength * mask * 7.5;
	
	if (radius < 0.05) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		vec3 sum = vec3(0.0);
		float wsum = 0.0;
		for (int i = 0; i < 12; i++) {
			float ang = float(i) * 0.5235987756; // 30 deg
			vec2 dir = vec2(cos(ang), sin(ang)) * px;
			sum += texture(screen_tex, uv + dir * radius * 0.55).rgb * 1.2;
			sum += texture(screen_tex, uv + dir * radius * 1.15).rgb * 0.8;
			wsum += 2.0;
		}
		sum += texture(screen_tex, uv).rgb * 0.6;
		wsum += 0.6;
		vec3 blurred = sum / wsum;
		// Subtle peripheral darkening at high magnification
		blurred *= mix(1.0, 0.78, blur_strength * mask * 0.6);
		COLOR = vec4(blurred, clamp(mask * blur_strength * 1.35, 0.0, 1.0));
	}
}
"""
	ads_blur_mat = ShaderMaterial.new()
	ads_blur_mat.shader = blur_sh
	ads_blur_overlay.material = ads_blur_mat
	ads_blur_overlay.z_index = -20
	add_child(ads_blur_overlay)
	move_child(ads_blur_overlay, 0) # Behind HUD elements, over 3D scene
	
	# NO 2D reticle in center during ADS — only physical reticles inside the 3D optic models!
	ads_reticle_overlay = Control.new()
	ads_reticle_overlay.name = "ADSReticleOverlay"
	ads_reticle_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ads_reticle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ads_reticle_overlay.visible = false
	add_child(ads_reticle_overlay)
	
	# Subtle off-center zoom level badge for variable optics (e.g. "2.5x [Колесико]")
	ads_zoom_label = Label.new()
	ads_zoom_label.name = "ZoomLabel"
	ads_zoom_label.set_anchors_preset(Control.PRESET_CENTER)
	ads_zoom_label.offset_left = 85
	ads_zoom_label.offset_top = 65
	ads_zoom_label.offset_right = 260
	ads_zoom_label.offset_bottom = 90
	ads_zoom_label.add_theme_font_size_override("font_size", 13)
	ads_zoom_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.44))
	ads_zoom_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	ads_zoom_label.add_theme_constant_override("outline_size", 3)
	ads_reticle_overlay.add_child(ads_zoom_label)

func _on_ads_state_changed(aiming: bool, zoom: float, reticle: String) -> void:
	if crosshair_node:
		crosshair_node.visible = (not aiming) and (not is_ugl_hud_active)
	if ads_reticle_overlay:
		var is_optic := reticle in ["lpvo_crosshair", "pgo7_crosshair", "sniper_crosshair", "acog_crosshair", "zf39_crosshair", "nvg", "thermal", "nvg_crosshair", "thermal_crosshair"]
		ads_reticle_overlay.visible = aiming and (not is_ugl_hud_active) and (is_optic or zoom > 1.05)
		if ads_zoom_label:
			var mode_tag := ""
			if reticle == "nvg" or reticle == "nvg_crosshair":
				mode_tag = "  [ПНВ]"
			elif reticle == "thermal" or reticle == "thermal_crosshair":
				mode_tag = "  [FLIR]"
			ads_zoom_label.text = "%.1fx%s  [Колесико]" % [zoom, mode_tag]

func _process(delta: float) -> void:
	# Update peripheral blur shader outside the optic lens proportional to magnification (off in UGL mode)
	if ads_blur_overlay and ads_blur_mat:
		var p = get_parent()
		var wm = p.weapon_manager if (p and "weapon_manager" in p) else null
		if wm and (not is_ugl_hud_active) and wm.ads_blend > 0.02 and wm.current_weapon and wm.current_weapon.has_mechanic("ads_enabled") and wm.current_ads_zoom > 1.05:
			ads_blur_overlay.visible = true
			var zoom_val: float = maxf(1.0, wm.current_ads_zoom)
			# Higher magnification -> stronger blur outside the optic (smoothly scaled across 1.5x..8.0x)!
			var norm_zoom: float = clampf((zoom_val - 1.0) / 5.0, 0.12, 1.0)
			var strength: float = wm.ads_blend * lerpf(0.28, 1.0, norm_zoom)
			ads_blur_mat.set_shader_parameter("blur_strength", strength)
			ads_blur_mat.set_shader_parameter("clear_radius", 0.18)
			ads_blur_mat.set_shader_parameter("feather", 0.055)
		else:
			ads_blur_overlay.visible = false
			ads_blur_mat.set_shader_parameter("blur_strength", 0.0)
			
	if boss_warning_label and boss_warning_label.visible:
		boss_warning_flash_t += delta * 6.0
		var pulse: float = 0.40 + 0.60 * (0.5 + 0.5 * sin(boss_warning_flash_t))
		boss_warning_label.modulate = Color(1.0, 0.38 + 0.50 * pulse, 0.22 + 0.35 * pulse, pulse)

	if is_respawning:
		respawn_countdown -= delta
		if respawn_timer_label:
			respawn_timer_label.text = "Возрождение у дверей магазина через: %d сек..." % maxi(0, int(ceil(respawn_countdown)))
		if respawn_countdown <= 0.0:
			is_respawning = false
			if respawn_overlay:
				respawn_overlay.visible = false
			var p = get_parent()
			if p and p.has_method("respawn_at_shop"):
				p.respawn_at_shop()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_game_over:
			return
		if is_cheat_menu_open():
			close_cheat_menu()
			get_viewport().set_input_as_handled()
		elif is_map_travel_open():
			close_map_travel()
			get_viewport().set_input_as_handled()
		elif is_workbench_open():
			handle_workbench_escape()
			get_viewport().set_input_as_handled()
		elif is_inventory_open():
			close_inventory()
			get_viewport().set_input_as_handled()
		elif shop_panel and shop_panel.visible:
			close_shop()
			get_viewport().set_input_as_handled()
		elif handbook_panel.visible:
			_on_close_handbook_pressed()
			get_viewport().set_input_as_handled()
		elif pause_panel.visible:
			resume_game()
			get_viewport().set_input_as_handled()
		else:
			pause_game()
			get_viewport().set_input_as_handled()

func is_any_menu_open() -> bool:
	if is_game_over:
		return true
	if is_cheat_menu_open() or is_map_travel_open() or is_workbench_open() or is_inventory_open():
		return true
	if shop_panel and shop_panel.visible:
		return true
	if handbook_panel and handbook_panel.visible:
		return true
	if pause_panel and pause_panel.visible:
		return true
	return false

# --- INVENTORY [I], WORKBENCH [N], CHEAT MENU [}] CONTROLLERS ---

func is_inventory_open() -> bool:
	return inventory_ui != null and inventory_ui.visible

func open_inventory() -> void:
	if is_game_over or not inventory_ui:
		return
	inventory_ui.visible = true
	inventory_ui.refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_inventory() -> void:
	if inventory_ui:
		inventory_ui.visible = false
	if not is_any_menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	else:
		open_inventory()

func is_workbench_open() -> bool:
	return workbench_ui != null and workbench_ui.visible

func open_workbench() -> void:
	if is_game_over or not workbench_ui:
		return
	var player = get_parent()
	if player and player.has_method("set_in_workbench"):
		player.set_in_workbench(true)
	workbench_ui.open_workbench()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if workbench_zone_prompt_label:
		workbench_zone_prompt_label.visible = false

func close_workbench() -> void:
	var player = get_parent()
	if player and player.has_method("set_in_workbench"):
		player.set_in_workbench(false)
	if workbench_ui:
		workbench_ui.visible = false
	if not is_any_menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if workbench_zone_prompt_label and player and ("is_near_workbench" in player) and player.is_near_workbench:
		workbench_zone_prompt_label.visible = true

func toggle_workbench() -> void:
	if is_workbench_open():
		close_workbench()
	else:
		open_workbench()

func handle_workbench_escape() -> void:
	if workbench_ui and workbench_ui.has_method("handle_escape"):
		workbench_ui.handle_escape()

func show_workbench_zone_prompt(show_prompt: bool) -> void:
	if not workbench_zone_prompt_label:
		workbench_zone_prompt_label = Label.new()
		workbench_zone_prompt_label.name = "WorkbenchZonePrompt"
		workbench_zone_prompt_label.text = "🔧 [N] ВЕРСТАК МОДИФИКАЦИИ"
		workbench_zone_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		workbench_zone_prompt_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
		workbench_zone_prompt_label.offset_left = -250
		workbench_zone_prompt_label.offset_right = 250
		workbench_zone_prompt_label.offset_top = -155
		workbench_zone_prompt_label.offset_bottom = -125
		workbench_zone_prompt_label.add_theme_font_size_override("font_size", 16)
		workbench_zone_prompt_label.add_theme_color_override("font_color", Color(0.86, 0.72, 0.38))
		workbench_zone_prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		workbench_zone_prompt_label.add_theme_constant_override("outline_size", 4)
		add_child(workbench_zone_prompt_label)
	workbench_zone_prompt_label.visible = show_prompt and not is_workbench_open()

func is_cheat_menu_open() -> bool:
	return cheat_menu_ui != null and cheat_menu_ui.visible

func open_cheat_menu() -> void:
	if not cheat_menu_ui:
		return
	cheat_menu_ui.visible = true
	cheat_menu_ui.refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_cheat_menu() -> void:
	if cheat_menu_ui:
		cheat_menu_ui.visible = false
	if not is_any_menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_cheat_menu() -> void:
	if is_cheat_menu_open():
		close_cheat_menu()
	else:
		open_cheat_menu()

func is_map_travel_open() -> bool:
	return map_travel_ui != null and map_travel_ui.visible

func open_map_travel() -> void:
	if is_game_over or not map_travel_ui:
		return
	var player = get_parent()
	if player and player.has_method("set_in_shop"):
		player.set_in_shop(true)
	map_travel_ui.visible = true
	map_travel_ui.refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if shop_zone_prompt_label:
		shop_zone_prompt_label.visible = false

func close_map_travel() -> void:
	var player = get_parent()
	if player and player.has_method("set_in_shop"):
		player.set_in_shop(false)
	if map_travel_ui:
		map_travel_ui.visible = false
	if not is_any_menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if shop_zone_prompt_label and player and ("is_near_shop" in player) and player.is_near_shop:
		shop_zone_prompt_label.visible = true

func toggle_map_travel() -> void:
	if is_map_travel_open():
		close_map_travel()
	else:
		open_map_travel()

func show_arena_interact_prompt(text_val: String) -> void:
	if not arena_interact_prompt_label:
		arena_interact_prompt_label = Label.new()
		arena_interact_prompt_label.name = "ArenaInteractPrompt"
		arena_interact_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arena_interact_prompt_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
		arena_interact_prompt_label.offset_left = -360
		arena_interact_prompt_label.offset_right = 360
		arena_interact_prompt_label.offset_top = -190
		arena_interact_prompt_label.offset_bottom = -160
		arena_interact_prompt_label.add_theme_font_size_override("font_size", 16)
		arena_interact_prompt_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.40))
		arena_interact_prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
		arena_interact_prompt_label.add_theme_constant_override("outline_size", 4)
		arena_interact_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(arena_interact_prompt_label)
	var hide_for_menu: bool = is_any_menu_open()
	arena_interact_prompt_label.visible = (text_val != "") and not hide_for_menu
	arena_interact_prompt_label.text = text_val

func show_arena_toast(msg: String) -> void:
	if not arena_toast_label:
		arena_toast_label = Label.new()
		arena_toast_label.name = "ArenaToastLabel"
		arena_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arena_toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		arena_toast_label.offset_top = 182.0
		arena_toast_label.offset_bottom = 216.0
		arena_toast_label.add_theme_font_size_override("font_size", 17)
		arena_toast_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.42))
		arena_toast_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		arena_toast_label.add_theme_constant_override("outline_size", 5)
		arena_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(arena_toast_label)
	arena_toast_label.text = msg
	arena_toast_label.visible = true
	arena_toast_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if arena_toast_tween:
		arena_toast_tween.kill()
	arena_toast_tween = create_tween()
	arena_toast_tween.tween_interval(3.6)
	arena_toast_tween.tween_property(arena_toast_label, "modulate:a", 0.0, 0.8)
	arena_toast_tween.tween_callback(func(): arena_toast_label.visible = false)

func pause_game() -> void:
	if is_game_over:
		return
	get_tree().paused = true
	pause_panel.visible = true
	handbook_panel.visible = false
	if shop_panel:
		shop_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	handbook_panel.visible = false
	if not is_game_over and (not shop_panel or not shop_panel.visible):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	resume_game()

func _on_handbook_button_pressed() -> void:
	pause_panel.visible = false
	handbook_panel.visible = true
	select_handbook_item("ak47")

func select_handbook_item(item_id: String) -> void:
	if not handbook_db.has(item_id):
		return
	var data = handbook_db[item_id]
	if handbook_title:
		handbook_title.text = data["title"]
	if handbook_stats:
		handbook_stats.text = data["stats"]
	if handbook_preview and handbook_preview.has_method("show_item"):
		handbook_preview.show_item(item_id)
		
	var bars: Array = data.get("bars", [])
	var boxes = [hb_stat1_box, hb_stat2_box, hb_stat3_box, hb_stat4_box]
	var labels = [hb_stat1_label, hb_stat2_label, hb_stat3_label, hb_stat4_label]
	var pbars = [hb_stat1_bar, hb_stat2_bar, hb_stat3_bar, hb_stat4_bar]
	
	if hb_stats_box:
		hb_stats_box.visible = (bars.size() > 0)
		for i in range(4):
			if boxes[i]:
				if i < bars.size():
					boxes[i].visible = true
					if labels[i]:
						labels[i].text = bars[i]["name"]
					if pbars[i]:
						pbars[i].max_value = bars[i]["max"]
						pbars[i].value = bars[i]["val"]
				else:
					boxes[i].visible = false

func setup_enemy_counter_ui() -> void:
	enemy_counter_container = PanelContainer.new()
	enemy_counter_container.name = "EnemyCounter"
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.92)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.76, 0.64, 0.38, 0.85) # Tarkov Gold
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.content_margin_left = 10.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	enemy_counter_container.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 8)
	enemy_counter_container.add_child(hbox)
	
	var icon := Label.new()
	icon.text = "🎯"
	icon.add_theme_font_size_override("font_size", 15)
	hbox.add_child(icon)
	
	enemy_counter_label = Label.new()
	enemy_counter_label.text = "ОСТАЛОСЬ ВРАГОВ: --"
	enemy_counter_label.add_theme_font_size_override("font_size", 14)
	enemy_counter_label.modulate = Color(0.85, 0.72, 0.45)
	hbox.add_child(enemy_counter_label)
	
	var tl = get_node_or_null("TopLeft")
	if tl:
		tl.add_child(enemy_counter_container)
		tiger_boss_hud = TigerBossHUDScript.new()
		tl.add_child(tiger_boss_hud)
		mi24_boss_hud = Mi24BossHUDScript.new()
		tl.add_child(mi24_boss_hud)
	else:
		add_child(enemy_counter_container)
		enemy_counter_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
		enemy_counter_container.position = Vector2(24, 96)
		tiger_boss_hud = TigerBossHUDScript.new()
		add_child(tiger_boss_hud)
		tiger_boss_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
		tiger_boss_hud.position = Vector2(24, 140)
		mi24_boss_hud = Mi24BossHUDScript.new()
		add_child(mi24_boss_hud)
		mi24_boss_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
		mi24_boss_hud.position = Vector2(24, 240)

	# Flashing Boss Advance Warning ("Через N волн приедет Tiger I / прилетит МИ-24!") — strictly behind menus!
	boss_warning_label = Label.new()
	boss_warning_label.name = "BossWarningLabel"
	boss_warning_label.visible = false
	boss_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_warning_label.z_index = -10
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_warning_label.offset_top = 138.0
	boss_warning_label.offset_bottom = 176.0
	boss_warning_label.add_theme_font_size_override("font_size", 22)
	boss_warning_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.18))
	boss_warning_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	boss_warning_label.add_theme_constant_override("outline_size", 6)
	add_child(boss_warning_label)
	move_child(boss_warning_label, 0)

func get_tiger_boss_hud() -> Node:
	return tiger_boss_hud

func get_mi24_boss_hud() -> Node:
	return mi24_boss_hud

func show_boss_warning(waves_remaining: int, boss_name: String = "Tiger I") -> void:
	if not boss_warning_label:
		return
	var verb: String = "прилетит" if "МИ-24" in boss_name.to_upper() else "приедет"
	if waves_remaining <= 0:
		boss_warning_label.text = "⚠ В ЭТОЙ ВОЛНЕ %s %s! ⚠" % [verb.to_upper(), boss_name.to_upper()]
	elif waves_remaining == 1:
		boss_warning_label.text = "⚠ Через 1 волну %s %s! ⚠" % [verb, boss_name]
	elif waves_remaining >= 2 and waves_remaining <= 4:
		boss_warning_label.text = "⚠ Через %d волны %s %s! ⚠" % [waves_remaining, verb, boss_name]
	else:
		boss_warning_label.text = "⚠ Через %d волн %s %s! ⚠" % [waves_remaining, verb, boss_name]
	boss_warning_label.visible = true

func hide_boss_warning() -> void:
	if boss_warning_label:
		boss_warning_label.visible = false

func update_enemies_remaining(count: int, is_active: bool) -> void:
	if not enemy_counter_label:
		return
	if not is_active:
		enemy_counter_label.text = "СЕКТОР ЗАЧИЩЕН"
		enemy_counter_label.modulate = Color(0.48, 0.72, 0.40)
	else:
		enemy_counter_label.text = "ОСТАЛОСЬ ВРАГОВ: %d" % count
		if count <= 3:
			enemy_counter_label.modulate = Color(0.92, 0.58, 0.28)
		else:
			enemy_counter_label.modulate = Color(0.85, 0.72, 0.45)

func _on_close_handbook_pressed() -> void:
	handbook_panel.visible = false
	pause_panel.visible = true

func _on_hb_ak47_pressed() -> void:
	select_handbook_item("ak47")

func _on_hb_shotgun_pressed() -> void:
	select_handbook_item("shotgun")

func _on_hb_pistol_pressed() -> void:
	select_handbook_item("pistol")

func _on_hb_rpg_pressed() -> void:
	select_handbook_item("rpg")

func _on_hb_knife_pressed() -> void:
	select_handbook_item("knife")

func _on_hb_enemy_red_pressed() -> void:
	select_handbook_item("enemy_red")

func _on_hb_enemy_blue_pressed() -> void:
	select_handbook_item("enemy_blue")

func _on_hb_enemy_yellow_pressed() -> void:
	select_handbook_item("enemy_yellow")

func _on_hb_enemy_green_pressed() -> void:
	select_handbook_item("enemy_green")

func _on_hb_armor_pressed() -> void:
	select_handbook_item("armor_vest")

func _on_hb_bandage_pressed() -> void:
	select_handbook_item("bandage")

func _on_hb_medkit_pressed() -> void:
	select_handbook_item("medkit")

func _on_hb_shahed_pressed() -> void:
	select_handbook_item("enemy_shahed")

func _on_hb_vodka_pressed() -> void:
	select_handbook_item("vodka")

func _on_hb_heavy_armor_pressed() -> void:
	select_handbook_item("heavy_armor")

func _on_hb_plate_pressed() -> void:
	select_handbook_item("armor_plate")

func _on_pause_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- FIELD SHOP SYSTEM (HANDBOOK STYLE + PER-AMMO-TYPE DYNAMIC ECONOMY) ---

const SHOP_AMMO_MAP := {
	"ak": {"weapons": ["ak47"], "caliber": "762x39", "pack": 30, "unit": "патр.", "preview": "ammo_ak", "btn_node": "BtnShopAK", "btn_prefix": "АК-47"},
	"shotgun": {"weapons": ["shotgun", "aa12"], "caliber": "12ga", "pack": 1, "unit": "патр.", "preview": "ammo_shotgun", "btn_node": "BtnShopShotgun", "btn_prefix": "12G", "shared_note": "Общий запас для Дробовика и AA-12 с тем же типом патрона."},
	"pistol": {"weapons": ["pistol"], "caliber": "9x19", "pack": 17, "unit": "патр.", "preview": "ammo_pistol", "btn_node": "BtnShopPistol", "btn_prefix": "9×19"},
	"rpg": {"weapons": ["rpg"], "caliber": "pg7v", "pack": 1, "unit": "выстр.", "preview": "ammo_rpg", "btn_node": "BtnShopRPG", "btn_prefix": "РПГ-7"},
	"ammo_792x57": {"weapons": ["kar98k", "mg42"], "caliber": "792x57", "pack": 25, "unit": "патр.", "preview": "ammo_792x57", "btn_node": "BtnShop_Ammo792", "btn_prefix": "7.92", "shared_note": "Общий запас для Kar98k и MG 42 с тем же типом патрона."},
	"ammo_762x54r": {"weapons": ["pkm"], "caliber": "762x54r", "pack": 50, "unit": "патр.", "preview": "ammo_762x54r", "btn_node": "BtnShop_Ammo762R", "btn_prefix": "ПКМ"},
	"ammo_338lm": {"weapons": ["l96a1"], "caliber": "338lm", "pack": 5, "unit": "патр.", "preview": "ammo_338lm", "btn_node": "BtnShop_Ammo338", "btn_prefix": ".338"},
	"ammo_50ae": {"weapons": ["deagle"], "caliber": "50ae", "pack": 14, "unit": "патр.", "preview": "ammo_50ae", "btn_node": "BtnShop_Ammo50AE", "btn_prefix": ".50AE"}
}

func _get_dynamic_shop_item_data(item_id: String) -> Dictionary:
	var base: Dictionary = shop_catalog.get(item_id, {}).duplicate(true)
	if not SHOP_AMMO_MAP.has(item_id):
		return base
	var cfg: Dictionary = SHOP_AMMO_MAP[item_id]
	var player = get_parent()
	var wm = player.weapon_manager if (player and "weapon_manager" in player) else null

	# Pick active weapon for this caliber: currently equipped first, then any owned weapon with custom ammo, else first owned
	var target_w: Weapon = null
	var wids: Array = cfg["weapons"]
	if wm:
		if wm.current_weapon and wm.current_weapon.weapon_id in wids:
			target_w = wm.current_weapon
		else:
			for wid in wids:
				var w_cand: Weapon = wm.get_weapon_by_id(str(wid))
				if w_cand:
					if not target_w:
						target_w = w_cand
					var mid_c: String = str(w_cand.installed_mods.get("ammo_type", ""))
					var m_c = WeaponModDBScript.get_mod(mid_c)
					if m_c and not m_c.is_vanilla_default:
						target_w = w_cand
						break

	var cal: String = str(cfg["caliber"])
	var active_ammo_id: String = target_w.get_active_ammo_pool_key() if target_w else Weapon.get_default_ammo_mod_id(cal)
	var m = WeaponModDBScript.get_mod(active_ammo_id)
	var pack: int = int(cfg["pack"])
	var unit: String = str(cfg["unit"])
	var reserve_cnt: int = wm.get_reserve_by_pool_key(active_ammo_id) if (wm and wm.has_method("get_reserve_by_pool_key")) else 0

	var dyn_price: int = int(base.get("price", 30))
	var ammo_mode: String = "standard" if item_id == "rpg" else ("buck" if item_id == "shotgun" else "fmj")
	var short_tag: String = ""
	if m:
		dyn_price = int(m.mechanics.get("shop_price", dyn_price))
		ammo_mode = str(m.mechanics.get("ammo_mode", ammo_mode))
		short_tag = m.short_name
		base["title"] = "%s  [%s]" % [m.name.to_upper(), str(cfg["btn_prefix"])]
		var extra_note: String = ("\n• " + str(cfg["shared_note"])) if cfg.has("shared_note") else ""
		base["desc"] = "%s\n• Текущий запас этого типа: %d шт.%s" % [m.description, reserve_cnt, extra_note]

		# Live ballistic & penetration stats matching selected ammo type!
		var base_dmg: float = target_w.damage if target_w else float(base.get("stat2_val", 40.0)) * m.damage_mult
		var pen_pct: float = float(m.mechanics.get("armor_pen_mult", 1.0)) * 100.0
		var rec_pct: float = m.recoil_pitch_mult * 100.0
		base["stat1_label"] = "Пачка: +%d %s  |  В запасе: %d шт." % [pack, unit, reserve_cnt]
		base["stat1_val"] = float(pack)
		base["stat1_max"] = float(maxi(pack * 2, 5))

		if item_id == "rpg":
			var rad: float = float(m.mechanics.get("blast_radius", 16.5))
			var rpg_dmg: float = target_w.damage if target_w else (900.0 * m.damage_mult)
			base["stat2_label"] = "Урон взрыва: %d ед. | Радиус: %.1f м" % [int(round(rpg_dmg)), rad]
			base["stat2_val"] = rpg_dmg
			base["stat2_max"] = 1500.0
			base["stat3_label"] = "Бронепробитие: %d%% | Отдача: %d%%" % [int(round(pen_pct)), int(round(rec_pct))]
			base["stat3_val"] = pen_pct
			base["stat3_max"] = 200.0
		elif item_id == "shotgun":
			var pel: int = int(m.mechanics.get("pellets_override", target_w.pellets if target_w else 8))
			var per_pel: float = target_w.damage if target_w else (18.0 * m.damage_mult)
			var total_dmg: float = per_pel * float(pel)
			var pel_txt: String = "1 тяжёлая пуля" if pel == 1 else "%d дробин" % pel
			base["stat2_label"] = "Урон выстрела: %d ед. (%s)" % [int(round(total_dmg)), pel_txt]
			base["stat2_val"] = total_dmg
			base["stat2_max"] = 240.0
			base["stat3_label"] = "Бронепробитие: %d%% | Отдача: %d%%" % [int(round(pen_pct)), int(round(rec_pct))]
			base["stat3_val"] = pen_pct
			base["stat3_max"] = 200.0
		else:
			base["stat2_label"] = "Урон за выстрел: %d ед. (мод. ×%.2f)" % [int(round(base_dmg)), m.damage_mult]
			base["stat2_val"] = base_dmg
			base["stat2_max"] = 320.0 if item_id == "ammo_338lm" else (180.0 if item_id in ["ammo_792x57", "ammo_50ae"] else 100.0)
			base["stat3_label"] = "Бронепробитие: %d%% | Отдача: %d%%" % [int(round(pen_pct)), int(round(rec_pct))]
			base["stat3_val"] = pen_pct
			base["stat3_max"] = 200.0

	base["price"] = dyn_price
	base["ammo_mode"] = ammo_mode
	base["pool_key"] = active_ammo_id
	base["pack"] = pack
	base["short_tag"] = short_tag
	base["btn_text"] = "КУПИТЬ +%d %s (%s) — $%d" % [pack, unit, short_tag if short_tag != "" else str(cfg["btn_prefix"]), dyn_price]
	return base

func _refresh_shop_list_button_labels() -> void:
	var shop_list := get_node_or_null("ShopPanel/HBox/LeftCol/VBox/Scroll/List")
	if not shop_list:
		return
	for item_id in SHOP_AMMO_MAP.keys():
		var cfg: Dictionary = SHOP_AMMO_MAP[item_id]
		var btn := shop_list.get_node_or_null(str(cfg["btn_node"])) as Button
		if not btn:
			continue
		var d: Dictionary = _get_dynamic_shop_item_data(item_id)
		var tag: String = str(d.get("short_tag", cfg["btn_prefix"]))
		btn.text = "%s: %s ($%d)" % [str(cfg["btn_prefix"]), tag, int(d["price"])]

func select_shop_item(item_id: String) -> void:
	if not shop_catalog.has(item_id):
		return
	current_shop_item_id = item_id
	var data: Dictionary = _get_dynamic_shop_item_data(item_id)
	
	if shop_item_title:
		shop_item_title.text = data["title"]
	if shop_price_badge:
		shop_price_badge.text = "Стоимость: $%d" % data["price"]
	if shop_item_desc:
		shop_item_desc.text = data["desc"]
		
	if shop_preview and shop_preview.has_method("show_item"):
		var preview_id: String = item_id
		match item_id:
			"ak":
				preview_id = "ammo_ak"
			"shotgun":
				preview_id = "ammo_shotgun"
			"pistol":
				preview_id = "ammo_pistol"
			"rpg":
				preview_id = "ammo_rpg"
			"rpg_launcher":
				preview_id = "rpg"
			"kar98k_weapon":
				preview_id = "kar98k"
			"pkm_weapon":
				preview_id = "pkm"
			"l96a1_weapon":
				preview_id = "l96a1"
			"deagle_weapon":
				preview_id = "deagle"
			"aa12_weapon":
				preview_id = "aa12"
			"mg42_weapon":
				preview_id = "mg42"
			"ammo_ugl":
				preview_id = "ammo_ugl"
			"weapon_slot_4", "weapon_slot_5":
				preview_id = "workbench"
		shop_preview.show_item(preview_id, str(data.get("ammo_mode", "")))
		
	if shop_stat1_box:
		if data.has("stat1_label"):
			shop_stat1_box.visible = true
			if shop_stat1_label:
				shop_stat1_label.text = data["stat1_label"]
			if shop_stat1_bar:
				shop_stat1_bar.max_value = data.get("stat1_max", 100.0)
				shop_stat1_bar.value = data.get("stat1_val", 0.0)
		else:
			shop_stat1_box.visible = false

	if shop_stat2_box:
		if data.has("stat2_label"):
			shop_stat2_box.visible = true
			if shop_stat2_label:
				shop_stat2_label.text = data["stat2_label"]
			if shop_stat2_bar:
				shop_stat2_bar.max_value = data.get("stat2_max", 100.0)
				shop_stat2_bar.value = data.get("stat2_val", 0.0)
		else:
			shop_stat2_box.visible = false

	if shop_stat3_box:
		if data.has("stat3_label"):
			shop_stat3_box.visible = true
			if shop_stat3_label:
				shop_stat3_label.text = data["stat3_label"]
			if shop_stat3_bar:
				shop_stat3_bar.max_value = data.get("stat3_max", 100.0)
				shop_stat3_bar.value = data.get("stat3_val", 0.0)
		else:
			shop_stat3_box.visible = false
		
	update_shop_ui()

func _on_shop_select_ak() -> void:
	select_shop_item("ak")

func _on_shop_select_shotgun() -> void:
	select_shop_item("shotgun")

func _on_shop_select_pistol() -> void:
	select_shop_item("pistol")

func _on_shop_select_rpg_launcher() -> void:
	select_shop_item("rpg_launcher")

func _on_shop_select_rpg() -> void:
	select_shop_item("rpg")

func _on_shop_select_workbench() -> void:
	select_shop_item("workbench")

func _on_shop_select_medkit() -> void:
	select_shop_item("medkit")

func _on_shop_select_vodka() -> void:
	select_shop_item("vodka")

func _on_shop_select_heavy_armor() -> void:
	select_shop_item("heavy_armor")

func _on_shop_select_plate() -> void:
	select_shop_item("armor_plate")

func _on_shop_buy_pressed() -> void:
	if not shop_catalog.has(current_shop_item_id):
		return
	var data: Dictionary = _get_dynamic_shop_item_data(current_shop_item_id)
	var price: int = int(data["price"])
	var player = get_parent()
	if not player or not player.has_method("spend_money"):
		return
		
	# Check custom purchase constraints before taking money
	var wm = player.weapon_manager if ("weapon_manager" in player) else null
	match current_shop_item_id:
		"rpg_launcher":
			if wm and wm.has_weapon("rpg"):
				return
		"rpg":
			if not wm or not wm.has_weapon("rpg"):
				return
		"kar98k_weapon":
			if wm and wm.has_weapon("kar98k"):
				return
		"pkm_weapon":
			if wm and wm.has_weapon("pkm"):
				return
		"l96a1_weapon":
			if wm and wm.has_weapon("l96a1"):
				return
		"deagle_weapon":
			if wm and wm.has_weapon("deagle"):
				return
		"aa12_weapon":
			if wm and wm.has_weapon("aa12"):
				return
		"mg42_weapon":
			if wm and wm.has_weapon("mg42"):
				return
		"ammo_792x57":
			if not wm or (not wm.has_weapon("kar98k") and not wm.has_weapon("mg42")):
				return
		"ammo_762x54r":
			if not wm or not wm.has_weapon("pkm"):
				return
		"ammo_338lm":
			if not wm or not wm.has_weapon("l96a1"):
				return
		"ammo_50ae":
			if not wm or not wm.has_weapon("deagle"):
				return
		"ammo_ugl":
			if not wm or not wm.has_any_ugl():
				return
		"weapon_slot_4":
			if not wm or wm.is_weapon_slot_unlocked(3):
				return
		"weapon_slot_5":
			if not wm or wm.is_weapon_slot_unlocked(4):
				return
		"workbench":
			if player.has_workbench:
				return
		"vodka":
			if player.vodka_count >= 3:
				return
		"heavy_armor":
			if player.has_heavy_armor and player.armor >= 150.0:
				return
		"armor_plate":
			if not player.has_heavy_armor or player.armor < 76.0 or player.armor >= 150.0:
				return

	if player.spend_money(price):
		if data.has("pool_key"):
			if wm:
				wm.add_reserve_ammo_by_type(str(data["pool_key"]), int(data.get("pack", 1)))
		else:
			match current_shop_item_id:
				"rpg_launcher":
					if wm:
						wm.grant_weapon(Weapon.create_rpg())
				"kar98k_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_kar98k())
				"pkm_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_pkm())
				"l96a1_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_l96a1())
				"deagle_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_deagle())
				"aa12_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_aa12())
				"mg42_weapon":
					if wm:
						wm.grant_weapon(Weapon.create_mg42())
				"ammo_ugl":
					if wm:
						wm.add_ugl_grenades(3)
				"weapon_slot_4":
					if wm:
						wm.unlock_weapon_slot(3)
				"weapon_slot_5":
					if wm:
						wm.unlock_weapon_slot(4)
				"workbench":
					if player.has_method("buy_workbench"):
						player.buy_workbench()
				"medkit":
					player.add_health(50.0)
				"vodka":
					player.add_vodka()
				"heavy_armor":
					player.buy_heavy_armor()
				"armor_plate":
					player.buy_armor_plate()
				
		play_buy_sfx()
		if data.has("pool_key"):
			# Refresh displayed reserve count live in description & stat1 without resetting 3D spin!
			var upd: Dictionary = _get_dynamic_shop_item_data(current_shop_item_id)
			if shop_item_desc:
				shop_item_desc.text = upd["desc"]
			if shop_stat1_label and upd.has("stat1_label"):
				shop_stat1_label.text = upd["stat1_label"]
		update_shop_ui()

func open_shop() -> void:
	if is_game_over:
		return
	var player = get_parent()
	if player and player.has_method("set_in_shop"):
		player.set_in_shop(true)
	if shop_panel:
		shop_panel.visible = true
	_refresh_shop_list_button_labels()
	select_shop_item(current_shop_item_id)
	update_shop_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if shop_zone_prompt_label:
		shop_zone_prompt_label.visible = false

func close_shop() -> void:
	var player = get_parent()
	if player and player.has_method("set_in_shop"):
		player.set_in_shop(false)
	if shop_panel:
		shop_panel.visible = false
	if not is_any_menu_open() and not is_game_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if shop_zone_prompt_label and player and ("is_near_shop" in player) and player.is_near_shop:
		shop_zone_prompt_label.visible = true

func toggle_shop() -> void:
	if shop_panel and shop_panel.visible:
		close_shop()
	else:
		open_shop()

func update_shop_ui() -> void:
	var player = get_parent()
	if not player:
		return
	var cur_money: int = player.money if ("money" in player and player.money != null) else 0
	if shop_balance_label:
		shop_balance_label.text = "БАЛАНС: $ %d" % cur_money
		
	if shop_buy_btn and shop_catalog.has(current_shop_item_id):
		var data: Dictionary = _get_dynamic_shop_item_data(current_shop_item_id)
		var can_afford: bool = cur_money >= int(data["price"])
		_refresh_shop_list_button_labels()
		var reason: String = ""
		
		var v_count: int = player.vodka_count if ("vodka_count" in player and player.vodka_count != null) else 0
		var has_ha: bool = player.has_heavy_armor if ("has_heavy_armor" in player and player.has_heavy_armor != null) else false
		var arm: float = player.armor if ("armor" in player and player.armor != null) else 0.0
		var has_wb: bool = player.has_workbench if ("has_workbench" in player and player.has_workbench != null) else false
		var wm = player.weapon_manager if ("weapon_manager" in player) else null
		var owns_rpg: bool = wm != null and wm.has_weapon("rpg")
		var owns_kar98k: bool = wm != null and wm.has_weapon("kar98k")
		var owns_pkm: bool = wm != null and wm.has_weapon("pkm")
		var owns_l96a1: bool = wm != null and wm.has_weapon("l96a1")
		var owns_deagle: bool = wm != null and wm.has_weapon("deagle")
		var owns_aa12: bool = wm != null and wm.has_weapon("aa12")
		var owns_mg42: bool = wm != null and wm.has_weapon("mg42")
		
		if current_shop_item_id == "rpg_launcher" and owns_rpg:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "rpg" and not owns_rpg:
			can_afford = false; reason = "Требуется РПГ-7"
		elif current_shop_item_id == "kar98k_weapon" and owns_kar98k:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "pkm_weapon" and owns_pkm:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "l96a1_weapon" and owns_l96a1:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "deagle_weapon" and owns_deagle:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "aa12_weapon" and owns_aa12:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "mg42_weapon" and owns_mg42:
			can_afford = false; reason = "УЖЕ КУПЛЕНО"
		elif current_shop_item_id == "ammo_792x57" and not owns_kar98k and not owns_mg42:
			can_afford = false; reason = "Требуется Kar98k или MG 42"
		elif current_shop_item_id == "ammo_762x54r" and not owns_pkm:
			can_afford = false; reason = "Требуется ПКМ"
		elif current_shop_item_id == "ammo_338lm" and not owns_l96a1:
			can_afford = false; reason = "Требуется L96A1"
		elif current_shop_item_id == "ammo_50ae" and not owns_deagle:
			can_afford = false; reason = "Требуется Desert Eagle"
		elif current_shop_item_id == "ammo_ugl" and (not wm or not wm.has_any_ugl()):
			can_afford = false; reason = "Установите ГП-25 / M203 на Верстаке"
		elif current_shop_item_id == "weapon_slot_4" and wm != null and wm.is_weapon_slot_unlocked(3):
			can_afford = false; reason = "СЛОТ [4] УЖЕ ОТКРЫТ"
		elif current_shop_item_id == "weapon_slot_5" and wm != null and wm.is_weapon_slot_unlocked(4):
			can_afford = false; reason = "СЛОТ [5] УЖЕ ОТКРЫТ"
		elif current_shop_item_id == "workbench" and has_wb:
			can_afford = false
			reason = "УЖЕ УСТАНОВЛЕН"
		elif current_shop_item_id == "vodka" and v_count >= 3:
			can_afford = false
			reason = "Слот [6] полон (3/3)"
		elif current_shop_item_id == "heavy_armor" and has_ha and arm >= 150.0:
			can_afford = false
			reason = "Броня на максимуме (150)"
		elif current_shop_item_id == "armor_plate":
			if not player.has_heavy_armor or player.armor < 76.0:
				can_afford = false
				reason = "Требуется активный сверхтяжелый жилет"
			elif player.armor >= 150.0:
				can_afford = false
				reason = "Броня на максимуме (150)"
		elif not can_afford:
			reason = "НЕДОСТАТОЧНО $"

		shop_buy_btn.disabled = not can_afford
		if can_afford:
			shop_buy_btn.text = data["btn_text"]
			shop_buy_btn.modulate = Color(1.0, 1.0, 1.0)
		else:
			if reason.length() > 0:
				shop_buy_btn.text = "%s (%s)" % [data["btn_text"], reason]
			else:
				shop_buy_btn.text = data["btn_text"]
			shop_buy_btn.modulate = Color(0.65, 0.65, 0.65)

func play_buy_sfx() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.bus = "SFX"
	sfx.stream = SoundEffects.create_buy_sound()
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _on_close_shop_pressed() -> void:
	close_shop()

var shop_zone_prompt_label: Label = null

func show_shop_zone_prompt(show_prompt: bool) -> void:
	if not shop_zone_prompt_label:
		shop_zone_prompt_label = Label.new()
		shop_zone_prompt_label.name = "ShopZonePrompt"
		shop_zone_prompt_label.text = "🛒 [B] МАГАЗИН   |   🗺 [M] СМЕНА КАРТЫ ($%d)" % GlobalSettings.MAP_TRAVEL_COST
		shop_zone_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shop_zone_prompt_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
		shop_zone_prompt_label.offset_left = -320
		shop_zone_prompt_label.offset_right = 320
		shop_zone_prompt_label.offset_top = -120
		shop_zone_prompt_label.offset_bottom = -90
		shop_zone_prompt_label.add_theme_font_size_override("font_size", 16)
		shop_zone_prompt_label.add_theme_color_override("font_color", Color(0.77, 0.65, 0.40))
		shop_zone_prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		shop_zone_prompt_label.add_theme_constant_override("outline_size", 4)
		add_child(shop_zone_prompt_label)
		
	shop_zone_prompt_label.visible = show_prompt and (not shop_panel or not shop_panel.visible)

# --- WAVE BANNER COUNTDOWN & INTEL ---

func show_wave_warmup(wave_num: int, remaining_sec: int, intel_text: String) -> void:
	wave_banner.visible = true
	wave_banner_title.text = "ПРИГОТОВЬТЕСЬ! ВОЛНА %d ЧЕРЕЗ: %d СЕК" % [wave_num, remaining_sec]
	wave_banner_intel.text = "РАЗВЕДКА: %s" % intel_text
	if wave_banner_hint:
		wave_banner_hint.text = "🛒 [B] МАГАЗИН | ⚡ [F] НАЧАТЬ ВОЛНУ"

func update_wave_warmup_countdown(wave_num: int, remaining_sec: int) -> void:
	if wave_banner.visible:
		wave_banner_title.text = "ПРИГОТОВЬТЕСЬ! ВОЛНА %d ЧЕРЕЗ: %d СЕК" % [wave_num, remaining_sec]

func show_wave_started() -> void:
	if shop_panel and shop_panel.visible:
		close_shop()
	if shop_zone_prompt_label:
		shop_zone_prompt_label.visible = false
	wave_banner_title.text = "ВОЛНА %d НАЧАЛАСЬ!" % current_wave_num
	if wave_banner_hint:
		wave_banner_hint.text = ""
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(wave_banner):
		wave_banner.visible = false

# --- PLAYER STATS UPDATES ---

func _on_health_changed(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current
	if health_label:
		health_label.text = "%d HP" % int(current)
		if current < 30:
			health_label.modulate = Color(0.95, 0.25, 0.25)
		else:
			health_label.modulate = Color(0.92, 0.90, 0.85)

func _on_armor_changed(current: float, max_val: float) -> void:
	if armor_bar:
		armor_bar.max_value = max_val
		armor_bar.value = current
		armor_bar.visible = current > 0.0
	if armor_label:
		armor_label.text = "%d БРОНЯ" % int(current)
		armor_label.visible = current > 0.0

func _on_stamina_changed(current: float, max_val: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = current
		if current <= 50.0:
			stamina_bar.add_theme_stylebox_override("fill", style_stamina_red)
		else:
			stamina_bar.add_theme_stylebox_override("fill", style_stamina_blue)
	if stamina_label:
		stamina_label.text = "%d ВЫНОСЛИВОСТЬ" % int(current)

func _on_score_changed(new_score: int) -> void:
	final_score = new_score
	if score_label:
		score_label.text = "$ %d" % new_score
	update_shop_ui()

func set_wave(wave_num: int) -> void:
	current_wave_num = wave_num
	if wave_label:
		wave_label.text = "WAVE %d" % wave_num

var prev_weapon_label_text: String = ""

func set_knife_active_ui(active: bool) -> void:
	if not eft_knife_cell.is_empty():
		var k_sb: StyleBoxFlat = eft_knife_cell["style"]
		var k_lbl: Label = eft_knife_cell["label"]
		if active:
			k_sb.bg_color = Color(0.22, 0.18, 0.10, 0.95)
			k_sb.border_color = Color(0.98, 0.80, 0.34, 1.0)
			k_sb.border_width_left = 2; k_sb.border_width_top = 2; k_sb.border_width_right = 2; k_sb.border_width_bottom = 2
			k_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
		else:
			k_sb.bg_color = Color(0.08, 0.08, 0.09, 0.84)
			k_sb.border_color = Color(0.56, 0.50, 0.36, 0.80)
			k_sb.border_width_left = 1; k_sb.border_width_top = 1; k_sb.border_width_right = 1; k_sb.border_width_bottom = 1
			k_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78))
	if weapon_label:
		if active:
			if weapon_label.text != "НОЖ":
				prev_weapon_label_text = weapon_label.text
			weapon_label.text = "НОЖ"
		else:
			var player = get_parent()
			if player and "weapon_manager" in player and player.weapon_manager and player.weapon_manager.current_weapon:
				weapon_label.text = player.weapon_manager.current_weapon.name.to_upper()
			elif prev_weapon_label_text.length() > 0 and prev_weapon_label_text != "НОЖ":
				weapon_label.text = prev_weapon_label_text
			else:
				weapon_label.text = "ПУСТО"

func _on_slots_updated() -> void:
	var player = get_parent()
	if not player or not ("weapon_manager" in player) or not player.weapon_manager:
		return
	var wm = player.weapon_manager
	var labels := [weapon_1_label, weapon_2_label, weapon_3_label]
	for i in range(3):
		if i < labels.size() and labels[i]:
			var w: Weapon = wm.weapon_slots[i] if i < wm.weapon_slots.size() else null
			if w:
				labels[i].text = "[%d] %s" % [i + 1, w.name.to_upper()]
			else:
				labels[i].text = "[%d] ПУСТО" % (i + 1)
	if wm.current_weapon:
		current_slot = wm.current_weapon_idx + 1
		highlight_weapon_card(current_slot)
	else:
		current_slot = 0
		highlight_weapon_card(0)
	_refresh_eft_quickbar()

func _on_weapon_changed(weapon: Weapon) -> void:
	var player = get_parent()
	var slot_num: int = 0
	if player and "weapon_manager" in player and player.weapon_manager:
		slot_num = player.weapon_manager.current_weapon_idx + 1
	elif weapon:
		slot_num = weapon.slot
	current_slot = slot_num
	if weapon_label:
		if weapon:
			weapon_label.text = weapon.name.to_upper()
		else:
			weapon_label.text = "ПУСТО"
		prev_weapon_label_text = weapon_label.text
	highlight_weapon_card(current_slot if weapon != null else 0)

func highlight_weapon_card(slot: int) -> void:
	if weapon_1_card:
		weapon_1_card.modulate = Color(1.2, 1.2, 1.2) if slot == 1 else Color(0.6, 0.6, 0.6, 0.6)
	if weapon_2_card:
		weapon_2_card.modulate = Color(1.2, 1.2, 1.2) if slot == 2 else Color(0.6, 0.6, 0.6, 0.6)
	if weapon_3_card:
		weapon_3_card.modulate = Color(1.2, 1.2, 1.2) if slot == 3 else Color(0.6, 0.6, 0.6, 0.6)
	if knife_card and (not knife_card_tween or not knife_card_tween.is_running()):
		knife_card.modulate = Color(0.6, 0.6, 0.6, 0.6)
	_refresh_eft_quickbar()

func flash_knife_indicator() -> void:
	if not eft_knife_cell.is_empty():
		var k_panel: PanelContainer = eft_knife_cell["panel"]
		if eft_knife_tween:
			eft_knife_tween.kill()
		k_panel.modulate = Color(1.5, 1.4, 1.1, 1.0)
		eft_knife_tween = create_tween()
		eft_knife_tween.tween_property(k_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
	if knife_card and knife_card.visible:
		if knife_card_tween:
			knife_card_tween.kill()
		knife_card.modulate = Color(1.5, 1.5, 1.5, 1.0)
		knife_card_tween = create_tween()
		knife_card_tween.tween_property(knife_card, "modulate", Color(0.6, 0.6, 0.6, 0.6), 0.35)

func _on_ammo_updated(current: int, reserve: int, is_reloading: bool, _has_chamber: bool = true, shotgun_4_1: bool = false) -> void:
	if ammo_label:
		var player = get_parent()
		var wm = player.weapon_manager if (player and "weapon_manager" in player) else null
		var cw: Weapon = wm.current_weapon if wm else null
		var inf_res: bool = wm.infinite_reserve_ammo if (wm and "infinite_reserve_ammo" in wm) else false
		var res_str: String = "∞" if inf_res else str(reserve)
		
		if cw == null:
			ammo_label.text = "-- / --"
		elif wm and ("is_ugl_mode" in wm) and wm.is_ugl_mode:
			var ugl_res_str: String = "∞" if inf_res else str(cw.ugl_reserve)
			ammo_label.text = "%d / %s" % [cw.ugl_ammo, ugl_res_str]
		elif cw.is_rpg:
			ammo_label.text = "%d / %s" % [current, res_str]
		elif cw.is_shotgun:
			if current > cw.mag_size:
				ammo_label.text = "%d+1 / %s" % [cw.mag_size, res_str]
			elif current == cw.mag_size and shotgun_4_1:
				ammo_label.text = "%d+1 / %s" % [cw.mag_size - 1, res_str]
			else:
				ammo_label.text = "%d / %s" % [current, res_str]
		else:
			if current > cw.mag_size:
				ammo_label.text = "%d+1 / %s" % [cw.mag_size, res_str]
			else:
				ammo_label.text = "%d / %s" % [current, res_str]
			
	if reload_label:
		var player2 = get_parent()
		var wm2 = player2.weapon_manager if (player2 and "weapon_manager" in player2) else null
		var rel_ugl: bool = wm2 != null and ("is_reloading_ugl" in wm2) and wm2.is_reloading_ugl
		reload_label.visible = is_reloading or rel_ugl

func flash_damage() -> void:
	if damage_tween:
		damage_tween.kill()
	damage_overlay.modulate.a = 0.5
	damage_tween = create_tween()
	damage_tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.35)

func show_hitmarker() -> void:
	if hitmarker_tween:
		hitmarker_tween.kill()
	hitmarker.modulate.a = 1.0
	hitmarker.scale = Vector2(1.2, 1.2)
	hitmarker_tween = create_tween()
	hitmarker_tween.tween_property(hitmarker, "scale", Vector2.ONE, 0.05)
	hitmarker_tween.tween_property(hitmarker, "modulate:a", 0.0, 0.15)

func _on_player_died() -> void:
	if is_game_over:
		return
	is_respawning = true
	respawn_countdown = 10.0
	if respawn_overlay:
		respawn_overlay.visible = true
	if shop_panel:
		shop_panel.visible = false
	if handbook_panel:
		handbook_panel.visible = false
	if pause_panel:
		pause_panel.visible = false
	if inventory_ui:
		inventory_ui.visible = false
	if workbench_ui:
		workbench_ui.visible = false
	if cheat_menu_ui:
		cheat_menu_ui.visible = false
	if map_travel_ui:
		map_travel_ui.visible = false

func build_respawn_overlay() -> void:
	respawn_overlay = Panel.new()
	respawn_overlay.name = "RespawnOverlay"
	respawn_overlay.anchors_preset = Control.PRESET_FULL_RECT
	respawn_overlay.anchor_right = 1.0
	respawn_overlay.anchor_bottom = 1.0
	respawn_overlay.visible = false
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.08, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.65, 0.16, 0.16, 0.9)
	respawn_overlay.add_theme_stylebox_override("panel", sb)
	
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -300
	vbox.offset_right = 300
	vbox.offset_top = -80
	vbox.offset_bottom = 80
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	respawn_overlay.add_child(vbox)
	
	respawn_title = Label.new()
	respawn_title.text = "ВЫ ПОГИБЛИ"
	respawn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_title.add_theme_font_size_override("font_size", 36)
	respawn_title.add_theme_color_override("font_color", Color(0.85, 0.20, 0.20))
	vbox.add_child(respawn_title)
	
	respawn_timer_label = Label.new()
	respawn_timer_label.text = "Возрождение у дверей магазина через: 10 сек..."
	respawn_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_timer_label.add_theme_font_size_override("font_size", 16)
	respawn_timer_label.add_theme_color_override("font_color", Color(0.77, 0.65, 0.40))
	vbox.add_child(respawn_timer_label)
	
	add_child(respawn_overlay)

func _on_restart_wave_pressed() -> void:
	is_game_over = false
	game_over_panel.visible = false
	
	# Restart current wave in EnemySpawner with 50% shop HP and preserved inventory
	var spawner = get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("restart_current_wave"):
		spawner.restart_current_wave(true)
		
	var player = get_parent()
	if player and player.has_method("reset_after_wave_restart"):
		player.reset_after_wave_restart()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_vodka_count_changed(count: int) -> void:
	if weapon_5_label:
		weapon_5_label.text = "[6] ЧЕКУНЕЦ 67 (%d/3)" % count
	if weapon_5_card:
		if count > 0:
			weapon_5_card.modulate = Color(1.0, 1.0, 1.0, 0.9)
		else:
			weapon_5_card.modulate = Color(0.5, 0.5, 0.5, 0.5)
	_refresh_eft_quickbar()

func _on_vodka_buff_updated(is_active: bool, time_left: float) -> void:
	if is_active:
		if weapon_5_label:
			weapon_5_label.text = "[6] ВОДКА: %.1fc" % time_left
		if weapon_5_card:
			weapon_5_card.modulate = Color(1.3, 1.1, 0.3, 1.0)
	else:
		var p = get_parent()
		var count: int = p.vodka_count if (p and "vodka_count" in p) else 0
		_on_vodka_count_changed(count)
	_refresh_eft_quickbar()

# --- SHOP DEFENSE HEALTH BAR (DEPRECATED STUBS) ---

func build_shop_health_bar() -> void:
	pass

func update_shop_health(_current: float, _max_val: float) -> void:
	pass

func trigger_shop_destroyed() -> void:
	pass
