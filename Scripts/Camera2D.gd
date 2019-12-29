extends Node

onready var parent = $'../'

var moveSpeed = 0.6

func _ready():
	parent.connect("dungeonGenerated", self, "_on_dungeonGeneration")
	set_process(true)
	
func _process(delta):
	var movement = Vector2()
	
	if Input.is_action_pressed("ui_up"):
		movement.y -= moveSpeed
	if Input.is_action_pressed("ui_down"):
		movement.y += moveSpeed
	if Input.is_action_pressed("ui_left"):
		movement.x -= moveSpeed
	if Input.is_action_pressed("ui_right"):
		movement.x += moveSpeed
	
	self.global_position += movement

func _on_dungeonGeneration():
	var center := Vector2()
	
	for r in parent.currentDungeon.rooms:
		center += Vector2(r.x, r.y) / len(parent.currentDungeon.rooms)
		
	self.global_position = center