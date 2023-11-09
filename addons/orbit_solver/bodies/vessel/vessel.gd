## Base class for all crafts in the simulation.
##
## A Vessel is a type of RigidBody3D which can be controlled by the Vessels Server.
## It talks which the Vessels Server through Requests.
@tool
@icon("res://addons/orbit_solver/bodies/vessel/assets/icon.png")
extends RigidBody3D
class_name VesselBody


enum DriverMode {
	ORBITAL_ON_RAILS,
	ORBITAL_OFF_RAILS,
	UNDER_ACCELERATION
}

enum HookLifetime {
	START,
	END
}

# Hooks for other parts of the system to interact with this vessel
signal entered_new_system_hook(lifetime: HookLifetime)
signal vessel_apply_central_force_hook(force: Vector3, lifetime: HookLifetime)
signal vessel_apply_central_impulse_hook(impulse: Vector3, lifetime: HookLifetime)
signal vessel_apply_force_hook(force: Vector3, my_position: Vector3, lifetime: HookLifetime)
signal vessel_apply_impulse_hook(force: Vector3, my_position: Vector3, lifetime: HookLifetime)
signal vessel_apply_torque_hook(torque: Vector3, lifetime: HookLifetime)
signal vessel_apply_torque_impulse_hook(impulse: Vector3, lifetime: HookLifetime)


## The current ECI state of the craft.
var eci_state: EciState

## The reference for simulation runs
var initial_eci_state: EciState

## The current host of this craft
var current_system_tree: LocalCelestialBodySystem

## The current mode of the vessel
var mode: DriverMode = DriverMode.ORBITAL_ON_RAILS


func _ready() -> void:
	custom_integrator = false
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 100
	continuous_cd = true
	freeze = false

	if not Engine.is_editor_hint():
		Planetarium.simulation_state.time_scale_changed.connect(_on_time_scale_changed)
		body_entered.connect(_on_body_entered)


## Plans:
## When in ORBIT MODE:
##   - On rails (set position manually) when idle (no forces being applied, such as accel or rotation)
##   - Switch off rails on collision, let the collision happen, calculate remaining velocity, reset initial state from there
##   - Switch off rails on accel, calculate resulting velocity, reset initial state from it
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if eci_state == null:
		return
	
	var previous_linear_velocity = state.linear_velocity
	state.integrate_forces()
	
	if mode == DriverMode.ORBITAL_ON_RAILS:
		_force_update_position()
	elif mode == DriverMode.ORBITAL_OFF_RAILS:
		linear_velocity = previous_linear_velocity + (linear_velocity - previous_linear_velocity) * Planetarium.simulation_state.now
		eci_state = EciState.new(
			current_system_tree.host.to_local(global_position),
			linear_velocity
		)
		eci_state.time = Planetarium.simulation_state.now
		initial_eci_state = eci_state
		mode = DriverMode.ORBITAL_OFF_RAILS if state.get_contact_count() > 0 else DriverMode.ORBITAL_ON_RAILS


func _force_update_position() -> void:
	linear_velocity = eci_state.velocity
	if current_system_tree != null:
		global_position = current_system_tree.host.to_global(eci_state.position)


func _on_body_entered(_body: Node) -> void:
	mode = DriverMode.ORBITAL_OFF_RAILS


func _on_time_scale_changed(old_time_scale: float, time_scale: float) -> void:
	if mode == DriverMode.ORBITAL_ON_RAILS and eci_state != null:
		_force_update_position()
		await get_tree().physics_frame
		_force_update_position()


func _on_celestial_host_updated(previous_position: Vector3) -> void:
	# Update our origin as to update our frame of reference as well
	global_position += current_system_tree.host.global_position - previous_position


func on_vessel_updated(eci_state: EciState, is_active: bool) -> void: 
	self.eci_state = eci_state
	# Since our frame of reference is changing (eci_state)
	# we need to update it's time component as well
	self.eci_state.time = Planetarium.simulation_state.now


func on_vessel_removed() -> void:
	if current_system_tree != null:
		current_system_tree.host_updated.disconnect(_on_celestial_host_updated)
	Planetarium.simulation_state.time_scale_changed.disconnect(_on_time_scale_changed)
	body_entered.disconnect(_on_body_entered)


func on_entered_new_system(eci_state: EciState, system_tree: LocalCelestialBodySystem) -> void:
	print('oi')
	entered_new_system_hook.emit(HookLifetime.START)
	
	self.eci_state = eci_state
	# Since our frame of reference is changing (eci_state)
	# we need to update it's time component as well
	self.eci_state.time = Planetarium.simulation_state.now
	initial_eci_state = self.eci_state
	
	if current_system_tree != null:
		current_system_tree.host_updated.disconnect(_on_celestial_host_updated)
	
	current_system_tree = system_tree
	current_system_tree.host_updated.connect(_on_celestial_host_updated)
	
	entered_new_system_hook.emit(HookLifetime.END)


## Custom version of apply_central_force
func vessel_apply_central_force(force: Vector3) -> void:
	vessel_apply_central_force_hook.emit(force, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_central_force(force)

	vessel_apply_central_force_hook.emit(force, HookLifetime.END)


## Custom version of apply_central_impulse
func vessel_apply_central_impulse(impulse: Vector3) -> void:
	vessel_apply_central_impulse_hook.emit(impulse, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_central_impulse(impulse)

	vessel_apply_central_impulse_hook.emit(impulse, HookLifetime.END)


## Custom version of apply_force
func vessel_apply_force(force: Vector3, my_position: Vector3 = Vector3(0, 0, 0)) -> void:
	vessel_apply_force_hook.emit(force, my_position, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_force(force, my_position)

	vessel_apply_force_hook.emit(force, my_position, HookLifetime.END)


## Custom version of apply_impulse
func vessel_apply_impulse(impulse: Vector3, my_position: Vector3 = Vector3(0, 0, 0)) -> void:
	vessel_apply_impulse_hook.emit(impulse, my_position, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_impulse(impulse, my_position)

	vessel_apply_impulse_hook.emit(impulse, my_position, HookLifetime.END)


## Custom version of apply_torque
func vessel_apply_torque(torque: Vector3) -> void:
	vessel_apply_torque_hook.emit(torque, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_torque(torque)

	vessel_apply_torque_hook.emit(torque, HookLifetime.END)


## Custom version of apply_torque_impulse
func vessel_apply_torque_impulse(impulse: Vector3) -> void:
	vessel_apply_torque_impulse_hook.emit(impulse, HookLifetime.START)

	mode = DriverMode.ORBITAL_OFF_RAILS
	super.apply_torque_impulse(impulse)

	vessel_apply_torque_impulse_hook.emit(impulse, HookLifetime.END)


