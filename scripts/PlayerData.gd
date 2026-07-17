extends Node

# Player Data Singleton

signal stats_changed
signal player_died

class PlayerState:
	var baseJob: String = ""
	var job: String = ""
	var promoted: bool = false
	var isAwakened: bool = false
	var relicLevel: int = 0
	var level: int = 1
	var exp: int = 0
	var maxExp: int = 50
	var gold: int = 500
	var potions: int = 5
	var scrolls: int = 0
	var hp: int = 0
	var maxHp: int = 0
	var mp: int = 0
	var maxMp: int = 0
	var baseAtk: int = 0
	var baseDef: int = 0
	var baseCrit: float = 0.0
	var baseEvade: float = 0.0
	var atk: int = 0
	var def: int = 0
	var critRate: float = 0.0
	var evadeRate: float = 0.0
	var speed: int = 0
	var comboRate: float = 0.0
	var skill: String = ""
	var skillCost: int = 0
	var weapon: String = "맨주먹"
	var weaponLevel: int = 0
	var armor: String = "평상복"
	var inventory: Dictionary = { "강화석": 0, "미확인 씨앗": 0 }
	var cards: Dictionary = {}
	var quests: Dictionary = { "killed": 0, "floor": 1 }
	var pet = null # Can be Dictionary or null
	var hasMercenary: bool = false
	var floor: int = 1
	var maxFloor: int = 1
	var reincarnation: int = 0
	var soulStones: int = 0
	var absHp: int = 0
	var absAtk: int = 0
	var absDef: int = 0
	var soulHp: int = 0
	var soulAtk: int = 0
	var soulDef: int = 0
	var cp: int = 0
	var lastRaidTime: float = 0.0
	var plants: Array = [
		{"state": "empty", "time": 0},
		{"state": "empty", "time": 0},
		{"state": "empty", "time": 0}
	]

	func to_dict() -> Dictionary:
		return {
			"baseJob": baseJob,
			"job": job,
			"promoted": promoted,
			"isAwakened": isAwakened,
			"relicLevel": relicLevel,
			"level": level,
			"exp": exp,
			"maxExp": maxExp,
			"gold": gold,
			"potions": potions,
			"scrolls": scrolls,
			"hp": hp,
			"maxHp": maxHp,
			"mp": mp,
			"maxMp": maxMp,
			"baseAtk": baseAtk,
			"baseDef": baseDef,
			"baseCrit": baseCrit,
			"baseEvade": baseEvade,
			"atk": atk,
			"def": def,
			"critRate": critRate,
			"evadeRate": evadeRate,
			"speed": speed,
			"comboRate": comboRate,
			"skill": skill,
			"skillCost": skillCost,
			"weapon": weapon,
			"weaponLevel": weaponLevel,
			"armor": armor,
			"inventory": inventory.duplicate(),
			"cards": cards.duplicate(),
			"quests": quests.duplicate(),
			"pet": pet,
			"hasMercenary": hasMercenary,
			"floor": floor,
			"maxFloor": maxFloor,
			"reincarnation": reincarnation,
			"soulStones": soulStones,
			"absHp": absHp,
			"absAtk": absAtk,
			"absDef": absDef,
			"soulHp": soulHp,
			"soulAtk": soulAtk,
			"soulDef": soulDef,
			"cp": cp,
			"lastRaidTime": lastRaidTime,
			"plants": plants.duplicate(true)
		}

	func from_dict(d: Dictionary):
		if d.has("baseJob"): baseJob = d.baseJob
		if d.has("job"): job = d.job
		if d.has("promoted"): promoted = d.promoted
		if d.has("isAwakened"): isAwakened = d.isAwakened
		if d.has("relicLevel"): relicLevel = int(d.relicLevel)
		if d.has("level"): level = int(d.level)
		if d.has("exp"): exp = int(d.exp)
		if d.has("maxExp"): maxExp = int(d.maxExp)
		if d.has("gold"): gold = int(d.gold)
		if d.has("potions"): potions = int(d.potions)
		if d.has("scrolls"): scrolls = int(d.scrolls)
		if d.has("hp"): hp = int(d.hp)
		if d.has("maxHp"): maxHp = int(d.maxHp)
		if d.has("mp"): mp = int(d.mp)
		if d.has("maxMp"): maxMp = int(d.maxMp)
		if d.has("baseAtk"): baseAtk = int(d.baseAtk)
		if d.has("baseDef"): baseDef = int(d.baseDef)
		if d.has("baseCrit"): baseCrit = float(d.baseCrit)
		if d.has("baseEvade"): baseEvade = float(d.baseEvade)
		if d.has("atk"): atk = int(d.atk)
		if d.has("def"): def = int(d.def)
		if d.has("critRate"): critRate = float(d.critRate)
		if d.has("evadeRate"): evadeRate = float(d.evadeRate)
		if d.has("speed"): speed = int(d.speed)
		if d.has("comboRate"): comboRate = float(d.comboRate)
		if d.has("skill"): skill = d.skill
		if d.has("skillCost"): skillCost = int(d.skillCost)
		if d.has("weapon"): weapon = d.weapon
		if d.has("weaponLevel"): weaponLevel = int(d.weaponLevel)
		if d.has("armor"): armor = d.armor
		if d.has("inventory"): inventory = d.inventory.duplicate()
		if d.has("cards"): cards = d.cards.duplicate()
		if d.has("quests"): quests = d.quests.duplicate()
		if d.has("pet"): pet = d.pet
		if d.has("hasMercenary"): hasMercenary = d.hasMercenary
		if d.has("floor"): floor = int(d.floor)
		if d.has("maxFloor"): maxFloor = int(d.maxFloor)
		if d.has("reincarnation"): reincarnation = int(d.reincarnation)
		if d.has("soulStones"): soulStones = int(d.soulStones)
		if d.has("absHp"): absHp = int(d.absHp)
		if d.has("absAtk"): absAtk = int(d.absAtk)
		if d.has("absDef"): absDef = int(d.absDef)
		if d.has("soulHp"): soulHp = int(d.soulHp)
		if d.has("soulAtk"): soulAtk = int(d.soulAtk)
		if d.has("soulDef"): soulDef = int(d.soulDef)
		if d.has("cp"): cp = int(d.cp)
		if d.has("lastRaidTime"): lastRaidTime = float(d.lastRaidTime)
		if d.has("plants"): plants = d.plants.duplicate(true)

