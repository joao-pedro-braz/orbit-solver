@tool
extends EditorScript

var tests := [
	preload("res://tests/solver/goodyear_solver_test.gd").new(),
]

func _run() -> void:
	print(Vector3(411.086466494319, 503.563945523853, -133.28780190823).length())
	
	for test in tests:
		test._run()
