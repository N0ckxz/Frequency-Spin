extends Control
class_name RadioStation

var target_frequency: float = 104.5
var current_frequency: float = 88.0
var is_active: bool = false

var freq_label: Label
var slider: HSlider
var intercept_btn: Button
var audio_player: AudioStreamPlayer

signal signal_intercepted(frequency)

func _ready() -> void:
	# Build the UI
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "--- COMMUNICATIONS RADIO ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	freq_label = Label.new()
	freq_label.text = "Freq: %.1f MHz" % current_frequency
	freq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(freq_label)
	
	slider = HSlider.new()
	slider.min_value = 88.0
	slider.max_value = 108.0
	slider.step = 0.1
	slider.value = current_frequency
	slider.custom_minimum_size = Vector2(300, 40)
	slider.value_changed.connect(_on_slider_value_changed)
	vbox.add_child(slider)
	
	intercept_btn = Button.new()
	intercept_btn.text = "INTERCEPT SIGNAL"
	intercept_btn.disabled = true
	intercept_btn.pressed.connect(_on_intercept_pressed)
	vbox.add_child(intercept_btn)
	
	# Audio setup
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://sfx/game jam sfx/dial spin1 (new).mp3")
	add_child(audio_player)
	
	hide()

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	if active:
		slider.grab_focus()

func _on_slider_value_changed(value: float) -> void:
	if not is_active: return
	
	current_frequency = value
	freq_label.text = "Freq: %.1f MHz" % current_frequency
	
	if not audio_player.playing:
		audio_player.play()
		
	# Check if we are close to target
	if abs(current_frequency - target_frequency) < 0.2:
		intercept_btn.disabled = false
		freq_label.modulate = Color(0, 1, 0) # Green for good signal
	else:
		intercept_btn.disabled = true
		freq_label.modulate = Color(1, 1, 1)

func _on_intercept_pressed() -> void:
	print("Signal intercepted at ", current_frequency)
	signal_intercepted.emit(current_frequency)
