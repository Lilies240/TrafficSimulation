# Vehicle.gd
# Some assistance from ChatGPT
extends PathFollow2D

@export var vehicleType: Enums.VehicleType # the type of vehicle
@export var pixels_per_meter = 100

@export var length: float = 10 # the length of the vehicle
var max_speed: float = 100.0  # Maximum speed of the vehicle
var acceleration: float = 50.0  # Acceleration rate (speed increase per second)
var deceleration: float = 70.0  # Deceleration rate (speed decrease per second)
var stop_distance: float  # the distance it takes to come to a stop
var min_queue_distance: float # the distance it keeps behind a car when stopped

var current_speed: float = 0.0  # The vehicle's current speed
var current_speed_limit: float # the speed limit of the road
var spawner: Node # Variable to hold the reference to the spawner
var route: Array[Path2D] = [] # list of paths the vehicle follows
var current_path_index: int = 0 # the index of the current path being followed
@export var current_path: Path2D # the current path being followed
var state: String = "accelerating" #
var upcoming_light_color: String = "green"
var car_ahead: PathFollow2D = null # Reference to nearest car ahead, if any

var isMajor: bool  # Whether the car was spawned as major traffic
var throughput: float  # Time elapsed from spawn time

func initialize(spawner_reference: Node, vType: Enums.VehicleType, nodePaths: Array[NodePath], speedLimit: float, is_major: bool):
	spawner = spawner_reference
	vehicleType = vType
	current_speed_limit = mph_to_mps(current_speed_limit) * pixels_per_meter
	current_speed = current_speed_limit
	isMajor = is_major
	throughput = 0.0
	
	# Add each path in nodePaths to the route array
	for path in nodePaths:
		route.append(get_node("/root/TestScene/" + str(path)))
	#print(route)
	
	set_current_path(route[0]) # Set the initial path
	
	# Set the car's stats based on the vehicle type
	match vehicleType:
		Enums.VehicleType.COMPACT:
			length = 4.45 * pixels_per_meter
			max_speed = kmph_to_mps(195) * pixels_per_meter
			acceleration = 3.75 * pixels_per_meter
			deceleration = 7 * pixels_per_meter
			v_offset = 0.875 * pixels_per_meter
			stop_distance = 40 * pixels_per_meter
			min_queue_distance = 1.25 * pixels_per_meter
			#print("Compact car spawned")
		Enums.VehicleType.MIDSIZE:
			length = 4.75 * pixels_per_meter
			max_speed = kmph_to_mps(210) * pixels_per_meter
			acceleration = 3.25 * pixels_per_meter
			deceleration = 6 * pixels_per_meter
			v_offset = 0.95 * pixels_per_meter
			stop_distance = 45 * pixels_per_meter
			min_queue_distance = 1.25 * pixels_per_meter
			#print("Midsize car spawned")
		Enums.VehicleType.SUV:
			length = 5.05 * pixels_per_meter
			max_speed = kmph_to_mps(175) * pixels_per_meter
			acceleration = 2.75 * pixels_per_meter
			deceleration = 5.25 * pixels_per_meter
			v_offset = 1.025 * pixels_per_meter
			stop_distance = 52.5 * pixels_per_meter
			min_queue_distance = 1.75 * pixels_per_meter
			#print("SUV spawned")
		Enums.VehicleType.TRUCK:
			length = 22.5 * pixels_per_meter
			max_speed = kmph_to_mps(110) * pixels_per_meter
			acceleration = 1 * pixels_per_meter
			deceleration = 3.5 * pixels_per_meter
			v_offset = 1.25 * pixels_per_meter
			stop_distance = 105 * pixels_per_meter
			min_queue_distance = 2.5 * pixels_per_meter
			#print("Semi-truck spawned")
		_:
			print("No vehicle type declared!")

func set_current_path(path: Path2D):
	current_path = path
	spawner.set_current_path(self, path)
	progress = 0

func transition_to_next_path():
	current_path_index += 1
	if current_path_index < route.size():
		set_current_path(route[current_path_index])
	else:
		spawner.removeInstance(self, isMajor, throughput)
		queue_free() # Remove vehicle from scene

func kmph_to_mps(speed):
	if spawner:
		return spawner.kmph_to_mps(speed)

func mph_to_mps(speed):
	if spawner:
		return spawner.mph_to_mps(speed)

