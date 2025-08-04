extends Control

func _ready() -> void:
	visible = false
	# Set the process mode so the pause menu can still receive input when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if get_tree().paused:
			resume_game()
			
		else:
			pause_game()

func pause_game() -> void:
	get_tree().paused = true
	visible = true

func resume_game() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	resume_game()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	# Example: Show settings submenu
	# Make sure SettingsSubMenu exists or replace with your actual settings logic
	if has_node("SettingsSubMenu"):
		$SettingsSubMenu.visible = true
	else:
		print("Settings pressed - implement your settings menu here")
