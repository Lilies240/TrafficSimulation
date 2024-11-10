# SpawnRequest.gd
extends Resource

class_name SpawnRequest

@export var vehicleType: Enums.VehicleType  # the type of vehicle
@export var spawnPaths: Array[NodePath]  # Reference to the paths it follows
@export var spawnTime: float  # time at which to spawn vehicle
