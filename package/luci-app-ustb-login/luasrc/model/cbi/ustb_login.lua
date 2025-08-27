local m = Map("ustb_login", translate("USTB Web Login"),
    translate("Configure USTB web login."))

local s = m:section(TypedSection, "ustb_login", translate("Login Settings"))
s.anonymous = true

s:option(Flag, "enabled", translate("Enable"))

s:option(Value, "username", translate("Username"))
local pw = s:option(Value, "password", translate("Password"))
pw.password = true

s:option(Value, "login_host", translate("Login Host"))
s:option(Flag, "attempt_ipv6", translate("Attempt IPv6"))
s:option(Value, "default_ipv6_address", translate("Default IPv6 Address"))

return m
