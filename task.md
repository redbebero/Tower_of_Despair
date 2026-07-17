# 절망의 탑: 온라인 Godot 포팅 작업 목록 (Task Checklist)

- [x] Autoload 스크립트 작성
  - [x] `scripts/Database.gd` (상수 데이터베이스)
  - [x] `scripts/PlayerData.gd` (플레이어 상태 및 스탯 계산)
  - [x] `scripts/SaveManager.gd` (로컬 저장/불러오기)
- [x] `project.godot` 설정 추가 (Autoload 등록 및 메인 씬 설정)
- [x] 핵심 게임 로직 스크립트 작성
  - [x] `scripts/CombatManager.gd` (전투, 레이드, 투기장, PvP 제어)
  - [x] `scripts/GameMap.gd` (그리드 맵 엔티티 렌더링 및 플레이어 이동)
- [x] 메인 컨트롤러 및 UI 구성
  - [x] `scripts/Main.gd` (화면 전환, 타이머, UI 갱신, 로그 처리)
  - [x] `scenes/main.tscn` (Control 노드 기반 전체 UI 레이아웃 정의)
- [x] 문법 및 오류 검증 (Headless GDScript Verification)
  - [x] `godot --headless --check-only` 실행하여 에러 없음 검증
