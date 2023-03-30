# Copyright (c) 2013, Darin Koblick
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Based on: https://www.mathworks.com/matlabcentral/fileexchange/35455-convert-keplerian-orbital-elements-to-a-state-vector

class_name OrbitalState


const TOLERANCE := 1e-8


static func solve_for_keplerian_orbital_elements(
		gravitation_constant: float,
		eci_state: EciState
) -> KeplerianOrbitalElements:
	var result := KeplerianOrbitalElements.new()
	
	# Position and Velocity
	var distance := eci_state.position.length()
	var speed := eci_state.velocity.length()
	var position_normalized := eci_state.position.normalized()
	
	# Orbital Angular Momentum
	var angular_momentum_vector := eci_state.position.cross(eci_state.velocity)
	var angular_momentum := angular_momentum_vector.length()
	result.angular_momentum = angular_momentum
	
#	var orbital_acceleration := (1.0 / gravitation_constant) \
#		* (
#			(eci_state.position * (speed ** 2 - gravitation_constant / distance)) \
#			- (eci_state.position.dot(eci_state.velocity) * eci_state.velocity)
#		)
	var eccentricity_vector := eci_state.velocity.cross(angular_momentum_vector) \
		/ gravitation_constant - position_normalized
	var eccentricity_vector_normalized := eccentricity_vector.normalized()
	var eccentricity_vector_magnitude := eccentricity_vector.length()
	
	
	# Inclination
	var inclination := acos(angular_momentum_vector.z / angular_momentum)
	result.inclination = inclination
	
	# Right Ascension of the Ascending Node
	var reference := Vector3.BACK
	var node_line_vector := reference.cross(angular_momentum_vector)
	var node_line := node_line_vector.length()
	var raan := acos(node_line_vector.x / node_line)
	if is_zero_approx(node_line_vector.x):
		raan = 0.0
	
	if node_line_vector.y < 0.0:
		raan = TAU - raan
	result.raan = raan
	
	# Eccentricity
	result.eccentricity = eccentricity_vector_magnitude
	
	# Argument of Periapsis
	var node_line_dot_acceleration := node_line_vector.dot(eccentricity_vector)
	var periapsis_argument := acos(node_line_dot_acceleration \
											/ (node_line * eccentricity_vector_magnitude))
	if is_zero_approx(node_line_dot_acceleration):
		periapsis_argument = 0
	
	if eccentricity_vector.z < 0.0:
		periapsis_argument = TAU - periapsis_argument
	result.periapsis_argument = periapsis_argument
	
	# True Anomaly
	# Due to some strange rounding errors, we need to clampf it
	var true_anomaly := acos(
		clampf(
			eccentricity_vector.dot(eci_state.position) \
				/ (eccentricity_vector_magnitude * distance),
			-1.0,
			1.0
		)
	)
	if is_zero_approx(eccentricity_vector.dot(eci_state.position)):
		true_anomaly = 0
	
	if eci_state.position.dot(eci_state.velocity) < 0.0:
		true_anomaly = TAU - true_anomaly
	result.true_anomaly = true_anomaly
	result.mean_anomaly = true_anomaly
	
	# True Longitude
	var true_longitude := acos(position_normalized.x)
	if eci_state.position.y < 0:
		true_longitude = TAU - true_longitude
	result.true_longitude = true_longitude
	
	# Argument of Latitude
	var node_line_dot_position := node_line_vector.dot(eci_state.position)
	var latitude_argument := acos(node_line_dot_position / (node_line * distance))
	if is_zero_approx(node_line_dot_position):
		latitude_argument = 0
	
	if eci_state.position.z < 0.0:
		latitude_argument = TAU - latitude_argument
	result.latitude_argument = latitude_argument
	
	# Longitude of Periapse
	var periapse_longitude := acos(eccentricity_vector_normalized.x)
	if is_zero_approx(eccentricity_vector.x):
		periapse_longitude = 0
	
	if eccentricity_vector.y < 0.0:
		periapse_longitude = TAU - periapse_longitude
	result.periapse_longitude = periapse_longitude
	
	# Semilatus Rectum
	# Semimajor Axis
	var semilatus_rectum: float
	var semi_major_axis: float
	if eccentricity_vector_magnitude != 1.0:
		semi_major_axis = -gravitation_constant / (2.0 * (
			(speed ** 2 / 2) - (gravitation_constant / distance)
		))
		semilatus_rectum = semi_major_axis * (1 - eccentricity_vector_magnitude ** 2)
	else:
		semi_major_axis = INF
		semilatus_rectum = angular_momentum ** 2 / gravitation_constant
	result.semi_major_axis = semi_major_axis
	result.semilatus_rectum = semilatus_rectum
	
	return result


