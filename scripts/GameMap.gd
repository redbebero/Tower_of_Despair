extends Control

# GameMap script for 11x11 Grid Map in Godot

signal nearby_entity_changed(menu_id)
signal map_changed
signal log_message(msg)

const MAP_SIZE = 11
const CELL_SIZE = 40 # px

var map_entities = []
var map_player_pos = Vector2i(5, 5)
var current_menu_mode = "map"

# Cache colors
const COLOR_TOWN = Color("151522") # Premium dark background
const COLOR_DUNGEON = Color("0d0d12")

var is_in_town = true

func _ready():
	# Configure this node
	custom_minimum_size = Vector2(MAP_SIZE * CELL_SIZE, MAP_SIZE * CELL_SIZE)

func load_town_map():
	is_in_town = true
	map_entities = [
		{ "x": 5, "y": 1, "icon": "🏰", "menuId": "tower-entrance", "name": "절망의탑" },
		{ "x": 1, "y": 1, "icon": "🏆", "menuId": "ranking", "name": "명예의전당" },
		{ "x": 9, "y": 1, "icon": "⚔️", "menuId": "pvp", "name": "결투장" },
		{ "x": 1, "y": 3, "icon": "🛏️", "menuId": "inn", "name": "여관" },
		{ "x": 9, "y": 3, "icon": "🏪", "menuId": "shop", "name": "상점" },
		{ "x": 3, "y": 3, "icon": "🌌", "menuId": "rift", "name": "차원의틈" },
		{ "x": 7, "y": 3, "icon": "🏟️", "menuId": "arena", "name": "투기장" },
		{ "x": 1, "y": 6, "icon": "🔨", "menuId": "blacksmith", "name": "대장간" },
		{ "x": 9, "y": 6, "icon": "👴", "menuId": "npc", "name": "촌장" },
		{ "x": 3, "y": 7, "icon": "🎣", "menuId": "fishing", "name": "낚시터" },
		{ "x": 7, "y": 7, "icon": "⛺", "menuId": "blackmarket", "name": "암시장" },
		{ "x": 1, "y": 8, "icon": "🌱", "menuId": "greenhouse", "name": "온실" },
		{ "x": 9, "y": 8, "icon": "🏛️", "menuId": "museum", "name": "도감" },
		{ "x": 5, "y": 9, "icon": "⛏️", "menuId": "ruins", "name": "지하유적" }
	]
	map_player_pos = Vector2i(5, 5)
	current_menu_mode = "map"
	check_nearby_entities()
	queue_redraw()
	map_changed.emit()

func enter_tower():
	if PlayerData.is_dead:
		return
	is_in_town = false
	var floor = PlayerData.player.floor
	log_message.emit("<hr>🏰 %d층 진입..." % floor)
	
	map_entities = []
	if floor % 5 == 0:
		map_entities.append({ "x": 5, "y": 3, "icon": "💀", "isMonster": true, "isBoss": true, "name": "보스" })
		map_entities.append({ "x": 5, "y": 1, "icon": "🔼", "isStairs": true, "name": "다음 층" })
	else:
		map_entities.append({ "x": 5, "y": 1, "icon": "🔼", "isStairs": true, "name": "다음 층" })
		var mob_count = randi() % 3 + 3 # 3 to 5 monsters
		for i in range(mob_count):
			var mx = randi() % MAP_SIZE
			var my = randi() % 7 + 2 # y between 2 and 8
			
			# Avoid overlaps with existing entities and the player spawn at (5,9)
			var overlap = false
			for ent in map_entities:
				if ent.x == mx and ent.y == my:
					overlap = true
					break
			if not overlap and not (mx == 5 and my == 9):
				map_entities.append({ "x": mx, "y": my, "icon": "👹", "isMonster": true, "isBoss": false })
				
	map_player_pos = Vector2i(5, 9)
	current_menu_mode = "map"
	check_nearby_entities()
	queue_redraw()
	map_changed.emit()

func move_player(dx: int, dy: int):
	if PlayerData.is_dead or CombatManager.is_raid_mode or CombatManager.is_arena_mode or CombatManager.is_pvp_mode or not CombatManager.current_monster.is_empty():
		return
	
	var nx = map_player_pos.x + dx
	var ny = map_player_pos.y + dy
	
	if nx >= 0 and nx < MAP_SIZE and ny >= 0 and ny < MAP_SIZE:
		map_player_pos.x = nx
		map_player_pos.y = ny
		
		# Check if stepped on stairs or monsters
		var tile = null
		for ent in map_entities:
			if ent.x == nx and ent.y == ny:
				tile = ent
				break
				
		if tile:
			if tile.get("isMonster", false):
				CombatManager.start_combat(tile.get("isBoss", false))
				# Remove monster from entities list when starting combat (win_combat will filter it out)
				CombatManager.combat_ended.connect(func(win):
					if win and not current_menu_mode == "combat":
						map_entities.erase(tile)
						check_nearby_entities()
						queue_redraw()
						map_changed.emit()
				, CONNECT_ONE_SHOT)
			elif tile.get("isStairs", false):
				var mobs_left = 0
				for ent in map_entities:
					if ent.get("isMonster", false):
						mobs_left += 1
				if mobs_left > 0:
					log_message.emit("<span class='damage'>층을 넘어가려면 남은 몬스터(%d마리)를 모두 잡아야 합니다!</span>" % mobs_left)
				else:
					next_floor()
					return
		
		check_nearby_entities()
		queue_redraw()
		map_changed.emit()

