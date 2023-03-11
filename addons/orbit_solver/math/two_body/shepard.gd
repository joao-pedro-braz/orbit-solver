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

class_name Shepard


# convergence criterion
const TOLERANCE := 1e-12
const MAX_ITER := 20
 

# Solve the two-body problem using Goodyear's method
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
	var ri := eci_state.position
	var vi := eci_state.velocity
	var u := 0.0
	var umax := INF
	var umin := -INF
	var orbits := 0.0
	var tdesired := simulation_duration
	var threshold := TOLERANCE * absf(tdesired)
	var r0 := ri.length()
	var n0 := ri.dot(vi)
	var beta := 2 * (mu / r0) - 1.0
	if beta != 0:
		umax = +1.0 / sqrt(absf(beta))
		umin = -1.0 / sqrt(absf(beta))
	
	if beta > 0.0:
		orbits = beta * simulation_duration - 2.0 * n0
		orbits = 1.0 + (orbits * sqrt(beta)) / (PI * mu)
		orbits = floorf(orbits / 2.0)
	
	var uold := 0.0
	var dtold := 0.0
	var u1: float
	var u2: float
	var r1: float
	for i in range(MAX_ITER):
		var q := beta * u * u
		q = q / (1.0 + q)
		var n := 0.0
		var r := 1.0
		var l := 1.0
		var s := 1.0
		var d := 3.0
		var gcf := 1.0
		var k := -5.0
		var gold := 0
		while gcf != gold:
			k = -k
			l = l + 2.0
			d = d + 4.0 * l
			n = n + (1.0 + k) * l
			r = d / (d - n * r * q)
			s = (r - 1.0) * s
			gold = gcf
			gcf  = gold + s
		var h0 := 1.0 - 2.0 * q
		var h1 := 2.0 * u * (1.0 - q)
		var u0 := 2.0 * h0 * h0 - 1.0
		u1 = 2.0 * h0 * h1
		u2 = 2.0 * h1 * h1
		var u3 := 2.0 * h1 * u2 * gcf / 3.0
		if not is_zero_approx(orbits):
			u3 = u3 + 2.0 * PI * orbits / (beta * sqrt(beta))
		r1 = r0 * u0 + n0 * u1 + mu * u2
		var dt := r0 * u1 + n0 * u2 + mu * u3
		var slope := 4.0 * r1 / (1.0 + beta * u * u)
		var terror := tdesired - dt
		if absf(terror) < threshold:
			break
		if i > 1 and is_equal_approx(u, uold):
			break
		
		if i > 1 and is_equal_approx(dt, dtold):
			break
		
		uold  = u
		dtold = dt
		
		var ustep := terror / slope
		if ustep > 0.0:
			umin = u
			u = u + ustep
			if u > umax:
				u = (umin + umax) / 2.0
		else:
			umax = u
			u = u + ustep
			if u < umin:
				u = (umin + umax) / 2.0
		if i == MAX_ITER:
			push_warning("Shepard: Max iterations (%s) reached when trying to solve universal form of Kepler's equation" % MAX_ITER)
	
	var f := 1.0 - (mu / r0) * u2
	var gg := 1.0 - (mu / r1) * u2
	var g : =  r0 * u1 + n0 * u2
	var ff := -mu * u1 / (r0 * r1)
	
	return EciState.new(
		eci_state.position * f + g * eci_state.velocity,
		eci_state.position * ff + gg * eci_state.velocity,
	)
