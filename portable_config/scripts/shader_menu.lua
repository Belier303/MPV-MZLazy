local mp = require "mp"
local input = require "mp.input"
local utils = require "mp.utils"

local options = {
    shader_dir = "~~/shaders/",
    shader_exts = "glsl,hook",
    preset_count = 3,
    preset_save_path = "~~/",
}
require "mp.options".read_options(options, "shader_menu")

local shader_base_path = ""
local presets = {}
local PRESETS_FILENAME = "shader_menu_presets.json"

local function normalize_path(p)
    if not p then return "" end
    return p:gsub("\\", "/"):gsub("/+", "/")
end

local function path_key(p)
    return normalize_path(p):lower()
end

local function get_extension(filename)
    return filename:match("%.([^%.]+)$")
end

local function strip_extension(filename)
    return filename:match("^(.+)%.[^%.]+$") or filename
end

local function load_presets()
    local dir = options.preset_save_path
    local expanded = mp.command_native({ "expand-path", dir }) or dir
    local filepath = utils.join_path(expanded, PRESETS_FILENAME)
    local f = io.open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    local data = utils.parse_json(content)
    if type(data) ~= "table" then return end
    for i, entry in ipairs(data) do
        if type(entry) == "table" and entry.list then
            presets[i] = entry
        end
    end
end

local function save_presets()
    local dir = options.preset_save_path
    local expanded = mp.command_native({ "expand-path", dir }) or dir
    local filepath = utils.join_path(expanded, PRESETS_FILENAME)
    local json = utils.format_json(presets)
    if not json then return end
    local f = io.open(filepath, "w")
    if not f then return end
    f:write(json)
    f:close()
end

local function scan_shaders(dir_path, prefix)
    prefix = prefix or ""
    local items = {}
    local dirs = utils.readdir(dir_path, "dirs")
    if dirs then
        table.sort(dirs)
        for _, dirname in ipairs(dirs) do
            local sub = utils.join_path(dir_path, dirname)
            local sub_items = scan_shaders(sub, prefix .. dirname .. "/")
            for _, si in ipairs(sub_items) do
                table.insert(items, si)
            end
        end
    end
    local exts = {}
    for ext in options.shader_exts:gmatch("[^,]+") do
        exts[ext:lower()] = true
    end
    local files = utils.readdir(dir_path, "files")
    if files then
        table.sort(files)
        for _, filename in ipairs(files) do
            local ext = get_extension(filename)
            if ext and exts[ext:lower()] then
                local full = utils.join_path(dir_path, filename)
                table.insert(items, {
                    path = full,
                    label = prefix .. strip_extension(filename),
                })
            end
        end
    end
    return items
end

local function show_menu()
    local shaders = mp.get_property_native("glsl-shaders", {})
    local shader_map = {}
    if type(shaders) == "table" then
        for _, p in ipairs(shaders) do
            shader_map[path_key(p)] = true
        end
    end

    local items = {}
    local values = {}

    table.insert(items, "[清空全部著色器]")
    table.insert(values, "__clear__")

    for i = 1, options.preset_count do
        local hint = (presets[i] and #presets[i].list > 0) and ("(" .. #presets[i].list .. " 項)") or "(空)"
        table.insert(items, "套用預設 " .. i .. " " .. hint)
        table.insert(values, "__preset_" .. i)
    end

    table.insert(items, "儲存目前佇列到預設...")
    table.insert(values, "__save_preset__")

    local shader_list = scan_shaders(shader_base_path)
    if #shader_list == 0 then
        table.insert(items, "（未找到著色器檔案）")
        table.insert(values, nil)
    else
        for _, s in ipairs(shader_list) do
            local check = shader_map[path_key(s.path)] and "✓ " or "  "
            table.insert(items, check .. s.label)
            table.insert(values, s.path)
        end
    end

    input.select({
        prompt = "著色器選單（選擇切換開關，ESC 關閉）",
        items = items,
        keep_open = true,
        submit = function(idx)
            local val = values[idx]
            if not val then return end

            if val == "__clear__" then
                mp.command('change-list glsl-shaders clr ""')
                mp.osd_message("已清空全部著色器", 1)
                show_menu()
                return
            end

            local preset_n = val:match("^__preset_(%d+)$")
            if preset_n then
                local n = tonumber(preset_n)
                if not presets[n] or #presets[n].list == 0 then
                    mp.osd_message("預設 " .. n .. " 為空", 2)
                    show_menu()
                    return
                end
                mp.command('change-list glsl-shaders clr ""')
                for _, p in ipairs(presets[n].list) do
                    mp.command('change-list glsl-shaders append "' .. p .. '"')
                end
                mp.osd_message("已套用著色器預設 " .. n, 2)
                show_menu()
                return
            end

            if val == "__save_preset__" then
                input.select({
                    prompt = "儲存到哪個預設？",
                    items = { "預設 1", "預設 2", "預設 3" },
                    submit = function(pn)
                        local list = mp.get_property_native("glsl-shaders", {})
                        presets[pn] = { str = table.concat(list, ","), list = list }
                        save_presets()
                        mp.osd_message("已儲存到預設 " .. pn, 2)
                        show_menu()
                    end,
                })
                return
            end

            -- 使用 commandv 避免路徑含特殊字元時解析錯誤
            mp.commandv("change-list", "glsl-shaders", "toggle", val)
            mp.osd_message("切換著色器: " .. (shader_map[path_key(val)] and "關" or "開"), 1)
            show_menu()
        end,
    })
end

mp.add_key_binding("F8", "shader-menu", show_menu)
mp.add_key_binding("Shift+F8", "shader-menu-root", show_menu)

local dir = options.shader_dir
local norm = normalize_path(dir)
if norm:match("^~~/") or norm:match("^~~\\") or norm == "~~" then
    shader_base_path = mp.command_native({ "expand-path", dir }) or dir
else
    shader_base_path = dir
end

load_presets()
