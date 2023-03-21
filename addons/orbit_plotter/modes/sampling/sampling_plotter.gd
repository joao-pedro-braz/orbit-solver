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
	host_mass: float,
	sphere_of_influence: float,
	sphere_of_influence_squared: float,
	eci_state: EciState,
) -> void:
	if _line == null:
		_line = LineRenderer.new()
		_line.visible = false
		add_child(_line)
	
	OrbitalPathSolver.done.connect(
		func(curve: Curve3D):
			print(curve.point_count)
			_line.visible = true
			_line.curve = curve,
		CONNECT_ONE_SHOT
	)
	
	OrbitalPathSolver.solve(
		host_mass,
		sphere_of_influence,
		sphere_of_influence_squared,
		eci_state,
		SAMPLING_PLOTTER_RESOLUTION
	)
	
	_set_color_and_width()


func _set_color_and_width() -> void:
	return
	var mesh: PrimitiveMesh = _line.multimesh.mesh
	mesh.radius = width / 2.0
	_line.set_instance_shader_parameter("size", width)
	_line.set_instance_shader_parameter("albedo", color)
