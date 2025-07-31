extends CharacterBody3D

# Movement variables
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var bob_freq: float = 2.0
@export var bob_amp: float = 0.08

# Pickup variables
@export var pickup_range: float = 3.0
@export var pickup_force: float = 10.0

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var t_bob: float = 0.0

# Pickup system
var picked_object: RigidBody3D = null
var pickup_joint: Generic6DOFJoint3D = null

# References to child nodes
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var pickup_ray: RayCast3D = $Head/Camera3D/PickUp

func _ready():
	# Capture the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup pickup raycast
	pickup_ray.target_position = Vector3(0, 0, -pickup_range)
	pickup_ray.enabled = true

func _unhandled_input(event):
	# Handle mouse look
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle movement input
	var input_dir = Vector2()
	
	if Input.is_action_pressed("left"):
		input_dir.x -= 1
	if Input.is_action_pressed("right"):
		input_dir.x += 1
	if Input.is_action_pressed("up"):
		input_dir.y += 1
	if Input.is_action_pressed("down"):
		input_dir.y -= 1
	
	input_dir = input_dir.normalized()
	
	# Determine current speed (walk or sprint)
	var current_speed = walk_speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	
	# Pickup system
	if Input.is_action_just_pressed("pickup"):
		if picked_object == null:
			pickup_object()
		else:
			drop_object()
	
	if Input.is_action_just_released("pickup"):
		if picked_object != null:
			drop_object()
	
	# Get the forward and right directions relative to where the head is looking
	var direction = Vector3()
	if input_dir != Vector2.ZERO:
		direction = (head.transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Head bobbing effect
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# Update picked object position if holding one
	if picked_object != null and pickup_joint != null:
		update_pickup_position()
	
	# Move the character
	move_and_slide()

func pickup_object():
	if pickup_ray.is_colliding():
		var collider = pickup_ray.get_collider()
		
		# Check if the collided object is a RigidBody3D
		if collider is RigidBody3D:
			picked_object = collider
			
			# Disable gravity on the picked object
			picked_object.gravity_scale = 0.0
			picked_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			picked_object.freeze = true
			
			# Create a joint to hold the object
			pickup_joint = Generic6DOFJoint3D.new()
			get_tree().current_scene.add_child(pickup_joint)
			
			# Create a temporary body for the joint anchor
			var anchor_body = StaticBody3D.new()
			head.add_child(anchor_body)
			
			# Set up the joint
			pickup_joint.node_a = anchor_body.get_path()
			pickup_joint.node_b = picked_object.get_path()
			
			# Position the anchor at the raycast end point
			var pickup_position = pickup_ray.get_collision_point()
			var local_pickup_pos = head.to_local(pickup_position)
			anchor_body.position = local_pickup_pos
			
			print("Picked up: ", picked_object.name)

func drop_object():
	if picked_object != null:
		# Re-enable physics on the object
		picked_object.freeze = false
		picked_object.gravity_scale = 1.0
		picked_object.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		
		# Add a small impulse in the forward direction
		var forward_impulse = -head.transform.basis.z * 2.0
		picked_object.apply_central_impulse(forward_impulse)
		
		# Clean up the joint
		if pickup_joint != null:
			# Remove the anchor body
			for child in head.get_children():
				if child is StaticBody3D:
					child.queue_free()
					break
			
			pickup_joint.queue_free()
			pickup_joint = null
		
		print("Dropped: ", picked_object.name)
		picked_object = null

func update_pickup_position():
	# Keep the object at the end of the raycast
	if picked_object != null:
		var target_position = head.global_position + (-head.transform.basis.z * pickup_range)
		
		# Smoothly move the object to the target position
		var current_pos = picked_object.global_position
		var new_pos = current_pos.lerp(target_position, pickup_force * get_physics_process_delta_time())
		picked_object.global_position = new_pos

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func _input(event):
	# Toggle mouse capture with Escape key
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Toggle fullscreen
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
