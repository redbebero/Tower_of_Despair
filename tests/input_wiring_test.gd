extends SceneTree

const REQUIRED_CONNECTIONS = {
	"GameContainer/MainLayout/CenterPanel/Dpad/BtnUp": "move_player",
	"GameContainer/MainLayout/CenterPanel/Dpad/BtnLeft": "move_player",
	"GameContainer/MainLayout/CenterPanel/Dpad/BtnDown": "move_player",
	"GameContainer/MainLayout/CenterPanel/Dpad/BtnRight": "move_player",
	"GameContainer/MainLayout/RightPanel/ActionTabs/PvPActions/BtnFindPvp": "start_pvp",
	"GameContainer/MainLayout/RightPanel/ActionTabs/TowerEntranceActions/FloorSelect/BtnPrevFloor": "change_floor",
	"GameContainer/MainLayout/RightPanel/ActionTabs/TowerEntranceActions/FloorSelect/BtnNextFloor": "change_floor",
	"GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnAttack": "start_combat_turn",
	"GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnSkill": "start_combat_turn",
	"GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnUsePotion": "start_combat_turn",
	"GameContainer/MainLayout/RightPanel/ActionTabs/CombatActions/ActionGrid/BtnRun": "start_combat_turn",
	"GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulAtk": "upgrade_soul",
	"GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulDef": "upgrade_soul",
	"GameContainer/MainLayout/RightPanel/ActionTabs/NpcActions/ReincControls/SoulUpgrades/BtnUpgradeSoulHp": "upgrade_soul",
	"GameContainer/MainLayout/RightPanel/ActionTabs/RiftActions/BtnRaidEnter": "enter_raid",
	"GameContainer/MainLayout/RightPanel/ActionTabs/ArenaActions/BtnEnterArena": "start_arena",
	"GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExStone": "buy_from_blackmarket",
	"GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExScroll": "buy_from_blackmarket",
	"GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExPotion": "buy_from_blackmarket",
	"GameContainer/MainLayout/RightPanel/ActionTabs/BlackmarketActions/Options/BtnExCard": "buy_from_blackmarket"
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root = load("res://scenes/main.tscn").instantiate()
	root.name = "InputWiringTestMain"
	get_root().add_child(root)
	await process_frame

	var failures: Array[String] = []
	for path in REQUIRED_CONNECTIONS:
		var button = root.get_node_or_null(path)
		if button == null:
			failures.append("missing node: %s" % path)
			continue

		var expected_method: String = REQUIRED_CONNECTIONS[path]
		var connected = false
		for connection in button.pressed.get_connections():
			var callable: Callable = connection["callable"]
			if callable.get_method() == expected_method:
				connected = true
				break
		if not connected:
			failures.append("missing %s connection: %s" % [expected_method, path])

	if failures.is_empty():
		print("INPUT_WIRING_TEST_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("INPUT_WIRING_TEST_FAIL (%d)" % failures.size())
		quit(1)
