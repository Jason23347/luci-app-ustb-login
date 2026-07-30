#!/usr/bin/lua

local uci = require "luci.model.uci".cursor()
local http = require "socket.http"
local ltn12 = require "ltn12"

local enabled = uci:get("ustb_login", "main", "enabled")
if enabled ~= "1" then os.exit(0) end

local function resolve_credentials()
	local default_account = uci:get("ustb_login", "main", "default_account") or ""

	if default_account ~= "" then
		local username = uci:get("ustb_login", default_account, "username")
		local password = uci:get("ustb_login", default_account, "password")
		if username and username ~= "" then
			return username, password or ""
		end
	end

	-- 回退：使用第一个账号
	local first_user, first_pass
	uci:foreach("ustb_login", "account", function(sec)
		if not first_user and sec.username and sec.username ~= "" then
			first_user = sec.username
			first_pass = sec.password or ""
			return false
		end
	end)
	if first_user then
		return first_user, first_pass
	end

	-- 兼容旧配置：凭据仍在 main 中
	return uci:get("ustb_login", "main", "username") or "",
	       uci:get("ustb_login", "main", "password") or ""
end

local username, password = resolve_credentials()
local login_host = uci:get("ustb_login", "main", "login_host") or ""
local attempt_ipv6 = tonumber(uci:get("ustb_login", "main", "attempt_ipv6") or "0")
local default_ipv6 = uci:get("ustb_login", "main", "default_ipv6_address") or ""

if username == "" or login_host == "" then
	os.execute('logger -t ustb_login "No account configured, skip login."')
	os.exit(0)
end

-- 获取IPv6
local ip_addr = ""
if attempt_ipv6 >= 1 then
	if default_ipv6 ~= "" then
		ip_addr = default_ipv6
	else
		local resp = {}
		http.request{
			url = "http://cippv6.ustb.edu.cn/get_ip.php",
			sink = ltn12.sink.table(resp)
		}
		local body = table.concat(resp)
		ip_addr = body:match("gIpV6Addr%s*=%s*'([^']+)'") or ""
	end
end

-- 拼接参数
local params = string.format("callback=suibian&DDDDD=%s&upass=%s&0MKKey=123456&v6ip=%s",
	username, password, ip_addr)

local resp = {}
http.request{
	url = login_host .. "/drcom/login?" .. params,
	sink = ltn12.sink.table(resp)
}
local body = table.concat(resp)

if body:match('"result":1') then
	os.execute(string.format('logger -t ustb_login "Login succeed as %s."', username))
else
	os.execute(string.format('logger -t ustb_login "Login failed as %s."', username))
end
