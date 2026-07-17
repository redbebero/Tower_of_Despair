extends Node

# CombatManager Singleton

signal combat_started
signal combat_ended(win)
signal combat_ui_update
signal log_message(msg)

var current_monster = {}
var is_raid_mode = false
var raid_turn = 0
var max_raid_turn = 10
var raid_total_damage = 0

var is_arena_mode = false
var arena_wave = 1
var arena_total_gold = 0
var arena_total_exp = 0

var is_pvp_mode = false

func calc_damage(atk: float, def: float) -> int:
	var damage = atk * (100.0 / (100.0 + def))
	var rand_factor = 0.9 + randf() * 0.2
	return int(max(1.0, floor(damage * rand_factor)))

func start_combat(is_boss: bool):
	if PlayerData.is_dead:
		return

	is_raid_mode = false
	is_arena_mode = false
	is_pvp_mode = false

	var pool = Database.boss_monsters if is_boss else Database.base_monsters
	var monster_index = 0
	if is_boss:
		monster_index = int(min(pool.size() - 1, floor(PlayerData.player.floor / 5.0)))
	else:
		monster_index = randi() % pool.size()

	var base_monster = pool[monster_index]
	current_monster = base_monster.duplicate()

	# Scale monster stats by floor
	var scale = 1.0 + (PlayerData.player.floor * 0.25)
	current_monster.hp = int(floor(current_monster.hp * scale))
	current_monster.maxHp = current_monster.hp
	current_monster.atk = int(floor(current_monster.atk * scale))
	current_monster.def = int(floor(current_monster.def * scale))
	current_monster.exp = int(floor(current_monster.exp * scale))
	current_monster.gold = int(floor(current_monster.gold * scale))

	if is_boss:
		current_monster.hp *= 2
		current_monster.maxHp = current_monster.hp
		current_monster.atk = int(floor(current_monster.atk * 1.5))
		current_monster.name = "👑 " + current_monster.name

	log_message.emit("<hr><span class='damage'>%s 등장!</span>" % current_monster.name)
	combat_started.emit()
	combat_ui_update.emit()

func start_turn(action: String):
	if current_monster.is_empty() or PlayerData.is_dead:
		return

	var player = PlayerData.player

	if is_raid_mode:
		if action == "skill" and player.mp < player.skillCost:
			log_message.emit("마나 부족!")
			return
		if action == "heal" and player.potions <= 0:
			log_message.emit("포션 없음!")
			return

		do_player_action(action, func():
			raid_turn += 1
			log_message.emit("🌌 [레이드 턴 %d/%d]" % [raid_turn, max_raid_turn])
			combat_ui_update.emit()
			if raid_turn >= max_raid_turn:
				end_raid()
		)
		return

	if action == "skill" and player.mp < player.skillCost:
		log_message.emit("마나 부족!")
		return
	if action == "heal" and player.potions <= 0:
		log_message.emit("포션 없음!")
		return

	if action == "run" or action == "heal" or player.speed >= current_monster.speed:
		if player.speed >= current_monster.speed and action != "run" and action != "heal":
			log_message.emit("<span class='highlight'>⚡ 선공!</span>")

		do_player_action(action, func():
			if not current_monster.is_empty() and current_monster.hp > 0:
				do_enemy_action(func(): end_phase())
		)
	else:
		log_message.emit("<span class='damage'>⚡ 적 선공!</span>")
		do_enemy_action(func():
			if not PlayerData.is_dead and not current_monster.is_empty():
				do_player_action(action, func(): end_phase())
		)

