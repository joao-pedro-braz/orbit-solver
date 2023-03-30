## Base class for all astronomical bodies in the simulation.
##
## CelestialBody represents a Celestial Body in the simulation.
## It can be a star, a planet, a mun or even an asteroid.
## It's main characteristic is being able to attract SatelliteBodys (and other CelestialBodys).
@tool
@icon("res://addons/orbit_solver/bodies/celestial/assets/icon.svg")
extends StaticBody3D
class_name CelestialBody


## Determines whether this body should affect others, but not be affected.
## Usually used for stars.
@export var is_static := false:
	set(value):
		is_static = value
		notify_property_list_changed()

## The Physical Fact Sheet for this body.
## Affects how it behaves in the simulation.
@export var physical_fact_sheet: CelestialBodyPhysicalFactSheet

## The Orbital Fact Sheet for this body.
## Used only if the body is not static.
## Also affects how it behaves in the simulation.
var orbital_fact_sheet: CelestialBodyOrbitalFactSheet

## The initial ECI State of the body, if it isn't static
var initial_eci_state: EciState

## The Current ECI State of the body, if it isn't static
var eci_state: EciState


## The local celestial body system relative to this body
var local_celestial_body_system: LocalCelestialBodySystem


func set_local_celestial_body_system(local_celestial_body_system: LocalCelestialBodySystem) -> void:
	self.local_celestial_body_system = local_celestial_body_system


func set_initial_eci_state(eci_state: EciState) -> void:
	if is_static:
		push_warning("Tried setting an initial ECI state for a static CelestialBody")
		return
	
	initial_eci_state = eci_state
	self.eci_state = eci_state


func _get_property_list() -> Array[Dictionary]:
	# By default, initial_eci_state` is not visible in the editor
	# Depends on whether the body is_static or not
	var property_usage = PROPERTY_USAGE_NO_EDITOR

	if not is_static:
		property_usage = PROPERTY_USAGE_DEFAULT

	var properties: Array[Dictionary] = []
	properties.append({
		"name": "orbital_fact_sheet",
		"type": TYPE_OBJECT,
		"usage": property_usage,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "CelestialBodyOrbitalFactSheet"
	})

	return properties
