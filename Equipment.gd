extends VBoxContainer

onready var slots = [$Items/Main, $Items/VBox/Relic, $Items/VBox/Acc/Acc1, $Items/VBox/Acc/Acc2, $Items/VBox/Acc/Acc3, $Items/VBox/Acc/Acc4, $Portrait]
var _item_database = item_database.new()
var items = {}

func _ready():
	for slot in slots:
		items[slot.name] = null
	yield(get_tree(), "idle_frame")
	update_stats()
		
func check_rotation(item):
	if item.rotated == true:
		var texture = item.get_node("Focus")
		texture.rect_rotation = 0
		texture.rect_position.x = 0
		item.size = Vector2(item.size.y, item.size.x)
		item.rotated = false
		item.rotate()
		
func update_stats():
	var stats = get_owner().get_node("ViewportContainer/Viewport/Menu/VBox/Inventory/Base/VBox/Body/Stats")
	for stat in stats.get_children():
		stat.get_child(0).get_node("SUM").text = str(GameState.data.player[stat.name.to_lower()] + GameState.get(stat.name.to_lower()))
		
func insert_item(item):
	var path = "res://entities/items/entities/" + item.get_meta("id") + "/" + item.get_meta("id") + ".tscn"
	var file = File.new()
	var do_file = file.file_exists(path)
	
	check_rotation(item)
		
	var item_pos = item.rect_global_position + item.rect_size / 2
	var slot = get_slot_under_pos(item_pos)
	if slot == null:
		return false
	var item_slot = _item_database.get_item(item.get_meta("id"))["slot"]
	var check = 0
	for s in item_slot:
		if s in slot.name:
			check += 1
	if check == 0:
		return false
	if items[slot.name] != null:
		return false
	if slot.name == "Portrait":
		_portrait(item, true)
	if "Acc" in slot.name:
		_rings(item, true, slot.name.right(3))
		
	for req in _item_database.get_item(item.get_meta("id"))["req"]:
		var stat = _item_database.get_item(item.get_meta("id"))["req"][req]
		if stat > 0:
			var global = GameState.data.player[req]
			if global < stat:
				return false
				
	items[slot.name] = item
	
	for stat in _item_database.get_item(item.get_meta("id"))["stats"]:
		var bonus = _item_database.get_item(item.get_meta("id"))["stats"][stat]
		if bonus > 0:
			var global = GameState.get(stat)
			global += bonus
			GameState.set(stat, global)
	
	update_stats()
	GameState.data.player.equipment[slot.name] = {"id":item.get_meta("id"), "x":item.rect_global_position.x, "y":item.rect_global_position.y}
	item.rect_global_position = slot.rect_global_position + slot.rect_size / 2 - item.rect_size / 2
	
	if do_file:
		var _item = load(path).instance()
		get_owner().get_node("../../YSort/Entities/Player").add_child(_item)

	
	return true

func quick_insert(item):
	var path = "res://entities/items/entities/" + item.get_meta("id") + "/" + item.get_meta("id") + ".tscn"
	var file = File.new()
	var do_file = file.file_exists(path)
	
	check_rotation(item)
	
	var item_slot = _item_database.get_item(item.get_meta("id"))["slot"]
	
	for req in _item_database.get_item(item.get_meta("id"))["req"]:
		var stat = _item_database.get_item(item.get_meta("id"))["req"][req]
		if stat > 0:
			var global = GameState.data.player[req]
			if global < stat:
				return false
				
	if item_slot[0] == "Portrait":
		_portrait(item, true)
	
	for slot in slots:
		for s in item_slot:
			if s in slot.name and items[slot.name] == null:
				items[slot.name] = item
				
				for stat in _item_database.get_item(item.get_meta("id"))["stats"]:
					var bonus = _item_database.get_item(item.get_meta("id"))["stats"][stat]
					if bonus > 0:
						var global = GameState.get(stat)
						global += bonus
						GameState.set(stat, global)
						
				if "Acc" in slot.name:
					_rings(item, true, slot.name.right(3))
						
				update_stats()
				item.rect_global_position = slot.rect_global_position + slot.rect_size / 2 - item.rect_size / 2
				GameState.data.player.equipment[slot.name] = {"id":item.get_meta("id"), "x":slot.rect_global_position.x, "y":slot.rect_global_position.y}
				
				if do_file:
					var _item = load(path).instance()
					get_owner().get_node("../../YSort/Entities/Player").add_child(_item)
				return true
	return false

