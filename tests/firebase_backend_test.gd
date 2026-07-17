extends SceneTree

func _init() -> void:
	var source = FileAccess.get_file_as_string("res://scripts/SaveManager.gd")
	var failures: Array[String] = []

	if not source.contains("castle-4de5d"):
		failures.append("Firebase project configuration missing")
	if not source.contains("castle-4de5d-default-rtdb.firebaseio.com"):
		failures.append("Realtime Database URL missing")
	if source.contains("user://save_data.json") or source.contains("user://leaderboard.json"):
		failures.append("local JSON path still present")
	if source.contains("FileAccess.open") or source.contains("FileAccess.store_string"):
		failures.append("local JSON persistence still present")

	if failures.is_empty():
		print("FIREBASE_BACKEND_TEST_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FIREBASE_BACKEND_TEST_FAIL (%d)" % failures.size())
		quit(1)
