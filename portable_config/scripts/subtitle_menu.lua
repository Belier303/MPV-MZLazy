local mp = require "mp"
local input = require "mp.input"

local function sf(fn)
    return function(...)
        local ok, err = xpcall(fn, debug.traceback, ...)
        if not ok then mp.msg.error("subtitle_menu:\n" .. tostring(err)) end
    end
end

local function setf(prop, val, msg)
    local ok, err = pcall(mp.set_property, prop, val)
    if not ok then mp.msg.error("subtitle_menu setf: " .. tostring(err)) end
    mp.osd_message(msg, 1.5)
end

local function menu_font(cb)
    local cur = mp.get_property("sub-font")
    local fonts = { "Microsoft JhengHei", "Microsoft YaHei", "DFKai-SB", "MingLiU", "SimHei", "LXGW WenKai Mono Lite", "Noto Sans CJK TC" }
    local items = {}
    for _, f in ipairs(fonts) do
        table.insert(items, ((f == cur) and "✓ " or "  ") .. f)
    end
    table.insert(items, "◀ 返回")
    input.select({
        prompt = "字體字型",
        items = items,
        submit = sf(function(idx)
            if idx <= #fonts then setf("sub-font", fonts[idx], "字體: " .. fonts[idx]) end
            if cb then cb() end
        end),
    })
end

local function menu_size(cb)
    local cur = mp.get_property_number("sub-font-size", 44)
    local sizes = { 20, 28, 36, 44, 52, 60, 72 }
    local items = {}
    for _, s in ipairs(sizes) do
        table.insert(items, ((s == cur) and "✓ " or "  ") .. s .. "pt")
    end
    table.insert(items, "◀ 返回")
    input.select({
        prompt = "字體大小",
        items = items,
        submit = sf(function(idx)
            if idx <= #sizes then mp.set_property_number("sub-font-size", sizes[idx]); mp.osd_message("字體大小: " .. sizes[idx] .. "pt", 1.5) end
            if cb then cb() end
        end),
    })
end

local function menu_border_width(cb)
    local cur = mp.get_property_number("sub-border-size", 2.5)
    local vals = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
    local items = {}
    for _, v in ipairs(vals) do
        local label = (v == 0) and "無外框" or (v .. "px")
        table.insert(items, ((math.abs(v - cur) < 0.1) and "✓ " or "  ") .. label)
    end
    table.insert(items, "◀ 返回")
    input.select({
        prompt = "外框大小（目前 " .. cur .. "px）",
        items = items,
        submit = sf(function(idx)
            if idx <= #vals then setf("sub-border-size", tostring(vals[idx]), "外框: " .. ((vals[idx] == 0) and "無" or vals[idx] .. "px")) end
            if cb then cb() end
        end),
    })
end

local function menu_border_color(cb)
    local cur = mp.get_property("sub-border-color")
    local colors = { "#FF000000", "#FFFFFFFF", "#FF888888", "#FFFF0000", "#FF00FF00", "#FF0000FF" }
    local names = { "黑色", "白色", "灰色", "紅色", "綠色", "藍色" }
    local items = {}
    for i, c in ipairs(colors) do
        table.insert(items, ((cur == c) and "✓ " or "  ") .. names[i])
    end
    table.insert(items, "◀ 返回")
    input.select({
        prompt = "外框顏色",
        items = items,
        submit = sf(function(idx)
            if idx <= #colors then setf("sub-border-color", colors[idx], "外框顏色: " .. names[idx]) end
            if cb then cb() end
        end),
    })
end

local function menu_border(cb)
    local items = { "外框大小", "外框顏色", "◀ 返回" }
    input.select({
        prompt = "字體外框",
        items = items,
        submit = sf(function(idx)
            if idx == 1 then menu_border_width(function() menu_border(cb) end)
            elseif idx == 2 then menu_border_color(function() menu_border(cb) end)
            elseif idx == 3 and cb then cb() end
        end),
    })
end

local function menu_shadow(cb)
    local cur = mp.get_property_number("sub-shadow-offset", 0.8)
    local items = {
        ((cur == 0) and "✓ " or "  ") .. "無陰影",
        ((cur > 0) and "✓ " or "  ") .. "有陰影",
        "◀ 返回",
    }
    input.select({
        prompt = "字體陰影",
        items = items,
        submit = sf(function(idx)
            if idx == 1 then setf("sub-shadow-offset", "0", "陰影: 關閉")
            elseif idx == 2 then setf("sub-shadow-offset", "0.8", "陰影: 開啟") end
            if cb then cb() end
        end),
    })
end

local function menu_bold(cb)
    local cur = mp.get_property_native("sub-bold")
    local items = {
        ((cur == false) and "✓ " or "  ") .. "標準",
        ((cur == true) and "✓ " or "  ") .. "粗體",
        "◀ 返回",
    }
    input.select({
        prompt = "字體粗細",
        items = items,
        submit = sf(function(idx)
            if idx == 1 then mp.set_property_native("sub-bold", false); mp.osd_message("粗體: 關閉", 1.5)
            elseif idx == 2 then mp.set_property_native("sub-bold", true); mp.osd_message("粗體: 開啟", 1.5) end
            if cb then cb() end
        end),
    })
end

local function main_menu()
    local items = { "字體字型", "字體大小", "字體外框", "字體陰影", "字體粗細" }
    local handlers = { menu_font, menu_size, menu_border, menu_shadow, menu_bold }
    local function show()
        input.select({
            prompt = "字幕樣式設定（ESC 關閉）",
            items = items,
            keep_open = true,
            submit = sf(function(idx)
                if idx >= 1 and idx <= #handlers then handlers[idx](show) end
                return true
            end),
        })
    end
    show()
end

mp.add_key_binding(nil, "subtitle-menu", function()
    local ok2, err2 = xpcall(main_menu, debug.traceback)
    if not ok2 then mp.msg.error("subtitle_menu entry:\n" .. tostring(err2)) end
end)
