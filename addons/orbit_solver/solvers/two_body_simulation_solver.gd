extends ThreadPool


class SimulationData:
	var identifier
	var host_mass: float
	var position: Vector3
	var velocity: Vector3
	var relative_time: float
	var gravitational_constant: float
	var now: float
	
	func _init(
		identifier,
		host_mass: float,
		position: Vector3,
		velocity: Vector3,
		relative_time: float,
		gravitational_constant: float,
		now: float,
	) -> void:
		self.identifier = identifier
		self.host_mass = host_mass
		self.position = position
		self.velocity = velocity
		self.relative_time = relative_time
		self.gravitational_constant = gravitational_constant
		self.now = now


class SimulationResult:
	var identifier
	var eci_state: EciState
	
	func _init(identifier, eci_state: EciState) -> void:
		self.identifier = identifier
		self.eci_state = eci_state


## Solving order *is* garanteed, but only because we block until all threads have finished their execution.
## Reducer can be used to change the output (from the defaul Array[SimulationResult]).
func solve(
	simulation_data: Array[SimulationData],
	force_immediate_execution = false
) -> Array[SimulationResult]:
	# Slight optimization, if we can do everything in a single thread, do it now!
	if simulation_data.size() < _work_per_thread:
		force_immediate_execution = true
	
	if THREADED and not force_immediate_execution:
		var waiting_threads: Array[ThreadPoolUnit] = _execute_work(simulation_data, _do_work)
		var results: Array[SimulationResult] = []
		for unit in waiting_threads:
			var result := unit.wait_to_finish()
			unit.idle = true
			if result is Array:
				results.append_array(result)
			else:
				results.append(result)

		return results
	else:
		return _do_work(simulation_data, null)


func _do_work(work: Array[SimulationData], _unit: ThreadPool.ThreadPoolUnit) -> Array[SimulationResult]:
	var result: Array[SimulationResult] = []
	for data in work:
		var eci_state := DanbyStumpff.solve(
			data.host_mass * data.gravitational_constant,
			data.now - data.relative_time,
			EciState.new(
				data.position,
				data.velocity
			)
		)
		result.append(SimulationResult.new(data.identifier, eci_state))
	
	return result
