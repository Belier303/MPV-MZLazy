local mp = require "mp"
local input = require "mp.input"
local utils = require "mp.utils"

local options = {
    max_items = 20,
}
require "mp.options".read_options(options, "vcs_wall")

local function format_time(seconds, use_hours)
    if not seconds or seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if use_hours or h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

local function open_vcs()
    local duration = mp.get_property_number("duration", 0)
    if duration <= 0 then
        mp.osd_message("無法取得影片長度", 2)
        return
    end

    local chapters = mp.get_property_native("chapter-list", {})
    local use_hours = duration >= 3600
    local entries = {}
    local seen = {}

    if #chapters > 0 then
        for i, ch in ipairs(chapters) do
            local title = ch.title or ("章節 " .. i)
            local time_str = format_time(ch.time, use_hours)
            local key = math.floor(ch.time)
            seen[key] = true
            table.insert(entries, {
                label = title .. "  (" .. time_str .. ")",
                time = ch.time,
            })
        end
    end

    local count = math.max(4, options.max_items)
    local step = duration / (count + 1)
    for i = 1, count do
        local t = step * i
        if t < 0.5 then t = 0.5 end
        if t > duration - 0.5 then t = duration - 0.5 end
        local key = math.floor(t)
        if not seen[key] then
            seen[key] = true
            table.insert(entries, {
                label = "時間點 " .. string.format("%.1f", t) .. "s  (" .. format_time(t, use_hours) .. ")",
                time = t,
            })
        end
    end

    table.sort(entries, function(a, b) return a.time < b.time end)

    local items = {}
    local times = {}
    for _, e in ipairs(entries) do
        table.insert(items, e.label)
        table.insert(times, e.time)
    end

    input.select({
        prompt = "VCS 章節縮圖牆 — 選擇跳轉",
        items = items,
        submit = function(idx)
            mp.commandv("seek", times[idx], "absolute")
            mp.osd_message("跳轉至 " .. format_time(times[idx], use_hours), 1)
        end,
    })
end

mp.add_key_binding("F9", "vcs-wall", open_vcs)
