extends CanvasLayer

signal commandEntered

onready var parent = $'../'
onready var terminal = $Terminal
onready var console = $Console

var currentConsoleLine = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	parent.connect("consoleCommand", self, "_onConsoleCommand")
	
	terminal.hide()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("open_console"):
		terminal.show()
		parent.buttonAvailible = false
		terminal.call_deferred("grab_focus")
	
	if Input.is_action_just_pressed("submit_console"):
		if terminal.text == "":
			terminal.hide()
			parent.buttonAvailible = true
			return
		
		if terminal.text[0] == '/':
			emit_signal("commandEntered", terminal.text.replace("\n", ""))
			
		terminal.text = ""
		terminal.hide()
		parent.buttonAvailible = true

func _onConsoleCommand(txt):
	currentConsoleLine += 1
	if currentConsoleLine > 5:
		console.lines_skipped += 1
	console.text += txt
	
