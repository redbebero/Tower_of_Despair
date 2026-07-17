# 절망의 탑: 온라인 Godot 포팅 구현 계획서 (Porting HTML5 RPG to Godot Engine 4.6)

이 계획서는 `index.html` 기반의 웹 RPG 게임 '절망의 탑: 온라인'의 핵심 로직과 UI를 Godot Engine 4.6 환경으로 포팅하고, 확장 가능한 아키텍처로 설계하여 안정적으로 구현하기 위한 계획입니다.

## assumptions (가정 사항)
1. **Godot 버전**: 현재 프로젝트의 `project.godot`에 명시된 Godot 4.6 (GL Compatibility 렌더러)을 타겟으로 합니다.
2. **언어**: UI 연동 및 게임 로직은 GDScript를 사용하여 구현합니다.
3. **Firebase 연동**: 
   - Godot에서 기존 JS Firebase SDK를 직접 쓰는 것은 불가능하므로, Godot용 REST API 클라이언트를 직접 작성하거나, 우선 **로컬 저장(Local Save System)**을 구축하고 Firebase 부분은 Mock/REST 방식으로 연동할 수 있는 추상화 레이어를 둡니다.
   - 랭킹(Leaderboard) 시스템 또한 HTTP Request를 통해 Firebase REST API와 통신하도록 설계하여 확장성을 확보합니다.

---

## User Review Required (사용자 검토 필요)

> [!IMPORTANT]
> **Firebase 연동 방식 결정**
> Godot 내에서 Firebase Firestore/Auth는 REST API를 이용해 구현하게 됩니다. 
> 1. 웹 버전과 동일한 Firebase 프로젝트(`myrpg-9b043`)의 REST API를 연동하여 로그인 및 데이터 저장/불러오기, 실시간 랭킹을 구현할 것인지
> 2. 우선 안정적인 로컬 오프라인 데이터 관리 및 로컬 랭킹 시뮬레이션을 구현한 뒤, Firebase REST API 연동을 추후 추가 단계로 가져갈 것인지 결정이 필요합니다.
> *(추천: 1단계로 로컬 저장 및 아키텍처 구축을 완료하여 검증하고, 2단계로 Firebase REST API 연동을 입히는 방식이 안정적입니다.)*

---

## Proposed Changes (제안된 변경 사항)

### 1. 게임 구조 및 데이터베이스 설계 (Data & Database Layer)

기존 JS의 하드코딩된 게임 데이터를 Godot Autoload(싱글톤)로 분리하여 데이터 수정과 확장이 용이하도록 합니다.

#### [NEW] [Database.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/Database.gd)
- 직업 정보 (`job_stats`), 펫 데이터베이스 (`pet_db`), 몬스터 데이터 (`base_monsters`, `boss_monsters`), 몬스터 특성 (`monster_traits`) 등 모든 상수 테이블을 관리합니다.
- 새로운 캐릭터나 몬스터를 추가할 때 이 파일만 수정하면 되므로 확장성이 뛰어납니다.

#### [NEW] [PlayerData.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/PlayerData.gd)
- 플레이어의 현재 상태(직업, 레벨, 스탯, 골드, 영혼석, 강화석, 인벤토리, 장착 아이템, 도감 수집 상태, 온실 화분 상태 등)를 관리하는 싱글톤입니다.
- 스탯 계산 함수 `calc_stats()`를 포함하여 장비, 펫, 유물, 도감 보너스 등을 실시간 적용합니다.
- 데이터 변경 시 이벤트를 발생시켜 UI가 즉각 갱신되도록 신호(Signal) 시스템을 활용합니다.

#### [NEW] [SaveManager.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/SaveManager.gd)
- 로컬 JSON 기반 저장/불러오기 시스템입니다.
- Firebase REST API 연동 시, 로그인 성공 후 클라우드 세이브 데이터를 받아와 로컬 데이터를 덮어쓰고 자동 저장 시 REST 요청을 보내도록 확장 가능한 인터페이스를 제공합니다.

---

### 2. 게임 맵 및 이동 (Map & Movement)

