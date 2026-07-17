extends Node

# Main Scene Controller Script

# UI Nodes
@onready var login_screen = %LoginScreen
@onready var start_screen = %StartScreen
@onready var game_container = %GameContainer
@onready var auth_email = %AuthEmail
@onready var auth_password = %AuthPassword
@onready var auth_msg = %AuthMsg
@onready var job_select_container = %JobSelectContainer

# Player stats
@onready var p_job_label = %PlayerJob
@onready var p_level_label = %PlayerLevel
@onready var hp_bar = %HpBar
@onready var mp_bar = %MpBar
@onready var exp_bar = %ExpBar
@onready var cp_label = %PlayerCp
@onready var atk_label = %PlayerAtk
@onready var def_label = %PlayerDef
@onready var speed_label = %PlayerSpeed
@onready var combo_label = %PlayerCombo
@onready var crit_label = %PlayerCrit
@onready var evade_label = %PlayerEvade
@onready var weapon_label = %PlayerWeapon
@onready var armor_label = %PlayerArmor
@onready var relic_label = %PlayerRelic
@onready var pet_label = %PlayerPet
@onready var merc_buff_label = %MercBuff

# Currencies
@onready var gold_label = %GoldLabel
@onready var soulstone_label = %SoulstoneLabel
@onready var enhance_label = %EnhanceLabel
@onready var save_status = %SaveStatus

# Map & Logging
@onready var map_title = %MapTitle
@onready var game_map = %GameMap
@onready var log_window = %LogWindow

# Context panels (Tab/Menu modes)
@onready var action_tabs = %ActionTabs
# Individual action panels inside ActionTabs
@onready var map_actions = %MapActions
@onready var ranking_actions = %RankingActions
@onready var pvp_actions = %PvPActions
@onready var greenhouse_actions = %GreenhouseActions
@onready var museum_actions = %MuseumActions
@onready var tower_actions = %TowerEntranceActions
@onready var combat_actions = %CombatActions
@onready var shop_actions = %ShopActions
@onready var inn_actions = %InnActions
@onready var blacksmith_actions = %BlacksmithActions
@onready var npc_actions = %NpcActions
@onready var rift_actions = %RiftActions
@onready var arena_actions = %ArenaActions
@onready var fishing_actions = %FishingActions
@onready var blackmarket_actions = %BlackmarketActions
@onready var ruins_actions = %RuinsActions
@onready var gameover_actions = %GameoverActions

# Combat UI elements
@onready var m_name_label = %MonsterName
@onready var m_trait_label = %MonsterTrait
@onready var m_hp_bar = %MonsterHpBar
@onready var m_atk_label = %MonsterAtk
@onready var m_def_label = %MonsterDef
@onready var m_speed_label = %MonsterSpeed
@onready var m_floor_label = %MonsterFloor
@onready var btn_skill = %BtnSkill

# Ruins UI
@onready var ruins_msg = %RuinsMsg
@onready var ruins_grid = %RuinsGrid
@onready var btn_ruins_buy = %BtnRuinsBuy

# Greenhouse UI
@onready var greenhouse_pots = %GreenhousePots
@onready var seed_count_label = %SeedCountLabel

# Shop UI
@onready var shop_items_list = %ShopItemsList

# Dex UI
@onready var dex_collected = %DexCollected
@onready var dex_bonus = %DexBonus
@onready var dex_list = %DexList

# Quest UI
@onready var quest_kill_progress = %QuestKillProgress
@onready var quest_kill_bar = %QuestKillBar
@onready var quest_floor_progress = %QuestFloorProgress
@onready var quest_floor_bar = %QuestFloorBar
@onready var quest_gold_progress = %QuestGoldProgress
@onready var quest_gold_bar = %QuestGoldBar

# Inventory
@onready var inventory_grid = %InventoryGrid

# Global timer
var global_timer: Timer
var save_indicator_timer: Timer

# Ruins State
var ruins_state = { "active": false, "grid": [], "clicksLeft": 0 }

func _ready():
	# Connect signals
	PlayerData.stats_changed.connect(update_ui)
	PlayerData.player_died.connect(show_gameover)
	CombatManager.log_message.connect(add_log)
	CombatManager.combat_started.connect(show_combat_screen)
	CombatManager.combat_ended.connect(func(_win): show_map_screen())
	CombatManager.combat_ui_update.connect(update_combat_ui)
	SaveManager.auth_succeeded.connect(_on_firebase_auth_succeeded)
	SaveManager.auth_failed.connect(_on_firebase_auth_failed)
	SaveManager.leaderboard_loaded.connect(render_rankings)
	
	game_map.nearby_entity_changed.connect(switch_context_panel)
	game_map.log_message.connect(add_log)
	_connect_missing_input_buttons()
	
	# Start with login screen
	login_screen.visible = true
	start_screen.visible = false
	game_container.visible = false
	save_status.modulate.a = 0.0
	
	# Setup global timer
	global_timer = Timer.new()
	global_timer.wait_time = 1.0
	global_timer.autostart = true
	global_timer.timeout.connect(on_global_timer_tick)
	add_child(global_timer)
	
	save_indicator_timer = Timer.new()
	save_indicator_timer.wait_time = 1.5
	save_indicator_timer.one_shot = true
	save_indicator_timer.timeout.connect(func(): save_status.modulate.a = 0.0)
	add_child(save_indicator_timer)

