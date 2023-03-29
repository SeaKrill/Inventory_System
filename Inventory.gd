extends Control

const item_base = preload("res://ui/Menu/Item_base.tscn")
const item_drop = preload("res://entities/items/Base_Loot.tscn")

onready var player = $Base/VBox/Body/Equipment/Name/Text
onready var level = $Base/VBox/Body/Equipment/Level/Text

onready var inv_base = self
onready var grid = $Base/VBox/Body/Grid
onready var equipment = $Base/VBox/Body/Equipment
onready var garbage = $Base/VBox/Body/Sidebar/Garbage
onready var portrait = $Base/VBox/Body/Equipment/Portrait
onready var inv_slots = $Slots
onready var mouse = $Mouse

onready var get_owner = get_owner().get_owner()
onready var get_parent = get_parent().get_parent()

var _item_database = item_database.new()
var item_held = null
var item_offset = Vector2()
var last_container = null
var last_pos = Vector2()

var focus = false
var item_loc = Vector2.ZERO
var rotate = false
var rotate_offset = Vector2.ZERO
var mouse_pos = Vector2.ZERO

func _ready():
	yield(get_tree(), "idle_frame")
	player.text = GameState.data.player.name
	mouse_pos = mouse.rect_global_position
	pickup_item("ODD Devision Device")
#	pickup_item("Fear")
#	pickup_item("Mind")
#	pickup_item("Greed")
#	pickup_item("Ring1")
	
# warning-ignore:unused_argument
func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton or !visible:
		return
	if mouse.has_focus():
		if Input.is_action_pressed("ui_down"):
			if item_held != null:
				if (item_loc.y - item_offset.y) + item_held.rect_size.y < inv_slots.rect_global_position.y + (64*9):
					item_loc.y += 64
					mouse_pos.y += 64
			elif mouse_pos.y + mouse.rect_size.y < get_parent.rect_size.y - mouse.rect_size.y:
				mouse_pos.y += 64
		if Input.is_action_pressed("ui_up"):
			if item_held != null:
				if (item_loc.y - item_offset.y) > inv_slots.rect_global_position.y:
					mouse.grab_focus()
					item_loc.y -= 64
					mouse_pos.y -= 64
			elif mouse_pos.y > inv_slots.rect_global_position.y:
				mouse.grab_focus()
				mouse_pos.y -= 64
			else:
				mouse.hide()
				get_owner().get_node("ViewportContainer/Viewport/Menu/VBox/Tabs/Inventory").grab_focus()
		if Input.is_action_pressed("ui_right"):
			if item_held != null:
				if (item_loc.x - item_offset.x) + item_held.rect_size.x < (get_parent.rect_global_position.x + get_parent.rect_size.x) - mouse.rect_size.x:
					item_loc.x += 64
					mouse_pos.x += 64
			elif mouse_pos.x + mouse.rect_size.x < (rect_global_position.x + rect_size.x) - mouse.rect_size.x:
				mouse_pos.x += 64
		if Input.is_action_pressed("ui_left"):
			if item_held != null:
				if item_held.rect_global_position.x > get_node("Base/VBox/Body/Sidebar").rect_global_position.x:
					item_loc.x -= 64
					mouse_pos.x -= 64
			elif mouse_pos.x > get_parent.rect_global_position.x + mouse.rect_size.x:
				mouse_pos.x -= 64
		if Input.is_action_just_pressed("ui_rotate_item"):
			if item_held != null:
				var _size = item_held.size.y
				check_rotation(item_held)
				if rotate:
					rotate = false
				else:
					rotate = true
				var _offset = _size - item_held.size.y
				if !item_held.get_global_rect().has_point(mouse_pos):
					rotate_offset = Vector2(0, mouse_pos.y - (item_loc.y - item_offset.y))
				else:
					rotate_offset = Vector2.ZERO
				
		if Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_modifier"):
			if item_held == null:
				quick_grab(mouse_pos)
				return
				
		if Input.is_action_just_pressed("ui_accept"):
			if item_held == null:
				grab(mouse_pos)
				if item_held != null:
					item_held.get_node("Focus/Select").show()
					item_offset = mouse_pos - item_held.rect_global_position
			else:
				item_held.get_node("Focus/Select").hide()
				release(item_loc - item_offset)
		
		mouse.rect_global_position = mouse_pos
		
		if item_held != null:
			item_loc = mouse_pos
		
		if item_held != null:
			item_held.rect_global_position = (item_loc - item_offset) + rotate_offset
			if (item_loc.x  - item_offset.x) + item_held.rect_size.x > get_parent.rect_global_position.x + get_parent.rect_size.x:
				item_held.rect_global_position.x -= (item_held.rect_global_position.x + item_held.rect_size.x) - (get_parent.rect_global_position.x + get_parent.rect_size.x)
			if (item_loc.y - item_offset.y) + item_held.rect_size.y > inv_slots.rect_global_position.y + (64*9):
				item_held.rect_global_position.y -= (item_held.rect_global_position.y + item_held.rect_size.y) - (inv_slots.rect_global_position.y + (64*9))
		
