@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("TwoBodySimulationSolver", "res://addons/orbit_solver/solvers/two_body_simulation_solver.gd")
	add_autoload_singleton("OrbitalPathSolver", "res://addons/orbit_solver/solvers/orbital_path_solver.gd")
	add_autoload_singleton("Planetarium", "res://addons/orbit_solver/servers/planetarium/planetarium.gd")
	add_autoload_singleton("Vessels", "res://addons/orbit_solver/servers/vessels/vessels.gd")
	add_autoload_singleton("DebugTool", "res://addons/orbit_solver/utils/debug_tool.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("TwoBodySimulationSolver")
	remove_autoload_singleton("OrbitalPathSolver")
	remove_autoload_singleton("Planetarium")
	remove_autoload_singleton("Vessels")
	remove_autoload_singleton("DebugTool")
