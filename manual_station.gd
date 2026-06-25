extends Control
class_name ManualStation

var is_active: bool = false

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	bg.custom_minimum_size = Vector2(500, 400)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "\n--- OPERATIONS MANUAL ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = """
	
STATION 1 (FRONT): COMMUNICATIONS RADIO
Tune the dial to intercept encrypted enemy signals. 

STATION 2 (RIGHT): DECODER
Press SPACE in time with the incoming signal pulses to decrypt the message clearly. Missed pulses will result in corrupted intelligence.

STATION 3 (BACK): SECURE REPORTING TERMINAL
Review decoded intelligence and transmit it to HQ or Pathfinder. Your choices influence the mission outcome.

STATION 4 (LEFT): OPERATIONS MANUAL
You are here. Consult this manual if you forget standard operating procedures.
"""
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text)
	
	hide()

func set_active(active: bool) -> void:
	is_active = active
	visible = active
