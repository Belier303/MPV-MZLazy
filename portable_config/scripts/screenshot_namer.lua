local DIR = "F:\\暫時下載檔"
local EXT = "png"

local function make_path()
    local name = mp.get_property("filename/no-ext", "screenshot")
    local safe = name:gsub('[<>:"/\\|?*]', '_')
    local pos = mp.get_property_number("time-pos", 0)
    local h = math.floor(pos / 3600)
    local m = math.floor((pos % 3600) / 60)
    local s = math.floor(pos % 60)
    local ts = string.format("%02d%02d%02d", h, m, s)
    local now = os.date("*t")
    local ds = string.format("%04d%02d%02d%02d%02d%02d", now.year, now.month, now.day, now.hour, now.min, now.sec)
    local fname = safe .. "-" .. ts .. "-" .. ds .. "." .. EXT
    return DIR .. "\\" .. fname, fname
end

local function take(mode)
    local path, fname = make_path()
    mp.commandv("screenshot-to-file", path, mode)
    mp.osd_message("截圖：" .. fname, 5)
end

-- script-binding 用（右鍵選單）
mp.add_key_binding(nil, "ss_video", function() take("video") end)
mp.add_key_binding(nil, "ss_sub",   function() take("subtitles") end)
mp.add_key_binding(nil, "ss_win",   function() take("window") end)
-- script-message 用（modernz 按鈕）
mp.register_script_message("ss_video_fn", function() take("video") end)
mp.register_script_message("ss_sub_fn",   function() take("subtitles") end)
mp.register_script_message("ss_win_fn",   function() take("window") end)

-- 實體按鍵
mp.add_key_binding("Ctrl+s", "ss_osd",    function() take("subtitles") end)
mp.add_key_binding("Ctrl+S", "ss_win_kb", function() take("window") end)
mp.add_key_binding("F12",    "ss_win_f12", function() take("window") end)
