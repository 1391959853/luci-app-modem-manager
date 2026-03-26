local M = {}

-- 发送 AT 命令并返回结果
function M.send_at_cmd(port, cmd, timeout_ms)
	timeout_ms = timeout_ms or 500
	local fd = nixio.open(port, nixio.O_RDWR)
	if not fd then return "ERROR: Cannot open " .. port end
	fd:write(cmd .. "\r\n")
	nixio.nanosleep(0, timeout_ms * 1000000)
	local result = ""
	while true do
		local data = fd:read(1024, 500000)
		if not data then break end
		result = result .. data
	end
	fd:close()
	return result
end

-- 获取模块基本信息（带缓存）
function M.get_modem_info()
	local module = M.detect_module()
	local signal = M.get_signal()
	local operator = M.get_operator()
	local sim_status = M.get_sim_status()
	local temperature = M.get_temperature()
	local nat_mode = M.get_nat_mode()

	return {
		vendor = module.vendor,
		model = module.model,
		imei = module.imei,
		imsi = module.imsi,
		fw_version = module.fw_version,
		signal = signal,
		operator = operator.name,
		operator_numeric = operator.numeric,
		sim_status = sim_status,
		temperature = temperature,
		nat_mode = nat_mode,
		drivers_loaded = M.check_drivers(),
	}
end

-- 检测模块厂商和型号
function M.detect_module()
	-- 优先通过 lsusb 识别
	local handle = io.popen("lsusb 2>/dev/null | grep -i -E 'quectel|fibocom|05c6|2c7c'")
	local usb = handle:read("*all")
	handle:close()
	local info = { vendor = "unknown", model = "unknown", imei = "", imsi = "", fw_version = "" }

	if usb:match("2c7c:0125") then
		info.vendor = "Quectel"
		info.model = "EC20/EC25"
	elseif usb:match("2c7c:0800") then
		info.vendor = "Quectel"
		info.model = "RG200U-CN"
	elseif usb:match("05c6:9003") then
		info.vendor = "Quectel"
		info.model = "724UG"
	elseif usb:match("2c7c:0296") then
		info.vendor = "Fibocom"
		info.model = "L720/L724"
	end

	-- 如果未识别，尝试 ATI
	if info.vendor == "unknown" then
		local ati = M.send_at_cmd("/dev/ttyUSB2", "ATI", 500)
		if ati:match("Quectel") then
			info.vendor = "Quectel"
			if ati:match("EC20") then info.model = "EC20"
			elseif ati:match("EC25") then info.model = "EC25"
			elseif ati:match("RG200U") then info.model = "RG200U-CN"
			else info.model = "Quectel-Other"
			end
		elseif ati:match("Fibocom") then
			info.vendor = "Fibocom"
			if ati:match("L720") then info.model = "L720"
			elseif ati:match("L724") then info.model = "L724"
			else info.model = "Fibocom-Other"
			end
		end
	end

	-- 获取静态信息（仅在已识别或串口可用时）
	if info.vendor ~= "unknown" then
		info.imei = M.send_at_cmd("/dev/ttyUSB2", "AT+CGSN", 500):match("%d+") or ""
		info.imsi = M.send_at_cmd("/dev/ttyUSB2", "AT+CIMI", 500):match("%d+") or ""
		info.fw_version = M.send_at_cmd("/dev/ttyUSB2", "AT+CGMR", 500):match("[^\r\n]+") or ""
	end
	return info
end

function M.get_signal()
	local resp = M.send_at_cmd("/dev/ttyUSB2", "AT+CSQ", 500)
	local csq = resp:match("CSQ: (%d+),")
	return tonumber(csq) or 0
end

function M.get_operator()
	local resp = M.send_at_cmd("/dev/ttyUSB2", "AT+COPS?", 500)
	local name = resp:match('"([^"]+)"')
	local numeric = resp:match('"(%d%d%d%d%d)"')
	return { name = name or "Unknown", numeric = numeric or "" }
end

function M.get_sim_status()
	local resp = M.send_at_cmd("/dev/ttyUSB2", "AT+CPIN?", 500)
	if resp:match("READY") then return "Ready"
	elseif resp:match("SIM PIN") then return "PIN Required"
	else return "Not Ready"
	end
end

function M.get_temperature()
	local resp = M.send_at_cmd("/dev/ttyUSB2", "AT+QTEMP", 500)
	local temp = resp:match("QTEMP: (%d+)")
	return temp and tonumber(temp) or "N/A"
end

function M.get_nat_mode()
	local resp = M.send_at_cmd("/dev/ttyUSB2", 'AT+QCFG="nat"?', 500)
	local mode = resp:match('"nat",(%d)')
	return mode or "?"
end

function M.check_drivers()
	local required = {"usbserial", "option", "qmi_wwan", "cdc_ncm"}
	local missing = {}
	for _, mod in ipairs(required) do
		if not nixio.fs.access("/sys/module/" .. mod) then
			table.insert(missing, mod)
		end
	end
	return missing
end

-- 短信功能
function M.read_sms()
	local port = "/dev/ttyUSB2"
	local fd = nixio.open(port, nixio.O_RDWR)
	if not fd then return {} end
	fd:write("AT+CMGF=1\r\n")
	nixio.nanosleep(0, 200000000)
	fd:write("AT+CMGL=\"ALL\"\r\n")
	nixio.nanosleep(0, 500000000)
	local result = ""
	while true do
		local data = fd:read(2048, 1000000)
		if not data then break end
		result = result .. data
	end
	fd:close()

	local messages = {}
	for line in result:gmatch("[^\r\n]+") do
		if line:match("^%+CMGL:") then
			local idx, status, sender, time = line:match("^%+CMGL: (%d+),\"([^\"]+)\",\"([^\"]+)\",[^,]*,\"([^\"]+)\"")
			if idx then
				messages[#messages+1] = {index = idx, status = status, sender = sender, time = time, text = ""}
			end
		elseif #messages > 0 and messages[#messages].text == "" and not line:match("^OK$") and not line:match("^%+CMGL:") then
			messages[#messages].text = line
		end
	end
	return messages
end

function M.send_sms(number, text)
	local port = "/dev/ttyUSB2"
	local fd = nixio.open(port, nixio.O_RDWR)
	if not fd then return false, "Cannot open " .. port end
	fd:write("AT+CMGF=1\r\n")
	nixio.nanosleep(0, 200000000)
	fd:write("AT+CMGS=\"" .. number .. "\"\r\n")
	nixio.nanosleep(0, 500000000)
	fd:write(text .. "\x1A\r\n")
	nixio.nanosleep(0, 1000000000)
	local result = ""
	while true do
		local data = fd:read(1024, 2000000)
		if not data then break end
		result = result .. data
	end
	fd:close()
	if result:match("OK") then
		return true
	else
		return false, result
	end
end

return M