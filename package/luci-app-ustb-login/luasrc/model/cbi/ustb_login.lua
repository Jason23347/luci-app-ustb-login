local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()

-- 原生 HTTP 请求（LuaSocket）
local has_http, http = pcall(require, "socket.http")
local has_ltn12, ltn12 = pcall(require, "ltn12")
if has_http then
  http.TIMEOUT = 3
end

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

-- 自动获取并显示 IPv6（只读）
do
  local dv = s:option(DummyValue, "_detected_ipv6", translate("Detected IPv6"))
  function dv.cfgvalue(self, sid)
    local attempt_ipv6 = tonumber(uci:get("ustb_login", sid, "attempt_ipv6") or "0")
    if attempt_ipv6 < 1 then
      return translate("Disabled")
    end

    local def = uci:get("ustb_login", sid, "default_ipv6_address") or ""
    if def ~= "" then
      return def
    end

    if not (has_http and has_ltn12) then
      return translate("LuaSocket not available")
    end

    local resp = {}
    local ok, code = http.request{
      url  = "http://cippv6.ustb.edu.cn/get_ip.php",
      sink = ltn12.sink.table(resp)
    }

    if not ok or (type(code) == "number" and code ~= 200) then
      return translate("Unavailable")
    end

    local body = table.concat(resp)
    local ip = body:match("gIpV6Addr%s*=%s*'([^']+)'") or ""
    return (ip ~= "" and ip) or translate("Unavailable")
  end
end

-- 手动登录按钮
do
  local btn = s:option(Button, "_manual_login", translate("Manual Login"))
  btn.inputtitle = translate("Login now")
  btn.inputstyle = "apply"
  function btn.write(self, sid)
    -- 后台执行，避免阻塞页面
    sys.call("/usr/bin/ustb_login.lua >/dev/null 2>&1 &")
  end
end

return m
