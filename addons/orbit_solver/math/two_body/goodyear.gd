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

class_name Goodyear


const A0 := 0.025
const B0 := A0 / 42.0
const C0 := B0 / 72.0
const D0 := C0 / 110.0
const E0 := D0 / 156.0
const F0 := E0 / 210.0
const G0 := F0 / 272.0
const H0 := G0 / 342.0
const I0 := 1.0 / 24.0
const J0 := I0 / 30.0
const K0 := J0 / 56.0
const L0 := K0 / 90.0
const M0 := L0 / 132.0
const N0 := M0 / 182.0
const O0 := N0 / 240.0
const P0 := O0 / 306.0
# convergence criterion
const TOLERANCE := 1.0e-8


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
	var rsdvs := eci_state.position.dot(eci_state.velocity)
	var rsm := eci_state.position.length()
	var zsma := 2.0 / rsm - 1.0 / mu
	
	var psi := 0.0
	if zsma > 0.0:
		psi = simulation_duration * zsma
	
	var alp := 1.0 - 2.0 * mu / rsm
	
	var rfm: float
	var s1: float
	var s2: float
	var s3: float
	var gg: float
	for z in range(20):
		var m := 0
		var psi2 := psi * psi
		var psi3 := psi * psi2
		var aas := alp * psi2
		
		var zas := 0.0
		if is_zero_approx(aas):
			zas = 1.0 / aas
		
		while abs(aas) > 1.0:
			m += 1
			aas = 0.25 * aas
		
		var pc5 := A0 + (B0 + (C0 + (D0 + (E0 + (F0 + (G0 + H0 * aas) * aas) \
			* aas) * aas) * aas) * aas) * aas
		
		var pc4 := I0 + (J0 + (K0 + (L0 + (M0 + (N0 + (O0 + P0 * aas) * aas) \
			* aas) * aas) * aas) * aas) * aas
		
		var pc3 := (0.5 + aas * pc5) / 3.0
		
		var pc2 := 0.5 + aas * pc4
		
		var pc1 := 1.0 + aas * pc3
	
		var pc0 := 1.0 + aas * pc2
		
		if m > 0:
			while m > 0:
				m -= 1
				pc1 = pc0 * pc1
				pc0 = 2 * pc0 * pc0 - 1.0
			
			pc2 = (pc0 - 1.0) * zas
			pc3 = (pc1 - 1.0) * zas
		
		s1 = pc1 * psi
		s2 = pc2 * psi2
		s3 = pc3 * psi3
		
		gg = rsm * s1 + rsdvs * s2
		var dtau := gg + mu * s3 - simulation_duration
		rfm = abs(rsdvs * s1 + mu * s2 + rsm * pc0)
		
		if abs(dtau) < (abs(simulation_duration) * TOLERANCE):
			break
		else:
			psi -= dtau / rfm
	
	var rsc := 1.0 / rsm
	var r2 := 1.0 / rfm
	var r12 := rsc * r2
	var fm1 := -mu * s2 * rsc
	var ff := fm1 + 1
	var fd := -mu * s1 * r12
	var gdm1 := -mu * s2 * r2
	var gd := gdm1 + 1
	
	return EciState.new(
		eci_state.position * ff + gg * eci_state.velocity,
		eci_state.position * fd + gd * eci_state.velocity,
	)
