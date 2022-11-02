extends Panel

onready var octavesSlider = $Control/GridContainer/OctavesSlider
onready var octavesValue = $Control/GridContainer/OctavesValue
onready var periodSlider = $Control/GridContainer/PeriodSlider
onready var periodValue = $Control/GridContainer/PeriodValue
onready var persistenceSlider = $Control/GridContainer/PersistenceSlider
onready var persistenceValue = $Control/GridContainer/PersistenceValue
onready var lucanaritySlider = $Control/GridContainer/LucanaritySlider
onready var lucanarityValue = $Control/GridContainer/LucanarityValue
onready var amplitudeSlider = $Control/GridContainer/AmplitudeSlider
onready var amplitudeValue = $Control/GridContainer/AmplitudeValue
onready var exponentiationSlider = $Control/GridContainer/ExponentiationSlider
onready var exponentiationValue = $Control/GridContainer/ExponentiationValue

var _timer: Timer = Timer.new()
const Timeout = 3

func _ready():
	_octaves_set(TerrainInfo.Octaves)
	_period_set(TerrainInfo.Period)
	_persistence_set(TerrainInfo.Persistence)
	_lucanarity_set(TerrainInfo.Lucanarity)
	_amplitude_set(TerrainInfo.Amplitude)
	_exponentiation_set(TerrainInfo.Exponentiation)
	
	octavesSlider.connect("value_changed", self, "_octaves_slider_value_changed")
	periodSlider.connect("value_changed", self, "_period_slider_value_changed")
	persistenceSlider.connect("value_changed", self, "_persistence_slider_value_changed")
	lucanaritySlider.connect("value_changed", self, "_lucanarity_slider_value_changed")
	amplitudeSlider.connect("value_changed", self, "_amplitude_slider_value_changed")
	exponentiationSlider.connect("value_changed", self, "_exponentiation_slider_value_changed")
	
	_timer.connect("timeout", self, "_timer_expired")
	
	add_child(_timer)
		
func _octaves_slider_value_changed(value: float):
	octavesValue.text = value as String
	_resetTimer()
	
func _period_slider_value_changed(value: float):
	periodValue.text = value as String
	_resetTimer()
	
func _persistence_slider_value_changed(value: float):
	persistenceValue.text = value as String
	_resetTimer()
	
func _lucanarity_slider_value_changed(value: float):
	lucanarityValue.text = value as String
	_resetTimer()
	
func _amplitude_slider_value_changed(value: float):
	amplitudeValue.text = value as String
	_resetTimer()

func _exponentiation_slider_value_changed(value: float):
	exponentiationValue.text = value as String	
	_resetTimer()

var octaves: int = 4 setget _octaves_set, _octaves_get
var period: float = 128 setget _period_set, _period_get
var persistence: float = 0.5 setget _persistence_set, _persistence_get
var lucanarity: float = 2.0 setget _lucanarity_set, _lucanarity_get
var amplitude: float= 1.0 setget _amplitude_set, _amplitude_get
var exponentiation: float = 1.0 setget _exponentiation_set, _exponentiation_get

func _octaves_get() -> int:
	return octavesValue.text as int

func _octaves_set(value: int):
	octavesValue.text = value as String
	octavesSlider.value = value

func _period_get() -> float:
	return periodValue.text as float

func _period_set(value: float):
	periodValue.text = value as String
	periodSlider.value = value
	
func _persistence_get() -> float:
	return persistenceValue.text as float
	
func _persistence_set(value: float):
	persistenceValue.text = value as String
	persistenceSlider.value = value
		
func _lucanarity_get() -> float:
	return lucanarityValue.text as float
	
func _lucanarity_set(value: float):
	lucanarityValue.text = value as String
	lucanaritySlider.value = value
	
func _amplitude_get() -> float:
	return amplitudeValue.text as float

func _amplitude_set(value: float):
	amplitudeValue.text = value as String
	amplitudeSlider.value = value
	
func _exponentiation_get() -> float:
	return exponentiationValue.text as float

func _exponentiation_set(value: float):
	exponentiationValue.text = value as String
	exponentiationSlider.value = value
	
func _resetTimer():
	_timer.stop()
	_timer.start(Timeout)
	
func _timer_expired():
	_timer.stop()
	TerrainInfo.Octaves = _octaves_get()
	TerrainInfo.Period = _period_get()
	TerrainInfo.Persistence = _persistence_get()
	TerrainInfo.Lucanarity = _lucanarity_get()
	TerrainInfo.Amplitude = _amplitude_get()
	TerrainInfo.Exponentiation = _exponentiation_get()
	TerrainInfo.emit_values_changed()


