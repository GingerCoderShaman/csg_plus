@tool
extends MeshInstance2D


func set_area(side1:Vector2, side2:Vector2):
	position = (side1+side2) / 2 # get center
	scale = (side1-side2).abs() #get distance from center
