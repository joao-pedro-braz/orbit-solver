## Contains state pertinante to the simulation.
extends RefCounted
class_name SimulationState


signal gravitational_constant_changed(old_gravitational_constant: float, gravitational_constant: float)
signal time_scale_changed(old_time_scale: float, time_scale: float)
signal now_changed(old_now: float, now: float)
signal state_changed(property: String, old_value, value)


## Measured in m³/kg.s²
## The constant gravitational value.
var gravitational_constant := 6.674e-11:
	set(value):
		_emit_changed_signal(
			"gravitational_constant",
			gravitational_constant,
			value
		)
		gravitational_constant = value

## Dimensionless.
## Affects how fast the simulation will run.
var time_scale := 1.0:
	set(value):
		_emit_changed_signal(
			"time_scale",
			time_scale,
			value
		)
		time_scale = value


## Measured in seconds.
## Represents the current time value for the simulation.
var now := 0.0


func _emit_changed_signal(
	property: String,
	previous_value,
	value
) -> void:
	call_deferred(
		"emit_signal",
		property + "_changed",
		previous_value,
		value
	)
	call_deferred(
		"emit_signal",
		"state_changed",
		property,
		previous_value,
		value
	)
