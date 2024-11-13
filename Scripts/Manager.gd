# Manager.gd
# Some assistance from ChatGPT
extends Node2D

@export var control_config: Enums.ControlConfig
@export var peak_time_duration: float = 180  # Duration of peak time in seconds
@export var off_peak_time_duration: float = 120 # Duration of off-peak time in seconds

@export var majorTrafficRate: Array[Vector2]  # the peak and off-peak min and max traffic arrival rate (in seconds)
@export var minorTrafficRate: Array[Vector2]

@export var simulationRunTime: float = 240 # Time that the simulation will run

@export var simulationTimeScale: float = 1.0 # engine time scale

@export var vehicle_scene: PackedScene
@export var compact_scene: PackedScene
@export var midsize_scene: PackedScene
@export var suv_scene: PackedScene
@export var truck_scene: PackedScene
@export var signal_scene: PackedScene

@export var majorRoutes: Array[Route]  # Array of possible paths to follow
@export var minorRoutes: Array[Route]

@export var traffic_signal_positions: Array[Vector2] = []  # List of positions for traffic signals
@export var traffic_signal_rotations: Array[float] = []  # List of rotations for traffic signals
@export var vehicleProbabilites: Array[float]
@onready var compactProb: float = vehicleProbabilites[0]
@onready var midsizeProb: float = compactProb + vehicleProbabilites[1]
@onready var suvProb: float = compactProb + midsizeProb + vehicleProbabilites[2]
@onready var truckProb: float = compactProb + midsizeProb + suvProb + vehicleProbabilites[3]


var traffic_signals: Array = []  # Array to store traffic signal instances
var phaseList: Array = [int(Enums.TrafficLight.MAJORRED), int(Enums.TrafficLight.MINORRED), int(Enums.TrafficLight.MAJORGREEN), int(Enums.TrafficLight.MINORRED), int(Enums.TrafficLight.MAJORYELLOW), int(Enums.TrafficLight.MINORRED), int(Enums.TrafficLight.MAJORRED),int(Enums.TrafficLight.MINORRED), int(Enums.TrafficLight.MAJORRED),int(Enums.TrafficLight.MINORGREEN), int(Enums.TrafficLight.MAJORRED), int(Enums.TrafficLight.MINORYELLOW)]

var vehicleInstances: Array = []  # Stores active vehicle instances
var elapsedTime: float = 0.0  # Tracks amount of time elapsed since scene start
var next_major_spawn_time: float = 0.0  # Next spawn time for major traffic
var next_minor_spawn_time: float = 0.0  # Next spawn time for minor traffic

var majorCarsPassed: int = 0  # Number of major traffic cars that have gone through
var minorCarsPassed: int = 0  # Number of minnor traffic cars that have gone through
var majorCarsSpawned: int = 0  # Number of major traffic cars spawned
var minorCarsSpawned: int = 0  # Number of minor traffic cars spawned
var majorCarThroughput: float = 0.0  # Time it takes for major traffic to get through
var minorCarThroughput: float = 0.0  # Time it takes for minor traffic to get through

var cycleTime: float = 0.0 # keep track of current cycle time elapsed
var isPeakTime: bool = true # keeps track of current cycle
var cyclesElapsed: int = 0 # number of cycles run
var currentcycleInfo: Array[float]
var allInfo = []

func _ready():
	Engine.time_scale = simulationTimeScale
	# Spawn traffic signals
	spawn_traffic_signals()

func spawn_traffic_signals():
	# Ensure we have defined both positions and rotations for the traffic signals
	if traffic_signal_positions.size() != traffic_signal_rotations.size():
		print("Error: Mismatch between traffic signal positions and rotations.")
		return
	
	# Create each traffic signal at the specified position and rotation
	for i in range(traffic_signal_positions.size()):
		var signal_instance = signal_scene.instantiate()
		signal_instance.position = traffic_signal_positions[i]
		signal_instance.rotation_degrees = traffic_signal_rotations[i]
		signal_instance.initialize(control_config, signal_instance.rotation_degrees, self, phaseList)
		
		# Add to the scene and store in the array
		add_child(signal_instance)
		traffic_signals.append(signal_instance)
	
	#print("Spawned", traffic_signals.size(), "traffic signals.")

