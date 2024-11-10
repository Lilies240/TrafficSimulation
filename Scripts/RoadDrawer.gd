# RoadDrawer.gd
extends Node2D

enum LineType {
	SOLID,
	DASHED
}

@export var path2d: Path2D
@export var line_width: float = 2.0
@export var line_color: Color = Color(1, 0, 0)
@export var line_type: LineType = LineType.SOLID
@export var dash_length: int = 0
@export var gap_length: int = 0

func _ready():
	_draw()

func _draw():
	if path2d and path2d.curve:
		# Get baked points from the curve
		var points = path2d.curve.get_baked_points()
		
		#Draw the path
		if line_type == LineType.DASHED:
			for i in range(points.size() - 1):
				if i % (dash_length + gap_length) < dash_length:
					draw_line(points[i], points[i + 1], line_color, line_width)
		else: #Draw a solid polyline
			draw_polyline(points, line_color, line_width)
