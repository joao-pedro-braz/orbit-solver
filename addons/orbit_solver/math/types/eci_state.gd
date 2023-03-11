extends Resource
class_name EciState


# kilometers
@export var position: Vector3

# kilometers/second
@export var velocity: Vector3

# seconds
@export var time := 0.0


func _init(position: Vector3, velocity: Vector3) -> void:
	self.position = position
	self.velocity = velocity


# Computes the distance between self and other (position and velocity)
# and returns the average
func error_factor(other: EciState) -> float:
	return max(
		position.distance_to(other.position),
		velocity.distance_to(other.velocity)
	)


func is_equal_approx(other: EciState) -> bool:
	return position.is_equal_approx(other.position) \
		and velocity.is_equal_approx(other.velocity)


func _to_string() -> String:
	return "EciState(position=%s, velocity=%s, time=%s)" % [str(position), str(velocity), str(time)]

