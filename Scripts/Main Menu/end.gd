extends Control

const MAIN_MENU_SCENE := "res://Scene/UI/main_menu.tscn"

func _unhandled_input(event):
	# Only respond to real presses (keys or mouse buttons)
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		var err := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		if err != OK:
			print("Error changing scene to Main Menu: ", err)
