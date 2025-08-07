extends Node
class_name TimeSystem

signal time_changed(current_time: float)
signal day_changed(day: int)

@export var day_length: float = 120.0  # 2 minutes per day
@export var start_time: float = 6.0  # Start at 6 AM

var current_time: float = 0.0
var current_day: int = 1
var time_scale: float = 1.0

func _ready():
	current_time = start_time
	set_process(true)

func _process(delta):
	current_time += (delta * time_scale * 24.0) / day_length
	
	if current_time >= 24.0:
		current_time -= 24.0
		current_day += 1
		day_changed.emit(current_day)
	
	time_changed.emit(current_time)

func get_time_of_day() -> String:
	var hour = int(current_time)
	var minute = int((current_time - hour) * 60)
	return "%02d:%02d" % [hour, minute]

func is_day_time() -> bool:
	return current_time >= 6.0 and current_time < 18.0

func is_night_time() -> bool:
	return not is_day_time()
