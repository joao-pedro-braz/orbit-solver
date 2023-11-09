extends Node


@onready var root: Node3D = $World
@onready var sun: CelestialBody = $World/Sun
@onready var earth: CelestialBody = $World/Earth
@onready var rockets: Node3D = $World/Rockets
@onready var main_vessel: VesselBody = $World/Earth/MainVessel
@onready var main_vessel_left_exaust: Marker3D = $World/Earth/MainVessel/LeftExaust
@onready var main_vessel_right_exaust: Marker3D = $World/Earth/MainVessel/RightExaust

var throtle := 0
var turn := 0
var vessel_orbits := {}

func _ready() -> void:
	earth.orbital_fact_sheet.orbital_elements = OrbitalState.solve_for_keplerian_orbital_elements(
		sun.physical_fact_sheet.mass * Planetarium.simulation_state.gravitational_constant,
		EciState.new(
			sun.to_local(earth.global_position),
			Vector3.BACK * 4.5
		)
	)
	earth.physical_fact_sheet.equatorial_radius = 10.0
	
	Planetarium.add_celestial_body(sun)
	Planetarium.add_celestial_body(earth, sun)
	Planetarium.simulation_state.time_scale = 0.5
	Planetarium.init()
	
	OrbitPlotter.plot_orbit_for(
		earth,
		Planetarium.solar_system.find(earth)
	)
	
	for rocket in rockets.get_children():
		Vessels.add_vessel(rocket)
	Vessels.add_vessel(main_vessel)
	Vessels.init()


func _physics_process(delta: float) -> void:
	if throtle != 0:
		main_vessel.vessel_apply_central_force(Vector3.FORWARD * 10000.0 * delta * throtle)
	
	if turn != 0:
		main_vessel.vessel_apply_torque(Vector3.UP * 100.0 * delta * -turn)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action("accelerate"):
			throtle = 1 if event.is_action_pressed("accelerate") else 0
		elif event.is_action("deaccelerate"):
			throtle = -1 if event.is_action_pressed("deaccelerate") else 0
		elif event.is_action("turn_right"):
			turn = 1 if event.is_action_pressed("turn_right") else 0
		elif event.is_action("turn_left"):
			turn = -1 if event.is_action_pressed("turn_left") else 0
		elif event.is_pressed():
			if OS.get_keycode_string(event.keycode) == '1':
				Planetarium.simulation_state.time_scale *= 0.5
			elif OS.get_keycode_string(event.keycode) == '2':
				Planetarium.simulation_state.time_scale *= 2.0
			elif OS.get_keycode_string(event.keycode) == '3':
				for i in 1:
					_spawn_rocket()
			elif OS.get_keycode_string(event.keycode) == '4':
				Planetarium.simulation_state.time_scale *= -1


func _spawn_rocket() -> void:
	var rocket := VesselBody.new()
	
	var mesh := CSGSphere3D.new()
	mesh.radius = 5.0
	mesh.radial_segments = 64
	mesh.rings = 32
	
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = 1.0
	
	rocket.add_child(mesh)
	rocket.add_child(collision_shape)
	
	# Pick a random position around earth
	rockets.add_child(rocket)
	rocket.position = Vector3(
		randf_range(50.0, 150.0) * (1 if randf() > 0.5 else -1),
		randf_range(50.0, 150.0) * (1 if randf() > 0.5 else -1),
		randf_range(50.0, 150.0) * (1 if randf() > 0.5 else -1)
	) + earth.position
	rocket.linear_velocity = earth.position.direction_to(rocket.position).rotated(Vector3.UP, PI / 2.0) * randf() * 6.0
	
	Vessels.add_vessel(rocket)
	
	OrbitPlotter.plot_orbit_for(
		rocket,
		rocket.current_system_tree
	)
	
	await get_tree().physics_frame
	rocket.body_exited.connect(
		func(body):
			if body == earth:
				Vessels.remove_vessel(rocket)
				rocket.queue_free()
	)
