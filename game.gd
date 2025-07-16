extends Node3D

@onready var pause_menu = $"Player/Pause menu"
var paused = false

func _ready():
	pause_menu.hide()
	Engine.time_scale = 1 
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

func pauseMenu():
	if paused: 
		pause_menu.hide()
		Engine.time_scale = 1 
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		pause_menu.show()
		Engine.time_scale = 0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = !paused
