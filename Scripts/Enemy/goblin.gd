extends CharacterBody2D
class_name goblin

var speed = 100.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right = true

# --- Combat Variables ---
var health: int = 40
const DAMAGE_AMOUNT: int = 10
const STOMP_THRESHOLD: float = 30.0
var dead: bool = false
# ------------------------

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $GoblinHitBox
@onready var edge_checker: RayCast2D = $RayCast2D
@onready var hitbox: Node2D = $GoblinHitBox

# --- Attack cooldown ---
var can_attack: bool = true
const ATTACK_COOLDOWN: float = 2.0  # seconds between attacks

func _ready():
	if damage_zone:
		damage_zone.body_entered.connect(_on_goblin_hit_box_area_entered)
	anim.play("move")


func _physics_process(delta):
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor() and edge_checker and not edge_checker.is_colliding():
		flip()

	velocity.x = speed
	move_and_slide()


func flip():
	facing_right = !facing_right
	scale.x = abs(scale.x) * -1

	if facing_right:
		speed = abs(speed)
	else:
		speed = -abs(speed)

	# Only flip the Area2D (GoblinHitBox)
	if hitbox:
		hitbox.position.x = -hitbox.position.x


# Flip to face a global x position (player). Only flips if needed.
func face_point(target_global_x: float) -> void:
	if target_global_x > global_position.x and not facing_right:
		flip()
	elif target_global_x < global_position.x and facing_right:
		flip()


func _on_goblin_hit_box_area_entered(area: Area2D) -> void:
	var body = area.get_parent() if area.get_parent() != null else area
	if not body:
		return

	if body.is_in_group("player"):
		var player_body = body as CharacterBody2D
		var y_delta = position.y - player_body.position.y

		# --- CASE 1: STOMP (player lands on goblin) ---
		if y_delta > STOMP_THRESHOLD and player_body.velocity.y > 0:
			print("Stomp: Goblin Destroyed!")
			take_damage(health)
			if player_body.has_method("apply_stomp_bounce"):
				player_body.apply_stomp_bounce()
			return

		# --- CASE 2: SIDE COLLISION (goblin attacks player) ---
		if dead or not can_attack:
			return

		# Face player direction
		face_point(player_body.global_position.x)

		# Attack immediately
		print("Goblin attacking player from side.")
		_do_attack(player_body)


func _do_attack(player_body: CharacterBody2D) -> void:
	can_attack = false  # prevent immediate re-attacks

	anim.play("attack")
	if player_body.has_method("take_damage"):
		player_body.take_damage(DAMAGE_AMOUNT)

	# Resume movement after attack animation
	await get_tree().create_timer(0.3).timeout
	if not dead:
		anim.play("move")

	# Re-enable attacking after cooldown
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true


func take_damage(amount: int):
	if dead:
		return

	health -= amount
	velocity = Vector2.ZERO

	if health <= 0:
		_trigger_death()
	else:
		anim.play("Hurt")
		await get_tree().create_timer(0.3).timeout
		if not dead:
			anim.play("move")


func _trigger_death():
	dead = true
	set_collision_mask_value(1, false)
	set_physics_process(false)

	anim.play("Dead")
	await get_tree().create_timer(1.5).timeout
	queue_free()
