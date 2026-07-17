extends Node

# Database of jobs, pets, equipment, traits, and monsters

const job_stats = {
	"전사": { "hp": 150, "mp": 40, "atk": 20, "def": 10, "crit": 10, "evade": 5, "speed": 10, "combo": 0, "skill": "대지가르기", "skillCost": 15, "reqJob": null, "reqLvl": 1 },
	"마법사": { "hp": 70,  "mp": 150, "atk": 35, "def": 2, "crit": 20, "evade": 5, "speed": 8, "combo": 0, "skill": "파이어볼", "skillCost": 20, "reqJob": null, "reqLvl": 1 },
	"도적": { "hp": 100, "mp": 60, "atk": 25, "def": 5, "crit": 30, "evade": 25, "speed": 25, "combo": 5, "skill": "연속베기", "skillCost": 15, "reqJob": null, "reqLvl": 1 },
	"궁수": { "hp": 110, "mp": 50, "atk": 28, "def": 7, "crit": 25, "evade": 15, "speed": 18, "combo": 2, "skill": "조준사격", "skillCost": 15, "reqJob": null, "reqLvl": 1 },
	"검성": { "pJob": "전사", "hpBonus": 100, "mpBonus": 50, "atkBonus": 30, "defBonus": 20, "critBonus": 15, "evadeBonus": 5, "speedBonus": 5, "comboBonus": 10, "skill": "극발도", "skillCost": 30, "reqJob": "전사", "reqLvl": 10 },
	"광전사": { "pJob": "전사", "hpBonus": 200, "mpBonus": 20, "atkBonus": 60, "defBonus": -10, "critBonus": 20, "evadeBonus": 0, "speedBonus": -2, "comboBonus": 5, "skill": "광란", "skillCost": 40, "reqJob": "전사", "reqLvl": 10 },
	"대마법사": { "pJob": "마법사", "hpBonus": 50, "mpBonus": 200, "atkBonus": 80, "defBonus": 5, "critBonus": 10, "evadeBonus": 5, "speedBonus": 5, "comboBonus": 0, "skill": "메테오", "skillCost": 60, "reqJob": "마법사", "reqLvl": 10 },
	"흑마법사": { "pJob": "마법사", "hpBonus": 80, "mpBonus": 100, "atkBonus": 50, "defBonus": 10, "critBonus": 15, "evadeBonus": 5, "speedBonus": 3, "comboBonus": 0, "skill": "생명흡수", "skillCost": 40, "reqJob": "마법사", "reqLvl": 10 },
	"암살자": { "pJob": "도적", "hpBonus": 80, "mpBonus": 50, "atkBonus": 40, "defBonus": 5, "critBonus": 30, "evadeBonus": 10, "speedBonus": 15, "comboBonus": 15, "skill": "절명", "skillCost": 35, "reqJob": "도적", "reqLvl": 10 },
	"환영술사": { "pJob": "도적", "hpBonus": 70, "mpBonus": 80, "atkBonus": 20, "defBonus": 10, "critBonus": 10, "evadeBonus": 30, "speedBonus": 10, "comboBonus": 10, "skill": "환영분신", "skillCost": 30, "reqJob": "도적", "reqLvl": 10 },
	"저격수": { "pJob": "궁수", "hpBonus": 90, "mpBonus": 60, "atkBonus": 50, "defBonus": 10, "critBonus": 40, "evadeBonus": 5, "speedBonus": 5, "comboBonus": 5, "skill": "헤드샷", "skillCost": 35, "reqJob": "궁수", "reqLvl": 10 },
	"레인저": { "pJob": "궁수", "hpBonus": 120, "mpBonus": 60, "atkBonus": 35, "defBonus": 20, "critBonus": 15, "evadeBonus": 20, "speedBonus": 12, "comboBonus": 15, "skill": "폭풍우", "skillCost": 30, "reqJob": "궁수", "reqLvl": 10 },
	"소드마스터": { "pJob": "전사", "hpBonus": 400, "mpBonus": 150, "atkBonus": 120, "defBonus": 60, "critBonus": 25, "evadeBonus": 10, "speedBonus": 15, "comboBonus": 20, "skill": "궁극검무", "skillCost": 50, "reqJob": "검성", "reqLvl": 30 },
	"블러드로드": { "pJob": "전사", "hpBonus": 600, "mpBonus": 80, "atkBonus": 180, "defBonus": -20, "critBonus": 30, "evadeBonus": 0, "speedBonus": 5, "comboBonus": 10, "skill": "피의축제", "skillCost": 60, "reqJob": "광전사", "reqLvl": 30 },
	"현자": { "pJob": "마법사", "hpBonus": 150, "mpBonus": 500, "atkBonus": 250, "defBonus": 20, "critBonus": 15, "evadeBonus": 10, "speedBonus": 10, "comboBonus": 0, "skill": "아마겟돈", "skillCost": 100, "reqJob": "대마법사", "reqLvl": 30 },
	"그림자군주": { "pJob": "도적", "hpBonus": 250, "mpBonus": 150, "atkBonus": 150, "defBonus": 20, "critBonus": 45, "evadeBonus": 20, "speedBonus": 30, "comboBonus": 25, "skill": "그림자참수", "skillCost": 50, "reqJob": "암살자", "reqLvl": 30 },
	"윈드워커": { "pJob": "궁수", "hpBonus": 300, "mpBonus": 150, "atkBonus": 130, "defBonus": 40, "critBonus": 30, "evadeBonus": 30, "speedBonus": 25, "comboBonus": 20, "skill": "폭풍우", "skillCost": 45, "reqJob": "레인저", "reqLvl": 30 }
}

