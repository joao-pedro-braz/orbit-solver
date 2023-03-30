class_name SphereOfInfluence


## Compute the SOI for parent -> child system.
## Assumes that the parent is more massive than the child.
static func solve(
	parent: CelestialBody,
	child: CelestialBody
) -> float:
	return child.orbital_fact_sheet.orbital_elements.semi_major_axis \
		* (child.physical_fact_sheet.mass / parent.physical_fact_sheet.mass) \
		** (2.0 / 5.0)
