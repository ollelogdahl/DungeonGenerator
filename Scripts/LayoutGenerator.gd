extends Node

onready var structs = load("res://Scripts/roomStructs.gd")


# publika const variabler
export var ROOM_COUNT = 5
export var ROOM_SIZE_MEAN = Vector2(6, 6)
export var ROOM_SIZE_BOUNDS = Vector2(3, 15)
export (float, 0.4, 2) var ROOM_SIZE_DEV = 1.3

export var MAJOR_ROOM_COUNT = 1
export var BIG_ROOM_CHANCE = 0.15
export var BIG_ROOM_FACTOR = 1.4

export var MAX_RETRIES = 100

export (int, 0, 100) var CORRIDOR_FORCEING = 20         # antal försök innan en ny riktning (tvingar tightare layout)
export (int, 1, 100) var UNFORCED_ROOM_RETRIES = 50
export (float, 0, 1) var RANDOM_BRANCH_CHANCE = 0.2
export (int, 0, 5) var BRANCH_COUNT := 3

export (float, 0, 1) var CONNECT_CLOSE_CHANCE = 0.6

var rng = RandomNumberGenerator.new()


func GenerateDungeonLayout(s):
	rng.seed = s

	var layout = structs.Layout.new()
	# skapar första rum i mitten av världen
	var startingRoom = RandomRoom(0, 0)
	layout.rooms.append(startingRoom)
	
	# main branch
	ForcedLayoutBranch(layout, startingRoom)
	
	# väljer ut ett slumpat rum och gör förgrening därifrån
	for i in range(BRANCH_COUNT):
		var rIndex = randi() % len(layout.rooms)
		TryLayoutBranch(layout, layout.rooms[rIndex])
		layout.rooms[rIndex].type = structs.RoomType.MAJOR
	
	# försöker lägga till ett extra rum till varje major rum
	for r in layout.rooms:
		if r.type == structs.RoomType.MAJOR:
			var rand = TryCreateAndConnectRoom(layout, r)
			if rand:
				rand.type = structs.RoomType.RAND
	
	# ansluter vissa rum som råkar ligga parallelt (skapar 'feedback')
	ForceCloseConnections(layout)
	
	startingRoom.type = structs.RoomType.START # flaggar första rummet som ett start rum
	return layout

func ForceCloseConnections(layout):
	# lägger till nya anslutningar
	for r1 in layout.rooms:
		for r2 in layout.rooms:
			if r1 == r2:
				continue
			
			# testa om dom ligger inom samma x/y
			if (r1.x <= r2.x and r2.x > r1.x + r1.w) or (r1.x < r2.x+r2.w and r1.x+r1.w > r2.x+r2.w):
				# dra vertikal linje från r1 till t2
				pass
				
	pass

func ForcedLayoutBranch(layout, connectingRoom):
	# loopar igenom antalet rum vi ska skapa
	for i in range(ROOM_COUNT-1):
		# skapa en ny korridor och ett nytt rum
		var room = ForceCreateAndConnectRoom(layout, connectingRoom)
		
		# skapar kanske en förgrening (som endast blir 1 rum långt)
		if rng.randf() < RANDOM_BRANCH_CHANCE:
			var randRoom = ForceCreateAndConnectRoom(layout, connectingRoom)
			randRoom.type = structs.RoomType.RAND
		connectingRoom = room

func TryLayoutBranch(layout, connectingRoom):
	# loopar igenom antalet rum vi ska skapa
	for i in range(ROOM_COUNT-1):
		# skapa en ny korridor och ett nytt rum
		var room = TryCreateAndConnectRoom(layout, connectingRoom)
		if room:
			connectingRoom = room

func ForceCreateAndConnectRoom(layout, connectingRoom):
	var valid = false
	var retries = 0
	var corridor
	var room
	
	
	var dir = rng.randi() % 4 # väljer en riktning om corridorforcing är på
	
	while not valid:
		if CORRIDOR_FORCEING == 0:
			dir = rng.randi() % 4
		elif retries % CORRIDOR_FORCEING == 0:
			dir = rng.randi() % 4

		# bygger en korridor från nångstans längstmed väggen
		corridor = RandomCorridorAlongWall(connectingRoom, dir)
		# beräknar vart korridoren slutar
		var corridorEnd = GetCorridorEnd(corridor)
		# väljer ett rum
		room = RandomRoomConnectedTo(corridorEnd, dir)
		
		# testar om rummet är giltigt, annars försök igen
		if not LayoutConflicting(layout, room):
			valid = true
		else:
			retries += 1

	connectingRoom.connections += 1
	layout.corridors.append(corridor)
	layout.rooms.append(room)
	return room