func _connect_missing_input_buttons():
	# D-pad
	_connect_button(get_node("GameContainer/MainLayout/CenterPanel/Dpad/BtnUp"), Callable(self, "move_player").bind(0, -1))
	_connect_button(get_node("GameContainer/MainLayout/CenterPanel/Dpad/BtnLeft"), Callable(self, "move_player").bind(-1, 0))
	_connect_button(get_node("GameContainer/MainLayout/CenterPanel/Dpad/BtnDown"), Callable(self, "move_player").bind(0, 1))
	_connect_button(get_node("GameContainer/MainLayout/CenterPanel/Dpad/BtnRight"), Callable(self, "move_player").bind(1, 0))

	# PvP, tower floor selection, and combat actions
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/PvPActions/BtnFindPvp"), Callable(CombatManager, "start_pvp"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/TowerEntranceActions/FloorSelect/BtnPrevFloor"), Callable(self, "change_floor").bind(-1))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/TowerEntranceActions/FloorSelect/BtnNextFloor"), Callable(self, "change_floor").bind(1))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnAttack"), Callable(self, "start_combat_turn").bind("attack"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnSkill"), Callable(self, "start_combat_turn").bind("skill"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnUsePotion"), Callable(self, "start_combat_turn").bind("heal"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnRun"), Callable(self, "start_combat_turn").bind("run"))

	# NPC, rift, arena, and black market
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulAtk"), Callable(self, "upgrade_soul").bind("atk"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulDef"), Callable(self, "upgrade_soul").bind("def"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulHp"), Callable(self, "upgrade_soul").bind("hp"))
	_connect_button(%BtnRaidEnter, Callable(CombatManager, "enter_raid"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/ArenaActions/BtnEnterArena"), Callable(CombatManager, "start_arena"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExStone"), Callable(self, "buy_from_blackmarket").bind("stone"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExScroll"), Callable(self, "buy_from_blackmarket").bind("scroll"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExPotion"), Callable(self, "buy_from_blackmarket").bind("potion"))
	_connect_button(get_node("GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExCard"), Callable(self, "buy_from_blackmarket").bind("card"))

func _connect_button(button: BaseButton, callback: Callable):
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

# --- LOGIN & FIREBASE AUTH ---

func _on_firebase_auth_succeeded():
	auth_msg.text = "로그인 완료"
	show_character_select()

func _on_firebase_auth_failed(message: String):
	auth_msg.text = message

func handle_login():
	var email = auth_email.text.strip_edges()
	var pwd = auth_password.text.strip_edges()
	if email.length() < 5 or pwd.length() < 6:
		auth_msg.text = "정보를 확인해주세요."
		return
	
	auth_msg.text = "로그인 중..."
	SaveManager.sign_in(email, pwd)

func handle_signup():
	var email = auth_email.text.strip_edges()
	var pwd = auth_password.text.strip_edges()
	if email.length() < 5 or pwd.length() < 6:
		auth_msg.text = "정보를 확인해주세요."
		return
	
	auth_msg.text = "계정 생성 중..."
	SaveManager.sign_up(email, pwd)

func logout():
	login_screen.visible = true
	start_screen.visible = false
	game_container.visible = false
	log_window.text = ""
	SaveManager.clear_session()

# --- CHARACTER SELECT ---

func show_character_select():
	login_screen.visible = false
	start_screen.visible = true
	game_container.visible = false
	render_job_list()

func render_job_list():
	# Clear previous nodes
	for child in job_select_container.get_children():
		child.queue_free()
		
	var jobs = ["전사", "마법사", "도적", "궁수"]
	var icons = ["🛡️", "🔮", "🗡️", "🏹"]
	
	for i in range(jobs.size()):
		var job = jobs[i]
		var icon = icons[i]
		
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		
		var select_btn = Button.new()
		var has_save = SaveManager.cloud_saves.has(job)
		select_btn.text = "%s %s %s" % [icon, job, "(이어하기)" if has_save else "(새 시작)"]
		select_btn.custom_minimum_size = Vector2(250, 45)
		
		var normal_color = Color("1e8449") if has_save else Color("2c3e50")
		select_btn.add_theme_color_override("font_color", Color.WHITE)
		select_btn.pressed.connect(func(): select_job(job))
		
		# Stylize button
		var style = StyleBoxFlat.new()
		style.bg_color = normal_color
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		select_btn.add_theme_stylebox_override("normal", style)
		
		row.add_child(select_btn)
		
		var delete_btn = Button.new()
		delete_btn.text = "삭제"
		delete_btn.custom_minimum_size = Vector2(60, 45)
		delete_btn.disabled = not has_save
		delete_btn.pressed.connect(func(): delete_job_data(job))
		
		var delete_style = StyleBoxFlat.new()
		delete_style.bg_color = Color("c0392b") if has_save else Color("444444")
		delete_style.corner_radius_top_left = 6
		delete_style.corner_radius_top_right = 6
		delete_style.corner_radius_bottom_left = 6
		delete_style.corner_radius_bottom_right = 6
		delete_btn.add_theme_stylebox_override("normal", delete_style)
		
		row.add_child(delete_btn)
		job_select_container.add_child(row)

func select_job(job: String):
	if SaveManager.cloud_saves.has(job):
		var saved = SaveManager.cloud_saves[job]
		PlayerData.resume_game(job, saved)
	else:
		PlayerData.start_new_game(job)
		
	start_screen.visible = false
	game_container.visible = true
	game_map.load_town_map()
	
	add_log("<span class='epic'>☁️ [%s] 동기화 완료!</span>" % job)

func delete_job_data(job: String):
	# Direct delete to align with simplification guidelines
	SaveManager.delete_job(job)
	render_job_list()

func back_to_char_select():
	SaveManager.save_current_player()
	log_window.text = ""
	show_character_select()

# --- LOGGER ---

func add_log(msg: String):
	# Convert basic HTML styling tags to BBCode
	var bb = msg.replace("<span class='highlight'>", "[color=#f1c40f]").replace("<span class=\"highlight\">", "[color=#f1c40f]")
	bb = bb.replace("<span class='damage'>", "[color=#ff4757]").replace("<span class=\"damage\">", "[color=#ff4757]")
	bb = bb.replace("<span class='heal'>", "[color=#2ecc71]").replace("<span class=\"heal\">", "[color=#2ecc71]")
	bb = bb.replace("<span class='epic'>", "[color=#9b59b6]").replace("<span class=\"epic\">", "[color=#9b59b6]")
	bb = bb.replace("</span>", "[/color]")
	bb = bb.replace("<b>", "[b]").replace("</b>", "[/b]")
	bb = bb.replace("<hr>", "[color=#333]───────────────[/color]\n")
	
	log_window.text += bb + "\n"
	log_window.scroll_to_line(log_window.get_line_count() - 1)

# --- UI REFRESH (STATS, HUD) ---

func update_ui():
	var p = PlayerData.player
	if p == null or p.baseJob == "":
		return
		
	gold_label.text = CombatManager.format_number(p.gold)
	soulstone_label.text = CombatManager.format_number(p.soulStones)
	enhance_label.text = CombatManager.format_number(p.inventory.get("강화석", 0))
	
	p_job_label.text = p.job
	p_level_label.text = str(p.level)
	
	# Hp/Mp/Exp bars
	hp_bar.max_value = p.maxHp
	hp_bar.value = p.hp
	hp_bar.get_node("Text").text = "%d / %d" % [p.hp, p.maxHp]
	
	mp_bar.max_value = p.maxMp
	mp_bar.value = p.mp
	mp_bar.get_node("Text").text = "%d / %d" % [p.mp, p.maxMp]
	
	exp_bar.max_value = p.maxExp
	exp_bar.value = p.exp
	exp_bar.get_node("Text").text = "%d / %d" % [p.exp, p.maxExp]
	
	cp_label.text = CombatManager.format_number(p.cp)
	atk_label.text = str(p.atk)
	def_label.text = str(p.def)
	speed_label.text = str(p.speed)
	combo_label.text = "%.1f%%" % p.comboRate
	crit_label.text = "%d%%" % p.critRate
	evade_label.text = "%d%%" % p.evadeRate
	
	weapon_label.text = "%s +%d" % [p.weapon, p.weaponLevel]
	armor_label.text = p.armor
	relic_label.text = "+%d강" % p.relicLevel
	pet_label.text = p.pet.name if p.pet else "없음"
	merc_buff_label.text = "고용됨" if p.hasMercenary else "미고용"
	
	# Render Inventory
	render_inventory()
	
	# Render Quests
	render_quests()
	
	# Update active panel content depending on state
	if game_map.current_menu_mode == "greenhouse":
		render_greenhouse()
	elif game_map.current_menu_mode == "museum":
		render_dex()
	elif game_map.current_menu_mode == "shop":
		render_shop()
	elif game_map.current_menu_mode == "npc":
		render_npc_menu()
		
	# Show save indicator
	save_status.modulate.a = 1.0
	save_indicator_timer.start()

func render_inventory():
	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()
		
	var p = PlayerData.player
	var items = [
		{ "icon": "🧪", "name": "포션", "amt": p.potions },
		{ "icon": "📜", "name": "파방권", "amt": p.scrolls },
		{ "icon": "🃏", "name": "도감카드", "amt": p.cards.size() }
	]
	
	var extra_icons = {"미확인 씨앗":"🌱", "물고기":"🐟", "황금잉어":"🐠", "빈 깡통":"🥫"}
	for key in p.inventory.keys():
		if key != "강화석" and p.inventory[key] > 0:
			items.append({
				"icon": extra_icons.get(key, "📦"),
				"name": key,
				"amt": p.inventory[key]
			})
			
	# Render slots
	for item in items:
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(60, 60)
		
		# Add border/background style
		var style = StyleBoxFlat.new()
		style.bg_color = Color("0a0a0f")
		style.border_color = Color("333344")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		slot.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		
		var icon_lbl = Label.new()
		icon_lbl.text = item.icon
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 22)
		vbox.add_child(icon_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = item.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color("aaaaaa"))
		vbox.add_child(name_lbl)
		
		slot.add_child(vbox)
		
		# Amount badge
		var amt_lbl = Label.new()
		amt_lbl.text = str(item.amt)
		amt_lbl.add_theme_font_size_override("font_size", 9)
		amt_lbl.add_theme_color_override("font_color", Color("f1c40f"))
		amt_lbl.position = Vector2(40, 42)
		slot.add_child(amt_lbl)
		
		inventory_grid.add_child(slot)

