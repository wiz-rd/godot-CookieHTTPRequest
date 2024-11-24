@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("CookieHTTPRequest", "HTTPRequest", preload("main/cookie_http_request.gd"), preload("assets/CookieHTTPRequest-EditorIcon.svg"))


func _exit_tree() -> void:
	remove_custom_type("CookieHTTPRequest")
