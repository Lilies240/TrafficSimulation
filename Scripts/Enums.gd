# Enums.gd
class_name Enums

enum VehicleType {
	NONE,
	COMPACT,
	MIDSIZE,
	SUV,
	TRUCK
}

enum TrafficLight {
	NONE,
	MAJORRED,
	MAJORYELLOW,
	MAJORGREEN,
	MINORRED,
	MINORYELLOW,
	MINORGREEN
}

enum ControlConfig {
	NONE,
	FIXEDINTERVAL,
	TIMEOFDAY,
	SENSOR
}