func _physics_process(delta):
	throughput += delta
	
	# Adjust speed based on state
	match state:
		"accelerating":
			accelerate(delta)
		"decelerating":
			decelerate(delta)
		"cruising":
			hold_speed(delta)
		"stopped":
			stop_vehicle()
	
	# Handle movement along the path
	progress += current_speed * delta
	
	# Check for intersecctions and cars ahead
	handle_intersection()
	
	# Move to next path if progress exceeds 1.0
	if progress >= current_path.curve.get_baked_length() - current_speed * delta:
		transition_to_next_path()

# Function to handle acceleration
func accelerate(delta):
	if current_speed < max_speed:
		current_speed += acceleration * delta
		if current_speed > max_speed:
			current_speed = max_speed

# Function to handle smooth deceleration
func decelerate(delta):
	if current_speed > 0:
		current_speed -= deceleration * delta
		if current_speed < 0:
			current_speed = 0

func hold_speed(delta):
	# Maintain current speed
	pass

func stop_vehicle():
	current_speed = 0

func check_upcoming_light():
	if is_intersection_ahead():
		upcoming_light_color = spawner.get_traffic_signal(current_path)

func is_intersection_ahead() -> bool:
	return current_path_index % 2 == 0

func handle_intersection():
	check_upcoming_light() # Update light color
	if is_intersection_ahead():
		var distance_to_intersection = calculate_distance_to_intersection()
		if (upcoming_light_color == "red" or upcoming_light_color == "yellow") and distance_to_intersection <= stop_distance:
			# Decelerate and prepare to stop
			print("\nCurrent road: " + str(current_path) + "\nCurrent state: " + str(state) + "\nIntersection Ahead: " + str(is_intersection_ahead()) + "\nUpcoming Light Color: " + str(upcoming_light_color) + "\nStopping Distance: " + str(stop_distance) + "\nCalculated Stopping Distance: " + str(current_speed ** 2 / (2 * deceleration)) + "\nDistance to intersection: " + str(distance_to_intersection) + "\nLength of road: " + str(current_path.get_curve().get_baked_length()) + "\nCurrent Progress: " + str(progress))
			state = "decelerating"
			if distance_to_intersection <= stop_distance:
				state = "stopped"
		elif upcoming_light_color == "green" or distance_to_intersection > stop_distance:
			# Accelerate or cruise
			state = "accelerating"
	else:
		# No intersection, continue normal behavior
		state = "accelerating"

func calculate_distance_to_intersection() -> float:
	# Calculate the distance to the end of the current path
	var total_length = current_path.get_curve().get_baked_length()
	return total_length - progress


# Conditions to determine if the car should accelerate
func should_accelerate() -> bool:
	# Accelerate if under the speed limit
	if current_speed < current_speed_limit and spawner.get_traffic_signal(current_path) == "green":
		return true
	return false

# Conditions to determine if the car should decelerate
func should_decelerate() -> bool:
	# Calculate required stopping distance for current speed
	var stopping_distance = (current_speed * current_speed) / (2 * deceleration) + stop_distance
	
	# Check for other vehicles ahead
	var vehiclesAhead = 0;
	for other_vehicle in spawner.vehicleInstances:
		if other_vehicle == self:
			continue
		
		# Check if on the same path and ahead
		if other_vehicle.current_path == self.current_path or (current_path_index + 1 >= 0 and current_path_index + 1 < route.size() and other_vehicle.current_path == route[current_path_index + 1]):
			var distance_to_other = other_vehicle.progress - self.progress - length / 2 - other_vehicle.length / 2
			
			if distance_to_other > 0:
				vehiclesAhead += 1;
				print("Distance: " + str(distance_to_other));

			# If within stopping range of another vehicle, start deceleration
			#if distance_to_other > 0 and distance_to_other <= stopping_distance:
				#return true
	if vehiclesAhead != 0:
		print("Vehicles ahead: " + str(vehiclesAhead));

	# Check traffic signals and adjust based on distance to intersections
	var distance_to_intersection = current_path.curve.get_baked_length() - progress
	print("Distance to intersection: " + str(distance_to_intersection))
	print("Stopping distance: " + str(stopping_distance))
	match spawner.get_traffic_signal(current_path):
		"yellow":
			if distance_to_intersection <= stopping_distance:
				return true
		"red":
			if distance_to_intersection <= stopping_distance:
				return true

	return false
