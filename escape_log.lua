-- Sistema de log para debug
local logFile = "c:\\UB\\scripts\\escape_debug.txt"

local function WriteLog(message)
    local file = io.open(logFile, "a")
    if file then
        file:write(os.date("%H:%M:%S") .. " - " .. message .. "\n")
        file:close()
    end
end

return WriteLog
