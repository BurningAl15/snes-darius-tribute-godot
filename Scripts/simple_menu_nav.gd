extends Node2D

@export var menu_scene_path := "res://Scenes/MainMenu.tscn"

func _on_back_pressed():
	get_tree().change_scene_to_file(menu_scene_path)

func _on_retry_pressed():
	var path := RunState.last_level_path
	print("Path ", path)
	if path != "":
		get_tree().change_scene_to_file(path)
	else:
		# fallback por si aún no se guardó
		get_tree().reload_current_scene()
