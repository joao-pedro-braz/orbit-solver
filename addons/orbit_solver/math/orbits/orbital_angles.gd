## Based of https://github.com/poliastro/poliastro/blob/1e2a0198bc70e7846f327f7805fd859875ca1777/src/poliastro/core/angles.py#L383
extends Node
class_name OrbitalAngles


static func true_anomaly_to_eccentric_anomaly(true_anomaly: float, eccentricity: float) -> float:
	return 2.0 * atan(sqrt((1.0 - eccentricity) / (1.0 + eccentricity)) * tan(true_anomaly / 2.0))


static func eccentric_anomaly_to_mean_anomaly(eccentric_anomaly: float, eccentricity: float) -> float:
	return eccentric_anomaly - eccentricity * sin(eccentric_anomaly)


static func true_anomaly_to_hyperbolic_anomaly(true_anomaly: float, eccentricity: float) -> float:
	return 2.0 * atanh(sqrt((eccentricity - 1.0) / (eccentricity + 1.0)) * tan(true_anomaly / 2.0))


static func hyperbolic_anomaly_to_mean_anomaly(hyperbolic_anomaly: float, eccentricity: float) -> float:
	return eccentricity * sinh(hyperbolic_anomaly) - hyperbolic_anomaly


static func eccentric_anomaly_to_true_anomaly(eccentricity_anomaly: float, eccentricity: float) -> float:
	return 2.0 * atan(sqrt((1.0 + eccentricity) / (1.0 - eccentricity)) * tan(eccentricity_anomaly / 2.0))


static func hyperbolic_anomaly_to_true_anomaly(hyperbolic_anomaly: float, eccentricity: float) -> float:
	return 2.0 * atan(sqrt((eccentricity + 1) / (eccentricity - 1)) * tanh(hyperbolic_anomaly / 2))


static func atanh(x: float) -> float:
	return (log(1.0 + x) - log(1.0 - x)) * 0.5
