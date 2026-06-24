local utils = require 'mp.utils'
local FILE = utils.join_path(mp.command_native({"expand-path", "~~/"}), "window_size.json")

local function save(t)
    local f = io.open(FILE, "w")
    if f then f:write(utils.format_json(t)); f:close() end
end

mp.observe_property("current-window-scale", "number", function(_, val)
    if val and val > 0 then save({scale = val}) end
end)

local function restore()
    local f = io.open(FILE, "r")
    if not f then return end
    local c = f:read("*a"); f:close()
    local ok, d = pcall(utils.parse_json, c)
    if ok and d and d.scale then
        mp.set_property_number("window-scale", d.scale)
    end
end

mp.add_timeout(0.5, restore)