#### [NEW] [GameMap.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/GameMap.gd)
- 330x330 크기의 Control 노드 내부에서 플레이어 및 NPC, 몬스터 엔티티들을 30px 그리드 단위로 드로잉 및 이동 처리합니다.
- 마을(Town) 맵 로드 시 촌장, 상점, 대장간, 낚시터 등 건물 아이콘 배치.
- 탑(Tower) 진입 시 층별 몬스터와 계단(Stairs) 스폰 로직 처리.
- 플레이어가 움직일 때마다 주변 엔티티(1칸 거리 내)를 탐색하여 해당 메뉴(Inn, Blacksmith 등)가 열리도록 합니다.

---

### 3. UI 및 상태 제어 (Main Scene & UI Panel)

#### [NEW] [main.tscn](file:///home/redbebero/work/projects/game/Godot/scenes/main.tscn)
- 전체 UI 레이아웃을 잡는 메인 씬입니다.
- HTML 구조를 모방한 3단 그리드 구조로 배치합니다.
  - **LeftPanel**: 플레이어 스탯 요약 (HP/MP/EXP Progress Bar), 장비 상태, 가방(인벤토리 GridContainer)
  - **CenterPanel**: 맵 표시 영역 (GameMap), 조작 D-Pad, 로그 출력 창(RichTextLabel)
  - **RightPanel**: 상황별 메뉴 세션 (TabContainer 또는 여러 PanelContainer가 상태에 따라 토글됨)
	- 탐험 모드/메인 액션, 명예의 전당(랭킹), 피의 결투장, 온실, 도감, 탑 입구, 전투 화면, 상점, 여관, 대장간, 촌장, 차원의 틈, 지하 유적 등
  - **QuestPanel**: 일일 의뢰 및 업적 상태

#### [NEW] [Main.gd](file:///home/redbebero/work/projects/game/Godot/scripts/Main.gd)
- 메인 씬의 컨트롤러 스크립트입니다.
- 로그인/회원가입 화면 처리, 캐릭터 선택 화면 처리.
- 1초 단위 글로벌 타이머를 돌려 온실 식물 성장, 레이드 쿨타임 등을 갱신합니다.
- `PlayerData`의 신호를 받아 전체 UI(골드, 영혼석, 스탯 등)를 갱신합니다.
- 로그 창에 시스템 메시지를 포맷팅하여 추가합니다.

#### [NEW] [CombatManager.gd](file:///home/redbebero/work/projects/game/Godot/scripts/CombatManager.gd)
- 일반 전투, 보스 전투, 투기장(무한 방어전), PvP 결투장, 차원의 마룡 레이드 등 모든 전투 로직을 담당합니다.
- 턴제 처리 (`start_turn`, `do_player_action`, `do_enemy_action`, `end_phase`).
- 몬스터 처치 시 전리품, 씨앗, 강화석 등 아이템 획득 및 경험치 보상 획득 로직.

---

## Verification Plan (검증 계획)

### Automated Tests (자동화 테스트)
- Godot 4.6 커맨드라인 실행을 통해 스크립트 문법 오류 유무 검증:
  `godot --headless --check-only`

### Manual Verification (수동 검증)
1. **캐릭터 생성 및 데이터 초기화**: 4개 직업(전사, 마법사, 도적, 궁수) 생성 및 정상 로드 여부 검증
2. **마을 이동 및 상호작용**: D-Pad 이동 시 건물 옆으로 가면 해당 상호작용 UI 패널이 열리는지 검증
3. **전투 및 레벨업**: 탑에 진입하여 몬스터와 전투, 승리 시 경험치 및 재화 획득, 레벨업 시 스탯 증가 검증
4. **대장간 강화 및 강화석**: 강화석과 골드를 소모하여 강화 성공/실패(+10강 이상 시 파괴 및 파방 주문서 작동) 검증
5. **온실 및 유적 파기**: 1분 대기 후 온실 수확물(영구 스탯 보너스) 획득 및 지하 유적 5회 발굴 보상 획득 검증
6. **로컬 세이브**: 게임 중단/재기동 시 이전 저장된 플레이어 정보가 정상 복원되는지 확인