func do_player_action(type: String, next: Callable):
	var player = PlayerData.player

	if type == "run":
		if is_raid_mode:
			log_message.emit("레이드 도주 불가!")
			return
		if is_pvp_mode:
			log_message.emit("<b><span style='color:#e74c3c;'>결투장에서 기권했습니다.</span></b>")
			player.hp = 1
			is_pvp_mode = false
			current_monster = {}
			combat_ended.emit(false)
			PlayerData.stats_changed.emit()
			return
		if is_arena_mode:
			log_message.emit("<b><span style='color:#e67e22;'>투기장 전투를 중단하고 무사히 빠져나왔습니다.</span></b>")
			is_arena_mode = false
			current_monster = {}
			combat_ended.emit(false)
			PlayerData.stats_changed.emit()
			SaveManager.save_current_player()
			return
		if randf() < 0.3:
			log_message.emit("도망 성공!")
			current_monster = {}
			combat_ended.emit(false)
			return
		else:
			log_message.emit("도망 실패!")
			next.call()
			return

	if type == "heal":
		player.potions -= 1
		player.hp = int(min(player.maxHp, player.hp + 150))
		log_message.emit("<span class='heal'>포션 회복 (+150).</span>")
		PlayerData.stats_changed.emit()
		combat_ui_update.emit()
		next.call()
		return

	var dmg = 0

	if type == "attack":
		dmg = calc_damage(player.atk, current_monster.def)
		if randf() < (player.critRate / 100.0):
			dmg *= 2
			log_message.emit("<b><span class='highlight'>크리티컬!</span></b>")
	elif type == "skill":
		player.mp -= player.skillCost
		match player.skill:
			"대지가르기", "파이어볼", "연속베기", "조준사격":
				dmg = calc_damage(player.atk * 2.5, current_monster.def * 0.5)
			"극발도":
				dmg = calc_damage(player.atk * 3.5, 0)
			"광란":
				dmg = calc_damage(player.atk * 4.0, current_monster.def)
				player.hp -= 20
			"메테오":
				dmg = calc_damage(player.atk * 4.5, current_monster.def)
			"헤드샷":
				dmg = calc_damage(player.atk * 3.5, current_monster.def * 0.2)
			"생명흡수":
				dmg = calc_damage(player.atk * 2.5, current_monster.def)
				player.hp = int(min(player.maxHp, player.hp + floor(dmg * 0.3)))
			"절명":
				dmg = calc_damage(player.atk * 2.0, current_monster.def)
				if randf() < 0.5:
					dmg *= 3
			"환영분신":
				dmg = calc_damage(player.atk * 3.0, current_monster.def)
				# evadeRate 임시 증가는 do_enemy_action에서 회피율로만 반영됨 (영구 누적 방지)
			"폭풍우":
				dmg = calc_damage(player.atk * 3.0, current_monster.def)
			"궁극검무":
				dmg = calc_damage(player.atk * 5.0, 0)
			"피의축제":
				dmg = calc_damage(player.atk * 6.0, current_monster.def)
				player.hp -= 50
			"아마겟돈":
				dmg = calc_damage(player.atk * 7.0, current_monster.def * 0.5)
			"그림자참수":
				dmg = calc_damage(player.atk * 4.0, current_monster.def)
				if randf() < 0.4:
					dmg *= 4

	if randf() < (player.comboRate / 100.0):
		log_message.emit("<b><span class='epic'>🌪️ 연격 2배!</span></b>")
		dmg *= 2

	var m_trait = current_monster.get("trait", "무특성")
	if m_trait == "암살" or m_trait == "기민함":
		if randf() < 0.2:
			log_message.emit("적 회피!")
			PlayerData.stats_changed.emit()
			combat_ui_update.emit()
			next.call()
			return

	if m_trait == "단단함":
		dmg = int(floor(dmg * 0.8))

	# Apply damage
	current_monster.hp -= dmg
	if is_raid_mode:
		raid_total_damage += dmg
		log_message.emit("<span style='color:#00ffff;'>누적: %s</span>" % format_number(raid_total_damage))

	log_message.emit("적에게 <span class='highlight'>%d</span> 피해!" % dmg)

	if m_trait == "반사":
		var ref_dmg = int(floor(dmg * 0.1))
		player.hp -= ref_dmg
		log_message.emit("<span class='damage'>적의 가시 갑옷! (%d 반사 피해)</span>" % ref_dmg)

	if current_monster.hp > 0 and player.hasMercenary:
		var md = calc_damage(50, current_monster.def)
		current_monster.hp -= md
		log_message.emit("<span class='heal'>용병 지원 (%d)</span>" % md)

	PlayerData.stats_changed.emit()
	combat_ui_update.emit()

	if is_raid_mode:
		next.call()
		return

	if player.hp <= 0:
		player.hp = 0
		game_over()
	elif current_monster.hp <= 0:
		win_combat()
	else:
		next.call()