func _fail(item):
	var tween = create_tween()
	var shake = 2
	var shake_duration = 0.05
	var shake_count = 4
	var dir = false

	for i in shake_count:
		if dir:
			shake = shake
			dir = false
		else:
			shake = -shake
			dir = true
		tween.tween_property(item.get_node("Focus/Img"), "rect_position:x", item.get_node("Focus/Img").rect_position.x + shake, shake_duration)

	tween.tween_property(item.get_node("Focus/Img"), "rect_position:x", 0.0, shake_duration)

func load_inventory():
	for item in grid.items.duplicate():
		grid.remove_item(item.rect_global_position)
		item.queue_free()

	for item in equipment.items.keys():
		if equipment.items[item] != null:
			equipment.items[item].queue_free()
			equipment.remove_item(equipment.items[item].rect_global_position)

	for _id in GameState.data.player.inventory.duplicate():
		GameState.data.player.inventory.remove(GameState.data.player.inventory.find(_id))
		var item_id = _id[0]
		var item_pos = Vector2(_id[1], _id[2])
		var item = item_base.instance()
		item.set_meta("id", item_id)
		item.get_node("Focus/Img").texture = load(_item_database.get_item(item_id)["icon"])
		inv_slots.add_child(item)
		item.rect_global_position = item_pos
		item.size = item.get_node("Focus/Img").rect_size
		if _id[3] == true:
			check_rotation(item)
		else:
			item.rotate()
		if !grid.insert_item(item):
			print("error: inventory load")

	for slot in GameState.data.player.equipment.keys():
		if GameState.data.player.equipment[slot] != null:
			var item_id = GameState.data.player.equipment[slot]["id"]
			var item_pos = Vector2(GameState.data.player.equipment[slot]["x"], GameState.data.player.equipment[slot]["y"])
			var item = item_base.instance()
			item.set_meta("id", item_id)
			item.get_node("Focus/Img").texture = load(_item_database.get_item(item_id)["icon"])
			inv_slots.add_child(item)
			item.rect_global_position = item_pos
			item.rotate()
			GameState.data.player.equipment[slot] = null
			if !equipment.insert_item(item):
				print("error: equipment load")

func check_rotation(item):
	if item != null:
		if item.size.x > item.size.y or item.size.x < item.size.y:
			var texture = item.get_node("Focus")
			if item.rotated == false:
				texture.rect_rotation = 90
				texture.rect_position.x = texture.rect_size.y
				item.size = Vector2(item.size.y, item.size.x)
				item.rotated = true
				item.rotate()
			else:
				texture.rect_rotation = 0
				texture.rect_position.x = 0
				item.size = Vector2(item.size.y, item.size.x)
				item.rotated = false
				item.rotate()
	
func quick_grab(cursor_pos):
	var c = get_container_under_cursor(cursor_pos)
	if c != null and c.has_method("get_item_under_pos"):
		if c.has_method("get_slot_under_pos"):
			var _item = equipment.items[c.get_slot_under_pos(cursor_pos).name]
			item_held = c.grab_item(_item.rect_global_position)
		else:
			item_held = c.grab_item(cursor_pos)
		if item_held != null:
			if "NONE" in _item_database.get_item(item_held.get_meta("id"))["slot"]:
				quick_return(c)
				return
			if "Equip" in c.name:
				if grid.insert_item_at_first_available_spot(item_held):
					item_held = null
					return
				else:
					if equipment.quick_insert(item_held):
						item_held = null
					return
			if "Grid" in c.name:
				if equipment.quick_insert(item_held):
					item_held = null
					return
				else:
					if !quick_replace():
						_fail(item_held)
						if item_held != null:
							grid.insert_item(item_held)
							item_held = null
							return

func quick_return(c):
	last_container = c
	last_container.insert_item(item_held)
	item_held = null

func quick_replace():
	for req in _item_database.get_item(item_held.get_meta("id"))["req"]:
		var stat = _item_database.get_item(item_held.get_meta("id"))["req"][req]
		if stat > 0:
