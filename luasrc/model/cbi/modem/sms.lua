local m = Map("modem", "SMS Management", "Send and receive SMS")

local send_section = m:section(SimpleSection, nil, "Send SMS")
local number = send_section:option(Value, "number", "Phone Number")
number.rmempty = false
local message = send_section:option(TextValue, "message", "Message")
message.rows = 3
local send_btn = send_section:option(Button, "send_sms", "Send")
send_btn.inputtitle = "Send"
send_btn.inputstyle = "apply"

function send_btn.write()
	local num = m:formvalue("cbid.modem.number")
	local msg = m:formvalue("cbid.modem.message")
	if num and msg then
		local modem_common = require("modem_common")
		local ok, err = modem_common.send_sms(num, msg)
		if ok then
			m.message = "SMS sent to " .. num
		else
			m.message = "Failed: " .. err
		end
	end
end

local list_section = m:section(SimpleSection, nil, "Inbox")
list_section.template = "modem/sms"

return m