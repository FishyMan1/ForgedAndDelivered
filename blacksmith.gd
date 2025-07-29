extends Node3D

# Export variables for easy configuration in the editor
@export var items_to_spawn: Array[PackedScene] = []
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 5.0

# References to child nodes
@onready var timer: Timer = $Timer
@onready var spawn_marker: Marker3D = $Marker3D

func _ready():
	# Connect the timer timeout signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Start the initial timer if we have items to spawn
	if items_to_spawn.size() > 0:
		_set_random_timer()
	else:
		print("Warning: No items to spawn assigned to Blacksmith!")

func _on_timer_timeout():
	spawn_random_item()
	_set_random_timer()

func spawn_random_item():
	# Check if we have items to spawn
	if items_to_spawn.size() == 0:
		print("No items available to spawn!")
		return
	
	# Pick a random item from the array
	var random_index = randi() % items_to_spawn.size()
	var item_scene = items_to_spawn[random_index]
	
	# Instance the item
	var item_instance = item_scene.instantiate()
	
	# Set the item's position to the marker's global position
	item_instance.global_position = spawn_marker.global_position
	
	# Add the item to the scene tree (not as child of blacksmith)
	get_tree().current_scene.add_child(item_instance)
	
	print("Blacksmith spawned: ", item_instance.name, " at position: ", spawn_marker.global_position)

func _set_random_timer():
	# Set a random wait time between min and max
	var random_time = randf_range(spawn_interval_min, spawn_interval_max)
	timer.wait_time = random_time
	timer.start()
	print("Next item will spawn in: ", random_time, " seconds")
