extends CharacterBody2D

@export var move_speed: float = 420.0
@export var clamp_margin: float = 16.0

@export var max_hp: int = 5
var hp: int

var screen_rect: Rect2

# --- Shooting (normal) ---
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.12
var shoot_timer: float = 0.0
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle2: Marker2D = $Muzzle2
var shoot_index: int = 0

# --- Charge shot ---
@export var charged_bullet_scene: PackedScene
@export var charge_time: float = 0.9
var charge: float = 0.0
var charging: bool = false

# --- Bomb ---
@export var bombs_max: int = 3
var bombs_left: int
@export var bomb_cooldown: float = 8.0
var bomb_cd: float = 0.0
@export var bomb_damage: int = 999 # daño “wipe” para enemigos normales

# --- Invulnerability ---
@export var invuln_time: float = 0.6
var invuln: float = 0.0

func _ready() -> void:
	hp = max_hp
	bombs_left = bombs_max
	screen_rect = get_viewport_rect()

func _physics_process(delta: float) -> void:
	# Timers
	shoot_timer = max(shoot_timer - delta, 0.0)
	invuln = max(invuln - delta, 0.0)
	bomb_cd = max(bomb_cd - delta, 0.0)

	# Movement
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vec = input_vec.normalized()

	velocity = input_vec * move_speed
	move_and_slide()

	# Clamp (con margen para que no se corte el sprite)
	global_position.x = clamp(global_position.x, clamp_margin, screen_rect.size.x - clamp_margin)
	global_position.y = clamp(global_position.y, clamp_margin, screen_rect.size.y - clamp_margin)

	# --- Normal shoot (solo si no estás cargando) ---
	if not charging and Input.is_action_pressed("shoot") and shoot_timer <= 0.0:
		shoot_timer = shoot_cooldown
		shoot()

	# --- Charge shot ---
	handle_charge(delta)

	# --- Bomb ---
	if Input.is_action_just_pressed("bomb"):
		try_bomb()

func handle_charge(delta: float) -> void:
	# Mantener presionado "charge" para cargar; al soltar dispara si llegó al umbral
	if Input.is_action_pressed("charge"):
		charging = true
		charge = min(charge + delta, charge_time)
	else:
		if charging:
			if charge >= charge_time:
				shoot_charged()
			charge = 0.0
			charging = false

func shoot() -> void:
	if bullet_scene == null:
		return

	shoot_index += 1
	shoot_index %= 2
	var dynamicMuzzle = muzzle if shoot_index == 0 else muzzle2
	var b := bullet_scene.instantiate()
	b.global_position = dynamicMuzzle.global_position
	get_tree().current_scene.add_child(b)

func shoot_charged() -> void:
	if charged_bullet_scene == null:
		return
	var b := charged_bullet_scene.instantiate()
	b.global_position = muzzle.global_position
	get_tree().current_scene.add_child(b)

func try_bomb() -> void:
	if bombs_left <= 0:
		return
	if bomb_cd > 0.0:
		return

	bombs_left -= 1
	bomb_cd = bomb_cooldown

	# 1) Limpia balas enemigas
	for n in get_tree().get_nodes_in_group("enemy_bullets"):
		if is_instance_valid(n):
			n.queue_free()

	# 2) Daño masivo a enemigos
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("hit"):
			e.hit(bomb_damage)

func get_charge_percent() -> float:
	if not charging:
		return 0.0
	return (charge / max(charge_time, 0.0001)) * 100.0

func take_damage(amount: int) -> void:
	if invuln > 0.0:
		return
	invuln = invuln_time
	hp -= amount

	# feedback rápido
	modulate = Color(1, 0.6, 0.6)
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree():
		modulate = Color.WHITE

	if hp <= 0:
		die()

func die() -> void:
	queue_free()