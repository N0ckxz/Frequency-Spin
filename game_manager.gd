extends Node

var radio_ui: RadioStation
var decoder_ui: DecoderStation
var terminal_ui: TerminalStation
var manual_ui: ManualStation

var current_station: int = 0
var pending_message: String = ""
var message_decoded: bool = false
var last_report_text: String = ""

func _ready() -> void:
	call_deferred("_setup_ui")

func _setup_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	get_tree().current_scene.add_child(canvas)
		
	radio_ui = RadioStation.new()
	canvas.add_child(radio_ui)
	
	decoder_ui = DecoderStation.new()
	canvas.add_child(decoder_ui)
	
	terminal_ui = TerminalStation.new()
	canvas.add_child(terminal_ui)
	
	manual_ui = ManualStation.new()
	canvas.add_child(manual_ui)
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.station_changed.connect(_on_station_changed)
	
	radio_ui.signal_intercepted.connect(_on_signal_intercepted)
	decoder_ui.decoding_finished.connect(_on_decoding_finished)
	terminal_ui.report_sent.connect(_on_report_sent)
		
	_on_station_changed(0) # Initialize

func _on_station_changed(index: int) -> void:
	current_station = index
	if radio_ui:
		radio_ui.set_active(index == 0)
	if decoder_ui:
		decoder_ui.set_active(index == 1)
		
		# Auto-start decoding if we have a pending message and we just switched to the decoder
		if index == 1 and pending_message != "" and not message_decoded and not decoder_ui.minigame_active:
			decoder_ui.start_decoding(pending_message)
			
	if terminal_ui:
		terminal_ui.set_active(index == 2)
		if index == 2 and message_decoded:
			terminal_ui.update_intelligence(pending_message)
			
	if manual_ui:
		manual_ui.set_active(index == 3)

func _on_signal_intercepted(freq: float) -> void:
	print("GameManager: Signal intercepted at ", freq)
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://sfx/game jam sfx/detection successful.mp3")
	add_child(audio)
	audio.play()
	
	# Set a test pending message for the hackathon prototype
	pending_message = "ENEMY TROOPS MOVING NORTH TOWARDS RAVEN"
	message_decoded = false
	print("GameManager: Awaiting decoding at Station 2...")

func _on_decoding_finished(final_text: String) -> void:
	message_decoded = true
	pending_message = final_text
	print("GameManager: Final Intelligence: ", final_text)
	# Play a reporting available sound
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://sfx/game jam sfx/reporting channel found.mp3")
	add_child(audio)
	audio.play()
	# This text will be available to report at Station 3

func _on_report_sent(target: String) -> void:
	last_report_text = pending_message
	pending_message = ""
	message_decoded = false
	
	var dialogue_resource = load("res://dialogues/report.dialogue")
	var title = "hq_report" if target == "HQ" else "pathfinder_report"
	
	var balloon = load("res://addons/dialogue_manager/example_balloon/example_balloon.tscn").instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, title)
