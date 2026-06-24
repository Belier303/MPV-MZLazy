local utils = require 'mp.utils'
local FILE = utils.join_path(mp.command_native({"expand-path", "~~/"}), "resume_pref.json")
local resume = false

local function load()
    local f = io.open(FILE, "r")
    if not f then return end
    local d = utils.parse_json(f:read("*a"))
    f:close()
    if type(d) == "table" and d.resume ~= nil then resume = d.resume end
end

local function save()
    local f = io.open(FILE, "w")
    if f then f:write(utils.format_json({resume = resume})); f:close() end
end

function toggle()
    resume = not resume
    save()
    mp.set_property_native("save-position-on-quit", resume)
    mp.osd_message(resume and "接續播放（記住位置）" or "從頭播放（每次重新開始）", 2)
end

load()
mp.set_property_native("save-position-on-quit", resume)

mp.add_key_binding(nil, "toggle-resume", toggle)
