# Vehicle.gd
# Some assistance from ChatGPT
extends PathFollow2D

@export var vehicleType: Enums.VehicleType # the type of vehicle
@export var pixels_per_meter = 100
@export var reactionTime: float = 0.5  # Time it takes for the driver to react

var stoppingDistance: float  # the distance it takes to come to a stop
var stoppedDistance: float # the distance it keeps behind a car when stopped
var followingDistance: float # the time in seconds that vehicle tries to keep behind the vehicle in front of it 

@export var length: float = 10 # the length of the vehicle
var max_speed: float = 100.0  # Maximum speed of the vehicle
var acceleration: float = 50.0  # Acceleration rate (speed increase per second)
var deceleration: float = 70.0  # Deceleration rate (speed decrease per second)
var current_speed: float = 0.0  # The vehicle's current speed

var spawner: Node # Variable to hold the reference to the spawner
var route: Array[Path2D] # list of paths the vehicle follows

func initialize(spawner_reference: Node, vType: Enums.VehicleType):
	spawner = spawner_reference
	vehicleType = vType
	
	# Set the car's stats based on the vehicle type
	match vehicleType:
		Enums.VehicleType.COMPACT:
			length = 4.45 * pixels_per_meter
			max_speed = kmph_to_mps(195) * pixels_per_meter
			acceleration = 3.75 * pixels_per_meter
			deceleration = 7 * pixels_per_meter
			v_offset = 0.875 * pixels_per_meter
			stoppingDistance = 40 * pixels_per_meter
			stoppedDistance = 1.25 * pixels_per_meter
			followingDistance = 2.5
			print("Compact car spawned")
		Enums.VehicleType.MIDSIZE:
			length = 4.75 * pixels_per_meter
			max_speed = kmph_to_mps(210) * pixels_per_meter
			acceleration = 3.25 * pixels_per_meter
			deceleration = 6 * pixels_per_meter
			v_offset = 0.95 * pixels_per_meter
			stoppingDistance = 45 * pixels_per_meter
			stoppedDistance = 1.25 * pixels_per_meter
			followingDistance = 2.5
			print("Midsize car spawned")
		Enums.VehicleType.SUV:
			length = 5.05 * pixels_per_meter
			max_speed = kmph_to_mps(175) * pixels_per_meter
			acceleration = 2.75 * pixels_per_meter
			deceleration = 5.25 * pixels_per_meter
			v_offset = 1.025 * pixels_per_meter
			stoppingDistance = 52.5 * pixels_per_meter
			stoppedDistance = 1.75 * pixels_per_meter
			followingDistance = 3.5
			print("SUV spawned")
		Enums.VehicleType.TRUCK:
			length = 22.5 * pixels_per_meter
			max_speed = kmph_to_mps(110) * pixels_per_meter
			acceleration = 1 * pixels_per_meter
			deceleration = 3.5 * pixels_per_meter
			v_offset = 1.25 * pixels_per_meter
			stoppingDistance = 105 * pixels_per_meter
			stoppedDistance = 2.5 * pixels_per_meter
			followingDistance = 5
			print("Semi-truck spawned")
		_:
			print("No vehicle type declared!")
	

func kmph_to_mps(speed):
	if spawner:
		return spawner.kmph_to_mps(speed)

func mph_to_mps(speed):
	if spawner:
		return spawner.mph_to_mps(speed)

func _ready():
	pass

func _process(delta):
	# Handle acceleration and deceleration
	if should_decelerate():
		decelerate(delta)
	elif should_accelerate():
		accelerate(delta)
	
	
	# Move the vehicle along the path
	progress += current_speed * delta
	
	# Move to next path if progress exceeds 1.0
	if progress_ratio > 1.0:
		pass

# Function to handle acceleration
func accelerate(delta):
	current_speed += acceleration * delta
	if current_speed > max_speed:
		current_speed = max_speed

# Function to handle deceleration
func decelerate(delta):
	current_speed -= deceleration * delta
	if current_speed < 0:
		current_speed = 0

# Conditions to determine if the car should accelerate
func should_accelerate() -> bool:
	# Accelerate if under the speed limit
	return true

# Conditions to determine if the car should decelerate
func should_decelerate() -> bool:
	# Check for other vehicles on the road ahead
	for other_vehicle in spawner.vehicleInstances:
		# Exclude self
		if other_vehicle == self:
			continue
		
		# Check if other vehicle is on current path
		if other_vehicle.path in route:
			# Calculate distance along path
			var distance_to_other = other_vehicle.progress - self.progress - length/2 - other_vehicle.length/2
			
			# Check if other car is behind them
			if distance_to_other < 0:
				continue
			# Check if within safe stopping distance
			elif distance_to_other < stoppingDistance + stoppedDistance:
				return true
			# Check if within safe following distance
			elif distance_to_other < current_speed * followingDistance:
				return true
	
	return false