func render_quests():
	var p = PlayerData.player
	var killed = p.quests.get("killed", 0)
	quest_kill_progress.text = "%d / 20" % killed
	quest_kill_bar.max_value = 20
	quest_kill_bar.value = killed
	
	var max_floor = p.maxFloor
	quest_floor_progress.text = "%d / 50" % max_floor
	quest_floor_bar.max_value = 50
	quest_floor_bar.value = max_floor
	
	var gold = p.gold
	var gold_target = 100000
	quest_gold_progress.text = "%s / 100K" % CombatManager.format_number(gold)
	quest_gold_bar.max_value = gold_target
	quest_gold_bar.value = int(min(gold, gold_target))

# --- MAP & CONTEXT SWITCH ---

func switch_context_panel(menu_id: String):
	# Normalize: strip hyphens so "tower-entrance" matches "TowerEntranceActions"
	var normalized_id = menu_id.to_lower().replace("-", "")
	for i in range(action_tabs.get_child_count()):
		var child = action_tabs.get_child(i)
		child.visible = (child.name.to_lower().begins_with(normalized_id))
		
	if menu_id == "tower-entrance":
		update_tower_entrance_ui()
	elif menu_id == "rift":
		update_rift_cooldown_text()
	elif menu_id == "ranking":
		load_rankings()
	elif menu_id == "ruins":
		render_ruins_grid(not ruins_state.active)

