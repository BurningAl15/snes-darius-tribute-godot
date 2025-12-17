extends Area2D

@export var speed: float = 180.0
@export var max_hp: int = 2
@export var contact_damage: int = 1
var hp: int

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position.x -= speed * delta

func hit(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		area.get_parent().take_damage(contact_damage) # parent = Player
		queue_free() # opcional: se destruye al chocar

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func die() -> void:
	var ex := preload("res://Prefabs/Explosion.tscn").instantiate()
	ex.global_position = global_position
	get_tree().current_scene.add_child(ex)
	queue_free()
