extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_session_auth_request()


func _session_auth_request() -> void:
	var signal_connections = [_request_completed_debug, _session_verify_request()]
	_programmatic_request("http://localhost:3000/api/auth/guest", HTTPClient.METHOD_GET, signal_connections)


func _session_verify_request() -> Callable:
	var signal_connections = [_request_completed_debug]
	return _chain_request("http://localhost:3000/api/auth/test", HTTPClient.METHOD_GET, signal_connections)


func _programmatic_request(request_url: String, client_method: HTTPClient.Method, signal_connections: Array) -> void:
	# Create request node
	var my_request := CookieHTTPRequest.new()
	add_child(my_request)
	# Create cleanup lambda
	var my_request_cleanup := func (_result, _response_code, _headers, _body) -> void:
		my_request.queue_free()
	# Add signal connections
	for connection in signal_connections:
		my_request.request_completed.connect(connection)
	# Last connection is cleanup
	my_request.request_completed.connect(my_request_cleanup)
	# Run request
	my_request.cookie_request(request_url, [], client_method)


func _request_completed_debug(result, response_code, headers, body) -> void:
	print("PH Result")
	print(result)
	print("PH Response Code")
	print(response_code)
	print("PH Headers")
	print(headers)
	print("PH Body")
	print(body.get_string_from_utf8())


# Util


# Creates a signal connection function that will chain a request using the provided request_url, client_method, and signal_connections
func _chain_request(request_url: String, client_method: HTTPClient.Method, signal_connections: Array) -> Callable:
	var programmatic_request_connector := func (_result, _response_code, _headers, _body) -> void:
		_programmatic_request(request_url, client_method, signal_connections)
	return programmatic_request_connector