static func solve_for_eci_state(
	gravitation_constant: float,
	keplerian_orbital_elements: KeplerianOrbitalElements
) -> EciState:
	# So we can safely make changes to the input
	# and use them down the function
	var input: KeplerianOrbitalElements = keplerian_orbital_elements.duplicate()
	
	if input.eccentricity < TOLERANCE \
		and fmod(input.inclination, PI) < TOLERANCE:
		input.periapsis_argument = 0.0
		input.raan = 0.0
		input.true_anomaly = input.true_longitude
	
	if input.eccentricity < TOLERANCE \
		and fmod(input.inclination, PI) > TOLERANCE:
		input.periapsis_argument = 0.0
		input.true_anomaly = input.latitude_argument
	
	if input.eccentricity > TOLERANCE \
		and fmod(input.inclination, PI) < TOLERANCE:
		input.raan = 0.0
		input.periapsis_argument = input.periapse_longitude
	
	var position_pqw := Vector3(
		input.semilatus_rectum * cos(input.true_anomaly) \
			/ (1.0 + input.eccentricity * cos(input.true_anomaly)),
		input.semilatus_rectum * sin(input.true_anomaly) \
			/ (1.0 + input.eccentricity * cos(input.true_anomaly)),
		0.0
	)
	
	var velocity_pqw := Vector3(
		-sqrt(gravitation_constant / input.semilatus_rectum) \
			* sin(input.true_anomaly),
		sqrt(gravitation_constant / input.semilatus_rectum) \
			* (input.eccentricity + cos(input.true_anomaly)),
		0.0
	)
	
	var transform := Transform3D.IDENTITY
	var cO := cos(input.raan)
	var sO := sin(input.raan)
	var co := cos(input.periapsis_argument)
	var so := sin(input.periapsis_argument)
	var ci := cos(input.inclination)
	var si := sin(input.inclination)
	
	transform.basis.x = Vector3(
		cO * co - sO * so * ci,
		-cO * so - sO * co * ci,
		sO * si
	)
	transform.basis.y = Vector3(
		sO * co + cO * so * ci,
		-sO * so + cO * co * ci,
		-cO * si
	)
	transform.basis.z = Vector3(
		so * si,
		co * si,
		ci
	)
	
	return EciState.new(
		position_pqw * transform,
		velocity_pqw * transform
	)


