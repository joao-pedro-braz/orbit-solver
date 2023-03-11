extends Node


const SamplingPlotter := preload("res://addons/orbit_plotter/modes/sampling/sampling_plotter.gd")


class OrbitPlotData:
	var remote_transform: RemoteTransform3D
	var plotter: SamplingPlotter


var _orbits := {}


## Plot Orbit for the given body in the given reference_frame.
## body should either be a Vessel or a CelestialBody.
func plot_orbit_for(body: Node3D, reference_frame: LocalCelestialBodySystem) -> void:
	var plot_data: OrbitPlotData
	if body in _orbits:
		# We're replotting
		plot_data = _orbits[body]
	else:
		plot_data = OrbitPlotData.new()
		_orbits[body] = plot_data
	
	if plot_data.remote_transform == null:
		plot_data.remote_transform = RemoteTransform3D.new()
		plot_data.remote_transform.update_rotation = false
		plot_data.remote_transform.update_scale = false
	
	plot_data.remote_transform.remote_path = body.get_path()
	# Might be a hot-spot
	if not reference_frame.host.get_children().find(plot_data.remote_transform):
		reference_frame.host.add_child(plot_data.remote_transform)
	
	var orbital_elements := OrbitalState.solve_to_keplerian_orbital_elements(
		reference_frame.host.physical_fact_sheet.mass * Planetarium.simulation_state.gravitational_constant,
		body.eci_state
	)
	
	if plot_data.plotter == null:
		plot_data.plotter = SamplingPlotter.new()
		reference_frame.host.add_child(plot_data.plotter)
		plot_data.plotter.global_position = reference_frame.host.global_position
		plot_data.plotter.plot(
			reference_frame.host.physical_fact_sheet.mass,
			reference_frame.sphere_of_influence,
			reference_frame.sphere_of_influence_squared,
			body.eci_state,
		)
	else:
		pass
