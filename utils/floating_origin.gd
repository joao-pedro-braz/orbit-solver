extends Node3D


signal world_shifted(origin: Vector3)


@export var threshold := 2000.0

@export var camera: Camera3D

@export var root: Node3D


func _physics_process(_delta: float) -> void:
	if camera != null and camera.global_transform.origin.length() > threshold:
		root.global_transform.origin -= camera.global_transform.origin
		emit_signal("world_shifted", camera.global_transform.origin)