static func rv2coe(
		gravitation_constant: float,
		eci_state: EciState
	) -> KeplerianOrbitalElements:
	var orbital_elements := KeplerianOrbitalElements.new()
	
	var h := eci_state.position.cross(eci_state.velocity)
	var n := Vector3.BACK.cross(h)
	var e := ((eci_state.velocity.length_squared() - gravitation_constant / eci_state.position.length()) \
		* eci_state.position - eci_state.position.dot(eci_state.velocity) * eci_state.velocity) / gravitation_constant
	orbital_elements.eccentricity = e.length()
	orbital_elements.semilatus_rectum = h.length_squared() / gravitation_constant
	orbital_elements.inclination = acos(h.z / h.length())

	var circular := orbital_elements.eccentricity < TOLERANCE
	var equatorial := absf(orbital_elements.inclination) < TOLERANCE

	if equatorial and not circular:
		orbital_elements.raan = 0.0
		orbital_elements.periapsis_argument = fmod(atan2(e.y, e.x), TAU)
		orbital_elements.true_anomaly = atan2((h.dot(e.cross(eci_state.position))) / h.length(), eci_state.position.dot(e))
	elif not equatorial and circular:
		orbital_elements.raan = fmod(atan2(n.y, n.x), TAU)
		orbital_elements.periapsis_argument = 0.0
		orbital_elements.true_anomaly = atan2((eci_state.position.dot(h.cross(n))) / h.length(), eci_state.position.dot(n))
	elif equatorial and circular:
		orbital_elements.raan = 0
		orbital_elements.periapsis_argument = 0
		orbital_elements.true_anomaly = fmod(atan2(eci_state.position[1], eci_state.position[0]), TAU)  # True longitude
	else:
		var a := orbital_elements.semilatus_rectum / (1.0 - (orbital_elements.eccentricity ** 2.0))
		var ka := gravitation_constant * a
		if a > 0.0:
			var e_se := eci_state.position.dot(eci_state.velocity) / sqrt(ka)
			var e_ce := eci_state.position.length() * eci_state.velocity.length_squared() / gravitation_constant - 1.0
			orbital_elements.true_anomaly = OrbitalAngles.eccentric_anomaly_to_true_anomaly(
				atan2(e_se, e_ce),
				orbital_elements.eccentricity
			)
		else:
			var e_sh := eci_state.position.dot(eci_state.velocity) / sqrt(-ka)
			var e_ch := eci_state.position.length() * (eci_state.velocity.length() ** 2.0) / gravitation_constant - 1.0
			orbital_elements.true_anomaly = OrbitalAngles.hyperbolic_anomaly_to_true_anomaly(
				log((e_ch + e_sh) / (e_ch - e_sh)) / 2.0,
				orbital_elements.eccentricity
			)

		orbital_elements.raan = fmod(atan2(n[1], n[0]), TAU)
		var px := eci_state.position.dot(n)
		var py := eci_state.position.dot(h.cross(n)) / h.length()
		orbital_elements.periapsis_argument = fmod(atan2(py, px) - orbital_elements.true_anomaly, TAU)

	orbital_elements.true_anomaly = fmod(orbital_elements.true_anomaly + PI, TAU) - PI

	return orbital_elements


static func rv_pqw(
	gravitation_constant: float,
	semilatus_rectum: float,
	eccentricity: float,
	true_anomaly: float) -> EciState:
	return EciState.new(
		Vector3(cos(true_anomaly), sin(true_anomaly), 0.0) * (semilatus_rectum / (1.0 + eccentricity * cos(true_anomaly))),
		Vector3(-sin(true_anomaly), eccentricity + cos(true_anomaly), 0.0) * sqrt(gravitation_constant / semilatus_rectum)
	)


static func coe_rotation_matrix(
	inclination: float,
	raan: float,
	periapsis_argument: float
) -> Basis:
	var basis := Basis.IDENTITY
	basis = basis.rotated(Vector3.BACK, periapsis_argument)
	basis = basis.rotated(Vector3.RIGHT, inclination)
	basis = basis.rotated(Vector3.BACK, raan)
	return basis


static func coe2rv(
	gravitation_constant: float,
	keplerian_orbital_elements: KeplerianOrbitalElements
) -> EciState:
	var pwq := rv_pqw(
		gravitation_constant,
		keplerian_orbital_elements.semilatus_rectum,
		keplerian_orbital_elements.eccentricity,
		keplerian_orbital_elements.true_anomaly,
	)
	var rm := coe_rotation_matrix(
		keplerian_orbital_elements.inclination,
		keplerian_orbital_elements.raan,
		keplerian_orbital_elements.periapsis_argument
	)
	pwq.position *= rm
	pwq.velocity *= rm
	return pwq
