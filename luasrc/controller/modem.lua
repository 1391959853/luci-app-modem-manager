module("luci.controller.modem", package.seeall)

function index()
	local page = entry({"admin", "modem"}, alias("admin", "modem", "status"), _("4/5G Modem"), 80)
	page.dependent = false
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"

	entry({"admin", "modem", "status"}, template("modem/status"), _("Status"), 10).leaf = true
	entry({"admin", "modem", "atcmd"}, cbi("modem/atcmd"), _("AT Commands"), 20)
	entry({"admin", "modem", "sms"}, cbi("modem/sms"), _("SMS"), 30)

	entry({"admin", "modem", "api", "modem_info"}, call("api_modem_info")).leaf = true
	entry({"admin", "modem", "api", "send_at"}, call("api_send_at")).leaf = true
	entry({"admin", "modem", "api", "read_sms"}, call("api_read_sms")).leaf = true
	entry({"admin", "modem", "api", "send_sms"}, call("api_send_sms")).leaf = true
	entry({"admin", "modem", "api", "load_driver"}, call("api_load_driver")).leaf = true
end

local modem_common = require("modem_common")

function api_modem_info()
	luci.http.prepare_content("application/json")
	local info = modem_common.get_modem_info()
	luci.http.write_json(info)
end

function api_send_at()
	luci.http.prepare_content("application/json")
	local cmd = luci.http.formvalue("cmd")
	local port = luci.http.formvalue("port") or "/dev/ttyUSB2"
	if not cmd then
		luci.http.write_json({error = "Missing command"})
		return
	end
	local result = modem_common.send_at_cmd(port, cmd)
	luci.http.write_json({result = result})
end

function api_read_sms()
	luci.http.prepare_content("application/json")
	local messages = modem_common.read_sms()
	luci.http.write_json({messages = messages})
end

function api_send_sms()
	luci.http.prepare_content("application/json")
	local number = luci.http.formvalue("number")
	local text = luci.http.formvalue("message")
	if not number or not text then
		luci.http.write_json({error = "Missing number or message"})
		return
	end
	local ok, err = modem_common.send_sms(number, text)
	if ok then
		luci.http.write_json({success = true})
	else
		luci.http.write_json({error = err})
	end
end

function api_load_driver()
	luci.http.prepare_content("application/json")
	local driver = luci.http.formvalue("driver")
	if not driver then
		luci.http.write_json({error = "Missing driver name"})
		return
	end
	local ret = os.execute("modprobe " .. driver .. " 2>/dev/null")
	luci.http.write_json({success = (ret == 0)})
end