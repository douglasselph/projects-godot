extends Panel

@onready var octavesSlider = $Control/GridContainer/OctavesSlider
@onready var octavesValue = $Control/GridContainer/OctavesValue
@onready var periodSlider = $Control/GridContainer/PeriodSlider
@onready var periodValue = $Control/GridContainer/PeriodValue
@onready var persistenceSlider = $Control/GridContainer/PersistenceSlider
@onready var persistenceValue = $Control/GridContainer/PersistenceValue
@onready var lucanaritySlider = $Control/GridContainer/LucanaritySlider
@onready var lucanarityValue = $Control/GridContainer/LucanarityValue
@onready var amplitudeSlider = $Control/GridContainer/AmplitudeSlider
@onready var amplitudeValue = $Control/GridContainer/AmplitudeValue
@onready var exponentiationSlider = $Control/GridContainer/ExponentiationSlider
@onready var exponentiationValue = $Control/GridContainer/ExponentiationValue

var _timer: Timer = Timer.new()
const Timeout = 3

func _ready():
	_octaves_set(TerrainInfo.Octaves)
	_period_set(TerrainInfo.Period)
	_persistence_set(TerrainInfo.Persistence)
	_lucanarity_set(TerrainInfo.Lucanarity)
	_amplitude_set(TerrainInfo.Amplitude)
	_exponentiation_set(TerrainInfo.Exponentiation)
	
	octavesSlider.connect("value_changed",Callable(self,"_octaves_slider_value_changed"))
	periodSlider.connect("value_changed",Callable(self,"_period_slider_value_changed"))
	persistenceSlider.connect("value_changed",Callable(self,"_persistence_slider_value_changed"))
	lucanaritySlider.connect("value_changed",Callable(self,"_lucanarity_slider_value_changed"))
	amplitudeSlider.connect("value_changed",Callable(self,"_amplitude_slider_value_changed"))
	exponentiationSlider.connect("value_changed",Callable(self,"_exponentiation_slider_value_changed"))
	
	_timer.connect("timeout",Callable(self,"_timer_expired"))
	
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

var octaves: int = 4 :
	get:
		return octaves # TODOConverter40 Copy here content of _octaves_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _octaves_set
var period: float = 128 :
	get:
		return period # TODOConverter40 Copy here content of _period_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _period_set
var persistence: float = 0.5 :
	get:
		return persistence # TODOConverter40 Copy here content of _persistence_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _persistence_set
var lucanarity: float = 2.0 :
	get:
		return lucanarity # TODOConverter40 Copy here content of _lucanarity_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _lucanarity_set
var amplitude: float= 1.0 :
	get:
		return amplitude # TODOConverter40 Copy here content of _amplitude_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _amplitude_set
var exponentiation: float = 1.0 :
	get:
		return exponentiation # TODOConverter40 Copy here content of _exponentiation_get
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _exponentiation_set

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


