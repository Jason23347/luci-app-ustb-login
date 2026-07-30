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

-- 当前登录账号信息（余额 / 流量）
do
	local FREE_QUOTA_GB = 120
	local PRICE_PER_GB = 0.6120
	local KB_PER_GB = 1024 * 1024

	local function kb_to_gb(kb)
		return (tonumber(kb) or 0) / KB_PER_GB
	end

	local function format_ipv4_flow(flow_kb)
		local used_gb = kb_to_gb(flow_kb)
		local pct = math.min(math.floor(used_gb * 100 / FREE_QUOTA_GB + 0.5), 100)
		local title
		if used_gb < FREE_QUOTA_GB then
			title = string.format("%.2f / %d GB (%.0f%%)", used_gb, FREE_QUOTA_GB, pct)
		else
			local excess_gb = used_gb - FREE_QUOTA_GB
			local cost = excess_gb * PRICE_PER_GB
			title = string.format("%d / %d GB，已超出 %.2f GB (%.2f 元)",
				FREE_QUOTA_GB, FREE_QUOTA_GB, excess_gb, cost)
		end
		return string.format(
			'<div class="cbi-progressbar" title="%s"><div style="width:%d%%"></div></div>',
			util.pcdata(title), pct)
	end

	local function fetch_session()
		local login_host = uci:get("ustb_login", "main", "login_host") or ""
		if login_host == "" then
			return { err = translate("Unavailable") }
		end

		local body = util.trim(util.exec(string.format(
			"uclient-fetch -T 1 -qO- '%s' 2>/dev/null",
			login_host:gsub("'", "'\\''"))))
		if body == "" then
			return { err = translate("Unavailable") }
		end

		if not body:find("flow=", 1, true) then
			return { err = translate("Login required") }
		end

		local flow = tonumber(body:match("flow%s*=%s*'%s*(%d+)%s*'")) or 0
		local fee = tonumber(body:match("fee%s*=%s*'%s*(%d+)%s*'")) or 0
		local v46m = tonumber(body:match("v46m%s*=%s*(%d+)")) or 0
		local v6df = tonumber(body:match("v6df%s*=%s*(%d+)")) or 0
		local v4_only = not (v46m == 4 or v46m == 12)

		return {
			balance = string.format("%.2f 元", fee / 10000),
			flow_v4 = format_ipv4_flow(flow),
			flow_v6 = v4_only
				and translate("IPV6 not found")
				or string.format("%.2f GB", kb_to_gb(v6df / 4)),
		}
	end

	local session = fetch_session()

	local info = m:section(SimpleSection, translate("Account Status"))

	local bal = info:option(DummyValue, "_balance", translate("Balance"))
	function bal.cfgvalue()
		return session.err or session.balance
	end

	local fv4 = info:option(DummyValue, "_flow_v4", translate("IPv4 Flow"))
	fv4.rawhtml = true
	function fv4.cfgvalue()
		return session.err or session.flow_v4
	end

	local fv6 = info:option(DummyValue, "_flow_v6", translate("IPv6 Flow"))
	function fv6.cfgvalue()
		return session.err or session.flow_v6
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