func show_map_screen():
	# If combat ended, check nearby context again
	game_map.check_nearby_entities()
	switch_context_panel(game_map.current_menu_mode)

func move_player(dx, dy):
	game_map.move_player(int(dx), int(dy))

# --- COMBAT PANEL HANDLERS ---

func show_combat_screen():
	switch_context_panel("combat")
	update_combat_ui()

func update_combat_ui():
	var mob = CombatManager.current_monster
	if mob.is_empty():
		return
		
	m_name_label.text = mob.name
	var trait_data = Database.monster_traits.get(mob.trait, { "text": "" })
	m_trait_label.text = trait_data.text
	
	m_hp_bar.max_value = mob.maxHp
	m_hp_bar.value = mob.hp
	m_hp_bar.get_node("Text").text = "%d / %d" % [mob.hp, mob.maxHp]
	
	m_atk_label.text = str(mob.atk)
	m_def_label.text = str(mob.def)
	m_speed_label.text = str(mob.speed)
	
	if CombatManager.is_raid_mode:
		m_floor_label.text = "레이드"
	elif CombatManager.is_arena_mode:
		m_floor_label.text = "투기장"
	elif CombatManager.is_pvp_mode:
		m_floor_label.text = "결투장"
	else:
		m_floor_label.text = "%d층" % PlayerData.player.floor
		
	# Update skill button text
	var skill_cost = PlayerData.player.skillCost
	btn_skill.text = "🔥 %s (-%d)" % [PlayerData.player.skill, skill_cost]

func start_combat_turn(action):
	CombatManager.start_turn(str(action))

# --- TOWERS / FLOORS ---

func update_tower_entrance_ui():
	var p = PlayerData.player
	%TargetFloorLabel.text = "%d / %d층" % [p.floor, p.maxFloor]
	%BtnEnterTower.text = "🚀 %d층 진입하기" % p.floor

func change_floor(dir):
	var p = PlayerData.player
	var next_f = p.floor + int(dir)
	p.floor = int(clamp(next_f, 1, p.maxFloor))
	update_tower_entrance_ui()

func enter_tower():
	game_map.enter_tower()
	show_map_screen()

# --- SHOP ACTIONS ---

func render_shop():
	# Clear shop
	for child in shop_items_list.get_children():
		child.queue_free()
		
	# Equipment DB rendering
	for eq in Database.equipment_db:
		var row = HBoxContainer.new()
		
		var icon = "🗡️" if eq.type == "무기" else "🛡️"
		var item_lbl = Label.new()
		item_lbl.text = "%s %s (+%d)" % [icon, eq.name, eq.stat]
		row.add_child(item_lbl)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		
		var buy_btn = Button.new()
		buy_btn.text = "%sG" % CombatManager.format_number(eq.price)
		buy_btn.pressed.connect(func(): buy_equip(eq.type, eq.name, eq.price, eq.stat))
		row.add_child(buy_btn)
		
		shop_items_list.add_child(row)

func buy_potion():
	var p = PlayerData.player
	if p.gold >= 50:
		p.gold -= 50
		p.potions += 1
		add_log("포션 구매 (-50G)")
		PlayerData.stats_changed.emit()
	else:
		add_log("골드가 부족합니다.")

func buy_scroll():
	var p = PlayerData.player
	if p.gold >= 2000:
		p.gold -= 2000
		p.scrolls += 1
		add_log("파방 주문서 구매 (-2,000G)")
		PlayerData.stats_changed.emit()
	else:
		add_log("골드가 부족합니다.")

func buy_equip(type: String, name: String, price: int, stat: int):
	var p = PlayerData.player
	if p.gold >= price:
		p.gold -= price
		if type == "무기":
			p.weapon = name
			p.weaponLevel = 0
			PlayerData.base_weapon_atk = stat
		else:
			p.armor = name
			PlayerData.base_armor_def = stat
		add_log("[%s] 장착! (-%dG)" % [name, price])
		PlayerData.calc_stats()
		PlayerData.stats_changed.emit()
	else:
		add_log("골드가 부족합니다.")

