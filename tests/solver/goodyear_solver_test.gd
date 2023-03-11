@tool
extends EditorScript


# earth's
const MU := 3.986e5
# in seconds
const SIMULATION_DURATION := 1.0


func _run() -> void:
	var eci_state := EciState.new(
		Vector3(999.9998, 4999.998, 6999.998),
		Vector3(3.000001, 4, 5)
	)
	
	var result := Goodyear.solve(MU, SIMULATION_DURATION, eci_state)
	print(result)
