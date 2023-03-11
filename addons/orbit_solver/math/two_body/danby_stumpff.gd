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

class_name DanbyStumpff


# convergence criterion
const TOLERANCE := 1.0e-8


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
	var r0 := eci_state.position.length()
	var v0 := eci_state.velocity.length()
	var alpha := 2.0 * mu / r0 - v0 ** 2.0
	var u := eci_state.position.dot(eci_state.velocity)
	
	var s: float
	var x: float
	if alpha > 0.0:
		# initial guess for elliptic orbit
		var a := mu / alpha
		var en := sqrt(mu / (a * a * a))
		var ec := 1 - r0 / a
		var es := u / (en * a * a)
		var e := sqrt(ec * ec + es * es)
		simulation_duration = simulation_duration - floorf(en * simulation_duration / TAU) * TAU / en
		
		if simulation_duration < 0.0:
			simulation_duration = simulation_duration + TAU / en

		var y := en * simulation_duration - es
		var z := es * cos(y) + ec * sin(y)
		var sigma: float
		if is_zero_approx(z):
			sigma = 1.0
		else:
			sigma = absf(z) / z
		x = y + 0.85 * sigma * e
		s = x / sqrt(alpha)
	else:
		# initial guess for hyperbolic orbit
		var r02 := r0 * r0
		var r03 := r02 * r0

		if absf(simulation_duration * u / r02) < 1.0 and absf(simulation_duration * simulation_duration * (alpha / r02 + mu / r03)) < 3.0:
			var t1 := 0.75 * simulation_duration
			var t2 := 0.25 * simulation_duration
			
			s = t1 / r0 - 0.5 * t1 * t1 * u / r03 + t1 * t1 * t1 \
				* (alpha - mu / r0 + 3.0 * u * u / r02) / (6.0 * r03) \
				+ t1 * t1 * t1 * t1 * (u / (r02 * r03)) \
				* (-3.0 * alpha / 8.0 - 5.0 * u * u / (8.0 * r02) + 5.0 * mu / (12.0 * r0))
			
			var r1 := r0 * (1.0 - alpha * s * s / 2.0) + u * s \
				* (1.0 - alpha * s * s / 6.0) + mu * s * s / 2.0
			
			var u1 := (-r0 * alpha + mu) * s * (1.0 - s * s * alpha / 6.0) \
				+ u * (1.0 - alpha * s * s / 2.0)
			
			var r12 := r1 * r1
			var r13 := r1 * r12
			
			s += t2 / r1 - 0.5 * t2 * t2 * u1 / r13 + t2 * t2 * t2 \
				* (alpha - mu / r1 + 3.0 * u1 * u1 / r12) / (6.0 * r13) \
				+ t2 * t2 * t2 * t2 * (u1 / (r12 * r13)) \
				* (-3.0 * alpha / 8.0 - 5.0 * u1 * u1 / (8.0 * r12) \
				+ 5.0 * mu / (12.0 * r1))
		else:
			var a := mu / alpha
			var en := sqrt(-mu / (a * a * a))
			var ch := 1.0 - r0 / a
			var sh := u / sqrt(-a * mu)
			var e := sqrt(ch * ch - sh * sh)
			var dm := en * simulation_duration

			if dm > 0.0:
				s = log((2.0 * dm + 1.8 * e) / (ch + sh)) / sqrt(-alpha)
			else:
				s = -log((-2.0 * dm + 1.8 * e) / (ch - sh)) / sqrt(-alpha)
	
	# solve universal form of Kepler's equation
	var nc = 0
	var ssaved = s
	var f: float
	var fp: float
	var fpp: float
	var fppp: float
	var c0: float
	var c1: float
	var c2: float
	var c3: float
	while true:
		nc += 1
		x = s * s * alpha
		var stumpff_result := _stumpff(x)
		c0 = stumpff_result.x
		c1 = stumpff_result.y
		c2 = stumpff_result.z
		c3 = stumpff_result.w

		c1 = c1 * s
		c2 = c2 * s * s
		c3 = c3 * s * s * s
		
		f = r0 * c1 + u * c2 + mu * c3 - simulation_duration
		fp = r0 * c0 + u * c1 + mu * c2
		fpp = (-r0 * alpha + mu) * c1 + u * c0
		fppp = (-r0 * alpha + mu) * c0 - u * alpha * c1
		
		var ds := -f / fp
		ds = -f / (fp + ds * fpp / 2.0)
		ds = -f / (fp + ds * fpp / 2.0 + ds * ds * fppp / 6.0)
		s = s + ds

		if abs(ds) < TOLERANCE or nc > 10:
			break
	
	if nc > 15:
		push_warning("DanbyStumpff: More than 15 iterations when trying to solve universal form of Kepler's equation, trying Shepard's method")
		# As a Fallback, we try to solve it using Shepard's method
		return Shepard.solve(mu, simulation_duration, eci_state)
	
	f = 1.0 - (mu / r0) * c2
	var g := simulation_duration - mu * c3
	var fdot := -(mu / (fp * r0)) * c1
	var gdot := 1.0 - (mu / fp) * c2
	
	return EciState.new(
		eci_state.position * f + g * eci_state.velocity,
		eci_state.position * fdot + gdot * eci_state.velocity,
	)


# Stumpff functions
# input
#  x = function argument
# output
#  [c0, c1, c2, c3] = function values at x
static func _stumpff(x: float) -> Vector4:
	var n = 0
	var x_copy := x
	while abs(x_copy) > 0.1:
		n = n + 1
		x_copy = 0.25 * x_copy
	
	var c2 := (1.0 - x_copy * (1.0 - x_copy * (1.0 - x_copy * (1.0 - x_copy / 182.0) / 132.0) / 90.0)) / 56.0
	c2 = (1.0 - x_copy * (1.0 - x_copy * c2 / 30.0) / 12.0) / 2.0
	var c3 := (1.0 - x_copy * (1.0 - x_copy * (1.0 - x_copy * (1.0 - x_copy / 210.0) / 156.0) / 110.0)) / 72.0
	c3 = (1.0 - x_copy * (1.0 - x_copy * c3 / 42.0) / 20.0) / 6.0
	var c1 := 1.0 - x_copy * c3
	var c0 := 1.0 - x_copy * c2
	
	while n > 0:
		n = n - 1
		c3 = 0.25 * (c2 + c0 * c3)
		c2 = 0.5 * c1 * c1
		c1 = c0 * c1
		c0 = 2.0 * c0 * c0 - 1.0
		x_copy = 4.0 * x_copy
	
	return Vector4(c0, c1, c2, c3)
