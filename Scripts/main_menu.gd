extends Node2D

func _on_easy_pressed(): get_tree().change_scene_to_file("res://Scenes/Level_Easy.tscn")
func _on_normal_pressed(): get_tree().change_scene_to_file("res://Scenes/Level_Normal.tscn")
func _on_hard_pressed(): get_tree().change_scene_to_file("res://Scenes/Level_Hard.tscn")
func _on_quit_pressed(): get_tree().quit()
