class_name HTTPCookieStore


# renamed this to match the other variable naming convention
# _storedCookies -> _stored_cookies
# @wiz-rd
static var _stored_cookies: Array = []


# Function to create a cookie head
# No return type since GDscript doesn't have nullable types yet: https://github.com/godotengine/godot-proposals/issues/162
static func get_cookie_header_for_request(request_url: String):
	var request_cookies = _retrieve_cookies_for_header(request_url)
	# User Agent SHOULD sort the cookie list. Since this is just a stop-gap until cookie handling gets added into Godot, skipping.
	if (request_cookies.size() != 0):
		return _create_cookie_header_string(request_cookies)
	return null


# Function to take in an array of cookies and store them
static func store_cookies(cookies: Array, request_url: String) -> void:
	# renamed some variables to make things clearer:
	# cookie -> new_cookie, update_cookie -> old_cookie
	# update_cookie_index -> old_cookie_index
	# as the cookies themselves weren't even being updated, just replaced
	# @wiz-rd
	for new_cookie in cookies:
		# Check for cookie-fix attack
		if (!new_cookie.secure_only_flag and !HTTPUtils.is_request_secure(request_url)):
			if (_check_for_cookie_fix_attack(new_cookie)):
				CookieDebug.push_debug(CookieDebug.LEVEL.ERR, "Storage", "Possible new_cookie-fix attack, discarding new_cookie")
				continue

		# for some reason the original author, Omn1core,
		# never removed the "set-cookie" portion of cookies...
		new_cookie.name = new_cookie.name.trim_prefix("set-cookie: ")
		# this causes a weird issue where the entire cookie name is,
		# for example, "set-cookie: session" instead of just "session"
		# which causes servers to endlessly create sessions
		# and sessions to simply not function whatsoever
		# server I'm experiencing this with: LiteStar/Uvicorn (Python)
		# @wiz-rd

		# Look for update cookie
		var old_cookie_index = _get_matching_cookie_index(new_cookie)

		if (old_cookie_index != null):
			# WARNING using an index on a list that likely isn't sorted
			# sounds like it could get very problematic
			# @wiz-rd
			var old_cookie = _stored_cookies[old_cookie_index]
			new_cookie.creation_time = old_cookie.creation_time

			# there is a logic error here
			# the array being modified was
			# "cookies" (method arg) and not
			# "_cookies" (class attribute,
			# or as it is in the Godot Asset Store plugin)
			# so it had no effect on the class._cookies variable.
			# @wiz-rd
			_stored_cookies.remove_at(old_cookie_index)

		_stored_cookies.push_back(new_cookie)


# Checks to see if a cookie is trying to update a secure cookie
static func _check_for_cookie_fix_attack(check_cookie: Dictionary) -> bool:
	for stored_cookie in _stored_cookies:
		if (check_cookie.name == stored_cookie.name and stored_cookie.secure_only_flag):
			if (HTTPUtils.domain_match(check_cookie.domain, stored_cookie.domain) or HTTPUtils.domain_match(stored_cookie.domain, check_cookie.domain)):
				if (HTTPUtils.path_match(check_cookie.path, stored_cookie.path)):
					return true
	return false


# Gets a matching cookie from the store, otherwise returns null
# No return type since GDscript doesn't have nullable types yet: https://github.com/godotengine/godot-proposals/issues/162
static func _get_matching_cookie_index(cookie: Dictionary):
	# the second argument in the range() function is NOT INCLUSIVE
	# so subtracting 1, like the original code did, ignores the
	# last item in the array. Removing the "- 1" fixes another
	# cookie duplication issue.
	# @wiz-rd
	for i in range(0, _stored_cookies.size(), 1):
		var stored_cookie = _stored_cookies[i]
		if(cookie.name == stored_cookie.name and cookie.domain == stored_cookie.domain and cookie.http_only_flag == stored_cookie.http_only_flag and cookie.path == stored_cookie.path):
			return i
	return null


# Gets all relevant cookies for a request URL
# As a side effect, removes any cookies that have expired
static func _retrieve_cookies_for_header(request_url: String) -> Array:
	var cookies := []
	# HTTP cares not for floating point precision
	var process_time := int(roundf(Time.get_unix_time_from_system()))
	var request_domain = HTTPUtils.get_url_domain(request_url)
	var request_path = HTTPUtils.get_url_path(request_url)
	for i in range(_stored_cookies.size() - 1, -1, -1):
		var cookie = _stored_cookies[i]
		if (cookie.get("persistant_flag") and cookie.get("expiry_time", HTTPUtils.MAX_SECONDS) < process_time):
			_stored_cookies.remove_at(i)
			continue
		# Retrieval check
		# Skipping http_only_flag check because there's no way for me to ensure this comes from a CookieHTTPRequest, end user can change code. 
		# Skipping same_site_flag check because this isn't a browser so it doesn't have a site to same_site check against.
		if (
			((cookie.host_only_flag and request_domain == cookie.domain)
			or (!cookie.host_only_flag and HTTPUtils.domain_match(request_domain, cookie.domain)))
			and HTTPUtils.path_match(request_path, cookie.path)
			and (!cookie.secure_only_flag or HTTPUtils.is_request_secure(request_url))
		):
			cookie.last_access_time = process_time
			cookies.push_front(cookie)
	return cookies


# Creates the `Cookie` http header using the passed in cookie array
static func _create_cookie_header_string(cookies: Array) -> String:
	var header_string := "Cookie: "
	for i in range(0, cookies.size(), 1):
		var cookie = cookies[i]
		# commenting out what I presume to be debugging
		# print statements as they severely muddy output
		# - @wiz-rd

		# print("Cookie Loop Index: " + str(i))
		# print(cookie)
		if (!cookie.name.is_empty()):
			header_string += cookie.name + "="
		if (!cookie.value.is_empty()):
			header_string += cookie.value
		if (i != cookies.size()-1):
			header_string += "; "
	# print("Header string will be: ")
	print(header_string)
	return header_string
