extends Node

const BASE_URL = "http://127.0.0.1:8000"

signal patients_loaded(data)
signal failed(msg)

var _http: HTTPRequest
var _action := ""


func _ready():
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_done)


func _cancel_if_busy() -> void:
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()


func get_all(page := 1) -> void:
	_action = "list"
	print(">>> get_all page:", page)
	_cancel_if_busy()
	var err = _http.request(BASE_URL + "/patients?page=" + str(page))
	if err != OK:
		emit_signal("failed", "Request error: " + str(err))


func search_patients(query: String, page: int = 1) -> void:
	_action = "search"
	print(">>> search_patients q:", query, " page:", page)
	_cancel_if_busy()
	var url = BASE_URL + "/patients/search/query?q=" + query.uri_encode() + "&page=" + str(page)
	var err = _http.request(url)
	if err != OK:
		emit_signal("failed", "Search request error: " + str(err))


func _done(_result, code, _headers, body):
	print(">>> _done action:", _action, " code:", code)
	if code >= 400:
		emit_signal("failed", "Error %d" % code)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null:
		emit_signal("failed", "Failed to parse response")
		return
	emit_signal("patients_loaded", parsed)
