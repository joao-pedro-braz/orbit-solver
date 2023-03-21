## The Planetarium.
##
## For now it assumes that a only a single solar system exists,
## but that might change in the future.
extends Node


const ID := "Planetarium"


## The current simulation state.
var simulation_state := SimulationState.new()
var solar_system := LocalCelestialBodySystem.new()


func _ready() -> void:
	# The Planetarium Server should be processed before the Vessels Server
	process_priority = ProcessPriority.PLANETARIUM_SERVER
	set_physics_process(false)
	set_process(false)


func _physics_process(delta: float) -> void:
	if solar_system.is_empty():
		return
	
	simulation_state.now = now(delta)
	_run_simulation()


## Starts the simulation.
## Should be called after all celestial bodies have been added.
func init() -> void:
	if solar_system.size() < 2:
		printerr("Can not update a solar system with less than 2 bodies")
		return
	
	_update_solar_system_initial_state(solar_system)
	set_physics_process(true)
	set_process(true)


## Makes the planeterium aware of a given body.
## If host is provided, will add the body as a child of it.
func add_celestial_body(body: CelestialBody, host: CelestialBody = null) -> void:
	if host != null:
		if solar_system.host == null:
			printerr("Failed to add Celestial Body, host doesn't exist")
			return
		
		var host_system := solar_system.find(host)
		if host_system == null:
			printerr("Failed to find the Host in the Solar System Tree")
			return
		elif body.is_static:
			printerr("A static Celestial Body cannot be a child of another Celestial Body")
			return
		elif body.physical_fact_sheet == null:
			printerr("Celestial Body is missing a Physical Facts Sheet")
			return
		elif body.orbital_fact_sheet == null:
			printerr("Celestial Body is missing an Orbital Facts Sheet")
			return
		
		host_system.append(body)
	elif solar_system.host != null:
		printerr("Solar System already has a host!")
		return
	elif body.physical_fact_sheet == null:
		printerr("Static Celestial Body is missing a Physical Facts Sheet")
		return
	else:
		solar_system.host = body
		# For now, at least, The Host the main Solar System has infinite influence
		solar_system.hill_sphere = INF
		solar_system.hill_sphere_squared = INF
		solar_system.sphere_of_influence = INF
		solar_system.sphere_of_influence_squared = INF
 

## Calculate the current simulation time
func now(delta: float) -> float:
	return simulation_state.now + simulation_state.time_scale * delta


## Find the body whose SOI is within the given position.
## Position assumed to be in global space.
func find_system_influent_over(position: Vector3) -> LocalCelestialBodySystem:
	var systems: Array[LocalCelestialBodySystem] = solar_system.children
	var children: Array[LocalCelestialBodySystem] = [null]
	
	var influent_system := solar_system
	while not children.is_empty():
		children = []
		
		for system in systems:
			if system.host.global_position.distance_squared_to(position) < system.sphere_of_influence_squared:
				influent_system = system
				children.append_array(system.children)
		
		systems = children
	
	return influent_system


## Updates the initial ECI state for every applicable body
func _update_solar_system_initial_state(solar_tree: LocalCelestialBodySystem) -> void:
	var host: CelestialBody = solar_tree.host
	for child_system in solar_tree.children:
		var child: CelestialBody = child_system.host
		
		var eci_state := OrbitalState.solve_for_eci_state(
			host.physical_fact_sheet.mass * simulation_state.gravitational_constant,
			child.orbital_fact_sheet.orbital_elements
		)
		eci_state.time = simulation_state.now
		child.set_initial_eci_state(eci_state)
		child_system.hill_sphere = HillSphere.solve(host, child)
		child_system.hill_sphere_squared = child_system.hill_sphere ** 2.0
		child_system.sphere_of_influence = SphereOfInfluence.solve(host, child)
		child_system.sphere_of_influence_squared = child_system.sphere_of_influence ** 2.0
		_update_solar_system_initial_state(child_system)


func _run_simulation() -> void:
	var systems: Array[LocalCelestialBodySystem] = solar_system.children
	var children: Array[LocalCelestialBodySystem] = [null]
	
	var influent_system := solar_system
	var work_to_be_done: Array[TwoBodySimulationSolver.SimulationData] = []
	while not children.is_empty():
		children = []
		
		for system in systems:
			work_to_be_done.append(
				TwoBodySimulationSolver.SimulationData.new(
					system,
					system.parent.host.physical_fact_sheet.mass,
					system.host.initial_eci_state.position,
					system.host.initial_eci_state.velocity,
					system.host.initial_eci_state.time,
					simulation_state.gravitational_constant,
					simulation_state.now
				)
			)
			children.append_array(system.children)
		
		systems = children
	
	# The planetarium must be solved first, before the Vessels
	# to ensure that, we mark it to be solved on the main Thread,
	# synchronously.
	var results: Array[TwoBodySimulationSolver.SimulationResult] = await TwoBodySimulationSolver.solve(work_to_be_done, true)
	for result in results:
		var system: LocalCelestialBodySystem = result.identifier
		var eci_state: EciState = result.eci_state
		system.on_celestial_system_host_updated(eci_state)
