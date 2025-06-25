extends Control

@onready var main = $"../../"


func _on_resume_pressed() -> void:
	main.pauseMenu()


func _on_settings_pressed() -> void:
	print("Settings pressed.")


func _on_quit_pressed() -> void:
	get_tree().quit()