func do_enemy_action(next: Callable):
	var player = PlayerData.player
	if randf() < (player.evadeRate / 100.0):
		log_message.emit("<span class='heal'>회피 성공!</span>")
		next.call()
		return

	if is_raid_mode:
		var td = int(floor(player.maxHp * 0.3))
		player.hp -= td
		log_message.emit("<span class='damage'>🐉 마룡 고정피해 (%d)!</span>" % td)
		PlayerData.stats_changed.emit()
		combat_ui_update.emit()
		if player.hp <= 0:
			player.hp = 0
			end_raid()
		else:
			next.call()
		return

	var eDmg = calc_damage(current_monster.atk, player.def)
	var m_trait = current_monster.get("trait", "무특성")
	var crit_chance = 0.25 if m_trait == "암살" else 0.1
	if randf() < crit_chance:
		eDmg = int(floor(eDmg * 1.5))
		log_message.emit("<span class='damage'>적 치명타!</span>")
		
	player.hp -= eDmg
	log_message.emit("적 공격! (%d 피해)" % eDmg)
	
	if m_trait == "흡혈":
		current_monster.hp = int(min(current_monster.maxHp, current_monster.hp + floor(eDmg * 0.3)))
		
	PlayerData.stats_changed.emit()
	combat_ui_update.emit()

	if player.hp <= 0:
		player.hp = 0
		if is_pvp_mode:
			log_message.emit("<hr><b><span class='damage'>결투에서 패배했습니다... (사망 패널티 없음)</span></b>")
			player.hp = 1
			is_pvp_mode = false
			current_monster = {}
			PlayerData.stats_changed.emit()
			combat_ended.emit(false)
			return
		game_over()
	else:
		next.call()

func end_phase():
	if current_monster.is_empty() or PlayerData.is_dead:
		return
	var player = PlayerData.player
	var m_trait = current_monster.get("trait", "무특성")
	if is_raid_mode:
		return
		
	if m_trait == "파멸":
		current_monster.atk += int(max(1, floor(current_monster.atk * 0.15)))
	if m_trait == "맹독":
		player.hp -= int(max(1, floor(player.maxHp * 0.05)))
		if player.hp <= 0:
			player.hp = 0
			game_over()
			return
	if m_trait == "재생":
		current_monster.hp = int(min(current_monster.maxHp, current_monster.hp + floor(current_monster.maxHp * 0.05)))
		
	if player.pet and player.pet.get("hpRegen", 0) > 0:
		player.hp = int(min(player.maxHp, player.hp + player.pet.hpRegen))
		
	PlayerData.stats_changed.emit()
	combat_ui_update.emit()
	SaveManager.save_current_player()

func win_combat():
	var player = PlayerData.player
	if is_arena_mode:
		arena_total_gold += current_monster.gold
		arena_total_exp += current_monster.exp
		log_message.emit("<span class='heal'>✔ 처치! 누적 골드: %sG</span>" % format_number(arena_total_gold))
		
		arena_wave += 1
		log_message.emit("<hr><b><span style='color:#e67e22;'>투기장 %d웨이브 몬스터 난입!</span></b>" % arena_wave)
		
		if arena_wave % 5 == 0:
			player.soulStones += 1
			log_message.emit("<b><span class='epic'>[연승 특별 보상] 영혼석 1개를 획득했습니다!</span></b>")
			
		PlayerData.stats_changed.emit()
		combat_ui_update.emit()
		
		# Next monster after short delay (using a mock timer or direct call)
		get_tree().create_timer(0.8).timeout.connect(start_arena_combat)
		return

	if is_pvp_mode:
		log_message.emit("<hr><b><span class='epic'>결투 승리!! 보상으로 %sG를 획득했습니다!</span></b>" % format_number(current_monster.gold))
		player.gold += current_monster.gold
		player.exp += current_monster.exp
		is_pvp_mode = false
		current_monster = {}
		PlayerData.check_level_up()
		PlayerData.stats_changed.emit()
		combat_ended.emit(true)
		SaveManager.save_current_player()
		return

	log_message.emit("<b><span style='color:#3498db;'>승리!</span></b>")
	player.exp += current_monster.exp
	player.gold += current_monster.gold
	player.quests["killed"] = player.quests.get("killed", 0) + 1
	
	# Stat increase on win
	var bHp = randi_range(2, 4)
	var bAtk = 1 if randf() < 0.4 else 0
	var bDef = 1 if randf() < 0.3 else 0
	player.absHp += bHp
	player.absAtk += bAtk
	player.absDef += bDef
	PlayerData.calc_stats()
	player.hp = int(min(player.maxHp, player.hp + bHp * pow(1.2, player.reincarnation)))
	
	# Drops
	var is_boss = player.floor % 5 == 0
	var drop_stone_chance = 1.0 if is_boss else 0.6
	if randf() < drop_stone_chance:
		player.inventory["강화석"] = player.inventory.get("강화석", 0) + 1
	if is_boss and randf() < 0.8:
		player.scrolls += 1
	if randf() < 0.1:
		drop_card(current_monster.name)
	if randf() < 0.25:
		player.inventory["미확인 씨앗"] = player.inventory.get("미확인 씨앗", 0) + 1
		log_message.emit("<b><span style='color:#2ecc71;'>[미확인 씨앗]을 획득했습니다! 온실에서 재배하세요.</span></b>")

	PlayerData.check_level_up()
	current_monster = {}
	PlayerData.stats_changed.emit()
	combat_ended.emit(true)
	SaveManager.save_current_player()

