@tool
extends EditorScript



func _run() -> void:
	var parent := CelestialBody.new()
	parent.mass = 1.99e30
	var child := CelestialBody.new()
	child.mass = 5.97e24
	
	var orbital_elements := KeplerianOrbitalElements.new()
	orbital_elements.semi_major_axis = 1.49597887e8
	orbital_elements.semilatus_rectum = 1.49597887e4
	orbital_elements.eccentricity = 0.01671022
	orbital_elements.inclination = 8.72665e-07
	orbital_elements.periapse_longitude = 1.79677
	orbital_elements.periapsis_argument = 1.9933027
	
	child.eci_state = OrbitalState.solve_to_eci_state(
		parent.mass * OrbitServer.gravitation_constant,
		orbital_elements
	)

	var radius := HillSphere.solve(parent, child)
	print(radius)
