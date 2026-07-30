local sys = require "luci.sys"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()

local m = Map("ustb_login", translate("USTB Web Login"),
    translate("Configure USTB web login."))

-- 全局登录设置
local s = m:section(TypedSection, "ustb_login", translate("Login Settings"))
s.anonymous = true
s.addremove = false

s:option(Flag, "enabled", translate("Enable"))

local da = s:option(ListValue, "default_account", translate("Default Account"))
da.rmempty = true
da:value("", translate("-- Please choose --"))
uci:foreach("ustb_login", "account", function(sec)
	local sid = sec[".name"]
	local remark = sec.remark or ""
	local user = sec.username or ""
	if remark ~= "" then
		da:value(sid, remark)
	elseif user ~= "" then
		da:value(sid, user)
	else
		da:value(sid, sid)
	end
end)

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

		local body = util.trim(util.exec("uclient-fetch -T 1 -qO- http://cippv6.ustb.edu.cn/get_ip.php 2>/dev/null"))
		if body == "" then
			return translate("Unavailable")
		end

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
		sys.call("/usr/bin/ustb_login.lua >/dev/null 2>&1 &")
	end
end

-- 多账号管理
local a = m:section(TypedSection, "account", translate("Accounts"),
    translate("Add multiple accounts and select one as default above."))
a.anonymous = true
a.addremove = true
a.template = "cbi/tblsection"

a:option(Value, "remark", translate("Remark"))
a:option(Value, "username", translate("Username"))
local pw = a:option(Value, "password", translate("Password"))
pw.password = true

return m
