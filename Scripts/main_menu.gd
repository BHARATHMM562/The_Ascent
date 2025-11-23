extends Control

# Reference the main buttons container using its Unique Name
@onready var main_buttons_container = %VBoxContainer

# Reference the OPTIONS PANEL container using its Unique Name
@onready var options_panel = %Options

# Reference the CheckButton for Mute/Unmute (correctly identified as CheckButton/Control type)
# FIX: The AudioControl node is a sibling of Scale_control, not its parent.
# Path: Options -> HBoxContainer -> Scale_control
@onready var mute_button: CheckButton = options_panel.get_node("HBoxContainer/Scale_control")

# --- AUDIO STATE ---
var music_bus_idx: int = -1

# --- PLAYER LIVES RESET LOGIC ---
const LIVES_RESOURCE_PATH = "user://player_lives_state.res"
const PLAYER_LIVES_RESOURCE_SCRIPT = "res://Scripts/PlayerLives.gd"
const MAX_LIVES: int = 50


func _ready() -> void:
	# 1. Ensure the options panel is hidden when the scene starts
	options_panel.hide()

	# 2. Initialize Audio Bus
	music_bus_idx = AudioServer.get_bus_index("Music")
	
	if music_bus_idx == -1:
		push_warning("Audio Bus 'Music' not found. Please ensure it is set up in Project Settings.")
		return
	
	if is_instance_valid(mute_button):
		# Set the CheckButton's initial state based on current volume (Muted if volume is minimum)
		var is_muted = AudioServer.get_bus_volume_db(music_bus_idx) <= -70.0
		mute_button.button_pressed = !is_muted # Toggled ON means sound ON (not muted)
		
		# Connect the signal so volume updates when the button is toggled
		# We connect to toggled(bool) because it's a CheckButton
		mute_button.toggled.connect(_on_mute_button_toggled)


# --- MAIN BUTTON LOGIC ---

func _on_NewGame_pressed() -> void:
	# ✅ Reset hearts to MAX before starting a new game
	var PlayerLivesClass = load(PLAYER_LIVES_RESOURCE_SCRIPT)
	var lives_res
	
	if FileAccess.file_exists(LIVES_RESOURCE_PATH):
		lives_res = ResourceLoader.load(LIVES_RESOURCE_PATH)
	else:
		lives_res = PlayerLivesClass.new()
	
	lives_res.current_lives = MAX_LIVES
	var err = ResourceSaver.save(lives_res, LIVES_RESOURCE_PATH)
	
	if err != OK:
		push_error("Failed to reset player hearts on New Game: " + str(err))
	else:
		print("Player hearts reset to MAX (" + str(MAX_LIVES) + ") for New Game.")

	# Starts a new game from the first level.
	get_tree().change_scene_to_file("res://Scene/Levels/level_1.tscn")


func _on_exit_pressed() -> void:
	# Quits the game.
	get_tree().quit()


# --- OPTIONS PANEL LOGIC ---

func _on_back_pressed() -> void:
	# When "Back" is pressed:
	# 1. Hide the options panel.
	options_panel.hide()
	# 2. Show the main game buttons container.
	main_buttons_container.show()


func _on_options_pressed() -> void:
	# This is connected to the 'Options' Button pressed() signal.
	# 1. Hide the main game buttons container.
	main_buttons_container.hide()
	# 2. Show the options panel.
	options_panel.show()


# --- AUDIO CONTROL FUNCTION (MUTE/UNMUTE) ---

const MUTE_DB: float = -80.0
const UNMUTE_DB: float = 0.0

func _on_mute_button_toggled(button_is_pressed: bool):
	# button_is_pressed is TRUE when the CheckButton is checked (Unmuted)
	
	if music_bus_idx != -1:
		var target_db = MUTE_DB
		if button_is_pressed:
			target_db = UNMUTE_DB
			
		AudioServer.set_bus_volume_db(music_bus_idx, target_db)