func remove_item(pos):
	var item = get_item_under_pos(pos)
	
	if item == null:
		return null
	var item_pos = item.rect_global_position + item.rect_size / 2
	var slot = get_slot_under_pos(item_pos)
	if _item_database.get_item(item.get_meta("id"))["slot"][0] == "Portrait":
		_portrait(item, false)
	if "Acc1" in _item_database.get_item(item.get_meta("id"))["slot"]:
		_rings(item, false, slot.name.right(3))
	items[slot.name] = null
	for stat in _item_database.get_item(item.get_meta("id"))["stats"]:
		var bonus = _item_database.get_item(item.get_meta("id"))["stats"][stat]
		if bonus > 0:
			var global = GameState.get(stat)
			global -= bonus
			GameState.set(stat, global)
			
	if get_owner().get_node_or_null("../../YSort/Entities/Player/" + item.get_meta("id")) != null:
		get_owner().get_node("../../YSort/Entities/Player/" + item.get_meta("id")).queue_free()
			
	update_stats()
	return item

func grab_item(pos):
	var item = get_item_under_pos(pos)
	if item == null:
		return null
	var item_pos = item.rect_global_position + item.rect_size / 2
	var slot = get_slot_under_pos(item_pos)
	if _item_database.get_item(item.get_meta("id"))["slot"][0] == "Portrait":
		_portrait(item, false)
	if "Acc1" in _item_database.get_item(item.get_meta("id"))["slot"]:
		_rings(item, false, slot.name.right(3))
	items[slot.name] = null
	for stat in _item_database.get_item(item.get_meta("id"))["stats"]:
		var bonus = _item_database.get_item(item.get_meta("id"))["stats"][stat]
		if bonus > 0:
			var global = GameState.get(stat)
			global -= bonus
			GameState.set(stat, global)
			
	if get_owner().get_node_or_null("../../YSort/Entities/Player/" + item.get_meta("id")) != null:
		get_owner().get_node("../../YSort/Entities/Player/" + item.get_meta("id")).queue_free()
	
	update_stats()
	GameState.data.player.equipment[slot.name] = null
	return item
	
func _portrait(item, dir):
	var nam = item.get_meta("id")
	for _image in $Portrait.get_children():
		if nam == _image.name and dir:
			_image.show()
		elif _image.name != "Base" and _image.name != "Rings":
			_image.hide()
		
	if dir:
		item.hide()
	else:
		item.show()

func _rings(item, dir, pos):
	var nam = item.get_meta("id").to_lower()
	for _ring in $Portrait/Rings.get_children():
		if _ring.name == pos and dir:
			var _path = "res://assets/UI/Portrait_Rings/" + str(pos) + "_" + nam + ".png"
			var _image = File.new().file_exists(_path)
			if _image:
				get_node("Portrait/Rings/" + str(pos)).texture = load(_path)
				_ring.show()
			else:
				print("error: failed to load portrait ring image")
		elif _ring.name == pos:
			_ring.hide()
 
func get_slot_under_pos(pos):
	return get_thing_under_pos(slots, pos)
 
func get_item_under_pos(pos):
	return get_thing_under_pos(items.values(), pos)
 
func get_thing_under_pos(arr, pos):
	for thing in arr:
		if thing != null and thing.get_global_rect().has_point(pos):
			return thing
	return null
