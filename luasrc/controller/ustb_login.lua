module("luci.controller.ustb_login", package.seeall)

function index()
    entry({"admin", "services", "ustb_login"}, cbi("ustb_login"), _("USTB Login"), 90)
end
