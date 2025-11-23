extends Area2D

# This export variable lets you set the next level in the editor.
@export var next_level_path: String = ""

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Play the portal animation if it exists.
	if anim.sprite_frames.has_animation("portal"):
		anim.play("portal")
	else:
		# Plays the default animation if "portal" is missing.
		anim.play()


func _on_portal_body_entered(body: Node2D) -> void:
	# This function is now responsible for saving the game state and changing the level.
	if body.name == "Player":
		
		# Now, we change the scene to the path specified in the editor.
		get_tree().change_scene_to_file(next_level_path)
