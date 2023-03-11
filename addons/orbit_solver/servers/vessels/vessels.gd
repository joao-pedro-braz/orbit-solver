extends Node


const ID := "Vessels"


signal entered_new_system(vessel: VesselBody, eci_state: EciState, system: LocalCelestialBodySystem)


var _vessels := {}
var _active_vessel: VesselBody


func _ready() -> void:
	# The Planetarium Server should be processed before the Vessels Server
	process_priority = ProcessPriority.VESSELS_SERVER
	
	set_physics_process(false)
	set_process(false)


func _physics_process(delta: float) -> void:
	if _vessels.is_empty():
		return
	
	_run_simulation()
	_update_vessels_metadata()


## Starts the simulation.
## Should be called after all vessels have been added.
func init() -> void:
	_update_vessels_metadata(true)
	
	set_physics_process(true)
	set_process(true)


## Adds a vessel to the simulation
func add_vessel(vessel: VesselBody) -> void:
	if vessel == null:
		printerr("Vessel not found!")
		return
	
	_vessels[vessel] = VesselMetadata.new()
	_update_vessel_metadata(vessel, true)


## Makes the given vessel the active one
func activate_vessel(vessel: VesselBody) -> void:
	_active_vessel = vessel


## Deactivates the current vessel
func deactivate_current_vessel() -> void:
	_active_vessel = null


## Remove the given vessel from the simulation
func remove_vessel(vessel: VesselBody) -> void:
	if vessel == _active_vessel:
		printerr("Can not remove active vessel!")
		return
	
	_vessels.erase(vessel)
	vessel.on_vessel_removed()


func _run_simulation() -> void:
	var work_to_be_done: Array[TwoBodySimulationSolver.SimulationData] = []
	var vessels := _vessels.keys()
	vessels.reverse()
	for vessel in vessels:
		if vessel.is_queued_for_deletion():
			_vessels.erase(vessel)
			continue
		
		var metadata: VesselMetadata = _vessels[vessel]
		var system: LocalCelestialBodySystem = metadata.influent_system
		
		work_to_be_done.append(
			TwoBodySimulationSolver.SimulationData.new(
				vessel,
				system.host.physical_fact_sheet.mass,
				vessel.initial_eci_state.position,
				vessel.initial_eci_state.velocity,
				vessel.initial_eci_state.time,
				Planetarium.simulation_state.gravitational_constant,
				Planetarium.simulation_state.now
			)
		)
	
	var results: Array[TwoBodySimulationSolver.SimulationResult] = await TwoBodySimulationSolver.solve(work_to_be_done)
	
	for result in results:
		result.identifier.on_vessel_updated(
			result.eci_state,
			_active_vessel == result.identifier
		)


## Updates the metadata for every vessel
func _update_vessels_metadata(force_update := false) -> void:
	var vessels := _vessels.keys()
	vessels.reverse()
	for vessel in vessels:
		_update_vessel_metadata(vessel, force_update)


## Updates the metadata for the given vessel
func _update_vessel_metadata(vessel: VesselBody, force_update := false) -> void:
	if vessel.is_queued_for_deletion():
		_vessels.erase(vessel)
		return
	
	var influent := Planetarium.find_system_influent_over(vessel.global_position)
	# Only update the influent_system if it actually changed
	if influent != _vessels[vessel].influent_system:
		_vessels[vessel].influent_system = influent
		
		# When entering a influent_system, we need to adjust our state
		# so it's aligned with the host's reference frame.
		var eci_state: EciState
		if vessel.eci_state != null:
			var time := vessel.eci_state.time
			eci_state = EciState.new(
				influent.host.to_local(vessel.eci_state.position),
				vessel.eci_state.velocity
			)
			eci_state.time = time
		else:
			var time := vessel.eci_state.time if vessel.eci_state != null else 0
			eci_state = EciState.new(
				influent.host.to_local(vessel.global_position),
				vessel.linear_velocity
			)
			eci_state.time = 0
		
		if force_update:
			vessel.on_entered_new_system(eci_state, influent)
		else:
			vessel.call_deferred("on_entered_new_system", eci_state, influent)
