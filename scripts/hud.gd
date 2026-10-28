extends CanvasLayer

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
@onready var weapon_2_card: PanelContainer = $TopRight/WeaponList/W2
@onready var weapon_3_card: PanelContainer = $TopRight/WeaponList/W3
@onready var weapon_5_card: PanelContainer = $TopRight/WeaponList/W5
@onready var weapon_5_label: Label = $TopRight/WeaponList/W5/Label
@onready var knife_card: PanelContainer = $KnifeCard
@onready var weapon_4_card: PanelContainer = $KnifeCard

@onready var score_label: Label = $TopLeft/ScoreLabel
@onready var wave_label: Label = $TopLeft/WaveLabel

@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var hitmarker: Control = $Crosshair/Hitmarker

# Death Screen
@onready var game_over_panel: Panel = $GameOverPanel
@onready var death_stats_label: Label = $GameOverPanel/VBox/StatsLabel

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

# Shop catalog database
var current_shop_item_id: String = "ak"
var shop_catalog = {
	"ak": {
		"title": "ПАТРОНЫ АК-47 (7.62x39)",
		"price": 20,
		"desc": "Секторный коробчатый магазин на 30 промежуточных патронов 7.62x39 мм для автомата Калашникова.",
		"stat1_label": "Боезапас в пачке: +30 патронов",
		"stat1_val": 30.0,
		"stat1_max": 60.0,
		"stat2_label": "Урон за пулю: 32 ед.",
		"stat2_val": 32.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 30 ПАТРОНОВ ($20)"
	},
	"shotgun": {
		"title": "КАРТЕЧЬ ДРОБОВИКА (12 GAUGE)",
		"price": 3,
		"desc": "Тяжелый патрон 12 калибра со свинцовой картечью 8.5 мм. Смертоносен на ближней дистанции.",
		"stat1_label": "Боезапас в пачке: +1 патрон",
		"stat1_val": 1.0,
		"stat1_max": 10.0,
		"stat2_label": "Урон залпа: 144 ед. (8 картечин по 18 ед.)",
		"stat2_val": 144.0,
		"stat2_max": 150.0,
		"btn_text": "КУПИТЬ 1 ПАТРОН ($3)"
	},
	"pistol": {
		"title": "ПАТРОНЫ ПИСТОЛЕТА (9x19)",
		"price": 12,
		"desc": "Двухрядный магазин на 17 пистолетных патронов 9x19 мм Parabellum. Высокая точность и темп огня.",
		"stat1_label": "Боезапас в пачке: +17 патронов",
		"stat1_val": 17.0,
		"stat1_max": 34.0,
		"stat2_label": "Урон за пулю: 26 ед.",
		"stat2_val": 26.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ 17 ПАТРОНОВ ($12)"
	},
	"medkit": {
		"title": "БОЛЬШАЯ ПОЛЕВАЯ АПТЕЧКА",
		"price": 40,
		"desc": "Войсковой реанимационный комплект первой помощи с гемостатиками. Мгновенно восстанавливает здоровье.",
		"stat1_label": "Восстановление здоровья: +50 HP",
		"stat1_val": 50.0,
		"stat1_max": 100.0,
		"btn_text": "КУПИТЬ АПТЕЧКУ ($40)"
	},
	"vodka": {
		"title": "ВОДКА \"ЧЕКУНЕЦ 67\"",
		"price": 67,
		"desc": "Стеклянный чекунец легендарной 40-градусной водки. Мгновенно лечит 6-7 HP, удваивает запас выносливости (до 300) и ускоряет спринт в 1.5 раза на 15 секунд без штрафов усталости! Вместимость слота [5]: до 3 шт.",
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
		"price": 80,
		"desc": "Штурмовой комплекс максимального класса защиты (150 брони). Весь входящий урон уменьшается вдвое, после чего делится поровну между здоровьем и броней. Действует пока броня не упадет ниже 76.",
		"stat1_label": "Запас брони: 150 ед.",
		"stat1_val": 150.0,
		"stat1_max": 150.0,
		"stat2_label": "Поглощение урона: -50% + Сплит",
		"stat2_val": 100.0,
		"stat2_max": 100.0,
		"btn_text": "КУПИТЬ СВЕРХТЯЖЕЛЫЙ ($80)"
	},
	"armor_plate": {
		"title": "БРОНЕПЛИТА ДЛЯ СВЕРХТЯЖЕЛОГО (+30)",
		"price": 30,
		"desc": "Сменная титано-керамическая бронеплита. Восстанавливает +30 единиц брони сверхтяжелого бронежилета (вплоть до 150). Недоступна к покупке без активного сверхтяжелого жилета (требуется броня >= 76).",
		"stat1_label": "Восстановление брони: +30 ед.",
		"stat1_val": 30.0,
		"stat1_max": 50.0,
		"btn_text": "КУПИТЬ БРОНЕПЛИТУ ($30)"
	}
}

