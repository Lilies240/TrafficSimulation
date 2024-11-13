# TrafficSignal.gd
extends Node2D

@export var peakIntervals: Array[float]  # the durations of each phase during peak time in a time of day system
@export var offPeakIntervals: Array[float]  # the durations of each phase during off-peak time in a time of day system
@export var fixedIntervals: Array[float] # the durations of each phase when using a fixed interval system
@export var configuration: Enums.ControlConfig
@export var phaseTextures: Array[Texture]
var phases: Array 

@export var currentPhase: Array[Enums.TrafficLight] = [Enums.TrafficLight.MAJORRED, Enums.TrafficLight.MINORRED]  # Initial phases (major red, minor red)

var manager: Node  # Reference to the spawner
@export var childSprite: Node

var currentPhaseTexture: Texture
var phaseIndex: int = 0
var timer: Timer
var sensor_mode_cycle: int = 0  # Keeps track of the cycle during sensor mode

func initialize(config: Enums.ControlConfig, rotation: float, manager_reference: Node, phaseList: Array):
	configuration = config
	self.rotation_degrees = rotation
	manager = manager_reference
	phases = phaseList
	
	# Create a timer to handle phase transitions
	timer = Timer.new()
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", self._on_timeout)
	_on_timeout()  # Start the initial phase

func _ready():
	pass

func _process(delta):
	if timer:
		pass
		#print(timer.time_left)

func _on_timeout():
	print("Timeout triggered, changing phase")
	# Cycle phases based on configuration
	match configuration:
		Enums.ControlConfig.FIXEDINTERVAL:
			change_phase(fixed_interval_duration())
		Enums.ControlConfig.TIMEOFDAY:
			change_phase(time_of_day_duration())
		Enums.ControlConfig.SENSOR:
			handle_sensor_mode()

func change_phase(duration: float):
	print("Next phase in: " + str(duration))
	# Update phase and set timer for next phase change
	currentPhase[0] = phases[phaseIndex % phases.size()] as Enums.TrafficLight  # Major phase
	currentPhase[1] = phases[(phaseIndex + 1) % phases.size()] as Enums.TrafficLight # Minor phase
	
	# Update phase texture to match current phase
	match currentPhase[0]:
		Enums.TrafficLight.MAJORRED:
			match currentPhase[1]:
				Enums.TrafficLight.MINORRED:
					currentPhaseTexture = phaseTextures[0]
				Enums.TrafficLight.MINORYELLOW:
					currentPhaseTexture = phaseTextures[4]
				Enums.TrafficLight.MINORGREEN:
					currentPhaseTexture = phaseTextures[3]
				_:
					pass
		Enums.TrafficLight.MAJORYELLOW:
			currentPhaseTexture = phaseTextures[2]
		Enums.TrafficLight.MAJORGREEN:
			currentPhaseTexture = phaseTextures[1]
		_:
			print("Unexpected traffic signal config")
	childSprite.texture = currentPhaseTexture
	
	timer.start(duration)
	
	# Increment the phase
	phaseIndex = (phaseIndex + 2) % phases.size()  # Increment by 2 to skip to the next pair (major, minor)

func fixed_interval_duration() -> float:
	# Use fixed interval for all phases
	return fixedIntervals[(phaseIndex / 2) % fixedIntervals.size()]

func time_of_day_duration() -> float:
	# Different intervals for peak vs off-peak hours
	var is_peak_time = check_peak_time()
	if is_peak_time:
		print("Peak Time of day duration: " + str(peakIntervals[phaseIndex % peakIntervals.size()]))
		return peakIntervals[phaseIndex/2 % peakIntervals.size()]
	else:
		print("Off-Peak Time of day duration: " + str(offPeakIntervals[phaseIndex % offPeakIntervals.size()]))
		return offPeakIntervals[phaseIndex/2 % offPeakIntervals.size()]

func handle_sensor_mode():
	# Handle the sensor-based phase logic
	if sensor_mode_cycle == 0:
		# Initial state: MAJORGREEN and MINORRED
		currentPhase[0] = Enums.TrafficLight.MAJORGREEN
		currentPhase[1] = Enums.TrafficLight.MINORRED
		currentPhaseTexture = phaseTextures[1]  # Use the texture for MAJORGREEN
		timer.start(peakIntervals[0])  # Duration of MAJORGREEN and MINORRED
		sensor_mode_cycle = 1  # Move to the next phase once the timer ends
	elif sensor_mode_cycle == 1:
		# Transition to MAJORYELLOW and MINORRED
		currentPhase[0] = Enums.TrafficLight.MAJORYELLOW
		currentPhase[1] = Enums.TrafficLight.MINORRED
		currentPhaseTexture = phaseTextures[2]  # Use the texture for MAJORYELLOW
		timer.start(peakIntervals[2])  # Duration of MAJORYELLOW and MINORRED
		sensor_mode_cycle = 2  # Move to the next phase once the timer ends
	elif sensor_mode_cycle == 2:
		# Transition to MAJORRED and MINORRED
		currentPhase[0] = Enums.TrafficLight.MAJORRED
		currentPhase[1] = Enums.TrafficLight.MINORRED
		currentPhaseTexture = phaseTextures[0]  # Use the texture for MAJORRED
		timer.start(peakIntervals[3])  # Duration of MAJORRED and MINORRED
		sensor_mode_cycle = 3  # Move to the next phase once the timer ends
	elif sensor_mode_cycle == 3:
		# Transition to MAJORRED and MINORGREEN
		currentPhase[0] = Enums.TrafficLight.MAJORRED
		currentPhase[1] = Enums.TrafficLight.MINORGREEN
		currentPhaseTexture = phaseTextures[3]  # Use the texture for MINORGREEN
		timer.start(peakIntervals[5])  # Duration of MAJORRED and MINORGREEN
		sensor_mode_cycle = 0  # Once all phases are completed, reset to start (MAJORGREEN, MINORRED)

func check_peak_time() -> bool:
	return manager.is_peak_time()

func check_minor_traffic() -> bool:
	# Placeholder to detect minor road traffic
	return false  # Replace with actual traffic sensor check
