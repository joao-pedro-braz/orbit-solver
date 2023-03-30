# Based on: https://www.mathworks.com/matlabcentral/fileexchange/48723-matlab-functions-for-two-body-orbit-propagation?focused=3853951&tab=function

# Copyright (c) 2014, David Eagle
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

class_name Danby


# convergence criterion
const TOLERANCE := 1.0e-8
const ITERATIONS := 25


# Solves the two-body problem using Danby-Stumpff's method
#
# Inputs:
#  - gravitation_constant = gravitational constant (km**3/sec**2)
#  - simulation_duration = propagation time interval (seconds)
#  - eci_state = Initial ECI position and velocity vectors 
#
# Output:
#  - result = Resulting  ECI position and velocity vectors
static func solve(
		mu: float, 
		simulation_duration: float, 
		eci_state: EciState
	) -> EciState:
	var orbital_elements := OrbitalState.solve_for_keplerian_orbital_elements(mu, eci_state)
	var semi_axis_a := orbital_elements.semilatus_rectum / (1.0 - orbital_elements.eccentricity ** 2.0)
	var n := sqrt(mu / absf(semi_axis_a) ** 3.0)

	var E: float
	var xma: float
	if is_zero_approx(orbital_elements.eccentricity):
		# Solving for circular orbit
		var M0 := orbital_elements.true_anomaly  # for circular orbit M = E = nu
		var M := M0 + n * simulation_duration
		orbital_elements.true_anomaly = M - 2.0 * PI * floorf(M / 2.0 / PI)
		return OrbitalState.solve_for_eci_state(mu, orbital_elements)

	elif orbital_elements.eccentricity < 1.0:
		# For elliptical orbit
		var M0 := OrbitalAngles.eccentric_anomaly_to_mean_anomaly(
			OrbitalAngles.true_anomaly_to_eccentric_anomaly(
				orbital_elements.true_anomaly,
				orbital_elements.eccentricity
			),
			orbital_elements.eccentricity
		)
		var M := M0 + n * simulation_duration
		xma = M - 2.0 * PI * floorf(M / 2.0 / PI)
		E = xma + 0.85 * sign(sin(xma)) * orbital_elements.eccentricity
	else:
		# For parabolic and hyperbolic
		var M0 := OrbitalAngles.hyperbolic_anomaly_to_mean_anomaly(
			OrbitalAngles.true_anomaly_to_hyperbolic_anomaly(
				orbital_elements.true_anomaly,
				orbital_elements.eccentricity
			),
			orbital_elements.eccentricity
		)
		var M := M0 + n * simulation_duration
		xma = M - 2.0 * PI * floorf(M / 2.0 / PI)
		E = log(2.0 * xma / orbital_elements.eccentricity + 1.8)

	# Iterations begin
	n = 0
	while n <= ITERATIONS:
		var f: float
		var fp: float
		var fpp: float
		var fppp: float
		
		if orbital_elements.eccentricity < 1.0:
			var s := orbital_elements.eccentricity * sin(E)
			var c := orbital_elements.eccentricity * cos(E)
			f = E - s - xma
			fp = 1 - c
			fpp = s
			fppp = c
		else:
			var s := orbital_elements.eccentricity * sinh(E)
			var c := orbital_elements.eccentricity * cosh(E)
			f = s - E - xma
			fp = c - 1
			fpp = s
			fppp = c

		if abs(f) <= TOLERANCE:
			var sta: float
			var cta: float
			if orbital_elements.eccentricity < 1.0:
				sta = sqrt(1 - orbital_elements.eccentricity**2) * sin(E)
				cta = cos(E) - orbital_elements.eccentricity
			else:
				sta = sqrt(orbital_elements.eccentricity**2 - 1) * sinh(E)
				cta = orbital_elements.eccentricity - cosh(E)

			orbital_elements.true_anomaly = atan2(sta, cta)
			break
		else:
			var delta := -f / fp
			var delta_star := -f / (fp + 0.5 * delta * fpp)
			var deltak := -f / (
				fp + 0.5 * delta_star * fpp + delta_star ** 2.0 * fppp / 6.0
			)
			E = E + deltak
			n += 1
	
	if n >= ITERATIONS:
		printerr("Boipasas ASAS")

	return OrbitalState.solve_for_eci_state(mu, orbital_elements)