func sell_loot():
	var p = PlayerData.player
	var earned = 0
	if p.inventory.get("빈 깡통", 0) > 0:
		earned += p.inventory["빈 깡통"] * 5
		p.inventory["빈 깡통"] = 0
	if p.inventory.get("물고기", 0) > 0:
		earned += p.inventory["물고기"] * 50
		p.inventory["물고기"] = 0
	if p.inventory.get("황금잉어", 0) > 0:
		earned += p.inventory["황금잉어"] * 500
		p.inventory["황금잉어"] = 0
		
	if earned > 0:
		p.gold += earned
		add_log("<b><span class='highlight'>%dG</span></b>의 전리품을 모두 팔았습니다!" % earned)
		PlayerData.stats_changed.emit()
	else:
		add_log("팔 수 있는 전리품이 가방에 없습니다.")

func hire_mercenary():
	var p = PlayerData.player
	if p.gold >= 2000 and not p.hasMercenary:
		p.gold -= 2000
		p.hasMercenary = true
		add_log("용병 고용 완료!")
		PlayerData.stats_changed.emit()
	else:
		add_log("골드가 부족하거나 이미 용병이 고용되어 있습니다.")

# --- INN (REST) ---

func rest():
	var p = PlayerData.player
	var cost = 50 + ((p.level - 1) * 20)
	if p.gold >= cost:
		p.gold -= cost
		p.hp = p.maxHp
		p.mp = p.maxMp
		add_log("여관 휴식 (-%dG). 모든 체력/마나 회복." % cost)
		PlayerData.stats_changed.emit()
		game_map.load_town_map()
	else:
		add_log("골드가 부족합니다.")

# --- BLACKSMITH (ENHANCE) ---

func enhance_weapon():
	var p = PlayerData.player
	var cost = 200 + (p.weaponLevel * 150)
	var stones = p.inventory.get("강화석", 0)
	if p.gold < cost or stones < 1:
		add_log("골드나 강화석이 부족합니다!")
		return
		
	p.gold -= cost
	p.inventory["강화석"] -= 1
	
	var rate = max(0.2, 1.0 - (p.weaponLevel * 0.05))
	if randf() < rate:
		p.weaponLevel += 1
		add_log("[color=#f1c40f]강화 성공! (+%d)[/color]" % p.weaponLevel)
	else:
		add_log("강화 실패...")
		if p.weaponLevel >= 10:
			var use_scroll = %UseScrollCheckbox.button_pressed
			if use_scroll and p.scrolls > 0:
				p.scrolls -= 1
				add_log("주문서가 무기 파괴를 막았습니다!")
			else:
				p.weapon = "맨주먹"
				p.weaponLevel = 0
				PlayerData.base_weapon_atk = 0
				add_log("[color=#ff4757]무기가 파괴되었습니다![/color]")
				
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

# --- NPC ACTIONS & PROMOTION ---

func render_npc_menu():
	# Clear choices
	var container = %JobChoicesContainer
	for child in container.get_children():
		child.queue_free()
		
	var p = PlayerData.player
	var available = false
	
	for j in Database.job_stats.keys():
		var data = Database.job_stats[j]
		if data.get("reqJob", "") == p.job and p.level >= data.get("reqLvl", 1):
			available = true
			var btn = Button.new()
			btn.text = "%s 승급 (Lv.%d+)" % [j, data.reqLvl]
			btn.pressed.connect(func(): promote_job(j))
			container.add_child(btn)
			
	if not available:
		var lbl = Label.new()
		lbl.text = "현재 승급 가능한 직업이 없습니다."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color("aaaaaa"))
		container.add_child(lbl)

func promote_job(j: String):
	var p = PlayerData.player
	p.job = j
	p.promoted = true
	add_log("<b>[color=#f1c40f][%s][/color]</b>로 전직했습니다!" % j)
	PlayerData.calc_stats()
	p.hp = p.maxHp
	p.mp = p.maxMp
	PlayerData.stats_changed.emit()

func reset_job_tier():
	var p = PlayerData.player
	if p.job == p.baseJob:
		add_log("이미 1차 직업 상태입니다.")
		return
	p.job = p.baseJob
	p.promoted = false
	add_log("직업이 1차로 초기화되었습니다.")
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

func draw_pet():
	var p = PlayerData.player
	if p.gold < 1000:
		add_log("골드가 부족합니다.")
		return
	p.gold -= 1000
	var pet = Database.pet_db[randi() % Database.pet_db.size()]
	p.pet = pet
	add_log("<b>[color=#9b59b6][%s][/color]</b> 펫이 부화했습니다!" % pet.name)
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

func reincarnate():
	var p = PlayerData.player
	if p.maxFloor < 20:
		add_log("최고 도달 층수가 20층 이상이어야 환생할 수 있습니다.")
		return
		
	# Direct reincarnation reset
	p.reincarnation += 1
	p.soulStones += int(floor(p.maxFloor / 10.0))
	p.level = 1
	p.exp = 0
	p.maxExp = 50
	p.gold = 500
	p.floor = 1
	p.weapon = "맨주먹"
	p.weaponLevel = 0
	PlayerData.base_weapon_atk = 0
	p.armor = "평상복"
	PlayerData.base_armor_def = 0
	p.job = p.baseJob
	p.promoted = false
	
	PlayerData.calc_stats()
	p.hp = p.maxHp
	p.mp = p.maxMp
	add_log("<b>[color=#9b59b6]🌀 환생했습니다! 새로운 힘이 느껴집니다.[/color]</b>")
	PlayerData.stats_changed.emit()

