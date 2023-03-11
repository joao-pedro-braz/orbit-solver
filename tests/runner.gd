@tool
extends EditorScript

var tests := [
	preload("res://tests/solver/goodyear_solver_test.gd").new(),
]

func _run() -> void:
	for test in tests:
		test._run()
