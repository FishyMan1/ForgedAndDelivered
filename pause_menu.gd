extends Control

@onready var main = $"../../"

func _ready():
	main.pauseMenu()

func _on_resume_pressed() -> void:
	main.pauseMenu()


func _on_settings_pressed() -> void:
	get_tree()


func _on_quit_pressed() -> void:
	get_tree().quit()
