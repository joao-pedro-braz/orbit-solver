class_name HillSphere


# Compute the hill sphere for parent -> child system.
# Assumes that the parent is more massive than the child.
static func solve(
	parent: CelestialBody,
	child: CelestialBody
) -> float:
	return child.orbital_fact_sheet.orbital_elements.semi_major_axis \
		* (1.0 - child.orbital_fact_sheet.orbital_elements.eccentricity) * pow(
			child.physical_fact_sheet.mass / (3.0 * parent.physical_fact_sheet.mass),
			1.0 / 3.0
		)
