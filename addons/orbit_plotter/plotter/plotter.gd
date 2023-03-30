extends Node


const SamplingPlotter := preload("res://addons/orbit_plotter/modes/sampling/sampling_plotter.gd")


class OrbitPlotData:
	var remote_transform: RemoteTransform3D
	var plotter: SamplingPlotter
	var sphere_of_influence_mesh: SphereOfInfluenceMeshInstance3D


var _orbits := {}


## Plot Orbit for the given body in the given reference_frame.
## body should either be a Vessel or a CelestialBody.
func plot_orbit_for(body: Node3D, reference_frame: LocalCelestialBodySystem) -> void:
	var dominant_reference: LocalCelestialBodySystem = reference_frame if body is VesselBody else reference_frame.parent
	
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
	if not dominant_reference.host.get_children().find(plot_data.remote_transform):
		dominant_reference.host.add_child(plot_data.remote_transform)
	
	if plot_data.plotter == null:
		plot_data.plotter = SamplingPlotter.new()
		dominant_reference.host.add_child(plot_data.plotter)
		plot_data.plotter.global_position = dominant_reference.host.global_position
		plot_data.plotter.plot(
			dominant_reference.host.physical_fact_sheet.mass,
			dominant_reference.sphere_of_influence,
			dominant_reference.sphere_of_influence_squared,
			body.eci_state,
		)
	else:
		pass
	
	if body is CelestialBody:
		# Add SOI
		if plot_data.sphere_of_influence_mesh == null:
			plot_data.sphere_of_influence_mesh = SphereOfInfluenceMeshInstance3D.new()
			var remote_transform := RemoteTransform3D.new()
			remote_transform.update_rotation = false
			remote_transform.update_scale = false
			body.add_child(plot_data.sphere_of_influence_mesh)
			remote_transform.remote_path = plot_data.sphere_of_influence_mesh.get_path()
			body.add_child(remote_transform)
		
		plot_data.sphere_of_influence_mesh.radius = reference_frame.sphere_of_influence * 0.5
