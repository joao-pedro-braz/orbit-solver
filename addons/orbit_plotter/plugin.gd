@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("OrbitPlotter", "res://addons/orbit_plotter/plotter/plotter.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("OrbitPlotter")
