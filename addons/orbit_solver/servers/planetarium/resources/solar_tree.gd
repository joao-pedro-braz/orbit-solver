## A LocalCelestialBodySystem represents a solar system.
##
## It contains a host star and a list of bodies (which can have other bodies and so on)
extends RefCounted
class_name LocalCelestialBodySystem


## Emitted very time the host of this celestial system updates.
## previous_position is assumed to be in global space.
signal host_updated(previous_position: Vector3)


var host: CelestialBody
var children: Array[LocalCelestialBodySystem] = []
var parent: LocalCelestialBodySystem = null

## Computed properties of the host -> parent relationship
##
## The Hill Sphere of this body in relation to it's parent (if applicable)
var hill_sphere: float
var hill_sphere_squared: float

## The SOI of the host in relation to it's parent
var sphere_of_influence: float
var sphere_of_influence_squared: float


func is_empty() -> bool:
	return size() == 0


func size() -> int:
	return 1 + children.reduce(
		func(acc, child):
			return child.size() + acc,
		0
	)


func append(child: CelestialBody) -> void:
	var child_tree := LocalCelestialBodySystem.new()
	child_tree.host = child
	child_tree.parent = self
	self.children.append(child_tree)


func find(host: CelestialBody) -> LocalCelestialBodySystem:
	if self.host == host:
		return self
	
	for child in children:
		var result := child.find(host)
		if result != null:
			break
	
	return null


func on_celestial_system_host_updated(eci_state: EciState) -> void:
	var previous_position := host.global_position
	host.global_position = parent.host.to_global(eci_state.position)
	host.eci_state = eci_state
	emit_signal("host_updated", previous_position)
