extends CharacterBody2D
class_name player

# --- PERSISTENCE PATHS ---
const LIVES_RESOURCE_PATH = "user://player_lives_state.res"
const LEVEL_1_PATH = "res://Scene/Levels/level_1.tscn"
const PLAYER_LIVES_RESOURCE_SCRIPT = "res://Scripts/PlayerLives.gd"
# -------------------------

const PAUSE_MENU_SCENE = preload("res://Scene/UI/pause_menu.tscn")
var pause_menu_instance: CanvasLayer = null

@export var speed: float = 250.0
@export var gravity: float = 2400.0
@export var jump_force: float = 900.0
@export var hurt_distance: float = 300.0
@export var dead_distance: float = 600.0
@export var hurt_duration: float = 0.5

var hit_count: int = 0
const MAX_HITS: int = 2
var fall_start_y: float = 0.0
var hurt_timer: float = 0.0
var can_jump: bool = true
var dead_state: bool = false
var dir_x: int = 0

const MAX_LIVES: int = 50   # canonical max hearts

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player_data: Resource
var current_level_path: String = ""    # initialized so is_empty() is safe

# New flag: true if no save file existed at startup (i.e. a true fresh launch)
var first_launch: bool = false

# internal: which scene to load after death animation finishes
var _pending_scene_to_load: String = ""


func _load_lives():
	var PlayerLivesClass = load(PLAYER_LIVES_RESOURCE_SCRIPT)

	# If no save exists, create one and mark this run as a fresh launch
	if FileAccess.file_exists(LIVES_RESOURCE_PATH):
		player_data = ResourceLoader.load(LIVES_RESOURCE_PATH)
		first_launch = false
	else:
		first_launch = true
		player_data = PlayerLivesClass.new()
		player_data.current_lives = MAX_LIVES
		ResourceSaver.save(player_data, LIVES_RESOURCE_PATH)


func _save_lives():
	ResourceSaver.save(player_data, LIVES_RESOURCE_PATH)


func _update_ui():
	var ui_text_edit = get_tree().current_scene.find_child("TextEdit", true)

	if is_instance_valid(ui_text_edit):
		ui_text_edit.text = str(player_data.current_lives)
	else:
		print("UI WARNING: TextEdit node not found in scene tree to update lives.")


# NEW DELAYED FUNCTION: Initialize path safely after 2 seconds
func _initialize_path_safely():
	# This runs after the delay, guaranteeing the scene metadata is available.
	var cs = get_tree().current_scene
	if is_instance_valid(cs) and cs.scene_file_path != "":
		current_level_path = cs.scene_file_path
		print("Path initialized successfully: " + current_level_path)

		# Only reset to max on a true fresh launch that starts at LEVEL_1_PATH
		if first_launch and current_level_path == LEVEL_1_PATH:
			# player_data is already created with MAX_LIVES in _load_lives when first_launch was true,
			# but ensure and save/update UI now that scene is available.
			player_data.current_lives = MAX_LIVES
			_save_lives()
			_update_ui()
			first_launch = false
			print("Fresh game start on Level 1: player lives set to MAX_LIVES.")
	else:
		current_level_path = LEVEL_1_PATH
		print("FATAL ERROR: Scene path failed to initialize after delay. Defaulting to Level 1 path.")


func _ready():
	fall_start_y = global_position.y
	anim.animation_finished.connect(_on_animation_finished)

	if anim.sprite_frames.has_animation("Dead"):
		anim.sprite_frames.set_animation_loop("Dead", false)

	# Load and update UI after all nodes are ready
	_load_lives()
	_update_ui()

	# Use a short timer to delay path initialization so scene metadata is ready
	get_tree().create_timer(2.0).timeout.connect(_initialize_path_safely)


