-- single_instance.lua — 強制單一實例
-- 第二個 mpv 實例自動將檔案傳給第一個後自盡
-- 改寫自 ashik4u/MPV-Single-Instance

local mp    = require 'mp'
local utils = require 'mp.utils'
local PIPE  = '\\\\.\\pipe\\mpvsocket'

local is_main = false

-- 嘗試連接現有管道 → 有則代表已有主實例在執行
local f = io.open(PIPE, "w")
if f then
    f:close()
    is_main = false
else
    mp.set_property("input-ipc-server", PIPE)
    is_main = true
end

if is_main then return end  -- 主實例不用處理

-- 次要實例：等待 start-file 取得路徑後發送給主實例
mp.register_event("start-file", function()
    local path = mp.get_property("path", "")
    if path == "" then return end

    local escaped = path:gsub('\\', '\\\\'):gsub('"', '\\"')
    local json = '{"command":["loadfile","' .. escaped .. '","replace"]}'

    local pipe = io.open(PIPE, "w")
    if pipe then
        pipe:write(json .. "\n")
        pipe:close()
    end

    mp.commandv("quit")
end)
