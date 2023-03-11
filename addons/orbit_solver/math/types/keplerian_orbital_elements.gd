extends Resource
class_name KeplerianOrbitalElements


## kilometers
@export
var semi_major_axis: float

## dimensionless
@export_range(0.0, 1.0)
var eccentricity: float

## radians
@export_range(0.0, PI, 0.01, "radians")
var inclination: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var periapsis_argument: float

## right ascension of ascending node
## radians
@export_range(0.0, TAU, 0.01, "radians")
var raan: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var true_anomaly: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var mean_anomaly: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var true_longitude: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var latitude_argument: float

## radians
@export_range(0.0, TAU, 0.01, "radians")
var periapse_longitude: float

## kilometers
@export
var semilatus_rectum: float

## kilometers²/second
@export
var angular_momentum: float


func error_factor(other: KeplerianOrbitalElements) -> float:
	var result := 0.0
	for property in self.get_property_list():
		result = max(result, self.get(property["name"]) / other.get(property["name"]))
	return result - 1.0


func is_equal_approx(other: KeplerianOrbitalElements) -> bool:
	return is_equal_approx(semi_major_axis, other.semi_major_axis) \
		and is_equal_approx(eccentricity, other.eccentricity) \
		and is_equal_approx(inclination, other.inclination) \
		and is_equal_approx(periapsis_argument, other.periapsis_argument) \
		and is_equal_approx(raan, other.raan) \
		and is_equal_approx(true_anomaly, other.true_anomaly) \
		and is_equal_approx(mean_anomaly, other.mean_anomaly) \
		and is_equal_approx(true_longitude, other.true_longitude) \
		and is_equal_approx(latitude_argument, other.latitude_argument) \
		and is_equal_approx(periapse_longitude, other.periapse_longitude) \
		and is_equal_approx(semilatus_rectum, other.semilatus_rectum) \
		and is_equal_approx(angular_momentum, other.angular_momentum)


func _to_string() -> String:
	return "KeplerianOrbitalElements(semi_major_axis=" + str(semi_major_axis) + \
				", eccentricity=" + str(eccentricity) + \
				", inclination=" + str(inclination) + \
				", periapsis_argument=" + str(periapsis_argument) + \
				", raan=" + str(raan) + \
				", true_anomaly=" + str(true_anomaly) + \
				", mean_anomaly=" + str(mean_anomaly) + \
				", true_longitude=" + str(true_longitude) + \
				", latitude_argument=" + str(latitude_argument) + \
				", periapse_longitude=" + str(periapse_longitude) + \
				", semilatus_rectum=" + str(semilatus_rectum) + \
				", angular_momentum=" + str(angular_momentum) + ")"
