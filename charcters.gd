extends Node3D
signal item_delivered(item: DeliveryItem, goal: DeliveryGoal)
signal all_items_delivered

@export var auto_move_items: bool = true
@export var item_speed: float = 100.0

var active_items: Array[DeliveryItem] = []
var goals: Array[DeliveryGoal] = []
var delivered_items: Array[DeliveryItem] = []

func _ready():
	# Connect to item signals when they're added
	pass

func _process(delta):
	if auto_move_items:
		update_items(delta)

# Add an item to the delivery system
func add_item(item: DeliveryItem):
	if not item.is_connected("delivered", _on_item_delivered):
		item.delivered.connect(_on_item_delivered)
	
	active_items.append(item)
	add_child(item)

# Add a goal to the system
func add_goal(goal: DeliveryGoal):
	goals.append(goal)
	add_child(goal)

# Create and add an item with specified properties
func create_item(item_position: Vector2, goal_id: String, item_texture: Texture2D = null) -> DeliveryItem:
	var item = DeliveryItem.new()
	item.position = item_position
	item.target_goal_id = goal_id
	item.speed = item_speed
	
	if item_texture:
		item.texture = item_texture
	
	add_item(item)
	return item

# Create and add a goal with specified properties
func create_goal(goal_position: Vector2, goal_id: String, detection_radius: float = 30.0, goal_texture: Texture2D = null) -> DeliveryGoal:
	var goal = DeliveryGoal.new()
	goal.position = goal_position
	goal.goal_id = goal_id
	goal.detection_radius = detection_radius
	
	if goal_texture:
		goal.texture = goal_texture
	
	add_goal(goal)
	return goal

# Update all active items
func update_items(delta: float):
	for item in active_items:
		if is_instance_valid(item):
			var target_goal = find_goal_by_id(item.target_goal_id)
			if target_goal:
				item.move_towards_goal(target_goal, delta)

# Find a goal by its ID
func find_goal_by_id(goal_id: String) -> DeliveryGoal:
	for goal in goals:
		if goal.goal_id == goal_id:
			return goal
	return null

# Handle item delivery
func _on_item_delivered(item: DeliveryItem):
	var goal = find_goal_by_id(item.target_goal_id)
	
	# Remove from active items
	active_items.erase(item)
	
	# Add to delivered items with timestamp
	delivered_items.append(item)
	
	# Emit signals
	item_delivered.emit(item, goal)
	
	if active_items.is_empty():
		all_items_delivered.emit()
	
	print("Item ", item.name, " delivered to goal ", item.target_goal_id)

# Get active items count
func get_active_items_count() -> int:
	return active_items.size()

# Get delivered items count
func get_delivered_items_count() -> int:
	return delivered_items.size()

# Remove all delivered items from scene
func clear_delivered_items():
	for item in delivered_items:
		if is_instance_valid(item):
			item.queue_free()
	delivered_items.clear()


# ================================
# DeliveryItem.gd
# Individual item that can be delivered to goals
class_name DeliveryItem
extends Sprite3D

signal delivered(item: DeliveryItem)

@export var target_goal_id: String = ""
@export var speed: float = 100.0
@export var auto_remove_on_delivery: bool = true

var is_delivered: bool = false
var delivery_time: float

func _ready():
	# Set default texture if none provided
	if not texture:
		texture = create_default_item_texture()

func move_towards_goal(goal: DeliveryGoal, delta: float):
	if is_delivered or not goal:
		return
	
	var direction = (goal.global_position - global_position).normalized()
	var movement = direction * speed * delta
	
	global_position += movement
	
	# Check if reached goal
	var distance = global_position.distance_to(goal.global_position)
	if distance <= goal.detection_radius:
		deliver_to_goal(goal)

func deliver_to_goal(goal: DeliveryGoal):
	if is_delivered:
		return
	
	is_delivered = true
	delivery_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	
	delivered.emit(self)
	
	if auto_remove_on_delivery:
		# Add removal effect
		create_delivery_effect()
		queue_free()

func create_delivery_effect():
	# Simple fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func create_default_item_texture() -> ImageTexture:
	var image = Image.create(20, 20, false, Image.FORMAT_RGB8)
	image.fill(Color.BLUE)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture


# ================================
# DeliveryGoal.gd
# Goal areas where items can be delivered
class_name DeliveryGoal
extends Area3D

@export var goal_id: String = ""
@export var detection_radius: float = 30.0
@export var show_detection_area: bool = true

var sprite: Sprite3D
var collision_shape: CollisionShape3D

func _ready():
	setup_goal()

func setup_goal():
	# Create sprite
	sprite = Sprite3D.new()
	sprite.texture = create_default_goal_texture()
	add_child(sprite)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	var circle_shape = CircleShape3D.new()
	circle_shape.radius = detection_radius
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)

func _draw():
	if show_detection_area:
		draw_circle(Vector3.ZERO, detection_radius, Color(1, 1, 0, 0.2))
		draw_arc(Vector3.ZERO, detection_radius, 0, TAU, 32, Color.YELLOW, 2.0)

func _on_body_entered(body):
	if body is DeliveryItem:
		body.deliver_to_goal(self)

func create_default_goal_texture() -> ImageTexture:
	var image = Image.create(40, 40, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

# Set custom texture
func set_texture(new_texture: Texture2D):
	if sprite:
		sprite.texture = new_texture
