class_name HTTPUtils


# Values used by both store and request
# Maximum representable time
const MAX_SECONDS = 9223372036854775807


# Get the hostname of a url string.
static func get_url_domain(url: String) -> String:
	# 1. Strip fragment and query first to prevent issues if a url is a query param
	# 2. Strip scheme to prevent issues with path stripping
	# 3. Strip path and port
	var domain := url
	# Strip fragment if present.
	domain = domain.get_slice("#", 0)
	# Strip query if present.
	domain = domain.get_slice("?", 0)
	# Strip scheme if present.
	domain = domain.get_slice("://", 1)
	# Strip path if present.
	domain = domain.get_slice("/", 0)
	# Strip port if present.
	domain = domain.get_slice(":", 0)
	return domain


# Get the path of a url string if present, otherwise return empty string
static func get_url_path(url: String) -> String:
	var path :=url
	# Strip fragment if present.
	path = path.get_slice("#", 0)
	# Strip query if present.
	path = path.get_slice("?", 0)
	# Strip scheme if present.
	path = path.get_slice("://", 1)
	# Split path if present.
	var split_path = path.split("/")
	if (split_path.size() == 1):
		path = ''
	else:
		split_path.remove_at(0)
		path = "/" + "/".join(split_path)
	return path


# Get the protocol of a url if present, otherwise return empty string
static func get_url_protocol(url: String) -> String:
	var protocol := url
	# Get protocol if present
	protocol = protocol.get_slice("://", 0)
	if (protocol == url):
		protocol = ""
	return protocol


# Function to check if a request_url is accessed securely using `https`
# Some user agents will say that `localhost` fits this criteria
# Godot throws a TLS error on a call to `https://localhost` if no certificate is set up, so not including it
static func is_request_secure(url: String) -> bool:
	var protocol = get_url_protocol(url)
	return protocol.to_lower() == "https"


# Function to check for domain matching
static func domain_match(check_string: String, domain_string: String) -> bool:
	var check_string_lower = check_string.to_lower()
	var domain_string_lower = domain_string.to_lower()
	if (check_string_lower == domain_string_lower):
		return true
	if (check_string_lower.ends_with(domain_string_lower)):
		var diff = check_string_lower.trim_suffix(domain_string_lower)
		if(diff[diff.size()-1] == "."):
			return true
	return false


# Function to check for path matching
static func path_match(check_string: String, path_string: String) -> bool:
	if (check_string == path_string):
		return true
	if (check_string.begins_with(path_string)):
		var diff_left = check_string.trim_suffix(path_string)
		var diff_right = path_string.trim_prefix(check_string)
		if (diff_left[diff_left.length()-1] == "/"):
			return true
		if (diff_right[0] == "/"):
			return true
	return false
	