const pet_db = [
	{ "name": "슬라임", "atk": 0, "def": 0, "crit": 0, "evade": 0, "hpRegen": 10 },
	{ "name": "전투늑대", "atk": 20, "def": 5, "crit": 5, "evade": 0, "hpRegen": 0 },
	{ "name": "황금박쥐", "atk": 0, "def": 0, "crit": 0, "evade": 15, "hpRegen": 0 },
	{ "name": "아기드래곤", "atk": 50, "def": 20, "crit": 10, "evade": 5, "hpRegen": 20 }
]

const equipment_db = [
	{ "type": "무기", "name": "강철검", "price": 1500, "stat": 35 },
	{ "type": "방어구", "name": "사슬갑옷", "price": 1500, "stat": 25 },
	{ "type": "무기", "name": "초합금검", "price": 10000, "stat": 150 },
	{ "type": "방어구", "name": "드래곤갑옷", "price": 10000, "stat": 120 },
	{ "type": "무기", "name": "미스릴 소드", "price": 35000, "stat": 400 },
	{ "type": "방어구", "name": "아다만티움 실드", "price": 35000, "stat": 300 },
	{ "type": "무기", "name": "엑스칼리버", "price": 150000, "stat": 1000 },
	{ "type": "방어구", "name": "절대신의 흉갑", "price": 150000, "stat": 800 }
]

const monster_traits = {
	"무특성": { "text": "" },
	"맹독": { "text": "[맹독]" },
	"흡혈": { "text": "[흡혈]" },
	"단단함": { "text": "[단단함]" },
	"암살": { "text": "[암살]" },
	"재생": { "text": "[재생]" },
	"파멸": { "text": "[파멸]" },
	"반사": { "text": "[반사]" },
	"기민함": { "text": "[기민함]" }
}

