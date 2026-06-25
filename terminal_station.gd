extends Control
class_name TerminalStation

var is_active: bool = false
var report_text: String = "NO PENDING INTELLIGENCE"

var message_label: Label
var hq_btn: Button
var pf_btn: Button

signal report_sent(target: String)

func _ready() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(500, 300)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "--- SECURE REPORTING TERMINAL ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	message_label = Label.new()
	message_label.text = report_text
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer2)
	
	hq_btn = Button.new()
	hq_btn.text = "TRANSMIT TO HQ"
	hq_btn.pressed.connect(func(): _transmit("HQ"))
	vbox.add_child(hq_btn)
	
	pf_btn = Button.new()
	pf_btn.text = "TRANSMIT TO PATHFINDER"
	pf_btn.pressed.connect(func(): _transmit("Pathfinder"))
	vbox.add_child(pf_btn)
	
	hide()

func set_active(active: bool) -> void:
	is_active = active
	visible = active

func update_intelligence(text: String) -> void:
	report_text = text
	message_label.text = "DECODED INTELLIGENCE:\n\n\"" + report_text + "\""
	hq_btn.disabled = false
	pf_btn.disabled = false

func _transmit(target: String) -> void:
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://sfx/game jam sfx/reporting option selection.mp3")
	add_child(audio)
	audio.play()
	
	hq_btn.disabled = true
	pf_btn.disabled = true
	report_sent.emit(target)