func upgrade_soul(type):
	type = str(type)
	var p = PlayerData.player
	if p.soulStones < 10:
		add_log("영혼석이 부족합니다. (10개 필요)")
		return
	p.soulStones -= 10
	if type == "hp": p.soulHp += 50
	elif type == "atk": p.soulAtk += 5
	elif type == "def": p.soulDef += 5
	add_log("영혼이 강화되었습니다.")
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

func attempt_awakening():
	var p = PlayerData.player
	if p.isAwakened:
		add_log("이미 각성한 상태입니다.")
		return
	if p.hp <= 100:
		add_log("체력이 부족합니다. (100 초과 필요)")
		return
		
	p.hp -= 100
	if randf() < 0.015:
		p.isAwakened = true
		add_log("<b>[color=#ff4757]🩸 피의 제단이 응답했습니다... [초월 각성] 성공![/color]</b>")
	else:
		add_log("제단이 피를 삼켰으나 아무 일도 일어나지 않았습니다. (각성 실패)")
	PlayerData.stats_changed.emit()

# --- RIFT & TOWER RAID ---

func update_rift_cooldown_text():
	var lbl = %RaidCooldownText
	var btn = %BtnRaidEnter
	
	var last_time = PlayerData.player.lastRaidTime
	if last_time == 0:
		lbl.text = "지금 즉시 토벌 가능!"
		lbl.add_theme_color_override("font_color", Color("2ecc71"))
		btn.disabled = false
		return
		
	var diff = (Time.get_unix_time_from_system() * 1000) - last_time
	var cooldown = 5 * 60 * 1000
	
	if diff < cooldown:
		var remain = int(ceil((cooldown - diff) / 1000.0))
		var m = remain / 60
		var s = remain % 60
		lbl.text = "다음 출현까지: %d분 %d초" % [m, s]
		lbl.add_theme_color_override("font_color", Color("e74c3c"))
		btn.disabled = true
	else:
		lbl.text = "지금 즉시 토벌 가능!"
		lbl.add_theme_color_override("font_color", Color("2ecc71"))
		btn.disabled = false

func upgrade_relic():
	var p = PlayerData.player
	var cost = int(floor(100000 * pow(1.5, p.relicLevel)))
	if p.gold >= cost:
		p.gold -= cost
		p.relicLevel += 1
		add_log("<b>[color=#00ffff]🔮 유물이 +%d 단계로 강화됨![/color]</b>" % p.relicLevel)
		PlayerData.calc_stats()
		PlayerData.stats_changed.emit()
	else:
		add_log("골드 부족!")

# --- FISHING ---

func do_fishing():
	var p = PlayerData.player
	if p.mp < 10:
		add_log("마나가 부족합니다. (10 필요)")
		return
	p.mp -= 10
	add_log("🎣 찌를 던지고 기다립니다...")
	PlayerData.stats_changed.emit()
	
	# Fishing wait timer
	get_tree().create_timer(1.0).timeout.connect(func():
		var r = randf()
		if r < 0.3:
			p.inventory["빈 깡통"] = p.inventory.get("빈 깡통", 0) + 1
			add_log("<span style='color:#aaa;'>빈 깡통을 낚았습니다. (가방에 보관됨)</span>")
		elif r < 0.6:
			p.inventory["물고기"] = p.inventory.get("물고기", 0) + 1
			add_log("<span class='heal'>싱싱한 물고기를 낚았습니다! (가방에 보관됨)</span>")
		elif r < 0.85:
			p.inventory["황금잉어"] = p.inventory.get("황금잉어", 0) + 1
			add_log("<b>[color=#f1c40f]비늘이 금빛인 잉어를 낚았습니다! (가방에 보관됨)[/color]</b>")
		elif r < 0.98:
			p.inventory["강화석"] = p.inventory.get("강화석", 0) + 1
			add_log("<b>[color=#f1c40f]물고기 뱃속에서 강화석을 발견했습니다![/color]</b>")
		else:
			p.soulStones += 1
			add_log("<b>[color=#9b59b6]전설의 심해어! 영혼석을 1개 얻었습니다!![/color]</b>")
		PlayerData.stats_changed.emit()
	)

# --- BLACK MARKET ---

func buy_from_blackmarket(item_type):
	item_type = str(item_type)
	var p = PlayerData.player
	if item_type == "stone":
		if p.soulStones < 1: add_log("영혼석이 부족합니다."); return
		p.soulStones -= 1
		p.inventory["강화석"] = p.inventory.get("강화석", 0) + 5
		add_log("강화석 5개를 얻었습니다.")
	elif item_type == "scroll":
		if p.soulStones < 1: add_log("영혼석이 부족합니다."); return
		p.soulStones -= 1
		p.scrolls += 2
		add_log("파방 주문서 2장을 얻었습니다.")
	elif item_type == "potion":
		if p.soulStones < 1: add_log("영혼석이 부족합니다."); return
		p.soulStones -= 1
		p.potions += 10
		add_log("포션 10개를 얻었습니다.")
	elif item_type == "card":
		if p.soulStones < 2: add_log("영혼석이 부족합니다. (2개 필요)"); return
		p.soulStones -= 2
		var all = Database.base_monsters + Database.boss_monsters
		var r_mob = all[randi() % all.size()].name
		add_log("<b>[color=#00ffff]암시장 랜덤 카드팩을 열었습니다![/color]</b>")
		CombatManager.drop_card(r_mob)
		
	PlayerData.stats_changed.emit()