const base_monsters = [
	{ "name": "슬라임", "hp": 60, "atk": 18, "def": 2, "exp": 30, "gold": 20, "speed": 5, "trait": "무특성" },
	{ "name": "독 슬라임", "hp": 80, "atk": 20, "def": 5, "exp": 40, "gold": 30, "speed": 6, "trait": "맹독" },
	{ "name": "고블린", "hp": 100, "atk": 25, "def": 5, "exp": 40, "gold": 30, "speed": 8, "trait": "무특성" },
	{ "name": "고블린 궁수", "hp": 80, "atk": 35, "def": 2, "exp": 45, "gold": 35, "speed": 15, "trait": "기민함" },
	{ "name": "해골 병사", "hp": 120, "atk": 30, "def": 10, "exp": 50, "gold": 40, "speed": 7, "trait": "무특성" },
	{ "name": "뱀파이어 박쥐", "hp": 150, "atk": 45, "def": 5, "exp": 65, "gold": 45, "speed": 25, "trait": "흡혈" },
	{ "name": "오크 전사", "hp": 180, "atk": 40, "def": 15, "exp": 70, "gold": 50, "speed": 12, "trait": "무특성" },
	{ "name": "미믹", "hp": 200, "atk": 50, "def": 30, "exp": 100, "gold": 200, "speed": 5, "trait": "단단함" },
	{ "name": "단단한 골렘", "hp": 250, "atk": 35, "def": 35, "exp": 90, "gold": 60, "speed": 2, "trait": "단단함" },
	{ "name": "그림자 암살자", "hp": 180, "atk": 60, "def": 10, "exp": 100, "gold": 70, "speed": 35, "trait": "암살" },
	{ "name": "사막 여우", "hp": 160, "atk": 45, "def": 8, "exp": 80, "gold": 60, "speed": 40, "trait": "기민함" },
	{ "name": "리자드맨", "hp": 250, "atk": 55, "def": 25, "exp": 100, "gold": 70, "speed": 15, "trait": "재생" },
	{ "name": "아이스 골렘", "hp": 300, "atk": 60, "def": 40, "exp": 120, "gold": 90, "speed": 5, "trait": "단단함" },
	{ "name": "파이어 엘리멘탈", "hp": 220, "atk": 80, "def": 15, "exp": 130, "gold": 100, "speed": 20, "trait": "반사" },
	{ "name": "데스나이트", "hp": 350, "atk": 70, "def": 40, "exp": 150, "gold": 120, "speed": 20, "trait": "무특성" },
	{ "name": "서큐버스", "hp": 280, "atk": 75, "def": 15, "exp": 160, "gold": 130, "speed": 30, "trait": "흡혈" },
	{ "name": "켈베로스", "hp": 400, "atk": 85, "def": 20, "exp": 180, "gold": 140, "speed": 28, "trait": "재생" },
	{ "name": "포악한 오거", "hp": 450, "atk": 90, "def": 30, "exp": 200, "gold": 160, "speed": 10, "trait": "단단함" },
	{ "name": "스펙터", "hp": 300, "atk": 100, "def": 5, "exp": 220, "gold": 180, "speed": 45, "trait": "기민함" },
	{ "name": "미노타우로스", "hp": 600, "atk": 120, "def": 50, "exp": 300, "gold": 250, "speed": 15, "trait": "파멸" }
]

const boss_monsters = [
	{ "name": "거대 슬라임 킹", "hp": 800, "atk": 80, "def": 20, "exp": 400, "gold": 400, "speed": 10, "trait": "재생" },
	{ "name": "피의 군주", "hp": 900, "atk": 140, "def": 50, "exp": 500, "gold": 600, "speed": 40, "trait": "흡혈" },
	{ "name": "심연의 지배자", "hp": 1000, "atk": 120, "def": 60, "exp": 500, "gold": 600, "speed": 30, "trait": "맹독" },
	{ "name": "고블린 킹", "hp": 1200, "atk": 110, "def": 40, "exp": 550, "gold": 700, "speed": 25, "trait": "기민함" },
	{ "name": "파멸의 거상", "hp": 1500, "atk": 100, "def": 100, "exp": 600, "gold": 600, "speed": 15, "trait": "파멸" },
	{ "name": "타락한 영웅", "hp": 1100, "atk": 150, "def": 70, "exp": 650, "gold": 750, "speed": 50, "trait": "암살" },
	{ "name": "저주받은 마검사", "hp": 1600, "atk": 180, "def": 80, "exp": 800, "gold": 900, "speed": 45, "trait": "반사" },
	{ "name": "무자비한 듀라한", "hp": 2000, "atk": 200, "def": 150, "exp": 900, "gold": 1000, "speed": 20, "trait": "단단함" },
	{ "name": "헬 하운드 알파", "hp": 2500, "atk": 250, "def": 100, "exp": 1200, "gold": 1300, "speed": 60, "trait": "흡혈" },
	{ "name": "고대 리치", "hp": 3000, "atk": 350, "def": 120, "exp": 2000, "gold": 2000, "speed": 35, "trait": "파멸" }
]