#			var global = GameState.get(req)
			var global = GameState.data.player[req]
			if global < stat:
				return false
	
	for slot in equipment.slots:
			if slot.name in _item_database.get_item(item_held.get_meta("id"))["slot"]:
				if equipment.items[slot.name] == null:
					item_held.rect_global_position = slot.rect_global_position
					if equipment.insert_item(item_held):
						item_held = null
						return true
	for slot in equipment.slots:
			if slot.name in _item_database.get_item(item_held.get_meta("id"))["slot"]:
				if equipment.items[slot.name] != null:
					var target_pos = equipment.items[slot.name].rect_global_position
					var target = equipment.grab_item(target_pos)
					if grid.insert_item_at_first_available_spot(target):
						item_held.rect_global_position = target_pos
						if equipment.insert_item(item_held):
							item_held = null
							return true
					target.rect_global_position = target_pos
					equipment.insert_item(target)
	return false
	
func replace():
	var cursor_pos = Vector2.ZERO
	if equipment.get_slot_under_pos(mouse_pos) == null:
		return false
	if equipment.items[equipment.get_slot_under_pos(mouse_pos).name] == null:
		return false
	if equipment.get_slot_under_pos(mouse_pos) != null:
		cursor_pos = equipment.items[equipment.get_slot_under_pos(mouse_pos).name].rect_global_position
	if equipment.get_item_under_pos(cursor_pos) == null:
		if rotate:
			check_rotation(item_held)
		return false
	var target = equipment.grab_item(equipment.get_item_under_pos(cursor_pos).rect_global_position)
	var target_pos = target.rect_global_position
	var slot = equipment.get_slot_under_pos(target_pos)
	var item_slot = _item_database.get_item(item_held.get_meta("id"))["slot"]
	if slot.name in item_slot:
		if grid.insert_item_at_first_available_spot(target):
			item_held.rect_global_position = target_pos
			if equipment.insert_item(item_held):
				item_held = null
				return true
	target.rect_global_position = target_pos
	equipment.insert_item(target)
	return false

func grab(cursor_pos):
	var c = get_container_under_cursor(cursor_pos)
	if c != null and c.has_method("get_slot_under_pos"):
		var _item = equipment.items[c.get_slot_under_pos(cursor_pos).name]
		if _item != null:
			item_held = c.grab_item(_item.rect_global_position)
		if item_held != null:
			last_container = c
			last_pos = _item.rect_global_position
			inv_slots.move_child(item_held, inv_slots.get_child_count())
			_item.rect_global_position -= _item.rect_global_position - cursor_pos
			return
	if c != null and c.has_method("grab_item"):
		item_held = c.grab_item(cursor_pos)
		if item_held != null:
			last_container = c
			last_pos = item_held.rect_global_position
			inv_slots.move_child(item_held, inv_slots.get_child_count())
 
func release(cursor_pos):
	rotate_offset = Vector2.ZERO
	if item_held == null:
		return
	var c = get_container_under_cursor(cursor_pos)
	if c == garbage:
		drop_item(item_held.get_meta("id"))
	elif c.has_method("insert_item"):
		if c.insert_item(item_held):
			item_held = null
		else:
			if !replace():
				rotate = false
				return_item()
	else:
		if rotate:
			check_rotation(item_held)
			rotate = false
		return_item()

func get_container_under_cursor(cursor_pos):
	var containers = [grid, equipment, garbage, inv_base]
	for c in containers:
		if c.get_global_rect().has_point(cursor_pos):
			return c
	return null
 
func return_item():
	if item_held != null:
		_fail(item_held)
		item_held.rect_global_position = last_pos
		last_container.insert_item(item_held)
		item_held = null
 
func drop_item(item_id):
#	var loot = get_tree().root.get_node("scene_handler/" + GameState.map + "/YSort/Loot")
	var loot = get_tree().root.get_node("scene_handler").loaded_scene.get_node("YSort/Loot")
	var item = item_drop.instance()
	item.set_meta("id", item_id)
#	item.get_node("Sprite").texture = load(_item_database.get_item(item_id)["icon"])
	item.get_node("Sprite").texture = load("res://assets/world/dropped_item.png")
	loot.add_child(item)
#	item.global_position = get_tree().root.get_node("scene_handler/" + GameState.map + "/YSort/Entities/Player").global_position
	item.global_position = get_tree().root.get_node("scene_handler").loaded_scene.get_node("YSort/Entities/Player").global_position
	item.set_meta("map_id", GameState.data.state.loot[GameState.data.state.map].size())
	GameState.data.state.loot[GameState.data.state.map][GameState.data.state.loot[GameState.data.state.map].size()] = \
		{"id":item_id, "pos":{"x":item.global_position.x, "y":item.global_position.y}}
	item_held.queue_free()
	item_held = null

func pickup_item(item_id):
	var item = item_base.instance()
	item.set_meta("id", item_id)
	item.get_node("Focus/Img").texture = load(_item_database.get_item(item_id)["icon"])
	inv_slots.add_child(item)
	item.rotate()
	if !grid.insert_item_at_first_available_spot(item):
		inv_slots.get_node(item).queue_free()
		return false
	return true