# Handbook item database
var handbook_db = {
	"ak47": {
		"title": "АК-47 (АВТОМАТ КАЛАШНИКОВА)",
		"bars": [
			{"name": "Урон за пулю: 32 ед.", "val": 32.0, "max": 100.0},
			{"name": "Темп огня: ~600 выстр/мин", "val": 600.0, "max": 800.0},
			{"name": "Емкость магазина: 30 патронов", "val": 30.0, "max": 60.0},
			{"name": "Эффективная дальность: Высокая", "val": 85.0, "max": 100.0}
		],
		"stats": "• Калибр: 7.62x39 мм образца 1943 года\n• Режим огня: Полный автомат (~600 выстр/мин)\n• Магазин: Секторный коробчатый на 30 патронов\n• Урон: 32 ед. на любой дистанции\n• Особенности: Легендарная надежность газоотводной автоматики с длинным ходом поршня. Громкий басовитый выстрел и звонкий металлический лязг затвора внушают первобытный ужас в космических захватчиков."
	},
	"shotgun": {
		"title": "ПОМПОВЫЙ ДРОБОВИК",
		"bars": [
			{"name": "Урон залпа: 144 ед. (8x18)", "val": 144.0, "max": 150.0},
			{"name": "Темп огня: ~65 выстр/мин", "val": 65.0, "max": 800.0},
			{"name": "Емкость магазина: 5 патронов", "val": 5.0, "max": 60.0},
			{"name": "Разброс картечи: Широкий", "val": 80.0, "max": 100.0}
		],
		"stats": "• Калибр: 12 Gauge (картечь 8.5 мм)\n• Режим огня: Ручная перезарядка подвижным цевьем\n• Магазин: Подствольный трубчатый на 5 патронов\n• Урон: 8 картечин по 18 ед. (до 144 ед. суммарно в упор)\n• Особенности: Оглушительный грохот картечного залпа и смачный клацающий звук досылания патронов в патронник. Идеальный аргумент для зачистки узких коридоров станции."
	},
	"pistol": {
		"title": "ТАКТИЧЕСКИЙ ПИСТОЛЕТ",
		"bars": [
			{"name": "Урон за пулю: 26 ед.", "val": 26.0, "max": 100.0},
			{"name": "Темп огня: ~400 выстр/мин", "val": 400.0, "max": 800.0},
			{"name": "Емкость магазина: 17 патронов", "val": 17.0, "max": 60.0},
			{"name": "Точность стрельбы: Высокая", "val": 90.0, "max": 100.0}
		],
		"stats": "• Калибр: 9x19 мм Parabellum\n• Режим огня: Полуавтоматический\n• Магазин: Двухрядный на 17 патронов\n• Урон: 26 ед.\n• Особенности: Высокоточный полимерный аналог Glock 17. Звонкий сверхзвуковой щелчок выстрела, моментальный сброс магазина и четкий металлический спуск затворной задержки."
	},
	"knife": {
		"title": "АРМЕЙСКИЙ ШТЫКОВОЙ НОЖ",
		"bars": [
			{"name": "Урон удара: 70 ед.", "val": 70.0, "max": 100.0},
			{"name": "Скорость удара: 0.35 сек", "val": 85.0, "max": 100.0},
			{"name": "Дистанция атаки: 2.8 м", "val": 28.0, "max": 100.0},
			{"name": "Охват экрана: 60%", "val": 60.0, "max": 100.0}
		],
		"stats": "• Тип: Тактическое холодное оружие ближнего боя\n• Быстрый удар: Клавиша [V] в любой момент\n• Урон: 70 ед. чистой стали\n• Дистанция поражения: 2.8 метра\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Штатный штык-нож с гравировкой \"Не влезай — зарежет!\". Найден на складе запчастей, где им десять лет подряд открывали консервные банки со сгущенкой и зачищали оптоволоконные кабели. Заточен до состояния лазерной бритвы. При нажатии клавиши [V] персонаж мгновенно опускает огнестрел и совершает сокрушительный диагональный росчерк на 60% экрана, рассекая скафандры предателей быстрее, чем они успеют нажать кнопку тревоги!»"
	},
	"enemy_red": {
		"title": "КРАСНЫЙ КРЮМЕЙТ (ОБЫЧНЫЙ ИМПОСТОР)",
		"bars": [
			{"name": "Здоровье: 100 HP", "val": 100.0, "max": 300.0},
			{"name": "Скорость бега: 4.2 м/с", "val": 4.2, "max": 10.0},
			{"name": "Урон автомата: 10 ед./пуля", "val": 10.0, "max": 50.0},
			{"name": "Награда: $4", "val": 4.0, "max": 20.0}
		],
		"stats": "• Здоровье: 100 HP | Скорость: 4.2 м/с\n• Вооружение: Автомат Калашникова (очереди по 3 выстрела, 10 урона за пулю)\n• Награда за ликвидацию: +$4\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Бывший корабельный кок с рейса \"Skeld-9\". Зашел в электрощитовую разогреть шаурму на главной энергомагистрали, случайно закоротил силовой кабель и устроил саботаж века. Когда экипаж собрал экстренное совещание, Красный так яростно доказывал, что \"просто чистил картошку разводным ключом\", что случайно выбросил капитана в шлюз. С тех пор бродит с АК-47, от испуга палит короткими очередями на каждый шорох и свято верит, что все вокруг — предатели, кроме него.»"
	},
	"enemy_blue": {
		"title": "СИНИЙ КРЮМЕЙТ (БЫСТРЫЙ СКАУТ)",
		"bars": [
			{"name": "Здоровье: 80 HP", "val": 80.0, "max": 300.0},
			{"name": "Скорость бега: 6.2 м/с (Спринт)", "val": 6.2, "max": 10.0},
			{"name": "Урон пистолета: 8 ед./пуля", "val": 8.0, "max": 50.0},
			{"name": "Награда: $6", "val": 6.0, "max": 20.0}
		],
		"stats": "• Здоровье: 80 HP | Скорость: 6.2 м/с (Сверхбыстрый спринтер)\n• Вооружение: Тактический пистолет (8 урона, частые полуавтоматические выстрелы)\n• Трофеи: ~12% шанс сбросить Полевые бинты (+10 HP)\n• Награда за ликвидацию: +$6\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Абсолютный чемпион корабля по скоростному залезанию в вентиляционные люки. Утром перед вылетом случайно насыпал в чашку концентрированный ракетный окислитель вместо быстрорастворимого кофе. В итоге получил пульс 350 ударов в минуту, сверхзвуковую скорость 6.2 м/с и привычку бегать исключительно нервными зигзагами. В карманах всегда таскает бинты, потому что на такой дикой скорости регулярно не вписывается в дверные проемы отсеков и со звоном впечатывается шлемом в переборки.»"
	},
	"enemy_yellow": {
		"title": "ЖЕЛТЫЙ КРЮМЕЙТ (ТЯЖЕЛОВЕС / БЕРСЕРК)",
		"bars": [
			{"name": "Здоровье: 280 HP (Тяжеловес)", "val": 280.0, "max": 300.0},
			{"name": "Скорость бега: 3.2 м/с", "val": 3.2, "max": 10.0},
			{"name": "Урон топора: 38 ед.", "val": 38.0, "max": 50.0},
			{"name": "Награда: $12", "val": 12.0, "max": 20.0}
		],
		"stats": "• Здоровье: 280 HP (Титаническая броня) | Скорость: 3.2 м/с\n• Вооружение: Тяжелый двуручный топор (38 ед. сокрушительного рубящего урона)\n• Трофеи: 100% гарантированный сброс Бронежилета (+15 брони)!\n• Награда за ликвидацию: +$12\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Старший системный администратор реакторного отсека. Когда на станции упал Wi-Fi сервер с любимым сериалом, воспринял инструкцию \"перерубить кабель аварийного питания\" с пугающей прямолинейностью. Натянул на пузо три слоя тяжелых кевларовых бронежилетов, выломал из пожарного щита гигантский двуручный топор и пошел лично разбираться с пользователями. Огнестрел презирает как изобретение трусов (\"хороший рубящий удар сверху лечит любые синие экраны смерти!\"). Если его победить, можно забрать его бронежилет прямо из лужи искр.»"
	},
	"enemy_green": {
		"title": "ЗЕЛЕНЫЙ КРЮМЕЙТ (СНАЙПЕР)",
		"bars": [
			{"name": "Здоровье: 60 HP", "val": 60.0, "max": 300.0},
			{"name": "Скорость бега: 3.5 м/с", "val": 3.5, "max": 10.0},
			{"name": "Урон AWP: 48 ед.", "val": 48.0, "max": 50.0},
			{"name": "Награда: $10", "val": 10.0, "max": 20.0}
		],
		"stats": "• Здоровье: 60 HP | Скорость: 3.5 м/с\n• Эксклюзивное оружие: Снайперская винтовка AWP (.338 Lapua Magnum, урон 48 ед., интервал 3.8с)\n• Дебафф оптики: За 1.6 сек до выстрела линза прицела ослепительно бликует (Lens Flare)!\n• Трофеи: ~12% шанс сбросить Полевые бинты (+10 HP)\n• Награда за ликвидацию: +$10\n\n📜 СЕКРЕТНОЕ ДОСЬЕ / ЗАБАВНАЯ ИСТОРИЯ:\n«Тонкая натура, романтик и астроном-самоучка. Мечтал открывать новые созвездия, поэтому тайком прикрутил к армейской винтовке AWP объектив от списанного орбитального телескопа \"Хаббл\". Теперь видит цель через три жилых модуля, но стал жертвой законов оптики: его гигантская линза за полторы секунды до выстрела сияет на солнце ярче диско-шара на сельской дискотеке. Сам Зеленый непоколебимо уверен, что этот демаскирующий блик — \"божественное сияние его непревзойденной снайперской харизмы\".»"
	},
	"armor_vest": {
		"title": "ТАКТИЧЕСКИЙ БРОНЕЖИЛЕТ",
		"bars": [
			{"name": "Запас брони: +15 ед.", "val": 15.0, "max": 75.0},
			{"name": "Поглощение урона: 50%", "val": 50.0, "max": 100.0},
			{"name": "Время жизни: 30 сек", "val": 30.0, "max": 60.0}
		],
		"stats": "• Класс защиты: Кевларовый жилет с титаново-керамической пластиной\n• Вместимость: +15 ед. брони (максимум до 75 ед.)\n• Механика поглощения: Поглощает ровно 50% входящего урона (вторая половина идет в HP).\n• Время жизни в мире: 30 секунд.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Тот самый бронежилет, снятый с туловища Желтого тяжеловеса. В нагрудных карманах до сих пор лежат обертки от космических сухпайков и инструкция по сборке топора. При подборе персонаж со смачным глухим стуком вгоняет керамическую плиту в отсек, намертво лепит липучку и с сочным хрустом застегивает молнию куртки!»"
	},
	"bandage": {
		"title": "ПОЛЕВЫЕ БИНТЫ",
		"bars": [
			{"name": "Восстановление: +10 HP", "val": 10.0, "max": 50.0},
			{"name": "Применение: Мгновенное", "val": 100.0, "max": 100.0},
			{"name": "Время жизни: 30 сек", "val": 30.0, "max": 60.0}
		],
		"stats": "• Тип: Стерильный медицинский перевязочный рулон\n• Эффект: Мгновенно восстанавливает +10 HP (максимум до 100 HP)\n• Источник: Выпадает с шансом ~12% исключительно с Синих Скаутов и Зеленых Снайперов.\n• Время жизни в мире: 30 секунд.\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Тактический марлевый рулон высшего сорта с тонким ароматом спирта и целебного космического подорожника. При подборе слышен характерный шелест быстрой перевязки и звонкий \"вжух-хрусь\" отрываемого края!»"
	},
	"medkit": {
		"title": "БОЛЬШАЯ ПОЛЕВАЯ АПТЕЧКА",
		"bars": [
			{"name": "Восстановление здоровья: +50 HP", "val": 50.0, "max": 100.0},
			{"name": "Стоимость в магазине: $40", "val": 40.0, "max": 100.0}
		],
		"stats": "• Тип: Полевой реанимационный кейс с медикаментами\n• Эффект: Мгновенно восстанавливает +50 HP\n• Стоимость в полевом магазине: $40\n\n📦 ПОЛЕВЫЕ ЗАМЕТКИ:\n«Тяжелый белый чемоданчик с красным крестом, набитый боевыми стимуляторами, био-гелем и рулонами космической синей изоленты. На внутренней стороне крышки нацарапано: \"Если оторвало руку — примотай обратно и беги на волну\". Мгновенно ставит на ноги даже бойцов, переживших выстрел снайперского AWP в упор!»"
	},
	"enemy_shahed": {
		"title": "БПЛА \"SHAHED\" (ДРОН-КАМИКАДЗЕ)",
		"bars": [
			{"name": "Здоровье: 30 HP", "val": 30.0, "max": 100.0},
			{"name": "Скорость пике: Высокая", "val": 95.0, "max": 100.0},
			{"name": "Урон взрыва: 50 HP (АОЕ)", "val": 50.0, "max": 100.0},
			{"name": "Уязвимость к дробовику: 1 выстрел", "val": 100.0, "max": 100.0}
		],
		"stats": "• Тип: Летающий барражирующий боеприпас / дрон-камикадзе\n• Здоровье: 30 HP\n• Маневр: Полет во всех 3 плоскостях (X, Y, Z), барражирование на высоте\n• Атака: Стремительное пикирование с леденящим воем двигателя и мощный взрыв (-50 HP) по игроку и врагам в радиусе 5.5м!\n• Критическая уязвимость: Дробовик уничтожает дрон С ОДНОГО ПОПАДАНИЯ ДАЖЕ ОДНОЙ КАРТЕЧЬЮ!\n\nТактическое досье:\nНизколетящий треугольный кошмар с характерным звуком двухтактного мотора мопеда. Заметив игрока, начинает крутое пике с пронзительным воем сирены. Не подпускайте в упор! Однако широкая картечь дробовика превращает дрон в металлолом с одного попадания на любой дистанции — цельтесь навстречу и стреляйте!"
	},
	"vodka": {
		"title": "ВОДКА \"ЧЕКУНЕЦ 67\"",
		"bars": [
			{"name": "Лечение: +6-7 HP", "val": 7.0, "max": 50.0},
			{"name": "Макс. выносливость: 300", "val": 100.0, "max": 100.0},
			{"name": "Скорость бега: +50%", "val": 75.0, "max": 100.0},
			{"name": "Длительность эффекта: 15 сек", "val": 15.0, "max": 30.0}
		],
		"stats": "• Тип: Тактический стимулятор / крепкий алкогольный напиток\n• Объем / Крепость: 0.25 л / 40% об.\n• Слот инвентаря: Клавиша [5] (вместимость до 3 бутылок)\n• Эффект:\n  - Мгновенно заживляет 6-7 HP здоровья\n  - Удваивает максимальную выносливость со 150 до 300 пунктов!\n  - Увеличивает скорость спринта в 1.5 раза\n  - Полностью отключает штрафы усталости и отдышки на 15 секунд!\n\nТактическое досье:\nТот самый \"Чекунец 67\" в компактной плоской бутылке. В критический момент боя глоток чекунца прочищает разум, снимает усталость и дарует богатырский спринт, позволяя уйти из окружения или разорвать дистанцию с толпой предателей."
	},
	"heavy_armor": {
		"title": "СВЕРХТЯЖЕЛЫЙ БРОНЕЖИЛЕТ (150 БР)",
		"bars": [
			{"name": "Макс. броня: 150 ед.", "val": 150.0, "max": 150.0},
			{"name": "Снижение урона: -50%", "val": 50.0, "max": 100.0},
			{"name": "Разделение урона: 50% HP / 50% БР", "val": 50.0, "max": 100.0},
			{"name": "Порог активности: >= 76 БР", "val": 76.0, "max": 150.0}
		],
		"stats": "• Класс защиты: 6А Сверхтяжелый штурмовой комплект\n• Емкость: 150 единиц брони (полный комплект при покупке)\n• Уникальная механика:\n  1. Любой входящий урон сначала РЕЖЕТСЯ ВДВОЕ (-50%)\n  2. Оставшийся урон делится поровну: 50% в здоровье, 50% в броню\n  3. Обычные бронежилеты с желтых врагов НЕ восполняют броню, пока она выше 75\n  4. Если броня опустится ниже 76 ед. (< 76), весь эффект сверхзащиты отключается и жилет возвращается к стандарту (макс 75)!\n\nТактическое досье:\nТитано-композитный экзо-бронежилет, предназначенный для штурма укрепленных позиций. Дает невероятную выживаемость под перекрестным огнем, но требует бережного ухода и своевременной замены плит!"
	},
	"armor_plate": {
		"title": "БРОНЕПЛИТА ДЛЯ СВЕРХТЯЖЕЛОГО",
		"bars": [
			{"name": "Восстановление брони: +30 ед.", "val": 30.0, "max": 50.0},
			{"name": "Стоимость: $30", "val": 30.0, "max": 100.0},
			{"name": "Лимит брони: До 150 ед.", "val": 150.0, "max": 150.0},
			{"name": "Требование: Сверхтяжелый (>= 76)", "val": 100.0, "max": 100.0}
		],
		"stats": "• Тип: Комплект титано-керамических бронепластин BR-5+\n• Эффект: Мгновенно восстанавливает +30 единиц брони сверхтяжелого бронежилета (вплоть до 150)\n• Условие покупки: Нельзя купить без активного сверхтяжелого бронежилета (требуется наличие жилета и текущая броня >= 76)\n\nТактическое досье:\nЗапасная бронеплита позволяет поддерживать ресурс сверхтяжелого бронежилета выше критического порога в 76 единиц, не допуская разрушения композитной матрицы."
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
	
	# Create stamina dynamic styles
	style_stamina_blue = StyleBoxFlat.new()
	style_stamina_blue.bg_color = Color(0.2, 0.55, 1.0, 1.0)
	style_stamina_blue.corner_radius_top_left = 3
	style_stamina_blue.corner_radius_top_right = 3
	style_stamina_blue.corner_radius_bottom_right = 3
	style_stamina_blue.corner_radius_bottom_left = 3
	
	style_stamina_red = StyleBoxFlat.new()
	style_stamina_red.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	style_stamina_red.corner_radius_top_left = 3
	style_stamina_red.corner_radius_top_right = 3
	style_stamina_red.corner_radius_bottom_right = 3
	style_stamina_red.corner_radius_bottom_left = 3
	
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
		stamina_label.modulate = Color(0.25, 0.65, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_game_over:
			return
		if shop_panel and shop_panel.visible:
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

func _on_close_handbook_pressed() -> void:
	handbook_panel.visible = false
	pause_panel.visible = true

func _on_hb_ak47_pressed() -> void:
	select_handbook_item("ak47")

func _on_hb_shotgun_pressed() -> void:
	select_handbook_item("shotgun")

func _on_hb_pistol_pressed() -> void:
	select_handbook_item("pistol")

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

# --- FIELD SHOP SYSTEM (HANDBOOK STYLE) ---

func select_shop_item(item_id: String) -> void:
	if not shop_catalog.has(item_id):
		return
	current_shop_item_id = item_id
	var data = shop_catalog[item_id]
	
	if shop_item_title:
		shop_item_title.text = data["title"]
	if shop_price_badge:
		shop_price_badge.text = "Стоимость: $%d" % data["price"]
	if shop_item_desc:
		shop_item_desc.text = data["desc"]
		
	if shop_preview and shop_preview.has_method("show_item"):
		var preview_id: String = "ak47" if item_id == "ak" else item_id
		shop_preview.show_item(preview_id)
		
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
	var data = shop_catalog[current_shop_item_id]
	var price: int = data["price"]
	var player = get_parent()
	if not player or not player.has_method("spend_money"):
		return
		
	# Check custom purchase constraints before taking money
	match current_shop_item_id:
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
		match current_shop_item_id:
			"ak":
				if player.weapon_manager:
					player.weapon_manager.add_reserve_ammo(1, 30)
			"shotgun":
				if player.weapon_manager:
					player.weapon_manager.add_reserve_ammo(2, 1)
			"pistol":
				if player.weapon_manager:
					player.weapon_manager.add_reserve_ammo(3, 17)
			"medkit":
				player.add_health(50.0)
			"vodka":
				player.add_vodka()
			"heavy_armor":
				player.buy_heavy_armor()
			"armor_plate":
				player.buy_armor_plate()
				
		play_buy_sfx()
		update_shop_ui()

func open_shop() -> void:
	if is_game_over:
		return
	if shop_panel:
		shop_panel.visible = true
	select_shop_item(current_shop_item_id)
	update_shop_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var spawner = get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("pause_warmup"):
		spawner.pause_warmup(true)

func close_shop() -> void:
	if shop_panel:
		shop_panel.visible = false
	if not pause_panel.visible and not handbook_panel.visible and not is_game_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	var spawner = get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_method("pause_warmup"):
		spawner.pause_warmup(false)

func toggle_shop() -> void:
	if shop_panel and shop_panel.visible:
		close_shop()
	else:
		open_shop()

func update_shop_ui() -> void:
	var player = get_parent()
	if not player:
		return
	if shop_balance_label:
		shop_balance_label.text = "БАЛАНС: $ %d" % player.money
		
	if shop_buy_btn and shop_catalog.has(current_shop_item_id):
		var data = shop_catalog[current_shop_item_id]
		var can_afford: bool = player.money >= data["price"]
		var reason: String = ""
		
		if current_shop_item_id == "vodka" and player.vodka_count >= 3:
			can_afford = false
			reason = "Слот [5] полон (3/3)"
		elif current_shop_item_id == "heavy_armor" and player.has_heavy_armor and player.armor >= 150.0:
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
	sfx.stream = SoundEffects.create_buy_sound()
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _on_close_shop_pressed() -> void:
	close_shop()

# --- WAVE BANNER COUNTDOWN & INTEL ---

func show_wave_warmup(wave_num: int, remaining_sec: int, intel_text: String) -> void:
	wave_banner.visible = true
	wave_banner_title.text = "ПРИГОТОВЬТЕСЬ! ВОЛНА %d ЧЕРЕЗ: %d СЕК" % [wave_num, remaining_sec]
	wave_banner_intel.text = "РАЗВЕДКА: %s" % intel_text

func update_wave_warmup_countdown(wave_num: int, remaining_sec: int) -> void:
	if wave_banner.visible:
		wave_banner_title.text = "ПРИГОТОВЬТЕСЬ! ВОЛНА %d ЧЕРЕЗ: %d СЕК" % [wave_num, remaining_sec]

func show_wave_started() -> void:
	if shop_panel and shop_panel.visible:
		close_shop()
	wave_banner_title.text = "ВОЛНА НАЧАЛАСЬ! К БОЮ!"
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
			health_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			health_label.modulate = Color(1.0, 1.0, 1.0)

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
	if weapon_label:
		if active:
			if weapon_label.text != "Штык-нож":
				prev_weapon_label_text = weapon_label.text
			weapon_label.text = "Штык-нож"
		else:
			if prev_weapon_label_text.length() > 0 and prev_weapon_label_text != "Штык-нож":
				weapon_label.text = prev_weapon_label_text
			elif current_slot > 0:
				var w_names: Dictionary = {1: "AK-47", 2: "SHOTGUN", 3: "PISTOL"}
				weapon_label.text = str(w_names.get(current_slot, "AK-47"))

func _on_weapon_changed(weapon: Weapon) -> void:
	current_slot = weapon.slot
	if weapon_label:
		weapon_label.text = weapon.name.to_upper()
		prev_weapon_label_text = weapon_label.text
	highlight_weapon_card(weapon.slot)

func highlight_weapon_card(slot: int) -> void:
	if weapon_1_card:
		weapon_1_card.modulate = Color(1.2, 1.2, 1.2) if slot == 1 else Color(0.6, 0.6, 0.6, 0.6)
	if weapon_2_card:
		weapon_2_card.modulate = Color(1.2, 1.2, 1.2) if slot == 2 else Color(0.6, 0.6, 0.6, 0.6)
	if weapon_3_card:
		weapon_3_card.modulate = Color(1.2, 1.2, 1.2) if slot == 3 else Color(0.6, 0.6, 0.6, 0.6)
	if weapon_4_card and (not knife_card_tween or not knife_card_tween.is_running()):
		weapon_4_card.modulate = Color(0.6, 0.6, 0.6, 0.6)

func flash_knife_indicator() -> void:
	if not weapon_4_card:
		return
	if knife_card_tween:
		knife_card_tween.kill()
	weapon_4_card.modulate = Color(1.5, 1.5, 1.5, 1.0)
	knife_card_tween = create_tween()
	knife_card_tween.tween_property(weapon_4_card, "modulate", Color(0.6, 0.6, 0.6, 0.6), 0.35)

func _on_ammo_updated(current: int, reserve: int, is_reloading: bool, _has_chamber: bool = true, shotgun_4_1: bool = false) -> void:
	if ammo_label:
		match current_slot:
			1: # AK-47 (mag_size = 30)
				if current > 30:
					ammo_label.text = "30+1 / %d" % reserve
				else:
					ammo_label.text = "%d / %d" % [current, reserve]
			2: # Shotgun (mag_size = 5)
				if current > 5:
					ammo_label.text = "5+1 / %d" % reserve
				elif current == 5 and shotgun_4_1:
					ammo_label.text = "4+1 / %d" % reserve
				else:
					ammo_label.text = "%d / %d" % [current, reserve]
			3: # Pistol (mag_size = 17)
				if current > 17:
					ammo_label.text = "17+1 / %d" % reserve
				else:
					ammo_label.text = "%d / %d" % [current, reserve]
			_:
				ammo_label.text = "%d / %d" % [current, reserve]
			
	if reload_label:
		reload_label.visible = is_reloading

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
	is_game_over = true
	game_over_panel.visible = true
	pause_panel.visible = false
	handbook_panel.visible = false
	if shop_panel:
		shop_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var diff_str: String = "Нормальная"
	if GlobalSettings:
		match GlobalSettings.current_difficulty:
			0:
				diff_str = "Легкая"
			2:
				diff_str = "Сложная"
				
	if death_stats_label:
		death_stats_label.text = "Волна: %d  |  Деньги: $ %d  |  Сложность: %s" % [current_wave_num, final_score, diff_str]

func _on_restart_wave_pressed() -> void:
	if GlobalSettings:
		GlobalSettings.last_wave = current_wave_num
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_vodka_count_changed(count: int) -> void:
	if weapon_5_label:
		weapon_5_label.text = "[5] ЧЕКУНЕЦ 67 (%d/3)" % count
	if weapon_5_card:
		if count > 0:
			weapon_5_card.modulate = Color(1.0, 1.0, 1.0, 0.9)
		else:
			weapon_5_card.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _on_vodka_buff_updated(is_active: bool, time_left: float) -> void:
	if is_active:
		if weapon_5_label:
			weapon_5_label.text = "[5] ВОДКА: %.1fc" % time_left
		if weapon_5_card:
			weapon_5_card.modulate = Color(1.3, 1.1, 0.3, 1.0)
	else:
		var p = get_parent()
		var count: int = p.vodka_count if (p and "vodka_count" in p) else 0
		_on_vodka_count_changed(count)
