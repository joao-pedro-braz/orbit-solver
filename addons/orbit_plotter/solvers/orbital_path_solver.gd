extends ThreadPool


const MAX_ITERATIONS := 1e5
const JUMP_SIZE_THRESHOLD := 1e-2


class DoneSignal:
	signal done(curve: PackedVector3Array, is_closed_orbit: bool)


class SimulationData:
	var host_radius_squared: float
	var host_mass: float
	var sphere_of_influence: float
	var sphere_of_influence_squared: float
	var orbiting_eci_state: EciState
	var resolution: float
	var gravitational_constant: float
	var done_signal: DoneSignal
	
	func _init(
		host_radius_squared: float,
		host_mass: float,
		sphere_of_influence: float,
		sphere_of_influence_squared: float,
		orbiting_eci_state: EciState,
		resolution: float,
		gravitational_constant: float,
		done_signal: DoneSignal
	) -> void:
		self.host_radius_squared = host_radius_squared
		self.host_mass = host_mass
		self.sphere_of_influence = sphere_of_influence
		self.sphere_of_influence_squared = sphere_of_influence_squared
		self.orbiting_eci_state = orbiting_eci_state
		self.resolution = resolution
		self.gravitational_constant = gravitational_constant
		self.done_signal = done_signal


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
	host_radius_squared: float,
	host_mass: float,
	sphere_of_influence: float,
	sphere_of_influence_squared: float,
	orbiting_eci_state: EciState,
	resolution: int) -> DoneSignal:
	var done_signal := DoneSignal.new()
	_execute_work(
		[
			SimulationData.new(
				host_radius_squared,
				host_mass,
				sphere_of_influence,
				sphere_of_influence_squared,
				orbiting_eci_state,
				resolution,
				Planetarium.simulation_state.gravitational_constant,
				done_signal
			),
		],
		_do_work,
		1
	)
	return done_signal

func _do_work(data: Array, unit: ThreadPool.ThreadPoolUnit) -> void:
	var simulation_data: SimulationData = data[0]
	
	var host_radius_squared: float = simulation_data.host_radius_squared
	var host_mass: float = simulation_data.host_mass
	var sphere_of_influence: float = simulation_data.sphere_of_influence
	var sphere_of_influence_squared: float = simulation_data.sphere_of_influence_squared
	var orbiting_eci_state: EciState = simulation_data.orbiting_eci_state
	var resolution: int = simulation_data.resolution
	var gravitational_constant: float = simulation_data.gravitational_constant
	var done_signal: DoneSignal = simulation_data.done_signal
	
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
	
	var offset := 0.0
	var first_guess := _solve(
		host_mass,
		gravitational_constant,
		offset,
		orbiting_eci_state,
		orbital_elements,
	)
	var result := PackedVector3Array([first_guess.position])
	var instruction: Instruction = Instruction.new(
		resolution,
		first_guess
	)
	var iterations := 0
	var is_closed_orbit = true
	while iterations < MAX_ITERATIONS:
		iterations += 1
		
		var timestamp = offset + instruction.jump_size
		var eci_state := _solve(
			host_mass,
			gravitational_constant,
			timestamp,
			orbiting_eci_state,
			orbital_elements,
		)
		
		var distance_squared := eci_state.position.length_squared()
		if distance_squared > sphere_of_influence_squared:
			is_closed_orbit = false
			break
		elif distance_squared <= host_radius_squared:
			if host_radius_squared - distance_squared > resolution:
				# We're going through the host, let's back-track a little to get as close as possible (for accuracy)
				instruction = Instruction.new(instruction.jump_size * 0.5, instruction.eci_state)
				continue
			else:
				is_closed_orbit = false
				break
		
		if eci_state.position.distance_to(first_guess.position) <= resolution * 1.1 \
			and eci_state.position.direction_to(first_guess.position).dot(first_guess.velocity) >= 0:
			# We're getting close to closing the orbit, override the instruction's target
			result.append(first_guess.position)
			result.append(eci_state.position)
			break
		
		var distance = eci_state.position.distance_to(instruction.eci_state.position)
		if distance > resolution and instruction.jump_size > JUMP_SIZE_THRESHOLD:
			# Still have work to do
			instruction = Instruction.new(instruction.jump_size * 0.5, instruction.eci_state)
		else:
			# Good enough
			result.append(eci_state.position)
			offset += instruction.jump_size
			# Process next instruction
			instruction = Instruction.new(instruction.jump_size * 2.0, eci_state)
	
	done_signal.done.emit(result, is_closed_orbit)
	if unit != null:
		unit.idle = true


func _solve(
	host_mass: float,
	gravitational_constant: float,
	timestamp: float,
	orbiting_eci_state: EciState,
	orbital_elements: KeplerianOrbitalElements
) -> EciState:
	if orbital_elements.eccentricity >= 1.0:
		return Danby.solve(
			host_mass * gravitational_constant,
			timestamp + orbiting_eci_state.time,
			orbiting_eci_state
		)
	else:
		return DanbyStumpff.solve(
			host_mass * gravitational_constant,
			timestamp + orbiting_eci_state.time,
			orbiting_eci_state
		)
