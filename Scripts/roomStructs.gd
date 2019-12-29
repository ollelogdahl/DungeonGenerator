enum RoomType{NORMAL, START, MAJOR, RAND}

# structs
class Room:
	var x := 0 # rummets övre vänstra hörn, x
	var y := 0 # rummets övre vänstra hörn,
	var w := 0 # rummets bredd
	var h := 0 # rummets höjd
	
	var connections := 0
	var type = RoomType.NORMAL
	
	func save():
		var saveDict = {
			"obj": "room",
			"x": x,
			"y": y,
			"w": w,
			"h": h,
			"connections": connections,
			"type": type
		}
		return saveDict

class Corridor:
	var x      := 0 # korridorens början, x
	var y      := 0 # korridorens början, y
	var dir    := 0 # 0-3 enumererar upp, höger, ner, vänster
	var length := 0 # längd av korridor, börjar på 1
	
	func save():
		var saveDict = {
			"obj": "corridor",
			"x": x,
			"y": y,
			"dir": dir,
			"length": length
		}
		return saveDict

class Layout:
	var rooms = []
	var corridors = []
	
	func Save(loc):
		var save = File.new()
		var path = "user://" + loc + ".dng"
		save.open(path, File.WRITE)
		for r in rooms:
			var data = r.call("save")
			save.store_line(to_json(data))
		for c in corridors:
			var data = c.call("save")
			save.store_line(to_json(data))
		print("File %s saved. [%s rooms, %s corridors]" % [path, len(rooms), len(corridors)])
		save.close()
		
	static func Load(loc):
		var save = File.new()
		var path = "user://" + loc + ".dng"
		if not save.file_exists(path):
			print("save doesn't exist")
			return
		
		save.open(path, File.READ)
		var obj = Layout.new()
		while not save.eof_reached():
			var cLine = parse_json(save.get_line())
			if not cLine:
				break
			if cLine["obj"] == "room":
				var r = Room.new()
				r.x = int(cLine["x"])
				r.y = int(cLine["y"])
				r.w = int(cLine["w"])
				r.h = int(cLine["h"])
				
				r.connections = int(cLine["connections"])
				r.type = int(cLine["type"])
				obj.rooms.append(r)
			elif cLine["obj"] == "corridor":
				var c = Corridor.new()
				c.x = int(cLine["x"])
				c.y = int(cLine["y"])
				c.dir = int(cLine["dir"])
				c.length = int(cLine["length"])
				obj.corridors.append(c)
		save.close()
		print("File %s loaded. [%s rooms, %s corridors]" % [path, len(obj.rooms), len(obj.corridors)])
		return obj
