extends ThreadPool


const MAX_ITERATIONS := 1e8


signal done(curve: Curve3D)


class SimulationData:
	var host_mass: float
	var sphere_of_influence: float
	var sphere_of_influence_squared: float
	var orbiting_eci_state: EciState
	var resolution: float
	var gravitational_constant: float
	
	func _init(
		host_mass: float,
		sphere_of_influence: float,
		sphere_of_influence_squared: float,
		orbiting_eci_state: EciState,
		resolution: float,
		gravitational_constant: float,
	) -> void:
		self.host_mass = host_mass
		self.sphere_of_influence = sphere_of_influence
		self.sphere_of_influence_squared = sphere_of_influence_squared
		self.orbiting_eci_state = orbiting_eci_state
		self.resolution = resolution
		self.gravitational_constant = gravitational_constant


class Instruction:
	var jump_size: float
	var eci_state: EciState
	
	func _init(
		jump_size: float,
		eci_state: EciState,
	) -> void:
		self.jump_size = jump_size
		self.eci_state = eci_state


func solve(
	host_mass: float,
	sphere_of_influence: float,
	sphere_of_influence_squared: float,
	orbiting_eci_state: EciState,
	resolution: int) -> Curve3D:
	var waiting_threads: Array[ThreadPoolUnit] = _execute_work(
		[
			SimulationData.new(
				host_mass,
				sphere_of_influence,
				sphere_of_influence_squared,
				orbiting_eci_state,
				resolution,
				Planetarium.simulation_state.gravitational_constant,
			),
		],
		_do_work,
		1
	)
	var result: Curve3D
	for unit in waiting_threads:
		result = unit.wait_to_finish()
		unit.idle = true
	
	return result

func _do_work(data: Array) -> Curve3D:
	var simulation_data: SimulationData = data[0]
	
	var host_mass: float = simulation_data.host_mass
	var sphere_of_influence: float = simulation_data.sphere_of_influence
	var sphere_of_influence_squared: float = simulation_data.sphere_of_influence_squared
	var orbiting_eci_state: EciState = simulation_data.orbiting_eci_state
	var resolution: int = simulation_data.resolution
	var gravitational_constant: float = simulation_data.gravitational_constant
	
	var orbital_elements := OrbitalState.solve_for_keplerian_orbital_elements(
		host_mass * gravitational_constant,
		orbiting_eci_state
	)
	
	if not is_zero_approx(orbiting_eci_state.time):
		# We need to normalize the ECI State
		orbiting_eci_state = OrbitalState.solve_for_eci_state(
			host_mass * gravitational_constant,
			orbital_elements
		)
	
	
	var period: float
	if orbital_elements.eccentricity >= 1.0:
		print("opie")
		period = 2.0 * sphere_of_influence / orbiting_eci_state.velocity.length()
	else:
		period = OrbitalPeriod.solve(host_mass, orbital_elements)
	print(period)
	var first := true
	var samplings := ceili(period)
	var offset := -samplings / 2.0
	var result: Array[EciState] = [
		# first guess
		DanbyStumpff.solve(
			host_mass * gravitational_constant,
			offset + orbiting_eci_state.time,
			EciState.new(
				orbiting_eci_state.position,
				orbiting_eci_state.velocity
			)
		),
	]
	var instructions: Array[Instruction] = [
		Instruction.new(
			period / samplings,
			result[-1]
		)
	]
	var iterations := 0
	while offset <= samplings and iterations < MAX_ITERATIONS:
		iterations += 1
		var instruction: Instruction = instructions.pop_front()
		
		var timestamp = offset + instruction.jump_size
		var eci_state := DanbyStumpff.solve(
			host_mass * gravitational_constant,
			timestamp + orbiting_eci_state.time,
			EciState.new(
				orbiting_eci_state.position,
				orbiting_eci_state.velocity
			)
		)
		
		if eci_state.position.length_squared() > sphere_of_influence_squared:
			# Outside of the sphere of influence, don't bother
			offset += instruction.jump_size
			instructions.push_front(Instruction.new(instruction.jump_size * 2.0, eci_state))
			continue
		
		var distance = eci_state.position.distance_to(instruction.eci_state.position)
		if distance > resolution:
			# Still have work to do
			var new_jump_size := instruction.jump_size / 2.0
			instructions.push_front(Instruction.new(new_jump_size, instruction.eci_state))
		else:
			# Good enough
			result.append(eci_state)
			offset += instruction.jump_size
			
			# Process next instruction
			instructions.push_front(Instruction.new(instruction.jump_size * 2.0, eci_state))
	
	var curve_3d := Curve3D.new()
	for eci_state in result:
		curve_3d.add_point(eci_state.position)
	
	# So we force baking
	curve_3d.get_baked_points()
	emit_signal("done", curve_3d)
	return curve_3d


func _sub_steps() -> void:
	pass
