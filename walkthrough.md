# 절망의 탑: 온라인 Godot 포팅 완료 보고서 (Walkthrough)

`index.html` 기반의 웹 RPG 게임 '절망의 탑: 온라인'의 모든 로직과 UI를 Godot Engine 4.6 (GDScript) 환경으로 성공적으로 포팅 및 완료했습니다.

## 구현 완료 항목 (Implemented Features)

### 1. Autoload 싱글톤 레이어
- **[Database.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/Database.gd)**: 직업 스탯, 펫 DB, 장비 DB, 몬스터 특성, 일반/보스 몬스터 등 하드코딩 데이터를 분리 관리하여 향후 확장성이 대폭 향상되었습니다.
- **[PlayerData.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/PlayerData.gd)**: 플레이어의 레벨, 경험치, 스탯 계산(유물/카드/장비/환생 보너스 적용)을 정교하게 실시간 처리합니다.
- **[SaveManager.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/SaveManager.gd)**: Firebase Email/Password Auth와 Realtime Database를 통해 인증, 캐릭터 저장, 명예의 전당 데이터를 원격으로 관리합니다.
- **[CombatManager.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/CombatManager.gd)**: 턴제 전투 로직(일반, 보스, 무한 투기장, 비동기 PvP 결투장, 10턴 마룡 레이드)을 완전히 포팅했습니다.

### 2. 맵 & 이동 엔진
- **[GameMap.gd](file:///home/redbebero/work/projects/game/Godot/절망의-/scripts/GameMap.gd)**: 11x11 타일 형식의 마을 광장 및 층별 던전 구조를 구현하고, D-pad 또는 키 입력을 통해 이동 및 주변 인터랙션(여관, 대장간, 촌장 승급 등)이 자동 트리거되도록 구축했습니다. (셀 크기 40px로 수정 및 정렬 최적화)

### 3. UI 및 컨트롤러
- **[main.tscn](file:///home/redbebero/work/projects/game/Godot/scenes/main.tscn)**: HTML의 3단 레이아웃을 이식했습니다. (HpBar, MpBar, ExpBar, MonsterHpBar의 `show_percentage = false` 적용으로 텍스트 겹침 문제 해결)
- **[Main.gd](file:///home/redbebero/work/projects/game/Godot/scripts/Main.gd)**: 메인 UI 컨트롤러로서 미니게임 제어, 시그널 기반 HUD 갱신을 총괄 제어합니다. (바인드된 콜러블 함수 매개변수 타입 힌트 해제로 런타임 연결 오류 해결)

---

## 검증 결과 (Verification Results)

- **GDScript 구문 검증**: `godot --headless --check-only` 빌드 툴 패스 완료. 
- **컴파일 경고 및 바인딩**: 바인드 함수 연결 해제 및 겹침 문제 해결 완료.