# --- RUINS MINIGAME ---

func buy_exploration_kit():
	var p = PlayerData.player
	if p.gold < 1000:
		add_log("골드가 부족합니다.")
		return
	if ruins_state.active:
		add_log("아직 진행 중인 탐사가 있습니다.")
		return
		
	p.gold -= 1000
	ruins_state.active = true
	ruins_state.clicksLeft = 5
	
	# Generate 16 grid cells
	var items = ["soul", "enhance", "enhance", "gold", "gold", "gold", "card"]
	var grid = []
	for i in range(16):
		if i < items.size():
			grid.append(items[i])
		else:
			grid.append("dirt")
			
	grid.shuffle()
	
	ruins_state.grid = []
	for type in grid:
		ruins_state.grid.append({ "type": type, "revealed": false })
		
	btn_ruins_buy.visible = false
	ruins_msg.text = "흙을 파내어 숨겨진 보물을 찾으세요! (남은 횟수: 5회)"
	render_ruins_grid(false)
	PlayerData.stats_changed.emit()

func render_ruins_grid(empty: bool):
	# Clear
	for child in ruins_grid.get_children():
		child.queue_free()
		
	for i in range(16):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(45, 45)
		
		var idx = i
		if empty:
			btn.text = "🟫"
			btn.disabled = true
		else:
			var cell = ruins_state.grid[idx]
			if cell.revealed:
				var icon = "🟫"
				match cell.type:
					"soul": icon = "💎"
					"enhance": icon = "⚙️"
					"gold": icon = "💰"
					"card": icon = "🃏"
				btn.text = icon
				btn.disabled = true
			else:
				btn.text = "🟫"
				btn.pressed.connect(func(): click_ruin(idx))
				
		ruins_grid.add_child(btn)

func click_ruin(idx: int):
	if not ruins_state.active or ruins_state.clicksLeft <= 0:
		return
		
	ruins_state.clicksLeft -= 1
	var cell = ruins_state.grid[idx]
	cell.revealed = true
	
	var p = PlayerData.player
	match cell.type:
		"soul":
			p.soulStones += 1
			add_log("<b>[color=#9b59b6][유적 발굴] 영혼석을 발견했습니다!![/color]</b>")
		"enhance":
			p.inventory["강화석"] = p.inventory.get("강화석", 0) + 1
			add_log("[유적 발굴] 강화석을 캐냈습니다!")
		"gold":
			p.gold += 2000
			add_log("<b>[color=#f1c40f][유적 발굴] 2,000G가 든 돈자루를 찾았습니다![/color]</b>")
		"card":
			var all = Database.base_monsters + Database.boss_monsters
			var r_mob = all[randi() % all.size()].name
			add_log("<b>[color=#00ffff][유적 발굴] 땅 속에서 오래된 카드를 발견했습니다![/color]</b>")
			CombatManager.drop_card(r_mob)
		"dirt":
			add_log("그냥 흙덩이입니다...")
			
	if ruins_state.clicksLeft <= 0:
		ruins_state.active = false
		ruins_msg.text = "탐사 키트 내구도가 다 되었습니다."
		btn_ruins_buy.visible = true
		# Reveal all
		for c in ruins_state.grid:
			c.revealed = true
	else:
		ruins_msg.text = "흙을 파내어 숨겨진 보물을 찾으세요! (남은 횟수: %d회)" % ruins_state.clicksLeft
		
	render_ruins_grid(false)
	PlayerData.stats_changed.emit()

# --- GREENHOUSE ---

func render_greenhouse():
	var p = PlayerData.player
	seed_count_label.text = str(p.inventory.get("미확인 씨앗", 0))
	
	# Clear
	for child in greenhouse_pots.get_children():
		child.queue_free()
		
	var now = Time.get_unix_time_from_system() * 1000 # ms
	for i in range(p.plants.size()):
		var pot = p.plants[i]
		var row = HBoxContainer.new()
		
		var lbl = Label.new()
		var btn = Button.new()
		
		var idx = i
		if pot.state == "empty":
			lbl.text = "🪴 빈 화분"
			btn.text = "씨앗 심기"
			btn.pressed.connect(func(): plant_seed(idx))
		elif pot.state == "growing":
			var left = int(ceil((pot.time - now) / 1000.0))
			if left < 0: left = 0
			lbl.text = "🌱 자라는 중..."
			btn.text = "%d초 남음" % left
			btn.disabled = true
		elif pot.state == "ready":
			lbl.text = "🍎 수확 가능!"
			btn.text = "수확하기"
			btn.pressed.connect(func(): harvest_plant(idx))
			
		row.add_child(lbl)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		
		row.add_child(btn)
		greenhouse_pots.add_child(row)

