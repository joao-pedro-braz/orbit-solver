class_name OrbitalPeriod


# Compute the hill sphere for parent -> child system.
# Assumes that the parent is more massive than the child.
static func solve(
	host_mass: float,
	orbital_elements: KeplerianOrbitalElements
) -> float:
	var semi_major_axis := orbital_elements.semi_major_axis ** 3
	return TAU * sqrt(
		semi_major_axis \
			/ (Planetarium.simulation_state.gravitational_constant \
			* host_mass)
	)
