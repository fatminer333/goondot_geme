class_name CapturedSignal
extends Resource
# Сигнал новой линейки Терминалов 1-3: захват на карте → настройка → продажа.
@export var id: String = ""
@export var name_ru: String = "Сигнал"
@export var freq_mhz: float = 50.0 # 1.0 - 100.0, задаёт Терминал 1
@export var polarity_deg: float = 0.0 # 0 - 360, задаёт Терминал 1
@export var polarity_sign: int = 1 # +1 положительная, -1 отрицательная
@export var state: int = 0 # 0 захвачен (ждёт настройки), 1 настроен (можно продать)
@export var reward: int = 50
