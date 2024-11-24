# CookieHTTPRequest Node for Godot

A Godot plugin providing a simple to use extension to the `HTTPRequest` Node, automatically handling HTTP cookies for requests and responses.

Provides an implementation of the algorithms specified in [RFC-6265bis](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-15). On making requests, will get all applicable cookies stored in the static `CookieStore` and attached a `Cookie` header containing them. On receiving a response, will process all `Set-Cookie` headers and store the resulting cookies in the static `CookieStore`.

This was created as a stopgap measure until cookie processing is adopted into the Godot engine source code. The current proposal for this change is located [here](https://github.com/godotengine/godot-proposals/issues/6556).

## Usage

Godot doesn't allow overriding of non-virtual functions, so `CookieHTTPRequest` Node exposes it's functionality via the `cookie_request` and `cookie_request_raw` methods, corresponding to the Godot `HTTPRequest` Node `request` and `request_raw` methods. You can easily swap it in wherever you currently use `HTTPRequest` and just change the method names you call.

### Cookie processing blocking

Because the `request_completed` method does not return any information about the request, this implementation saves off the `current_request_url` for use during processing of `Set-Cookie` headers. To prevent this from changing during the process, `request` and `request_raw` will return `@GlobalScope.ERR_BUSY` while the post-request process is being completed, despite the request being completed.

### `Cookie` headers provided in `custom_headers` parameter

If one or more `Cookie` headers are provided in the `custom_header` parameter, the request methods will keep them separate from the `Cookie` header provided from the store, with that header proceeding all other request headers. As long as the resource you are accessing is using at least `HTTP/2`, this should not be an issue as multiple `Cookie` header support was added in that version. The order should also not be an issue, as `RFC6265bis` says a server "SHOULD NOT" rely on order of cookies.

## Implementation caveats

Due to the nature of this implementation being for Godot and being implemented as a plugin rather than part of the Godot Engine, as well as being a stopgap rather than a permanent solution, there are some differences in how this code follows the RFC specification.

### Canonical host names

This algorithm does not do any DNS checks to get the canonical host name for domain values in cookies. For example, a cookie with a `domain` value of `m.example.com` or `www.example.com` would not be provided on requests to `example.com`. This isn't as much of an issue as it would be for a browser, but make sure that your requests are to the canonical version of a server, and that the server is set up to provide the canonical name for cookie `domain` values.

### HTTP Only flagging

Since this code isn't integrated into the engine directly and is editable by anyone who imports the asset, there's no way it can reliably determine whether a request to the store is made by the `CookieHTTPRequest` node or a direct access. As such, the check related to the `http_only` flag is skipped on retrieval.

### Same Site flagging

The RFC for cookies was written with web browser agents in mind. As Godot is not a web browser, it doesn't inherently have a origin. Therefore, the check related to the `same_site` flag is skipped on retrieval.

## Credit

Asset and editor icons made by [meltyKitt](https://meltykitt.carrd.co/)