func next_floor():
	PlayerData.player.floor += 1
	log_message.emit("<b><span class='highlight'>계단을 발견했습니다! [%d층]으로 올라갑니다.</span></b>" % PlayerData.player.floor)
	if PlayerData.player.quests:
		PlayerData.player.quests["floor"] = int(max(PlayerData.player.quests.get("floor", 1), PlayerData.player.floor))
	
	if PlayerData.player.floor > PlayerData.player.maxFloor:
		PlayerData.player.maxFloor = PlayerData.player.floor
		
	enter_tower()
	PlayerData.stats_changed.emit()
	SaveManager.save_current_player()

func check_nearby_entities():
	if PlayerData.is_dead or not CombatManager.current_monster.is_empty():
		return
		
	var nearby = null
	for ent in map_entities:
		# Manhattan distance <= 1: same tile or cardinal neighbors only (no diagonals)
		# Matches index.html: abs(e.x - playerX) + abs(e.y - playerY) <= 1
		if ent.has("menuId") and (abs(ent.x - map_player_pos.x) + abs(ent.y - map_player_pos.y)) <= 1:
			nearby = ent
			break
			
	if nearby:
		if nearby.menuId != current_menu_mode:
			current_menu_mode = nearby.menuId
			nearby_entity_changed.emit(nearby.menuId)
	else:
		# If in tower and combat isn't active, menu is tower-entrance or combat UI (handled separately)
		if not is_in_town:
			# In tower, if not fighting, default to map mode actions or combat
			if current_menu_mode != "map" and current_menu_mode != "combat":
				current_menu_mode = "map"
				nearby_entity_changed.emit("map")
		else:
			if current_menu_mode != "map":
				current_menu_mode = "map"
				nearby_entity_changed.emit("map")

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, size.x, size.y), COLOR_TOWN if is_in_town else COLOR_DUNGEON)
	
	# Draw grid lines (subtle)
	var grid_color = Color(1, 1, 1, 0.04) if is_in_town else Color(1, 0, 0, 0.03)
	for i in range(1, MAP_SIZE):
		draw_line(Vector2(i * CELL_SIZE, 0), Vector2(i * CELL_SIZE, size.y), grid_color)
		draw_line(Vector2(0, i * CELL_SIZE), Vector2(size.x, i * CELL_SIZE), grid_color)
		
	# Draw entities
	var nearby_ent = null
	for ent in map_entities:
		# Manhattan distance <= 1: same tile or cardinal neighbors only (no diagonals)
		if ent.has("menuId") and (abs(ent.x - map_player_pos.x) + abs(ent.y - map_player_pos.y)) <= 1:
			nearby_ent = ent
			break
			
	var default_font = ThemeDB.fallback_font
	
	for ent in map_entities:
		var pos = Vector2(ent.x * CELL_SIZE, ent.y * CELL_SIZE)
		# Draw icon centered
		draw_string(default_font, pos + Vector2(8, 28), ent.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		
		# Draw name if exists
		if ent.has("name"):
			var name_pos = pos + Vector2(20, 37)
			draw_string_outline(default_font, name_pos, ent.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, 2, Color.BLACK)
			draw_string(default_font, name_pos, ent.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.WHITE)
			
		# Draw interactive hint 💬
		if ent == nearby_ent and not CombatManager.is_raid_mode:
			draw_string(default_font, pos + Vector2(20, -2), "💬", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.YELLOW)
			
	# Draw player
	var p_icon = "🧍"
	if PlayerData.player.baseJob != "":
		match PlayerData.player.baseJob:
			"전사": p_icon = "🤺"
			"마법사": p_icon = "🧙‍♂️"
			"도적": p_icon = "🥷"
			"궁수": p_icon = "🏹"
			
	var p_pos = Vector2(map_player_pos.x * CELL_SIZE, map_player_pos.y * CELL_SIZE)
	# Draw playerCentered
	draw_string(default_font, p_pos + Vector2(8, 28), p_icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