func get_traffic_signal(current_path: Path2D) -> String:
	match current_path.name.substr(0,8):
		"W-E Flow": # major roads
			if current_path.name.ends_with("4") or current_path.name.ends_with("5"): # last roads
				return "green"
			match traffic_signals[0].currentPhase[0]:
				Enums.TrafficLight.MAJORRED:
					return "red"
				Enums.TrafficLight.MAJORYELLOW:
					return "yellow"
				Enums.TrafficLight.MAJORGREEN:
					return "green"
		"E-W Flow": # major roads
			if current_path.name.ends_with("0") or current_path.name.ends_with("1"): # last roads
				return "green"
			match traffic_signals[0].currentPhase[0]:
				Enums.TrafficLight.MAJORRED:
					return "red"
				Enums.TrafficLight.MAJORYELLOW:
					return "yellow"
				Enums.TrafficLight.MAJORGREEN:
					return "green"
		"N-S Flow": # minor roads
			if current_path.name.ends_with("2") or current_path.name.ends_with("3"): # last roads
				return "green"
			match traffic_signals[1].currentPhase[1]:
				Enums.TrafficLight.MINORRED:
					return "red"
				Enums.TrafficLight.MINORYELLOW:
					return "yellow"
				Enums.TrafficLight.MINORGREEN:
					return "green"
		"S-N Flow": # minor roads
			if current_path.name.ends_with("0") or current_path.name.ends_with("1"): # last roads
				return "green"
			match traffic_signals[1].currentPhase[1]:
				Enums.TrafficLight.MINORRED:
					return "red"
				Enums.TrafficLight.MINORYELLOW:
					return "yellow"
				Enums.TrafficLight.MINORGREEN:
					return "green"
		_:
			return ""
	return ""

func _process(delta):
	# Update elapsed time
	elapsedTime += delta
	cycleTime += delta
	
	# Check if simulation run time is over
	if elapsedTime >= simulationRunTime:
		# print final results
		#print("Final results: \n\tCars Spawned: " + str(majorCarsSpawned+minorCarsSpawned) + " (" + str(majorCarsSpawned) + " major, " + str(minorCarsSpawned) + " minor)"
							#+ "\n\tCars Passed: " + str(majorCarsPassed+minorCarsPassed) + " (" + str(majorCarsPassed) + " major, " + str(minorCarsPassed) + " minor)"
							#+ "\n\tAverage Throughput: " + str((majorCarThroughput+minorCarThroughput)/(majorCarsPassed+minorCarsPassed)) + " (" + str(majorCarThroughput/majorCarsPassed) + " major, " + str(minorCarThroughput/minorCarsPassed) + " minor)")
		
		currentcycleInfo = [majorCarsSpawned,minorCarsSpawned,(majorCarsSpawned+minorCarsSpawned),majorCarsPassed,minorCarsPassed,(majorCarsPassed+minorCarsPassed),(majorCarThroughput/majorCarsPassed),(minorCarThroughput/minorCarsPassed),((majorCarThroughput+minorCarThroughput)/(majorCarsPassed+minorCarsPassed))]
		allInfo.append(currentcycleInfo)
		cyclesElapsed += 1
		print("Cycle " + str(cyclesElapsed))
		if cyclesElapsed >= 30:
			var s = ""
			for value in range(len(currentcycleInfo)):
				for cycle in range(len(allInfo)):
					s += str(allInfo[cycle][value])
					if cycle != len(allInfo) - 1:
						s += ","
				s += "\n"
			print(s)
			get_tree().paused = true
		else: # Reset simulation
			for instance in vehicleInstances:
				instance.free()
				vehicleInstances.erase(instance)
			
			elapsedTime = 0
			next_major_spawn_time = 0
			next_minor_spawn_time = 0
			
			for i in range(len(traffic_signals)):
				traffic_signals[i].initialize(control_config, traffic_signal_rotations[i], self, phaseList)
			
			majorCarsPassed = 0
			minorCarsPassed = 0
			majorCarsSpawned = 0
			minorCarsSpawned = 0
			majorCarThroughput = 0
			minorCarThroughput = 0
			
			cycleTime = 0
			isPeakTime = true
	
	# Check if traffic pattern needs to change
	if isPeakTime:
		if cycleTime >= peak_time_duration:
			# reset cycleTime and update isPeakTime
			cycleTime = 0
			isPeakTime = not isPeakTime
	else:
		if cycleTime >= off_peak_time_duration:
			# reset cycleTime and update isPeakTime
			cycleTime = 0
			isPeakTime = not isPeakTime
	
	# Check if it's time to spawn a major vehicle
	if elapsedTime >= next_major_spawn_time:
		var major_request = create_spawn_request(true)
		spawn_vehicle(major_request, true)
		majorCarsSpawned += 1
		#print("Major Cars Spawned: " + str(majorCarsSpawned) + "\nCars Spawned: " + str(majorCarsSpawned + minorCarsSpawned))
		schedule_next_major_spawn()  # Schedule the next major vehicle spawn
	
	# Check if it's time to spawn a minor vehicle
	if elapsedTime >= next_minor_spawn_time:
		var minor_request = create_spawn_request(false)
		minorCarsSpawned += 1
		#print("Minor Cars Spawned: " + str(minorCarsSpawned) + "\nCars Spawned: " + str(majorCarsSpawned + minorCarsSpawned))
		spawn_vehicle(minor_request, false)
		schedule_next_minor_spawn()  # Schedule the next minor vehicle spawn

