extends Path2D

@export var should_loop = true
@export var speed = 50.0 
@onready var path_follower: PathFollow2D = $PathFollow2D
var animation_player: AnimationPlayer = null # Initialized in _ready

func _ready():
	# Safely find the AnimationPlayer node.
	animation_player = path_follower.get_node_or_null("AnimationPlayer")

	if animation_player:
		# Scale animation speed based on exported 'speed' variable.
		animation_player.speed_scale = speed / 50.0 
		
		# Start playing the 'move' animation immediately.
		# This relies on the animation's loop mode (Loop or Ping-Pong) 
		# being set in the editor to make it infinite.
		animation_player.play("move")
	else:
		# If the AnimationPlayer is missing, log an error.
		push_error("ERROR: AnimationPlayer node not found as a child of PathFollow2D!")
