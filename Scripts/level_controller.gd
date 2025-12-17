extends Node2D

# --- Spawning / Level ---
@export var enemy_scene: PackedScene
@export var enemy_pool: Array[PackedScene] = []
@export var enemy_weights: Array[float] = []

@export var level_duration_sec: float = 120.0
@export var spawn_interval: float = 1.4
@export var spawn_y_margin: float = 40.0

# --- Timeline / Waves ---
@export var use_timeline: bool = true

@export var phase_durations: Array[float] = [30.0, 45.0, 45.0]

@export var phase_spawn_intervals: Array[float] = [1.6, 1.3, 1.0]

# Weights por fase. Cada elemento debe tener el MISMO tamaño que enemy_pool.
# Ejemplo con 2 enemigos [Basic, Shooter]:
# [
#   PackedFloat32Array([90.0, 10.0]),
#   PackedFloat32Array([70.0, 30.0]),
#   PackedFloat32Array([50.0, 50.0]),
# ]
@export var phase_weights: Array[PackedFloat32Array] = [
	PackedFloat32Array([]),
	PackedFloat32Array([]),
	PackedFloat32Array([]),
]

# --- Scenes ---
@export var victory_scene: PackedScene
@export var game_over_scene: PackedScene

# --- Player lookup ---
@export var player_path: NodePath

var time_left: float
var game_over_triggered := false
var victory_triggered := false

# Timeline runtime
var phase_index := 0
var phase_time_left := 0.0
var current_weights: Array[float] = []

@onready var spawn_timer: Timer = $Spawners/SpawnTimer

# --- HUD ---
@onready var time_label: Label = get_node_or_null("HUD/Root/TimeLabel") as Label
@onready var hp_label: Label = get_node_or_null("HUD/Root/HBoxContainer/HpLabel") as Label
@onready var bomb_label: Label = get_node_or_null("HUD/Root/HBoxContainer/BombLabel") as Label

@onready var hp_bar: TextureProgressBar = get_node_or_null("HUD/Root/HpBar") as TextureProgressBar
@onready var charge_bar: TextureProgressBar = get_node_or_null("HUD/Root/ChargeBar") as TextureProgressBar


func _ready() -> void:
	RunState.last_level_path = get_tree().current_scene.scene_file_path
	reset_level()


func reset_level() -> void:
	game_over_triggered = false
	victory_triggered = false

	time_left = level_duration_sec

	spawn_timer.wait_time = spawn_interval
	if not spawn_timer.timeout.is_connected(_spawn_enemy):
		spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()

	_init_timeline()

	_update_hud()


func _process(delta: float) -> void:
	if game_over_triggered or victory_triggered:
		return

	var player := _get_player()
	if player == null:
		_go_game_over()
		return

	time_left = max(time_left - delta, 0.0)
	if time_left <= 0.0:
		end_level()
		return

	_update_timeline(delta)

	_update_hud()


func _init_timeline() -> void:
	phase_index = 0
	current_weights.clear()

	if not use_timeline:
		return

	if phase_durations.is_empty():
		use_timeline = false
		return

	phase_time_left = max(phase_durations[0], 0.0)
	_apply_phase(phase_index)


func _update_timeline(delta: float) -> void:
	if not use_timeline:
		return

	if phase_index >= phase_durations.size():
		return

	phase_time_left -= delta
	if phase_time_left > 0.0:
		return

	phase_index += 1
	if phase_index >= phase_durations.size():
		return

	phase_time_left = max(phase_durations[phase_index], 0.0)
	_apply_phase(phase_index)


func _apply_phase(i: int) -> void:
	if i < phase_spawn_intervals.size():
		spawn_timer.wait_time = phase_spawn_intervals[i]

	if enemy_pool.is_empty():
		return
	if i >= phase_weights.size():
		return

	var w := phase_weights[i]
	if w.size() != enemy_pool.size():
		current_weights.clear()
		return

	current_weights.clear()
	for k in w.size():
		current_weights.append(float(w[k]))


func _get_player() -> Node:
	if player_path != NodePath("") and has_node(player_path):
		var p := get_node(player_path)
		if is_instance_valid(p):
			return p

	var arr := get_tree().get_nodes_in_group("player")
	if arr.size() > 0 and is_instance_valid(arr[0]):
		return arr[0]

	var p2 := get_node_or_null("Player")
	if p2 != null and is_instance_valid(p2):
		return p2

	return null


func _update_hud() -> void:
	if time_label:
		time_label.text = "TIME: %03d" % int(ceil(time_left))

	var player := _get_player()
	if player == null:
		return

	# Labels
	if hp_label:
		hp_label.text = "HP: %d" % int(player.hp)
	if bomb_label:
		bomb_label.text = "BOMB: %d" % int(player.bombs_left)

	# HP Bar
	if hp_bar:
		hp_bar.min_value = 0.0
		hp_bar.max_value = float(player.max_hp)
		hp_bar.value = float(player.hp)

	# Charge Bar
	if charge_bar:
		charge_bar.min_value = 0.0
		charge_bar.max_value = 100.0
		if player.has_method("get_charge_percent"):
			charge_bar.value = float(player.get_charge_percent())
		else:
			charge_bar.value = 0.0


func _spawn_enemy() -> void:
	var scene := _pick_enemy_scene()
	if scene == null:
		return

	var e := scene.instantiate()
	var h := get_viewport_rect().size.y
	var y := randf_range(spawn_y_margin, h - spawn_y_margin)

	e.global_position = Vector2(get_viewport_rect().size.x + 60.0, y)
	add_child(e)


func _pick_enemy_scene() -> PackedScene:
	if not enemy_pool.is_empty():
		var weights_to_use: Array[float] = enemy_weights
		if use_timeline and current_weights.size() == enemy_pool.size():
			weights_to_use = current_weights

		if weights_to_use.size() != enemy_pool.size():
			return enemy_pool[randi() % enemy_pool.size()]

		var total := 0.0
		for w in weights_to_use:
			total += max(w, 0.0)

		if total <= 0.0:
			return enemy_pool[randi() % enemy_pool.size()]

		var r := randf() * total
		for i in enemy_pool.size():
			r -= max(weights_to_use[i], 0.0)
			if r <= 0.0:
				return enemy_pool[i]
		return enemy_pool.back()

	return enemy_scene


func end_level() -> void:
	if victory_triggered:
		return
	victory_triggered = true

	spawn_timer.stop()

	if victory_scene:
		get_tree().change_scene_to_packed(victory_scene)
	else:
		print("LEVEL COMPLETE (no victory_scene asignada)")


func _go_game_over() -> void:
	if game_over_triggered:
		return
	game_over_triggered = true

	spawn_timer.stop()

	if game_over_scene:
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		get_tree().reload_current_scene()