func create_spawn_request(is_major_route: bool) -> SpawnRequest:
	# Create a new spawn request with random vehicle type and route
	var request = SpawnRequest.new()
	
	# Set the spawn time as the current elapsed time
	request.spawnTime = elapsedTime
	
	# Choose a random vehicle type based on probabilities
	request.vehicleType = choose_random_vehicle_type()
	
	# Choose a random route based on traffic type
	request.spawnPaths = choose_random_route(majorRoutes) if is_major_route else choose_random_route(minorRoutes)
	
	return request

func choose_random_vehicle_type() -> Enums.VehicleType:
		# Randomly select vehicle type based on probabilities
	var random_val = randf()  # Range up to the total cumulative probability
	if random_val < compactProb:
		return Enums.VehicleType.COMPACT
	#elif random_val < midsizeProb:
		#return Enums.VehicleType.MIDSIZE
	#elif random_val <= suvProb:
		#return Enums.VehicleType.SUV
	#else:
		#return Enums.VehicleType.TRUCK
	return Enums.VehicleType.COMPACT

func choose_random_route(routes: Array[Route]) -> Array[NodePath]:
	# Randomly select one of the available routes
	if routes.size() > 0:
		return routes[randi() % routes.size()].paths
	return []

func schedule_next_major_spawn():
	# Schedule the next spawn time for major traffic based on peak/off-peak
	var traffic_rate = majorTrafficRate[0] if is_peak_time() else majorTrafficRate[1]
	next_major_spawn_time = elapsedTime + randf_range(traffic_rate.x, traffic_rate.y)

func schedule_next_minor_spawn():
	# Schedule the next spawn time for minor traffic based on peak/off-peak
	var traffic_rate = minorTrafficRate[0] if is_peak_time() else minorTrafficRate[1]
	next_minor_spawn_time = elapsedTime + randf_range(traffic_rate.x, traffic_rate.y)

func spawn_vehicle(request: SpawnRequest, isMajor: bool):
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
	var path_node = get_node("/root/TestScene/" + str(request.spawnPaths[0]))
	if path_node:
		path_node.add_child(vehicle_instance)
	else:
		print("Error: Path2D node not found for vehicle spawn.")
	
	# Initialize the vehicle instance
	vehicle_instance.initialize(self, request.vehicleType, request.spawnPaths, 50, isMajor)
	
	# Add the vehicle instance to the array
	vehicleInstances.append(vehicle_instance)
	
	#print("Vehicle spawned and added to list. Total vehicles: ", vehicleInstances.size())

func is_peak_time() -> bool:
	# Check if current period is peak or off-peak time
	return isPeakTime

func _compare_spawn_times(a: SpawnRequest, b: SpawnRequest) -> int:
	return int(a.spawnTime - b.spawnTime)

func mph_to_mps(speed):
	#Convert speed from miles per hour to meters per second
	return speed * 1609.34 / 3600.0

func kmph_to_mps(speed):
	#Convert speed from meters per second to kilometers per hour
	return speed * 1000.0 / 3600.0

func set_current_path(instanceNode: Node, path: Path2D):
	instanceNode.get_parent().remove_child(instanceNode)
	path.add_child(instanceNode)


func removeInstance(instance: Node, isMajor: bool, throughput: float):
	vehicleInstances.erase(instance)
	if isMajor:
		majorCarsPassed += 1
		majorCarThroughput += throughput
		#print("Major Cars Passed: " + str(majorCarsPassed) + "\nCars Passed: " + str(majorCarsPassed + minorCarsPassed) + "\nThroughput: " + str(throughput) + "\nAverage Major Car Throughput: " + str(majorCarThroughput / majorCarsPassed))
	else:
		minorCarsPassed += 1
		minorCarThroughput += throughput
		#print("Minor Cars Passed: " + str(minorCarsPassed) + "\nCars Passed: " + str(majorCarsPassed + minorCarsPassed) + "\nThroughput: " + str(throughput) + "\nAverage Minor Car Throughput: " + str(minorCarThroughput / minorCarsPassed))
	
	#print("Average Throughput: " + str((majorCarThroughput + minorCarThroughput) / (majorCarsPassed + minorCarsPassed)))