func _physics_process(delta: float):
	if dead_state:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var was_on_floor := is_on_floor()

	if hurt_timer > 0:
		hurt_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if hurt_timer <= 0:
			anim.play("Idle")
		return

	# -------------------- INPUT HANDLING --------------------

	# Movement & gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir := 0
	if Input.is_action_pressed("Left"):
		dir -= 1
	if Input.is_action_pressed("Right"):
		dir += 1

	dir_x = dir
	velocity.x = float(dir) * speed

	if dir != 0:
		anim.flip_h = dir < 0

	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor() and can_jump:
		velocity.y = -jump_force
		can_jump = false
		anim.play("Jump")

	if Input.is_action_just_released("Jump"):
		can_jump = true

	move_and_slide()

	var now_on_floor := is_on_floor()

	if was_on_floor and not now_on_floor:
		fall_start_y = global_position.y

	if not was_on_floor and now_on_floor:
		var fall_distance := global_position.y - fall_start_y

		# If fall exceeds death threshold -> play death flow (reduces a heart)
		if fall_distance > dead_distance:
			print("Fall: Dead threshold exceeded. distance=", fall_distance)
			_trigger_death()
			velocity = Vector2.ZERO
			return

		# Else if fall exceeds hurt threshold -> play hurt animation but do NOT remove a heart
		elif fall_distance > hurt_distance:
			print("Fall: Hurt threshold exceeded. distance=", fall_distance)
			anim.play("Hurt")
			hurt_timer = hurt_duration
			velocity = Vector2.ZERO
			return

	if hurt_timer <= 0:
		if not now_on_floor:
			anim.play("Jump")
		else:
			if abs(velocity.x) > 0:
				anim.play("Run")
			elif anim.animation != "Idle":
				anim.play("Idle")


# --- DAMAGE and HITBOX LOGIC ---
func take_damage(amount: int):
	if dead_state:
		return

	hit_count += 1

	if hit_count >= MAX_HITS:
		_trigger_death()
	else:
		anim.play("Hurt")
		hurt_timer = hurt_duration
		velocity = Vector2.ZERO

		var knockback_force = 400
		var source = get_tree().get_first_node_in_group("enemy")
		if source:
			var knockback_dir = (global_position - source.global_position).normalized()
			velocity.x = knockback_dir.x * knockback_force
			velocity.y = -knockback_force / 2


func apply_stomp_bounce():
	velocity.y = -jump_force / 2


# --- DEATH LOGIC ---
func _trigger_death() -> void:
	if dead_state:
		return

	# Play death animation and mark dead_state immediately to stop player input
	anim.play("Dead")
	dead_state = true
	velocity = Vector2.ZERO

	# decrement lives and persist immediately so UI/save state is correct
	if player_data and player_data.current_lives > 0:
		player_data.current_lives -= 1
		_save_lives()
		_update_ui()

	# Decide which scene to load after death animation finishes
	var next_scene := LEVEL_1_PATH
	if player_data and player_data.current_lives > 0:
		# If player still has lives, reload the same level (use current_level_path if available)
		if current_level_path != "" and not current_level_path.is_empty():
			next_scene = current_level_path
		else:
			# final attempt to retrieve current scene path
			var cs = get_tree().current_scene
			if is_instance_valid(cs) and cs.scene_file_path != "":
				next_scene = cs.scene_file_path
			else:
				next_scene = LEVEL_1_PATH
	else:
		# No lives left -> restart from LEVEL_1_PATH (you already reset lives to MAX in your previous logic)
		next_scene = LEVEL_1_PATH

	# store pending scene so _on_animation_finished will change scene after animation
	_pending_scene_to_load = next_scene
	print("Death triggered — will load:", _pending_scene_to_load, "after Dead animation.")


# --- ANIMATION FINISHED FIX ---
func _on_animation_finished() -> void:
	var finished_anim_name = anim.animation
	# Only react when the Dead animation completes and we have a pending scene to load
	if finished_anim_name == "Dead" and _pending_scene_to_load != "":
		var to_load = _pending_scene_to_load
		_pending_scene_to_load = ""
		# Change scene now that the dead animation played fully
		get_tree().change_scene_to_file(to_load)


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused == false:
			get_tree().paused = true
			pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
			get_tree().root.add_child(pause_menu_instance)
		elif is_instance_valid(pause_menu_instance):
			pause_menu_instance._on_resume_pressed()
			

func save_current_level_path() -> void:
	# Ensure the player_data resource exists
	if player_data == null:
		return

	var cs = get_tree().current_scene
	if is_instance_valid(cs) and cs.scene_file_path != "":
		player_data.current_level_path = cs.scene_file_path
	else:
		# fallback if scene path not found
		player_data.current_level_path = LEVEL_1_PATH

	_save_lives()
	print("Player: Saved current level path:", player_data.current_level_path)