func drop_card(monster_name: String):
	var player = PlayerData.player
	var base_name = monster_name.replace("[5W] ", "").replace("투기장 ", "").replace("💀 ", "").replace("👑 ", "")
	if not player.has("cards"):
		player.cards = {}
	if not player.cards.has(base_name):
		player.cards[base_name] = 1
		log_message.emit("<b><span style='color:#00ffff;'>[도감] 새로운 카드 획득! : %s</span></b>" % base_name)
	else:
		player.cards[base_name] += 1
		log_message.emit("<span style='color:#aaa;'>[도감] 중복 카드 획득 : %s (보유: %d장)</span>" % [base_name, player.cards[base_name]])
	PlayerData.calc_stats()
	PlayerData.stats_changed.emit()

func end_raid():
	var player = PlayerData.player
	var reward = int(floor(raid_total_damage * 0.1))
	if reward < 500:
		reward = 500
	player.gold += reward
	log_message.emit("<hr><span class='epic'>🏆 레이드 종료!</span>")
	log_message.emit("총 피해량: %s" % format_number(raid_total_damage))
	log_message.emit("보상: 💰 %s 골드" % format_number(reward))
	
	is_raid_mode = false
	raid_total_damage = 0
	current_monster = {}
	PlayerData.stats_changed.emit()
	combat_ended.emit(true)

func game_over():
	if is_arena_mode:
		var player = PlayerData.player
		log_message.emit("<hr><span class='damage'>💀 투기장 패배...</span>")
		log_message.emit("최종 웨이브: %d" % arena_wave)
		log_message.emit("보상: 💰 %s / EXP %s" % [format_number(arena_total_gold), format_number(arena_total_exp)])
		player.gold += arena_total_gold
		player.exp += arena_total_exp
		is_arena_mode = false
		current_monster = {}
		PlayerData.check_level_up()
		PlayerData.stats_changed.emit()
		combat_ended.emit(false)
		return

	PlayerData.is_dead = true
	log_message.emit("<hr><b><span class='damage'>💀 사망...</span></b>")
	PlayerData.player_died.emit()
	PlayerData.stats_changed.emit()

func revive():
	PlayerData.is_dead = false
	is_arena_mode = false
	is_pvp_mode = false
	var pen = int(floor(PlayerData.player.gold * 0.1))
	PlayerData.player.gold = int(max(0, PlayerData.player.gold - pen))
	PlayerData.player.hp = PlayerData.player.maxHp
	current_monster = {}
	log_message.emit("<hr><span class='heal'>마을에서 부활했습니다. (-%dG)</span>" % pen)
	PlayerData.stats_changed.emit()
	combat_ended.emit(false)
	SaveManager.save_current_player()

func start_arena():
	if PlayerData.is_dead:
		return
	if PlayerData.player.gold < 1000:
		log_message.emit("<span class='damage'>골드가 부족합니다. (1,000G 필요)</span>")
		return
	
	PlayerData.player.gold -= 1000
	PlayerData.stats_changed.emit()
	log_message.emit("<span class='highlight'>1,000G를 지불하고 무한 방어전에 입장했습니다!</span>")
	
	is_arena_mode = true
	is_raid_mode = false
	is_pvp_mode = false
	arena_wave = 1
	arena_total_gold = 0
	arena_total_exp = 0
	start_arena_combat()