var player = PlayerState.new()
var base_weapon_atk = 0
var base_armor_def = 0
var is_dead = false

func start_new_game(job: String):
	var stats = Database.job_stats[job]
	player = PlayerState.new()
	player.baseJob = job
	player.job = job
	player.baseCrit = stats.crit
	player.baseEvade = stats.evade
	player.skill = stats.skill
	player.skillCost = stats.skillCost
	
	base_weapon_atk = 0
	base_armor_def = 0
	is_dead = false
	calc_stats()
	player.hp = player.maxHp
	player.mp = player.maxMp
	stats_changed.emit()

func resume_game(job_name: String, saved_data: Dictionary):
	player = PlayerState.new()
	player.from_dict(saved_data.player)
	base_weapon_atk = saved_data.get("baseW", 0)
	base_armor_def = saved_data.get("baseA", 0)
	
	is_dead = false
	calc_stats()
	stats_changed.emit()

func calc_stats():
	if player == null or player.baseJob == "":
		return
	var b = Database.job_stats[player.baseJob]
	var p = null
	if player.job != player.baseJob and Database.job_stats.has(player.job):
		p = Database.job_stats[player.job]
		
	var r = player.relicLevel
	var cardCount = player.cards.size()
	var dexMult = 1.0 + (cardCount * 0.01)
	
	var rHp = b.hp + (player.level - 1) * 30 + (p.hpBonus if p else 0) + player.absHp + player.soulHp + (r * 100)
	var rMp = b.mp + (player.level - 1) * 15 + (p.mpBonus if p else 0)
	var rAtk = b.atk + (player.level - 1) * 8 + (p.atkBonus if p else 0) + player.absAtk + player.soulAtk + (r * 20)
	var rDef = b.def + (player.level - 1) * 4 + (p.defBonus if p else 0) + player.absDef + player.soulDef + (r * 10)
	
	var rm = pow(1.2, player.reincarnation)
	var am = 2.5 if player.isAwakened else 1.0
	
	player.maxHp = int(floor(rHp * rm * am * dexMult))
	player.maxMp = int(floor(rMp * rm * am))
	player.baseAtk = int(floor(rAtk * rm * am * dexMult))
	player.baseDef = int(floor(rDef * rm * am * dexMult))
	
	player.baseCrit = b.crit + (p.critBonus if p else 0) + (r * 0.5)
	player.baseEvade = b.evade + (p.evadeBonus if p else 0) + (r * 0.2)
	player.speed = b.speed + (player.level - 1) * 1 + (p.speedBonus if p else 0) + (r * 2)
	player.comboRate = b.combo + (p.comboBonus if p else 0) + (r * 0.5)
	
	# final stats including equipment and pet
	var final_atk = player.baseAtk + base_weapon_atk + (player.weaponLevel * 10) + (player.pet.atk if player.pet else 0)
	var final_def = player.baseDef + base_armor_def + (player.pet.def if player.pet else 0)
	var final_crit = player.baseCrit + (player.pet.crit if player.pet else 0)
	var final_evade = player.baseEvade + (player.pet.evade if player.pet else 0)
	
	player.atk = final_atk
	player.def = final_def
	player.critRate = final_crit
	player.evadeRate = final_evade
	
	# CP Calculation
	player.cp = int(floor(player.maxHp * 0.5 + final_atk * 5 + final_def * 5 + player.speed * 2 + final_crit * 10 + final_evade * 10))

func check_level_up() -> bool:
	var lvup = false
	while player.exp >= player.maxExp:
		player.level += 1
		player.exp -= player.maxExp
		player.maxExp = int(floor(player.maxExp * 1.4))
		lvup = true
	if lvup:
		calc_stats()
		player.hp = player.maxHp
		player.mp = player.maxMp
		stats_changed.emit()
	return lvup
