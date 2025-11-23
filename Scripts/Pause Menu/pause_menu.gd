extends CanvasLayer

const MAIN_MENU_SCENE := "res://Scene/UI/main_menu.tscn"
const LEVEL_1_PATH := "res://Scene/Levels/level_1.tscn"
const LIVES_RESOURCE_PATH := "user://player_lives_state.res"
const PLAYER_LIVES_SCRIPT := "res://Scripts/PlayerLives.gd"

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_pressed():
	queue_free()
	get_tree().paused = false

func _on_restart_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()

func _on_home_pressed():
	# Attempt 1: ask the Player instance to save itself (preferred)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("save_current_level_path"):
		player.save_current_level_path()
		print("pause_menu: asked Player to save current level path.")
	else:
		# Fallback: write the current scene path directly into the PlayerLives resource file.
		var cs = get_tree().current_scene
		var save_path := LEVEL_1_PATH
		if is_instance_valid(cs) and cs.scene_file_path != "":
			save_path = cs.scene_file_path

		var PL := preload(PLAYER_LIVES_SCRIPT)
		var res : Resource = null

		# If a user save file already exists, load it and update; otherwise create a new resource.
		if FileAccess.file_exists(LIVES_RESOURCE_PATH):
			res = ResourceLoader.load(LIVES_RESOURCE_PATH)
			if res == null:
				# If loading failed for any reason, create a fresh resource
				res = PL.new()
		else:
			res = PL.new()

		# Set the saved path and persist
		if res.has_variable("current_level_path"):
			res.set("current_level_path", save_path)
		else:
			# best-effort: try to set attribute directly
			res.current_level_path = save_path

		var err = ResourceSaver.save(res, LIVES_RESOURCE_PATH)
		if err == OK:
			print("pause_menu: fallback saved current level path:", save_path)
		else:
			push_error("pause_menu: failed to save PlayerLives resource. err=" + str(err))

	# Finally — unpause and go to main menu
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
