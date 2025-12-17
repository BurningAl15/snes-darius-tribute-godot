extends Area2D

@export var speed := 140.0
@export var max_hp := 3
@export var bullet_scene: PackedScene
@export var shoot_interval := 1.2
@export var contact_damage := 1

var hp := 0
@onready var shoot_timer: Timer = $ShootTimer

func _ready():
	hp = max_hp
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)

	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(shoot)
	shoot_timer.start()

func _physics_process(delta):
	global_position.x -= speed * delta

func hit(dmg: int):
	hp -= dmg
	if hp <= 0:
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		area.get_parent().take_damage(contact_damage)
		die()

func shoot():
	if bullet_scene == null: return
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(-10, 0)
	get_tree().current_scene.add_child(b)

func die() -> void:
	var ex := preload("res://Prefabs/Explosion.tscn").instantiate()
	ex.global_position = global_position
	get_tree().current_scene.add_child(ex)
	queue_free()
