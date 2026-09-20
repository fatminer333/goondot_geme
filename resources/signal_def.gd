class_name SignalDef
extends Resource
@export var id: String = ""
@export var name_ru: String = "Странный пульс"
@export var frequency_mhz: float = 87.5
@export var strength: float = 60.0
@export var type: int = 0 # 0 NARROW 1 PULSE 2 DRIFT 3 NOISE
@export var bandwidth_mhz: float = 0.2
@export var reward: int = 25
@export var lifetime_sec: float = 300.0
@export var state: int = 0 # 0 активен 1 расшифрован