func TryCreateAndConnectRoom(layout, connectingRoom):
	var valid = false
	var retries = 0
	var corridor
	var room
	
	
	var dir = rng.randi() % 4 # väljer en riktning om corridorforcing är på
	while not valid:
		if CORRIDOR_FORCEING == 0:
			dir = rng.randi() % 4
		elif retries % CORRIDOR_FORCEING == 0:
			dir = rng.randi() % 4

		# bygger en korridor från nångstans längstmed väggen
		corridor = RandomCorridorAlongWall(connectingRoom, dir)

		# beräknar vart korridoren slutar
		var corridorEnd = GetCorridorEnd(corridor)
		# väljer ett rum
		room = RandomRoomConnectedTo(corridorEnd, dir)
		
		# testar om rummet är giltigt, annars försök igen
		if not LayoutConflicting(layout, room):
			valid = true
		else:
			retries += 1
		
		if retries > UNFORCED_ROOM_RETRIES:
			return
	
	connectingRoom.connections += 1
	layout.corridors.append(corridor)
	layout.rooms.append(room)
	return room

func RandomCorridorAlongWall(room, dir):
	var corridor = structs.Corridor.new()
	match(dir):
		0:
			corridor.x = (rng.randi() % (room.w-1)) + room.x + 1
			corridor.y = room.y
		1:
			corridor.x = room.x + room.w
			corridor.y = (rng.randi() % (room.h-1)) + room.y + 1
		2:
			corridor.x = (rng.randi() % (room.w-1)) + room.x + 1
			corridor.y = room.y + room.h
		3:
			corridor.x = room.x
			corridor.y = (rng.randi() % (room.h-1)) + room.y + 1

	corridor.dir = dir
	corridor.length = (rng.randi() % 2) + 1
	return corridor

func GetCorridorEnd(corridor):
	var corridorEnd = Vector2()
	match(corridor.dir):
		0:
			corridorEnd.x = corridor.x
			corridorEnd.y = corridor.y - corridor.length
		1:
			corridorEnd.x = corridor.x + corridor.length
			corridorEnd.y = corridor.y
		2:
			corridorEnd.x = corridor.x
			corridorEnd.y = corridor.y + corridor.length
		3:
			corridorEnd.x = corridor.x - corridor.length
			corridorEnd.y = corridor.y
	return corridorEnd

# given en punkt, generera ett rum vars vägg dir-2 skär punkten
func RandomRoomConnectedTo(pointToConnect, dir):
	var room = structs.Room.new()
	var roomSize = RandomRoomSize()
	room.w = int(roomSize.x)
	room.h = int(roomSize.y)

	match(dir):
		0:
			room.x = int(pointToConnect.x - 1 - rng.randi() % (room.w-1))
			room.y = int(pointToConnect.y - roomSize.y)
		1:
			room.x = int(pointToConnect.x)
			room.y = int(pointToConnect.y - 1 - rng.randi() % (room.h-1))
		2:
			room.x = int(pointToConnect.x - 1 - rng.randi() % (room.w-1))
			room.y = int(pointToConnect.y)
		3:
			room.x = int(pointToConnect.x - roomSize.x)
			room.y = int(pointToConnect.y - 1 - rng.randi() % (room.h-1))
	room.connections += 1
	return room

# testar om ett rum/korridor krockar med något annat
func LayoutConflicting(layout, room):
	for r in layout.rooms:
		if RoomsColliding(r, room):
			return true
	for c in layout.corridors:
		if RoomCorridorColliding(room, c):
			return true
	return false

func RoomsColliding(r1, r2):
	if r1.x < r2.x + r2.w and r1.x + r1.w > r2.x and r1.y < r2.y + r2.h and r1.y + r1.h > r2.y:
		return true
	else:
		return false

func RoomCorridorColliding(r, c):
	match(c.dir):
		0:
			if c.x < r.x+r.w and c.x > r.x and c.y > r.y and c.y < r.y+r.h+c.length:
				return true
		1:
			if c.x > r.x and c.x < r.x+r.w+c.length and c.y < r.y+r.h and c.y > r.y:
				return true
		2:
			if c.x < r.x+r.w and c.x > r.x and c.y > r.y - c.length and c.y < r.y+r.h:
				return true
		3:
			if c.x > r.x - c.length and c.x < r.x+r.w and c.y < r.y+r.h and c.y > r.y:
				return true

func RandomRoom(x, y):
	var room = structs.Room.new()
	var roomSize = RandomRoomSize()
	room.x = x
	room.y = y
	room.w = int(roomSize.x)
	room.h = int(roomSize.y)
	return room

func RandomRoomSize():
	var size = Vector2()
	size.x = clamp(int(rng.randfn(ROOM_SIZE_MEAN.x, ROOM_SIZE_DEV)), ROOM_SIZE_BOUNDS.x, ROOM_SIZE_BOUNDS.y)
	size.y = clamp(int(rng.randfn(ROOM_SIZE_MEAN.y, ROOM_SIZE_DEV)), ROOM_SIZE_BOUNDS.x, ROOM_SIZE_BOUNDS.y)
	if rng.randf() < BIG_ROOM_CHANCE:
		size *= BIG_ROOM_FACTOR
	return size
