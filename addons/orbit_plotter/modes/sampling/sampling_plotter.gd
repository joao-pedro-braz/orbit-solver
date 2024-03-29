extends Node3D


# Size in kilometers of each segment
const SAMPLING_PLOTTER_RESOLUTION := 5.0
const LineRenderer := preload("res://addons/orbit_plotter/modes/sampling/line_renderer/line_renderer.gd")

@export_category("Rendering")
@export var color: Color = Color.DARK_SLATE_GRAY:
	set(value):
		color = value
		if _line:
			_set_color_and_width()

@export var width: float = 0.05:
	set(value):
		width = value
		if _line:
			_set_color_and_width()


var _line: LineRenderer


func plot(
	host_radius_squared: float,
	host_mass: float,
	sphere_of_influence: float,
	sphere_of_influence_squared: float,
	eci_state: EciState,
) -> void:
	if _line == null:
		_line = LineRenderer.new()
		_line.visible = false
		add_child(_line)
	
	OrbitalPathSolver.solve(
		host_radius_squared,
		host_mass,
		sphere_of_influence,
		sphere_of_influence_squared,
		eci_state,
		SAMPLING_PLOTTER_RESOLUTION
	).done.connect(_set_curve, CONNECT_ONE_SHOT)
	
	_set_color_and_width()


func _set_color_and_width() -> void:
	return
	var mesh: PrimitiveMesh = _line.multimesh.mesh
	mesh.radius = width / 2.0
	_line.set_instance_shader_parameter("size", width)
	_line.set_instance_shader_parameter("albedo", color)


func _set_curve(result: PackedVector3Array, is_closed_orbit: bool) -> void:
	_line.visible = true
	_line.curve = result
	_line.is_closed = is_closed_orbit