func plant_seed(idx: int):
	var p = PlayerData.player
	var seeds = p.inventory.get("미확인 씨앗", 0)
	if seeds < 1:
		add_log("미확인 씨앗이 없습니다. (탑의 몬스터가 드랍합니다)")
		return
		
	p.inventory["미확인 씨앗"] -= 1
	p.plants[idx] = {
		"state": "growing",
		"time": (Time.get_unix_time_from_system() * 1000) + 60000 # 1 minute
	}
	add_log("🌱 씨앗을 심었습니다! 1분 뒤에 수확할 수 있습니다.")
	PlayerData.stats_changed.emit()

func harvest_plant(idx: int):
	var p = PlayerData.player
	var pot = p.plants[idx]
	if pot.state != "ready":
		return
		
	var r = randf()
	if r < 0.25:
		p.absHp += 20
		add_log("<b>[color=#2ecc71][생명의 열매]를 수확했습니다! 최대 체력이 20 증가합니다.[/color]</b>")
	elif r < 0.5:
		p.absAtk += 3
		add_log("<b>[color=#ff4757][투신의 열매]를 수확했습니다! 공격력이 3 증가합니다.[/color]</b>")
	elif r < 0.75:
		p.absDef += 3
		add_log("<b>[color=#f1c40f][철벽의 열매]를 수확했습니다! 방어력이 3 증가합니다.[/color]</b>")
	else:
		p.gold += 3000
		add_log("<b>[color=#f1c40f][황금 사과]를 수확했습니다! 3,000G에 판매했습니다.[/color]</b>")
		
	p.plants[idx] = { "state": "empty", "time": 0 }
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

# --- MONSTER DEX ---

func render_dex():
	var p = PlayerData.player
	var collected = p.cards.size()
	dex_collected.text = str(collected)
	dex_bonus.text = str(collected)
	
	# Clear
	for child in dex_list.get_children():
		child.queue_free()
		
	var all = Database.base_monsters + Database.boss_monsters
	for m in all:
		var row = HBoxContainer.new()
		
		var name_lbl = Label.new()
		var count_lbl = Label.new()
		
		var has_card = p.cards.has(m.name)
		if has_card:
			name_lbl.text = "🃏 %s" % m.name
			name_lbl.add_theme_color_override("font_color", Color("2ecc71"))
			count_lbl.text = "보유: %d장" % p.cards[m.name]
			count_lbl.add_theme_color_override("font_color", Color("f1c40f"))
		else:
			name_lbl.text = "🃏 ??? (미수집)"
			name_lbl.add_theme_color_override("font_color", Color("666666"))
			count_lbl.text = "보유: 0장"
			count_lbl.add_theme_color_override("font_color", Color("666666"))
			
		row.add_child(name_lbl)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		
		row.add_child(count_lbl)
		dex_list.add_child(row)

# --- LEADERBOARD ---

func load_rankings():
	SaveManager.fetch_leaderboard()

func render_rankings():
	var container = %RankingList
	for child in container.get_children():
		child.queue_free()
		
	var list = SaveManager.get_leaderboard()
	for i in range(list.size()):
		var entry = list[i]
		var item = PanelContainer.new()
		var style = StyleBoxFlat.new()
		
		# If it's the current player, highlight
		var is_me = entry.get("uid", "") == SaveManager.current_uid and entry.get("job", "") == PlayerData.player.job
		style.bg_color = Color("2c2c00") if is_me else Color("1a1a24")
		style.border_color = Color("f1c40f") if is_me else Color("333344")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		item.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		
		var left_lbl = Label.new()
		left_lbl.text = "%d위. %s [%s]" % [i+1, entry.nickname, entry.job]
		hbox.add_child(left_lbl)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var right_vbox = VBoxContainer.new()
		var cp_lbl = Label.new()
		cp_lbl.text = "CP: %s" % CombatManager.format_number(entry.cp)
		cp_lbl.add_theme_color_override("font_color", Color("3498db"))
		right_vbox.add_child(cp_lbl)
		
		var details_lbl = Label.new()
		details_lbl.text = "최고 %d층 / Lv.%d" % [entry.get("maxFloor", 1), entry.get("level", 1)]
		details_lbl.add_theme_color_override("font_color", Color("2ecc71"))
		details_lbl.add_theme_font_size_override("font_size", 10)
		right_vbox.add_child(details_lbl)
		
		hbox.add_child(right_vbox)
		item.add_child(hbox)
		container.add_child(item)

# --- GLOBAL TICK & DEAD SCREEN ---

func on_global_timer_tick():
	if PlayerData.player == null or PlayerData.player.baseJob == "":
		return
		
	# Update greenhouse growing plants
	var needs_update = false
	var now = Time.get_unix_time_from_system() * 1000
	for pot in PlayerData.player.plants:
		if pot.state == "growing" and now >= pot.time:
			pot.state = "ready"
			needs_update = true
			
	if needs_update or game_map.current_menu_mode == "greenhouse":
		render_greenhouse()
		
	if game_map.current_menu_mode == "rift":
		update_rift_cooldown_text()
		
	# Auto-save triggers automatically inside PlayerData/CombatManager after operations, 
	# but we can also periodic-save locally if needed.

func show_gameover():
	switch_context_panel("gameover")

func revive():
	CombatManager.revive()
	game_map.load_town_map()
	show_map_screen()
