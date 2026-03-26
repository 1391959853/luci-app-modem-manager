local m = Map("modem", "AT Commands", "Send AT commands to the modem")
local s = m:section(SimpleSection, nil, nil)

local cmd = s:option(Value, "at_cmd", "AT Command")
cmd.rmempty = false

local port = s:option(ListValue, "port", "Serial Port")
port:value("/dev/ttyUSB2", "ttyUSB2 (AT)")
port:value("/dev/ttyUSB3", "ttyUSB3")

local send = s:option(Button, "send", "Send")
send.inputtitle = "Execute"
send.inputstyle = "apply"

local output = s:option(TextValue, "output", "Response")
output.rows = 10
output.readonly = true

function send.write()
	local cmd_text = m:formvalue("cbid.modem.at_cmd")
	local port_dev = m:formvalue("cbid.modem.port") or "/dev/ttyUSB2"
	if cmd_text and cmd_text ~= "" then
		local modem_common = require("modem_common")
		local result = modem_common.send_at_cmd(port_dev, cmd_text, 1000)
		m.uci:set("modem", "at", "output", result)
		m.uci:commit("modem")
	end
end

function m.parse(map)
	m.uci:load("modem")
	local saved = m.uci:get("modem", "at", "output")
	if saved then
		map:set("cbid.modem.output", saved)
	end
end

return m