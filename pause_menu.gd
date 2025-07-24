extends Control


func _ready() -> void:
	visible = false
	# Optional: Connect signals programmatically
	$Resume.pressed.connect(_on_resume_pressed)
	$Settings.pressed.connect(_on_settings_pressed)
	$Exit.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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
	$SettingsSubMenu.visible = true
