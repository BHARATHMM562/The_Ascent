extends Node2D

# This variable will hold a reference to your Player node
@onready var player_node = $Player

func _ready():
	# Set the player's position to a specific starting coordinate when the level loads.
	# THIS LINE IS CRITICAL. Make sure these coordinates are far away from the portal.
	player_node.global_position = Vector2(168, 440)


func _on_portal_body_entered(body: Node2D) -> void:
	# Now, we check if the body's name is "Player" to see if it's our character.
	if body.name == "Player":
		get_tree().change_scene_to_file("res://Scene/Levels/level_6.tscn")
