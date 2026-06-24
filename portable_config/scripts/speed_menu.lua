local mp = require "mp"
local input = require "mp.input"

local function open_speed_menu()
    local current = mp.get_property_number("speed", 1)
    local presets = { 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0 }
    local labels = {}
    local values = {}
    for _, s in ipairs(presets) do
        local prefix = (math.abs(s - current) < 0.01) and "✓ " or "  "
        table.insert(labels, prefix .. string.format("%.2f", s) .. "x")
        table.insert(values, s)
    end
    table.insert(labels, "---")
    table.insert(labels, "自訂倍速 (0.1~100)")
    table.insert(values, "__custom__")

    input.select({
        prompt = "播放速度（目前 " .. string.format("%.2f", current) .. "x）",
        items = labels,
        submit = function(idx)
            if idx > #values then return end
            local v = values[idx]
            if v == "__custom__" then
                mp.osd_message("使用 [ 減速 0.1 / ] 加速 0.1 調整", 3)
            else
                mp.set_property("speed", v)
                mp.osd_message("速度: " .. string.format("%.2f", v) .. "x", 1)
            end
        end,
    })
end

mp.add_key_binding("Shift+F9", "speed-menu", open_speed_menu)
