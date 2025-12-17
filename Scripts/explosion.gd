extends Node2D

@onready var anim: AnimatedSprite2D = get_node_or_null("Anim") as AnimatedSprite2D

func _ready() -> void:
	if anim == null:
		for c in get_children():
			if c is AnimatedSprite2D:
				anim = c
				break

	if anim == null:
		push_error("Explosion: No se encontró AnimatedSprite2D (Anim). Revisa Explosion.tscn")
		queue_free()
		return

	anim.animation_finished.connect(_on_finished)

	if anim.sprite_frames and anim.sprite_frames.has_animation("explode"):
		anim.play("explode")
	else:
		var names := anim.sprite_frames.get_animation_names()
		if names.size() > 0:
			anim.play(names[0])
		else:
			push_error("Explosion: No hay animaciones en SpriteFrames")
			queue_free()

func _on_finished() -> void:
	queue_free()
