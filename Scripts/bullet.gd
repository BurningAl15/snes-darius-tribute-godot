extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage)
		queue_free()

func _physics_process(delta: float) -> void:
	global_position.x += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
