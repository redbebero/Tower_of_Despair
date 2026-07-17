extends Node

# Firebase Auth + Realtime Database REST backend.

signal auth_succeeded
signal auth_failed(message)
signal saves_loaded
signal leaderboard_loaded

const FIREBASE_API_KEY = "AIzaSyDIxKI6j-xxkuFkyhtF3jv4Zitzc-IXUvg"
const FIREBASE_PROJECT_ID = "castle-4de5d"
const FIREBASE_APP_ID = "1:229476309257:web:897fde21b252341b425bd8"
const DATABASE_URL = "https://castle-4de5d-default-rtdb.firebaseio.com"
const AUTH_URL = "https://identitytoolkit.googleapis.com/v1/"

var cloud_saves: Dictionary = {}
var leaderboard_cache: Array = []
var current_uid = ""
var current_email = ""
var id_token = ""
var refresh_token = ""

func _ready():
	pass

func clear_session():
	cloud_saves = {}
	leaderboard_cache = []
	current_uid = ""
	current_email = ""
	id_token = ""
	refresh_token = ""

func sign_in(email: String, password: String):
	_auth_request("accounts:signInWithPassword", email, password)

func sign_up(email: String, password: String):
	_auth_request("accounts:signUp", email, password)

func _auth_request(endpoint: String, email: String, password: String):
	var payload = JSON.stringify({
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	_request(
		AUTH_URL + endpoint + "?key=" + FIREBASE_API_KEY,
		HTTPClient.METHOD_POST,
		payload,
		func(response_code: int, data: Dictionary):
			if response_code != 200:
				auth_failed.emit(_firebase_error(data))
				return
			current_uid = str(data.get("localId", ""))
			current_email = str(data.get("email", email))
			id_token = str(data.get("idToken", ""))
			refresh_token = str(data.get("refreshToken", ""))
			_load_all_saves_remote()
	)

func load_all_saves():
	if id_token.is_empty() or current_uid.is_empty():
		cloud_saves = {}
		saves_loaded.emit()
		return
	_load_all_saves_remote()

func _load_all_saves_remote():
	var path = "/users/%s/characters" % current_uid.uri_encode()
	_database_request(HTTPClient.METHOD_GET, path, null, func(response_code: int, data):
		if response_code != 200:
			cloud_saves = {}
			auth_failed.emit("Firebase 저장소에 접근할 수 없습니다. Realtime Database Rules를 확인하세요.")
			return
		if typeof(data) == TYPE_DICTIONARY:
			cloud_saves = data
		else:
			cloud_saves = {}
		saves_loaded.emit()
		auth_succeeded.emit()
	)

func save_current_player():
	if PlayerData.player == null or PlayerData.player.baseJob == "" or PlayerData.is_dead:
		return
	if id_token.is_empty() or current_uid.is_empty():
		return

	var job = PlayerData.player.baseJob
	var save_data = {
		"player": PlayerData.player.to_dict(),
		"baseW": PlayerData.base_weapon_atk,
		"baseA": PlayerData.base_armor_def
	}
	cloud_saves[job] = save_data
	var path = "/users/%s/characters/%s" % [current_uid.uri_encode(), job.uri_encode()]
	_database_request(HTTPClient.METHOD_PUT, path, save_data)
	update_leaderboard(job)

func delete_job(job: String):
	cloud_saves.erase(job)
	if id_token.is_empty() or current_uid.is_empty():
		return
	var character_path = "/users/%s/characters/%s" % [current_uid.uri_encode(), job.uri_encode()]
	_database_request(HTTPClient.METHOD_DELETE, character_path, null)
	var entry_id = "%s_%s" % [current_uid, job]
	_database_request(HTTPClient.METHOD_DELETE, "/leaderboard/%s" % entry_id.uri_encode(), null)

func update_leaderboard(job: String):
	if id_token.is_empty() or current_uid.is_empty():
		return
	var player = PlayerData.player
	var entry_id = "%s_%s" % [current_uid, job]
	var entry = {
		"id": entry_id,
		"uid": current_uid,
		"nickname": nickname(),
		"job": player.job,
		"level": player.level,
		"maxFloor": player.maxFloor,
		"cp": player.cp,
		"hp": player.maxHp,
		"atk": player.atk,
		"def": player.def,
		"speed": player.speed
	}
	var replaced = false
	for i in range(leaderboard_cache.size()):
		if leaderboard_cache[i].get("id", "") == entry_id:
			leaderboard_cache[i] = entry
			replaced = true
			break
	if not replaced:
		leaderboard_cache.append(entry)
	var path = "/leaderboard/%s" % entry_id.uri_encode()
	_database_request(HTTPClient.METHOD_PUT, path, entry)

func fetch_leaderboard():
	if id_token.is_empty():
		leaderboard_cache = []
		leaderboard_loaded.emit()
		return
	_database_request(HTTPClient.METHOD_GET, "/leaderboard", null, func(response_code: int, data):
		leaderboard_cache = []
		if response_code == 200 and typeof(data) == TYPE_DICTIONARY:
			for entry in data.values():
				if typeof(entry) == TYPE_DICTIONARY:
					leaderboard_cache.append(entry)
		leaderboard_cache.sort_custom(func(a, b): return int(a.get("cp", 0)) > int(b.get("cp", 0)))
		leaderboard_loaded.emit()
	)

func get_leaderboard() -> Array:
	return leaderboard_cache.duplicate(true)

func nickname() -> String:
	return current_email.get_slice("@", 0) if not current_email.is_empty() else "모험가"

func _database_request(method: HTTPClient.Method, path: String, payload, callback: Callable = Callable()):
	var query = "?auth=" + id_token.uri_encode()
	_request(DATABASE_URL + path + ".json" + query, method, "" if payload == null else JSON.stringify(payload), callback)

func _request(url: String, method: HTTPClient.Method, payload: String, callback: Callable):
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(data) != TYPE_DICTIONARY:
			data = {} if data == null else {"value": data}
		if callback.is_valid():
			callback.call(response_code, data)
		request.queue_free()
	)
	var headers = PackedStringArray(["Content-Type: application/json"])
	var error = request.request(url, headers, method, payload)
	if error != OK:
		if callback.is_valid():
			callback.call(0, {"error": str(error)})
		request.queue_free()

func _firebase_error(data: Dictionary) -> String:
	var message = str(data.get("error", {}).get("message", "Firebase 요청 실패"))
	match message:
		"EMAIL_EXISTS": return "이미 가입된 이메일입니다."
		"EMAIL_NOT_FOUND", "INVALID_PASSWORD": return "이메일 또는 비밀번호가 올바르지 않습니다."
		"INVALID_EMAIL": return "이메일 형식이 올바르지 않습니다."
		"WEAK_PASSWORD": return "비밀번호가 너무 약합니다."
		_: return "Firebase 오류: %s" % message
