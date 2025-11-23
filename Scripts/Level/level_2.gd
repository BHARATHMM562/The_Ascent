extends Node2D

# This variable will hold a reference to your Player node
@onready var player_node = $Player

func _ready():
	# Set the player's position to the starting coordinate for Level 2.
	# YOU MUST CHANGE these coordinates to your level's starting X and Y.
	player_node.global_position = Vector2(-700, 920)


func _on_portal_body_entered(body: Node2D) -> void:
	# Now, we check if the body's name is "Player" to see if it's our character.
	if body.name == "Player":
		# When the player enters the portal, go back to the first level.
		get_tree().change_scene_to_file("res://Scene/Levels/level_3.tscn")