func start_arena_combat():
	if PlayerData.is_dead or not is_arena_mode:
		return
	
	var base_m = Database.base_monsters[randi() % Database.base_monsters.size()]
	var m = base_m.duplicate()
	var scale = 2.0 + randf() * 2.0
	
	m.hp = int(floor(m.hp * scale))
	m.maxHp = m.hp
	m.atk = int(floor(m.atk * scale))
	m.def = int(floor(m.def * scale))
	m.exp = int(floor(m.exp * scale * 2.0))
	m.gold = int(floor(m.gold * scale * 2.0))
	
	current_monster = m
	current_monster.name = "🏟️ [투기장] " + m.name
	log_message.emit("<hr>투기장 맹수 <b><span class='damage'>%s</span></b> 출현!" % m.name)
	
	combat_started.emit()
	combat_ui_update.emit()

func enter_raid():
	if PlayerData.is_dead or not check_raid_cooldown():
		return
	
	is_raid_mode = true
	is_arena_mode = false
	is_pvp_mode = false
	raid_turn = 0
	max_raid_turn = 10
	raid_total_damage = 0
	
	PlayerData.player.lastRaidTime = Time.get_unix_time_from_system() * 1000 # milliseconds
	SaveManager.save_current_player()
	
	current_monster = {
		"name": "🐉 차원의 마룡",
		"hp": 999999999,
		"maxHp": 999999999,
		"atk": 0,
		"def": int(PlayerData.player.atk * 0.8),
		"exp": 0,
		"gold": 0,
		"speed": 0,
		"trait": "파멸"
	}
	
	log_message.emit("<hr><span class='epic'>🐉 차원의 마룡 등장! 10턴 동안 최대한 많은 피해를 입혀라!</span>")
	combat_started.emit()
	combat_ui_update.emit()

func check_raid_cooldown() -> bool:
	var now = Time.get_unix_time_from_system() * 1000 # ms
	var cooldown = 5 * 60 * 1000 # 5 min
	var last_time = PlayerData.player.lastRaidTime
	var diff = now - last_time
	if diff < cooldown:
		var remain = int(ceil((cooldown - diff) / 1000.0))
		log_message.emit("<span class='damage'>아직 마룡이 출현할 때가 아닙니다. (%d초 남음)</span>" % remain)
		return false
	return true

func start_pvp():
	if PlayerData.player.hp < PlayerData.player.maxHp:
		log_message.emit("<span class='damage'>체력을 가득 채운 후 도전하세요!</span>")
		return
		
	log_message.emit("⚔️ 결투 상대를 찾는 중...")
	var leaderboard = SaveManager.get_leaderboard()
	if leaderboard.is_empty():
		SaveManager.fetch_leaderboard()
		log_message.emit("랭킹을 불러오는 중입니다. 잠시 후 다시 도전하세요.")
		return
	var opponents = []
	for entry in leaderboard:
		# Exclude current player
		if entry.get("uid", "") != SaveManager.current_uid or entry.get("job", "") != PlayerData.player.job:
			opponents.append(entry)
			
	if opponents.is_empty():
		log_message.emit("<span class='damage'>상대를 찾을 수 없습니다. (현재 등록된 다른 유저가 없습니다)</span>")
		return
		
	var enemy = opponents[randi() % opponents.size()]
	is_pvp_mode = true
	is_raid_mode = false
	is_arena_mode = false
	
	current_monster = {
		"name": "[유저] %s (%s)" % [enemy.nickname, enemy.job],
		"trait": "무특성",
		"hp": enemy.hp,
		"maxHp": enemy.hp,
		"atk": enemy.atk,
		"def": enemy.def,
		"speed": enemy.speed,
		"exp": enemy.level * 30,
		"gold": enemy.level * 100
	}
	
	log_message.emit("<hr><b><span class='damage'>결투 시작! 상대는 Lv.%d %s(%s) 입니다!</span></b>" % [enemy.level, enemy.nickname, enemy.job])
	combat_started.emit()
	combat_ui_update.emit()

func format_number(val: int) -> String:
	# GDScript simple comma formatting
	var text = str(val)
	var result = ""
	var length = text.length()
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			result += ","
		result += text[i]
	return result
