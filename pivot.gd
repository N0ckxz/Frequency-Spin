extends Control # Or Node2D, depending on your node type

@export var radius: float = 300.0       # Distance from the pivot point
@export var angle_spacing: float = 20.0 # Spacing between items in degrees
@export var lerp_speed: float = 10.0    # Smoothness of the spin
@export var base_offset_angle: float = 0.0 # Adjusts the default starting view angle

var menu_items: Array[Node] = []
var current_index: int = 0
var target_rotation: float = 0.0

func _ready():
	# Gather all children
	menu_items = get_children()
	# Force the window to grab the mouse when the gameplay scene starts
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Position the items relative to the pivot
	for i in range(menu_items.size()):
		if menu_items[i] is Label:
			# Calculate the angle for each item so they line up sequentially
			var item_angle = deg_to_rad(i * angle_spacing + base_offset_angle)
			
			# Trigonometry to place them in a neat circle curve
			menu_items[i].position = Vector2(cos(item_angle), sin(item_angle)) * radius
			
			# Set the text pivot to its center so it rotates cleanly
			menu_items[i].pivot_offset = menu_items[i].size / 2.0
			
			# Orient the text to face outwards from the center pivot
			menu_items[i].rotation = item_angle

	# Set the initial camera target so the 0th item is dead center
	update_target_rotation()

func _process(delta):
	# Smoothly rotate the main pivot
	rotation = lerp_angle(rotation, target_rotation, lerp_speed * delta)
	
	# Highlight selected item, dim others
	for i in range(menu_items.size()):
		if i == current_index:
			menu_items[i].modulate = Color(1, 1, 1, 1) # Full bright
			menu_items[i].scale = lerp(menu_items[i].scale, Vector2(1.2, 1.2), 15 * delta) # Pop out slightly
		else:
			menu_items[i].modulate = Color(1, 1, 1, 0.3) # Faded out
			menu_items[i].scale = lerp(menu_items[i].scale, Vector2(1.0, 1.0), 15 * delta)

func _unhandled_input(event):
	if event.is_action_pressed("ui_down"):
		if current_index < menu_items.size() - 1:
			current_index += 1
			update_target_rotation()
			
	if event.is_action_pressed("ui_up"):
		if current_index > 0:
			current_index -= 1
			update_target_rotation()

	if event.is_action_pressed("ui_accept"):
		var selected_item = menu_items[current_index]
		
		if selected_item is Label:
			# .strip_edges() removes accidental spaces before or after the text
			var clean_text = selected_item.text.to_lower().strip_edges()
			print("Attempting to select: '", clean_text, "'") # This will print exactly what Godot sees
			
			match clean_text:
				"play", "start":
					print("Loading the actual game world now...")
					# Make sure this points to your NEW standalone gameplay scene file!
					get_tree().change_scene_to_file("res://main.tscn")
				
				"exit", "quit":
					print("SUCCESS: Quitting...")
					get_tree().quit()
			
	if event.is_action_pressed("ui_up"):
		if current_index > 0:
			current_index -= 1
			update_target_rotation()

func update_target_rotation():
	# Rotating the pivot negatively pulls the chosen item straight into the center line
	target_rotation = deg_to_rad(-current_index * angle_spacing)
