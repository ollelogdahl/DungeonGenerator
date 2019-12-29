extends Node2D

signal dungeonGenerated
signal consoleCommand

var currentDungeon
var buttonAvailible = true

var corridorColor = Color(1, 0, 0)


onready var generator = $DungeonGenerator
onready var structs = load("res://Scripts/roomStructs.gd")


# Called when the node enters the scene tree for the first time.
func _ready():
	$GUI.connect("commandEntered", self, "_on_commandEntered")
	
	GenerateDungeon()
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
	
	if Input.is_action_just_pressed("generate") and buttonAvailible:
		GenerateDungeon()

func GenerateDungeon(s = null):
	if s == null:
		s = randi()
	currentDungeon = $DungeonGenerator.GenerateDungeonLayout(s)
	emit_signal("dungeonGenerated")
	ConsoleWrite("Dungeon generated. seed: %x" % s)

func _on_commandEntered(string):
	print(string)
	var cmd = string.split(" ")
	
	
	if cmd[0] == "/generate":
			GenerateDungeon()
	elif cmd[0] == "/set":
		if len(cmd) == 3:
			if cmd[1] in generator:
				var value
				match typeof(generator.get(cmd[1])):
					TYPE_INT:
						value = int(cmd[2])
					TYPE_BOOL:
						value = bool(cmd[2])
					TYPE_STRING:
						value = cmd[2]
					TYPE_REAL:
						value = float(cmd[2])
					_:
						ConsoleWrite("error: invalid type")
						return
				
				generator.set(cmd[1], value)
				ConsoleWrite("%s set to %s" % [cmd[1], cmd[2]])
			else:
				ConsoleWrite("parameter %s doesn't exist" % cmd[1])
		else:
			ConsoleWrite("/set usage:\n   /set [parameter] [value]")
	elif cmd[0] == "/save":
		currentDungeon.Save(cmd[1])
		ConsoleWrite("saving dungeon as %s.dng..." % cmd[1])
	elif cmd[0] == "/load":
		if len(cmd) != 2:
			ConsoleWrite("/load usade:\n   /load [file]")
			return
		var new = structs.Layout.Load(cmd[1])
		ConsoleWrite("loading dungeon %s.dng..." % cmd[1])
		if new:
			currentDungeon = new
			emit_signal("dungeonGenerated")
	else:
		ConsoleWrite("unknown command %s!" % cmd[0])

func ConsoleWrite(txt):
	emit_signal("consoleCommand", txt+"\n")



func _draw():
	for r in currentDungeon.rooms:
		var fillColor
		var gridColor
		var edgeColor
		match(r.type):
			structs.RoomType.NORMAL:
				fillColor = Color(  0,   0.1, 0.30)
				gridColor = Color(0.0,   0.1, 0.45)
				edgeColor = Color(0.3,   0.3,    1)
			structs.RoomType.MAJOR:
				fillColor = Color(0.3,   0.1, 0.30)
				gridColor = Color(0.4,   0.1, 0.45)
				edgeColor = Color(0.8,   0.3,    1)
			structs.RoomType.START:
				fillColor = Color(0.1,   0.3, 0.20)
				gridColor = Color(0.2,   0.4, 0.35)
				edgeColor = Color(0.3,     1,  0.8)
			structs.RoomType.RAND:
				fillColor = Color(0.1,   0.1,  0.1)
				gridColor = Color(0.2,   0.2,  0.2)
				edgeColor = Color(0.4,   0.4,  0.6)
		
		draw_rect( Rect2(r.x, r.y, r.w, r.h), fillColor,  true)
		for w in range(r.w-1):
			draw_line(Vector2(r.x + w+1, r.y), Vector2(r.x+w+1, r.y+r.h), gridColor)
		for h in range(r.h-1):
			draw_line(Vector2(r.x, r.y+h+1), Vector2(r.x+r.w, r.y+h+1), gridColor)
		draw_rect( Rect2(r.x, r.y, r.w, r.h), edgeColor, false)
		
	for c in currentDungeon.corridors:
		match(c.dir):
			0:
				draw_line(Vector2(c.x,c.y), Vector2(c.x, c.y - c.length), corridorColor, 1)
			1:
				draw_line(Vector2(c.x,c.y), Vector2(c.x + c.length, c.y), corridorColor, 1)
			2:
				draw_line(Vector2(c.x,c.y), Vector2(c.x, c.y + c.length), corridorColor, 1)
			3:
				draw_line(Vector2(c.x,c.y), Vector2(c.x - c.length, c.y), corridorColor, 1)
