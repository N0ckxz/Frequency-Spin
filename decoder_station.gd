extends Control
class_name DecoderStation

var is_active: bool = false
var minigame_active: bool = false

var target_words: PackedStringArray = []
var decoded_words: PackedStringArray = []
var notes: Array = []
var speed: float = 200.0 # Pixels per second
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0
var words_spawned: int = 0

var track_ui: ColorRect
var hit_zone_ui: ColorRect
var result_label: Label
var instructions_label: Label

var hit_audio: AudioStreamPlayer
var fail_audio: AudioStreamPlayer
var success_audio: AudioStreamPlayer

signal decoding_finished(final_text)

func _ready() -> void:
	# Build UI
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 200)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "--- SIGNAL DECODER ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	instructions_label = Label.new()
	instructions_label.text = "Awaiting Signal..."
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions_label)
	
	# The Rhythm Track
	var track_container = Control.new()
	track_container.custom_minimum_size = Vector2(400, 50)
	vbox.add_child(track_container)
	
	track_ui = ColorRect.new()
	track_ui.color = Color(0.1, 0.1, 0.1, 0.8)
	track_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track_container.add_child(track_ui)
	
	hit_zone_ui = ColorRect.new()
	hit_zone_ui.color = Color(0.2, 0.8, 0.2, 0.5)
	hit_zone_ui.size = Vector2(40, 50)
	hit_zone_ui.position = Vector2(50, 0) # Hit zone near the left
	track_container.add_child(hit_zone_ui)
	
	result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(result_label)
	
	# Audio
	hit_audio = AudioStreamPlayer.new()
	hit_audio.stream = load("res://sfx/game jam sfx/rhythm click.mp3")
	add_child(hit_audio)
	
	fail_audio = AudioStreamPlayer.new()
	fail_audio.stream = load("res://sfx/game jam sfx/rhythm fail.mp3")
	add_child(fail_audio)
	
	success_audio = AudioStreamPlayer.new()
	success_audio.stream = load("res://sfx/game jam sfx/rhythm success.mp3")
	add_child(success_audio)
	
	hide()

func set_active(active: bool) -> void:
	is_active = active
	visible = active

func start_decoding(message: String) -> void:
	target_words = message.split(" ")
	decoded_words.clear()
	for i in range(target_words.size()):
		decoded_words.append("?????")
		
	notes.clear()
	for child in track_ui.get_children():
		child.queue_free()
		
	words_spawned = 0
	spawn_timer = 0.5
	minigame_active = true
	instructions_label.text = "Press SPACE when note is in the green zone!"
	_update_result_text()

func _process(delta: float) -> void:
	if not minigame_active: return
	
	# Spawning notes
	if words_spawned < target_words.size():
		spawn_timer -= delta
		if spawn_timer <= 0:
			_spawn_note(words_spawned)
			words_spawned += 1
			spawn_timer = spawn_interval
			
	# Move notes
	for i in range(notes.size() - 1, -1, -1):
		var note_data = notes[i]
		var ui_node = note_data["node"]
		ui_node.position.x -= speed * delta
		
		# Missed note
		if ui_node.position.x < 0:
			fail_audio.play()
			ui_node.queue_free()
			notes.remove_at(i)
			_check_game_over()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not minigame_active: return
	
	if event.is_action_pressed("ui_accept"): # SPACE bar
		_attempt_hit()

func _spawn_note(word_index: int) -> void:
	var note_rect = ColorRect.new()
	note_rect.color = Color(1, 1, 1, 1)
	note_rect.size = Vector2(20, 50)
	note_rect.position = Vector2(400, 0) # Spawn at right edge of track
	track_ui.add_child(note_rect)
	
	notes.append({
		"word_index": word_index,
		"node": note_rect
	})

func _attempt_hit() -> void:
	var hit_zone_x = hit_zone_ui.position.x
	var hit_zone_width = hit_zone_ui.size.x
	var hit_tolerance = hit_zone_width / 2.0
	var hit_center = hit_zone_x + hit_tolerance
	
	var best_note_idx = -1
	var min_dist = 9999.0
	
	for i in range(notes.size()):
		var note_center = notes[i]["node"].position.x + 10 # Half of note width
		var dist = abs(note_center - hit_center)
		if dist < min_dist and dist <= hit_tolerance + 20: # 20px extra leeway
			min_dist = dist
			best_note_idx = i
			
	if best_note_idx != -1:
		hit_audio.play()
		var word_idx = notes[best_note_idx]["word_index"]
		decoded_words[word_idx] = target_words[word_idx]
		notes[best_note_idx]["node"].queue_free()
		notes.remove_at(best_note_idx)
		_update_result_text()
		
		# Flash hit zone
		var tween = create_tween()
		hit_zone_ui.color = Color(1, 1, 1, 1)
		tween.tween_property(hit_zone_ui, "color", Color(0.2, 0.8, 0.2, 0.5), 0.2)
	else:
		fail_audio.play()
		# Flash track red for miss
		var tween = create_tween()
		track_ui.color = Color(0.8, 0.2, 0.2, 0.8)
		tween.tween_property(track_ui, "color", Color(0.1, 0.1, 0.1, 0.8), 0.2)
		
	_check_game_over()

func _check_game_over() -> void:
	if words_spawned >= target_words.size() and notes.size() == 0:
		minigame_active = false
		instructions_label.text = "Decoding Complete"
		success_audio.play()
		var final_text = " ".join(decoded_words)
		signal_intercepted_and_decoded(final_text)

func signal_intercepted_and_decoded(text: String):
	print("Decoded Text: ", text)
	decoding_finished.emit(text)

func _update_result_text() -> void:
	result_label.text = " ".join(decoded_words)
