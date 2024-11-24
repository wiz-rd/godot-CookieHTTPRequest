class_name CookieDebug


enum LEVEL {WARN, ERR}

# Debug format string
const DEBUG_FORMAT := "CookieHTTPRequest: %s - %s"


# Push formatted string to appropriate debug level
static func push_debug(level: LEVEL, area: String, statement: String) -> void:
	match level:
		LEVEL.WARN:
			push_warning(DEBUG_FORMAT % [area, statement])
		LEVEL.ERR:
			push_error(DEBUG_FORMAT % [area, statement])
