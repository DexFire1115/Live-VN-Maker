extends Control

var loadfile: ZIPReader = ZIPReader.new()
var loadroot: String
var fileinfo: Dictionary
#var homeDir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
var homeDir: String = "/home/dexfire1115/Documents/SotCIE/"

var filetree := DataTree.new()
var soundDict: Dictionary[String, AudioStream] = {}
var imageDict: Dictionary[String, ImageTexture] = {}
var charDict: Dictionary[int, Node]
var keylog := ""
@onready var loadArchive := $LoadArchive
@onready var background := $Background
@onready var visual := $"."
@onready var keyprint := $KeyPrint
@onready var charNode := preload("res://char.tscn")


func _input(event: InputEvent) -> void:
	if(!(event is InputEventKey && event.pressed)): return
	var newtext := getNewKeyCode(event.as_text_keycode())
	if(!newtext.is_empty()): keylog += " " + newtext
	if(keylog.ends_with("~")):
		keylog = ""
	if(keylog.ends_with("!")):
		keylog = keylog.rsplit(" ", true, 2)[0]
	if(keylog.ends_with("\\")):
		readCommand(keylog)
		keylog = ""
	keyprint.text = keylog

func getNewKeyCode(s: String) -> String:
	var keys := "".join(Array(s.split("+")).map(getKeyValue))
	var baseKey := keys.remove_chars("@^#$")
	if(baseKey.is_empty()): return ""
	return keys

func getKeyValue(s: String) -> String:
	match(s):
		"Ctrl": return "^"
		"Alt": return "@"
		"Shift": return "$"
		"Meta": return "#"
		"CapsLock": return "%"
		"Escape": return "~"
		"Backspace": return "!"
		"Enter": return "\\"
		"QuoteLeft": return "`"
		"Minus": return "-"
		"Equal": return "="
		"BracketLeft": return "["
		"BracketRight": return "]"
		"BackSlash": return "\\"
		"Semicolon": return ";"
		"Apostrophe": return "\'"
		"Comma": return ","
		"Period": return "."
		"Slash": return "/"
		"Space": return "_"
		_: return s



func readCommandSet(s: String):
	var commands := Array(s.split("\\"))
	for c in commands:
		readCommand(c)

func readCommand(s: String):
	var args := Array(s.split(" ", false))
	if(args.size() == 0): return
	match(args[0]):
		"^F": loadArchive.visible = true
		"^A": addUnit(1, "L")
		"A": addUnitCommand(args)
		"B": setBackground(args)

func setBackground(args: Array):
	if(args.size() < 2): return
	var imgName: String = filetree.safeGet("Backgrounds/" + args[1] + "/Asset", TYPE_STRING)
	if(!imageDict.has(imgName)): return
	background.texture = imageDict[imgName]
	

func addUnitCommand(args: Array):
	if(args.size() < 3): return
	if(!String(args[1]).is_valid_int()): return
	addUnit(int(args[1]), args[2])

func addUnit(id: int, cname: String):
	var charData = DataTree.new(filetree.safeGet("Chars/" + cname, TYPE_DICTIONARY))
	if(charData.isEmpty()): return null
	var textureName = charData.safeGet("Asset", TYPE_STRING)
	if(textureName == null || !imageDict.has(textureName)): return
	var texture := imageDict[textureName]
	var currNode := charNode.instantiate()
	visual.add_child(currNode)
	currNode.texture = texture
	charDict.set(id, currNode)
	currNode.position = Vector2(
		charData.dget("DefaultX", 0),
		charData.dget("DefaultY", 0)
	)
	currNode.rotation = charData.dget("DefaultRot", 0)
	if(charData.has("Scale")):
		currNode.scale = Vector2(charData.dget("Scale", 1), charData.dget("Scale", 1))
	else:
		currNode.scale = Vector2(
			charData.dget("ScaleX", 1),
			charData.dget("ScaleY", 1)
		)
	currNode.flip_h = charData.dget("DefaultFlipH", false)
	currNode.flip_v = charData.dget("DefaultFlipV", false)
	

func remUnit(id: int):
	if(!charDict.has(id)): return
	visual.remove_child(charDict[id])
	charDict.erase(id)








func _ready() -> void:
	loadArchive.current_dir = homeDir

func _on_load_archive_file_selected(path: String) -> void:
	homeDir = path.rsplit("/", true, 1)[0]
	if(FileAccess.file_exists(path)):
		loadfile.open(path)
		var fileList := loadfile.get_files()
		for filePath in fileList:
				if filePath.ends_with("ref"):
					loadroot = filePath.rsplit("ref").get(0)
		filetree = DataTree.new()
		for filePath in fileList:
			fileBranch(filePath)
		loadfile.close()
	#print(filetree)
	#print(soundDict)
	#print(imageDict)
	readCommandSet(filetree.safeGet("loader/autoload", TYPE_STRING))

func fileBranch(path: String) -> void:
	var pathStack := path.split(loadroot, true, 1)
	if(pathStack.size() < 2): return
	pathStack = pathStack[1].split("/")
	var tempDict := filetree.dataset
	for level in pathStack:
		if(level.is_empty()): return
		if(level.ends_with(".json")):
			tempDict.set(level, JSON.parse_string(loadfile.read_file(path).get_string_from_ascii()))
			if(str(tempDict.get(level)) == "<null>"): print("ERROR : ", level)
			continue
		if(level.ends_with(".wav")):
			soundDict.set(level, AudioStreamWAV.load_from_buffer(loadfile.read_file(path)))
			tempDict.set(level, "@ExportSOUND")
			continue
		if(level.ends_with(".png")):
			imageDict.set(level, loadImageTexture(loadfile.read_file(path), "png"))
			tempDict.set(level, "@ExportIMAGE")
			continue
		if(level.ends_with(".jpg")):
			imageDict.set(level, loadImageTexture(loadfile.read_file(path), "jpg"))
			tempDict.set(level, "@ExportIMAGE")
			continue
		if(level.ends_with(".svg")):
			imageDict.set(level, loadImageTexture(loadfile.read_file(path), "svg"))
			tempDict.set(level, "@ExportIMAGE")
			continue
		if(level.ends_with(".webp")):
			imageDict.set(level, loadImageTexture(loadfile.read_file(path), "webp"))
			tempDict.set(level, "@ExportIMAGE")
			continue
		if(level == "ref"):
			tempDict.set(level, null)
			continue
		if(!tempDict.has(level)): tempDict.set(level, {})
		tempDict = tempDict[level]

func loadImageTexture(buffer: PackedByteArray, type: String) -> ImageTexture:
	var img := Image.new()
	match(type):
		"png": img.load_png_from_buffer(buffer)
		"jpg": img.load_jpg_from_buffer(buffer)
		"svg": img.load_svg_from_buffer(buffer)
		"webp": img.load_webp_from_buffer(buffer)
		_: return null
	return ImageTexture.create_from_image(img)
