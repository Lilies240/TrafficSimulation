# Manager.gd
# Some assistance from ChatGPT
extends Node2D

@export var vehicle_scene: PackedScene
@export var compact_scene: PackedScene
@export var midsize_scene: PackedScene
@export var suv_scene: PackedScene
@export var truck_scene: PackedScene

@export var spawnQueue: Array[SpawnRequest] = [] # the queue of vehicle spawns

var vehicleInstances: Array = []  # Stores active vehicle instances
var elapsedTime: float = 0.0  # Tracks amount of time elapsed since scene start

func _ready():
	# Sort spawnQueue by spawnTime
	spawnQueue.sort_custom(_compare_spawn_times)
	
func _process(delta):
	# Update elapsed time
	elapsedTime += delta
	
	# Check each spawn request
	for request in spawnQueue:
		if elapsedTime >= request.spawnTime:
			spawn_vehicle(request)
			spawnQueue.erase(request)  # Remove the request after it is spawned
			break

func spawn_vehicle(request: SpawnRequest):
	# Instantiate the correct vehicle scene based on the type	
	var vehicle_instance
	match request.vehicleType:
		Enums.VehicleType.COMPACT:
			vehicle_instance = compact_scene.instantiate()
		Enums.VehicleType.MIDSIZE:
			vehicle_instance = midsize_scene.instantiate()
		Enums.VehicleType.SUV:
			vehicle_instance = suv_scene.instantiate()
		Enums.VehicleType.TRUCK:
			vehicle_instance = truck_scene.instantiate()
		_:
			vehicle_instance = vehicle_scene.instantiate()
	
	# Add the vehicle to specified road
	var path_node = get_node(request.spawnPath) if request.spawnPath != null else null
	if path_node:
		path_node.add_child(vehicle_instance)
	else:
		print("Error: Path2D node not found for vehicle spawn.")
	
	# Initialize the vehicle instance
	vehicle_instance.initialize(self,request.vehicleType)
	
	# Add the vehicle instance to the array
	vehicleInstances.append(vehicle_instance)
	
	print("Vehicle spawned and added to list. Total vehicles: ", vehicleInstances.size())

func _compare_spawn_times(a: SpawnRequest, b: SpawnRequest) -> int:
	return int(a.spawnTime - b.spawnTime)

func _mph_to_mps(speed):
	#Convert speed from miles per hour to meters per second
	return speed * 1609.34 / 3600.0

func kmph_to_mps(speed):
	#Convert speed from meters per second to kilometers per hour
	return speed * 1000.0 / 3600.0
